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

  /// Confidence for virtual candidate edges. A Discover-measured link
  /// (dB, both directions) beats a tally: blend measured quality with
  /// the tally so a strong-but-new responder outranks a weak favourite.
  double _candidateConfidence(Candidate c) {
    final tally = (c.weight / (c.weight + 2)).clamp(0.05, 1.0);
    final snr = c.bestSnr;
    if (snr == null) return tally;
    final measured = estimator.snrQuality(snr);
    return (0.7 * measured + 0.3 * tally).clamp(0.05, 1.0);
  }

  RouteFound? search({
    required List<Candidate> egress,
    required List<Candidate> ingress,
    required Map<(String, String), EdgeState> edges,
    required int nowMillis,
    Map<(String, String), double> penalties = const {},
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
      (adjacency[from] ??= []).add((
        to,
        estimator.edgeCost(entry.value, nowMillis) +
            (penalties[entry.key] ?? 0),
      ));
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

    // est. delivery: doorstep confidence × forward-edge p × far-side
    // confidence. Without the candidate terms a 1-hop route has no
    // edges at all and reads 100% — a repeater merely HEARD once
    // (inferred, unproven in the sending direction) must not display
    // certainty the cost function never believed.
    final source =
        sources.where((s) => s.repeaterHash == hops.first).firstOrNull;
    final target =
        targets.where((t) => t.repeaterHash == hops.last).firstOrNull;
    var delivery = (source == null ? 1.0 : _candidateConfidence(source)) *
        (target == null ? 1.0 : _candidateConfidence(target));
    for (var i = 0; i < hops.length - 1; i++) {
      final e = edges[(hops[i], hops[i + 1])];
      if (e != null) {
        delivery *= estimator.calibratedP(e, nowMillis).clamp(0.01, 1.0);
      }
    }
    return RouteFound(hops, delivery);
  }
}
