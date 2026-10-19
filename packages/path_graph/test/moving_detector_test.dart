import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Owner, 2026-10-19: carpeaters may never advert or say their position.
// From traffic alone: a fixed repeater's links fill within a day and then
// barely grow; a moving one keeps meeting repeaters it never had links to.
// These detectors only watch until mobileAutoTagsRoute is switched on.

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const minute = 60 * 1000;
const hour = 60 * minute;

void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;
  late List<(String, MovingReason)> signs;

  setUp(() async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    signs = [];
    graph.onMovingSign = (hash, reason) => signs.add((hash, reason));
  });

  tearDown(() => graph.dispose());

  const whale = [0xC8, 0x82];
  var next = 0x1000;

  /// A packet relayed by [a] then a repeater never seen before; I did not
  /// hear the last hop myself (no new repeater for me).
  void meetsNew(List<int> a, {bool iHeardIt = false}) {
    final b = next++;
    graph.observePath(path([...a, b >> 8, b & 0xFF]), 2,
        const ObservationOrigin.anonymous(),
        lastHopHeard: iHeardIt);
  }

  /// Known for a day: one link, 25 hours ago.
  void knownForADay(List<int> hop) {
    meetsNew(hop);
    nowMillis += 25 * hour;
  }

  /// New links at 0, 0, +30, +60, +60 min: five, over three half-hours.
  void steadyNovelty(List<int> hop,
      {bool iHeardThem = false, void Function()? between}) {
    for (final step in [0, 0, 30, 30, 0]) {
      nowMillis += step * minute;
      between?.call();
      meetsNew(hop, iHeardIt: iHeardThem);
    }
  }

  test('steady novelty from a repeater known for a day: watching only', () {
    knownForADay(whale);
    steadyNovelty(whale);
    final status = graph.movingStatus('C882')!;
    expect(status.reason, MovingReason.newLinks);
    expect(status.acts, isFalse);
    expect(signs, [('C882', MovingReason.newLinks)]);

    nowMillis += 10 * minute;
    meetsNew(whale);
    expect(signs, hasLength(1), reason: 'told once a day, not per link');
  });

  test('one burst is not enough', () {
    knownForADay(whale);
    for (var i = 0; i < 12; i++) {
      nowMillis += 20 * 1000;
      meetsNew(whale);
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

  test('switched on, a detector tag acts on routing', () {
    knownForADay(whale);
    steadyNovelty(whale);
    graph.updateConfig(graph.config.copyWith(mobileAutoTagsRoute: true));
    expect(graph.movingStatus('C882')!.acts, isTrue);
  });
}
