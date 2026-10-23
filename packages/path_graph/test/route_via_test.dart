import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory(),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    // My proven doorstep is A277; the trunk A277 <-> 1312 <-> 5CBB is
    // seen both ways; F857 has been seen only being reached from 5CBB.
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

  test('a leg seen only in the outbound direction is enough', () {
    final via = graph.findRouteVia('5CBB', 'F857') as RouteResult;
    expect(via.pathBytes, [0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB, 0xF8, 0x57]);
  });

  test('a leg seen only in the opposite direction is not', () {
    graph.observePath(path([0xE8, 0x00, 0x5C, 0xBB]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    expect((graph.findRouteVia('5CBB', 'E800') as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('no proven doorstep floods before any leg is tried', () async {
    final g = PathGraph(NativeDatabase.memory(),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await g.init();
    g.setRadioIdentity(selfPk, 2);
    g.observePath(path([0xA2, 0x77]), 2, const ObservationOrigin.anonymous());
    expect((g.findRouteVia('A277', '1312') as FloodResult).reason,
        FloodReason.noProvenEndpoint);
    await g.dispose();
  });

  group('route back from a repeater', () {
    // A packet that came in via 1312 then A277: I hear A277.
    void hearViaA277() =>
        graph.observePath(path([0x13, 0x12, 0xA2, 0x77]), 2,
            const ObservationOrigin.anonymous());

    test('runs B -> ... -> a repeater I hear', () {
      hearViaA277();
      final back = graph.findReturnPathFromRepeater('5CBB') as RouteResult;
      expect(back.pathBytes, [0x5C, 0xBB, 0x13, 0x12, 0xA2, 0x77]);
    });

    test('a link seen only the other way is not used back', () {
      hearViaA277();
      expect(
          (graph.findReturnPathFromRepeater('F857') as FloodResult).reason,
          FloodReason.noCorridor);
    });

    test('a repeater I hear is a one-hop route back', () {
      graph.observePath(path([0x5C, 0xBB]), 2,
          const ObservationOrigin.anonymous());
      final back = graph.findReturnPathFromRepeater('5CBB') as RouteResult;
      expect(back.pathBytes, [0x5C, 0xBB]);
    });

    test('alternatives back are distinct and start at the repeater', () {
      hearViaA277();
      graph.observePath(path([0x5C, 0xBB]), 2,
          const ObservationOrigin.anonymous());
      final alts = graph.findReturnAlternativesFromRepeater('5CBB');
      expect(alts.map((r) => r.pathBytes.toList()).toSet(), hasLength(alts.length));
      for (final r in alts) {
        expect(r.pathBytes.take(2), [0x5C, 0xBB]);
      }
      // I hear 5CBB directly, and the trunk is a second way back.
      expect(alts.map((r) => r.pathBytes.toList()), [
        [0x5C, 0xBB],
        [0x5C, 0xBB, 0x13, 0x12, 0xA2, 0x77],
      ]);
    });

    test('a one-hop route to a repeater leaves room for the corridor', () {
      // 5CBB proved it hears me too: it is a doorstep and the target.
      graph.reportSendResult(path([0x5C, 0xBB]), true);
      final alts = graph.findAlternativesToRepeater('5CBB');
      expect(alts.map((r) => r.pathBytes.toList()), [
        [0x5C, 0xBB],
        [0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB],
      ]);
    });

    test('nothing heard yet has no route back', () {
      expect(
          (graph.findReturnPathFromRepeater('5CBB') as FloodResult).reason,
          FloodReason.noEvidence);
    });
  });
}
