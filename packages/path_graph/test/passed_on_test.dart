import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Field 2026-11-24 (at home, the repeater 30 m away, the contact at home
// too): one missed ACK and the next try was a flood, a second and every
// route to every contact was dropped for ten minutes. The ACK was missed
// because two radios sent at once, about one try in four. A failed try is
// now charged by where it broke, and what tells is this radio hearing its
// own packet passed on.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const minute = 60 * 1000;

const a277 = [0xA2, 0x77];
const beef = [0xBE, 0xEF];
const aa77 = [0xAA, 0x77];
const home = [...a277, ...aa77];

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
    // A route with a delivery record: one failure's count would make an
    // unproven link unusable by itself, which is not what is under test.
    for (var i = 0; i < 5; i++) {
      graph.reportSendResult(path(home), true, contactPubkey: bobPk);
    }
  });

  tearDown(() => graph.dispose());

  /// A try on [route] got no ACK, with [hopsHeard] of its hops heard
  /// passing it on.
  void missed(int? hopsHeard, [List<int> route = home]) =>
      graph.reportSendResult(path(route), false,
          contactPubkey: bobPk, hopsHeard: hopsHeard);

  String? firstHop() => switch (graph.findPath(bobPk)) {
        RouteResult(:final pathBytes) => pathBytes
            .take(2)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
        _ => null,
      };

  Candidate mine(String hash) =>
      graph.egressCandidates().firstWhere((c) => c.repeaterHash == hash);

  double estimate() => (graph.findPath(bobPk) as RouteResult).estDelivery;

  group('heard passing it on', () {
    test('however many ACKs are missed, my doorstep is not charged', () {
      for (var i = 0; i < 6; i++) {
        missed(1);
      }
      expect(mine('A277').failedSinceProof, 0);
      expect(firstHop(), 'A277');
      expect(graph.selfAdvice(contactPubkey: bobPk), isNull);
    });

    test('it is a proof that it hears me, and pushes no other doorstep down',
        () {
      graph.observeOwnEcho(path(beef), 2);
      final before = mine('BEEF').weight;
      missed(null);
      expect(mine('A277').failedSinceProof, 1);

      graph.observePassedOn(path(home), 2);
      expect(mine('A277').failedSinceProof, 0);
      expect(mine('BEEF').weight, before);
    });

    test('where the radio knows its area, it is filed as heard here', () {
      nowMillis += 4 * minute;
      graph.setPlace('c1_1', const {});
      expect(firstHop(), isNull, reason: 'nobody was heard hearing me here');
      graph.observePassedOn(path(home), 2);
      expect(graph.placesHere().keys, ['A277']);
      expect(firstHop(), 'A277');
    });

    test('the links up to the last hop heard carried it; the rest are in '
        'question', () {
      final clean = estimate();
      missed(2);
      final carried = estimate();
      expect(carried, greaterThanOrEqualTo(clean),
          reason: 'A277 to AA77 carried it');

      missed(1);
      expect(estimate(), lessThan(carried),
          reason: 'past A277 nobody was heard: that link may have failed');
    });
  });

  group('listened for and not heard, the same packet sent twice', () {
    test('a doubt about my doorstep alone, which one Discover settles', () {
      final clean = estimate();
      missed(0);
      expect(graph.selfAdvice(contactPubkey: bobPk),
          DiscoverReason.doorstepSilent);
      expect(mine('A277').failedSinceProof, 1);
      expect(firstHop(), 'A277', reason: 'one doubt drops nothing');
      expect(estimate(), clean, reason: 'no link was tried');
      final theirs = graph.ingressCandidates(bobPk)
          .firstWhere((c) => c.repeaterHash == 'AA77');
      graph.reportFloodDelivered(bobPk);
      expect(theirs.failedSinceProof, 0,
          reason: 'the packet never reached their repeater');
    });

    test('its Discover answer ends the doubt', () {
      missed(0);
      graph.observeDiscoverResults(
          [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 12)],
          failureEpisode: false);
      expect(graph.selfAdvice(contactPubkey: bobPk), isNull);
      expect(mine('A277').failedSinceProof, 0);
    });

    test('another repeater answers and it does not: that one starts the '
        'routes, until it proves itself again', () {
      // Bob is reachable from BEEF too.
      for (var i = 0; i < 5; i++) {
        graph.reportSendResult(path([...beef, ...aa77]), true,
            contactPubkey: bobPk);
      }
      for (var i = 0; i < 5; i++) {
        graph.observeOwnEcho(path(a277), 2);
      }
      expect(firstHop(), 'A277');

      missed(0);
      expect(firstHop(), 'A277', reason: 'nobody else has spoken yet');
      nowMillis += 3000;
      graph.observeDiscoverResults(
          [const DiscoverResponse(repeaterHash: 'BEEF', uplinkSnr: 2)],
          failureEpisode: false);
      expect(firstHop(), 'BEEF');

      nowMillis += 2000;
      graph.observeDiscoverResults(
          [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 12)],
          failureEpisode: false);
      expect(firstHop(), 'A277');
    });

    test('a doubt is over after ten minutes', () {
      missed(0);
      nowMillis += 11 * minute;
      expect(graph.selfAdvice(contactPubkey: bobPk), isNull);
    });

    test('twice in a row and it stops starting routes, here, until it proves '
        'itself here', () {
      nowMillis += 4 * minute;
      graph.setPlace('c1_1', const {});
      graph.observePassedOn(path(home), 2);
      missed(0);
      expect(firstHop(), 'A277');
      missed(0);
      expect(graph.findPath(bobPk), isA<FloodResult>());
      expect(graph.placesHere()['A277']!.failedHere, isTrue);

      graph.observePassedOn(path(home), 2);
      expect(firstHop(), 'A277');
      expect(graph.placesHere()['A277']!.failedHere, isFalse);
    });
  });

  test('nobody could be listened for: charged as before, two in a row hold '
      'the doorstep', () {
    missed(null);
    expect(firstHop(), 'A277');
    missed(null);
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsFailing);
  });
}
