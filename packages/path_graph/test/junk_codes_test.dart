import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Field, 2026-10-23: some transmitter puts random bytes in flood paths and
// real repeaters relay them, adding their own codes after the junk. Three
// codes in four in the owner's graph were one-offs, heard in one burst
// (copies within seconds) and never again, many starting 00 or FF, which
// no real key can. A link to a code the graph never had is filed only once
// the same link is heard again ten minutes or more later.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const second = 1000;
const minute = 60 * second;

void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;

  setUp(() async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  void hear(List<int> bytes) => graph.observePath(
      path(bytes), 2, const ObservationOrigin.anonymous());

  test('a path of codes nobody knew files nothing', () {
    hear([0x00, 0x41, 0xB1, 0x07, 0xA2, 0x77]);
    final snap = graph.snapshot();
    expect(snap.edges, isEmpty);
    expect(snap.nodes, isEmpty);
    expect(graph.counters.linksHeld, 2);
    expect(graph.egressCandidates(), isEmpty,
        reason: 'a code heard once is not a doorstep, however loud');
  });

  test('the same link heard again later is filed with both sightings', () {
    final first = nowMillis;
    hear([0xA2, 0x77, 0x13, 0x12]);
    nowMillis += 10 * minute;
    hear([0xA2, 0x77, 0x13, 0x12]);
    final link = graph.snapshot().edges[('A277', '1312')]!;
    expect(link.firstObserved, first);
    expect(link.obsCount, 2);
    expect(graph.egressCandidates().map((c) => c.repeaterHash), ['1312']);
  });

  test('another copy of the same burst stays held', () {
    hear([0xA2, 0x77, 0x13, 0x12]);
    nowMillis += 21 * second;
    hear([0xA2, 0x77, 0x13, 0x12]);
    expect(graph.snapshot().edges, isEmpty);
  });

  test('links between codes the graph knows file at once', () {
    graph.ingestNode('A277', name: 'INTERLAKEN');
    graph.ingestNode('1312', name: 'Hub');
    hear([0x5D, 0x3F, 0xA2, 0x77, 0x13, 0x12]);
    final edges = graph.snapshot().edges;
    expect(edges.keys, [('A277', '1312')],
        reason: 'the junk code before them waits');
    expect(graph.egressCandidates().map((c) => c.repeaterHash), ['1312']);
  });

  test('my own packets vouch for their path', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(selfPk));
    expect(graph.snapshot().edges.keys, [('A277', '1312')]);
  });

  test('a one-hop path from a code nobody knew adds nothing', () {
    hear([0xD6, 0xED]);
    expect(graph.snapshot().nodes, isEmpty);
    expect(graph.egressCandidates(), isEmpty);
  });

  test('0 files every link at once', () {
    graph.updateConfig(graph.config.copyWith(newCodeConfirmMinutes: 0));
    hear([0xA2, 0x77, 0x13, 0x12]);
    expect(graph.snapshot().edges.keys, [('A277', '1312')]);
    expect(graph.counters.linksHeld, 0);
  });
}
