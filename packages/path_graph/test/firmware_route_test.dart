import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

/// A route the firmware learned (a contact's out_path) proves both
/// doorsteps but says nothing about how good the corridor is: it is the
/// first flood copy to arrive, a race won on hop count.
void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  final firmwareRoute = path([0xA2, 0x77, 0x10, 0x00]);

  void learnFirmwareRoute() => graph.reportSendResult(firmwareRoute, true,
      contactPubkey: bobPk, stride: 2, tally: false);

  test('proves the doorsteps and marks the corridor seen, no tally', () {
    learnFirmwareRoute();
    final snap = graph.snapshot();
    final edge = snap.edges[('A277', '1000')]!;
    expect(edge.s, 0);
    expect(edge.n, 0);
    expect(edge.obsCount, 1);
    expect(snap.edges.containsKey(('1000', 'A277')), isFalse,
        reason: 'the return direction is never inferred');
    expect(graph.egressCandidates().map((c) => c.repeaterHash), ['A277']);
    expect(graph.ingressCandidates(bobPk).map((c) => c.repeaterHash), ['1000']);
  });

  test('a corridor known only from a firmware route is routable at prior quality',
      () {
    // The login that earned the route walked A277 -> 1000 in the sending
    // direction; that is the evidence a route needs (owner, 2026-10-13).
    learnFirmwareRoute();
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    final route = result as RouteResult;
    expect(route.pathBytes, firmwareRoute);
    expect(route.hopProbabilities.single, closeTo(0.5, 0.05),
        reason: 'seen once, never tallied: the prior, not a measurement');
  });

  test('the return direction changes nothing for the route out', () {
    learnFirmwareRoute();
    final before = (graph.findPath(bobPk) as RouteResult).estDelivery;
    graph.observePath(path([0x10, 0x00, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    expect((graph.findPath(bobPk) as RouteResult).estDelivery,
        closeTo(before, 1e-6));
  });

  test('loses to a corridor we have delivered on', () {
    learnFirmwareRoute();
    graph.observePath(path([0x10, 0x00, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    final longer = path([0xA2, 0x77, 0xA1, 0x77, 0x10, 0x00]);
    for (var i = 0; i < 5; i++) {
      graph.reportSendResult(longer, true, contactPubkey: bobPk, stride: 2);
    }
    graph.observePath(path([0x10, 0x00, 0xA1, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0xA1, 0x77, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, longer);
  });
}
