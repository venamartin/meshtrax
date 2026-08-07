import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

const pkA = 'a277aa0000000000000000000000000000000000000000000000000000000000';
const pkB = '1312bb0000000000000000000000000000000000000000000000000000000000';
const pkFar = '5cbbcc000000000000000000000000000000000000000000000000000000000';

Map<String, dynamic> doc({List<Map<String, dynamic>>? nodes,
    List<Map<String, dynamic>>? links}) {
  return {
    'format': 'meshtrax-graph-v1',
    'directed': true,
    'multigraph': false,
    'graph': {'generated_at': 'T', 'region': 'testland', 'hash_width': 2},
    'nodes': nodes ??
        [
          {'id': pkA, 'name': 'Alpha', 'role': 'repeater',
           'lat': 36.9, 'lon': -121.7},
          {'id': pkB, 'name': 'Bravo', 'role': 'repeater',
           'lat': 36.95, 'lon': -121.75},
        ],
    'links': links ??
        [
          {'source': pkA, 'target': pkB, 'score': 0.9, 'avg_snr': 7.5,
           'bidirectional': true, 'weight': 100},
        ],
  };
}

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  test('import seeds nodes and both directions of a bidirectional link',
      () async {
    await graph.importGraph(doc());
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Alpha');
    expect(snap.nodes['A277']!.pubkey, pkA);
    expect(snap.edges[('A277', '1312')]!.importedScore, 0.9);
    expect(snap.edges[('1312', 'A277')]!.importedScore, 0.9);
  });

  test('undirected document seeds both directions with a SYMMETRIC prior',
      () async {
    // Corescope's real shape: one entry per pair, one avg_snr, no
    // reverse entry anywhere in the file.
    final doc = {
      'format': 'meshtrax-graph-v1',
      'directed': false,
      'graph': {'region': 'testland', 'snr_directionality': 'symmetric'},
      'nodes': [
        {'id': pkA, 'name': 'Alpha'},
        {'id': pkB, 'name': 'Bravo'},
      ],
      'links': [
        {'source': pkA, 'target': pkB, 'score': 0.8, 'avg_snr': 6.0},
      ],
    };
    await graph.importGraph(doc);
    final snap = graph.snapshot();
    final fwd = snap.edges[('A277', '1312')]!;
    final rev = snap.edges[('1312', 'A277')]!;
    expect(fwd.avgSnr, 6.0);
    expect(rev.avgSnr, 6.0, reason: 'same number both ways — one estimate');
    // And it is only a PRIOR: a locally measured value must win.
    fwd.measuredSnr = -12;
    expect(graph.estimator.priorQuality(fwd),
        lessThan(graph.estimator.priorQuality(rev)),
        reason: 'measured SNR outranks the imported symmetric estimate');
  });

  test('one-way link seeds source->target only', () async {
    await graph.importGraph(doc(links: [
      {'source': pkA, 'target': pkB, 'score': 0.8, 'bidirectional': false},
    ]));
    final snap = graph.snapshot();
    expect(snap.edges.containsKey(('A277', '1312')), isTrue);
    expect(snap.edges.containsKey(('1312', 'A277')), isFalse);
  });

  test('day-1 bootstrap: import alone yields a route', () async {
    await graph.importGraph(doc());
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77]), true);
    graph.observePath(Uint8List.fromList([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
  });

  test('re-import replaces the prior, never touches local evidence',
      () async {
    await graph.importGraph(doc());
    // Local evidence accrues.
    graph.reportSendResult(
        Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true);
    final before = graph.snapshot().edges[('A277', '1312')]!;
    expect(before.s, 1);

    // New snapshot with a worse score: prior replaced, s/n intact.
    await graph.importGraph(doc(links: [
      {'source': pkA, 'target': pkB, 'score': 0.3, 'bidirectional': true},
    ]));
    final after = graph.snapshot().edges[('A277', '1312')]!;
    expect(after.importedScore, 0.3);
    expect(after.s, 1);
    expect(after.n, 1);
  });

  test('geo radius filters far nodes, keeps position-less ones', () async {
    await graph.importGraph(doc(nodes: [
      {'id': pkA, 'name': 'Near', 'lat': 36.9, 'lon': -121.7},
      {'id': pkB, 'name': 'NoPos'},
      {'id': pkFar.padRight(64, '0'), 'name': 'Far', 'lat': 34.0,
       'lon': -118.0},
    ]), homePosition: const GeoPosition(36.9, -121.7), radiusKm: 100);
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Near');
    expect(snap.nodes['1312']!.name, 'NoPos');
    expect(snap.nodes.containsKey('5CBB'), isFalse);
  });

  test('unknown format rejected', () {
    expect(graph.importGraph({'format': 'meshtrax-graph-v2'}),
        throwsFormatException);
  });

  test('advert metadata outranks import on the same node', () async {
    await graph.importGraph(doc());
    graph.ingestNode('A277', name: 'AlphaRenamed');
    expect(graph.snapshot().nodes['A277']!.name, 'AlphaRenamed');
    // A later import does not clobber advert-sourced name.
    await graph.importGraph(doc());
    expect(graph.snapshot().nodes['A277']!.name, 'AlphaRenamed');
  });
}
