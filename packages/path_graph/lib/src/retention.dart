import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';

/// Retention knobs. Set [maxAgeDays] to null for a permanent map.
class RetentionPolicy {
  const RetentionPolicy({
    this.maxAgeDays = 30,
    this.positionTagDays = 7,
    this.maxNodes = 5000,
    this.maxEdges = 20000,
  });

  /// Idle hearsay older than this is forgotten. Null disables the age
  /// pass entirely (caps still apply).
  final int? maxAgeDays;

  /// Position tags run on their own, shorter clock: the coordinate is
  /// only useful for recent distance-gating and is the most sensitive
  /// thing stored. Ageing one out drops the column, never the row.
  final int positionTagDays;

  final int maxNodes;
  final int maxEdges;
}

/// What one sweep removed. Surfaced in the UI — silently deleting a
/// user's learned map would be the wrong kind of surprise.
class RetentionReport {
  const RetentionReport({
    this.edgesAged = 0,
    this.nodesAged = 0,
    this.ingressAged = 0,
    this.positionsCleared = 0,
    this.edgesEvicted = 0,
    this.nodesEvicted = 0,
  });

  final int edgesAged;
  final int nodesAged;
  final int ingressAged;
  final int positionsCleared;
  final int edgesEvicted;
  final int nodesEvicted;

  int get totalRemoved =>
      edgesAged + nodesAged + ingressAged + edgesEvicted + nodesEvicted;

  bool get isEmpty => totalRemoved == 0 && positionsCleared == 0;
}

/// Staleness sweep and growth caps.
///
/// Infrastructure is protected: repeater links do not get worse because
/// nobody used them this week, so an edge with attempt counts (we sent
/// through it, traced it, or a handshake proved it) or an imported prior
/// is never aged out by idleness. Only unconfirmed hearsay ages, plus
/// the genuinely perishable doorstep lists — people move even though
/// repeaters don't.
class Retention {
  const Retention(this._store, this._evidence, this._estimator);

  final GraphStore _store;
  final EvidenceStore _evidence;
  final Estimator _estimator;

  static const _trafficEpsilon = 0.05;
  static const _dayMillis = 24 * 60 * 60 * 1000;

  static bool _edgeProtected(EdgeState e) => e.n > 0 || e.hasImport;

  RetentionReport sweep(int nowMillis, RetentionPolicy policy) {
    var edgesAged = 0, nodesAged = 0, ingressAged = 0, positionsCleared = 0;

    final maxAgeDays = policy.maxAgeDays;
    if (maxAgeDays != null) {
      final cutoff = nowMillis - maxAgeDays * _dayMillis;

      for (final key in _store.edges.keys.toList()) {
        final e = _store.edges[key]!;
        if (_edgeProtected(e)) continue;
        if ((e.lastObserved ?? 0) >= cutoff) continue;
        if (_estimator.decayedTraffic(e, nowMillis) >= _trafficEpsilon) {
          continue;
        }
        _store.removeEdge(key.$1, key.$2);
        edgesAged++;
      }

      for (final key in _evidence.entries.keys.toList()) {
        if (_evidence.entries[key]!.lastSeen >= cutoff) continue;
        _evidence.removeEntry(key);
        ingressAged++;
      }

      final referenced = _referencedNodes();
      for (final hash in _store.nodes.keys.toList()) {
        final n = _store.nodes[hash]!;
        if (n.source != NodeSource.observed) continue;
        if (referenced.contains(hash)) continue;
        if ((n.lastHeard ?? 0) >= cutoff) continue;
        _store.removeNode(hash);
        nodesAged++;
      }
    }

    final positionCutoff = nowMillis - policy.positionTagDays * _dayMillis;
    for (final entry in _evidence.entries.entries) {
      final e = entry.value;
      if (e.observedLat == null && e.observedLon == null) continue;
      if (e.lastSeen >= positionCutoff) continue;
      e.observedLat = null;
      e.observedLon = null;
      _evidence.markDirty(entry.key);
      positionsCleared++;
    }

    return RetentionReport(
      edgesAged: edgesAged,
      nodesAged: nodesAged,
      ingressAged: ingressAged,
      positionsCleared: positionsCleared,
      edgesEvicted: _capEdges(nowMillis, policy.maxEdges),
      nodesEvicted: _capNodes(policy.maxNodes),
    );
  }

  Set<String> _referencedNodes() {
    final referenced = <String>{};
    for (final key in _store.edges.keys) {
      referenced
        ..add(key.$1)
        ..add(key.$2);
    }
    return referenced;
  }

  /// Backstop when the age pass cannot keep up. Unconfirmed hearsay goes
  /// first, lightest traffic first; attempt-counted and imported rows are
  /// evicted last, and only because a hard cap has to be hard.
  int _capEdges(int nowMillis, int maxEdges) {
    final over = _store.edges.length - maxEdges;
    if (over <= 0) return 0;

    final ranked = _store.edges.entries.toList()
      ..sort((a, b) {
        final pa = _edgeProtected(a.value), pb = _edgeProtected(b.value);
        if (pa != pb) return pa ? 1 : -1;
        return _estimator
            .decayedTraffic(a.value, nowMillis)
            .compareTo(_estimator.decayedTraffic(b.value, nowMillis));
      });

    for (var i = 0; i < over; i++) {
      _store.removeEdge(ranked[i].key.$1, ranked[i].key.$2);
    }
    return over;
  }

  int _capNodes(int maxNodes) {
    final over = _store.nodes.length - maxNodes;
    if (over <= 0) return 0;

    final referenced = _referencedNodes();
    bool protectedNode(String hash, NodeState n) =>
        n.source != NodeSource.observed || referenced.contains(hash);

    final ranked = _store.nodes.entries.toList()
      ..sort((a, b) {
        final pa = protectedNode(a.key, a.value);
        final pb = protectedNode(b.key, b.value);
        if (pa != pb) return pa ? 1 : -1;
        return (a.value.lastHeard ?? 0).compareTo(b.value.lastHeard ?? 0);
      });

    for (var i = 0; i < over; i++) {
      _store.removeNode(ranked[i].key);
    }
    return over;
  }

  /// The privacy escape hatch: wipe everything this radio learned and
  /// keep the community starter map. Imported priors survive (they go
  /// separately, by region); local counters on an imported edge are
  /// zeroed rather than deleted so the prior stays intact.
  void clearLearnedData() {
    for (final key in _store.edges.keys.toList()) {
      final e = _store.edges[key]!;
      if (!e.hasImport) {
        _store.removeEdge(key.$1, key.$2);
        continue;
      }
      e
        ..s = 0
        ..n = 0
        ..trafficWeight = 0
        ..obsCount = 0
        ..lastObserved = null
        ..measuredSnr = null
        ..source = 'imported';
      _store.markEdgeDirty(key.$1, key.$2);
    }

    final referenced = _referencedNodes();
    for (final hash in _store.nodes.keys.toList()) {
      final n = _store.nodes[hash]!;
      if (n.source == NodeSource.imported || referenced.contains(hash)) {
        n.lastHeard = null;
        _store.markNodeDirty(hash);
        continue;
      }
      _store.removeNode(hash);
    }

    for (final key in _evidence.entries.keys.toList()) {
      _evidence.removeEntry(key);
    }
  }
}
