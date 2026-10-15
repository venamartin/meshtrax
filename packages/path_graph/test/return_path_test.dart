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
    // The corridor has also been seen the other way (irrelevant here).
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

  test('return alternatives: the best corridor first, then one avoiding it',
      () {
    // Bob was heard through two doorsteps, each with a corridor seen
    // to 1312, the repeater I hear last.
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x13, 0x12, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0x22, 0x22, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x13, 0x12, 0x22, 0x22]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    final back = graph.findReturnAlternatives(bobPk);
    expect(back, hasLength(2));
    expect(back.first.pathBytes,
        (graph.findReturnPath(bobPk) as RouteResult).pathBytes,
        reason: 'the first alternative is the plain return path');
    expect(back[0].pathBytes.sublist(0, 2), isNot(back[1].pathBytes.sublist(0, 2)),
        reason: 'the second starts at the other doorstep');
  });

  test('return alternatives: nothing heard, or no radio, gives none', () {
    expect(graph.findReturnAlternatives(bobPk), isEmpty);
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    expect(graph.findReturnAlternatives(bobPk), isEmpty,
        reason: 'a delivery proves the way out, not the way back');
  });

  test('the way back needs only the direction their packet travelled', () {
    // Field (2026-10-13): the room's reply came room → 4000 → A277 → me.
    // Nothing has ever been heard going A277 → 4000, and nothing needs
    // to be: the packet itself is the proof for this direction.
    graph.observePath(path([0x40, 0x00, 0xA2, 0x77]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    expect(graph.findPath(bobPk), isA<FloodResult>(),
        reason: 'nothing proves any repeater hears me yet');
    final back = graph.findReturnPath(bobPk);
    expect(back, isA<RouteResult>());
    expect((back as RouteResult).pathBytes, [0x40, 0x00, 0xA2, 0x77]);
    expect(graph.findReturnAlternatives(bobPk).single.pathBytes,
        [0x40, 0x00, 0xA2, 0x77]);
  });
}
