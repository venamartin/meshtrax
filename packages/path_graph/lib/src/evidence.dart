import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'db/database.dart';
import 'estimator.dart';

/// Sentinel repeater hash for "heard them with an empty path".
const String directHash = 'DIRECT';

enum EvidenceTier { inferred, proven, direct }

class IngressEntry {
  IngressEntry({
    required this.weight,
    required this.lastSeen,
    required this.tier,
    this.observedLat,
    this.observedLon,
  });

  double weight;
  int lastSeen; // arrival millis
  EvidenceTier tier;
  double? observedLat;
  double? observedLon;

  /// Self rows only: hub-signature tracking (final vs penultimate).
  int finalCount = 0;
  int penultimateCount = 0;
}

class Candidate {
  const Candidate(this.repeaterHash, this.weight, this.tier);
  final String repeaterHash;
  final double weight;
  final EvidenceTier tier;
}

/// Weighted "who hears them" (contacts) and "who hears me" (self rows,
/// keyed by radio pubkey) lists, with decay, hub demotion, and the
/// discover supersede/slash discipline.
class EvidenceStore {
  EvidenceStore(this._db, this.config);

  final PathGraphDatabase _db;
  PathGraphConfig config;

  /// (ownerPubkey, repeaterHash) → entry.
  final Map<(String, String), IngressEntry> entries = {};
  final Set<(String, String)> _dirty = {};

  /// Contact mirror (isolation invariant: fed only by ingestContact).
  final Map<String, ({String name, int lastRefreshed})> knownContacts = {};
  final Set<String> _dirtyContacts = {};

  final Map<String, int> _lastSlashMillis = {};

  IngressEntry _upsert(String owner, String hash, EvidenceTier tier,
      double increment, int arrival) {
    final key = (owner, hash);
    final entry = entries.putIfAbsent(
        key, () => IngressEntry(weight: 0, lastSeen: arrival, tier: tier));
    entry.weight += increment;
    entry.lastSeen = arrival;
    // Tier only upgrades (proven never demoted back to inferred by a tally).
    if (tier.index > entry.tier.index) entry.tier = tier;
    _dirty.add(key);
    return entry;
  }

  /// Contact ingress: path[0] of traffic they originated.
  void recordIngress(String contactPubkey, String repeaterHash,
      {required bool pubkeyConfirmed, required int arrival}) {
    _upsert(contactPubkey, repeaterHash, EvidenceTier.proven,
        pubkeyConfirmed ? 3.0 : 1.0, arrival);
  }

  /// Self last-hop prior: final hop of a received path (inferred tier).
  void recordLastHop(String selfPubkey, String repeaterHash, int arrival,
      {double? lat, double? lon}) {
    final e =
        _upsert(selfPubkey, repeaterHash, EvidenceTier.inferred, 1.0, arrival);
    e.finalCount++;
    if (lat != null) e.observedLat = lat;
    if (lon != null) e.observedLon = lon;
  }

  /// Hub-signature counter: repeater seen second-to-last.
  void recordPenultimate(String selfPubkey, String repeaterHash) {
    final entry = entries[(selfPubkey, repeaterHash)];
    if (entry != null) {
      entry.penultimateCount++;
      _dirty.add((selfPubkey, repeaterHash));
    }
  }

  /// Direct reception of a contact (empty path).
  void recordDirect(String contactPubkey, int arrival) {
    _upsert(contactPubkey, directHash, EvidenceTier.direct, 3.0, arrival);
  }

  /// Proven egress upgrade (delivered send through this first hop).
  void recordProvenEgress(String selfPubkey, String repeaterHash, int arrival) {
    _upsert(selfPubkey, repeaterHash, EvidenceTier.proven, 3.0, arrival);
  }

  /// Discover results: proven refresh always; supersede/slash only in a
  /// failure episode, epoch-limited and floored, never on empty results.
  void applyDiscover(String selfPubkey,
      List<({String hash, double? snr})> responses, int arrival,
      {required bool failureEpisode}) {
    if (responses.isEmpty) return; // empty probe = no information

    if (failureEpisode) {
      final last = _lastSlashMillis[selfPubkey];
      final epochMs = config.slashEpochMinutes * 60 * 1000;
      if (last == null || arrival - last >= epochMs) {
        _lastSlashMillis[selfPubkey] = arrival;
        for (final entry in entries.entries) {
          if (entry.key.$1 != selfPubkey) continue;
          final e = entry.value;
          final factor = e.tier == EvidenceTier.inferred
              ? config.slashFactorInferred
              : config.slashFactorProven;
          e.weight *= factor;
          _dirty.add(entry.key);
        }
      }
    }

    for (final r in responses) {
      // Uplink SNR ranks responders: weight 3 at full quality, 1 at zero.
      final quality = r.snr == null
          ? 0.5
          : ((r.snr! - config.snrZeroQualityDb) /
                  (config.snrFullQualityDb - config.snrZeroQualityDb))
              .clamp(0.0, 1.0);
      _upsert(selfPubkey, r.hash, EvidenceTier.proven, 1.0 + 2.0 * quality,
          arrival);
    }
  }

  double _decayedWeight(String owner, IngressEntry e, int now, bool isSelf) {
    final halfLifeMs = isSelf
        ? config.egressHalfLifeMinutes * 60 * 1000
        : config.ingressHalfLifeHours * 60 * 60 * 1000;
    final dt = now - e.lastSeen;
    if (dt <= 0) return e.weight;
    return e.weight * math.pow(0.5, dt / halfLifeMs);
  }

  /// Ranked candidates for an owner. Self rows get fast decay and the
  /// hub demotion (penultimate ≫ final, vetoed by proven tier).
  List<Candidate> candidatesFor(String owner, int now, {required bool isSelf}) {
    final out = <Candidate>[];
    for (final entry in entries.entries) {
      if (entry.key.$1 != owner) continue;
      final e = entry.value;
      var w = _decayedWeight(owner, e, now, isSelf);
      if (isSelf && e.tier == EvidenceTier.inferred) {
        final appearances = e.finalCount + e.penultimateCount;
        if (appearances > 0) {
          w *= (e.finalCount / appearances); // hub signature demotion
        }
      }
      if (w > 0.05) out.add(Candidate(entry.key.$2, w, e.tier));
    }
    out.sort((a, b) => b.weight.compareTo(a.weight));
    return out;
  }

  /// Fresh direct-reception evidence for this contact?
  bool hasFreshDirect(String contactPubkey, int now) {
    final e = entries[(contactPubkey, directHash)];
    if (e == null) return false;
    return now - e.lastSeen <= config.directFreshMinutes * 60 * 1000;
  }

  void ingestContact(String pubkey, String name, int arrival) {
    knownContacts[pubkey] = (name: name, lastRefreshed: arrival);
    _dirtyContacts.add(pubkey);
  }

  /// Unique-name lookup for channel attribution (null if 0 or 2+ match).
  String? contactByUniqueName(String name) {
    String? found;
    for (final entry in knownContacts.entries) {
      if (entry.value.name == name) {
        if (found != null) return null;
        found = entry.key;
      }
    }
    return found;
  }

  Future<void> load() async {
    for (final row in await _db.select(_db.contactIngress).get()) {
      entries[(row.ownerPubkey, row.repeaterHash)] = IngressEntry(
        weight: row.weight,
        lastSeen: row.lastSeen,
        tier: EvidenceTier.values.byName(row.evidence),
        observedLat: row.observedLat,
        observedLon: row.observedLon,
      );
    }
    for (final row in await _db.select(_db.knownContacts).get()) {
      knownContacts[row.contactPubkey] =
          (name: row.name, lastRefreshed: row.lastRefreshed);
    }
  }

  Future<void> flush() async {
    if (_dirty.isEmpty && _dirtyContacts.isEmpty) return;
    final dirty = _dirty.toList();
    final dirtyContacts = _dirtyContacts.toList();
    _dirty.clear();
    _dirtyContacts.clear();

    await _db.batch((batch) {
      for (final key in dirty) {
        final e = entries[key];
        if (e == null) continue;
        batch.insert(
          _db.contactIngress,
          ContactIngressCompanion.insert(
            ownerPubkey: key.$1,
            repeaterHash: key.$2,
            weight: e.weight,
            lastSeen: e.lastSeen,
            evidence: e.tier.name,
            observedLat: Value(e.observedLat),
            observedLon: Value(e.observedLon),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final pk in dirtyContacts) {
        final c = knownContacts[pk];
        if (c == null) continue;
        batch.insert(
          _db.knownContacts,
          KnownContactsCompanion.insert(
            contactPubkey: pk,
            name: c.name,
            lastRefreshed: c.lastRefreshed,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
