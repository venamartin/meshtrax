import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
  });

  tearDown(() => graph.dispose());

  test('empty module floods with noEvidence', () {
    final result = graph.findPath('aa' * 32);
    expect(result, isA<FloodResult>());
    expect((result as FloodResult).reason, FloodReason.noEvidence);
  });

  test('observePath rejects 1-byte stride and counts the drop', () {
    graph.observePath(
      Uint8List.fromList([0xA2, 0x77]),
      1,
      const ObservationOrigin.anonymous(),
    );
    expect(graph.counters.dropped1Byte, 1);
    expect(graph.counters.observationsApplied, 0);
  });

  test('observePath accepts 2-byte stride', () {
    graph.observePath(
      Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]),
      2,
      const ObservationOrigin.anonymous(),
    );
    expect(graph.counters.observationsApplied, 1);
    expect(graph.counters.dropped1Byte, 0);
  });

  test('radio identity is stored', () {
    graph.setRadioIdentity('ab' * 32, 2);
    expect(graph.selfPubkey, 'ab' * 32);
    expect(graph.selfStride, 2);
  });
}
