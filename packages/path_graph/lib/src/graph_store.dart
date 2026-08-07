import 'package:drift/drift.dart';

import 'db/database.dart';

/// Node metadata precedence: signed advert > import > anonymous
/// observation (see design doc, import semantics).
enum NodeSource { observed, imported, advert }

class NodeState {
  NodeState({required this.source, this.name, this.role, this.lat, this.lon,
      this.lastHeard, this.region, this.pubkey});

  NodeSource source;
  String? name;
  String? role;
  double? lat;
  double? lon;
  int? lastHeard; // arrival millis
  String? region;
  String? pubkey;
}

class EdgeState {
  EdgeState({required this.source});

  /// Attempt-counted local evidence (never touched by imports).
  int s = 0;
  int n = 0;

  /// Passive-sighting accumulation (decay applied at read).
  double trafficWeight = 0;
  int? lastObserved; // arrival millis
  int obsCount = 0;
  String source;

  // Import layer (meshtrax-graph-v2, replaced wholesale per collector).
  // Somebody else's measurements of THIS direction — never merged into
  // the local counters above, never copied to the reverse edge.
  double? importedSnr;
  int importedObservations = 0;
  int importedDelivered = 0;
  int importedAttempts = 0;
  int? importedLastObserved;

  // Local layer: trace-fed SNR EWMA.
  double? measuredSnr;

  /// Anything at all in the import layer?
  bool get hasImport =>
      importedSnr != null || importedObservations > 0 || importedAttempts > 0;
}

/// In-memory working set over the Drift durability layer. All hot
/// operations run here; dirty rows flush in one transaction.
class GraphStore {
  GraphStore(this._db);

  final PathGraphDatabase _db;

  final Map<String, NodeState> nodes = {};
  final Map<(String, String), EdgeState> edges = {};

  final Set<String> _dirtyNodes = {};
  final Set<(String, String)> _dirtyEdges = {};

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

  /// Applies one directed observation from→to. Returns false when the
  /// (messageId, edge) pair was already counted for this message.
  bool observeEdge(String from, String to, int arrivalMillis,
      {String? messageId}) {
    if (messageId != null) {
      final key = '$messageId|$from>$to';
      if (_seenMessageEdges.contains(key)) return false;
      _seenMessageEdges.add(key);
      _seenOrder.add(key);
      while (_seenOrder.length > _seenCap) {
        _seenMessageEdges.remove(_seenOrder.removeAt(0));
      }
    }

    nodeFor(from, NodeSource.observed).lastHeard = arrivalMillis;
    nodeFor(to, NodeSource.observed).lastHeard = arrivalMillis;

    final edge = edges.putIfAbsent(
        (from, to), () => EdgeState(source: 'observed'));
    edge.trafficWeight += 1;
    edge.obsCount += 1;
    edge.lastObserved = arrivalMillis;
    _dirtyEdges.add((from, to));
    return true;
  }

  /// Metadata enrichment respecting source precedence.
  void enrichNode(String hash, NodeSource source,
      {String? name, String? role, double? lat, double? lon, String? pubkey,
      String? region}) {
    final node = nodeFor(hash, source);
    final outranks = source.index >= node.source.index;
    if (outranks) {
      node.source = source;
      if (name != null) node.name = name;
      if (role != null) node.role = role;
      if (lat != null) node.lat = lat;
      if (lon != null) node.lon = lon;
      if (pubkey != null) node.pubkey = pubkey;
      if (region != null) node.region = region;
    } else {
      // Lower-precedence source fills blanks only.
      node.name ??= name;
      node.role ??= role;
      node.lat ??= lat;
      node.lon ??= lon;
      node.pubkey ??= pubkey;
      node.region ??= region;
    }
    _dirtyNodes.add(hash);
  }

  void markEdgeDirty(String from, String to) => _dirtyEdges.add((from, to));

  Future<void> load() async {
    for (final row in await _db.select(_db.graphNodes).get()) {
      nodes[row.hashBytes] = NodeState(
        source: NodeSource.values.byName(row.source),
        name: row.name,
        role: row.role,
        lat: row.lat,
        lon: row.lon,
        lastHeard: row.lastHeard,
        region: row.region,
        pubkey: row.pubkey,
      );
    }
    for (final row in await _db.select(_db.graphEdges).get()) {
      edges[(row.fromHash, row.toHash)] = EdgeState(source: row.source)
        ..s = row.s
        ..n = row.n
        ..trafficWeight = row.trafficWeight
        ..lastObserved = row.lastObserved
        ..obsCount = row.obsCount
        ..importedSnr = row.importedSnr
        ..importedObservations = row.importedObservations
        ..importedDelivered = row.importedDelivered
        ..importedAttempts = row.importedAttempts
        ..importedLastObserved = row.importedLastObserved
        ..measuredSnr = row.measuredSnr;
    }
  }

  Future<void> flush() async {
    if (_dirtyNodes.isEmpty && _dirtyEdges.isEmpty) return;
    final dirtyNodes = _dirtyNodes.toList();
    final dirtyEdges = _dirtyEdges.toList();
    _dirtyNodes.clear();
    _dirtyEdges.clear();

    await _db.batch((batch) {
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
            region: Value(n.region),
            pubkey: Value(n.pubkey),
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
            trafficWeight: Value(e.trafficWeight),
            lastObserved: Value(e.lastObserved),
            obsCount: Value(e.obsCount),
            source: e.source,
            importedSnr: Value(e.importedSnr),
            importedObservations: Value(e.importedObservations),
            importedDelivered: Value(e.importedDelivered),
            importedAttempts: Value(e.importedAttempts),
            importedLastObserved: Value(e.importedLastObserved),
            measuredSnr: Value(e.measuredSnr),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
