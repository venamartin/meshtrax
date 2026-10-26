import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

/// A route the firmware learned (a contact's out_path) proves both
/// doorsteps but says nothing about how good the corridor is: it is the
/// first flood copy to arrive, a race won on hop count.
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

  final firmwareRoute = path([0xA2, 0x77, 0x10, 0x00]);

  void learnFirmwareRoute() => graph.reportSendResult(firmwareRoute, true,
      contactPubkey: bobPk, stride: 2, tally: false);

  test('proves the doorsteps and marks the corridor seen, no tally', () {
    learnFirmwareRoute();
    final snap = graph.snapshot();
    final edge = snap.edges[('A277', '1000')]!;
    expect(edge.s, 0);
    expect(edge.n, 0);
    expect(edge.obsCount, 1);
    expect(snap.edges.containsKey(('1000', 'A277')), isFalse,
        reason: 'the return direction is never inferred');
    expect(graph.egressCandidates().map((c) => c.repeaterHash), ['A277']);
    expect(graph.ingressCandidates(bobPk).map((c) => c.repeaterHash), ['1000']);
  });

  test('a corridor known only from a firmware route is routable at prior quality',
      () {
    // The login that earned the route walked A277 -> 1000 in the sending
    // direction; that is the evidence a route needs (owner, 2026-10-13).
    learnFirmwareRoute();
    final result = graph.findPath(bobPk);
    expect(result, isA<RouteResult>());
    final route = result as RouteResult;
    expect(route.pathBytes, firmwareRoute);
    expect(route.hopProbabilities.single, closeTo(0.5, 0.05),
        reason: 'seen once, never tallied: the prior, not a measurement');
  });

  test('the return direction changes nothing for the route out', () {
    learnFirmwareRoute();
    final before = (graph.findPath(bobPk) as RouteResult).estDelivery;
    graph.observePath(path([0x10, 0x00, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    expect((graph.findPath(bobPk) as RouteResult).estDelivery,
        closeTo(before, 1e-6));
  });

  final longer = path([0xA2, 0x77, 0xA1, 0x77, 0x10, 0x00]);

  void deliverOnLonger() {
    for (var i = 0; i < 5; i++) {
      graph.reportSendResult(longer, true, contactPubkey: bobPk, stride: 2);
    }
    graph.observePath(path([0x10, 0x00, 0xA1, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path([0xA1, 0x77, 0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
  }

  Uint8List? best() => switch (graph.findPath(bobPk)) {
        RouteResult(:final pathBytes) => pathBytes,
        _ => null,
      };

  test('leads while live: the corridor a flood of mine just took to them',
      () {
    deliverOnLonger();
    learnFirmwareRoute();
    expect(best(), firmwareRoute);
    expect(graph.findAlternatives(bobPk).first.pathBytes, longer,
        reason: 'history still ranks everything after it');
  });

  test('loses to a corridor we have delivered on once it is no longer live',
      () {
    learnFirmwareRoute();
    deliverOnLonger();
    nowMillis += const Duration(minutes: 11).inMilliseconds;
    expect(best(), longer);
  });

  test('a failed send on the live route ends its lead at once', () {
    deliverOnLonger();
    learnFirmwareRoute();
    graph.reportSendResult(firmwareRoute, false,
        contactPubkey: bobPk, stride: 2);
    expect(best(), longer);
  });

  test('a newer PATH reply replaces the live route', () {
    deliverOnLonger();
    learnFirmwareRoute();
    nowMillis += 1000;
    graph.reportSendResult(longer, true,
        contactPubkey: bobPk, stride: 2, tally: false);
    expect(best(), longer);
    graph.reportSendResult(firmwareRoute, false,
        contactPubkey: bobPk, stride: 2);
    expect(best(), longer, reason: 'the old live route failing changes nothing');
  });

  test('the live route is priced like any other route', () {
    learnFirmwareRoute();
    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.estDelivery, greaterThan(0));
    expect(route.estDelivery, lessThan(1));
    expect(route.egressProven, isTrue);
    expect(route.ingressProven, isTrue);
  });

  // The screen says why it leads (owner, 2026-10-26: a lower % on top).
  test('the live route says how long ago the flood took it', () {
    deliverOnLonger();
    learnFirmwareRoute();
    nowMillis += const Duration(minutes: 4).inMilliseconds;
    final route = graph.findPath(bobPk) as RouteResult;
    expect(route.liveAgeMillis, const Duration(minutes: 4).inMilliseconds);
    expect(graph.findAlternatives(bobPk).map((r) => r.liveAgeMillis),
        everyElement(isNull));
    nowMillis += const Duration(minutes: 7).inMilliseconds;
    expect((graph.findPath(bobPk) as RouteResult).liveAgeMillis, isNull,
        reason: 'no longer live: it ranks like any other route');
  });
}
