import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'db/database.dart';
import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';
import 'retention.dart';
import 'search.dart';

export 'estimator.dart' show Estimator, PathGraphConfig;
export 'evidence.dart' show Candidate, EvidenceTier, directHash;
export 'graph_store.dart' show EdgeState, NodeState, NodeSource;
export 'retention.dart' show RetentionPolicy, RetentionReport;

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
  const DiscoverResponse(
      {required this.repeaterHash, this.uplinkSnr, this.rxSnr});

  /// 4-hex 2-byte hash bucket.
  final String repeaterHash;

  /// dB at which the repeater heard OUR request (control payload byte
  /// 1) — the direction that matters for sending.
  final double? uplinkSnr;

  /// dB at which WE heard the response (frame header) — the reverse
  /// direction of the same exchange.
  final double? rxSnr;
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
        _estimator = Estimator(config) {
    _store = GraphStore(_db);
    _evidence = EvidenceStore(_db, config);
  }

  final PathGraphDatabase _db;
  final DateTime Function() _now;
  Estimator _estimator;

  Estimator get estimator => _estimator;
  PathGraphConfig get config => _estimator.config;

  /// Live retune (β slider, thresholds). Affects routing immediately;
  /// stored evidence is untouched.
  void updateConfig(PathGraphConfig config) {
    _estimator = Estimator(config);
    _evidence.config = config;
  }
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
      [
        for (final r in responses)
          (hash: r.repeaterHash, snr: r.uplinkSnr, rxSnr: r.rxSnr)
      ],
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

  /// Trace result: top-grade evidence — the only source of middle-hop
  /// SNR. [hops] are 2-byte hash hex in traversal order; [snrs][i] is
  /// the level at which hops[i] heard the *previous* transmission (so
  /// snrs[0] is my first hop hearing ME → proven egress). Each hop pair
  /// gets measuredSnr plus an attempt-counted success. Round-trip paths
  /// (A,B,A) fill the reverse edges by the same rule, no special case.
  void observeTrace(List<String> hops, List<double> snrs) {
    if (hops.isEmpty) return;
    final arrival = _arrivalMillis;
    final self = _selfPubkey;

    if (self != null && snrs.isNotEmpty) {
      _evidence.recordProvenEgress(self, hops[0].toUpperCase(), arrival);
    }
    for (var i = 1; i < hops.length; i++) {
      final from = hops[i - 1].toUpperCase();
      final to = hops[i].toUpperCase();
      final edge = _store.edges
          .putIfAbsent((from, to), () => EdgeState(source: 'trace'));
      if (i < snrs.length) {
        // EWMA so repeated traces refine rather than overwrite.
        edge.measuredSnr = edge.measuredSnr == null
            ? snrs[i]
            : edge.measuredSnr! * 0.6 + snrs[i] * 0.4;
      }
      edge.s++;
      edge.n++;
      edge.lastObserved = arrival;
      _store.markEdgeDirty(from, to);
      _store.nodeFor(to, NodeSource.observed).lastHeard = arrival;
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
  List<RouteResult> findAlternatives(String contactPubkey, {int count = 3}) =>
      _alternatives(
          (now) => _evidence.candidatesFor(contactPubkey, now, isSelf: false),
          count);

  /// Alternatives with a repeater itself as the destination.
  List<RouteResult> findAlternativesToRepeater(String repeaterHash,
          {int count = 3}) =>
      _alternatives(
          (_) => [
                Candidate(
                    repeaterHash.toUpperCase(), 4.0, EvidenceTier.proven)
              ],
          count);

  List<RouteResult> _alternatives(
      List<Candidate> Function(int now) ingressFor, int count) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const [];
    final egress = _evidence.candidatesFor(self, now, isSelf: true);
    final ingress = ingressFor(now);
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

  /// Contacts that have at least one ingress entry — i.e. targets
  /// `findPath` can actually reason about (UI/debug).
  List<String> contactsWithIngress() {
    final self = _selfPubkey;
    return _evidence.entries.keys
        .map((k) => k.$1)
        .where((owner) => owner != self)
        .toSet()
        .toList();
  }

  /// Ranked ingress candidates for a contact (UI/debug).
  List<Candidate> ingressCandidates(String contactPubkey) =>
      _evidence.candidatesFor(contactPubkey, _arrivalMillis, isSelf: false);

  /// Staleness sweep: forget idle unconfirmed hearsay past the policy's
  /// age gate, drop stale position tags (row survives, coordinate goes),
  /// and enforce the growth caps. Infrastructure — attempt-counted or
  /// imported edges — is never aged out by idleness. Cheap; run on
  /// connect and daily. The report is for the UI: silent deletion of a
  /// user's learned map would be the wrong kind of surprise.
  RetentionReport sweepStale(
      {RetentionPolicy policy = const RetentionPolicy()}) {
    final report = Retention(_store, _evidence, _estimator)
        .sweep(_arrivalMillis, policy);
    if (!report.isEmpty) _scheduleFlush();
    return report;
  }

  /// The privacy escape hatch ("Clear learned data"): wipes everything
  /// this radio learned — observed nodes/edges, local counters, contact
  /// ingress, position tags. Imported priors survive; they are removed
  /// separately by region. Flushes immediately.
  Future<void> clearLearnedData() async {
    Retention(_store, _evidence, _estimator).clearLearnedData();
    _observationsApplied = 0;
    _dropped1Byte = 0;
    await flush();
  }

  static const _maxImportNodes = 20000;
  static const _maxImportLinks = 100000;

  static double _haversineKm(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0, p = math.pi / 180;
    final dLa = (la2 - la1) * p, dLo = (lo2 - lo1) * p;
    final a = math.sin(dLa / 2) * math.sin(dLa / 2) +
        math.cos(la1 * p) * math.cos(la2 * p) *
            math.sin(dLo / 2) * math.sin(dLo / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static final _hashPattern = RegExp(r'^[0-9A-F]{4}$');

  static int? _millisFromIso(Object? value) =>
      value is String ? DateTime.tryParse(value)?.millisecondsSinceEpoch : null;

  /// meshtrax-graph-v2 node-link document → the import prior layer.
  ///
  /// v2 is a true directed graph: A→B and B→A are separate links with
  /// their own measurements, and neither is ever derived from the other.
  /// A document that only knows one direction seeds only that direction,
  /// so an imported link cannot on its own satisfy the bidirectional
  /// route contract — which is the whole point of dropping v1, where one
  /// symmetric Corescope SNR was copied into both directions and made
  /// unproven links look routable.
  ///
  /// Node ids are 2-byte hash buckets (4 hex chars); the full pubkey
  /// rides alongside when the exporter knew it. Local evidence (s/n,
  /// traffic, measured SNR, ingress) is never touched, and re-importing
  /// replaces the prior wholesale rather than accumulating.
  ///
  /// Throws [FormatException] on an unknown format or cap violation.
  Future<void> importGraph(
    Map<String, dynamic> document, {
    GeoPosition? homePosition,
    double? radiusKm,
  }) async {
    if (document['format'] != 'meshtrax-graph-v2') {
      throw FormatException(
          'not a meshtrax-graph-v2 document (got ${document['format']})');
    }
    if (document['directed'] == false) {
      throw const FormatException(
          'undirected documents are not importable — one SNR for both '
          'directions is not a measurement of either');
    }
    final nodes = (document['nodes'] as List?) ?? const [];
    final links = (document['links'] as List?) ?? const [];
    if (nodes.length > _maxImportNodes || links.length > _maxImportLinks) {
      throw const FormatException('import exceeds size caps');
    }
    final meta = (document['graph'] as Map?) ?? const {};
    final region = meta['region_hint'] as String?;

    final kept = <String>{}; // hash buckets that survived the geo filter
    for (final raw in nodes) {
      final node = raw as Map;
      final hash = (node['id'] as String?)?.toUpperCase();
      if (hash == null || !_hashPattern.hasMatch(hash)) continue;
      final lat = (node['lat'] as num?)?.toDouble();
      final lon = (node['lon'] as num?)?.toDouble();
      // Geo scope: belt-and-suspenders at 2-byte; position-less kept.
      if (homePosition != null && radiusKm != null &&
          lat != null && lon != null &&
          _haversineKm(homePosition.lat, homePosition.lon, lat, lon) >
              radiusKm) {
        continue;
      }
      kept.add(hash);
      _store.enrichNode(hash, NodeSource.imported,
          name: node['name'] as String?,
          role: node['role'] as String?,
          lat: lat,
          lon: lon,
          pubkey: node['pubkey'] as String?,
          region: region);
    }

    for (final raw in links) {
      final link = raw as Map;
      final from = (link['source'] as String?)?.toUpperCase();
      final to = (link['target'] as String?)?.toUpperCase();
      if (from == null || to == null) continue;
      if (!kept.contains(from) || !kept.contains(to)) continue;
      final edge = _store.edges
          .putIfAbsent((from, to), () => EdgeState(source: 'imported'));
      // Replace, never accumulate: this is one collector's current view.
      edge.importedSnr = (link['measured_snr'] as num?)?.toDouble();
      edge.importedObservations = (link['observations'] as num?)?.toInt() ?? 0;
      edge.importedDelivered = (link['delivered'] as num?)?.toInt() ?? 0;
      edge.importedAttempts = (link['attempts'] as num?)?.toInt() ?? 0;
      edge.importedLastObserved = _millisFromIso(link['last_observed']);
      _store.markEdgeDirty(from, to);
    }

    await _db.into(_db.graphMeta).insertOnConflictUpdate(
        GraphMetaCompanion.insert(
            key: 'import:${region ?? "unknown"}',
            value: '${meta['generated_at']}'));
    _scheduleFlush();
  }

  static String _isoFromMillis(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)
          .toIso8601String();

  /// This radio's observations as a meshtrax-graph-v2 document, ready to
  /// hand to another collector.
  ///
  /// **Repeater topology only.** The export carries directed links
  /// between forwarding nodes and the public advert metadata of the
  /// nodes those links touch — nothing else. Contact ingress lists are
  /// never exported (they are a position-tagged log of who I talked to
  /// and where I stood), nor is the contact mirror, nor my own identity
  /// or doorstep. A node appears only if a link references it, so the
  /// document cannot name a node I merely heard about.
  ///
  /// Only locally observed edges are exported. An imported prior belongs
  /// to the collector that measured it and is not laundered through my
  /// file — which also keeps a two-way exchange from feeding each side
  /// its own data back. (Multi-collector merge is a separate problem,
  /// deliberately deferred.)
  Map<String, dynamic> exportGraph({
    String? regionHint,
    String collector = 'meshtrax',
  }) {
    final links = <Map<String, dynamic>>[];
    final referenced = <String>{};

    for (final entry in _store.edges.entries) {
      final e = entry.value;
      final local = e.obsCount > 0 || e.n > 0 || e.measuredSnr != null;
      if (!local) continue;
      final (from, to) = entry.key;
      referenced
        ..add(from)
        ..add(to);
      links.add({
        'source': from,
        'target': to,
        'observations': e.obsCount,
        if (e.measuredSnr != null) 'measured_snr': e.measuredSnr,
        'trace_confirmed': e.measuredSnr != null,
        if (e.n > 0) 'delivered': e.s,
        if (e.n > 0) 'attempts': e.n,
        if (e.lastObserved != null)
          'last_observed': _isoFromMillis(e.lastObserved!),
      });
    }

    final nodes = <Map<String, dynamic>>[];
    for (final hash in referenced.toList()..sort()) {
      final n = _store.nodes[hash];
      nodes.add({
        'id': hash,
        if (n?.pubkey != null) 'pubkey': n!.pubkey,
        if (n?.name != null) 'name': n!.name,
        if (n?.role != null) 'role': n!.role,
        if (n?.lat != null) 'lat': n!.lat,
        if (n?.lon != null) 'lon': n!.lon,
        if (n?.lastHeard != null) 'last_heard': _isoFromMillis(n!.lastHeard!),
      });
    }

    return {
      'format': 'meshtrax-graph-v2',
      'directed': true,
      'multigraph': false,
      'graph': {
        'generated_at': _isoFromMillis(_arrivalMillis),
        'collector': collector,
        if (regionHint != null) 'region_hint': regionHint,
        'hash_width': 2,
      },
      'nodes': nodes,
      'links': links,
    };
  }

  static const _sessionFormat = 'meshtrax-path-graph-session-v1';

  /// A complete private checkpoint of everything the module holds.
  ///
  /// This is NOT [exportGraph]. Export is the shareable file and
  /// withholds contact ingress, the contact mirror, my identity and my
  /// doorstep by design. A session carries all of it, plus imported
  /// priors and the in-memory hub counters, so a restore lands exactly
  /// where the save left off. Keep it local — sharing one hands over a
  /// position-tagged log of who this radio talks to.
  ///
  /// Timestamps are raw arrival millis, not wire times: a session is a
  /// machine checkpoint, and converting them would only lose precision.
  ///
  /// Ordinary restarts do not need this — state persists in the
  /// database. It exists to checkpoint before an experiment and roll
  /// back after one.
  Map<String, dynamic> saveSession() {
    return {
      'format': _sessionFormat,
      'private': true,
      'saved_at': _isoFromMillis(_arrivalMillis),
      'self': {'pubkey': _selfPubkey, 'stride': _selfStride},
      'counters': {
        'observations_applied': _observationsApplied,
        'dropped_1byte': _dropped1Byte,
      },
      'nodes': [
        for (final e in _store.nodes.entries)
          {
            'hash': e.key,
            'source': e.value.source.name,
            if (e.value.name != null) 'name': e.value.name,
            if (e.value.role != null) 'role': e.value.role,
            if (e.value.lat != null) 'lat': e.value.lat,
            if (e.value.lon != null) 'lon': e.value.lon,
            if (e.value.lastHeard != null) 'last_heard': e.value.lastHeard,
            if (e.value.region != null) 'region': e.value.region,
            if (e.value.pubkey != null) 'pubkey': e.value.pubkey,
          }
      ],
      'edges': [
        for (final e in _store.edges.entries)
          {
            'from': e.key.$1,
            'to': e.key.$2,
            'source': e.value.source,
            's': e.value.s,
            'n': e.value.n,
            'traffic_weight': e.value.trafficWeight,
            'obs_count': e.value.obsCount,
            if (e.value.lastObserved != null)
              'last_observed': e.value.lastObserved,
            if (e.value.measuredSnr != null)
              'measured_snr': e.value.measuredSnr,
            if (e.value.importedSnr != null)
              'imported_snr': e.value.importedSnr,
            'imported_observations': e.value.importedObservations,
            'imported_delivered': e.value.importedDelivered,
            'imported_attempts': e.value.importedAttempts,
            if (e.value.importedLastObserved != null)
              'imported_last_observed': e.value.importedLastObserved,
          }
      ],
      'ingress': [
        for (final e in _evidence.entries.entries)
          {
            'owner': e.key.$1,
            'repeater': e.key.$2,
            'weight': e.value.weight,
            'last_seen': e.value.lastSeen,
            'tier': e.value.tier.name,
            if (e.value.observedLat != null) 'lat': e.value.observedLat,
            if (e.value.observedLon != null) 'lon': e.value.observedLon,
            if (e.value.uplinkSnr != null) 'uplink_snr': e.value.uplinkSnr,
            if (e.value.downlinkSnr != null)
              'downlink_snr': e.value.downlinkSnr,
            'final_count': e.value.finalCount,
            'penultimate_count': e.value.penultimateCount,
          }
      ],
      'contacts': [
        for (final e in _evidence.knownContacts.entries)
          {
            'pubkey': e.key,
            'name': e.value.name,
            'last_refreshed': e.value.lastRefreshed,
          }
      ],
    };
  }

  /// Restores a [saveSession] checkpoint, **replacing** everything the
  /// module currently holds — memory and database both. Throws
  /// [FormatException] on anything else.
  Future<void> loadSession(Map<String, dynamic> document) async {
    if (document['format'] != _sessionFormat) {
      throw FormatException(
          'not a $_sessionFormat document (got ${document['format']})');
    }
    _flushTimer?.cancel();
    _flushTimer = null;
    await _store.clear();
    await _evidence.clear();

    for (final raw in (document['nodes'] as List?) ?? const []) {
      final n = raw as Map;
      _store.nodes[n['hash'] as String] = NodeState(
        source: NodeSource.values.byName(n['source'] as String),
        name: n['name'] as String?,
        role: n['role'] as String?,
        lat: (n['lat'] as num?)?.toDouble(),
        lon: (n['lon'] as num?)?.toDouble(),
        lastHeard: (n['last_heard'] as num?)?.toInt(),
        region: n['region'] as String?,
        pubkey: n['pubkey'] as String?,
      );
    }
    for (final raw in (document['edges'] as List?) ?? const []) {
      final e = raw as Map;
      _store.edges[(e['from'] as String, e['to'] as String)] =
          EdgeState(source: e['source'] as String? ?? 'observed')
            ..s = (e['s'] as num?)?.toInt() ?? 0
            ..n = (e['n'] as num?)?.toInt() ?? 0
            ..trafficWeight = (e['traffic_weight'] as num?)?.toDouble() ?? 0
            ..obsCount = (e['obs_count'] as num?)?.toInt() ?? 0
            ..lastObserved = (e['last_observed'] as num?)?.toInt()
            ..measuredSnr = (e['measured_snr'] as num?)?.toDouble()
            ..importedSnr = (e['imported_snr'] as num?)?.toDouble()
            ..importedObservations =
                (e['imported_observations'] as num?)?.toInt() ?? 0
            ..importedDelivered =
                (e['imported_delivered'] as num?)?.toInt() ?? 0
            ..importedAttempts = (e['imported_attempts'] as num?)?.toInt() ?? 0
            ..importedLastObserved =
                (e['imported_last_observed'] as num?)?.toInt();
    }
    for (final raw in (document['ingress'] as List?) ?? const []) {
      final i = raw as Map;
      _evidence.entries[(i['owner'] as String, i['repeater'] as String)] =
          IngressEntry(
        weight: (i['weight'] as num).toDouble(),
        lastSeen: (i['last_seen'] as num).toInt(),
        tier: EvidenceTier.values.byName(i['tier'] as String),
        observedLat: (i['lat'] as num?)?.toDouble(),
        observedLon: (i['lon'] as num?)?.toDouble(),
      )
            ..uplinkSnr = (i['uplink_snr'] as num?)?.toDouble()
            ..downlinkSnr = (i['downlink_snr'] as num?)?.toDouble()
            ..finalCount = (i['final_count'] as num?)?.toInt() ?? 0
            ..penultimateCount = (i['penultimate_count'] as num?)?.toInt() ?? 0;
    }
    for (final raw in (document['contacts'] as List?) ?? const []) {
      final c = raw as Map;
      _evidence.knownContacts[c['pubkey'] as String] = (
        name: c['name'] as String,
        lastRefreshed: (c['last_refreshed'] as num).toInt(),
      );
    }

    final self = (document['self'] as Map?) ?? const {};
    final pubkey = self['pubkey'] as String?;
    if (pubkey != null) {
      setRadioIdentity(pubkey, (self['stride'] as num?)?.toInt() ?? 2);
    }
    final counters = (document['counters'] as Map?) ?? const {};
    _observationsApplied =
        (counters['observations_applied'] as num?)?.toInt() ?? 0;
    _dropped1Byte = (counters['dropped_1byte'] as num?)?.toInt() ?? 0;

    _store.markAllDirty();
    _evidence.markAllDirty();
    await flush();
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
