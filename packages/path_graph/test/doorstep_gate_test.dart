import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Field 2026-10-17 (drive Aromas → San Jose): the home repeater started
// every route 40 km away. A failed one-hop route marked nothing down,
// Dijkstra never drops a source by weight and the ladder always tries the
// best route, so only excluding a doorstep from starting routes can turn
// a stale route into the flood that teaches the graph where I am.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const minute = 60 * 1000;

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

  void echo(List<int> firstHop) => graph.observeOwnEcho(path(firstHop), 2);

  /// A link a → b, seen in that direction only.
  void corridor(List<int> a, List<int> b) => graph.observePath(
      path([...a, ...b]), 2, const ObservationOrigin.anonymous(),
      lastHopHeard: false);

  /// Bob's packets arrive through [hop].
  void bobVia(List<int> hop) => graph.observePath(
      path(hop), 2, const ObservationOrigin.pubkeyConfirmed(bobPk),
      lastHopHeard: false);

  /// A packet reached me with [hop] as its last repeater.
  void heardLast(List<int> hop) => graph.observePath(
      path([0x13, 0x12, ...hop]), 2, const ObservationOrigin.anonymous());

  void failed(List<int> route) =>
      graph.reportSendResult(path(route), false, contactPubkey: bobPk);

  /// A corridor with delivery history: one failure's n+1 would make a
  /// passive link unusable on its own, which is not what is under test.
  void provenCorridor(List<int> route) {
    for (var i = 0; i < 5; i++) {
      graph.reportSendResult(path(route), true, contactPubkey: bobPk);
    }
  }

  String? firstHop() => switch (graph.findPath(bobPk)) {
        RouteResult(:final pathBytes) =>
          pathBytes.take(2).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        _ => null,
      };

  FloodReason? floodReason() => switch (graph.findPath(bobPk)) {
        FloodResult(:final reason) => reason,
        _ => null,
      };

  const a277 = [0xA2, 0x77];
  const beef = [0xBE, 0xEF];
  const r1312 = [0x13, 0x12];

  group('failures since the last proof', () {
    test('two failed sends from my only doorstep and the next send floods',
        () {
      provenCorridor([...a277, ...r1312]);
      expect(firstHop(), 'a277');

      failed([...a277, ...r1312]);
      expect(firstHop(), 'a277', reason: 'one failure is not a verdict');
      failed([...a277, ...r1312]);
      expect(floodReason(), FloodReason.doorstepsFailing);
      expect(graph.doorstepHold(graph.egressCandidates().single),
          FloodReason.doorstepsFailing);
    });

    test('any proof resets the count', () {
      provenCorridor([...a277, ...r1312]);
      failed([...a277, ...r1312]);
      failed([...a277, ...r1312]);
      expect(floodReason(), FloodReason.doorstepsFailing);

      echo(a277); // the flood's echo: it still hears me
      expect(firstHop(), 'a277');
      expect(graph.egressCandidates().single.failedSinceProof, 0);
    });

    test('another proven doorstep takes over', () {
      for (var i = 0; i < 4; i++) {
        echo(a277);
      }
      echo(beef);
      bobVia(r1312);
      corridor(a277, r1312);
      corridor(beef, r1312);
      expect(firstHop(), 'a277', reason: 'the heavier doorstep starts');

      failed([...a277, ...r1312]);
      failed([...a277, ...r1312]);
      expect(firstHop(), 'beef');
    });

    test('a live route whose first hop is held is dropped', () {
      bobVia(r1312);
      graph.reportSendResult(path([...a277, ...r1312]), true,
          contactPubkey: bobPk, tally: false);
      expect(firstHop(), 'a277', reason: 'the PATH reply route leads');

      failed([...a277, ...r1312]);
      failed([...a277, ...r1312]);
      expect(floodReason(), FloodReason.doorstepsFailing);
    });
  });

  group('silence while I hear others', () {
    test('a doorstep I stop hearing stops starting routes', () {
      echo(a277);
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);
      expect(firstHop(), 'beef');

      nowMillis += 40 * minute;
      for (var i = 0; i < 3; i++) {
        heardLast(a277);
        nowMillis += minute;
      }
      final held = graph.egressCandidates()
          .firstWhere((c) => c.repeaterHash == 'BEEF');
      expect(graph.doorstepHold(held), FloodReason.doorstepsQuiet);
      expect(firstHop(), isNot('beef'),
          reason: 'A277 still starts, but has no corridor: noCorridor');
      expect(floodReason(), FloodReason.noCorridor);
    });

    test('when every doorstep is quiet the flood says so', () {
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);

      nowMillis += 40 * minute;
      for (var i = 0; i < 3; i++) {
        heardLast(a277); // heard only, never proven: cannot start a route
        nowMillis += minute;
      }
      expect(floodReason(), FloodReason.doorstepsQuiet);
    });

    test('one stray packet after a quiet stretch excludes nothing', () {
      echo(a277);
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);

      nowMillis += 40 * minute;
      heardLast(a277);
      expect(firstHop(), 'beef');
    });

    test('a proof keeps a doorstep alive even when I never hear it', () {
      echo(a277);
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);

      nowMillis += 40 * minute;
      echo(beef); // it echoed my send; its own transmissions I never hear
      for (var i = 0; i < 3; i++) {
        heardLast(a277);
        nowMillis += minute;
      }
      expect(firstHop(), 'beef');
    });

    test('my only doorstep is never quiet: the clock is my own hearing', () {
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);

      nowMillis += 3 * 60 * minute;
      for (var i = 0; i < 3; i++) {
        heardLast(beef);
        nowMillis += minute;
      }
      expect(firstHop(), 'beef');
    });

    test('a quiet mesh excludes nothing', () {
      echo(a277);
      echo(beef);
      bobVia(r1312);
      corridor(beef, r1312);

      nowMillis += 3 * 60 * minute;
      expect(firstHop(), 'beef');
    });
  });
}
