import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    // My proven doorstep is A277; the trunk A277 <-> 1312 <-> 5CBB is
    // proven both ways; F857 is reachable one way only.
    graph.reportSendResult(path([0xA2, 0x77]), true);
    void link(List<int> a, List<int> b) {
      graph.observePath(path([...a, ...b]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
      graph.observePath(path([...b, ...a]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
    }

    link([0xA2, 0x77], [0x13, 0x12]);
    link([0x13, 0x12], [0x5C, 0xBB]);
    graph.observePath(path([0x5C, 0xBB, 0xF8, 0x57]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
  });

  tearDown(() => graph.dispose());

  test('routes me -> A -> B along the proven trunk', () {
    final result = graph.findRouteVia('1312', '5CBB');
    expect(result, isA<RouteResult>());
    final route = result as RouteResult;
    expect(route.pathBytes, [0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB]);
    expect(route.hopProbabilities, hasLength(2));
    expect(route.egressProven, isTrue);
  });

  test('A == B is the plain route to that repeater', () {
    final via = graph.findRouteVia('5CBB', '5CBB') as RouteResult;
    final plain = graph.findPathToRepeater('5CBB') as RouteResult;
    expect(via.pathBytes, plain.pathBytes);
  });

  test('a one-way leg floods rather than guessing', () {
    expect((graph.findRouteVia('5CBB', 'F857') as FloodResult).reason,
        FloodReason.noBidirectionalRoute);
  });

  test('no proven doorstep floods before any leg is tried', () async {
    final g = PathGraph(NativeDatabase.memory());
    await g.init();
    g.setRadioIdentity(selfPk, 2);
    g.observePath(path([0xA2, 0x77]), 2, const ObservationOrigin.anonymous());
    expect((g.findRouteVia('A277', '1312') as FloodResult).reason,
        FloodReason.noProvenEndpoint);
    await g.dispose();
  });
}
