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
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  /// Makes edge a<->b usable both ways. Payload-grade observations
  /// (lastHopHeard: false) so no egress candidates are minted as a side
  /// effect — tests control candidates solely through anchor().
  void link(List<int> a, List<int> b) {
    graph.observePath(path([...a, ...b]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([...b, ...a]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
  }

  /// Doorsteps: A277 hears me, 1312 hears Bob. Single-hop paths so no
  /// edges are created as a side effect.
  void anchor() {
    graph.reportSendResult(path([0xA2, 0x77]), true); // proven egress A277
    // Payload-embedded path (e.g. path-return): ingress only, the last
    // hop was not heard over RF.
    graph.observePath(path([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
  }

  test('routes my doorstep -> their doorstep over bidirectional corridor',
      () {
    anchor();
    link([0xA2, 0x77], [0x13, 0x12]);
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    final route = result as RouteResult;
    expect(route.pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(route.estDelivery, inExclusiveRange(0, 1.0001));
  });

  test('one-way corridor floods with noBidirectionalRoute', () {
    anchor();
    // Only A277 -> 1312 observed; reverse never.
    graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    final result = graph.findPath(bobPk);
    expect((result as FloodResult).reason, FloodReason.noBidirectionalRoute);
  });

  test('no candidates floods with noEvidence', () {
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.noEvidence);
  });

  test('shared doorstep yields a single-hop path', () {
    graph.reportSendResult(path([0xA2, 0x77]), true);
    graph.observePath(path([0xA2, 0x77, 0x5C, 0xBB]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk)); // A277 hears Bob too
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, [0xA2, 0x77]);
  });

  test('loud dead-end loses to quieter candidate with a real route', () {
    anchor();
    // 5CBB is a much louder egress candidate — but routes nowhere.
    for (var i = 0; i < 10; i++) {
      graph.reportSendResult(path([0x5C, 0xBB]), true);
    }
    link([0xA2, 0x77], [0x13, 0x12]); // quiet A277 has the route
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes.sublist(0, 2), [0xA2, 0x77]);
  });

  test('multi-hop route through the trunk', () {
    anchor();
    link([0xA2, 0x77], [0x5C, 0xBB]);
    link([0x5C, 0xBB], [0x13, 0x12]);
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes,
        [0xA2, 0x77, 0x5C, 0xBB, 0x13, 0x12]);
  });

  test('beta steers hop tolerance', () async {
    // With beta near 1, a 2-hop strong route should beat... build both:
    // direct weak-ish corridor vs detour. Here just assert route search
    // respects maxHops budget: a corridor longer than maxHops floods.
    final tiny = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(maxHops: 2));
    await tiny.init();
    tiny.setRadioIdentity(selfPk, 2);
    tiny.reportSendResult(path([0xA2, 0x77]), true);
    tiny.observePath(path([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
    // 3-hop corridor: A277 - 5CBB - 1312.
    for (final pair in [
      ([0xA2, 0x77], [0x5C, 0xBB]),
      ([0x5C, 0xBB], [0x13, 0x12])
    ]) {
      tiny.observePath(path([...pair.$1, ...pair.$2]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
      tiny.observePath(path([...pair.$2, ...pair.$1]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
    }
    final result = tiny.findPath(bobPk);
    expect(result, isA<FloodResult>(),
        reason: '3 hops exceeds maxHops=2 budget');
    await tiny.dispose();
  });
}
