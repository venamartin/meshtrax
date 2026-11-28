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
const hour = 60 * minute;

/// Owner, 2026-11-28: "we must treat two repeaters that constantly have one
/// way communication as a possible path. A to B heard many times we have
/// to presume B to A. If we find it fails, then it loses weight."
///
/// Bob's floods arrive BEEF→1000→AD77. AD77 is not a doorstep of mine,
/// A277 is, and A277→AD77 was heard the way my packet will go. The way to
/// Bob is his path the other way round, A277→AD77→1000→BEEF, over two
/// links never heard in that direction. (Before this, only a contact's
/// last few paths could be turned round, as guesses at a fixed 30%, two to
/// a route: the splice of 2026-10-23.)
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

  /// A277 hears me (proven), and A277→AD77 was heard the way my packet
  /// will go.
  void myEnd() {
    graph.reportSendResult(path(a277), true);
    for (var i = 0; i < 30; i++) {
      graph.observePath(path([...a277, ...ad77]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
    }
  }

  /// Bob's flood BEEF→1000→AD77, heard [times] times a minute apart.
  void bobsFlood({required int times}) {
    for (var i = 0; i < times; i++) {
      nowMillis += minute;
      graph.observePath(path([...beef, ...r1000, ...ad77]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk),
          messageId: 'bob-$nowMillis');
    }
  }

  final wayToBob = [...a277, ...ad77, ...r1000, ...beef];

  /// The rating of the link [from]→[to] as the search prices it.
  double rating(String from, String to) {
    final edges = graph.snapshot().edges;
    final e = edges[(from, to)], reverse = edges[(to, from)];
    return e != null
        ? graph.estimator.calibratedP(e, nowMillis, reverse: reverse)
        : graph.estimator.presumedP(reverse!, nowMillis);
  }

  test('a path heard coming in is a route going out', () {
    myEnd();
    bobsFlood(times: 30);

    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.pathBytes, wayToBob);
    expect(route.guessedLinks, everyElement(isFalse),
        reason: 'presumed links are links, not guesses');
    expect(route.hopProbabilities[1], greaterThan(0.7),
        reason: 'AD77→1000, never heard that way, rated as 1000→AD77 is');
    expect(route.hopProbabilities[1], closeTo(rating('1000', 'AD77'), 1e-9));
    expect(route.hopProbabilities[2], closeTo(rating('BEEF', '1000'), 1e-9));
    expect(graph.snapshot().edges.containsKey(('AD77', '1000')), isFalse,
        reason: 'nothing is written down that was not heard or tried');
  });

  test('heard a few times it is still a route, rated low', () {
    myEnd();
    bobsFlood(times: 2);
    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.pathBytes, wayToBob);
    expect(route.hopProbabilities[1], closeTo(2 / 12, 0.01));
  });

  test('a way heard going out beats the presumed one when heard as often',
      () {
    myEnd();
    bobsFlood(times: 30);
    // A277→1000→BEEF heard the way my packet goes: a repeater shorter.
    for (var i = 0; i < 30; i++) {
      graph.observePath(path([...a277, ...r1000, ...beef]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
    }
    expect((graph.findPath(bobPk) as RouteResult).pathBytes,
        [...a277, ...r1000, ...beef]);
  });

  test('a send that fails over it takes weight from the direction it went',
      () {
    myEnd();
    bobsFlood(times: 30);
    final before = rating('AD77', '1000');
    final inward = rating('1000', 'AD77');

    for (var i = 0; i < 6; i++) {
      graph.reportSendResult(path(wayToBob), false, contactPubkey: bobPk);
    }
    expect(rating('AD77', '1000'), lessThan(before * 0.6),
        reason: 'six sends lost on the way out');
    expect(rating('1000', 'AD77'), closeTo(inward, 0.02),
        reason: 'nothing was learned about the way in');
    expect(graph.snapshot().edges[('AD77', '1000')]!.obsCount, 0);

    // A suspicion fades, as on any link.
    nowMillis += 5 * 24 * hour;
    bobsFlood(times: 30);
    expect(rating('AD77', '1000'), greaterThan(before * 0.9));
  });

  test('a delivery over it is proof of that direction', () {
    myEnd();
    bobsFlood(times: 2);
    final before = rating('AD77', '1000');
    for (var i = 0; i < 4; i++) {
      graph.reportSendResult(path(wayToBob), true, contactPubkey: bobPk);
    }
    expect(graph.snapshot().edges[('AD77', '1000')]!.s, 4);
    expect(rating('AD77', '1000'), greaterThan(before * 2));
  });

  test('a link gone quiet for days is presumed no more than it is rated',
      () {
    myEnd();
    bobsFlood(times: 2);
    nowMillis += 12 * 24 * hour;
    graph.reportSendResult(path(a277), true);
    expect(graph.findPath(bobPk), isNot(isA<RouteResult>()),
        reason: 'two sightings twelve days ago are next to nothing either '
            'way round');
  });

  test('a link touching a moving repeater is presumed only while fresh',
      () {
    myEnd();
    bobsFlood(times: 30);
    graph.setMovingOverride('1000', MovingOverride.moves);
    expect(graph.findPath(bobPk), isA<RouteResult>());
    nowMillis += 40 * minute;
    graph.reportSendResult(path(a277), true);
    expect(graph.findPath(bobPk), isNot(isA<RouteResult>()));
  });
}
