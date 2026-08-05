import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'db/database.dart';
import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';
import 'search.dart';

export 'estimator.dart' show Estimator, PathGraphConfig;
export 'evidence.dart' show Candidate, EvidenceTier, directHash;
export 'graph_store.dart' show EdgeState, NodeState, NodeSource;

/// Attribution quality of an observed path's originator.
sealed class ObservationOrigin {
  const ObservationOrigin();

  /// Sender identity cryptographically confirmed (DM decrypt, path
  /// return, signed advert).
  const factory ObservationOrigin.pubkeyConfirmed(String contactPubkey) =
      PubkeyConfirmedOrigin;

  /// Channel message whose display name matched exactly one contact.
  const factory ObservationOrigin.uniqueName(String contactPubkey) =
      UniqueNameOrigin;

  /// Unknown or ambiguous sender — edges only, no ingress attribution.
  const factory ObservationOrigin.anonymous() = AnonymousOrigin;
}

class PubkeyConfirmedOrigin extends ObservationOrigin {
  const PubkeyConfirmedOrigin(this.contactPubkey);
  final String contactPubkey;
}

class UniqueNameOrigin extends ObservationOrigin {
  const UniqueNameOrigin(this.contactPubkey);
  final String contactPubkey;
}

class AnonymousOrigin extends ObservationOrigin {
  const AnonymousOrigin();
}

/// A single repeater's answer to a zero-hop Discover.
class DiscoverResponse {
  const DiscoverResponse({required this.repeaterHash, this.uplinkSnr});

  /// 4-hex 2-byte hash bucket.
  final String repeaterHash;

  /// dB at which the repeater heard our request (response byte 1).
  final double? uplinkSnr;
}

/// Geographic position (any of the three optional sources).
class GeoPosition {
  const GeoPosition(this.lat, this.lon);
  final double lat;
  final double lon;
}

/// Why findPath returned flood — surfaced in the why-this-path UI.
enum FloodReason { noEvidence, noBidirectionalRoute, belowThreshold, overBudget }

/// The three-tier return contract: direct | bidirectional path | flood.
sealed class PathResult {
  const PathResult();

  const factory PathResult.direct() = DirectResult;
  const factory PathResult.path(Uint8List pathBytes, double estDelivery) =
      RouteResult;
  const factory PathResult.flood(FloodReason reason) = FloodResult;
}

/// Zero-hop: fresh direct-reception evidence — send with an empty path.
class DirectResult extends PathResult {
  const DirectResult();
}

/// A route over links proven in both directions. [pathBytes] is wire
/// format (2-byte hops); truncate each hop to its first byte for
/// 1-byte-mode targets.
class RouteResult extends PathResult {
  const RouteResult(this.pathBytes, this.estDelivery);
  final Uint8List pathBytes;
  final double estDelivery;
}

class FloodResult extends PathResult {
  const FloodResult(this.reason);
  final FloodReason reason;
}

/// Observation counters (graph_meta backed; snapshot for UI/debug).
class PathGraphCounters {
  const PathGraphCounters({
    required this.observationsApplied,
    required this.dropped1Byte,
  });

  final int observationsApplied;
  final int dropped1Byte;
}

/// The module. Push-in, never read-out: this API is the complete
/// inventory of everything the module will ever know.
class PathGraph {
  PathGraph(
    QueryExecutor executor, {
    DateTime Function()? now,
    PathGraphConfig config = const PathGraphConfig(),
  })  : _db = PathGraphDatabase(executor),
        _now = now ?? DateTime.now,
        estimator = Estimator(config) {
    _store = GraphStore(_db);
    _evidence = EvidenceStore(_db, config);
  }

  final PathGraphDatabase _db;
  final DateTime Function() _now;
  final Estimator estimator;
  late final GraphStore _store;
  late final EvidenceStore _evidence;

  Timer? _flushTimer;
  static const _flushDelay = Duration(seconds: 30);

  String? _selfPubkey;
  int _selfStride = 2;

  int _observationsApplied = 0;
  int _dropped1Byte = 0;

  /// Loads persisted state into the in-memory working set.
  Future<void> init() async {
    await _store.load();
    await _evidence.load();
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();
    await _db.close();
  }

  /// Persists dirty state now (also runs on a debounce after writes).
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _store.flush();
    await _evidence.flush();
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(_flushDelay, () {
      _flushTimer = null;
      _store.flush();
      _evidence.flush();
    });
  }

  int get _arrivalMillis => _now().millisecondsSinceEpoch;

  static String _hopHex(Uint8List path, int stride, int hopIndex) {
    final start = hopIndex * stride;
    final b = StringBuffer();
    for (var i = start; i < start + stride; i++) {
      b.write(path[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return b.toString();
  }

  /// Identity of the connected radio; scopes egress rows and default
  /// observation stride.
  void setRadioIdentity(String selfPubkey, int stride) {
    _selfPubkey = selfPubkey;
    _selfStride = stride;
  }

  String? get selfPubkey => _selfPubkey;
  int get selfStride => _selfStride;

  /// Any received path (already parsed by the caller — the module never
  /// touches wire frames). Rejects stride < 2 (counted, not silent).
  /// Hops wider than 2 bytes truncate losslessly into 2-byte buckets.
  /// [messageId] enables union-per-message dedup across flood variants.
  /// [lastHopHeard]: true for paths physically received over RF (their
  /// final hop is a repeater *I heard* → feeds the last-hop prior);
  /// false for payload-embedded paths (path-return contents, firmware
  /// out_paths) whose final hop proves nothing about my RX.
  void observePath(
    Uint8List pathBytes,
    int stride,
    ObservationOrigin origin, {
    double? rxSnr,
    GeoPosition? position,
    String? messageId,
    bool lastHopHeard = true,
  }) {
    final arrival = _arrivalMillis;

    // Empty path + known sender = direct reception (zero-hop evidence).
    if (pathBytes.isEmpty) {
      final contact = switch (origin) {
        PubkeyConfirmedOrigin(:final contactPubkey) => contactPubkey,
        UniqueNameOrigin(:final contactPubkey) => contactPubkey,
        AnonymousOrigin() => null,
      };
      if (contact != null) {
        _evidence.recordDirect(contact, arrival);
        _observationsApplied++;
        _scheduleFlush();
      }
      return;
    }

    if (stride < 2) {
      _dropped1Byte++;
      return;
    }
    if (pathBytes.length % stride != 0) return;

    final hopCount = pathBytes.length ~/ stride;
    for (var i = 0; i < hopCount - 1; i++) {
      _store.observeEdge(
        _hopHex(pathBytes, stride, i),
        _hopHex(pathBytes, stride, i + 1),
        arrival,
        messageId: messageId,
      );
    }
    if (hopCount == 1) {
      _store
          .nodeFor(_hopHex(pathBytes, stride, 0), NodeSource.observed)
          .lastHeard = arrival;
    }

    // Contact ingress: path[0] of traffic they originated.
    final first = _hopHex(pathBytes, stride, 0);
    switch (origin) {
      case PubkeyConfirmedOrigin(:final contactPubkey):
        _evidence.recordIngress(contactPubkey, first,
            pubkeyConfirmed: true, arrival: arrival);
      case UniqueNameOrigin(:final contactPubkey):
        _evidence.recordIngress(contactPubkey, first,
            pubkeyConfirmed: false, arrival: arrival);
      case AnonymousOrigin():
        break; // edges only
    }

    // Self egress: final hop is the last-hop prior; penultimate feeds
    // the hub-signature demotion. RF-received paths only.
    final self = _selfPubkey;
    if (self != null && lastHopHeard) {
      _evidence.recordLastHop(
          self, _hopHex(pathBytes, stride, hopCount - 1), arrival,
          lat: position?.lat, lon: position?.lon);
      if (hopCount >= 2) {
        _evidence.recordPenultimate(
            self, _hopHex(pathBytes, stride, hopCount - 2));
      }
    }

    _observationsApplied++;
    _scheduleFlush();
  }

  /// Proven egress refresh; supersede/slash only in a failure episode.
  void observeDiscoverResults(
    List<DiscoverResponse> responses, {
    GeoPosition? position,
    required bool failureEpisode,
  }) {
    final self = _selfPubkey;
    if (self == null) return;
    _evidence.applyDiscover(
      self,
      [for (final r in responses) (hash: r.repeaterHash, snr: r.uplinkSnr)],
      _arrivalMillis,
      failureEpisode: failureEpisode,
    );
    _scheduleFlush();
  }

  /// Delivery outcome for a path we sent on. Success proves every
  /// forward hop (s+1, n+1); failure is the small forward penalty (n+1
  /// only — the break can't be localized). The ACK's own route is never
  /// inferred. Uses the radio's stride ([setRadioIdentity]).
  void reportSendResult(
    Uint8List pathBytes,
    bool success, {
    int? tripTimeMs,
  }) {
    final stride = _selfStride;
    if (stride < 2 || pathBytes.isEmpty || pathBytes.length % stride != 0) {
      return;
    }
    final hopCount = pathBytes.length ~/ stride;
    final arrival = _arrivalMillis;
    for (var i = 0; i < hopCount - 1; i++) {
      final from = _hopHex(pathBytes, stride, i);
      final to = _hopHex(pathBytes, stride, i + 1);
      final edge = _store.edges.putIfAbsent(
          (from, to), () => EdgeState(source: 'observed'));
      if (success) edge.s++;
      edge.n++;
      edge.lastObserved = arrival;
      _store.markEdgeDirty(from, to);
    }
    // Delivered send proves the first hop heard us: proven egress.
    final self = _selfPubkey;
    if (success && self != null && hopCount >= 1) {
      _evidence.recordProvenEgress(
          self, _hopHex(pathBytes, stride, 0), arrival);
    }
    _scheduleFlush();
  }

  /// Repeater advert metadata enrichment (advert outranks import).
  void ingestNode(
    String hashBytes, {
    String? name,
    String? pubkey,
    double? lat,
    double? lon,
  }) {
    _store.enrichNode(
      hashBytes.toUpperCase(),
      NodeSource.advert,
      name: name,
      pubkey: pubkey,
      lat: lat,
      lon: lon,
    );
    _store.nodeFor(hashBytes.toUpperCase(), NodeSource.advert).lastHeard =
        _arrivalMillis;
    _scheduleFlush();
  }

  /// Read-only view of the working set for UI/debug rendering.
  ({Map<String, NodeState> nodes, Map<(String, String), EdgeState> edges})
      snapshot() => (
            nodes: Map.unmodifiable(_store.nodes),
            edges: Map.unmodifiable(_store.edges),
          );

  /// Contact mirror feed (full PK→name refresh on connect, add/rename).
  void ingestContact(String contactPubkey, String name,
      {GeoPosition? position}) {
    _evidence.ingestContact(contactPubkey, name, _arrivalMillis);
    _scheduleFlush();
  }

  /// Channel attribution against the module's own mirror: exactly one
  /// name match → uniqueName origin, else anonymous.
  ObservationOrigin resolveName(String name) {
    final pk = _evidence.contactByUniqueName(name);
    return pk == null
        ? const ObservationOrigin.anonymous()
        : ObservationOrigin.uniqueName(pk);
  }

  /// Best path TO a repeater itself (repeater/room login, map tap):
  /// the target is the node — no contact ingress list involved. A
  /// repeater that is also my own doorstep yields a single-hop path.
  PathResult findPathToRepeater(String repeaterHash) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const PathResult.flood(FloodReason.noEvidence);
    final egress = _evidence.candidatesFor(self, now, isSelf: true);
    if (egress.isEmpty) {
      return const PathResult.flood(FloodReason.noEvidence);
    }

    final route = PathFinder(estimator.config, estimator).search(
      egress: egress,
      ingress: [Candidate(repeaterHash.toUpperCase(), 4.0, EvidenceTier.proven)],
      edges: _store.edges,
      nowMillis: now,
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noBidirectionalRoute);
    }
    return PathResult.path(_hopsToBytes(route.hops), route.estDelivery);
  }

  static Uint8List _hopsToBytes(List<String> hops) {
    final bytes = Uint8List(hops.length * 2);
    for (var i = 0; i < hops.length; i++) {
      bytes[i * 2] = int.parse(hops[i].substring(0, 2), radix: 16);
      bytes[i * 2 + 1] = int.parse(hops[i].substring(2, 4), radix: 16);
    }
    return bytes;
  }

  /// Up to [count] genuinely divergent routes: after each find, its
  /// edges are penalized so the next search prefers different links
  /// (the retry ladder's alternative-path step, and the harness UI).
  List<RouteResult> findAlternatives(String contactPubkey, {int count = 3}) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const [];
    final egress = _evidence.candidatesFor(self, now, isSelf: true);
    final ingress =
        _evidence.candidatesFor(contactPubkey, now, isSelf: false);
    if (egress.isEmpty || ingress.isEmpty) return const [];

    final finder = PathFinder(estimator.config, estimator);
    final penalties = <(String, String), double>{};
    final results = <RouteResult>[];
    final seen = <String>{};
    for (var i = 0; i < count * 2 && results.length < count; i++) {
      final route = finder.search(
        egress: egress,
        ingress: ingress,
        edges: _store.edges,
        nowMillis: now,
        penalties: penalties,
      );
      if (route == null) break;
      final key = route.hops.join('>');
      if (seen.add(key)) {
        final bytes = Uint8List(route.hops.length * 2);
        for (var h = 0; h < route.hops.length; h++) {
          bytes[h * 2] =
              int.parse(route.hops[h].substring(0, 2), radix: 16);
          bytes[h * 2 + 1] =
              int.parse(route.hops[h].substring(2, 4), radix: 16);
        }
        results.add(RouteResult(bytes, route.estDelivery));
      }
      for (var h = 0; h < route.hops.length - 1; h++) {
        final k = (route.hops[h], route.hops[h + 1]);
        penalties[k] = (penalties[k] ?? 0) + 1.4; // ≈ ×4 in probability
      }
    }
    return results;
  }

  /// Ranked egress candidates for the connected radio (UI/debug).
  List<Candidate> egressCandidates() {
    final self = _selfPubkey;
    if (self == null) return const [];
    return _evidence.candidatesFor(self, _arrivalMillis, isSelf: true);
  }

  /// Ranked ingress candidates for a contact (UI/debug).
  List<Candidate> ingressCandidates(String contactPubkey) =>
      _evidence.candidatesFor(contactPubkey, _arrivalMillis, isSelf: false);

  static const _maxImportNodes = 20000;
  static const _maxImportLinks = 100000;

  static String _hashOfPubkey(String pubkey) =>
      pubkey.substring(0, 4).toUpperCase();

  static double _haversineKm(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0, p = math.pi / 180;
    final dLa = (la2 - la1) * p, dLo = (lo2 - lo1) * p;
    final a = math.sin(dLa / 2) * math.sin(dLa / 2) +
        math.cos(la1 * p) * math.cos(la2 * p) *
            math.sin(dLo / 2) * math.sin(dLo / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// meshtrax-graph-v1 node-link document → prior layer. Never touches
  /// local evidence (s/n, traffic, ingress); re-import is idempotent.
  /// Throws [FormatException] on unknown format or cap violations.
  Future<void> importGraph(
    Map<String, dynamic> document, {
    GeoPosition? homePosition,
    double? radiusKm,
  }) async {
    if (document['format'] != 'meshtrax-graph-v1' ||
        document['directed'] != true) {
      throw const FormatException('not a meshtrax-graph-v1 document');
    }
    final nodes = (document['nodes'] as List?) ?? const [];
    final links = (document['links'] as List?) ?? const [];
    if (nodes.length > _maxImportNodes || links.length > _maxImportLinks) {
      throw const FormatException('import exceeds size caps');
    }
    final meta = (document['graph'] as Map?) ?? const {};
    final region = meta['region'] as String?;

    final kept = <String, String>{}; // pubkey → hash bucket
    for (final raw in nodes) {
      final node = raw as Map;
      final pubkey = node['id'] as String?;
      if (pubkey == null || pubkey.length < 4) continue;
      final lat = (node['lat'] as num?)?.toDouble();
      final lon = (node['lon'] as num?)?.toDouble();
      // Geo scope: belt-and-suspenders at 2-byte; position-less kept.
      if (homePosition != null && radiusKm != null &&
          lat != null && lon != null &&
          _haversineKm(homePosition.lat, homePosition.lon, lat, lon) >
              radiusKm) {
        continue;
      }
      final hash = _hashOfPubkey(pubkey);
      kept[pubkey] = hash;
      _store.enrichNode(hash, NodeSource.imported,
          name: node['name'] as String?,
          role: node['role'] as String?,
          lat: lat,
          lon: lon,
          pubkey: pubkey,
          region: region);
    }

    void seedPrior(String from, String to, double? score, double? snr) {
      final edge = _store.edges
          .putIfAbsent((from, to), () => EdgeState(source: 'imported'));
      edge.importedScore = score; // replace, never accumulate
      edge.avgSnr = snr;
      _store.markEdgeDirty(from, to);
    }

    for (final raw in links) {
      final link = raw as Map;
      final from = kept[link['source']];
      final to = kept[link['target']];
      if (from == null || to == null) continue;
      final score = (link['score'] as num?)?.toDouble();
      final snr = (link['avg_snr'] as num?)?.toDouble();
      seedPrior(from, to, score, snr);
      if (link['bidirectional'] == true) seedPrior(to, from, score, snr);
    }

    await _db.into(_db.graphMeta).insertOnConflictUpdate(
        GraphMetaCompanion.insert(
            key: 'import:${region ?? "unknown"}',
            value: '${meta['generated_at']}'));
    _scheduleFlush();
  }

  /// Best path to this contact: direct | bidirectional route | flood.
  PathResult findPath(String contactPubkey) {
    final now = _arrivalMillis;

    // Tier 1: fresh direct-reception evidence → empty path wins.
    if (_evidence.hasFreshDirect(contactPubkey, now)) {
      return const PathResult.direct();
    }

    // Tier 2: bidirectional route over candidate lists.
    final self = _selfPubkey;
    if (self == null) return const PathResult.flood(FloodReason.noEvidence);
    final egress = _evidence.candidatesFor(self, now, isSelf: true);
    final ingress =
        _evidence.candidatesFor(contactPubkey, now, isSelf: false);
    if (egress.isEmpty || ingress.isEmpty) {
      return const PathResult.flood(FloodReason.noEvidence);
    }

    final route = PathFinder(estimator.config, estimator).search(
      egress: egress,
      ingress: ingress,
      edges: _store.edges,
      nowMillis: now,
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noBidirectionalRoute);
    }

    final bytes = Uint8List(route.hops.length * 2);
    for (var i = 0; i < route.hops.length; i++) {
      bytes[i * 2] = int.parse(route.hops[i].substring(0, 2), radix: 16);
      bytes[i * 2 + 1] = int.parse(route.hops[i].substring(2, 4), radix: 16);
    }
    return PathResult.path(bytes, route.estDelivery);
  }

  PathGraphCounters get counters => PathGraphCounters(
        observationsApplied: _observationsApplied,
        dropped1Byte: _dropped1Byte,
      );
}
