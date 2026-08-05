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

  void link(List<int> a, List<int> b) {
    graph.observePath(path([...a, ...b]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([...b, ...a]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
  }

  test('alternatives diverge: second route avoids the first corridor', () {
    graph.reportSendResult(path([0xA2, 0x77]), true);
    graph.observePath(path([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
    // Two disjoint corridors: direct link, and a detour via 5CBB.
    link([0xA2, 0x77], [0x13, 0x12]);
    link([0xA2, 0x77], [0x5C, 0xBB]);
    link([0x5C, 0xBB], [0x13, 0x12]);

    final alternatives = graph.findAlternatives(bobPk, count: 3);
    expect(alternatives.length, 2);
    expect(alternatives[0].pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(alternatives[1].pathBytes,
        [0xA2, 0x77, 0x5C, 0xBB, 0x13, 0x12]);
  });

  test('no candidates yields no alternatives', () {
    expect(graph.findAlternatives(bobPk), isEmpty);
  });
}
