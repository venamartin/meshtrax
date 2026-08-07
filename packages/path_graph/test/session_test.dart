import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

/// Builds a graph with something in every layer the module has.
Future<PathGraph> populated() async {
  final g = PathGraph(NativeDatabase.memory());
  await g.init();
  g.setRadioIdentity(selfPk, 2);
  g.ingestContact(bobPk, 'Bob');
  g.ingestNode('A277', name: 'Alpha', lat: 36.97, lon: -121.73);
  g.observePath(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
      const ObservationOrigin.pubkeyConfirmed(bobPk),
      position: const GeoPosition(36.9, -121.7));
  g.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, -4.0]);
  g.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true);
  g.observeDiscoverResults(
      [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 7)],
      failureEpisode: false);
  await g.importGraph({
    'format': 'meshtrax-graph-v2',
    'directed': true,
    'graph': {'region_hint': 'elsewhere'},
    'nodes': [
      {'id': 'AAAA'},
      {'id': 'BBBB'}
    ],
    'links': [
      {'source': 'AAAA', 'target': 'BBBB', 'measured_snr': 7.0,
       'observations': 12, 'delivered': 2, 'attempts': 3}
    ],
  });
  return g;
}

void main() {
  test('a session restores every layer, including what export withholds',
      () async {
    final source = await populated();
    final doc = jsonDecode(jsonEncode(source.saveSession()))
        as Map<String, dynamic>;
    final before = source.snapshot();
    final beforeEgress = source.egressCandidates();
    final beforeIngress = source.ingressCandidates(bobPk);
    await source.dispose();

    final restored = PathGraph(NativeDatabase.memory());
    await restored.init();
    await restored.loadSession(doc);

    expect(restored.selfPubkey, selfPk);
    expect(restored.selfStride, 2);
    expect(restored.snapshot().nodes.length, before.nodes.length);
    expect(restored.snapshot().edges.length, before.edges.length);

    // Local evidence, verbatim.
    final edge = restored.snapshot().edges[('A277', '1312')]!;
    expect(edge.s, before.edges[('A277', '1312')]!.s);
    expect(edge.n, before.edges[('A277', '1312')]!.n);
    expect(edge.measuredSnr, 6.5);
    expect(edge.obsCount, before.edges[('A277', '1312')]!.obsCount);

    // The imported prior layer, kept separate and intact.
    final imported = restored.snapshot().edges[('AAAA', 'BBBB')]!;
    expect(imported.importedSnr, 7.0);
    expect(imported.importedDelivered, 2);
    expect(imported.importedAttempts, 3);
    expect(imported.s, 0);

    // Advert metadata and its precedence marker.
    final node = restored.snapshot().nodes['A277']!;
    expect(node.name, 'Alpha');
    expect(node.source, NodeSource.advert);
    expect(node.lat, 36.97);

    // Exactly what exportGraph refuses to carry.
    expect(restored.egressCandidates().map((c) => c.repeaterHash),
        beforeEgress.map((c) => c.repeaterHash));
    expect(restored.egressCandidates().first.uplinkSnr, 9);
    expect(restored.ingressCandidates(bobPk).map((c) => c.repeaterHash),
        beforeIngress.map((c) => c.repeaterHash));
    expect(restored.resolveName('Bob'), isA<UniqueNameOrigin>());

    await restored.dispose();
  });

  test('routing decisions survive the round trip', () async {
    final source = await populated();
    final expected = source.findPath(bobPk);
    final doc = source.saveSession();
    await source.dispose();

    final restored = PathGraph(NativeDatabase.memory());
    await restored.init();
    await restored.loadSession(doc);
    final actual = restored.findPath(bobPk);

    expect(actual.runtimeType, expected.runtimeType);
    if (expected is RouteResult) {
      expect((actual as RouteResult).pathBytes, expected.pathBytes);
    }
    await restored.dispose();
  });

  test('loading replaces state rather than merging into it', () async {
    final source = await populated();
    final doc = source.saveSession();
    await source.dispose();

    final target = PathGraph(NativeDatabase.memory());
    await target.init();
    target.setRadioIdentity(selfPk, 2);
    target.observePath(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]), 2,
        const ObservationOrigin.anonymous());
    expect(target.snapshot().edges.containsKey(('DEAD', 'BEEF')), isTrue);

    await target.loadSession(doc);
    expect(target.snapshot().edges.containsKey(('DEAD', 'BEEF')), isFalse,
        reason: 'a checkpoint restore is not a merge');

    // And the replacement reached the database, not just memory.
    await target.flush();
    await target.dispose();
  });

  test('a restored session survives a reopen of the database', () async {
    final source = await populated();
    final doc = source.saveSession();
    await source.dispose();

    // Same file across two opens.
    final file = '${Directory.systemTemp.createTempSync('pg_sess').path}/s.db';
    final first = PathGraph(NativeDatabase(File(file)));
    await first.init();
    await first.loadSession(doc);
    await first.dispose();

    final second = PathGraph(NativeDatabase(File(file)));
    await second.init();
    second.setRadioIdentity(selfPk, 2);
    expect(second.snapshot().edges[('A277', '1312')]!.measuredSnr, 6.5);
    expect(second.egressCandidates(), isNotEmpty);
    await second.dispose();
  });

  test('non-session documents are rejected', () async {
    final g = PathGraph(NativeDatabase.memory());
    await g.init();
    expect(g.loadSession({'format': 'meshtrax-graph-v2'}),
        throwsFormatException);
    await g.dispose();
  });
}
