import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

/// A meshtrax-graph-v2 document: node ids are 2-byte hash buckets and
/// every link describes exactly one direction.
Map<String, dynamic> doc({
  List<Map<String, dynamic>>? nodes,
  List<Map<String, dynamic>>? links,
}) {
  return {
    'format': 'meshtrax-graph-v2',
    'directed': true,
    'multigraph': false,
    'graph': {
      'generated_at': '2026-08-07T00:00:00Z',
      'collector': 'meshtrax 1.7.13',
      'region_hint': 'testland',
      'hash_width': 2,
    },
    'nodes': nodes ??
        [
          {'id': 'A277', 'name': 'Alpha', 'role': 'repeater',
           'lat': 36.9, 'lon': -121.7},
          {'id': '1312', 'name': 'Bravo', 'role': 'repeater',
           'lat': 36.95, 'lon': -121.75},
        ],
    'links': links ??
        [
          {'source': 'A277', 'target': '1312', 'observations': 47,
           'measured_snr': 6.5, 'trace_confirmed': true},
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

  test('a link seeds its own direction and nothing else', () async {
    await graph.importGraph(doc());
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Alpha');
    expect(snap.edges[('A277', '1312')]!.importedSnr, 6.5);
    expect(snap.edges.containsKey(('1312', 'A277')), isFalse,
        reason: 'B->A is a separate measurement nobody made');
  });

  test('the reverse direction carries its own numbers', () async {
    await graph.importGraph(doc(links: [
      {'source': 'A277', 'target': '1312', 'measured_snr': 6.5,
       'observations': 47},
      {'source': '1312', 'target': 'A277', 'measured_snr': -9.0,
       'observations': 3},
    ]));
    final snap = graph.snapshot();
    expect(snap.edges[('A277', '1312')]!.importedSnr, 6.5);
    expect(snap.edges[('1312', 'A277')]!.importedSnr, -9.0);
    expect(graph.estimator.priorQuality(snap.edges[('A277', '1312')]!),
        greaterThan(
            graph.estimator.priorQuality(snap.edges[('1312', 'A277')]!)),
        reason: 'asymmetry survives the import — that is the point');
  });

  test('one-way import cannot satisfy the bidirectional contract', () async {
    // Everything a route needs EXCEPT evidence that 1312 hears A277 back.
    await graph.importGraph(doc());
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77]), true);
    graph.observePath(Uint8List.fromList([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
    expect(graph.findPath(bobPk), isA<FloodResult>());
  });

  test('day-1 bootstrap: a both-directions import alone yields a route',
      () async {
    await graph.importGraph(doc(links: [
      {'source': 'A277', 'target': '1312', 'measured_snr': 6.5,
       'observations': 47},
      {'source': '1312', 'target': 'A277', 'measured_snr': 5.0,
       'observations': 40},
    ]));
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77]), true);
    graph.observePath(Uint8List.fromList([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
  });

  test('delivery record imports as a prior, not as local attempts', () async {
    await graph.importGraph(doc(links: [
      {'source': 'A277', 'target': '1312', 'delivered': 3, 'attempts': 4,
       'observations': 12, 'last_observed': '2026-08-06T12:00:00Z'},
    ]));
    final e = graph.snapshot().edges[('A277', '1312')]!;
    expect(e.importedDelivered, 3);
    expect(e.importedAttempts, 4);
    expect(e.s, 0, reason: 'local attempt counters stay mine alone');
    expect(e.n, 0);
    expect(e.importedLastObserved,
        DateTime.utc(2026, 8, 6, 12).millisecondsSinceEpoch);
  });

  test('re-import replaces the prior, never touches local evidence',
      () async {
    await graph.importGraph(doc());
    graph.reportSendResult(
        Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true);
    expect(graph.snapshot().edges[('A277', '1312')]!.s, 1);

    await graph.importGraph(doc(links: [
      {'source': 'A277', 'target': '1312', 'measured_snr': -11.0,
       'observations': 2},
    ]));
    final after = graph.snapshot().edges[('A277', '1312')]!;
    expect(after.importedSnr, -11.0);
    expect(after.importedObservations, 2);
    expect(after.s, 1);
    expect(after.n, 1);
  });

  test('geo radius filters far nodes and the links that touch them',
      () async {
    await graph.importGraph(
      doc(nodes: [
        {'id': 'A277', 'name': 'Near', 'lat': 36.9, 'lon': -121.7},
        {'id': '1312', 'name': 'NoPos'},
        {'id': '5CBB', 'name': 'Far', 'lat': 34.0, 'lon': -118.0},
      ], links: [
        {'source': 'A277', 'target': '1312', 'observations': 5},
        {'source': 'A277', 'target': '5CBB', 'observations': 5},
      ]),
      homePosition: const GeoPosition(36.9, -121.7),
      radiusKm: 100,
    );
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Near');
    expect(snap.nodes['1312']!.name, 'NoPos');
    expect(snap.nodes.containsKey('5CBB'), isFalse);
    expect(snap.edges.containsKey(('A277', '1312')), isTrue);
    expect(snap.edges.containsKey(('A277', '5CBB')), isFalse);
  });

  test('v1 and undirected documents are rejected', () {
    expect(graph.importGraph({'format': 'meshtrax-graph-v1'}),
        throwsFormatException);
    expect(
        graph.importGraph({'format': 'meshtrax-graph-v2', 'directed': false}),
        throwsFormatException);
  });

  test('node ids must be 2-byte hashes', () async {
    await graph.importGraph(doc(nodes: [
      {'id': 'a277', 'name': 'lowercase is fine'},
      {'id': 'a277aa00000000000000000000000000000000000000000000000000000000',
       'name': 'a pubkey is not an id'},
    ], links: const []));
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'lowercase is fine');
    expect(snap.nodes.length, 1);
  });

  test('advert metadata outranks import on the same node', () async {
    await graph.importGraph(doc());
    graph.ingestNode('A277', name: 'AlphaRenamed');
    expect(graph.snapshot().nodes['A277']!.name, 'AlphaRenamed');
    await graph.importGraph(doc());
    expect(graph.snapshot().nodes['A277']!.name, 'AlphaRenamed');
  });
}
