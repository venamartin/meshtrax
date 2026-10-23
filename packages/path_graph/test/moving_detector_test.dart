import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Owner, 2026-10-19: carpeaters may never advert or say their position.
// From traffic alone: a moving repeater keeps meeting repeaters it never
// had links to and leaves its old neighbours behind. Field, 2026-10-23: a
// busy hilltop meets new ones too — one-off garbage codes and repeaters
// the radio had simply not sampled with it yet — but keeps being heard
// with the old ones. These detectors only watch until mobileAutoTagsRoute
// is switched on.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const minute = 60 * 1000;
const hour = 60 * minute;

void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;
  late List<(String, MovingReason, bool)> signs;

  const whale = [0xC8, 0x82];
  var next = 0x1000;
  var pool = 0x2000;
  late int poolNext;

  setUp(() async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    signs = [];
    graph.onMovingSign =
        (hash, reason, check) => signs.add((hash, reason, check.tagged));
    // Repeaters around the mesh, heard a day ago: the ones a moving
    // repeater meets later.
    poolNext = pool;
    for (var i = 0; i < 16; i++) {
      graph.observePath(path([0x13, 0x12, (pool + i) >> 8, (pool + i) & 0xFF]),
          2, const ObservationOrigin.anonymous(),
          lastHopHeard: false);
    }
    pool += 16;
    nowMillis += 25 * hour;
  });

  tearDown(() => graph.dispose());

  /// A packet relayed by [a] then a code never seen before; I did not
  /// hear the last hop myself (no new repeater for me).
  void meetsNew(List<int> a, {bool iHeardIt = false}) {
    final b = next++;
    graph.observePath(path([...a, b >> 8, b & 0xFF]), 2,
        const ObservationOrigin.anonymous(),
        lastHopHeard: iHeardIt);
  }

  /// A packet relayed by [a] then a repeater known for a day that [a]
  /// never had a link to.
  void meetsKnown(List<int> a) {
    final b = poolNext++;
    graph.observePath(path([...a, b >> 8, b & 0xFF]), 2,
        const ObservationOrigin.anonymous(),
        lastHopHeard: false);
  }

  /// [hop] heard with [count] neighbours (first seen now).
  List<List<int>> neighbours(List<int> hop, int count) {
    final codes = [
      for (var i = 0; i < count; i++) [0x40 + i, 0x01],
    ];
    for (final code in codes) {
      graph.observePath(path([...hop, ...code]), 2,
          const ObservationOrigin.anonymous(),
          lastHopHeard: false);
    }
    return codes;
  }

  void hearAgain(List<int> hop, List<List<int>> codes) {
    for (final code in codes) {
      graph.observePath(path([...hop, ...code]), 2,
          const ObservationOrigin.anonymous(),
          lastHopHeard: false);
    }
  }

  /// Known for a day: one link, 25 hours ago.
  void knownForADay(List<int> hop) {
    meetsNew(hop);
    nowMillis += 25 * hour;
  }

  /// New links at 0, 0, +30, +60, +60 min: five, over three half-hours.
  void steadyNovelty(List<int> hop,
      {void Function(List<int> hop)? meet, void Function()? between}) {
    for (final step in [0, 0, 30, 30, 0]) {
      nowMillis += step * minute;
      between?.call();
      (meet ?? meetsKnown)(hop);
    }
  }

  test('steady novelty from a repeater known for a day: watching only', () {
    knownForADay(whale);
    steadyNovelty(whale);
    final status = graph.movingStatus('C882')!;
    expect(status.reason, MovingReason.newLinks);
    expect(status.acts, isFalse);
    expect(signs, [('C882', MovingReason.newLinks, true)]);

    nowMillis += 10 * minute;
    meetsKnown(whale);
    expect(signs, hasLength(1), reason: 'told once a day, not per link');
  });

  test('one burst is not enough', () {
    knownForADay(whale);
    for (var i = 0; i < 12; i++) {
      nowMillis += 20 * 1000;
      meetsKnown(whale);
    }
    expect(graph.movingStatus('C882'), isNull);
  });

  test('a repeater known for less than a day is not judged', () {
    steadyNovelty(whale);
    expect(graph.movingStatus('C882'), isNull);
  });

  test('my own drive does not make fixed repeaters look new', () {
    knownForADay(whale);
    // I meet a repeater I never had before between its new links.
    steadyNovelty(whale, between: () => meetsNew([0xBE, 0xEF], iHeardIt: true));
    expect(graph.movingStatus('C882'), isNull);
  });

  // 1000 and MMC2, 2026-10-23: a third of their new links went to one-off
  // codes no real key could have (00/FF prefixes and all).
  test('a hilltop meeting codes nobody knew is not moving', () {
    knownForADay(whale);
    steadyNovelty(whale, meet: meetsNew);
    expect(graph.movingStatus('C882'), isNull);
    expect(signs, isEmpty);
  });

  test('a busy repeater still heard with its old neighbours stays put', () {
    final old = neighbours(whale, 6);
    nowMillis += 25 * hour;
    steadyNovelty(whale, between: () => hearAgain(whale, old));
    expect(graph.movingStatus('C882'), isNull);
    expect(signs, [('C882', MovingReason.newLinks, false)],
        reason: '5 new against 6 old: told why, not tagged');

    nowMillis += 10 * minute;
    meetsKnown(whale);
    expect(signs, hasLength(1), reason: 'told once a day, not per link');
  });

  test('old neighbours not heard in the window do not hold it back', () {
    neighbours(whale, 6);
    nowMillis += 25 * hour;
    steadyNovelty(whale);
    expect(graph.movingStatus('C882')!.reason, MovingReason.newLinks);
  });

  test('one that keeps proving it hears me while meeting new ones rides with me',
      () {
    // Proofs at 0, +20, +40, +60 min; new links at +20, +40, +60.
    graph.observeOwnEcho(path(whale), 2);
    for (var slice = 1; slice <= 3; slice++) {
      nowMillis += 20 * minute;
      graph.observeOwnEcho(path(whale), 2);
      meetsNew(whale, iHeardIt: true);
      meetsNew(whale, iHeardIt: true);
    }
    final status = graph.movingStatus('C882')!;
    expect(status.reason, MovingReason.ridesWithMe);
    expect(status.withMe, isTrue);
    expect(status.acts, isFalse);
    expect(signs.map((s) => s.$2), contains(MovingReason.ridesWithMe));
  });

  test('a busy doorstep at home still heard with its old neighbours does not '
      'ride with me', () {
    final old = neighbours(whale, 7);
    nowMillis += 25 * hour;
    graph.observeOwnEcho(path(whale), 2);
    for (var slice = 1; slice <= 3; slice++) {
      nowMillis += 20 * minute;
      graph.observeOwnEcho(path(whale), 2);
      hearAgain(whale, old);
      meetsNew(whale, iHeardIt: true);
      meetsNew(whale, iHeardIt: true);
    }
    expect(graph.movingStatus('C882'), isNull);
    expect(signs, contains(('C882', MovingReason.ridesWithMe, false)));
  });

  test('a repeater at home that keeps proving itself meets nobody new', () {
    graph.observePath(path([...whale, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous());
    for (var slice = 0; slice < 6; slice++) {
      nowMillis += 20 * minute;
      graph.observeOwnEcho(path(whale), 2);
      graph.observePath(path([...whale, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous());
    }
    expect(graph.movingStatus('C882'), isNull);
    expect(signs, isEmpty);
  });

  // DEAD and D237, 2026-10-23: two or three keys on one code look like one
  // repeater in several places.
  test('a code several keys use says so instead of "moves"', () {
    graph.ingestNode('C882', name: 'WHITE_WHALE', pubkey: 'c882aaaa');
    graph.ingestContact('C882BBBB', 'Twin');
    graph.ingestContact('c882aaaa', 'WHITE_WHALE');
    knownForADay(whale);
    steadyNovelty(whale);
    final status = graph.movingStatus('c882')!;
    expect(status.reason, MovingReason.sharedCode);
    expect(status.sharedKeys, 2, reason: 'one key counted once, any case');
    expect(status.acts, isFalse);
    expect(graph.movingRepeaters()['C882']!.reason, MovingReason.sharedCode);

    graph.setMovingOverride('C882', MovingOverride.moves);
    expect(graph.movingStatus('C882')!.reason, MovingReason.manual,
        reason: "the user's word is never relabelled");
  });

  test('one key on its code is plain "moves"', () {
    graph.ingestNode('C882', name: 'WHITE_WHALE', pubkey: 'c882aaaa');
    graph.ingestContact('c882aaaa', 'WHITE_WHALE');
    knownForADay(whale);
    steadyNovelty(whale);
    expect(graph.movingStatus('C882')!.reason, MovingReason.newLinks);
    expect(graph.movingStatus('C882')!.sharedKeys, isNull);
  });

  test('switched on, a detector tag acts on routing', () {
    knownForADay(whale);
    steadyNovelty(whale);
    graph.updateConfig(graph.config.copyWith(mobileAutoTagsRoute: true));
    expect(graph.movingStatus('C882')!.acts, isTrue);
  });
}
