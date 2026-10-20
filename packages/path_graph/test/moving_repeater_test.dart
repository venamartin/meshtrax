import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Owner, 2026-10-19: a repeater in a car collects links to every repeater
// it passes. Carpeaters may never advert or say their position, so the
// advert check is only one way to tag one; the user's word beats all.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const whaleKey = 'c882' 'aa' 'aa';
const twinKey = 'c882' 'bb' 'bb';
const minute = 60 * 1000;
const day = 24 * 60 * minute;

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

  // Berkeley, then Oakland about 8 km on.
  void advert(String key, double lat, double lon) =>
      graph.ingestNode('C882', name: 'WHITE_WHALE', pubkey: key, lat: lat, lon: lon);

  test('the same key advertising 2+ km away marks the repeater as moving', () {
    advert(whaleKey, 37.849, -122.271);
    expect(graph.movingStatus('C882'), isNull);
    nowMillis += 10 * minute;
    advert(whaleKey, 37.80, -122.20);
    final status = graph.movingStatus('c882')!;
    expect(status.reason, MovingReason.advertMoved);
    expect(status.acts, isTrue);
    expect(status.withMe, isFalse);
  });

  test('another key on the same code is a twin, not a move', () {
    advert(whaleKey, 37.849, -122.271);
    advert(twinKey.toUpperCase(), 38.58, -121.49);
    expect(graph.movingStatus('C882'), isNull);
    advert(twinKey, 38.70, -121.30);
    expect(graph.movingStatus('C882')!.reason, MovingReason.advertMoved,
        reason: 'the same key moving is a move, whatever its case');
  });

  test('a few hundred metres of GPS wander is not a move', () {
    advert(whaleKey, 37.849, -122.271);
    advert(whaleKey, 37.850, -122.272);
    expect(graph.movingStatus('C882'), isNull);
  });

  test('0,0 is no position: no move, and the known one stays', () {
    advert(whaleKey, 37.849, -122.271);
    advert(whaleKey, 0, 0);
    final node = graph.snapshot().nodes['C882']!;
    expect((node.lat, node.lon), (37.849, -122.271));
    advert(whaleKey, 37.849, -122.271);
    expect(graph.movingStatus('C882'), isNull);
  });

  test("a contact's doorstep stored at 0,0 does not wipe their list", () async {
    await graph.loadSession({
      'format': 'meshtrax-path-graph-session-v1',
      'nodes': [
        {'hash': 'A277', 'source': 'advert', 'lat': 0, 'lon': 0},
        {'hash': '5CBB', 'source': 'advert', 'lat': 37.77, 'lon': -122.42},
      ],
    });
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    graph.observePath(path([0x5C, 0xBB, 0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk));
    expect(graph.ingressCandidates(bobPk).map((c) => c.repeaterHash),
        containsAll(['5CBB', 'A277']),
        reason: '0,0 is not 12,000 km from San Francisco');
  });

  test('a move lasts mobileTagDays from the last one', () {
    advert(whaleKey, 37.849, -122.271);
    advert(whaleKey, 37.80, -122.20);
    nowMillis += 13 * day;
    expect(graph.movingStatus('C882'), isNotNull);
    nowMillis += 2 * day;
    expect(graph.movingStatus('C882'), isNull);
  });

  test("the user's word beats every detector", () {
    advert(whaleKey, 37.849, -122.271);
    advert(whaleKey, 37.80, -122.20);

    graph.setMovingOverride('c882', MovingOverride.staysPut);
    expect(graph.movingStatus('C882'), isNull);

    graph.setMovingOverride('C882', MovingOverride.withMe);
    final mine = graph.movingStatus('C882')!;
    expect(mine.reason, MovingReason.manualWithMe);
    expect(mine.withMe, isTrue);

    graph.setMovingOverride('C882', null);
    expect(graph.movingStatus('C882')!.reason, MovingReason.advertMoved);

    graph.setMovingOverride('96FD', MovingOverride.moves);
    expect(graph.movingRepeaters().keys, unorderedEquals(['C882', '96FD']));
  });

  test('the traffic detectors only watch until switched on', () async {
    await graph.loadSession({
      'format': 'meshtrax-path-graph-session-v1',
      'nodes': [
        {'hash': '9441', 'source': 'observed', 'auto_moving_at': nowMillis},
        {'hash': '7E9A', 'source': 'observed', 'auto_rides_with_me_at': nowMillis},
      ],
    });
    expect(graph.movingStatus('9441')!.reason, MovingReason.newLinks);
    expect(graph.movingStatus('9441')!.acts, isFalse);
    expect(graph.movingStatus('7E9A')!.withMe, isTrue);
    expect(graph.movingStatus('7E9A')!.acts, isFalse);

    graph.updateConfig(graph.config.copyWith(mobileAutoTagsRoute: true));
    expect(graph.movingStatus('9441')!.acts, isTrue);
    expect(graph.movingStatus('7E9A')!.acts, isTrue);
  });

  test('a link keeps the time it was first seen', () {
    graph.observePath(path([0xC8, 0x82, 0x91, 0x05]), 2,
        const ObservationOrigin.anonymous());
    final first = nowMillis;
    nowMillis += 30 * minute;
    graph.observePath(path([0xC8, 0x82, 0x91, 0x05]), 2,
        const ObservationOrigin.anonymous());
    final link = graph.snapshot().edges[('C882', '9105')]!;
    expect(link.firstObserved, first);
    expect(link.lastObserved, nowMillis);

    graph.reportSendResult(path([0xA2, 0x77, 0x13, 0x12]), false);
    expect(graph.snapshot().edges[('A277', '1312')]!.firstObserved, nowMillis);
    graph.observeTrace(['5CBB', 'A277'], [6, 5]);
    expect(graph.snapshot().edges[('5CBB', 'A277')]!.firstObserved, nowMillis);
  });

  test('tags and first-seen times survive a session round trip', () async {
    advert(whaleKey, 37.849, -122.271);
    advert(whaleKey, 37.80, -122.20);
    graph.setMovingOverride('96FD', MovingOverride.withMe);
    graph.observePath(path([0xC8, 0x82, 0x91, 0x05]), 2,
        const ObservationOrigin.anonymous());
    final saved = graph.saveSession();

    final other = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await other.init();
    await other.loadSession(saved);
    expect(other.movingStatus('C882')!.reason, MovingReason.advertMoved);
    expect(other.movingStatus('96FD')!.reason, MovingReason.manualWithMe);
    expect(other.snapshot().edges[('C882', '9105')]!.firstObserved, nowMillis);
    await other.dispose();
  });
}
