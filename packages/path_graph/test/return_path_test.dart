import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  test('their heard-from doorstep to my heard-last doorstep', () {
    // Bob's message arrived A277 -> 1312 -> me: A277 heard Bob, I heard
    // 1312. Forward that is a guess; backward it is the proof.
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    // The corridor is known both ways.
    graph.observePath(path([0x13, 0x12, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    expect(graph.findPath(bobPk), isA<FloodResult>(),
        reason: 'nothing proven toward Bob');
    final back = graph.findReturnPath(bobPk);
    expect(back, isA<RouteResult>());
    expect((back as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(back.egressProven, isTrue);
    expect(back.ingressProven, isTrue);
  });

  test('a delivered send alone says nothing about the way back', () {
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    expect((graph.findReturnPath(bobPk) as FloodResult).reason,
        FloodReason.noEvidence);
  });
}
