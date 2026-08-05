import 'dart:math' as math;

import 'estimator.dart';
import 'evidence.dart';
import 'graph_store.dart';

class RouteFound {
  const RouteFound(this.hops, this.estDelivery);

  /// Repeater hash hex per hop, first hop = my doorstep.
  final List<String> hops;
  final double estDelivery;
}

/// Multi-source/multi-target Dijkstra over the bidirectional-usable
/// subgraph. Candidates enter through virtual edges costed by their
/// confidence; a loud dead-end loses to a quieter candidate with a
/// real route.
class PathFinder {
  const PathFinder(this.config, this.estimator);

  final PathGraphConfig config;
  final Estimator estimator;

  /// Tally → [0,1] confidence for virtual candidate edges.
  double _candidateConfidence(Candidate c) =>
      (c.weight / (c.weight + 2)).clamp(0.05, 1.0);

  RouteFound? search({
    required List<Candidate> egress,
    required List<Candidate> ingress,
    required Map<(String, String), EdgeState> edges,
    required int nowMillis,
  }) {
    final sources = egress.where((c) => c.repeaterHash != directHash).toList();
    final targets = ingress.where((c) => c.repeaterHash != directHash).toList();
    if (sources.isEmpty || targets.isEmpty) return null;

    // Bidirectional-usable adjacency: forward edge costed, both
    // directions must clear the threshold.
    final adjacency = <String, List<(String, double)>>{};
    for (final entry in edges.entries) {
      final (from, to) = entry.key;
      final reverse = edges[(to, from)];
      if (reverse == null) continue;
      if (!estimator.usable(entry.value, nowMillis) ||
          !estimator.usable(reverse, nowMillis)) {
        continue;
      }
      (adjacency[from] ??= [])
          .add((to, estimator.edgeCost(entry.value, nowMillis)));
    }

    const virtualSource = '<SRC>';
    final targetCost = {
      for (final t in targets)
        t.repeaterHash: -math.log(_candidateConfidence(t)),
    };

    final dist = <String, double>{virtualSource: 0};
    final hopsTo = <String, int>{virtualSource: 0};
    final prev = <String, String>{};
    final visited = <String>{};

    // Seed: virtual source → each egress candidate.
    for (final s in sources) {
      final cost = -math.log(_candidateConfidence(s));
      if (cost < (dist[s.repeaterHash] ?? double.infinity)) {
        dist[s.repeaterHash] = cost;
        hopsTo[s.repeaterHash] = 1;
        prev[s.repeaterHash] = virtualSource;
      }
    }

    String? bestTarget;
    var bestTotal = double.infinity;

    while (true) {
      String? u;
      var best = double.infinity;
      for (final e in dist.entries) {
        if (!visited.contains(e.key) && e.value < best) {
          best = e.value;
          u = e.key;
        }
      }
      if (u == null) break;
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

      for (final (v, cost) in adjacency[u] ?? const <(String, double)>[]) {
        if (visited.contains(v)) continue;
        final hops = hopsTo[u]! + 1;
        if (hops > config.maxHops) continue;
        final nd = dist[u]! + cost;
        if (nd < (dist[v] ?? double.infinity)) {
          dist[v] = nd;
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

    // est. delivery: product of forward-edge p along the route.
    var delivery = 1.0;
    for (var i = 0; i < hops.length - 1; i++) {
      final e = edges[(hops[i], hops[i + 1])];
      if (e != null) {
        delivery *= estimator.calibratedP(e, nowMillis).clamp(0.01, 1.0);
      }
    }
    return RouteFound(hops, delivery);
  }
}
