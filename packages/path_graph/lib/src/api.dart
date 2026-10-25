import 'dart:async';

import 'package:drift/drift.dart';

import 'db/database.dart';
import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';
import 'mesh_id.dart';
import 'moving.dart';
import 'place_store.dart';
import 'retention.dart';
import 'search.dart';

export 'estimator.dart' show Estimator, PathGraphConfig, haversineKm;
export 'evidence.dart' show Candidate, EvidenceTier, directHash;
export 'graph_store.dart' show EdgeState, MovingOverride, NodeState, NodeSource;
export 'mesh_id.dart' show MeshId;
export 'place_store.dart' show PlaceRow;
export 'moving.dart' show MovingCheck, MovingReason, MovingStatus;
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

  /// Hash bucket in hex, at the graph's identity width.
  final String repeaterHash;

  /// dB at which the repeater heard OUR request (control payload byte
  /// 1) — the direction that matters for sending.
  final double? uplinkSnr;

  /// dB at which WE heard the response (frame header) — the reverse
  /// direction of the same exchange.
  final double? rxSnr;
}

/// Why Pathfinder would like one Discover now ([PathGraph.selfAdvice]):
/// each is a doubt about MY side of the air that one zero-hop request
/// settles for a packet, where a flood would cost the whole mesh.
enum DiscoverReason {
  /// The radio knows its area and no repeater has been heard hearing me
  /// around here.
  noDoorstepHere,

  /// The radio has moved to another area since a doorstep last proved it
  /// hears me.
  movedSinceProof,

  /// A doorstep of mine is held for failing my sends, toward two or more
  /// different contacts (or it has gone quiet too): my side, not theirs.
  doorstepsFailingMe,

  /// A whole ladder, flood included, went unanswered and no repeater
  /// echoed any of it.
  ladderUnanswered,
}

/// Geographic position of a repeater, from its advert.
class GeoPosition {
  const GeoPosition(this.lat, this.lon);
  final double lat;
  final double lon;
}

/// Why findPath returned flood — surfaced in the why-this-path UI.
enum FloodReason {
  noEvidence,

  /// Doorsteps exist on both sides, but none of MINE was ever proven to
  /// hear this radio (only heard by me). A delivered send, a trace or a
  /// Discover answer proves one.
  noProvenEndpoint,
  noCorridor,
  belowThreshold,
  overBudget,

  /// Every doorstep of mine that could start a route has failed my last
  /// sends since it last proved it hears me
  /// ([PathGraphConfig.selfFailGate]).
  doorstepsFailing,

  /// Every doorstep of mine that could start a route has gone quiet
  /// while I hear others ([PathGraphConfig.selfSilenceMinutes]).
  doorstepsQuiet,

  /// Every doorstep of mine that could start a route is a moving repeater
  /// that has not proved it hears me for
  /// [PathGraphConfig.mobileFreshMinutes].
  doorstepsMoving,

  /// The radio knows the area it is in, and no doorstep of mine was ever
  /// heard hearing me there (or the ones that were have failed here).
  doorstepsNotHere,

  /// The radio has moved to another area since this contact last got a
  /// packet of mine, and their way back ends at a repeater not heard
  /// hearing me here: a route out would reach them, but their ACK would
  /// ride their stored route back and die (simulator, 2026-10-25). A
  /// flood teaches their radio the way back.
  movedSinceTheyReachedMe,

  /// Every repeater heard carrying the contact's packets has failed my last
  /// direct sends to them ([PathGraphConfig.contactFailGate]): it hears
  /// them, they do not hear it.
  theirDoorstepsFailing,
}

/// The three-tier return contract: direct | bidirectional path | flood.
sealed class PathResult {
  const PathResult();

  const factory PathResult.direct() = DirectResult;
  const factory PathResult.path(
    Uint8List pathBytes,
    double estDelivery, {
    List<double> hopProbabilities,
    List<bool> guessedLinks,
    bool egressProven,
    bool ingressProven,
  }) = RouteResult;
  const factory PathResult.flood(FloodReason reason) = FloodResult;
}

/// Zero-hop: a delivered empty-path send proved they hear this radio —
/// send with an empty path while that is fresh.
class DirectResult extends PathResult {
  const DirectResult();
}

/// A route over links observed in the direction it travels. [pathBytes] is wire
/// format (hops at the graph's identity width); truncate each hop to
/// its first byte for 1-byte-mode targets. The evidence rides along so
/// the caller can see why this option ranks where it does.
class RouteResult extends PathResult {
  const RouteResult(
    this.pathBytes,
    this.estDelivery, {
    this.hopProbabilities = const [],
    this.guessedLinks = const [],
    this.egressProven = true,
    this.ingressProven = true,
  });
  final Uint8List pathBytes;
  final double estDelivery;

  /// Calibrated p of each between-hop link, in path order.
  final List<double> hopProbabilities;

  /// Per between-hop link, in path order: a splice guess — the reverse of
  /// a link heard on the contact's inbound path, never observed in this
  /// direction — rather than an observed link. Empty when nothing was
  /// guessed. See [PathGraphConfig.guessQ].
  final List<bool> guessedLinks;

  /// How many of the route's links are splice guesses.
  int get guessedHops => guessedLinks.where((g) => g).length;

  /// Whether the first hop was proven to hear this radio (always, unless
  /// the graph was configured to allow inferred endpoints), and whether
  /// the last hop was proven to reach the target by a delivery — false
  /// when the route ends at a doorstep only heard carrying their
  /// traffic.
  final bool egressProven;
  final bool ingressProven;
}

class FloodResult extends PathResult {
  const FloodResult(this.reason);
  final FloodReason reason;
}

/// Observation counters (graph_meta backed; snapshot for UI/debug).
class PathGraphCounters {
  const PathGraphCounters({
    required this.observationsApplied,
    required this.droppedNarrow,
    this.linksHeld = 0,
  });

  final int observationsApplied;

  /// Paths whose stride was narrower than the graph's bucket width —
  /// unusable for identity (a 1-byte hash can't be widened to 2).
  final int droppedNarrow;

  /// Sightings of links to codes the graph never had, held back until
  /// heard again ([PathGraphConfig.newCodeConfirmMinutes]).
  final int linksHeld;
}

/// The module. Push-in, never read-out: this API is the complete
/// inventory of everything the module will ever know.
class PathGraph {
  /// [hashWidthBytes] is the graph's identity width — every node, edge
  /// and ingress key is the first N bytes of a pubkey. 2 is right for
  /// today's meshes; the knob exists so a regional mesh outgrowing 2
  /// bytes moves to 3 or 4 by re-collecting (or re-collapsing stored
  /// pubkeys), not by hunting hardcoded 2s. The width is stamped into
  /// the database, exports, and session checkpoints — mixing widths is
  /// refused rather than silently mangled.
  PathGraph(
    QueryExecutor executor, {
    DateTime Function()? now,
    PathGraphConfig config = const PathGraphConfig(),
    this.hashWidthBytes = 2,
    this.mesh,
  })  : assert(hashWidthBytes >= 2 && hashWidthBytes <= 4,
            'wire path hops are 1–4 bytes; buckets below 2 are useless'),
        _db = PathGraphDatabase(executor),
        _now = now ?? DateTime.now,
        _estimator = Estimator(config) {
    _store = GraphStore(_db, hashWidthBytes: hashWidthBytes)
      ..onLinkSeen = _onLinkSeen;
    _evidence = EvidenceStore(_db, config, hashWidthBytes: hashWidthBytes);
    _places = PlaceStore(_db);
  }

  final int hashWidthBytes;

  /// The radio preset this graph is for, when the caller knows it. Stamped
  /// into exports and checkpoints; a checkpoint from another mesh is
  /// refused, since its codes name other repeaters.
  final MeshId? mesh;

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
  late final PlaceStore _places;

  Timer? _flushTimer;
  static const _flushDelay = Duration(seconds: 30);

  String? _selfPubkey;
  int _selfStride = 2;

  int _observationsApplied = 0;
  int _droppedNarrow = 0;
  int _linksHeld = 0;
  // Links to codes the graph never had, waiting to be heard again
  // (PathGraphConfig.newCodeConfirmMinutes): when first heard. Oldest
  // first; memory only.
  final Map<(String, String), int> _heldLinks = {};
  static const _heldLinksCap = 20000;
  // (messageId|first hop) of own echoes already proved; insertion-ordered.
  final Set<String> _ownEchoSeen = <String>{};
  // Per contact: the route their latest PATH reply named, and when
  // (see PathGraphConfig.liveRouteMinutes). Memory only.
  final Map<String, ({List<String> hops, int at})> _liveRoutes = {};
  // Per contact: the distinct paths their recent keyed packets (decoded
  // DM or post, signed advert, matched ACK or PATH reply) travelled to
  // reach me, newest first — the splice's hints (PathGraphConfig.guessQ).
  // Memory only, never exported, cleared with the radio identity.
  final Map<String, List<({List<String> hops, int at})>> _hints = {};
  // Guessed links a send failed on, with the arrival millis of the failure.
  // Memory only, like the hints: nothing is minted, but the same guess is
  // not offered again while a hint could carry it
  // (PathGraphConfig.hintFreshMinutes). A delivery over the link clears it.
  final Map<(String, String), int> _failedGuesses = {};

  // Watching-only moving-repeater detectors (PathGraphConfig.mobileNewLinks)
  // and, per node, the first sighting of its oldest link (0 = from before
  // first sightings were kept), built on first use. Memory only.
  final _strangerNovelty = NoveltyCounter(sliceMs: 30 * 60 * 1000);
  final _riderNovelty = NoveltyCounter(sliceMs: 20 * 60 * 1000);
  Map<String, int>? _knownSince;
  // reason|hash → when a vetoed check was last told. Memory only.
  final Map<String, int> _vetoToldAt = {};

  /// Told when a watching-only detector starts seeing [hash] move, or
  /// would have but still hears it with its old links ([MovingCheck.tagged]
  /// false) — each at most once a day per repeater and reason.
  void Function(String hash, MovingReason reason, MovingCheck check)?
      onMovingSign;

  /// Loads persisted state into the in-memory working set.
  Future<void> init() async {
    // The identity width is a property of the collected data, not of
    // the code — refuse a database collected at another width rather
    // than silently mangling its keys. (Databases from before the
    // stamp were all width-2.)
    final stamp = await (_db.select(_db.graphMeta)
          ..where((t) => t.key.equals('hash_width')))
        .getSingleOrNull();
    // No stamp + existing rows = a database from before the stamp,
    // which was always collected at width 2.
    final dbWidth = stamp != null
        ? int.tryParse(stamp.value) ?? 2
        : (await (_db.select(_db.graphNodes)..limit(1)).get()).isEmpty
            ? hashWidthBytes
            : 2;
    if (dbWidth != hashWidthBytes) {
      throw StateError(
          'database was collected at hash width $dbWidth, this PathGraph '
          'runs at $hashWidthBytes — re-collect or re-collapse; widths '
          'cannot mix');
    }
    await _db.into(_db.graphMeta).insertOnConflictUpdate(
        GraphMetaCompanion.insert(
            key: 'hash_width', value: '$hashWidthBytes'));

    await _store.load();
    await _evidence.load();
    await _places.load();
    // Heal rows minted before wide hops truncated into buckets.
    _store.normalizeKeys();
    _evidence.normalizeKeys();
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
    await _places.flush();
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(_flushDelay, () {
      _flushTimer = null;
      _store.flush();
      _evidence.flush();
      _places.flush();
    });
  }

  int get _arrivalMillis => _now().millisecondsSinceEpoch;

  /// Hash-native identity: a hop is always its first [hashWidthBytes]
  /// bytes, whatever width the sender used. Hashes are pubkey prefixes,
  /// so a wider hop truncates losslessly into the bucket the rest of
  /// the graph knows — found live: a stride-3 path minted 'A27782'
  /// beside 'A277', the same repeater counted twice.
  String _hopHex(Uint8List path, int stride, int hopIndex) {
    final start = hopIndex * stride;
    final b = StringBuffer();
    for (var i = start; i < start + hashWidthBytes; i++) {
      b.write(path[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return b.toString();
  }

  /// Identity of the connected radio; scopes egress rows and default
  /// observation stride.
  void setRadioIdentity(String selfPubkey, int stride) {
    if (_selfPubkey != selfPubkey.toLowerCase()) {
      clearHints();
      setPlace(null, const {});
    }
    _selfPubkey = selfPubkey.toLowerCase();
    _selfStride = stride;
  }

  // Where the radio is, as an opaque cell key the app computes from the
  // radio's own GPS (about 500 m across) plus the cells around it. Never
  // a coordinate, never stored, never logged: the owner's rule is that
  // no precise location is kept (2026-10-25). Null when the radio has no
  // live fix.
  String? _cell;
  Set<String> _nearCells = const {};

  /// When the radio last left the block of cells it was in (a step to a
  /// neighbouring cell is not a move). Null until it has.
  int? _movedAt;

  /// Contacts that have got a packet of mine since that move (a flooded
  /// delivery, their PATH reply): their radio holds a way back that ends
  /// where I am now.
  final Set<String> _reachedSinceMove = {};

  void setPlace(String? cell, Set<String> near) {
    final moved = cell != null && _cell != null && !_nearCells.contains(cell);
    if (moved) {
      _movedAt = _arrivalMillis;
      _reachedSinceMove.clear();
    }
    final firstFix = cell != null && _cell == null;
    _cell = cell;
    _nearCells = cell == null ? const {} : {cell, ...near};
    if (firstFix) _backfillPlace(cell);
  }

  /// Doorsteps that proved they hear me in the minutes before the area
  /// became known were almost certainly proving it here: a radio on its
  /// first fix after connecting has not gone anywhere. Filed under the
  /// new cell so the first send here does not flood over proofs the
  /// graph already holds (simulator 2026-10-25). Never on a move.
  final Map<String, ({int at, double? uplinkSnr})> _recentSelfProofs = {};
  static const _placeBackfillMinutes = 3;

  void _backfillPlace(String cell) {
    final self = _selfPubkey;
    if (self == null) return;
    final cutoff = _arrivalMillis - _placeBackfillMinutes * 60 * 1000;
    for (final e in _recentSelfProofs.entries) {
      if (e.value.at < cutoff) continue;
      _places.note(self, cell, e.key, _today, uplinkSnr: e.value.uplinkSnr);
    }
    _recentSelfProofs.clear();
    _scheduleFlush();
  }

  /// A flood of mine was delivered to them: their radio now holds the
  /// way back from where I am.
  void reportFloodDelivered(String contactPubkey) {
    _reachedSinceMove.add(contactPubkey.toLowerCase());
  }

  /// Whether their known way back ends at a repeater heard hearing me
  /// around here. True when nothing is known about their way back: that
  /// is no reason to flood.
  bool _theirWayBackEndsHere(String contactPubkey) {
    final self = _selfPubkey;
    if (self == null || _cell == null) return true;
    final back = findReturnPath(contactPubkey);
    if (back is! RouteResult) return true;
    final bytes = back.pathBytes;
    final last = bytes.sublist(bytes.length - hashWidthBytes);
    final hash = last.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return _places.rowIn(self, _nearCells, hash) != null;
  }

  // What selfAdvice reads: the last time any doorstep proved it hears me,
  // which contacts each failing doorstep failed toward since it last
  // proved itself, and when a whole ladder last went unanswered with no
  // echo heard. Memory only — advice is about now.
  int? _lastSelfProofAt;
  final Map<String, Set<String>> _failedToward = {};
  int? _unansweredLadderAt;
  static const _unansweredAdviceMinutes = 10;

  /// A ladder to [contactPubkey] ended. [echoHeard]: whether any repeater
  /// was heard echoing a flood of it; null when no flood of it could have
  /// been observed (nothing to conclude).
  void reportLadderEnded(String contactPubkey,
      {required bool delivered, required bool? echoHeard}) {
    if (!delivered && echoHeard == false) _unansweredLadderAt = _arrivalMillis;
  }

  /// Whether one Discover would settle a doubt about my side of the air,
  /// and which. Null when there is none, and always null while every
  /// doorstep that reaches [contactPubkey] is failing deliveries to them:
  /// that doubt is on their side, and a Discover cannot answer it.
  DiscoverReason? selfAdvice({String? contactPubkey}) {
    final self = _selfPubkey;
    if (self == null) return null;
    final now = _arrivalMillis;
    if (contactPubkey != null &&
        _theirDoorstepsAllFailing(contactPubkey.toLowerCase(), now)) {
      return null;
    }
    final mine = _egressCandidates(self, now);
    if (_cell != null &&
        (mine.candidates?.isEmpty ?? true) &&
        mine.held.values.every((r) => r == FloodReason.doorstepsNotHere)) {
      return _movedAt != null && (_lastSelfProofAt ?? 0) < _movedAt!
          ? DiscoverReason.movedSinceProof
          : DiscoverReason.noDoorstepHere;
    }
    final all = _evidence.candidatesFor(self, now, isSelf: true);
    for (final e in mine.held.entries) {
      if (e.value != FloodReason.doorstepsFailing) continue;
      final toward = _failedToward[e.key] ?? const <String>{};
      final c = all.where((x) => x.repeaterHash == e.key).firstOrNull;
      if (toward.length >= 2 || (c != null && _isQuiet(c, now))) {
        return DiscoverReason.doorstepsFailingMe;
      }
    }
    final unanswered = _unansweredLadderAt;
    if (unanswered != null &&
        now - unanswered <= _unansweredAdviceMinutes * 60 * 1000) {
      return DiscoverReason.ladderUnanswered;
    }
    return null;
  }

  String? get currentCell => _cell;
  Set<String> get nearCells => _nearCells;

  /// Whether any area remembers which repeaters heard this radio: what a
  /// checkpoint would carry with [saveSession] includePlaces.
  bool get hasPlaces => _places.rows.isNotEmpty;

  /// Which repeaters heard me around here, for display: hash → row.
  Map<String, PlaceRow> placesHere() {
    final self = _selfPubkey;
    if (self == null || _cell == null) return const {};
    final out = <String, PlaceRow>{};
    for (final e in _places.rows.entries) {
      if (e.key.$1 != self || !_nearCells.contains(e.key.$2)) continue;
      final have = out[e.key.$3];
      if (have == null || e.value.lastSeenDay > have.lastSeenDay) {
        out[e.key.$3] = e.value;
      }
    }
    return out;
  }

  int get _today => _arrivalMillis ~/ Duration.millisecondsPerDay;

  /// A repeater proved it hears me, and the radio knows where it is:
  /// remember that for this area. Only a Discover answer or a trace
  /// brings a level; a proof without one leaves the level alone.
  void _notePlace(String repeater, {double? uplinkSnr}) {
    final upper = repeater.toUpperCase();
    _lastSelfProofAt = _arrivalMillis;
    _failedToward.remove(upper);
    _unansweredLadderAt = null;
    final self = _selfPubkey, cell = _cell;
    if (self == null) return;
    if (cell == null) {
      _recentSelfProofs[upper] = (at: _arrivalMillis, uplinkSnr: uplinkSnr);
      return;
    }
    _places.note(self, cell, upper, _today, uplinkSnr: uplinkSnr);
  }

  void _failPlace(String repeater) {
    final self = _selfPubkey, cell = _cell;
    if (self == null || cell == null) return;
    _places.markFailed(self, cell, repeater.toUpperCase());
  }

  /// Forgets every contact's inbound paths (the splice's hints): another
  /// radio, another mesh, or the graph was cleared.
  void clearHints() {
    _hints.clear();
    _failedGuesses.clear();
  }

  String? get selfPubkey => _selfPubkey;
  int get selfStride => _selfStride;

  /// Any received path (already parsed by the caller — the module never
  /// touches wire frames). Rejects strides narrower than the bucket
  /// width (counted, not silent). Wider hops truncate losslessly into
  /// buckets.
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
    String? messageId,
    bool lastHopHeard = true,
  }) {
    final arrival = _arrivalMillis;

    var contact = switch (origin) {
      PubkeyConfirmedOrigin(:final contactPubkey) => contactPubkey.toLowerCase(),
      UniqueNameOrigin(:final contactPubkey) => contactPubkey.toLowerCase(),
      AnonymousOrigin() => null,
    };
    // A packet under my own key is an echo of my own flood: its first
    // hop heard me, nothing else. It must not be filed as a contact
    // sighting of myself — that rule halves every other doorstep on
    // every sighting (right for a handheld on the move, ruinous for my
    // own list, where several repeaters echo the same send) and would
    // call a zero-hop copy "direct". My own end forgets through the
    // proof itself: see PathGraphConfig.selfProofStaleMinutes. Each flood
    // copy of one packet proves its first hop once; the path itself is
    // still a heard corridor, filed anonymously below.
    if (contact != null && contact == _selfPubkey) {
      final firstHop = pathBytes.isEmpty || stride < hashWidthBytes
          ? ''
          : _hopHex(pathBytes, stride, 0);
      if (messageId == null || _ownEchoSeen.add('$messageId|$firstHop')) {
        if (_ownEchoSeen.length > 256) _ownEchoSeen.remove(_ownEchoSeen.first);
        observeOwnEcho(pathBytes, stride);
      }
      contact = null;
    }

    // Empty path + known sender = direct reception (zero-hop evidence).
    if (pathBytes.isEmpty) {
      if (contact != null) {
        _evidence.recordDirect(contact, arrival);
        _observationsApplied++;
        _scheduleFlush();
      }
      return;
    }

    if (stride < hashWidthBytes) {
      _droppedNarrow++;
      return;
    }
    if (pathBytes.length % stride != 0) return;

    final hopCount = pathBytes.length ~/ stride;
    final hops = [
      for (var i = 0; i < hopCount; i++) _hopHex(pathBytes, stride, i),
    ];
    // A packet that is mine or decoded as a contact's vouches for its path;
    // anything else heard on the air may carry junk codes.
    final vouched =
        origin is! AnonymousOrigin || config.newCodeConfirmMinutes <= 0;
    bool known(String hash) => vouched || _store.nodes.containsKey(hash);
    for (var i = 0; i < hopCount - 1; i++) {
      _fileLink(hops[i], hops[i + 1], arrival, messageId, vouched: vouched);
    }
    if (hopCount == 1 && known(hops[0])) {
      _store.nodeFor(hops[0], NodeSource.observed).lastHeard = arrival;
    }

    // Contact ingress: path[0] of traffic they originated.
    // [contact] is the normalised key, and null for anonymous traffic and
    // for my own echoes (edges only).
    if (contact != null) {
      _creditContactDoorstep(contact, hops.first,
          confirmed: origin is PubkeyConfirmedOrigin, arrival: arrival);
      if (origin is PubkeyConfirmedOrigin) _recordHint(contact, hops, arrival);
    }

    // Self egress: final hop is the last-hop prior; penultimate feeds
    // the hub-signature demotion. RF-received paths only, and only codes
    // the graph knows: a junk last hop heard loud is still junk.
    final self = _selfPubkey;
    if (self != null && lastHopHeard && known(hops.last)) {
      _evidence.recordLastHop(self, hops.last, arrival, downlinkSnr: rxSnr);
      if (hopCount >= 2 && known(hops[hopCount - 2])) {
        _evidence.recordPenultimate(self, hops[hopCount - 2]);
      }
    }

    _observationsApplied++;
    _scheduleFlush();
  }

  /// Files the link [from]→[to] at once when it is vouched for or both
  /// codes are known. A link to a code the graph never had waits until it
  /// is heard again [PathGraphConfig.newCodeConfirmMinutes] later — junk
  /// codes never come back, and copies of one packet arrive within
  /// seconds — and is then filed with both sightings.
  void _fileLink(String from, String to, int at, String? messageId,
      {required bool vouched}) {
    if (vouched ||
        (_store.nodes.containsKey(from) && _store.nodes.containsKey(to))) {
      _store.observeEdge(from, to, at, messageId: messageId);
      return;
    }
    final key = (from, to);
    final first = _heldLinks[key];
    final waitMs =
        (config.newCodeConfirmMinutes * Duration.millisecondsPerMinute).round();
    if (first != null && at - first >= waitMs) {
      _heldLinks.remove(key);
      _store.observeEdge(from, to, at,
          messageId: messageId, heardBefore: first);
      return;
    }
    _linksHeld++;
    if (first == null) {
      _heldLinks[key] = at;
      if (_heldLinks.length > _heldLinksCap) {
        _heldLinks.remove(_heldLinks.keys.first);
      }
    }
  }

  /// A channel message the app decrypted: [senderName] is the "name: "
  /// prefix of the text, [pathBytes] the path the packet arrived on. A
  /// name that matches exactly one known contact credits their doorstep;
  /// anything else is dropped.
  void observeChannelSender(
      String senderName, Uint8List pathBytes, int stride) {
    final pk = _evidence.contactByUniqueName(senderName);
    if (pk == null) return;
    observeContactSender(pk, pathBytes, stride, confirmed: false);
  }

  /// A packet from [contactPubkey] heard on [pathBytes]: a DM or room
  /// post the radio decrypted ([confirmed] — the MAC proved the key) or a
  /// channel message matched by name. Attribution only — the same packet
  /// already reached [observePath] anonymously through the raw feed, so
  /// edges and my own last-hop prior are not counted again here. An
  /// empty path means they reached me with no repeater in between, which
  /// only a proven key may claim. Returns whether anything was filed.
  /// [deliveredAck]: this packet is the flooded ACK of a send of mine, so
  /// its first hop just carried a delivery to them: that doorstep's
  /// failed-delivery count starts again (the contact-side gate is reset
  /// only by a delivery, and this is one; simulator 2026-10-25: without
  /// it three delivered floods via BEEF left BEEF gated for good).
  bool observeContactSender(
      String contactPubkey, Uint8List pathBytes, int stride,
      {required bool confirmed, bool deliveredAck = false}) {
    contactPubkey = contactPubkey.toLowerCase();
    if (contactPubkey == _selfPubkey) {
      observeOwnEcho(pathBytes, stride);
      return true;
    }
    final arrival = _arrivalMillis;
    if (pathBytes.isEmpty) {
      // A name match proves nothing about who was in range: DIRECT would
      // route every send without a repeater for half an hour.
      if (!confirmed) return false;
      _evidence.recordDirect(contactPubkey, arrival);
      _observationsApplied++;
      _scheduleFlush();
      return true;
    }
    if (stride < hashWidthBytes) {
      _droppedNarrow++;
      return false;
    }
    if (pathBytes.length % stride != 0) return false;
    _creditContactDoorstep(contactPubkey, _hopHex(pathBytes, stride, 0),
        confirmed: confirmed, arrival: arrival);
    if (deliveredAck) {
      _evidence.clearContactFailures(contactPubkey, _hopHex(pathBytes, stride, 0));
    }
    if (confirmed) {
      _recordHint(contactPubkey, [
        for (var i = 0; i < pathBytes.length ~/ stride; i++)
          _hopHex(pathBytes, stride, i)
      ], arrival);
    }
    _observationsApplied++;
    _scheduleFlush();
    return true;
  }

  /// Another copy of a keyed packet from [contactPubkey] that
  /// [observeContactSender] already filed, heard on [pathBytes]: a hint
  /// for the splice and nothing else. The doorstep was credited by the
  /// first copy and the raw feed already filed the corridor; what this
  /// copy adds is a path with repeater-to-repeater links the first,
  /// shortest copy did not have (field 2026-10-24: a room's reply arrived
  /// as BEEF alone and as 5B98,F5EE,AA77,A277 — only the second can be
  /// reversed). Returns whether a hint was kept.
  bool observeInboundCopy(
      String contactPubkey, Uint8List pathBytes, int stride) {
    contactPubkey = contactPubkey.toLowerCase();
    if (contactPubkey == _selfPubkey || pathBytes.isEmpty) return false;
    if (stride < hashWidthBytes || pathBytes.length % stride != 0) {
      return false;
    }
    final hops = pathBytes.length ~/ stride;
    if (hops < 2) return false;
    _recordHint(contactPubkey,
        [for (var i = 0; i < hops; i++) _hopHex(pathBytes, stride, i)],
        _arrivalMillis);
    return true;
  }

  /// Keeps [hops] (travel order: their doorstep first, the repeater I
  /// heard last) as one of [contactPubkey]'s recent inbound paths. Only
  /// keyed packets get here: a channel line matched by name is not one.
  void _recordHint(String contactPubkey, List<String> hops, int arrival) {
    if (hops.length < 2) return; // nothing between doorsteps to reverse
    final list = _hints.putIfAbsent(contactPubkey, () => []);
    final key = hops.join('>');
    list.removeWhere((h) => h.hops.join('>') == key);
    list.insert(0, (hops: List.unmodifiable(hops), at: arrival));
    while (list.length > config.hintsPerContact) {
      list.removeLast();
    }
  }

  /// A contact's recent inbound paths (the splice's hints) as kept, newest
  /// first, with the arrival millis of each (UI/debug).
  List<({List<String> hops, int at})> hintsFor(String contactPubkey) =>
      List.unmodifiable(_hints[contactPubkey.toLowerCase()] ?? const []);

  /// The reverse guesses the next search for [contactPubkey] would be
  /// offered right now, after every guard (UI/debug).
  Set<(String, String)> hintGuessesFor(String contactPubkey) =>
      _hintGuesses(contactPubkey.toLowerCase(), _arrivalMillis);

  /// The splice's guesses for one query: the reverse of each
  /// repeater-to-repeater link on [contactPubkey]'s fresh inbound paths
  /// (not their doorstep's link to them, which a route ends on anyway),
  /// vetted link by link. A guess is offered only when the store knows
  /// nothing about that direction, the observed direction has history
  /// ([PathGraphConfig.hintLinkMinAgeMinutes], two packets), the hop is
  /// not impossibly long ([PathGraphConfig.hintMaxHopKm]) and no end is a
  /// moving repeater gone stale.
  Set<(String, String)> _hintGuesses(String contactPubkey, int now) {
    final hints = _hints[contactPubkey];
    if (hints == null || hints.isEmpty) return const {};
    final freshMs = (config.hintFreshMinutes * 60 * 1000).round();
    final minAgeMs = (config.hintLinkMinAgeMinutes * 60 * 1000).round();
    hints.removeWhere((h) => now - h.at > freshMs);
    _failedGuesses.removeWhere((_, at) => now - at > freshMs);
    if (hints.isEmpty) return const {};
    final moving = _movingNow(now);
    final out = <(String, String)>{};
    for (final hint in hints) {
      final hops = hint.hops;
      for (var i = 1; i < hops.length; i++) {
        final observed = (hops[i - 1], hops[i]);
        final guess = (hops[i], hops[i - 1]);
        if (hops[i] == hops[i - 1] ||
            _store.edges.containsKey(guess) ||
            _failedGuesses.containsKey(guess)) {
          continue;
        }
        // A link first seen before the graph kept first-seen times is old
        // by definition (field 2026-10-24: BEEF→A277 in the real export).
        final seen = _store.edges[observed];
        if (seen == null ||
            seen.obsCount < 2 ||
            (seen.firstObserved != null &&
                hint.at - seen.firstObserved! < minAgeMs)) {
          continue;
        }
        if (moving.contains(hops[i]) || moving.contains(hops[i - 1])) {
          if (now - hint.at > _mobileFreshMs) continue;
        }
        final a = _store.nodes[hops[i]];
        final b = _store.nodes[hops[i - 1]];
        if (a?.lat != null &&
            a?.lon != null &&
            b?.lat != null &&
            b?.lon != null &&
            haversineKm(a!.lat!, a.lon!, b!.lat!, b.lon!) > config.hintMaxHopKm) {
          continue;
        }
        out.add(guess);
      }
    }
    return out;
  }

  /// An echo of my own flood, heard back with the path it travelled.
  /// Only the FIRST hop proves anything about me: it heard me directly,
  /// in the sending direction, so it is a confirmed doorstep. The hops
  /// after it forwarded each other — I may hear them, they did not
  /// necessarily hear me — and the raw feed already filed the corridor
  /// and the heard-last guess for the same packet, so nothing else is
  /// counted here. No level is recorded: a repeater does not report how
  /// loud it heard me.
  void observeOwnEcho(Uint8List pathBytes, int stride) {
    final self = _selfPubkey;
    if (self == null || pathBytes.isEmpty) return;
    if (stride < hashWidthBytes) {
      _droppedNarrow++;
      return;
    }
    if (pathBytes.length % stride != 0) return;
    _evidence.recordProvenEgress(
        self, _hopHex(pathBytes, stride, 0), _arrivalMillis,
        supersede: true);
    _notePlace(_hopHex(pathBytes, stride, 0));
    _observationsApplied++;
    _scheduleFlush();
  }

  /// A repeater's own zero-hop transmission reached this radio (an
  /// overheard discover reply, for one). That is the heard-last fact a
  /// received path gives — I hear it, measured — and nothing about
  /// whether it hears me.
  void observeRepeaterHeard(String hash, {double? rxSnr}) {
    final self = _selfPubkey;
    if (self == null) return;
    _evidence.recordLastHop(self, hash.toUpperCase(), _arrivalMillis,
        downlinkSnr: rxSnr);
    _observationsApplied++;
    _scheduleFlush();
  }

  /// One sighting of a contact through [hash]: the repeater that heard
  /// them first. Their doorstep list answers "who hears them now", so
  /// the sighting first pushes the rest of the list down — wiped when
  /// advert positions show [hash] is too far from their current top
  /// doorstep to be the same place, slashed otherwise — and then counts.
  void _creditContactDoorstep(String pk, String hash,
      {required bool confirmed, required int arrival}) {
    final top = _evidence
        .candidatesFor(pk, arrival, isSelf: false)
        .where((c) => c.repeaterHash != directHash)
        .firstOrNull;
    if (top != null && top.repeaterHash != hash && _movedFar(top.repeaterHash, hash)) {
      _evidence.wipeContact(pk);
    } else {
      _evidence.supersedeContact(pk,
          except: hash, factor: config.contactSupersedeFactor);
    }
    _evidence.recordIngress(pk, hash,
        pubkeyConfirmed: confirmed, arrival: arrival);
    if (confirmed) _evidence.recordRelayedSighting(pk, arrival);
  }

  bool _movedFar(String fromHash, String toHash) {
    final a = _store.nodes[fromHash];
    final b = _store.nodes[toHash];
    if (!isRealPosition(a?.lat, a?.lon) || !isRealPosition(b?.lat, b?.lon)) {
      return false;
    }
    return haversineKm(a!.lat!, a.lon!, b!.lat!, b.lon!) >
        config.contactMoveWipeKm;
  }

  /// Proven egress refresh; supersede/slash only in a failure episode.
  void observeDiscoverResults(
    List<DiscoverResponse> responses, {
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
    for (final r in responses) {
      _notePlace(r.repeaterHash, uplinkSnr: r.uplinkSnr);
    }
    _scheduleFlush();
  }

  /// Delivery outcome for a path we sent on. Success proves every
  /// forward hop (s+1, n+1): the first hop heard us (proven egress) and,
  /// with [contactPubkey], the last hop reached them (proven ingress).
  /// Failure is the small forward penalty (n+1 only — the break can't be
  /// localized). The ACK's own route is never inferred. An empty path
  /// delivered to [contactPubkey] proves the zero-hop link.
  ///
  /// [tally] false is for a route the firmware learned (a contact's
  /// out_path after a flood): it is the first flood copy to arrive, a
  /// race won on hop count, not reliability. It still proves both
  /// doorsteps, but the corridor links are only marked as seen in the
  /// forward direction — no success tally, and the return direction is
  /// not inferred. It is also the live route to them: it leads
  /// [findPath] for [PathGraphConfig.liveRouteMinutes], until a send on
  /// it fails.
  ///
  /// [stride] is the hash width the path was written at — a contact's
  /// stored route keeps the width of the packet that built it, which
  /// need not be the radio's own. Default: the radio's stride
  /// ([setRadioIdentity]). A path narrower than the graph's bucket is
  /// dropped and counted, like any other observation: reading 1-byte
  /// hashes two at a time would mint repeaters that do not exist.
  ///
  /// [guessedLinks], per between-hop link, marks the splice's guesses the
  /// route was sent on ([RouteResult.guessedLinks]). A delivery proves
  /// them like any other hop. A failure on a route with a guess in it
  /// says nothing the graph may keep: the break was most likely the guess,
  /// so no row is minted for a guessed pair and my doorstep is not charged
  /// (owner, 2026-10-24).
  void reportSendResult(
    Uint8List pathBytes,
    bool success, {
    int? tripTimeMs,
    String? contactPubkey,
    int? stride,
    bool tally = true,
    bool proveEgress = true,
    List<bool> guessedLinks = const [],
  }) {
    contactPubkey = contactPubkey?.toLowerCase();
    final arrival = _arrivalMillis;
    if (pathBytes.isEmpty) {
      if (success && contactPubkey != null) {
        _evidence.recordDirect(contactPubkey, arrival, proven: true);
        _scheduleFlush();
      }
      return;
    }
    stride ??= _selfStride;
    if (stride < hashWidthBytes) {
      _droppedNarrow++;
      return;
    }
    if (pathBytes.length % stride != 0) return;
    final hopCount = pathBytes.length ~/ stride;
    final anyGuessed = guessedLinks.any((g) => g);
    for (var i = 0; i < hopCount - 1 && i < guessedLinks.length; i++) {
      if (!guessedLinks[i]) continue;
      final link = (_hopHex(pathBytes, stride, i), _hopHex(pathBytes, stride, i + 1));
      if (success) {
        _failedGuesses.remove(link);
      } else {
        _failedGuesses[link] = arrival;
      }
    }
    if (!success && _selfPubkey != null && !anyGuessed) {
      // The break cannot be localised, but a doorstep that keeps failing
      // my sends since it last proved itself stops starting routes
      // (PathGraphConfig.selfFailGate); any proof resets it.
      _evidence.recordFailedEgress(_selfPubkey!, _hopHex(pathBytes, stride, 0));
      _failPlace(_hopHex(pathBytes, stride, 0));
      if (contactPubkey != null) {
        _failedToward
            .putIfAbsent(_hopHex(pathBytes, stride, 0).toUpperCase(), () => {})
            .add(contactPubkey);
      }
      // ...and their end likewise: a doorstep that keeps failing deliveries
      // to them stops ending routes (PathGraphConfig.contactFailGate);
      // only a delivery through it resets that.
      if (contactPubkey != null) {
        _evidence.recordFailedIngress(
            contactPubkey, _hopHex(pathBytes, stride, hopCount - 1));
      }
    }
    if (contactPubkey != null) {
      final hops = [
        for (var i = 0; i < hopCount; i++) _hopHex(pathBytes, stride, i)
      ];
      if (!tally && success && hopCount <= config.maxHops) {
        _liveRoutes[contactPubkey] = (hops: hops, at: arrival);
        _reachedSinceMove.add(contactPubkey);
      } else if (!success &&
          _liveRoutes[contactPubkey]?.hops.join('>') == hops.join('>')) {
        _liveRoutes.remove(contactPubkey);
      }
    }
    for (var i = 0; i < hopCount - 1; i++) {
      final from = _hopHex(pathBytes, stride, i);
      final to = _hopHex(pathBytes, stride, i + 1);
      if (!tally) {
        _store.observeEdge(from, to, arrival);
        continue;
      }
      if (!success && anyGuessed) continue;
      _store.nodeFor(from, NodeSource.observed).lastHeard = arrival;
      _store.nodeFor(to, NodeSource.observed).lastHeard = arrival;
      final edge = _store.edges.putIfAbsent((from, to),
          () => EdgeState(source: 'observed', firstObserved: arrival));
      if (success) edge.s++;
      edge.n++;
      edge.lastObserved = arrival;
      _store.markEdgeDirty(from, to);
    }
    if (success) {
      final self = _selfPubkey;
      // [proveEgress] false: an echo of this very send already proved the
      // first hop heard me; counting the delivery too would double it.
      // A route the firmware learned ([tally] false) is the path a flood
      // of mine took: its first hop forwarded that flood.
      if (self != null && proveEgress) {
        _evidence.recordProvenEgress(
            self, _hopHex(pathBytes, stride, 0), arrival,
            floodProven: !tally);
        _notePlace(_hopHex(pathBytes, stride, 0));
      }
      if (contactPubkey != null) {
        _evidence.recordProvenIngress(
            contactPubkey, _hopHex(pathBytes, stride, hopCount - 1), arrival);
      }
    }
    _scheduleFlush();
  }

  /// Trace result: top-grade evidence — the only source of middle-hop
  /// SNR. [hops] are bucket-width hash hex in traversal order; [snrs][i] is
  /// the level at which hops[i] heard the *previous* transmission (so
  /// snrs[0] is my first hop hearing ME → proven egress, measured). The
  /// firmware appends one more value, how I heard hops.last, so a
  /// full list is `hops.length + 1` long: hops.last reached me directly
  /// (a heard doorstep, measured downlink), and on a round trip (A,B,A)
  /// my doorstep is measured both ways from one trace. Each hop pair
  /// gets measuredSnr plus an attempt-counted success; round trips fill
  /// the reverse edges by the same rule, no special case.
  void observeTrace(List<String> hops, List<double> snrs) {
    if (hops.isEmpty) return;
    final arrival = _arrivalMillis;
    final self = _selfPubkey;

    if (self != null && snrs.isNotEmpty) {
      _evidence.recordProvenEgress(self, hops[0].toUpperCase(), arrival,
          uplinkSnr: snrs[0]);
      _notePlace(hops[0], uplinkSnr: snrs[0]);
      if (snrs.length > hops.length) {
        _evidence.recordLastHop(self, hops.last.toUpperCase(), arrival,
            downlinkSnr: snrs[hops.length]);
      }
    }
    for (var i = 1; i < hops.length; i++) {
      final from = hops[i - 1].toUpperCase();
      final to = hops[i].toUpperCase();
      final edge = _store.edges.putIfAbsent(
          (from, to), () => EdgeState(source: 'trace', firstObserved: arrival));
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

  /// Repeater advert metadata enrichment (advert outranks import). An
  /// advert without a position fix (0,0) leaves the known position alone.
  /// The same key advertising a real position [PathGraphConfig.mobileMoveKm]
  /// from its last one marks the repeater as moving; another key on the
  /// same hash is a code twin, not a move.
  void ingestNode(
    String hashBytes, {
    String? name,
    String? pubkey,
    double? lat,
    double? lon,
  }) {
    final hash = hashBytes.toUpperCase();
    final real = isRealPosition(lat, lon);
    final before = _store.nodes[hash];
    if (real &&
        before != null &&
        before.source == NodeSource.advert &&
        pubkey != null &&
        before.pubkey?.toLowerCase() == pubkey.toLowerCase() &&
        isRealPosition(before.lat, before.lon) &&
        haversineKm(before.lat!, before.lon!, lat!, lon!) >=
            config.mobileMoveKm) {
      before.movedAt = _arrivalMillis;
    }
    _store.enrichNode(
      hash,
      NodeSource.advert,
      name: name,
      pubkey: pubkey,
      lat: real ? lat : null,
      lon: real ? lon : null,
    );
    _store.nodeFor(hash, NodeSource.advert).lastHeard = _arrivalMillis;
    _scheduleFlush();
  }

  /// Whether [hash] moves, and why; null for a fixed repeater. A traffic
  /// tag on a code several known keys use says so
  /// ([MovingReason.sharedCode]).
  MovingStatus? movingStatus(String hash) {
    final key = hash.toUpperCase();
    final node = _store.nodes[key];
    final status =
        node == null ? null : movingStatusOf(node, config, _arrivalMillis);
    return status?.reason == MovingReason.newLinks
        ? _sharedCode(key, status!, _contactKeysByCode())
        : status;
  }

  /// Every repeater tagged as moving, acting or watching-only.
  Map<String, MovingStatus> movingRepeaters() {
    final now = _arrivalMillis;
    final tagged = {
      for (final e in _store.nodes.entries)
        if (movingStatusOf(e.value, config, now) case final status?)
          e.key: status,
    };
    if (tagged.values.every((s) => s.reason != MovingReason.newLinks)) {
      return tagged;
    }
    final keys = _contactKeysByCode();
    return tagged.map((hash, s) => MapEntry(hash, _sharedCode(hash, s, keys)));
  }

  /// [status] as [MovingReason.sharedCode] when it is a [MovingReason.newLinks]
  /// tag and contacts plus the node's own advert show 2+ keys on [hash].
  MovingStatus _sharedCode(String hash, MovingStatus status,
      Map<String, Set<String>> contactKeys) {
    if (status.reason != MovingReason.newLinks) return status;
    final advertKey = _store.nodes[hash]?.pubkey?.toLowerCase();
    final keys = {...?contactKeys[hash], if (advertKey != null) advertKey};
    return keys.length < 2
        ? status
        : MovingStatus(MovingReason.sharedCode,
            acts: status.acts, sharedKeys: keys.length);
  }

  /// Code → the distinct contact keys that use it.
  Map<String, Set<String>> _contactKeysByCode() {
    final width = hashWidthBytes * 2;
    final byCode = <String, Set<String>>{};
    for (final pubkey in _evidence.knownContacts.keys) {
      if (pubkey.length < width) continue;
      final key = pubkey.toLowerCase();
      (byCode[key.substring(0, width).toUpperCase()] ??= {}).add(key);
    }
    return byCode;
  }

  /// Every sighting of a link feeds the detectors. One the graph already
  /// had, from before their window, says both ends still have that
  /// neighbour. A new one is news for both ends: one that proved it hears
  /// me in each of the last three 20-minute slices and keeps meeting new
  /// repeaters rides with me (no stationary gate: I move with it). Anyone
  /// else known for a day that keeps meeting repeaters also known for a
  /// day (a one-off code is mostly garbage) while I stay put moves — "stay
  /// put" being no repeater new to me for an hour, so my own drive does
  /// not make fixed ones look new. Either way it must also have left its
  /// old neighbours behind ([PathGraphConfig.mobileNewShare]).
  void _onLinkSeen(String from, String to, int at,
      {required bool created, int? firstObserved}) {
    if (!created) {
      for (final hash in [from, to]) {
        _strangerNovelty.seen(hash, (from, to), at, firstObserved);
        _riderNovelty.seen(hash, (from, to), at, firstObserved);
      }
      return;
    }
    final known = _knownSince ??= _buildKnownSince();
    final lastNew = _evidence.lastNewSelfRowAt;
    final stationary =
        lastNew == null || at - lastNew > Duration.millisecondsPerHour;
    final minLinks = config.mobileNewLinks;
    final since = {
      from: known.putIfAbsent(from, () => at),
      to: known.putIfAbsent(to, () => at),
    };
    bool knownADay(String hash) =>
        at - since[hash]! >= Duration.millisecondsPerDay;
    for (final hash in [from, to]) {
      final other = hash == from ? to : from;
      final meetsSteadily = _riderNovelty.add(hash, at, minLinks: minLinks);
      if (_selfPubkey != null &&
          _evidence.provenInEachSlice(hash, at,
              sliceMs: _riderNovelty.sliceMs, slices: 3)) {
        if (meetsSteadily) {
          _judgeMoving(_riderNovelty, hash, MovingReason.ridesWithMe, at);
        }
      } else if (stationary &&
          knownADay(hash) &&
          knownADay(other) &&
          _strangerNovelty.add(hash, at, minLinks: minLinks)) {
        _judgeMoving(_strangerNovelty, hash, MovingReason.newLinks, at);
      }
    }
  }

  /// [hash] keeps meeting new repeaters; it moves only if they outnumber
  /// the old ones it is still heard with.
  void _judgeMoving(
      NoveltyCounter counter, String hash, MovingReason reason, int at) {
    final fresh = counter.newLinks(hash);
    final old = counter.oldLinks(hash, at);
    final check = (
      newLinks: fresh,
      oldLinks: old,
      tagged: fresh > config.mobileNewShare * (fresh + old),
    );
    if (check.tagged) {
      _markMoving(hash, reason, at, check);
      return;
    }
    final key = '${reason.name}|$hash';
    final last = _vetoToldAt[key];
    if (last == null || at - last > Duration.millisecondsPerDay) {
      _vetoToldAt[key] = at;
      onMovingSign?.call(hash, reason, check);
    }
  }

  void _markMoving(String hash, MovingReason reason, int at, MovingCheck check) {
    final node = _store.nodeFor(hash, NodeSource.observed);
    final rides = reason == MovingReason.ridesWithMe;
    final last = rides ? node.autoRidesWithMeAt : node.autoMovingAt;
    if (rides) {
      node.autoRidesWithMeAt = at;
    } else {
      node.autoMovingAt = at;
    }
    _store.markNodeDirty(hash);
    if (last == null || at - last > Duration.millisecondsPerDay) {
      onMovingSign?.call(hash, reason, check);
    }
  }

  Map<String, int> _buildKnownSince() {
    final known = <String, int>{};
    for (final e in _store.edges.entries) {
      final t = e.value.firstObserved ?? 0;
      for (final h in [e.key.$1, e.key.$2]) {
        final k = known[h];
        if (k == null || t < k) known[h] = t;
      }
    }
    return known;
  }

  /// The user's word on [hash]; null hands it back to the detectors.
  void setMovingOverride(String hash, MovingOverride? value) {
    final key = hash.toUpperCase();
    _store.nodeFor(key, NodeSource.observed).movingOverride = value;
    _store.markNodeDirty(key);
    _scheduleFlush();
  }

  /// Cheap sizes for before/after comparisons (a snapshot copies).
  int get nodeCount => _store.nodes.length;
  int get edgeCount => _store.edges.length;

  /// Read-only view of the working set for UI/debug rendering.
  ({Map<String, NodeState> nodes, Map<(String, String), EdgeState> edges})
      snapshot() => (
            nodes: Map.unmodifiable(_store.nodes),
            edges: Map.unmodifiable(_store.edges),
          );

  /// Contact mirror feed (full PK→name refresh on connect, add/rename).
  void ingestContact(String contactPubkey, String name) {
    _evidence.ingestContact(contactPubkey.toLowerCase(), name, _arrivalMillis);
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
    final mine = _egressCandidates(self, now);
    final egress = mine.candidates;
    if (egress == null) return const PathResult.flood(FloodReason.noEvidence);
    if (egress.isEmpty) {
      return PathResult.flood(mine.gate ?? FloodReason.noProvenEndpoint);
    }

    final route = PathFinder(estimator.config, estimator).search(
      egress: egress,
      // The repeater IS the destination — full-confidence virtual
      // target, no far-side doorstep uncertainty to price in.
      ingress: [_selfTarget(repeaterHash)],
      edges: _store.edges,
      nowMillis: now,
      moving: _movingNow(now),
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noCorridor);
    }
    return _toResult(route);
  }

  /// The route a packet from [contactPubkey] would take BACK to this
  /// radio, over links their packets travelled: from a repeater heard
  /// carrying their packets (their doorstep) to one this radio heard
  /// last (mine). The same "heard" rows the forward query refuses as
  /// guesses are the proof here — hearing is evidence for the direction
  /// the packet travelled. Diagnostic: the ACK's real route is chosen by
  /// their radio, not ours.
  PathResult findReturnPath(String contactPubkey) {
    contactPubkey = contactPubkey.toLowerCase();
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const PathResult.flood(FloodReason.noEvidence);
    final theirs = _freshRows(
        _evidence.heardCandidatesFor(contactPubkey, now, isSelf: false), now);
    final mine =
        _freshRows(_evidence.heardCandidatesFor(self, now, isSelf: true), now);
    if (theirs.isEmpty || mine.isEmpty) {
      return const PathResult.flood(FloodReason.noEvidence);
    }
    final route = PathFinder(estimator.config, estimator).search(
      egress: theirs,
      ingress: mine,
      edges: _store.edges,
      nowMillis: now,
      moving: _movingNow(now),
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noCorridor);
    }
    return _toResult(route);
  }

  /// The route back from repeater [repeaterHash] to this radio, over
  /// links heard in that direction: the repeater → … → one this radio
  /// heard last. The map's "route & trace" return leg, so a trace comes
  /// home on links that work that way instead of mirroring the way out.
  PathResult findReturnPathFromRepeater(String repeaterHash) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const PathResult.flood(FloodReason.noEvidence);
    final mine =
        _freshRows(_evidence.heardCandidatesFor(self, now, isSelf: true), now);
    if (mine.isEmpty) return const PathResult.flood(FloodReason.noEvidence);
    final route = PathFinder(estimator.config, estimator).search(
      egress: [_selfTarget(repeaterHash)],
      ingress: mine,
      edges: _store.edges,
      nowMillis: now,
      moving: _movingNow(now),
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noCorridor);
    }
    return _toResult(route);
  }

  /// Up to [count] divergent routes back from repeater [repeaterHash] to
  /// this radio, over the same heard rows [findReturnPathFromRepeater]
  /// uses.
  List<RouteResult> findReturnAlternativesFromRepeater(String repeaterHash,
      {int count = 3}) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const [];
    return _divergentRoutes(
      egress: [_selfTarget(repeaterHash)],
      ingress:
          _freshRows(_evidence.heardCandidatesFor(self, now, isSelf: true), now),
      count: count,
      now: now,
    );
  }

  /// Up to [count] divergent routes BACK from [contactPubkey] to this
  /// radio, over the same heard rows [findReturnPath] uses: their
  /// doorstep → … → mine. Diagnostic, like the single return path.
  List<RouteResult> findReturnAlternatives(String contactPubkey,
      {int count = 3}) {
    contactPubkey = contactPubkey.toLowerCase();
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const [];
    return _divergentRoutes(
      egress: _freshRows(
          _evidence.heardCandidatesFor(contactPubkey, now, isSelf: false), now),
      ingress:
          _freshRows(_evidence.heardCandidatesFor(self, now, isSelf: true), now),
      count: count,
      now: now,
    );
  }

  /// A traceable route from this radio to repeater [b] that passes
  /// through repeater [a]: my proven doorstep → … → A → … → B. Built for
  /// the map's "route & trace": the app sends a round-trip trace along
  /// it, and the trace result proves (or refutes) every hop in both
  /// directions. Pass [a] equal to [b] to route to a single repeater.
  PathResult findRouteVia(String a, String b) {
    final first = findPathToRepeater(a);
    if (first is! RouteResult) return first;
    final aHash = a.toUpperCase();
    final bHash = b.toUpperCase();
    if (aHash == bHash) return first;

    final leg = PathFinder(estimator.config, estimator).search(
      egress: [_selfTarget(aHash)],
      ingress: [_selfTarget(bHash)],
      edges: _store.edges,
      nowMillis: _arrivalMillis,
      moving: _movingNow(_arrivalMillis),
    );
    if (leg == null) {
      return const PathResult.flood(FloodReason.noCorridor);
    }
    final hops = [..._bytesToHops(first.pathBytes), ...leg.hops.skip(1)];
    if (hops.length > config.maxHops) {
      return const PathResult.flood(FloodReason.overBudget);
    }
    return RouteResult(
      _hopsToBytes(hops),
      first.estDelivery * leg.estDelivery,
      hopProbabilities: [...first.hopProbabilities, ...leg.hopProbabilities],
      egressProven: first.egressProven,
      ingressProven: true,
    );
  }

  List<String> _bytesToHops(Uint8List bytes) => [
        for (var i = 0; i + hashWidthBytes <= bytes.length; i += hashWidthBytes)
          [
            for (var b = 0; b < hashWidthBytes; b++)
              bytes[i + b].toRadixString(16).padLeft(2, '0').toUpperCase()
          ].join()
      ];

  bool get _provenOnly => !config.allowInferredEndpoints;

  /// Egress candidates for routing. [candidates] is null when nothing is
  /// known at all, empty when doorsteps are known but none may start a
  /// route. [held] names the proven doorsteps the gate kept out, each
  /// with its reason; [gate] is the reason of the heaviest held one, for
  /// the flood when nothing survives.
  ({List<Candidate>? candidates, Map<String, FloodReason> held, FloodReason? gate})
      _egressCandidates(String self, int now) {
    final all = _evidence.candidatesFor(self, now, isSelf: true);
    if (all.isEmpty) return (candidates: null, held: const {}, gate: null);
    final eligible = _provenOnly ? all.where((c) => c.proven).toList() : all;
    final held = <String, FloodReason>{};
    FloodReason? gate;
    final kept = <Candidate>[];
    // candidatesFor sorts by weight, so the first held one is the heaviest.
    final cell = _cell;
    for (final c in eligible) {
      var hold = doorstepHold(c, now: now);
      var use = c;
      // Where the radio is known, a doorstep starts a route only if it
      // was heard hearing me around here and has not failed here since;
      // the level measured here replaces any measured elsewhere.
      if (hold == null && cell != null && c.repeaterHash != directHash) {
        final row = _places.rowIn(self, _nearCells, c.repeaterHash);
        if (row == null || row.failedHere) {
          hold = FloodReason.doorstepsNotHere;
        } else {
          use = c.withUplink(row.uplinkSnr);
        }
      }
      if (hold == null) {
        kept.add(use);
      } else {
        held[c.repeaterHash] = hold;
        gate ??= hold;
      }
    }
    return (candidates: kept, held: held, gate: gate);
  }

  /// Why [c], one of my proven doorsteps, may not start a route right now,
  /// or null when it may (see [PathGraphConfig.selfFailGate]). Failures
  /// are checked first: they are this doorstep's own record.
  FloodReason? doorstepHold(Candidate c, {int? now}) {
    final self = _selfPubkey;
    if (self == null || !c.isSelf || !c.proven) return null;
    if (c.failedSinceProof >= config.selfFailGate) {
      return FloodReason.doorstepsFailing;
    }
    now ??= _arrivalMillis;
    if (_staleMoving(c, now, byProof: true)) return FloodReason.doorstepsMoving;
    if (_isQuiet(c, now)) return FloodReason.doorstepsQuiet;
    return null;
  }

  /// Whether doorstep [c] of mine has gone quiet while others are heard
  /// ([PathGraphConfig.selfSilenceMinutes]).
  bool _isQuiet(Candidate c, int now) {
    final self = _selfPubkey;
    if (self == null) return false;
    final windowMs = (config.selfSilenceMinutes * 60 * 1000).round();
    final newest = _evidence
        .candidatesFor(self, now, isSelf: true)
        .fold(0, (m, x) => x.lastSeen > m ? x.lastSeen : m);
    return newest - c.lastSeen > windowMs &&
        _evidence.selfAliveEventsSince(newest - windowMs) >=
            config.selfSilenceMinEvents;
  }

  /// A contact's route end may be a doorstep proven by a delivery or one
  /// merely heard carrying their traffic: a repeater that hears a
  /// handheld reaches it (first-hop symmetry, 2026-09-25). Only rows
  /// that are neither — e.g. a DIRECT row minted by a delivered
  /// empty-path send — stay out.
  List<Candidate>? _ingressCandidates(String contactPubkey, int now) {
    final all = _evidence.candidatesFor(contactPubkey.toLowerCase(), now, isSelf: false);
    if (all.isEmpty) return null;
    return _freshRows(
        (_provenOnly ? all.where((c) => c.proven || c.heard) : all)
            .where((c) => !doorstepFailsThem(c))
            .toList(),
        now);
  }

  /// Whether [c], one of a contact's doorsteps, has failed my last direct
  /// sends to them since its last proven delivery
  /// ([PathGraphConfig.contactFailGate]).
  bool doorstepFailsThem(Candidate c) =>
      !c.isSelf &&
      c.repeaterHash != directHash &&
      c.failedSinceProof >= config.contactFailGate;

  /// Whether every doorstep known for [contactPubkey] is held by
  /// [doorstepFailsThem].
  bool _theirDoorstepsAllFailing(String contactPubkey, int now) {
    final all = _evidence.candidatesFor(contactPubkey, now, isSelf: false)
        .where((c) => c.repeaterHash != directHash)
        .toList();
    return all.isNotEmpty && all.every(doorstepFailsThem);
  }

  int get _mobileFreshMs => (config.mobileFreshMinutes * 60 * 1000).round();

  /// Repeaters whose moving tag acts on routing right now.
  Set<String> _movingNow(int now) => {
        for (final e in _store.nodes.entries)
          if (movingStatusOf(e.value, config, now)?.acts ?? false) e.key,
      };

  /// [c] sits on a moving repeater and was last refreshed longer ago than
  /// [PathGraphConfig.mobileFreshMinutes]: by its last proof when
  /// [byProof] (my end stays proven-only), else by its last sighting. My
  /// own row for one riding with me never goes stale.
  bool _staleMoving(Candidate c, int now, {bool byProof = false}) {
    final node = _store.nodes[c.repeaterHash];
    final status = node == null ? null : movingStatusOf(node, config, now);
    if (status == null || !status.acts) return false;
    if (c.isSelf && status.withMe) return false;
    final at = byProof ? (c.provenAt ?? 0) : c.lastSeen;
    return now - at > _mobileFreshMs;
  }

  List<Candidate> _freshRows(List<Candidate> rows, int now) =>
      rows.where((c) => !_staleMoving(c, now)).toList();

  RouteResult _toResult(RouteFound route) => RouteResult(
        _hopsToBytes(route.hops),
        route.estDelivery,
        hopProbabilities: route.hopProbabilities,
        guessedLinks: route.guessedLinks,
        egressProven: route.egressProven,
        ingressProven: route.ingressProven,
      );

  static Candidate _selfTarget(String repeaterHash) =>
      Candidate(repeaterHash.toUpperCase(), 1e9, EvidenceTier.proven,
          proven: true);

  Uint8List _hopsToBytes(List<String> hops) {
    final bytes = Uint8List(hops.length * hashWidthBytes);
    for (var i = 0; i < hops.length; i++) {
      for (var b = 0; b < hashWidthBytes; b++) {
        bytes[i * hashWidthBytes + b] =
            int.parse(hops[i].substring(b * 2, b * 2 + 2), radix: 16);
      }
    }
    return bytes;
  }

  /// Up to [count] genuinely divergent routes: after each find, its
  /// edges are penalized so the next search prefers different links
  /// (the retry ladder's alternative-path step, and the harness UI).
  List<RouteResult> findAlternatives(String contactPubkey, {int count = 3}) =>
      _alternatives(
          (now) => _ingressCandidates(contactPubkey, now) ?? const [], count,
          guessedFor: (now) => _hintGuesses(contactPubkey.toLowerCase(), now));

  /// Alternatives with a repeater itself as the destination.
  List<RouteResult> findAlternativesToRepeater(String repeaterHash,
          {int count = 3}) =>
      _alternatives((_) => [_selfTarget(repeaterHash)], count);

  List<RouteResult> _alternatives(
      List<Candidate> Function(int now) ingressFor, int count,
      {Set<(String, String)> Function(int now)? guessedFor}) {
    final now = _arrivalMillis;
    final self = _selfPubkey;
    if (self == null) return const [];
    return _divergentRoutes(
      egress: _egressCandidates(self, now).candidates ?? const [],
      ingress: ingressFor(now),
      count: count,
      now: now,
      guessed: guessedFor?.call(now) ?? const {},
    );
  }

  List<RouteResult> _divergentRoutes({
    required List<Candidate> egress,
    required List<Candidate> ingress,
    required int count,
    required int now,
    Set<(String, String)> guessed = const {},
  }) {
    if (egress.isEmpty || ingress.isEmpty) return const [];
    egress = List.of(egress);
    ingress = List.of(ingress);

    final finder = PathFinder(estimator.config, estimator);
    final moving = _movingNow(now);
    final links = finder.links(
        edges: _store.edges, nowMillis: now, moving: moving, guessed: guessed);
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
        moving: moving,
        adjacency: links,
      );
      if (route == null) break;
      final key = route.hops.join('>');
      if (seen.add(key)) results.add(_toResult(route));
      if (route.hops.length == 1) {
        // A one-hop route has no edge to penalise: the next search would
        // find it again. Take the hop off whichever end has others.
        final hop = route.hops.single;
        bool drop(List<Candidate> end) =>
            end.length > 1 &&
            (end..removeWhere((c) => c.repeaterHash == hop)).isNotEmpty;
        if (!drop(ingress) && !drop(egress)) break;
        continue;
      }
      for (var h = 0; h < route.hops.length - 1; h++) {
        final k = (route.hops[h], route.hops[h + 1]);
        penalties[k] = (penalties[k] ?? 0) + 1.4; // ≈ ×4 in probability
      }
    }
    return results;
  }

  /// The confidence the router prices a doorstep at (UI/debug): tally
  /// blended with the measured link when one exists.
  double doorstepConfidence(Candidate c) => PathFinder(estimator.config, estimator)
      .candidateConfidence(c, _arrivalMillis);

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
      _evidence.candidatesFor(contactPubkey.toLowerCase(), _arrivalMillis, isSelf: false);

  /// Staleness sweep: forget idle unconfirmed hearsay past the policy's
  /// age gate, drop stale position tags (row survives, coordinate goes),
  /// and enforce the growth caps. Infrastructure — attempt-counted or
  /// traced edges — is never aged out by idleness. Cheap; run on
  /// connect and daily. The report is for the UI: silent deletion of a
  /// user's learned map would be the wrong kind of surprise.
  RetentionReport sweepStale(
      {RetentionPolicy policy = const RetentionPolicy()}) {
    final report = Retention(_store, _evidence, _estimator, _places)
        .sweep(_arrivalMillis, policy);
    if (!report.isEmpty) _scheduleFlush();
    return report;
  }

  /// The privacy escape hatch ("Clear learned data"): wipes everything
  /// this radio learned — nodes, edges, counters, contact ingress,
  /// position tags. The graph relearns from the next packet. Flushes
  /// immediately.
  Future<void> clearLearnedData() async {
    Retention(_store, _evidence, _estimator, _places).clearLearnedData();
    _observationsApplied = 0;
    _droppedNarrow = 0;
    _linksHeld = 0;
    _heldLinks.clear();
    await flush();
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
  /// Everything in the graph was observed by this radio, so every edge
  /// with evidence is exported. Nothing is ever imported back: the graph
  /// learns only from the air, and a session checkpoint is the backup.
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
        if (e.firstObserved != null)
          'first_observed': _isoFromMillis(e.firstObserved!),
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
        if (mesh != null) 'mesh': mesh!.toJson(),
        if (regionHint != null) 'region_hint': regionHint,
        'hash_width': hashWidthBytes,
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
  /// doorstep by design. A session carries all of it, plus the in-memory
  /// hub counters, so a restore lands exactly where the save left off.
  /// It is the backup of what this radio learned. Keep it local —
  /// sharing one hands over a position-tagged log of who this radio
  /// talks to.
  ///
  /// Timestamps are raw arrival millis, not wire times: a session is a
  /// machine checkpoint, and converting them would only lose precision.
  ///
  /// Ordinary restarts do not need this — state persists in the
  /// database. It exists to checkpoint before an experiment and roll
  /// back after one.
  /// [includePlaces]: also the areas this radio has been heard in (the
  /// user is asked first; they are a coarse history of where it went).
  Map<String, dynamic> saveSession({bool includePlaces = false}) {
    return {
      'format': _sessionFormat,
      'private': true,
      'saved_at': _isoFromMillis(_arrivalMillis),
      'hash_width': hashWidthBytes,
      if (mesh != null) 'mesh': mesh!.toJson(),
      'self': {'pubkey': _selfPubkey, 'stride': _selfStride},
      'counters': {
        'observations_applied': _observationsApplied,
        'dropped_narrow': _droppedNarrow,
        'links_held': _linksHeld,
      },
      if (includePlaces && _places.rows.isNotEmpty) 'places': _places.toJson(),
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
            if (e.value.pubkey != null) 'pubkey': e.value.pubkey,
            if (e.value.movedAt != null) 'moved_at': e.value.movedAt,
            if (e.value.movingOverride != null)
              'moving_override': e.value.movingOverride!.name,
            if (e.value.autoMovingAt != null)
              'auto_moving_at': e.value.autoMovingAt,
            if (e.value.autoRidesWithMeAt != null)
              'auto_rides_with_me_at': e.value.autoRidesWithMeAt,
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
            if (e.value.firstObserved != null)
              'first_observed': e.value.firstObserved,
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
            if (e.value.provenAt != null) 'proven_at': e.value.provenAt,
            if (e.value.uplinkSnr != null) 'uplink_snr': e.value.uplinkSnr,
            if (e.value.downlinkSnr != null)
              'downlink_snr': e.value.downlinkSnr,
            'final_count': e.value.finalCount,
            'penultimate_count': e.value.penultimateCount,
            'proven_count': e.value.provenCount,
            if (e.value.floodProvenAt != null)
              'flood_proven_at': e.value.floodProvenAt,
            if (e.value.lastHeardAt != null)
              'last_heard_at': e.value.lastHeardAt,
            if (e.value.failedSinceProof != 0)
              'failed_since_proof': e.value.failedSinceProof,
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
    // Checkpoints from before the stamp existed were all width-2.
    final docWidth = (document['hash_width'] as num?)?.toInt() ?? 2;
    if (docWidth != hashWidthBytes) {
      throw FormatException(
          'checkpoint was saved at hash width $docWidth, this graph runs '
          'at $hashWidthBytes — widths cannot mix');
    }
    // Checkpoints from before meshes were stamped carry no mesh and are
    // taken on trust; a stamped one must match, since the same codes name
    // other repeaters on another preset.
    final docMesh = MeshId.fromJson(document['mesh']);
    if (docMesh != null && mesh != null && docMesh != mesh) {
      throw FormatException(
          'backup is from another mesh ($docMesh); this graph is for $mesh');
    }
    // Parse everything before touching anything: one bad row must not
    // leave the graph wiped and the restore failed.
    final nodes = <String, NodeState>{};
    final edges = <(String, String), EdgeState>{};
    final ingress = <(String, String), IngressEntry>{};
    final contacts = <String, ({String name, int lastRefreshed})>{};
    try {
      for (final raw in (document['nodes'] as List?) ?? const []) {
        final n = raw as Map;
        // Checkpoints from before imports were removed may carry
        // 'imported' nodes; they are plain observed nodes now.
        nodes[n['hash'] as String] = NodeState(
          source: n['source'] == 'advert' ? NodeSource.advert : NodeSource.observed,
          name: n['name'] as String?,
          role: n['role'] as String?,
          lat: (n['lat'] as num?)?.toDouble(),
          lon: (n['lon'] as num?)?.toDouble(),
          lastHeard: (n['last_heard'] as num?)?.toInt(),
          pubkey: n['pubkey'] as String?,
          movedAt: (n['moved_at'] as num?)?.toInt(),
          movingOverride: MovingOverride.values
              .where((v) => v.name == n['moving_override'])
              .firstOrNull,
          autoMovingAt: (n['auto_moving_at'] as num?)?.toInt(),
          autoRidesWithMeAt: (n['auto_rides_with_me_at'] as num?)?.toInt(),
        );
      }
      for (final raw in (document['edges'] as List?) ?? const []) {
        final e = raw as Map;
        edges[(e['from'] as String, e['to'] as String)] =
            EdgeState(
                source: e['source'] as String? ?? 'observed',
                firstObserved: (e['first_observed'] as num?)?.toInt())
              ..s = (e['s'] as num?)?.toInt() ?? 0
              ..n = (e['n'] as num?)?.toInt() ?? 0
              ..trafficWeight = (e['traffic_weight'] as num?)?.toDouble() ?? 0
              ..obsCount = (e['obs_count'] as num?)?.toInt() ?? 0
              ..lastObserved = (e['last_observed'] as num?)?.toInt()
              ..measuredSnr = (e['measured_snr'] as num?)?.toDouble();
      }
      for (final raw in (document['ingress'] as List?) ?? const []) {
        final i = raw as Map;
        ingress[(i['owner'] as String, i['repeater'] as String)] =
            IngressEntry(
          weight: (i['weight'] as num).toDouble(),
          lastSeen: (i['last_seen'] as num).toInt(),
          tier: EvidenceTier.values.byName(i['tier'] as String),
        )
              ..provenAt = (i['proven_at'] as num?)?.toInt()
              ..uplinkSnr = (i['uplink_snr'] as num?)?.toDouble()
              ..downlinkSnr = (i['downlink_snr'] as num?)?.toDouble()
              ..finalCount = (i['final_count'] as num?)?.toInt() ?? 0
              ..penultimateCount = (i['penultimate_count'] as num?)?.toInt() ?? 0
              // A checkpoint from before the count: a proven row was proven
              // at least once.
              ..provenCount = (i['proven_count'] as num?)?.toInt() ??
                  (i['proven_at'] == null ? 0 : 1)
              ..floodProvenAt = (i['flood_proven_at'] as num?)?.toInt()
              ..lastHeardAt = (i['last_heard_at'] as num?)?.toInt()
              ..failedSinceProof =
                  (i['failed_since_proof'] as num?)?.toInt() ?? 0;
      }
      for (final raw in (document['contacts'] as List?) ?? const []) {
        final c = raw as Map;
        contacts[c['pubkey'] as String] = (
          name: c['name'] as String,
          lastRefreshed: (c['last_refreshed'] as num).toInt(),
        );
      }
    } on TypeError catch (e) {
      throw FormatException('bad row in checkpoint: $e');
    } on ArgumentError catch (e) {
      throw FormatException('bad row in checkpoint: $e');
    }

    _flushTimer?.cancel();
    _flushTimer = null;
    await _store.clear();
    await _evidence.clear();
    _knownSince = null;
    _strangerNovelty.clear();
    _riderNovelty.clear();
    _vetoToldAt.clear();
    _heldLinks.clear();
    _store.nodes.addAll(nodes);
    _store.edges.addAll(edges);
    _evidence.entries.addAll(ingress);
    _evidence.knownContacts.addAll(contacts);

    // The live radio's identity wins: a checkpoint from another radio,
    // or saved at another stride, must not become it. Without a radio
    // (bench, offline) the checkpoint's is all there is.
    final self = (document['self'] as Map?) ?? const {};
    final pubkey = self['pubkey'] as String?;
    if (pubkey != null && _selfPubkey == null) {
      setRadioIdentity(pubkey, (self['stride'] as num?)?.toInt() ?? 2);
    }
    final counters = (document['counters'] as Map?) ?? const {};
    _observationsApplied =
        (counters['observations_applied'] as num?)?.toInt() ?? 0;
    _droppedNarrow = (counters['dropped_narrow'] as num?)?.toInt() ??
        (counters['dropped_1byte'] as num?)?.toInt() ??
        0;
    _linksHeld = (counters['links_held'] as num?)?.toInt() ?? 0;
    // A checkpoint saved without its areas restores none: the file is
    // the whole of what the graph then knows.
    _places.replaceAll(document['places']);

    _store.markAllDirty();
    _evidence.markAllDirty();
    _store.normalizeKeys();
    _evidence.normalizeKeys();
    await flush();
  }

  /// Best path to this contact: direct | bidirectional route | flood.
  /// A route starts only at a doorstep proven to hear this radio
  /// (unless [PathGraphConfig.allowInferredEndpoints] is set) and ends
  /// at one proven to reach the contact or heard carrying their
  /// packets — hearing a handheld is reaching it.
  PathResult findPath(String contactPubkey) {
    contactPubkey = contactPubkey.toLowerCase();
    final now = _arrivalMillis;

    // Tier 1: fresh direct-reception evidence → empty path wins. Their
    // packet arriving with no hops is the same symmetric evidence as a
    // delivered empty-path send.
    // A direct reception from before the radio moved to another area
    // says nothing about here.
    if (_evidence.hasFreshDirect(contactPubkey, now) &&
        (_movedAt == null ||
            _evidence.directSeenAt(contactPubkey) >= _movedAt!)) {
      return const PathResult.direct();
    }

    // Since the move, nothing of mine has reached them and their way back
    // ends where I no longer am: a route out would get there and its ACK
    // would not get back.
    if (_movedAt != null &&
        !_reachedSinceMove.contains(contactPubkey) &&
        !_theirWayBackEndsHere(contactPubkey)) {
      return const PathResult.flood(FloodReason.movedSinceTheyReachedMe);
    }

    // Tier 2: the route a flood of mine just took to them.
    final live = _liveRoute(contactPubkey, now);
    if (live != null) return live;

    // Tier 3: bidirectional route over candidate lists.
    final self = _selfPubkey;
    if (self == null) return const PathResult.flood(FloodReason.noEvidence);
    final mine = _egressCandidates(self, now);
    final egress = mine.candidates;
    final ingress = _ingressCandidates(contactPubkey, now);
    if (egress == null || ingress == null) {
      return const PathResult.flood(FloodReason.noEvidence);
    }
    if (egress.isEmpty) {
      return PathResult.flood(mine.gate ?? FloodReason.noProvenEndpoint);
    }
    if (ingress.isEmpty) {
      return PathResult.flood(_theirDoorstepsAllFailing(contactPubkey, now)
          ? FloodReason.theirDoorstepsFailing
          : FloodReason.noProvenEndpoint);
    }

    final route = PathFinder(estimator.config, estimator).search(
      egress: egress,
      ingress: ingress,
      edges: _store.edges,
      nowMillis: now,
      moving: _movingNow(now),
      guessed: _hintGuesses(contactPubkey, now),
    );
    if (route == null) {
      return const PathResult.flood(FloodReason.noCorridor);
    }
    return _toResult(route);
  }

  /// Hop count of their latest PATH reply's route while it is live, else
  /// null: the freshest distance to them the graph knows.
  int? liveRouteHops(String contactPubkey) {
    final live = _liveRoutes[contactPubkey.toLowerCase()];
    if (live == null) return null;
    if (_arrivalMillis - live.at > config.liveRouteMinutes * 60 * 1000) {
      return null;
    }
    return live.hops.length;
  }

  /// Their latest PATH reply's route while it leads, priced like any
  /// other route.
  RouteResult? _liveRoute(String contactPubkey, int now) {
    final live = _liveRoutes[contactPubkey];
    if (live == null) return null;
    if (now - live.at > config.liveRouteMinutes * 60 * 1000) {
      _liveRoutes.remove(contactPubkey);
      return null;
    }
    final self = _selfPubkey;
    // Its first hop may have failed my sends or gone quiet since.
    if (self != null &&
        _egressCandidates(self, now).held.containsKey(live.hops.first)) {
      return null;
    }
    // Its last hop may have failed my deliveries to them since.
    if (_evidence
        .candidatesFor(contactPubkey, now, isSelf: false)
        .any((c) => c.repeaterHash == live.hops.last && doorstepFailsThem(c))) {
      return null;
    }
    return _toResult(PathFinder(estimator.config, estimator).score(
      live.hops,
      egress: self == null
          ? const []
          : _evidence.candidatesFor(self, now, isSelf: true),
      ingress: _evidence.candidatesFor(contactPubkey, now, isSelf: false),
      edges: _store.edges,
      nowMillis: now,
    ));
  }

  PathGraphCounters get counters => PathGraphCounters(
        observationsApplied: _observationsApplied,
        droppedNarrow: _droppedNarrow,
        linksHeld: _linksHeld,
      );
}
