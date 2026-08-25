import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const dayMs = 24 * 60 * 60 * 1000;

void main() {
  late int nowMs;
  late PathGraph graph;

  setUp(() async {
    nowMs = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMs));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  void hear(List<int> path) => graph.observePath(
      Uint8List.fromList(path), 2, const ObservationOrigin.anonymous());

  group('age gate', () {
    test('idle unconfirmed hearsay past the gate is forgotten', () {
      hear([0xA2, 0x77, 0x13, 0x12]);
      nowMs += 40 * dayMs;
      final report = graph.sweepStale();
      expect(report.edgesAged, 1);
      expect(report.nodesAged, 2, reason: 'both hashes were edge-only mints');
      expect(graph.snapshot().edges, isEmpty);
      expect(graph.snapshot().nodes, isEmpty);
    });

    test('recent hearsay survives', () {
      hear([0xA2, 0x77, 0x13, 0x12]);
      nowMs += 10 * dayMs;
      expect(graph.sweepStale().totalRemoved, 0);
      expect(graph.snapshot().edges, hasLength(1));
    });

    test('attempt-counted infrastructure never ages out by idleness', () {
      graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true);
      nowMs += 400 * dayMs;
      expect(graph.sweepStale().edgesAged, 0);
      expect(graph.snapshot().edges.keys, contains(('A277', '1312')));
    });

    test('imported priors never age out', () async {
      await graph.importGraph({
        'format': 'meshtrax-graph-v2',
        'directed': true,
        'graph': {'region_hint': 'r'},
        'nodes': [
          {'id': 'AAAA'},
          {'id': 'BBBB'}
        ],
        'links': [
          {'source': 'AAAA', 'target': 'BBBB', 'observations': 5}
        ],
      });
      nowMs += 400 * dayMs;
      expect(graph.sweepStale().totalRemoved, 0);
      expect(graph.snapshot().edges.keys, contains(('AAAA', 'BBBB')));
    });

    test('advert-known node outlives its stale edges', () {
      graph.ingestNode('A277', name: 'Alpha', pubkey: 'a2' * 32);
      hear([0xA2, 0x77, 0x13, 0x12]);
      nowMs += 40 * dayMs;
      final report = graph.sweepStale();
      expect(report.edgesAged, 1);
      expect(report.nodesAged, 1, reason: 'only the anonymous 1312 mint');
      expect(graph.snapshot().nodes.keys, contains('A277'));
    });

    test('stale ingress rows age out', () {
      graph.observePath(Uint8List.fromList([0xA2, 0x77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk));
      nowMs += 40 * dayMs;
      final report = graph.sweepStale();
      expect(report.ingressAged, greaterThan(0));
      expect(graph.ingressCandidates(bobPk), isEmpty);
    });

    test('maxAgeDays null disables the age pass', () {
      hear([0xA2, 0x77, 0x13, 0x12]);
      nowMs += 4000 * dayMs;
      final report =
          graph.sweepStale(policy: const RetentionPolicy(maxAgeDays: null));
      expect(report.totalRemoved, 0);
    });
  });

  group('position tags', () {
    test('age off on their own clock without deleting the row', () {
      graph.observePath(Uint8List.fromList([0xA2, 0x77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk),
          position: const GeoPosition(36.9, -121.7));
      nowMs += 10 * dayMs; // past 7-day tag clock, inside 30-day age gate
      final report = graph.sweepStale();
      expect(report.positionsCleared, 1);
      expect(report.ingressAged, 0);
      // The evidence rows themselves survive (decay has zeroed their
      // routing weight by now, so inspect the session dump, not the
      // candidate list).
      final rows = graph.saveSession()['ingress'] as List;
      expect(rows, isNotEmpty, reason: 'rows survive, only the tag goes');
      for (final row in rows) {
        expect((row as Map).containsKey('lat'), isFalse);
        expect(row.containsKey('lon'), isFalse);
      }
    });

    test('fresh tags are kept', () {
      graph.observePath(Uint8List.fromList([0xA2, 0x77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk),
          position: const GeoPosition(36.9, -121.7));
      nowMs += 3 * dayMs;
      expect(graph.sweepStale().positionsCleared, 0);
    });
  });

  group('growth caps', () {
    test('evict lowest-traffic hearsay first, protected rows last', () {
      graph.reportSendResult(
          Uint8List.fromList([0xC0, 0x01, 0xC0, 0x02]), true);
      hear([0xA2, 0x77, 0x13, 0x12]); // 1 sighting
      hear([0xB1, 0x11, 0xB2, 0x22]);
      hear([0xB1, 0x11, 0xB2, 0x22]); // 2 sightings
      final report = graph.sweepStale(
          policy: const RetentionPolicy(maxEdges: 2, maxNodes: 1000));
      expect(report.edgesEvicted, 1);
      final edges = graph.snapshot().edges.keys;
      expect(edges, contains(('C001', 'C002')), reason: 'attempt-counted');
      expect(edges, contains(('B111', 'B222')), reason: 'heavier traffic');
      expect(edges, isNot(contains(('A277', '1312'))));
    });

    test('node cap evicts loose observed mints before anything else', () {
      graph.ingestNode('AD00', name: 'Advert');
      hear([0xA2, 0x77, 0x13, 0x12]);
      hear([0xCC, 0xCC]); // single hop: loose observed node, no edge
      final report = graph.sweepStale(
          policy: const RetentionPolicy(maxNodes: 3, maxEdges: 1000));
      expect(report.nodesEvicted, 1);
      final nodes = graph.snapshot().nodes.keys;
      expect(nodes, containsAll(['A277', '1312']), reason: 'edge-referenced');
      expect(nodes, contains('AD00'), reason: 'advert metadata');
      expect(nodes, isNot(contains('CCCC')));
    });
  });

  group('clear learned data', () {
    test('wipes local layers, keeps imported priors', () async {
      await graph.importGraph({
        'format': 'meshtrax-graph-v2',
        'directed': true,
        'graph': {'region_hint': 'r'},
        'nodes': [
          {'id': 'AAAA'},
          {'id': 'BBBB'}
        ],
        'links': [
          {'source': 'AAAA', 'target': 'BBBB', 'observations': 5,
           'measured_snr': 6.0}
        ],
      });
      // Local evidence on the imported edge AND a purely local edge.
      graph.reportSendResult(Uint8List.fromList([0xAA, 0xAA, 0xBB, 0xBB]), true);
      hear([0xA2, 0x77, 0x13, 0x12]);
      graph.observePath(Uint8List.fromList([0xA2, 0x77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk));

      await graph.clearLearnedData();

      final snap = graph.snapshot();
      expect(snap.edges.keys, [('AAAA', 'BBBB')]);
      final kept = snap.edges[('AAAA', 'BBBB')]!;
      expect(kept.importedObservations, 5, reason: 'prior survives');
      expect(kept.n, 0, reason: 'local counters zeroed');
      expect(kept.measuredSnr, isNull, reason: 'locally measured SNR wiped');
      expect(kept.importedSnr, 6.0);
      expect(snap.nodes.keys, isNot(contains('A277')));
      expect(graph.egressCandidates(), isEmpty);
      expect(graph.ingressCandidates(bobPk), isEmpty);
      expect(graph.counters.observationsApplied, 0);
    });
  });

  group('persistence', () {
    test('a swept row stays gone after reopen', () async {
      final dir = Directory.systemTemp.createTempSync('path_graph_ret');
      final file = File('${dir.path}/ret.db');

      final g1 = PathGraph(NativeDatabase(file),
          now: () => DateTime.fromMillisecondsSinceEpoch(nowMs));
      await g1.init();
      g1.setRadioIdentity(selfPk, 2);
      g1.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous());
      await g1.flush();

      nowMs += 40 * dayMs;
      expect(g1.sweepStale().edgesAged, 1);
      await g1.dispose(); // flushes the deletes

      final g2 = PathGraph(NativeDatabase(file),
          now: () => DateTime.fromMillisecondsSinceEpoch(nowMs));
      await g2.init();
      expect(g2.snapshot().edges, isEmpty);
      expect(g2.snapshot().nodes, isEmpty);
      await g2.dispose();
      dir.deleteSync(recursive: true);
    });
  });
}
