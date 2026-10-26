import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/screens/path_graph_screen.dart';
import 'package:path_graph/path_graph.dart';

// Pathfinder's order is its ranking, not the % shown: a live route leads,
// and the end repeaters weigh three times their share of the % (field rule
// 2026-09-25). When a later route reads a higher %, the first says why
// (owner, 2026-10-26: "putting paths with smaller chance at the top").
RouteResult _route(
  List<int> bytes,
  double p, {
  List<double> links = const [],
  int? liveAgeMillis,
}) =>
    RouteResult(Uint8List.fromList(bytes), p,
        hopProbabilities: links, liveAgeMillis: liveAgeMillis);

void main() {
  String? why(List<PathResult> shown) => routeLeadReason(
      shown.first as RouteResult, shown,
      liveRouteMinutes: 10);

  test('says nothing when the order agrees with the %', () {
    expect(why([_route([1, 2], 0.6), _route([3, 4], 0.4)]), isNull);
  });

  test('a live route says how long ago the flood took it', () {
    expect(
      why([
        _route([1, 2], 0.3, liveAgeMillis: 4 * 60000),
        _route([3, 4], 0.6),
      ]),
      'First because a flood of yours reached them this way 4 min ago: '
      'that route leads for 10 minutes',
    );
  });

  test('stronger end repeaters lead a higher %', () {
    // Ends 0.72 over a 0.5 link (36%) against ends 0.4 at one hop (40%).
    expect(
      why([_route([1, 2, 3, 4], 0.36, links: [0.5]), _route([5, 6], 0.40)]),
      startsWith('First because its end repeaters hear better'),
    );
  });

  test('fewer hops lead a higher %', () {
    // One hop with ends 0.45 against two hops with ends 0.5.
    expect(
      why([_route([1, 2], 0.45), _route([5, 6, 7, 8], 0.5, links: [1.0])]),
      startsWith('First because it has fewer hops'),
    );
  });
}
