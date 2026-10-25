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
  });

  double weight;
  int lastSeen; // arrival millis
  EvidenceTier tier;

  /// Arrival millis of the last proof in the SENDING direction: a
  /// delivered send through this hop, a trace, a Discover answer. Only
  /// hearing a repeater never sets it — hearing proves the other
  /// direction. Routes start and end at proven rows only.
  int? provenAt;
  bool get proven => provenAt != null;

  /// Measured first-hop SNR, both directions (Discover).
  double? uplinkSnr;
  double? downlinkSnr;

  /// Self rows only: hub-signature tracking (final vs penultimate).
  int finalCount = 0;
  int penultimateCount = 0;

  /// Every proof in the sending direction, all owners.
  int provenCount = 0;

  /// Self rows: last echo of my flood through this hop. Null = it never
  /// showed it forwards my floods, so a flood echo elsewhere says
  /// nothing against it.
  int? floodProvenAt;

  /// Last time this row was heard (not proven); null on rows from before
  /// the clocks were split, which fall back to [lastSeen].
  int? lastHeardAt;

  /// Self rows: direct sends that started here and got no ACK since the
  /// last proof. Any proof resets it.
  int failedSinceProof = 0;
}

class Candidate {
  const Candidate(this.repeaterHash, this.weight, this.tier,
      {this.uplinkSnr,
      this.downlinkSnr,
      this.proven = false,
      this.heard = false,
      this.finalCount = 0,
      this.penultimateCount = 0,
      this.provenCount = 0,
      this.provenAt,
      this.lastSeen = 0,
      this.isSelf = false,
      this.failedSinceProof = 0});
  final String repeaterHash;
  final double weight;
  final EvidenceTier tier;

  /// One of my own doorsteps (a repeater that hears this radio), as
  /// opposed to a contact's.
  final bool isSelf;

  /// Self rows: failed direct sends from here since the last proof.
  final int failedSinceProof;

  /// Tallies behind the ranking, for display: times heard carrying the
  /// owner's packets, times seen second-to-last (my rows), times proven
  /// in the sending direction, and the arrival millis of the last proof
  /// and the last sighting (0 = never).
  final int finalCount;
  final int penultimateCount;
  final int provenCount;
  final int? provenAt;
  final int lastSeen;

  /// Proven in the sending direction (see [IngressEntry.provenAt]).
  final bool proven;

  /// Heard carrying the owner's own packets (a contact's first hop, or
  /// the last hop before this radio). For a contact this is enough to
  /// end a route on: a repeater that hears a handheld reaches it. For
  /// my own end it is only a guess — I may hear a mountaintop that
  /// cannot hear me.
  final bool heard;

  /// Measured link to this candidate when Discover has run.
  final double? uplinkSnr;
  final double? downlinkSnr;

  /// The level in the direction a send travels. For one of my doorsteps
  /// only the uplink counts (how it heard me: a trace or a Discover
  /// answer); how loud I hear it says nothing about that, and a strong
  /// downlink kept a home repeater ranked first 40 km away (field
  /// 2026-10-17). A contact's doorstep falls back to the downlink by
  /// reciprocity. Null = tally-only candidate.
  double? get sendingSnr => isSelf ? uplinkSnr : (uplinkSnr ?? downlinkSnr);
}

/// Weighted "who hears them" (contacts) and "who hears me" (self rows,
/// keyed by radio pubkey) lists, with decay, hub demotion, and the
/// discover supersede/slash discipline.
class EvidenceStore {
  EvidenceStore(this._db, this.config, {this.hashWidthBytes = 2});

  final PathGraphDatabase _db;
  PathGraphConfig config;
  final int hashWidthBytes;

  /// (ownerPubkey, repeaterHash) → entry.
  final Map<(String, String), IngressEntry> entries = {};
  final Set<(String, String)> _dirty = {};
  final Set<(String, String)> _deleted = {};

  /// Contact mirror (isolation invariant: fed only by ingestContact).
  final Map<String, ({String name, int lastRefreshed})> knownContacts = {};
  final Set<String> _dirtyContacts = {};

  final Map<String, int> _lastSlashMillis = {};
  final Map<String, int> _lastSelfSupersedeMillis = {};

  /// When a key-confirmed packet of a contact last reached me through a
  /// repeater. Memory only: after a restart, direct waits for the next
  /// such packet to end it.
  final Map<String, int> _lastRelayed = {};

  /// Arrival millis of the last packets that showed my own end is alive
  /// (a repeater heard as my last hop, or a proof). The silence gate asks
  /// "have I heard enough lately for a doorstep's silence to mean
  /// anything?" — one stray packet after a quiet night says nothing.
  /// Memory only, newest last, capped.
  final List<int> _selfAliveEvents = [];

  void _noteSelfAlive(int arrival) {
    _selfAliveEvents.add(arrival);
    if (_selfAliveEvents.length > 64) _selfAliveEvents.removeAt(0);
  }

  int selfAliveEventsSince(int sinceMillis) =>
      _selfAliveEvents.where((t) => t >= sinceMillis).length;

  /// Arrival millis of the last time a repeater I had not had for a day
  /// heard me or was heard by me: the position-free sign that I moved (a
  /// radio at home meets nobody new). Memory only.
  int? lastNewSelfRowAt;

  /// Arrival millis of my doorsteps' proofs in the last hour, per hash,
  /// for the "rides with me" detector. Memory only.
  final Map<String, List<int>> _selfProofTimes = {};

  void _noteSelfRow(String selfPubkey, String repeaterHash, int arrival) {
    final e = entries[(selfPubkey, repeaterHash)];
    if (e == null || arrival - e.lastSeen > Duration.millisecondsPerDay) {
      lastNewSelfRowAt = arrival;
    }
  }

  /// Whether my doorstep [repeaterHash] proved it hears me in each of the
  /// last [slices] slices of [sliceMs].
  bool provenInEachSlice(String repeaterHash, int now,
      {required int sliceMs, required int slices}) {
    final times = _selfProofTimes[repeaterHash];
    if (times == null) return false;
    final filled = {
      for (final t in times)
        if (now - t < sliceMs * slices) (now - t) ~/ sliceMs,
    };
    return filled.length >= slices;
  }

  /// A direct send to [contactPubkey] that ended at [repeaterHash] got no
  /// ACK: one more failure against that doorstep for this pair.
  void recordFailedIngress(String contactPubkey, String repeaterHash) {
    final e = entries[(contactPubkey, repeaterHash)];
    if (e == null) return;
    e.failedSinceProof++;
    _dirty.add((contactPubkey, repeaterHash));
  }

  /// A direct send that started at [repeaterHash] got no ACK.
  void recordFailedEgress(String selfPubkey, String repeaterHash) {
    final e = entries[(selfPubkey, repeaterHash)];
    if (e == null) return;
    e.failedSinceProof++;
    _dirty.add((selfPubkey, repeaterHash));
  }

  /// Weights before this epoch's supersede, so a doorstep that echoes
  /// the same send a moment later gets its slash back.
  final Map<(String, String), double> _slashedThisEpoch = {};

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

  /// Contact ingress guess: path[0] of traffic they originated proves
  /// that repeater heard THEM — the reverse of what a send needs — so it
  /// is a candidate for Discover ranking and the UI, never a route end.
  void recordIngress(String contactPubkey, String repeaterHash,
      {required bool pubkeyConfirmed, required int arrival}) {
    // finalCount on a contact row counts "was their first hop" — proof,
    // in the return direction, that this repeater hears them.
    _upsert(contactPubkey, repeaterHash, EvidenceTier.inferred,
            pubkeyConfirmed ? 3.0 : 1.0, arrival)
      ..finalCount += 1
      ..lastHeardAt = arrival;
  }

  /// Doorsteps proven for the RETURN direction: repeaters that were
  /// heard carrying the owner's own packets (a contact's first hop, or
  /// the last hop before this radio). A guess for sending, proof for
  /// receiving.
  List<Candidate> heardCandidatesFor(String owner, int now,
      {required bool isSelf}) {
    final out = <Candidate>[];
    for (final entry in entries.entries) {
      if (entry.key.$1 != owner) continue;
      final e = entry.value;
      if (e.finalCount == 0 || entry.key.$2 == directHash) continue;
      // My rows: ranked by how often I hear them, not by the weight that
      // ranks them as hearing ME — proof and supersede move that one.
      final w = _decayedWeight(owner, e, now, isSelf,
          sinceHeard: true, base: isSelf ? e.finalCount.toDouble() : null);
      if (w > 0.05) {
        out.add(Candidate(entry.key.$2, w, e.tier,
            uplinkSnr: e.uplinkSnr,
            downlinkSnr: e.downlinkSnr,
            proven: true,
            heard: true,
            finalCount: e.finalCount,
            penultimateCount: e.penultimateCount,
            provenCount: e.provenCount,
            provenAt: e.provenAt,
            lastSeen: e.lastHeardAt ?? e.lastSeen,
            isSelf: isSelf));
      }
    }
    out.sort((a, b) => b.weight.compareTo(a.weight));
    return out;
  }

  /// A fresh sighting of the contact through one repeater makes every
  /// other doorstep of theirs less likely to be where they are now:
  /// multiply the rest (DIRECT included) by [factor]. Proof markers and
  /// tallies stay; only the ranking weight moves.
  void supersedeContact(String owner,
      {required String except, required double factor}) {
    for (final entry in entries.entries) {
      if (entry.key.$1 != owner || entry.key.$2 == except) continue;
      entry.value.weight *= factor;
      _dirty.add(entry.key);
    }
  }

  /// They moved out of range of everything known: drop every doorstep
  /// row of theirs.
  void wipeContact(String owner) {
    for (final key in entries.keys.where((k) => k.$1 == owner).toList()) {
      removeEntry(key);
    }
  }

  /// Proven contact ingress: the last hop of a send that was delivered
  /// (ACKed) or of a path-discovery out_path — a repeater that reached
  /// them, in the direction that matters.
  void recordProvenIngress(
      String contactPubkey, String repeaterHash, int arrival) {
    _upsert(contactPubkey, repeaterHash, EvidenceTier.proven, 3.0, arrival)
      ..provenAt = arrival
      ..provenCount += 1
      ..failedSinceProof = 0;
  }

  /// EWMA so repeat measurements refine rather than overwrite.
  static double _blend(double? old, double fresh) =>
      old == null ? fresh : old * 0.6 + fresh * 0.4;

  /// Self last-hop prior: final hop of a received path (inferred tier).
  /// [downlinkSnr] is the level I heard that hop at — the reverse of
  /// what a send needs, but the only strength measurement a heard-only
  /// doorstep ever gets (ranking falls back to it).
  /// A row already proven gains no weight from being heard: its weight
  /// ranks it as a repeater that hears ME, which hearing it cannot show.
  void recordLastHop(String selfPubkey, String repeaterHash, int arrival,
      {double? downlinkSnr}) {
    final proven = entries[(selfPubkey, repeaterHash)]?.proven ?? false;
    _noteSelfRow(selfPubkey, repeaterHash, arrival);
    final e = _upsert(selfPubkey, repeaterHash, EvidenceTier.inferred,
        proven ? 0.0 : 1.0, arrival);
    _capSelf(e);
    e
      ..finalCount += 1
      ..lastHeardAt = arrival;
    _noteSelfAlive(arrival);
    if (downlinkSnr != null) e.downlinkSnr = _blend(e.downlinkSnr, downlinkSnr);
  }

  /// Hub-signature counter: repeater seen second-to-last.
  void recordPenultimate(String selfPubkey, String repeaterHash) {
    final entry = entries[(selfPubkey, repeaterHash)];
    if (entry != null) {
      entry.penultimateCount++;
      _dirty.add((selfPubkey, repeaterHash));
    }
  }

  /// Direct reception of a contact (empty path). Hearing them proves
  /// they reach me; [proven] is a delivered empty-path send, which
  /// proves I reach them.
  void recordDirect(String contactPubkey, int arrival, {bool proven = false}) {
    final e =
        _upsert(contactPubkey, directHash, EvidenceTier.direct, 3.0, arrival);
    if (proven) {
      e.provenAt = arrival;
      e.provenCount++;
    }
  }

  /// Proven egress upgrade (delivered send or trace through this first
  /// hop). A trace also measures the link: [uplinkSnr] is how the hop
  /// heard ME, [downlinkSnr] how I heard it. [supersede]: an echo of my
  /// flood — every doorstep had the same chance to echo it, so the
  /// silent ones count against (a direct send or trace only ever tries
  /// one). [floodProven]: the hop forwarded a flood of mine, learned
  /// from a PATH reply rather than its echo; it marks the row as one whose
  /// silence on later floods counts, without superseding anyone now
  /// (field 2026-10-17: rows proven only by PATH replies were immune to
  /// every later supersede and held routes 40 km from home).
  void recordProvenEgress(String selfPubkey, String repeaterHash, int arrival,
      {double? uplinkSnr,
      double? downlinkSnr,
      bool supersede = false,
      bool floodProven = false}) {
    _undoSlash((selfPubkey, repeaterHash), arrival);
    final e = _proveSelf(selfPubkey, repeaterHash, 3.0, arrival);
    if (supersede || floodProven) e.floodProvenAt = arrival;
    if (uplinkSnr != null) e.uplinkSnr = _blend(e.uplinkSnr, uplinkSnr);
    if (downlinkSnr != null) e.downlinkSnr = _blend(e.downlinkSnr, downlinkSnr);
    if (supersede) _supersedeStaleSelf(selfPubkey, arrival);
  }

  /// A proof that this hop hears me. The first proof starts from the
  /// proof weight: the hearing tally on an unproven row measures how
  /// well I hear it, which says nothing about how well it hears me.
  IngressEntry _proveSelf(
      String selfPubkey, String repeaterHash, double weight, int arrival) {
    final firstProof = entries[(selfPubkey, repeaterHash)]?.provenAt == null;
    _noteSelfRow(selfPubkey, repeaterHash, arrival);
    (_selfProofTimes[repeaterHash] ??= [])
      ..add(arrival)
      ..removeWhere((t) => arrival - t > Duration.millisecondsPerHour);
    final e =
        _upsert(selfPubkey, repeaterHash, EvidenceTier.proven, weight, arrival)
          ..provenAt = arrival
          ..provenCount += 1
          ..failedSinceProof = 0;
    if (firstProof) e.weight = weight;
    _capSelf(e);
    _noteSelfAlive(arrival);
    return e;
  }

  void _capSelf(IngressEntry e) {
    if (e.weight > config.selfWeightCap) e.weight = config.selfWeightCap;
  }

  bool _inSelfEpoch(String selfPubkey, int arrival) {
    final last = _lastSelfSupersedeMillis[selfPubkey];
    return last != null &&
        arrival - last < config.slashEpochMinutes * 60 * 1000;
  }

  /// A doorstep of mine just proved it hears me: every other proven one
  /// that has not proved anything for [PathGraphConfig.selfProofStaleMinutes]
  /// is less likely to hear me where I am now. Once per slash epoch, so
  /// the several echoes of one send count as one event; a doorstep that
  /// proves inside the same epoch is restored ([_undoSlash]).
  void _supersedeStaleSelf(String selfPubkey, int arrival) {
    if (_inSelfEpoch(selfPubkey, arrival)) return;
    _lastSelfSupersedeMillis[selfPubkey] = arrival;
    _slashedThisEpoch.removeWhere((k, _) => k.$1 == selfPubkey);
    final staleMs = config.selfProofStaleMinutes * 60 * 1000;
    for (final entry in entries.entries) {
      if (entry.key.$1 != selfPubkey) continue;
      final e = entry.value;
      final provenAt = e.provenAt;
      if (provenAt == null || arrival - provenAt <= staleMs) continue;
      // Never echoed a flood of mine: its silence now is no evidence.
      if (e.floodProvenAt == null) continue;
      _slashedThisEpoch[entry.key] = e.weight;
      e.weight =
          math.min(e.weight, config.selfWeightCap) * config.selfSupersedeFactor;
      _dirty.add(entry.key);
    }
  }

  void _undoSlash((String, String) key, int arrival) {
    final before = _slashedThisEpoch.remove(key);
    final e = entries[key];
    if (before == null || e == null || !_inSelfEpoch(key.$1, arrival)) return;
    e.weight = before;
  }

  /// Discover results: proven refresh always; supersede/slash only in a
  /// failure episode, epoch-limited and floored, never on empty results.
  void applyDiscover(String selfPubkey,
      List<({String hash, double? snr, double? rxSnr})> responses, int arrival,
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
      _undoSlash((selfPubkey, r.hash), arrival);
      // It answered: it heard us.
      final entry =
          _proveSelf(selfPubkey, r.hash, 1.0 + 2.0 * quality, arrival);
      // Keep the measured dB, both directions — a Discover exchange is
      // the best-measured link we ever get (fresh, bidirectional, and
      // it's the first hop).
      if (r.snr != null) entry.uplinkSnr = _blend(entry.uplinkSnr, r.snr!);
      if (r.rxSnr != null) {
        entry.downlinkSnr = _blend(entry.downlinkSnr, r.rxSnr!);
      }
    }
    _supersedeStaleSelf(selfPubkey, arrival);
  }

  /// [sinceProof]: age a proven row of mine from its last proof, not
  /// from the last time I heard it — the clock for ranking it as a
  /// repeater that hears me. Hearing still refreshes the heard list.
  /// [base] replaces the stored weight.
  double _decayedWeight(String owner, IngressEntry e, int now, bool isSelf,
      {bool sinceProof = false, bool sinceHeard = false, double? base}) {
    // Proven egress (Discover, delivered send, trace) is a measurement,
    // not a guess — it outlives an inferred last-hop tally.
    final provenBoost = (isSelf && e.tier != EvidenceTier.inferred)
        ? config.egressProvenDecayFactor
        : 1.0;
    final halfLifeMs = isSelf
        ? config.egressHalfLifeMinutes * provenBoost * 60 * 1000
        : config.ingressHalfLifeHours * 60 * 60 * 1000;
    // Rows saved before the cap existed are capped on read.
    final raw = base ?? e.weight;
    final weight = isSelf ? math.min(raw, config.selfWeightCap) : raw;
    final since = sinceProof
        ? (e.provenAt ?? e.lastSeen)
        : sinceHeard
            ? (e.lastHeardAt ?? e.lastSeen)
            : e.lastSeen;
    final dt = now - since;
    if (dt <= 0) return weight;
    return weight * math.pow(0.5, dt / halfLifeMs);
  }

  /// Ranked candidates for an owner. Self rows get fast decay and the
  /// hub demotion (penultimate ≫ final, vetoed by proven tier).
  /// [provenOnly] keeps rows proven in the sending direction.
  List<Candidate> candidatesFor(String owner, int now,
      {required bool isSelf, bool provenOnly = false}) {
    final out = <Candidate>[];
    for (final entry in entries.entries) {
      if (entry.key.$1 != owner) continue;
      final e = entry.value;
      if (provenOnly && !e.proven) continue;
      var w =
          _decayedWeight(owner, e, now, isSelf, sinceProof: isSelf && e.proven);
      if (isSelf && e.tier == EvidenceTier.inferred) {
        final appearances = e.finalCount + e.penultimateCount;
        if (appearances > 0) {
          w *= (e.finalCount / appearances); // hub signature demotion
        }
      }
      if (w > 0.05) {
        out.add(Candidate(entry.key.$2, w, e.tier,
            uplinkSnr: e.uplinkSnr,
            downlinkSnr: e.downlinkSnr,
            proven: e.proven,
            heard: e.finalCount > 0,
            finalCount: e.finalCount,
            penultimateCount: e.penultimateCount,
            provenCount: e.provenCount,
            provenAt: e.provenAt,
            lastSeen: e.lastSeen,
            isSelf: isSelf,
            failedSinceProof: e.failedSinceProof));
      }
    }
    out.sort((a, b) => b.weight.compareTo(a.weight));
    return out;
  }

  /// Fresh direct-reception evidence for this contact? With
  /// [provenOnly], only when an empty-path send to them was delivered.
  /// A packet of theirs that came only through a repeater after it ends
  /// direct at once (see [PathGraphConfig.directFreshMinutes]).
  bool hasFreshDirect(String contactPubkey, int now,
      {bool provenOnly = false}) {
    final e = entries[(contactPubkey, directHash)];
    if (e == null) return false;
    if (provenOnly && !e.proven) return false;
    if (now - e.lastSeen > config.directFreshMinutes * 60 * 1000) return false;
    final relayed = _lastRelayed[contactPubkey];
    return relayed == null ||
        relayed - e.lastSeen <= config.relayedCopyGraceSeconds * 1000;
  }

  void recordRelayedSighting(String contactPubkey, int arrival) =>
      _lastRelayed[contactPubkey] = arrival;

  void markDirty((String, String) key) => _dirty.add(key);

  /// Retention removal. The row leaves memory now and the database on
  /// the next flush.
  void removeEntry((String, String) key) {
    if (entries.remove(key) == null) return;
    _dirty.remove(key);
    _deleted.add(key);
  }

  void ingestContact(String pubkey, String name, int arrival) {
    // The app re-feeds its whole contact list on every change; only a new
    // contact or a new name needs writing.
    if (knownContacts[pubkey]?.name == name) return;
    knownContacts[pubkey] = (name: name, lastRefreshed: arrival);
    _dirtyContacts.add(pubkey);
  }

  /// Unique-name lookup for channel attribution (null if 0 or 2+ match).
  /// Case and surrounding whitespace are ignored, as the app's own
  /// channel-sender matching does.
  String? contactByUniqueName(String name) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    String? found;
    for (final entry in knownContacts.entries) {
      if (entry.value.name.trim().toLowerCase() == wanted) {
        if (found != null) return null;
        found = entry.key;
      }
    }
    return found;
  }

  /// Session restore: drop everything, in memory and on disk.
  Future<void> clear() async {
    entries.clear();
    knownContacts.clear();
    _dirty.clear();
    _deleted.clear();
    _dirtyContacts.clear();
    _lastSlashMillis.clear();
    _lastSelfSupersedeMillis.clear();
    _slashedThisEpoch.clear();
    _selfProofTimes.clear();
    lastNewSelfRowAt = null;
    await _db.delete(_db.contactIngress).go();
    await _db.delete(_db.knownContacts).go();
  }

  void markAllDirty() {
    _dirty.addAll(entries.keys);
    _dirtyContacts.addAll(knownContacts.keys);
  }

  /// Folds ingress rows keyed by a wider-than-bucket repeater hash into
  /// their bucket (same healing rule as the graph store; DIRECT is the
  /// one legitimate non-hash key). Owners are folded to lowercase too:
  /// adverts once filed contacts under an uppercase key nothing queried.
  void normalizeKeys() {
    final hexWidth = hashWidthBytes * 2;
    bool wide(String hash) => hash.length > hexWidth && hash != directHash;
    for (final key in entries.keys
        .where((k) => wide(k.$2) || k.$1 != k.$1.toLowerCase())
        .toList()) {
      final ghost = entries.remove(key)!;
      _deleted.add(key);
      final bucket = (
        key.$1.toLowerCase(),
        wide(key.$2) ? key.$2.substring(0, hexWidth) : key.$2
      );
      final target = entries[bucket];
      if (target == null) {
        entries[bucket] = ghost;
      } else {
        target
          ..weight += ghost.weight
          ..finalCount += ghost.finalCount
          ..penultimateCount += ghost.penultimateCount
          ..provenCount += ghost.provenCount
          ..uplinkSnr ??= ghost.uplinkSnr
          ..downlinkSnr ??= ghost.downlinkSnr;
        if ((ghost.provenAt ?? 0) > (target.provenAt ?? 0)) {
          target.provenAt = ghost.provenAt;
        }
        if ((ghost.floodProvenAt ?? 0) > (target.floodProvenAt ?? 0)) {
          target.floodProvenAt = ghost.floodProvenAt;
        }
        if ((ghost.lastHeardAt ?? 0) > (target.lastHeardAt ?? 0)) {
          target.lastHeardAt = ghost.lastHeardAt;
        }
        target.failedSinceProof =
            math.max(target.failedSinceProof, ghost.failedSinceProof);
        if (ghost.lastSeen > target.lastSeen) target.lastSeen = ghost.lastSeen;
        if (ghost.tier.index > target.tier.index) target.tier = ghost.tier;
      }
      _dirty.add(bucket);
    }
    for (final pk in knownContacts.keys
        .where((k) => k != k.toLowerCase())
        .toList()) {
      final ghost = knownContacts.remove(pk)!;
      final lower = pk.toLowerCase();
      final kept = knownContacts[lower];
      if (kept == null || ghost.lastRefreshed > kept.lastRefreshed) {
        knownContacts[lower] = ghost;
      }
      _dirtyContacts
        ..add(pk)
        ..add(lower);
    }
  }

  Future<void> load() async {
    for (final row in await _db.select(_db.contactIngress).get()) {
      entries[(row.ownerPubkey, row.repeaterHash)] = IngressEntry(
        weight: row.weight,
        lastSeen: row.lastSeen,
        tier: EvidenceTier.values.byName(row.evidence),
      )
        ..provenAt = row.provenAt
        ..uplinkSnr = row.uplinkSnr
        ..downlinkSnr = row.downlinkSnr
        ..finalCount = row.finalCount
        ..penultimateCount = row.penultimateCount
        ..provenCount = row.provenCount
        ..floodProvenAt = row.floodProvenAt
        ..lastHeardAt = row.lastHeardAt
        ..failedSinceProof = row.failedSinceProof;
    }
    for (final row in await _db.select(_db.knownContacts).get()) {
      knownContacts[row.contactPubkey] =
          (name: row.name, lastRefreshed: row.lastRefreshed);
    }
  }

  Future<void> flush() async {
    if (_dirty.isEmpty && _dirtyContacts.isEmpty && _deleted.isEmpty) return;
    final dirty = _dirty.toList();
    final dirtyContacts = _dirtyContacts.toList();
    final deleted = _deleted.toList();
    _dirty.clear();
    _dirtyContacts.clear();
    _deleted.clear();

    await _db.batch((batch) {
      // Deletes first: a row removed by a sweep and re-recorded before
      // the flush must end up inserted, not dropped.
      for (final key in deleted) {
        batch.deleteWhere(
            _db.contactIngress,
            (t) =>
                t.ownerPubkey.equals(key.$1) & t.repeaterHash.equals(key.$2));
      }
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
            provenAt: Value(e.provenAt),
            uplinkSnr: Value(e.uplinkSnr),
            downlinkSnr: Value(e.downlinkSnr),
            finalCount: Value(e.finalCount),
            penultimateCount: Value(e.penultimateCount),
            provenCount: Value(e.provenCount),
            floodProvenAt: Value(e.floodProvenAt),
            lastHeardAt: Value(e.lastHeardAt),
            failedSinceProof: Value(e.failedSinceProof),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final pk in dirtyContacts) {
        final c = knownContacts[pk];
        if (c == null) {
          // Folded into its lowercase key by normalizeKeys.
          batch.deleteWhere(
              _db.knownContacts, (t) => t.contactPubkey.equals(pk));
          continue;
        }
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
