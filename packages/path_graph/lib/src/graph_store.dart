import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'db/database.dart';

/// Node metadata precedence: signed advert > anonymous observation.
enum NodeSource { observed, advert }

/// The user's word on whether a repeater moves; beats every detector.
enum MovingOverride {
  /// Someone else's moving repeater.
  moves,

  /// A repeater travelling with this radio (in my car).
  withMe,

  /// A fixed repeater, whatever the detectors say.
  staysPut,
}

class NodeState {
  NodeState({required this.source, this.name, this.role, this.lat, this.lon,
      this.lastHeard, this.pubkey, this.movedAt, this.movingOverride,
      this.autoMovingAt, this.autoRidesWithMeAt});

  NodeSource source;
  String? name;
  String? role;
  double? lat;
  double? lon;
  int? lastHeard; // arrival millis
  String? pubkey;

  /// Arrival millis of the last advert that put this repeater somewhere
  /// else (same key, both positions real).
  int? movedAt;
  MovingOverride? movingOverride;

  /// Watching-only detector results: arrival millis of the last time its
  /// traffic looked like a moving repeater, and like one riding with me.
  int? autoMovingAt;
  int? autoRidesWithMeAt;
}

/// One direction of one link, as this radio observed it. Nothing here
/// comes from anywhere but the air.
class EdgeState {
  EdgeState({required this.source, this.firstObserved});

  /// Attempt-counted evidence: deliveries, and attempts over all time.
  int s = 0;
  int n = 0;

  /// Failed attempts still held against the link, fading at read from
  /// [lastFailed] (arrival millis). A failure cannot say which hop broke,
  /// so it is a suspicion on every link of the route, never a fact.
  double failWeight = 0;
  int? lastFailed;

  /// Failures still held against the link at [nowMillis]: [failWeight]
  /// halves every [halfLifeHours] since [lastFailed].
  double failuresAt(int nowMillis, double halfLifeHours) {
    final last = lastFailed;
    if (last == null || failWeight == 0) return 0;
    final hours = (nowMillis - last) / (1000 * 60 * 60);
    if (hours <= 0) return failWeight;
    return failWeight * math.pow(0.5, hours / halfLifeHours);
  }

  /// One more failure at [arrival]. The weight held so far is faded to
  /// now first; adding to it as stored would re-date every old failure
  /// to now (review 2026-10-31: a link failing once a week never faded).
  void addFailure(int arrival, double halfLifeHours) {
    failWeight = failuresAt(arrival, halfLifeHours) + 1;
    lastFailed = arrival;
  }

  /// One failure counted at some time before [arrival] was no failure: it
  /// is taken off what is still held.
  void takeBackFailure(int arrival, double halfLifeHours) {
    final held = failuresAt(arrival, halfLifeHours);
    if (held == 0) return;
    failWeight = math.max(0, held - 1);
    lastFailed = arrival;
  }

  /// Sightings still held, fading from [lastObserved] as [failWeight] does
  /// from [lastFailed]: the link's weight.
  double trafficWeight = 0;
  int? lastObserved; // arrival millis

  /// Sightings still held at [nowMillis]: [trafficWeight] halves every
  /// [halfLifeHours] since [lastObserved].
  double trafficAt(int nowMillis, double halfLifeHours) {
    final last = lastObserved;
    if (last == null || trafficWeight == 0) return 0;
    final hours = (nowMillis - last) / (1000 * 60 * 60);
    if (hours <= 0) return trafficWeight;
    return trafficWeight * math.pow(0.5, hours / halfLifeHours);
  }

  /// [sightings] more at [arrival]. The weight held so far is faded to now
  /// first; adding to it as stored re-dated every old sighting to now, so
  /// one sighting gave a link busy weeks ago its whole count back.
  void addTraffic(int sightings, int arrival, double halfLifeHours) {
    trafficWeight = trafficAt(arrival, halfLifeHours) + sightings;
    lastObserved = arrival;
  }

  /// A weight stored before sightings faded as they were added is every
  /// sighting the link ever had. Brought down to what [obsCount] sightings
  /// at an even rate from [firstObserved] to [lastObserved] leave at the
  /// last one. Never raises a weight, so running it twice changes nothing.
  /// Replay of a field graph: with the lifetime counts kept, 81% of best
  /// routes held a link not heard for three days; converted, 10%.
  void fadeLifetimeCount(double halfLifeHours) {
    final last = lastObserved;
    if (last == null || trafficWeight <= 1) return;
    // A link from before first-seen times were kept is a month old at most
    // (the retention age).
    final first = firstObserved ?? last - 30 * 24 * 60 * 60 * 1000;
    final hours = math.max((last - first) / (1000 * 60 * 60), 1.0);
    final left = obsCount / hours * halfLifeHours / math.ln2 *
        (1 - math.pow(0.5, hours / halfLifeHours));
    trafficWeight = math.min(trafficWeight, math.max(left, 1.0));
  }

  /// Arrival millis of the first sighting; null for links from before it
  /// was kept (old).
  int? firstObserved;
  int obsCount = 0;
  String source;

  /// Trace-fed SNR EWMA: the only measurement of a middle hop.
  double? measuredSnr;
}

/// In-memory working set over the Drift durability layer. All hot
/// operations run here; dirty rows flush in one transaction.
class GraphStore {
  GraphStore(this._db,
      {this.hashWidthBytes = 2,
      this.failureHalfLifeHours = 24,
      this.trafficHalfLifeHours = 48});

  final PathGraphDatabase _db;
  final int hashWidthBytes;

  /// [PathGraphConfig.failureHalfLifeHours], for merging failure weights.
  final double failureHalfLifeHours;

  /// [PathGraphConfig.trafficHalfLifeHours], for adding and merging
  /// sightings.
  final double trafficHalfLifeHours;
  int get _hexWidth => hashWidthBytes * 2;

  final Map<String, NodeState> nodes = {};
  final Map<(String, String), EdgeState> edges = {};

  /// Called on every counted sighting of a link; [created] when the graph
  /// never had it.
  void Function(String from, String to, int arrivalMillis,
      {required bool created, int? firstObserved})? onLinkSeen;

  final Set<String> _dirtyNodes = {};
  final Set<(String, String)> _dirtyEdges = {};
  final Set<String> _deletedNodes = {};
  final Set<(String, String)> _deletedEdges = {};

  /// Recently applied (messageId, edge) pairs — union-per-message dedup
  /// across flood variants. Bounded FIFO.
  final Set<String> _seenMessageEdges = {};
  final List<String> _seenOrder = [];
  static const int _seenCap = 4096;

  NodeState nodeFor(String hash, NodeSource source) {
    return nodes.putIfAbsent(hash, () {
      _dirtyNodes.add(hash);
      return NodeState(source: source);
    });
  }

  /// [hash] was heard at [arrival]: minted if new, and saved either way.
  /// A time that only moved in memory read as weeks old after a restart
  /// and the node cap evicted repeaters in daily use (field 2026-10-22).
  void heard(String hash, NodeSource source, int arrival) {
    nodeFor(hash, source).lastHeard = arrival;
    _dirtyNodes.add(hash);
  }

  /// Applies one directed observation from→to. Returns false when the
  /// (messageId, edge) pair was already counted for this message.
  /// [heardBefore]: a link held back until heard again was first heard
  /// then; a new link counts both sightings.
  bool observeEdge(String from, String to, int arrivalMillis,
      {String? messageId, int? heardBefore}) {
    if (messageId != null) {
      final key = '$messageId|$from>$to';
      if (_seenMessageEdges.contains(key)) return false;
      _seenMessageEdges.add(key);
      _seenOrder.add(key);
      while (_seenOrder.length > _seenCap) {
        _seenMessageEdges.remove(_seenOrder.removeAt(0));
      }
    }

    heard(from, NodeSource.observed, arrivalMillis);
    heard(to, NodeSource.observed, arrivalMillis);

    var created = false;
    final edge = edges.putIfAbsent((from, to), () {
      created = true;
      return EdgeState(
          source: 'observed', firstObserved: heardBefore ?? arrivalMillis);
    });
    onLinkSeen?.call(from, to, arrivalMillis,
        created: created, firstObserved: edge.firstObserved);
    final sightings = created && heardBefore != null ? 2 : 1;
    edge.addTraffic(sightings, arrivalMillis, trafficHalfLifeHours);
    edge.obsCount += sightings;
    _dirtyEdges.add((from, to));
    return true;
  }

  /// Metadata enrichment respecting source precedence.
  void enrichNode(String hash, NodeSource source,
      {String? name, String? role, double? lat, double? lon, String? pubkey}) {
    final node = nodeFor(hash, source);
    final outranks = source.index >= node.source.index;
    if (outranks) {
      node.source = source;
      if (name != null) node.name = name;
      if (role != null) node.role = role;
      if (lat != null) node.lat = lat;
      if (lon != null) node.lon = lon;
      if (pubkey != null) node.pubkey = pubkey;
    } else {
      // Lower-precedence source fills blanks only.
      node.name ??= name;
      node.role ??= role;
      node.lat ??= lat;
      node.lon ??= lon;
      node.pubkey ??= pubkey;
    }
    _dirtyNodes.add(hash);
  }

  void markEdgeDirty(String from, String to) => _dirtyEdges.add((from, to));

  void markNodeDirty(String hash) => _dirtyNodes.add(hash);

  /// Retention removal. The row leaves memory now and the database on
  /// the next flush.
  void removeEdge(String from, String to) {
    final key = (from, to);
    if (edges.remove(key) == null) return;
    _dirtyEdges.remove(key);
    _deletedEdges.add(key);
  }

  void removeNode(String hash) {
    if (nodes.remove(hash) == null) return;
    _dirtyNodes.remove(hash);
    _deletedNodes.add(hash);
  }

  /// Session restore: drop everything, in memory and on disk.
  Future<void> clear() async {
    nodes.clear();
    edges.clear();
    _dirtyNodes.clear();
    _dirtyEdges.clear();
    _deletedNodes.clear();
    _deletedEdges.clear();
    _seenMessageEdges.clear();
    _seenOrder.clear();
    await _db.delete(_db.graphEdges).go();
    await _db.delete(_db.graphNodes).go();
  }

  /// The radio could hear nothing for [gapMillis] (the app was not
  /// connected): the sightings held are given back what that time will
  /// fade them by, so a link is no weaker for not having been listened
  /// for. Times are left as they are.
  void unfade(int gapMillis, double halfLifeHours) {
    final factor =
        math.pow(2, gapMillis / (1000 * 60 * 60) / halfLifeHours).toDouble();
    for (final entry in edges.entries) {
      if (entry.value.trafficWeight == 0) continue;
      entry.value.trafficWeight *= factor;
      _dirtyEdges.add(entry.key);
    }
  }

  /// [EdgeState.fadeLifetimeCount] for every link, once for a database
  /// from before sightings faded as they were added.
  void fadeLifetimeCounts() {
    for (final entry in edges.entries) {
      entry.value.fadeLifetimeCount(trafficHalfLifeHours);
      _dirtyEdges.add(entry.key);
    }
  }

  void markAllDirty() {
    _dirtyNodes.addAll(nodes.keys);
    _dirtyEdges.addAll(edges.keys);
  }

  /// Folds rows keyed by a wider-than-bucket hash into their bucket
  /// (hashes are pubkey prefixes, so truncation is the identity the
  /// rest of the graph already uses). Runs after load: heals databases
  /// and session files written before the mint was fixed.
  void normalizeKeys() {
    for (final hash
        in nodes.keys.where((k) => k.length > _hexWidth).toList()) {
      final ghost = nodes.remove(hash)!;
      _deletedNodes.add(hash);
      final bucket = hash.substring(0, _hexWidth);
      final target = nodes[bucket];
      if (target == null) {
        nodes[bucket] = ghost;
      } else {
        target
          ..name ??= ghost.name
          ..role ??= ghost.role
          ..lat ??= ghost.lat
          ..lon ??= ghost.lon
          ..pubkey ??= ghost.pubkey
          ..movingOverride ??= ghost.movingOverride;
        if ((ghost.lastHeard ?? 0) > (target.lastHeard ?? 0)) {
          target.lastHeard = ghost.lastHeard;
        }
        target
          ..movedAt = _newer(target.movedAt, ghost.movedAt)
          ..autoMovingAt = _newer(target.autoMovingAt, ghost.autoMovingAt)
          ..autoRidesWithMeAt =
              _newer(target.autoRidesWithMeAt, ghost.autoRidesWithMeAt);
      }
      _dirtyNodes.add(bucket);
    }

    for (final key in edges.keys
        .where((k) => k.$1.length > _hexWidth || k.$2.length > _hexWidth)
        .toList()) {
      final ghost = edges.remove(key)!;
      _deletedEdges.add(key);
      final bucket = (
        key.$1.substring(0, _hexWidth),
        key.$2.substring(0, _hexWidth)
      );
      final target = edges[bucket];
      if (target == null) {
        edges[bucket] = ghost;
      } else {
        target
          ..s += ghost.s
          ..n += ghost.n
          ..obsCount += ghost.obsCount
          ..measuredSnr ??= ghost.measuredSnr;
        // Both failure weights faded to the newer clock before they add.
        final failedAt = _newer(target.lastFailed, ghost.lastFailed);
        if (failedAt != null) {
          target.failWeight = target.failuresAt(failedAt, failureHalfLifeHours) +
              ghost.failuresAt(failedAt, failureHalfLifeHours);
          target.lastFailed = failedAt;
        }
        // The sightings the same way.
        final seenAt = _newer(target.lastObserved, ghost.lastObserved);
        if (seenAt != null) {
          target.trafficWeight =
              target.trafficAt(seenAt, trafficHalfLifeHours) +
                  ghost.trafficAt(seenAt, trafficHalfLifeHours);
          target.lastObserved = seenAt;
        }
        // The older first sighting; unknown (null) is the oldest.
        final a = target.firstObserved, b = ghost.firstObserved;
        target.firstObserved = a == null || b == null ? null : (a < b ? a : b);
      }
      _dirtyEdges.add(bucket);
    }
  }

  static int? _newer(int? a, int? b) =>
      a == null ? b : (b == null || a >= b ? a : b);

  Future<void> load() async {
    for (final row in await _db.select(_db.graphNodes).get()) {
      nodes[row.hashBytes] = NodeState(
        source: NodeSource.values.byName(row.source),
        name: row.name,
        role: row.role,
        lat: row.lat,
        lon: row.lon,
        lastHeard: row.lastHeard,
        pubkey: row.pubkey,
        movedAt: row.movedAt,
        movingOverride: MovingOverride.values
            .where((v) => v.name == row.movingOverride)
            .firstOrNull,
        autoMovingAt: row.autoMovingAt,
        autoRidesWithMeAt: row.autoRidesWithMeAt,
      );
    }
    for (final row in await _db.select(_db.graphEdges).get()) {
      edges[(row.fromHash, row.toHash)] =
          EdgeState(source: row.source, firstObserved: row.firstObserved)
        ..s = row.s
        ..n = row.n
        ..failWeight = row.failWeight
        ..lastFailed = row.lastFailed
        ..trafficWeight = row.trafficWeight
        ..lastObserved = row.lastObserved
        ..obsCount = row.obsCount
        ..measuredSnr = row.measuredSnr;
    }
  }

  Future<void> flush() async {
    if (_dirtyNodes.isEmpty &&
        _dirtyEdges.isEmpty &&
        _deletedNodes.isEmpty &&
        _deletedEdges.isEmpty) {
      return;
    }
    final dirtyNodes = _dirtyNodes.toList();
    final dirtyEdges = _dirtyEdges.toList();
    final deletedNodes = _deletedNodes.toList();
    final deletedEdges = _deletedEdges.toList();
    _dirtyNodes.clear();
    _dirtyEdges.clear();
    _deletedNodes.clear();
    _deletedEdges.clear();

    await _db.batch((batch) {
      // Deletes first: a hash removed by a sweep and re-observed before
      // the flush must end up inserted, not dropped.
      for (final key in deletedEdges) {
        batch.deleteWhere(
            _db.graphEdges,
            (t) =>
                t.fromHash.equals(key.$1) & t.toHash.equals(key.$2));
      }
      for (final hash in deletedNodes) {
        batch.deleteWhere(_db.graphNodes, (t) => t.hashBytes.equals(hash));
      }
      for (final hash in dirtyNodes) {
        final n = nodes[hash];
        if (n == null) continue;
        batch.insert(
          _db.graphNodes,
          GraphNodesCompanion.insert(
            hashBytes: hash,
            name: Value(n.name),
            role: Value(n.role),
            lat: Value(n.lat),
            lon: Value(n.lon),
            lastHeard: Value(n.lastHeard),
            source: n.source.name,
            pubkey: Value(n.pubkey),
            movedAt: Value(n.movedAt),
            movingOverride: Value(n.movingOverride?.name),
            autoMovingAt: Value(n.autoMovingAt),
            autoRidesWithMeAt: Value(n.autoRidesWithMeAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final key in dirtyEdges) {
        final e = edges[key];
        if (e == null) continue;
        batch.insert(
          _db.graphEdges,
          GraphEdgesCompanion.insert(
            fromHash: key.$1,
            toHash: key.$2,
            s: Value(e.s),
            n: Value(e.n),
            failWeight: Value(e.failWeight),
            lastFailed: Value(e.lastFailed),
            trafficWeight: Value(e.trafficWeight),
            lastObserved: Value(e.lastObserved),
            obsCount: Value(e.obsCount),
            source: e.source,
            measuredSnr: Value(e.measuredSnr),
            firstObserved: Value(e.firstObserved),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
