import 'dart:io';
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
    expect(graph.counters.droppedNarrow, 1);
    expect(graph.counters.observationsApplied, 0);
  });

  test('observePath accepts 2-byte stride', () {
    graph.observePath(
      Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]),
      2,
      const ObservationOrigin.anonymous(),
    );
    expect(graph.counters.observationsApplied, 1);
    expect(graph.counters.droppedNarrow, 0);
  });

  test('radio identity is stored', () {
    graph.setRadioIdentity('ab' * 32, 2);
    expect(graph.selfPubkey, 'ab' * 32);
    expect(graph.selfStride, 2);
  });

  group('hashWidthBytes: 3', () {
    test('the whole pipeline speaks 6-hex identities', () async {
      final g = PathGraph(NativeDatabase.memory(), hashWidthBytes: 3);
      await g.init();
      g.setRadioIdentity('ab' * 32, 3);

      // A stride-2 path cannot be widened — dropped, counted.
      g.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous());
      expect(g.counters.droppedNarrow, 1);

      // Stride-3 is native; stride-4 truncates into 3-byte buckets.
      g.observePath(
          Uint8List.fromList([0xA2, 0x77, 0x82, 0x13, 0x12, 0x99]),
          3,
          ObservationOrigin.pubkeyConfirmed('b0' * 32));
      g.observePath(
          Uint8List.fromList([0xA2, 0x77, 0x82, 0x0B, 0x13, 0x12, 0x99, 0x0C]),
          4,
          const ObservationOrigin.anonymous());
      final snap = g.snapshot();
      expect(snap.nodes.keys, unorderedEquals(['A27782', '131299']));
      expect(snap.edges.keys, [('A27782', '131299')]);
      expect(g.ingressCandidates('b0' * 32).single.repeaterHash, 'A27782');

      // Export stamps the width; the exported ids are 6-hex.
      final doc = g.exportGraph();
      expect((doc['graph'] as Map)['hash_width'], 3);
      expect(((doc['nodes'] as List).first as Map)['id'], hasLength(6));
      await g.dispose();
    });

    test('width-2 documents and databases are refused at width 3', () async {
      final g2 = PathGraph(NativeDatabase.memory());
      await g2.init();
      g2.ingestNode('A277', name: 'Alpha');
      final export = g2.exportGraph();
      final session = g2.saveSession();

      final g3 = PathGraph(NativeDatabase.memory(), hashWidthBytes: 3);
      await g3.init();
      expect(g3.importGraph(export), throwsFormatException);
      expect(g3.loadSession(session), throwsFormatException);
      await g3.dispose();

      // And the database itself is stamped: reopening g2's executor at
      // width 3 must refuse rather than mangle.
      await g2.flush();
      final file = File(
          '${Directory.systemTemp.createTempSync('pg_width').path}/w.db');
      final w2 = PathGraph(NativeDatabase(file));
      await w2.init();
      w2.ingestNode('A277', name: 'Alpha');
      await w2.dispose();
      final w3 = PathGraph(NativeDatabase(file), hashWidthBytes: 3);
      await expectLater(w3.init(), throwsStateError);
      await g2.dispose();
    });
  });

  test('a once-heard doorstep never shows near-certain delivery', () {
    // Live find (AA77, 2026-08-14): hearing a repeater's transmission
    // once makes it an inferred egress candidate — fine — but the
    // 1-hop route to it displayed est 100% because the estimate only
    // multiplied between-hop edges and a direct route has none. The
    // doorstep-confidence term must be in the estimate.
    graph.setRadioIdentity('ab' * 32, 2);
    graph.observePath(Uint8List.fromList([0xAA, 0x77]), 2,
        const ObservationOrigin.anonymous());
    final result = graph.findPathToRepeater('AA77');
    expect(result, isA<RouteResult>());
    final est = (result as RouteResult).estDelivery;
    expect(est, lessThan(0.5),
        reason: 'one overheard transmission is not near-certainty');

    // Proven, SNR-measured evidence raises it — the estimate tracks
    // the evidence, not the hop count.
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'AA77', uplinkSnr: 8, rxSnr: 8)],
        failureEpisode: false);
    final proven = graph.findPathToRepeater('AA77') as RouteResult;
    expect(proven.estDelivery, greaterThan(est));
    expect(proven.estDelivery, greaterThan(0.8),
        reason: 'measured 8 dB uplink is near-full quality');
  });

  test('wide hops truncate into 2-byte buckets — never a second identity',
      () {
    // Found live (2026-08-14): a stride-3 path minted 'A27782' beside
    // 'A277' — the same repeater (pubkey a27782…) counted twice, and a
    // 6-hex node id would violate the v2 export format besides.
    graph.setRadioIdentity('ab' * 32, 2);
    graph.observePath(
      Uint8List.fromList([0xA2, 0x77, 0x82, 0x13, 0x12, 0x99]),
      3,
      ObservationOrigin.pubkeyConfirmed('b0' * 32),
    );
    final snap = graph.snapshot();
    expect(snap.nodes.keys, unorderedEquals(['A277', '1312']));
    expect(snap.edges.keys, [('A277', '1312')]);
    expect(graph.egressCandidates().map((c) => c.repeaterHash),
        everyElement(hasLength(4)));
    expect(graph.ingressCandidates('b0' * 32).single.repeaterHash, 'A277');
  });
}
