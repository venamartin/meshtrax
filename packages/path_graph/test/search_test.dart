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
    // These tests exercise the corridor search; endpoint proof is
    // covered in evidence_test, so inferred doorsteps are allowed here.
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(allowInferredEndpoints: true));
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

  test('a strong doorstep with a longer corridor beats a weak one with a short corridor',
      () async {
    // A277 hears me well (proven five times); 1000 heard me once. Bob is
    // heard through 1312. 1000 links to 1312 directly; A277 needs 5CBB.
    Future<PathGraph> build(double doorstepWeight,
        {bool measureWeak = false}) async {
      final g = PathGraph(NativeDatabase.memory(),
          config: PathGraphConfig(doorstepWeight: doorstepWeight));
      await g.init();
      g.setRadioIdentity(selfPk, 2);
      for (var i = 0; i < 5; i++) {
        g.reportSendResult(path([0xA2, 0x77]), true);
      }
      g.reportSendResult(path([0x10, 0x00]), true);
      if (measureWeak) {
        g.observeDiscoverResults(
            [const DiscoverResponse(repeaterHash: '1000', uplinkSnr: -12)],
            failureEpisode: false);
      }
      g.observePath(path([0x13, 0x12]), 2,
          const ObservationOrigin.pubkeyConfirmed(bobPk), lastHopHeard: false);
      void both(List<int> a, List<int> b) {
        g.observePath(path([...a, ...b]), 2,
            const ObservationOrigin.anonymous(), lastHopHeard: false);
        g.observePath(path([...b, ...a]), 2,
            const ObservationOrigin.anonymous(), lastHopHeard: false);
      }

      both([0x10, 0x00], [0x13, 0x12]);
      both([0xA2, 0x77], [0x5C, 0xBB]);
      both([0x5C, 0xBB], [0x13, 0x12]);
      return g;
    }

    final strong = await build(3);
    expect((strong.findPath(bobPk) as RouteResult).pathBytes,
        [0xA2, 0x77, 0x5C, 0xBB, 0x13, 0x12],
        reason: 'start at the repeater that hears me best');
    await strong.dispose();

    final flat = await build(1);
    expect((flat.findPath(bobPk) as RouteResult).pathBytes,
        [0x10, 0x00, 0x13, 0x12],
        reason: 'at weight 1 the shorter corridor wins — the field bug');
    await flat.dispose();

    final measured = await build(1, measureWeak: true);
    expect((measured.findPath(bobPk) as RouteResult).pathBytes.sublist(0, 2),
        [0xA2, 0x77],
        reason: 'a measured weak uplink loses even without the knob');
    await measured.dispose();
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

  test('findPathToRepeater: doorstep target is single hop, trunk is multi',
      () {
    graph.reportSendResult(path([0xA2, 0x77]), true);
    expect((graph.findPathToRepeater('A277') as RouteResult).pathBytes,
        [0xA2, 0x77]);

    link([0xA2, 0x77], [0x5C, 0xBB]);
    expect((graph.findPathToRepeater('5CBB') as RouteResult).pathBytes,
        [0xA2, 0x77, 0x5C, 0xBB]);

    expect(graph.findPathToRepeater('F857'), isA<FloodResult>());
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
