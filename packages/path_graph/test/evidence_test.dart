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
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  test('confirmed traffic writes contact ingress from path[0] as a guess',
      () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final ingress = graph.ingressCandidates(bobPk);
    expect(ingress.single.repeaterHash, 'A277');
    expect(ingress.single.tier, EvidenceTier.inferred,
        reason: 'A277 heard Bob; that says nothing about reaching Bob');
    expect(ingress.single.proven, isFalse);
  });

  test('a delivered send proves its last hop reaches the contact', () {
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    final ingress = graph.ingressCandidates(bobPk).single;
    expect(ingress.repeaterHash, '1312');
    expect(ingress.tier, EvidenceTier.proven);
    expect(ingress.proven, isTrue);
    expect(graph.egressCandidates().single.proven, isTrue);
  });

  test('my doorstep must be proven: a heard-only egress floods', () {
    // Heard Bob through A277 and heard 1312 last: Bob's end is good
    // (A277 heard him), mine is a guess (I hear 1312; does it hear me?).
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x13, 0x12, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous());
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noProvenEndpoint);
    expect(graph.findAlternatives(bobPk), isEmpty);

    // One flood exchange proves my end (A277 hears me). A277 also heard
    // Bob, so the shared doorstep is the whole route.
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    final route = graph.findPath(bobPk);
    expect(route, isA<RouteResult>());
    expect((route as RouteResult).pathBytes, [0xA2, 0x77]);
    expect(route.egressProven, isTrue);
    expect(route.ingressProven, isFalse, reason: 'A277 heard Bob, no delivery yet');
    expect(route.hopProbabilities, isEmpty);
  });

  test('a heard-from contact doorstep ends a route once mine is proven',
      () {
    graph.reportSendResult(path([0xA2, 0x77]), true); // A277 hears me
    // Bob's message came 1312 -> A277 -> me: 1312 heard Bob.
    graph.observePath(path([0x13, 0x12, 0xA2, 0x77]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    final bobs = graph.ingressCandidates(bobPk).single;
    expect(bobs.repeaterHash, '1312');
    expect(bobs.heard, isTrue);
    expect(bobs.proven, isFalse);

    final route = graph.findPath(bobPk);
    expect(route, isA<RouteResult>(),
        reason: 'a repeater that hears a handheld reaches it');
    expect((route as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(route.egressProven, isTrue);
    expect(route.ingressProven, isFalse);
  });

  test('a channel sender with a unique name credits their doorstep only',
      () {
    graph.ingestContact(bobPk, 'Bob');
    graph.observeChannelSender('Bob', path([0xA2, 0x77, 0x13, 0x12]), 2);
    final bobs = graph.ingressCandidates(bobPk).single;
    expect(bobs.repeaterHash, 'A277');
    expect(bobs.weight, 1.0, reason: 'name-matched weighs less');
    expect(bobs.heard, isTrue);
    expect(graph.snapshot().edges, isEmpty,
        reason: 'edges came from the raw feed already');
    expect(graph.egressCandidates(), isEmpty,
        reason: 'no second last-hop tally for me');

    graph.observeChannelSender(' bob ', path([0xA2, 0x77]), 2);
    expect(graph.ingressCandidates(bobPk).single.weight, 2.0,
        reason: 'case and whitespace do not matter');

    graph.ingestContact('cc' 'cc' 'cc', 'Bob');
    graph.observeChannelSender('Bob', path([0x5C, 0xBB]), 2);
    expect(graph.ingressCandidates(bobPk).single.repeaterHash, 'A277',
        reason: 'an ambiguous name credits nobody');
    expect(graph.ingressCandidates('cc' 'cc' 'cc'), isEmpty);
  });

  test('a packet under my own key is an echo: first hop hears me, no slash',
      () {
    graph.reportSendResult(path([0xA2, 0x77]), true); // A277 proven, 3.0
    graph.reportSendResult(path([0xA2, 0x77]), true); // 6.0

    // My own advert echoed back with BEEF as first forwarder.
    graph.observePath(path([0xBE, 0xEF, 0xA2, 0x77]), 2,
        ObservationOrigin.pubkeyConfirmed(selfPk));
    graph.observeContactSender(selfPk, path([0xBE, 0xEF, 0xA2, 0x77]), 2,
        confirmed: true);

    final mine = {for (final c in graph.egressCandidates()) c.repeaterHash: c};
    expect(mine['A277']!.weight, closeTo(6.0, 0.01),
        reason: 'my own list is never halved by my own echoes');
    expect(mine['BEEF']!.proven, isTrue, reason: 'BEEF did hear me');
    expect(mine.containsKey(directHash), isFalse);

    // A zero-hop copy under my key is nothing, not "direct".
    graph.observePath(Uint8List(0), 2, ObservationOrigin.pubkeyConfirmed(selfPk));
    graph.observeContactSender(selfPk, Uint8List(0), 2, confirmed: true);
    expect(graph.egressCandidates().any((c) => c.repeaterHash == directHash),
        isFalse);
  });

  test('my own advert in uppercase is still mine; each copy proves once, '
      'and its path is still a heard corridor', () {
    // Audit: adverts reached the graph uppercase, so my own advert missed
    // the self check and was filed as a contact sighting of myself.
    final upper = selfPk.toUpperCase();
    for (var i = 0; i < 2; i++) {
      graph.observePath(path([0xBE, 0xEF, 0xA2, 0x77]), 2,
          ObservationOrigin.pubkeyConfirmed(upper),
          messageId: 'advert-1');
    }
    final mine = {for (final c in graph.egressCandidates()) c.repeaterHash: c};
    expect(mine['BEEF']!.proven, isTrue);
    expect(mine['BEEF']!.provenCount, 1, reason: 'one packet, one proof');
    expect(graph.snapshot().edges.containsKey(('BEEF', 'A277')), isTrue);
  });

  test('a decrypted DM credits the sender\'s doorstep, confirmed', () {
    graph.observeContactSender(bobPk, path([0xA2, 0x77, 0x13, 0x12]), 2,
        confirmed: true);
    final bobs = graph.ingressCandidates(bobPk).single;
    expect(bobs.repeaterHash, 'A277');
    expect(bobs.weight, 3.0, reason: 'the MAC proved the key');
    expect(bobs.heard, isTrue);
    expect(bobs.proven, isFalse, reason: 'heard from, not delivered to');
    expect(graph.snapshot().edges, isEmpty,
        reason: 'edges came from the raw feed already');
    expect(graph.egressCandidates(), isEmpty,
        reason: 'no second last-hop tally for me');

    graph.observeContactSender(bobPk, Uint8List(0), 2, confirmed: true);
    expect(graph.ingressCandidates(bobPk).map((c) => c.repeaterHash),
        contains(directHash));

    final narrow = graph.counters.droppedNarrow;
    graph.observeContactSender(bobPk, path([0xA2, 0x77]), 1, confirmed: true);
    expect(graph.counters.droppedNarrow, narrow + 1);
  });

  test('every sighting slashes the other doorsteps: a move buries the old',
      () {
    for (var i = 0; i < 3; i++) {
      graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk));
    }
    expect(graph.ingressCandidates(bobPk).single.weight, 9.0);

    for (var i = 0; i < 3; i++) {
      graph.observePath(path([0x5C, 0xBB, 0x13, 0x12]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk));
    }
    final ranked = graph.ingressCandidates(bobPk);
    expect(ranked.first.repeaterHash, '5CBB');
    expect(ranked.first.weight, 9.0);
    expect(ranked.last.repeaterHash, 'A277');
    expect(ranked.last.weight, closeTo(1.125, 1e-9), reason: '9 × 0.5³');
  });

  test('a first hop far from the current top doorstep wipes the list', () {
    graph.ingestNode('A277', lat: 36.97, lon: -121.73); // Watsonville
    graph.ingestNode('5CBB', lat: 37.77, lon: -122.42); // San Francisco
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(Uint8List(0), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk)); // heard direct too
    expect(graph.ingressCandidates(bobPk), hasLength(2));

    graph.observePath(path([0x5C, 0xBB, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final after = graph.ingressCandidates(bobPk);
    expect(after.map((c) => c.repeaterHash), ['5CBB'],
        reason: 'one message from 100 km away replaces everything');
    expect(after.single.weight, 3.0);
  });

  test('without positions a far move is only a slash', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x5C, 0xBB, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    final byHash = {
      for (final c in graph.ingressCandidates(bobPk)) c.repeaterHash: c.weight
    };
    expect(byHash, {'5CBB': 3.0, 'A277': 1.5});
  });

  test('an unrefreshed contact doorstep fades in hours, not days', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    nowMillis += 2 * 60 * 60 * 1000;
    expect(graph.ingressCandidates(bobPk), isNotEmpty);
    nowMillis += 4 * 24 * 60 * 60 * 1000;
    expect(graph.ingressCandidates(bobPk), isEmpty);
  });

  test('allowInferredEndpoints restores the guess, flagged', () async {
    final g = PathGraph(NativeDatabase.memory(),
        config: const PathGraphConfig(
            newCodeConfirmMinutes: 0, allowInferredEndpoints: true));
    await g.init();
    g.setRadioIdentity(selfPk, 2);
    g.observePath(path([0xA2, 0x77]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    g.reportSendResult(path([0xA2, 0x77]), true);
    final route = g.findPath(bobPk) as RouteResult;
    expect(route.egressProven, isTrue);
    expect(route.ingressProven, isFalse);
    await g.dispose();
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

  test('direct: hearing them at zero hops is as good as a delivered send',
      () {
    graph.observePath(
        Uint8List(0), 2, const ObservationOrigin.pubkeyConfirmed(bobPk));
    expect(graph.findPath(bobPk), isA<DirectResult>(),
        reason: 'two handhelds: if I hear them, they hear me');

    nowMillis += 31 * 60 * 1000; // beyond directFreshMinutes
    expect(graph.findPath(bobPk), isA<FloodResult>());

    graph.reportSendResult(Uint8List(0), true, contactPubkey: bobPk);
    expect(graph.findPath(bobPk), isA<DirectResult>());
  });

  // Field 2026-10-16: delivered direct at home, then walking away; their
  // DMs came over 2-5 hops while "direct" won for half an hour.
  group('direct ends when they come only through a repeater', () {
    void heardDirect() =>
        graph.reportSendResult(Uint8List(0), true, contactPubkey: bobPk);
    bool relayed({bool confirmed = true}) => graph.observeContactSender(
        bobPk, path([0xA2, 0x77]), 2,
        confirmed: confirmed);

    test('a later DM of theirs over a repeater ends it at once', () {
      heardDirect();
      nowMillis += 5 * 60 * 1000;
      relayed();
      expect(graph.findPath(bobPk), isNot(isA<DirectResult>()));
    });

    test('a relayed copy of the packet that came direct does not', () {
      heardDirect();
      nowMillis += 15 * 1000;
      relayed();
      expect(graph.findPath(bobPk), isA<DirectResult>());
    });

    test('a name match proves nothing, either way', () {
      heardDirect();
      nowMillis += 5 * 60 * 1000;
      relayed(confirmed: false);
      expect(graph.findPath(bobPk), isA<DirectResult>());
    });

    test('hearing them direct again brings it back', () {
      heardDirect();
      nowMillis += 5 * 60 * 1000;
      relayed();
      nowMillis += 60 * 1000;
      graph.observeContactSender(bobPk, Uint8List(0), 2, confirmed: true);
      expect(graph.findPath(bobPk), isA<DirectResult>());
    });
  });

  test('the level I heard the last hop at is kept as its downlink', () {
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), rxSnr: 5.0);
    expect(graph.egressCandidates().single.downlinkSnr, 5.0);
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), rxSnr: 0.0);
    expect(graph.egressCandidates().single.downlinkSnr, closeTo(3.0, 1e-9));
  });

  test('doorstep confidence: a measured weak link ranks below a good tally',
      () {
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: '1000', uplinkSnr: -12)],
        failureEpisode: false);
    for (var i = 0; i < 5; i++) {
      graph.reportSendResult(path([0xA2, 0x77]), true);
    }
    final byHash = {
      for (final c in graph.egressCandidates()) c.repeaterHash: c
    };
    expect(byHash['1000']!.proven, isTrue, reason: 'it answered');
    expect(graph.doorstepConfidence(byHash['1000']!),
        lessThan(graph.doorstepConfidence(byHash['A277']!)));
  });

  // Field 2026-10-17: +11.6 dB measured at home kept the home repeater
  // ranked first 40 km away through two halvings.
  group('a measured level belongs to where it was measured', () {
    Candidate mine(double weight,
            {double? up, double? down, int provenAgoMinutes = 0}) =>
        Candidate('A277', weight, EvidenceTier.proven,
            uplinkSnr: up,
            downlinkSnr: down,
            proven: true,
            provenAt: nowMillis - provenAgoMinutes * 60 * 1000,
            isSelf: true);
    double tallyOnly(double w) => w / (w + 2);

    test('it fades with the age of the last proof', () {
      final fresh = graph.doorstepConfidence(mine(12, up: 11.6));
      final stale =
          graph.doorstepConfidence(mine(12, up: 11.6, provenAgoMinutes: 180));
      expect(fresh, greaterThan(stale));
      expect(stale, lessThan(tallyOnly(12) * 0.3 + 0.7 * 0.125 + 0.01),
          reason: 'after four half-lives the level is nearly gone');
      expect(stale, greaterThanOrEqualTo(tallyOnly(12) * 0.3),
          reason: 'the tally share never fades here');
    });

    test('my doorstep ranks on how it hears me, never on how I hear it', () {
      expect(graph.doorstepConfidence(mine(3, down: 10.0)),
          closeTo(tallyOnly(3), 1e-9),
          reason: 'a downlink level alone leaves a self row tally-only');
      final theirs = Candidate('BEEF', 3, EvidenceTier.proven,
          downlinkSnr: 10.0, proven: true, provenAt: nowMillis);
      expect(graph.doorstepConfidence(theirs), greaterThan(tallyOnly(3)),
          reason: "a contact's doorstep still falls back by reciprocity");
    });
  });

  test('an echo of my own flood confirms its first hop, nothing after it',
      () {
    // My message came back A277 -> BBBB -> BEEF -> A377. A277 heard me;
    // the rest forwarded each other.
    graph.observeOwnEcho(path([0xA2, 0x77, 0xBB, 0xBB, 0xBE, 0xEF, 0xA3, 0x77]), 2);
    final mine = graph.egressCandidates().single;
    expect(mine.repeaterHash, 'A277');
    expect(mine.proven, isTrue);
    expect(mine.uplinkSnr, isNull, reason: 'a repeater never reports the level');
    expect(graph.snapshot().edges, isEmpty,
        reason: 'the corridor came from the raw feed already');

    // A second echo through another first hop confirms a second doorstep.
    graph.observeOwnEcho(path([0x10, 0x00, 0xA3, 0x77]), 2);
    expect(graph.egressCandidates().map((c) => c.repeaterHash),
        containsAll(['A277', '1000']));
    expect(graph.egressCandidates().every((c) => c.proven), isTrue);

    graph.observeOwnEcho(path([0x5C]), 1); // 1-byte hashes: unusable
    expect(graph.counters.droppedNarrow, 1);
    graph.observeOwnEcho(Uint8List(0), 2); // no repeater involved
    expect(graph.egressCandidates(), hasLength(2));
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
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await first.init();
    first.setRadioIdentity(selfPk, 2);
    first.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    first.ingestContact(bobPk, 'Bob');
    await first.flush();

    final second = PathGraph(executor,
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await second.init();
    second.setRadioIdentity(selfPk, 2);
    expect(second.ingressCandidates(bobPk).single.repeaterHash, 'A277');
    expect(second.resolveName('Bob'), isA<UniqueNameOrigin>());
    await second.dispose();
  });

  test('provenCount counts every proof and the display tallies are exposed',
      () {
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    nowMillis += 1000;
    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: bobPk);
    var mine = graph.egressCandidates().single;
    expect(mine.provenCount, 2);
    expect(mine.provenAt, nowMillis);
    expect(mine.lastSeen, nowMillis);
    expect(graph.ingressCandidates(bobPk).single.provenCount, 2,
        reason: 'the last hop reached Bob twice');

    nowMillis += 1000;
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 7)],
        failureEpisode: false);
    mine = graph.egressCandidates().single;
    expect(mine.provenCount, 3);

    // Only hearing a repeater proves nothing in the sending direction.
    graph.observePath(path([0xBE, 0xEF]), 2,
        const ObservationOrigin.anonymous());
    final beef = graph
        .egressCandidates()
        .firstWhere((c) => c.repeaterHash == 'BEEF');
    expect(beef.provenCount, 0);
    expect(beef.finalCount, 1);
    expect(beef.provenAt, isNull);
  });
}
