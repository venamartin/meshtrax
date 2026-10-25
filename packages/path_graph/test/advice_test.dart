import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const carolPk = 'c0' 'c0' 'c0';
const a277 = [0xA2, 0x77];
const beef = [0xBE, 0xEF];
const minute = 60 * 1000;

/// selfAdvice: one Discover settles a doubt about MY side of the air.
/// Never about theirs.
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

  void advance(int ms) => nowMillis += ms;

  /// Bob and Carol both sit behind A277 (A277 → BEEF → them).
  void corridors() {
    for (final who in [bobPk, carolPk]) {
      graph.reportSendResult(path([...a277, ...beef]), true, contactPubkey: who);
    }
  }

  test('nothing to say with no cell and nothing wrong', () {
    corridors();
    expect(graph.selfAdvice(contactPubkey: bobPk), isNull);
  });

  test('in a known area nobody has been heard hearing me', () {
    corridors();
    advance(4 * minute); // long enough ago that nothing is filed here
    graph.setPlace('c1_1', const {});
    expect(graph.selfAdvice(), DiscoverReason.noDoorstepHere);
    graph.observeOwnEcho(path(a277), 2);
    expect(graph.selfAdvice(), isNull);
  });

  test('moved since the last proof', () {
    corridors();
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    advance(minute);
    graph.setPlace('c9_9', const {});
    expect(graph.selfAdvice(), DiscoverReason.movedSinceProof);
  });

  test('a doorstep failing toward two contacts is my side; one is not', () {
    corridors();
    for (var i = 0; i < 2; i++) {
      graph.reportSendResult(path([...a277, ...beef]), false, contactPubkey: bobPk);
    }
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsFailing);
    expect(graph.selfAdvice(), isNull, reason: 'one contact: could be theirs');
    graph.reportSendResult(path([...a277, ...beef]), false, contactPubkey: carolPk);
    expect(graph.selfAdvice(), DiscoverReason.doorstepsFailingMe);
    // A proof clears the record.
    graph.observeOwnEcho(path(a277), 2);
    expect(graph.selfAdvice(), isNull);
  });

  test('never while their doorsteps are the ones failing', () {
    corridors();
    // A277 fails twice toward Bob and once toward Carol: my side is in
    // doubt (two contacts), but BEEF has failed Bob twice as well, so for
    // Bob the doubt is his end and no Discover can settle it.
    for (var i = 0; i < 2; i++) {
      graph.reportSendResult(path([...a277, ...beef]), false, contactPubkey: bobPk);
    }
    graph.reportSendResult(path([...a277, ...beef]), false, contactPubkey: carolPk);
    expect(graph.selfAdvice(contactPubkey: bobPk), isNull);
    expect(graph.selfAdvice(contactPubkey: carolPk),
        DiscoverReason.doorstepsFailingMe);
  });

  test('a whole ladder unanswered with no echo, for ten minutes', () {
    corridors();
    graph.reportLadderEnded(bobPk, delivered: false, echoHeard: null);
    expect(graph.selfAdvice(), isNull, reason: 'no flood was observable');
    graph.reportLadderEnded(bobPk, delivered: false, echoHeard: true);
    expect(graph.selfAdvice(), isNull, reason: 'somebody echoed it');
    graph.reportLadderEnded(bobPk, delivered: false, echoHeard: false);
    expect(graph.selfAdvice(), DiscoverReason.ladderUnanswered);
    advance(11 * minute);
    expect(graph.selfAdvice(), isNull);
  });

  group('after a move, their way back decides the first send', () {
    void theirWayBackViaA277() {
      // Bob's packets reach me BEEF → A277: his radio holds that route.
      for (var i = 0; i < 2; i++) {
        graph.observePath(path([...beef, ...a277]), 2,
            const ObservationOrigin.pubkeyConfirmed(bobPk),
            messageId: 'bob-$i');
      }
    }

    test('their way back ends where I was: flood first', () {
      corridors();
      graph.setPlace('c1_1', const {});
      graph.observeOwnEcho(path(a277), 2);
      theirWayBackViaA277();
      expect(graph.findPath(bobPk), isA<RouteResult>());

      advance(minute);
      graph.setPlace('c9_9', const {});
      // Here only F5EE answers a Discover, and F5EE reaches BEEF: a route
      // out exists, but Bob's radio would ACK on BEEF, A277 and A277 no
      // longer hears me (the simulator's deaf-here run, 2026-10-25).
      graph.observeDiscoverResults(
          [const DiscoverResponse(repeaterHash: 'F5EE', uplinkSnr: 8)],
          failureEpisode: false);
      graph.observePath(path([0xF5, 0xEE, ...beef]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
      expect((graph.findPath(bobPk) as FloodResult).reason,
          FloodReason.movedSinceTheyReachedMe);
      // Carol never showed a way back: nothing says it is wrong.
      expect(graph.findPath(carolPk), isA<RouteResult>());

      // A flood got through: their radio knows the way back now.
      graph.reportFloodDelivered(bobPk);
      expect(graph.findPath(bobPk), isA<RouteResult>());
    });

    test('a step to the next cell is not a move', () {
      corridors();
      graph.setPlace('c1_1', {'c1_2'});
      graph.observeOwnEcho(path(a277), 2);
      theirWayBackViaA277();
      graph.setPlace('c1_2', {'c1_1'});
      expect(graph.findPath(bobPk), isA<RouteResult>());
    });
  });
}
