import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Owner, 2026-10-19: a moving repeater's links go stale as it drives.
// "A hears it" in Oakland at 10:00 and "it reaches B" in Sacramento at
// 14:00 must not read as a two-hop corridor. Everything about one counts
// for mobileFreshMinutes after it was last refreshed; my own row for one
// riding with me stays.

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
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  const a277 = [0xA2, 0x77];
  const whale = [0xC8, 0x82];
  const r1312 = [0x13, 0x12];

  /// A Discover answer: [hop] hears me, proven now.
  void proveMine(List<int> hop) => graph.observeDiscoverResults([
        DiscoverResponse(
            repeaterHash: hop
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase(),
            uplinkSnr: 8,
            rxSnr: 8)
      ], failureEpisode: false);

  /// A link a → b, seen in that direction only.
  void link(List<int> a, List<int> b) => graph.observePath(
      path([...a, ...b]), 2, const ObservationOrigin.anonymous(),
      lastHopHeard: false);

  /// Bob's packets arrive through [hop].
  void bobVia(List<int> hop) => graph.observePath(
      path(hop), 2, const ObservationOrigin.pubkeyConfirmed(bobPk),
      lastHopHeard: false);

  String? route() => switch (graph.findPath(bobPk)) {
        RouteResult(:final pathBytes) => [
            for (var i = 0; i < pathBytes.length; i += 2)
              pathBytes
                  .sublist(i, i + 2)
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join()
          ].join(','),
        _ => null,
      };

  FloodReason? floodReason() => switch (graph.findPath(bobPk)) {
        FloodResult(:final reason) => reason,
        _ => null,
      };

  test("a moving repeater's links stop carrying routes after the window", () {
    proveMine(a277);
    link(a277, whale);
    link(whale, r1312);
    bobVia(r1312);
    graph.setMovingOverride('C882', MovingOverride.moves);
    expect(route(), 'a277,c882,1312');

    nowMillis += 16 * minute;
    proveMine(a277);
    bobVia(r1312);
    expect(route(), isNull);
    expect(floodReason(), FloodReason.noCorridor);

    graph.setMovingOverride('C882', MovingOverride.staysPut);
    expect(route(), 'a277,c882,1312',
        reason: 'a fixed repeater keeps its links as before');
  });

  test('one fresh link is not enough: the wormhole stays shut', () {
    proveMine(a277);
    link(a277, whale); // Oakland, 10:00
    graph.setMovingOverride('C882', MovingOverride.moves);

    nowMillis += 4 * 60 * minute;
    proveMine(a277);
    link(whale, r1312); // Sacramento, 14:00
    bobVia(r1312);
    expect(route(), isNull);

    graph.setMovingOverride('C882', null);
    expect(route(), 'a277,c882,1312',
        reason: 'untagged, the four-hour-old Oakland link is the wormhole');
    graph.setMovingOverride('C882', MovingOverride.moves);

    link(a277, whale);
    expect(route(), 'a277,c882,1312',
        reason: 'both links heard in the last few minutes');
  });

  test('my doorstep on a moving repeater counts from its last proof', () {
    proveMine(whale);
    link(whale, r1312);
    bobVia(r1312);
    graph.setMovingOverride('C882', MovingOverride.moves);

    nowMillis += 20 * minute;
    link(whale, r1312);
    bobVia(r1312);
    expect(floodReason(), FloodReason.doorstepsMoving);
    final held = graph.egressCandidates().single;
    expect(graph.doorstepHold(held), FloodReason.doorstepsMoving);

    proveMine(whale);
    expect(route(), 'c882,1312');
  });

  test('one riding with me keeps my doorstep row; its links still expire', () {
    proveMine(whale);
    link(whale, r1312);
    bobVia(r1312);
    graph.setMovingOverride('C882', MovingOverride.withMe);

    nowMillis += 20 * minute;
    link(whale, r1312);
    bobVia(r1312);
    expect(route(), 'c882,1312', reason: 'it is in my car: it hears me');

    nowMillis += 20 * minute;
    bobVia(r1312);
    expect(route(), isNull, reason: 'its link to 1312 is 20 minutes old');
  });

  test("a contact's doorstep on a moving repeater counts from the last sighting",
      () {
    proveMine(a277);
    link(a277, whale);
    bobVia(whale);
    graph.setMovingOverride('C882', MovingOverride.moves);
    expect(route(), 'a277,c882');

    nowMillis += 20 * minute;
    proveMine(a277);
    link(a277, whale);
    expect(route(), isNull, reason: 'Bob was last heard through it 20 min ago');

    bobVia(whale);
    expect(route(), 'a277,c882');
  });

  test('watching-only tags change nothing', () async {
    await graph.loadSession({
      'format': 'meshtrax-path-graph-session-v1',
      'nodes': [
        {'hash': 'C882', 'source': 'observed', 'auto_moving_at': nowMillis},
      ],
    });
    graph.setRadioIdentity(selfPk, 2);
    proveMine(a277);
    link(a277, whale);
    link(whale, r1312);
    bobVia(r1312);

    nowMillis += 16 * minute;
    proveMine(a277);
    bobVia(r1312);
    expect(graph.movingStatus('C882')!.acts, isFalse);
    expect(route(), 'a277,c882,1312');

    graph.updateConfig(graph.config.copyWith(mobileAutoTagsRoute: true));
    expect(route(), isNull);
  });

  test('repeater routes and alternatives skip stale moving links too', () {
    proveMine(a277);
    link(a277, whale);
    link(whale, r1312);
    graph.setMovingOverride('C882', MovingOverride.moves);
    expect(graph.findPathToRepeater('1312'), isA<RouteResult>());
    expect(graph.findAlternativesToRepeater('1312'), isNotEmpty);

    nowMillis += 16 * minute;
    proveMine(a277);
    expect(graph.findPathToRepeater('1312'), isA<FloodResult>());
    expect(graph.findAlternativesToRepeater('1312'), isEmpty);
  });
}
