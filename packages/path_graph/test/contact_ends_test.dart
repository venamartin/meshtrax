import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

// Owner, 2026-11-27: "We know what we can hear and we know what can hear
// us. Pathfinder can fill in the middle." A contact's own MeshTrax says
// which repeaters it hears: a route to them ends on one of those.
void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory(),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    // A277 hears me; the corridor A277 -> 1312 is heard often.
    graph.reportSendResult(path([0xA2, 0x77]), true);
    for (var i = 0; i < 30; i++) {
      graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous(),
          lastHopHeard: false);
    }
  });

  tearDown(() => graph.dispose());

  test('a repeater they say they hear ends a route to them', () {
    expect(graph.findPath(bobPk), isA<FloodResult>(),
        reason: 'nothing is known of their end yet');

    graph.observeContactHears(bobPk, '1312', snr: 6);

    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(route.ingressProven, isTrue,
        reason: 'measured at their end, in the direction a send travels');
    final end = graph.ingressCandidates(bobPk).single;
    expect(end.repeaterHash, '1312');
    expect(end.uplinkSnr, 6);
  });

  test('without a level it still ends a route', () {
    graph.observeContactHears(bobPk, '1312');
    expect(graph.findPath(bobPk), isA<RouteResult>());
    expect(graph.ingressCandidates(bobPk).single.uplinkSnr, isNull);
  });

  test('a code of another width, or my own key, is not filed', () {
    graph.observeContactHears(bobPk, '13');
    graph.observeContactHears(selfPk, '1312');
    expect(graph.ingressCandidates(bobPk), isEmpty);
    expect(graph.counters.droppedNarrow, 1);
  });
}
