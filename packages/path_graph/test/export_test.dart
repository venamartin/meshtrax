import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

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

  List<Map<String, dynamic>> linksOf(Map<String, dynamic> doc) =>
      (doc['links'] as List).cast<Map<String, dynamic>>();

  test('exports directed links with their own measurements', () async {
    // A -> B seen in traffic and traced; B -> A only traced back.
    graph.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, -4.0]);

    final doc = graph.exportGraph(regionHint: 'bayarea');
    expect(doc['format'], 'meshtrax-graph-v2');
    expect(doc['directed'], isTrue);
    expect((doc['graph'] as Map)['collector'], 'meshtrax');
    expect((doc['graph'] as Map)['region_hint'], 'bayarea');

    final fwd = linksOf(doc)
        .firstWhere((l) => l['source'] == 'A277' && l['target'] == '1312');
    final rev = linksOf(doc)
        .firstWhere((l) => l['source'] == '1312' && l['target'] == 'A277');
    expect(fwd['measured_snr'], 6.5);
    expect(rev['measured_snr'], -4.0);
    expect(fwd['trace_confirmed'], isTrue);
    expect(fwd['observations'], 1, reason: 'one passive sighting of A->B');
    expect(rev['observations'], 0, reason: 'the reverse was never overheard');
  });

  test('delivery attempts export as delivered/attempts', () async {
    final path = Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]);
    graph.reportSendResult(path, true);
    graph.reportSendResult(path, false);

    final link = linksOf(graph.exportGraph()).single;
    expect(link['delivered'], 1);
    expect(link['attempts'], 2);
    expect(link['trace_confirmed'], isFalse);
    expect(link['last_observed'], isA<String>());
  });

  test('round-trips through importGraph', () async {
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, -4.0]);
    graph.ingestNode('A277', name: 'Alpha', lat: 36.9, lon: -121.7);
    final doc = graph.exportGraph();

    final other = PathGraph(NativeDatabase.memory());
    await other.init();
    await other.importGraph(doc);
    final snap = other.snapshot();
    expect(snap.nodes['A277']!.name, 'Alpha');
    expect(snap.edges[('A277', '1312')]!.importedSnr, 6.5);
    expect(snap.edges[('1312', 'A277')]!.importedSnr, -4.0);
    await other.dispose();
  });

  test('carries repeater topology and nothing else', () async {
    // Everything private the module knows: a named contact, their
    // ingress list, my own doorstep, and a position tag.
    graph.ingestContact(bobPk, 'Bob');
    graph.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk),
        position: const GeoPosition(36.9712, -121.7334));
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: '1312', uplinkSnr: 9)],
        failureEpisode: false);
    expect(graph.ingressCandidates(bobPk), isNotEmpty);
    expect(graph.egressCandidates(), isNotEmpty);

    final json = jsonEncode(graph.exportGraph());
    expect(json.contains(bobPk), isFalse, reason: 'no contact pubkeys');
    expect(json.toLowerCase().contains('bob'), isFalse, reason: 'no names');
    expect(json.contains(selfPk), isFalse, reason: 'no self identity');
    expect(json.contains('36.97'), isFalse, reason: 'no position tags');
    expect(json.contains('ingress'), isFalse);

    // What it DOES carry: the repeater-to-repeater hop.
    expect(linksOf(graph.exportGraph()).single,
        containsPair('source', 'A277'));
  });

  test('imported priors are not re-exported', () async {
    await graph.importGraph({
      'format': 'meshtrax-graph-v2',
      'directed': true,
      'graph': {'region_hint': 'elsewhere'},
      'nodes': [
        {'id': 'AAAA'},
        {'id': 'BBBB'}
      ],
      'links': [
        {'source': 'AAAA', 'target': 'BBBB', 'measured_snr': 7.0,
         'observations': 99}
      ],
    });
    graph.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());

    final links = linksOf(graph.exportGraph());
    expect(links.single['source'], 'A277',
        reason: "someone else's measurement stays theirs");
    expect((graph.exportGraph()['nodes'] as List).length, 2);
  });
}
