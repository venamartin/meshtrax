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

  test('empty discover result is no information', () {
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 8)],
        failureEpisode: false);
    final before = graph.egressCandidates().single.weight;
    graph.observeDiscoverResults(const [], failureEpisode: true);
    expect(graph.egressCandidates().single.weight, before);
  });

  test('egress decays in minutes, contact ingress in hours', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final egress0 = graph.egressCandidates().single.weight;
    final ingress0 = graph.ingressCandidates(bobPk).single.weight;

    nowMillis += 60 * 60 * 1000; // one hour
    expect(graph.egressCandidates(), isEmpty,
        reason: 'minutes-scale egress decayed to noise');
    expect(graph.ingressCandidates(bobPk).single.weight,
        closeTo(ingress0 * 0.99, ingress0 * 0.02),
        reason: 'hours-scale ingress barely moved');
    expect(egress0, greaterThan(0));
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
