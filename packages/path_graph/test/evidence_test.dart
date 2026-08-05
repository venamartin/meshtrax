import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

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

  test('confirmed traffic writes contact ingress from path[0]', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final ingress = graph.ingressCandidates(bobPk);
    expect(ingress.single.repeaterHash, 'A277');
    expect(ingress.single.tier, EvidenceTier.proven);
  });

  test('uniqueName attribution weighs less than pubkey-confirmed', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x24, 0x9F, 0x13, 0x12]), 2,
        const ObservationOrigin.uniqueName(bobPk));
    final ingress = graph.ingressCandidates(bobPk);
    expect(ingress.first.repeaterHash, 'A277');
    expect(ingress.first.weight, greaterThan(ingress.last.weight));
  });

  test('anonymous traffic never writes ingress, still counts edges', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());
    expect(graph.ingressCandidates(bobPk), isEmpty);
    expect(graph.snapshot().edges.length, 1);
  });

  test('self last-hop tally: final position votes, hub gets demoted', () {
    // 1312 is the doorstep: mostly final. A277 is the hub: penultimate.
    for (var i = 0; i < 5; i++) {
      graph.observePath(path([0x5C, 0xBB, 0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous());
    }
    graph.observePath(path([0x5C, 0xBB, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous()); // A277 final once
    final egress = graph.egressCandidates();
    expect(egress.first.repeaterHash, '1312');
    final hub = egress.firstWhere((c) => c.repeaterHash == 'A277');
    expect(hub.weight, lessThan(egress.first.weight),
        reason: 'penultimate-heavy hub demoted');
  });

  test('empty path from confirmed sender = fresh direct → findPath direct',
      () {
    graph.observePath(
        Uint8List(0), 2, const ObservationOrigin.pubkeyConfirmed(bobPk));
    expect(graph.findPath(bobPk), isA<DirectResult>());

    nowMillis += 31 * 60 * 1000; // beyond directFreshMinutes
    expect(graph.findPath(bobPk), isA<FloodResult>());
  });

  test('delivered send upgrades first hop to proven egress', () {
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true);
    final egress = graph.egressCandidates();
    expect(egress.single.repeaterHash, 'A277');
    expect(egress.single.tier, EvidenceTier.proven);
  });

  test('discover: proactive refresh never slashes; failure episode does',
      () {
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 8)],
        failureEpisode: false);
    final before = graph.egressCandidates().single.weight;

    // Proactive again: adds, no slash.
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: '1312', uplinkSnr: 8)],
        failureEpisode: false);
    expect(graph.egressCandidates().length, 2);

    // Failure episode: pre-existing entries slashed (floored), fresh
    // responder seeded on top.
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: '249F', uplinkSnr: 8)],
        failureEpisode: true);
    final a277 = graph
        .egressCandidates()
        .firstWhere((c) => c.repeaterHash == 'A277');
    expect(a277.weight, lessThan(before));
    expect(graph.egressCandidates().first.repeaterHash, '249F');
  });

  test('discover stores measured dB both ways and it outranks a tally', () {
    // A weak-but-familiar doorstep vs a freshly measured strong one.
    for (var i = 0; i < 6; i++) {
      graph.observePath(path([0x24, 0x9F, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous());
    }
    graph.observeDiscoverResults([
      const DiscoverResponse(
          repeaterHash: '1312', uplinkSnr: -15, rxSnr: -14), // weak link
      const DiscoverResponse(
          repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 8), // strong link
    ], failureEpisode: false);

    final byHash = {
      for (final c in graph.egressCandidates()) c.repeaterHash: c
    };
    expect(byHash['A277']!.uplinkSnr, 9);
    expect(byHash['A277']!.downlinkSnr, 8);
    expect(byHash['1312']!.uplinkSnr, -15);

    // The strong measured link must win the first hop even though 1312
    // has more accumulated tally weight.
    graph.observePath(path([0xA2, 0x77, 0x5C, 0xBB]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0x5C, 0xBB, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0x13, 0x12, 0x5C, 0xBB]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0x5C, 0xBB, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    final route = graph.findPathToRepeater('5CBB');
    expect(route, isA<RouteResult>());
    expect((route as RouteResult).pathBytes.sublist(0, 2), [0xA2, 0x77],
        reason: 'measured strong uplink beats a bigger tally');
  });

  test('empty discover result is no information', () {
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 8)],
        failureEpisode: false);
    final before = graph.egressCandidates().single.weight;
    graph.observeDiscoverResults(const [], failureEpisode: true);
    expect(graph.egressCandidates().single.weight, before);
  });

  test('egress ages faster than ingress, but survives a coffee break', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final egress0 = graph.egressCandidates().single.weight;
    final ingress0 = graph.ingressCandidates(bobPk).single.weight;

    nowMillis += 30 * 60 * 1000; // half an hour away from the bench
    expect(graph.egressCandidates(), isNotEmpty,
        reason: 'evidence must not evaporate between test runs');
    final egressFade =
        graph.egressCandidates().single.weight / egress0;
    final ingressFade =
        graph.ingressCandidates(bobPk).single.weight / ingress0;
    expect(egressFade, lessThan(ingressFade),
        reason: 'my doorstep ages faster than theirs');

    nowMillis += 6 * 60 * 60 * 1000; // long idle
    expect(graph.egressCandidates(), isEmpty,
        reason: 'an inferred last-hop guess does expire eventually');
  });

  test('proven egress outlives an inferred guess', () {
    graph.observePath(path([0x24, 0x9F, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous()); // inferred 1312
    graph.reportSendResult(path([0xA2, 0x77, 0x5C, 0xBB]), true); // proven A277

    nowMillis += 4 * 60 * 60 * 1000;
    final survivors =
        graph.egressCandidates().map((c) => c.repeaterHash).toList();
    expect(survivors, contains('A277'));
    expect(survivors, isNot(contains('1312')));
  });

  test('resolveName: unique → uniqueName, duplicate → anonymous', () {
    graph.ingestContact(bobPk, 'Bob');
    expect(graph.resolveName('Bob'), isA<UniqueNameOrigin>());
    graph.ingestContact('cc' 'cc' 'cc', 'Bob');
    expect(graph.resolveName('Bob'), isA<AnonymousOrigin>());
    expect(graph.resolveName('Nobody'), isA<AnonymousOrigin>());
  });

  test('evidence survives flush and reload', () async {
    final executor = NativeDatabase.memory();
    final first = PathGraph(executor,
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await first.init();
    first.setRadioIdentity(selfPk, 2);
    first.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    first.ingestContact(bobPk, 'Bob');
    await first.flush();

    final second = PathGraph(executor,
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await second.init();
    second.setRadioIdentity(selfPk, 2);
    expect(second.ingressCandidates(bobPk).single.repeaterHash, 'A277');
    expect(second.resolveName('Bob'), isA<UniqueNameOrigin>());
    await second.dispose();
  });
}
