import 'dart:math' as math;

import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';

class RouteFound {
  const RouteFound(this.hops, this.estDelivery, this.hopProbabilities,
      {required this.egressProven, required this.ingressProven});

  /// Repeater hash hex per hop, first hop = my doorstep.
  final List<String> hops;
  final double estDelivery;

  /// Calibrated p of each between-hop link, hops[i]→hops[i+1].
  final List<double> hopProbabilities;

  /// Whether each end of the route was proven in the sending direction.
  final bool egressProven;
  final bool ingressProven;
}

/// Multi-source/multi-target Dijkstra over the bidirectional-usable
/// subgraph. Candidates enter through virtual edges costed by their
/// confidence; a loud dead-end loses to a quieter candidate with a
/// real route.
class PathFinder {
  const PathFinder(this.config, this.estimator);

  final PathGraphConfig config;
  final Estimator estimator;

  /// Confidence for virtual candidate edges. A measured link (dB from a
  /// Discover answer or a trace, in the sending direction) beats a tally:
  /// blend measured quality with the tally so a strong-but-new responder
  /// outranks a weak favourite. The measured part fades with the tally
  /// and with the age of the last proof — a level measured somewhere I no
  /// longer am must not hold a doorstep up (field 2026-10-14: 11.9 dB
  /// kept a doorstep 20 miles away at 99%; 2026-10-17: +11.6 dB measured
  /// at home kept it first 40 km away through two halvings). At full
  /// weight and a fresh proof it is the plain blend.
  double candidateConfidence(Candidate c, int nowMillis) {
    final tally = (c.weight / (c.weight + 2)).clamp(0.05, 1.0);
    final snr = c.sendingSnr;
    if (snr == null) return tally;
    final fullTally = config.selfWeightCap / (config.selfWeightCap + 2);
    final freshness = (tally / fullTally).clamp(0.0, 1.0);
    final proofAge = nowMillis - (c.provenAt ?? c.lastSeen);
    final proofFade = proofAge <= 0
        ? 1.0
        : math.pow(0.5, proofAge / (config.measuredSnrHalfLifeMinutes * 60000))
            .toDouble();
    final measured = estimator.snrQuality(snr);
    return (0.7 * measured * freshness * proofFade + 0.3 * tally)
        .clamp(0.05, 1.0);
  }

  /// Doorstep cost: strength dominates corridor length
  /// ([PathGraphConfig.doorstepWeight]).
  double _doorstepCost(Candidate c, int nowMillis) =>
      config.doorstepWeight * -math.log(candidateConfidence(c, nowMillis));

  /// The usable links, each with its cost, by the repeater it leaves. A
  /// link is usable in the direction packets were seen to travel it, and
  /// only that direction. The graph never infers the reverse, and it
  /// demands nothing about the reverse either (owner, 2026-10-13): a
  /// route is a chain of links each observed the way the packet will go.
  /// Quality is priced per link and per doorstep. A link touching a
  /// [moving] repeater counts only while fresh
  /// ([PathGraphConfig.mobileFreshMinutes]).
  ///
  /// Built once for a run of searches at one instant (the alternatives);
  /// each search adds its own penalties.
  Map<String, List<(String, (String, String), double)>> links({
    required Map<(String, String), EdgeState> edges,
    required int nowMillis,
    Set<String> moving = const {},
  }) {
    final freshMs = (config.mobileFreshMinutes * 60 * 1000).round();
    final adjacency = <String, List<(String, (String, String), double)>>{};
    for (final entry in edges.entries) {
      final (from, to) = entry.key;
      if (!estimator.usable(entry.value, nowMillis)) continue;
      if ((moving.contains(from) || moving.contains(to)) &&
          nowMillis - (entry.value.lastObserved ?? 0) > freshMs) {
        continue;
      }
      (adjacency[from] ??= [])
          .add((to, entry.key, estimator.edgeCost(entry.value, nowMillis)));
    }
    return adjacency;
  }

  /// [adjacency] from [links] at the same [nowMillis] and [moving], or
  /// null to build it here.
  RouteFound? search({
    required List<Candidate> egress,
    required List<Candidate> ingress,
    required Map<(String, String), EdgeState> edges,
    required int nowMillis,
    Map<(String, String), double> penalties = const {},
    Set<String> moving = const {},
    Map<String, List<(String, (String, String), double)>>? adjacency,
  }) {
    final sources = egress.where((c) => c.repeaterHash != directHash).toList();
    final targets = ingress.where((c) => c.repeaterHash != directHash).toList();
    if (sources.isEmpty || targets.isEmpty) return null;

    adjacency ??= links(edges: edges, nowMillis: nowMillis, moving: moving);

    const virtualSource = '<SRC>';
    final targetCost = {
      for (final t in targets) t.repeaterHash: _doorstepCost(t, nowMillis),
    };

    final dist = <String, double>{};
    final hopsTo = <String, int>{virtualSource: 0};
    final prev = <String, String>{};
    final visited = <String>{};
    // Next to settle: the cheapest, and of equal costs the one reached
    // first — so a tie always goes the same way.
    final reachedAt = <String, int>{};
    final queue = _Queue();
    void reach(String node, double cost) {
      dist[node] = cost;
      queue.add(
          cost, reachedAt.putIfAbsent(node, () => reachedAt.length), node);
    }

    reach(virtualSource, 0);
    // Seed: virtual source → each egress candidate.
    for (final s in sources) {
      final cost = _doorstepCost(s, nowMillis);
      if (cost < (dist[s.repeaterHash] ?? double.infinity)) {
        reach(s.repeaterHash, cost);
        hopsTo[s.repeaterHash] = 1;
        prev[s.repeaterHash] = virtualSource;
      }
    }

    String? bestTarget;
    var bestTotal = double.infinity;

    while (queue.isNotEmpty) {
      final (cost, u) = queue.removeFirst();
      // A node is queued again each time it gets cheaper; only its
      // cheapest entry counts.
      if (visited.contains(u) || cost != dist[u]) continue;
      visited.add(u);

      // Reaching any target closes a route via its virtual edge.
      final tCost = targetCost[u];
      if (tCost != null) {
        final total = dist[u]! + tCost;
        if (total < bestTotal) {
          bestTotal = total;
          bestTarget = u;
        }
      }

      for (final (v, key, base)
          in adjacency[u] ?? const <(String, (String, String), double)>[]) {
        if (visited.contains(v)) continue;
        final hops = hopsTo[u]! + 1;
        if (hops > config.maxHops) continue;
        final nd = dist[u]! + (base + (penalties[key] ?? 0));
        if (nd < (dist[v] ?? double.infinity)) {
          reach(v, nd);
          hopsTo[v] = hops;
          prev[v] = u;
        }
      }
    }

    if (bestTarget == null) return null;

    final hops = <String>[];
    String? cur = bestTarget;
    while (cur != null && cur != virtualSource) {
      hops.insert(0, cur);
      cur = prev[cur];
    }
    return score(hops,
        egress: sources, ingress: targets, edges: edges, nowMillis: nowMillis);
  }

  /// [hops] priced as a route. est. delivery: doorstep confidence ×
  /// forward-edge p × far-side confidence. Without the candidate terms a
  /// 1-hop route has no edges at all and reads 100% — a repeater merely
  /// HEARD once (inferred, unproven in the sending direction) must not
  /// display certainty the cost function never believed.
  RouteFound score(
    List<String> hops, {
    required List<Candidate> egress,
    required List<Candidate> ingress,
    required Map<(String, String), EdgeState> edges,
    required int nowMillis,
  }) {
    final source =
        egress.where((s) => s.repeaterHash == hops.first).firstOrNull;
    final target =
        ingress.where((t) => t.repeaterHash == hops.last).firstOrNull;
    var delivery =
        (source == null ? 1.0 : candidateConfidence(source, nowMillis)) *
            (target == null ? 1.0 : candidateConfidence(target, nowMillis));
    final hopProbabilities = <double>[];
    for (var i = 0; i < hops.length - 1; i++) {
      final e = edges[(hops[i], hops[i + 1])];
      final p = e == null
          ? 1.0
          : estimator.calibratedP(e, nowMillis).clamp(0.01, 1.0);
      hopProbabilities.add(p);
      delivery *= p;
    }
    return RouteFound(hops, delivery, hopProbabilities,
        egressProven: source?.proven ?? false,
        ingressProven: target?.proven ?? false);
  }
}

/// A binary min-heap of (cost, reached-at order, node).
class _Queue {
  final _items = <(double, int, String)>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void _swap(int a, int b) {
    final t = _items[a];
    _items[a] = _items[b];
    _items[b] = t;
  }

  static bool _before((double, int, String) a, (double, int, String) b) =>
      a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 < b.$2);

  void add(double cost, int order, String node) {
    _items.add((cost, order, node));
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (!_before(_items[i], _items[parent])) break;
      _swap(i, parent);
      i = parent;
    }
  }

  (double, String) removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final left = 2 * i + 1;
        if (left >= _items.length) break;
        final right = left + 1;
        final child =
            right < _items.length && _before(_items[right], _items[left])
                ? right
                : left;
        if (!_before(_items[child], _items[i])) break;
        _swap(i, child);
        i = child;
      }
    }
    return (first.$1, first.$3);
  }
}
