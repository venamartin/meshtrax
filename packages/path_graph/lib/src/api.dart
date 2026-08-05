import 'package:drift/drift.dart';

import 'db/database.dart';

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
  PathGraph(QueryExecutor executor) : _db = PathGraphDatabase(executor);

  final PathGraphDatabase _db;

  String? _selfPubkey;
  int _selfStride = 2;

  int _observationsApplied = 0;
  int _dropped1Byte = 0;

  /// Loads persisted state into the in-memory working set.
  Future<void> init() async {
    // Working-set load lands with the graph store step.
    await _db.customSelect('SELECT 1').get();
  }

  Future<void> dispose() => _db.close();

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
  void observePath(
    Uint8List pathBytes,
    int stride,
    ObservationOrigin origin, {
    double? rxSnr,
    GeoPosition? position,
  }) {
    if (stride < 2) {
      _dropped1Byte++;
      return;
    }
    if (pathBytes.isEmpty || pathBytes.length % stride != 0) return;
    _observationsApplied++;
    // Graph/ingress updates land with the graph store step.
  }

  /// Proven egress refresh; supersede/slash only in a failure episode.
  void observeDiscoverResults(
    List<DiscoverResponse> responses, {
    GeoPosition? position,
    required bool failureEpisode,
  }) {
    // Lands with the evidence step.
  }

  /// Delivery outcome for a path we sent on. Success proves every
  /// forward hop (updates s/n); failure applies the small forward
  /// penalty. The ACK's own route is never inferred.
  void reportSendResult(
    Uint8List pathBytes,
    bool success, {
    int? tripTimeMs,
  }) {
    // Lands with the evidence step.
  }

  /// Repeater advert / import metadata enrichment.
  void ingestNode(
    String hashBytes, {
    String? name,
    String? pubkey,
    double? lat,
    double? lon,
  }) {
    // Lands with the graph store step.
  }

  /// Contact mirror feed (full PK→name refresh on connect, add/rename).
  void ingestContact(String contactPubkey, String name, {GeoPosition? position}) {
    // Lands with the ingress step.
  }

  /// meshtrax-graph-v1 node-link document → prior layer for [region].
  Future<void> importGraph(
    Map<String, dynamic> document, {
    GeoPosition? homePosition,
    double? radiusKm,
  }) async {
    // Lands with the import step.
  }

  /// Best path to this contact: direct | bidirectional route | flood.
  PathResult findPath(String contactPubkey) {
    // Empty module → flood is the honest answer (and correct today:
    // no evidence exists until the graph store step lands).
    return const PathResult.flood(FloodReason.noEvidence);
  }

  PathGraphCounters get counters => PathGraphCounters(
        observationsApplied: _observationsApplied,
        dropped1Byte: _dropped1Byte,
      );
}
