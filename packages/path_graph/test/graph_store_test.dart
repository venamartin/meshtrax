import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
  });

  tearDown(() => graph.dispose());

  test('observed path [A,B,C] creates directed edges A->B, B->C only', () {
    graph.observePath(
      path([0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB]),
      2,
      const ObservationOrigin.anonymous(),
    );
    final snap = graph.snapshot();
    expect(snap.nodes.keys, containsAll(['A277', '1312', '5CBB']));
    expect(snap.edges.containsKey(('A277', '1312')), isTrue);
    expect(snap.edges.containsKey(('1312', '5CBB')), isTrue);
    expect(snap.edges.containsKey(('1312', 'A277')), isFalse,
        reason: 'reverse direction is never inferred');
    expect(snap.edges.length, 2);
  });

  test('variants of one message dedup shared edges, count new branches', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), messageId: 'm1');
    graph.observePath(path([0xA2, 0x77, 0x24, 0x9F]), 2,
        const ObservationOrigin.anonymous(), messageId: 'm1');
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), messageId: 'm1');

    final snap = graph.snapshot();
    expect(snap.edges[('A277', '1312')]!.obsCount, 1,
        reason: 'same edge in same message counted once');
    expect(snap.edges[('A277', '249F')]!.obsCount, 1);

    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), messageId: 'm2');
    expect(graph.snapshot().edges[('A277', '1312')]!.obsCount, 2,
        reason: 'a new message counts again');
  });

  test('ingestNode advert metadata outranks and fills', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());
    graph.ingestNode('a277',
        name: 'Prunetucky', pubkey: 'a2' '77' 'aa', lat: 36.9, lon: -121.7);
    final node = graph.snapshot().nodes['A277']!;
    expect(node.name, 'Prunetucky');
    expect(node.source, NodeSource.advert);
    expect(node.lat, closeTo(36.9, 1e-9));
  });

  test('state survives flush and reload', () async {
    final executor = NativeDatabase.memory();
    final first = PathGraph(executor);
    await first.init();
    first.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());
    first.ingestNode('A277', name: 'Prunetucky');
    await first.flush();

    // Same executor, fresh instance = fresh in-memory state from DB.
    final second = PathGraph(executor);
    await second.init();
    final snap = second.snapshot();
    expect(snap.edges[('A277', '1312')]!.obsCount, 1);
    expect(snap.nodes['A277']!.name, 'Prunetucky');
    await second.dispose();
  });
}
