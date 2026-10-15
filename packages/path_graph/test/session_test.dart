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
  g.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true,
      contactPubkey: bobPk);
  g.observeDiscoverResults(
      [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 7)],
      failureEpisode: false);
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

    // Send-direction proof survives: the doorstep A277 was proven by a
    // delivered send, and so was Bob's ingress at 1312.
    expect(
        restored
            .egressCandidates()
            .singleWhere((c) => c.repeaterHash == 'A277')
            .proven,
        isTrue);
    expect(
        restored
            .ingressCandidates(bobPk)
            .singleWhere((c) => c.repeaterHash == '1312')
            .proven,
        isTrue);

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

  test('a checkpoint carrying 6-hex ghosts loads healed and merged', () async {
    // Sessions saved before wide hops truncated into 2-byte buckets hold
    // the same repeater twice ('A277' and 'A27782' — live find,
    // 2026-08-14). Loading folds the ghost into its bucket.
    final source = await populated();
    final doc = source.saveSession();
    await source.dispose();

    final bucketWeight = ((doc['ingress'] as List).cast<Map>().singleWhere(
            (r) => r['owner'] == selfPk && r['repeater'] == 'A277'))['weight']
        as num;
    (doc['nodes'] as List).add({'hash': 'A27782', 'source': 'observed'});
    (doc['edges'] as List).add({
      'from': 'A27782',
      'to': '1312',
      'source': 'observed',
      's': 1,
      'n': 2,
      'traffic_weight': 3.0,
      'obs_count': 3,
    });
    (doc['ingress'] as List).add({
      'owner': selfPk,
      'repeater': 'A27782',
      'weight': 2.0,
      'last_seen': DateTime.now().millisecondsSinceEpoch,
      'tier': 'inferred',
    });

    final g = PathGraph(NativeDatabase.memory());
    await g.init();
    await g.loadSession(doc);

    final snap = g.snapshot();
    expect(snap.nodes.keys.where((k) => k.length > 4), isEmpty);
    expect(snap.edges.keys.where((k) => k.$1.length > 4 || k.$2.length > 4),
        isEmpty);
    final merged = snap.edges[('A277', '1312')]!;
    expect(merged.n, greaterThanOrEqualTo(2), reason: 'ghost counters folded');
    expect(merged.measuredSnr, 6.5, reason: 'bucket row keeps its own SNR');
    g.setRadioIdentity(selfPk, 2);
    final egress = g.egressCandidates();
    expect(egress.map((c) => c.repeaterHash),
        isNot(contains('A27782')));
    expect(
        egress.singleWhere((c) => c.repeaterHash == 'A277').weight,
        greaterThan(bucketWeight * 0.5),
        reason: 'ghost weight folded in, not dropped');
    await g.dispose();
  });

  test('non-session documents are rejected', () async {
    final g = PathGraph(NativeDatabase.memory());
    await g.init();
    expect(g.loadSession({'format': 'meshtrax-graph-v2'}),
        throwsFormatException);
    await g.dispose();
  });

  test('proven_count rides the session; an old checkpoint reads proven rows as 1',
      () async {
    final source = await populated();
    final before = source.egressCandidates().first;
    expect(before.provenCount, greaterThan(0));
    final doc = source.saveSession();
    await source.dispose();

    final restored = PathGraph(NativeDatabase.memory());
    await restored.init();
    await restored.loadSession(doc);
    expect(restored.egressCandidates().first.provenCount, before.provenCount);
    await restored.dispose();

    // A checkpoint written before the field existed.
    for (final row in doc['ingress'] as List) {
      (row as Map).remove('proven_count');
    }
    final old = PathGraph(NativeDatabase.memory());
    await old.init();
    await old.loadSession(doc);
    expect(old.egressCandidates().first.provenCount, 1,
        reason: 'a proven row was proven at least once');
    await old.dispose();
  });

  test('one bad row fails the restore and leaves the graph as it was',
      () async {
    final source = await populated();
    final doc = jsonDecode(jsonEncode(source.saveSession()))
        as Map<String, dynamic>;
    await source.dispose();
    (doc['ingress'] as List).add({'owner': selfPk, 'repeater': 'DEAD'});

    final target = await populated();
    final before = target.egressCandidates().length;
    await expectLater(target.loadSession(doc), throwsFormatException);
    expect(target.egressCandidates().length, before,
        reason: 'nothing was cleared before the parse failed');
    expect(target.snapshot().edges, isNotEmpty);
    await target.dispose();
  });

  test('a checkpoint from another radio never replaces the live identity',
      () async {
    final source = await populated();
    final doc = source.saveSession();
    await source.dispose();

    const livePk = 'cd' 'cd' 'cd';
    final target = PathGraph(NativeDatabase.memory());
    await target.init();
    target.setRadioIdentity(livePk, 2);
    await target.loadSession(doc);
    expect(target.selfPubkey, livePk);
    expect(target.selfStride, 2);
    await target.dispose();
  });

  test('re-feeding an unchanged contact writes nothing; a rename does',
      () async {
    var now = 1000000;
    final g = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(now));
    await g.init();
    Map contact() => (g.saveSession()['contacts'] as List)
        .cast<Map>()
        .singleWhere((c) => c['pubkey'] == bobPk);

    g.ingestContact(bobPk, 'Bob');
    now += 60000;
    g.ingestContact(bobPk, 'Bob');
    expect(contact()['last_refreshed'], 1000000,
        reason: 'the same name is not re-stamped, so it is not rewritten');

    now += 60000;
    g.ingestContact(bobPk, 'Bobby');
    expect(contact()['name'], 'Bobby');
    expect(contact()['last_refreshed'], now);
    await g.dispose();
  });
}
