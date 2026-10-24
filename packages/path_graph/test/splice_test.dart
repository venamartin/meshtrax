import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

const a277 = [0xA2, 0x77];
const ad77 = [0xAD, 0x77];
const r1000 = [0x10, 0x00];
const beef = [0xBE, 0xEF];

const minute = 60 * 1000;

/// The splice (owner, 2026-10-23): Bob's flood arrived BEEF→1000→AD77.
/// AD77 is not a doorstep of mine, A277 is, and A277→AD77 was heard in the
/// sending direction. Pathfinder joins the proven part to the reversed
/// tail: A277→AD77→1000→BEEF, two hops guessed.
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

  void advance(int minutes) => nowMillis += minutes * minute;

  /// A277 hears me (proven), and A277→AD77 was heard the way my packet
  /// will go.
  void myEnd() {
    graph.reportSendResult(path(a277), true);
    graph.observePath(path([...a277, ...ad77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
  }

  /// Bob's flood BEEF→1000→AD77 heard [times] times, [gapMinutes] apart:
  /// the last one is the hint, the earlier ones its history.
  void bobsFlood({int times = 2, int gapMinutes = 11}) {
    for (var i = 0; i < times; i++) {
      if (i > 0) advance(gapMinutes);
      graph.observePath(path([...beef, ...r1000, ...ad77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk),
          messageId: 'bob-$i');
    }
  }

  List<int> bytesOf(PathResult r) => (r as RouteResult).pathBytes;

  test("joins my proven corridor to the reversed tail of Bob's path", () {
    myEnd();
    bobsFlood();

    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    final route = result as RouteResult;
    expect(route.pathBytes, [...a277, ...ad77, ...r1000, ...beef]);
    expect(route.guessedLinks, [false, true, true]);
    expect(route.guessedHops, 2);
    // Guessed hops are priced at guessQ, never read as certain.
    expect(route.hopProbabilities[1], 0.3);
    expect(route.hopProbabilities[2], 0.3);
    expect(route.estDelivery, lessThan(0.3 * 0.3 + 0.001));
  });

  test('an observed corridor beats a splice of equal length', () {
    myEnd();
    bobsFlood();
    // A277→1000 and 1000→BEEF heard the way my packet goes: a route with
    // no guesses, one hop shorter even.
    graph.observePath(path([...a277, ...r1000, ...beef]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);

    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.pathBytes, [...a277, ...r1000, ...beef]);
    expect(route.guessedHops, 0);
  });

  test('a path heard once is no hint', () {
    myEnd();
    bobsFlood(times: 1);

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('two sightings minutes apart are no hint either (ducting guard)',
      () {
    myEnd();
    bobsFlood(times: 2, gapMinutes: 3);

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('a hint goes stale after hintFreshMinutes', () {
    myEnd();
    bobsFlood();
    advance(11);

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('my end must still be a proven doorstep', () {
    // AD77 heard me? Never proven. Bob's path alone proves nothing about
    // my end, so no splice starts at AD77.
    bobsFlood();

    expect(graph.findPath(bobPk), isA<FloodResult>());
  });

  test('the guessed-hop cap holds', () {
    graph.reportSendResult(path(a277), true);
    // Bob is one hop farther: BEEF→1000→AD77→A277-ish corridor needs
    // three guesses to reach him from A277 if A277→AD77 is itself a guess.
    for (var i = 0; i < 2; i++) {
      if (i > 0) advance(11);
      graph.observePath(path([...beef, ...r1000, ...ad77, ...a277]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk),
          messageId: 'far-$i');
    }

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('a hop too long for LoRa is not reversed', () {
    myEnd();
    // AD77 and 1000 sit 200 km apart: ducting, not a corridor.
    graph.ingestNode('AD77', name: 'AD77', lat: 36.6, lon: -121.9);
    graph.ingestNode('1000', name: '1000', lat: 38.4, lon: -121.9);
    bobsFlood();

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('the store beats the overlay once a direction has been tried', () {
    myEnd();
    bobsFlood();
    // A send AD77→1000→BEEF already failed on a non-splice route: the store
    // holds that direction as tried and unusable, so no guess re-opens it.
    graph.reportSendResult(path([...ad77, ...r1000]), false);

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });

  test('a failed splice mints nothing and does not charge my doorstep', () {
    myEnd();
    bobsFlood();
    final route = graph.findPath(bobPk) as RouteResult;

    graph.reportSendResult(route.pathBytes, false,
        contactPubkey: bobPk, guessedLinks: route.guessedLinks);

    expect(graph.snapshot().edges.containsKey(('AD77', '1000')), isFalse);
    expect(graph.snapshot().edges.containsKey(('1000', 'BEEF')), isFalse);
    final a277Row =
        graph.egressCandidates().firstWhere((c) => c.repeaterHash == 'A277');
    expect(a277Row.failedSinceProof, 0);
    // The guess stands for the next ladder: nothing real said no.
    expect(bytesOf(graph.findPath(bobPk)), route.pathBytes);
  });

  test('a delivered splice proves its guessed hops forward', () {
    myEnd();
    bobsFlood();
    final route = graph.findPath(bobPk) as RouteResult;

    graph.reportSendResult(route.pathBytes, true,
        contactPubkey: bobPk, guessedLinks: route.guessedLinks);

    final e = graph.snapshot().edges[('AD77', '1000')]!;
    expect(e.s, 1);
    expect(e.n, 1);
    final again = graph.findPath(bobPk) as RouteResult;
    expect(again.pathBytes, route.pathBytes);
    expect(again.guessedHops, 0);
  });

  test('hints die with the radio identity', () {
    myEnd();
    bobsFlood();
    graph.setRadioIdentity('cdcdcd', 2);
    graph.reportSendResult(path(a277), true);

    expect(graph.findPath(bobPk), isA<FloodResult>());
  });

  test('a channel line matched by name supplies no hint', () {
    myEnd();
    graph.ingestContact(bobPk, 'Bob');
    for (var i = 0; i < 2; i++) {
      if (i > 0) advance(11);
      graph.observeChannelSender('Bob', path([...beef, ...r1000, ...ad77]), 2);
    }

    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noCorridor);
  });
}
