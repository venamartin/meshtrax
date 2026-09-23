import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const selfPk = 'ab' 'ab' 'ab';

void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  test('one-way trace sets measured SNR forward and proves egress', () {
    graph.observeTrace(['A277', '1312', '5CBB'], [9.0, 6.5, -2.0]);
    final snap = graph.snapshot();
    expect(snap.edges[('A277', '1312')]!.measuredSnr, 6.5);
    expect(snap.edges[('1312', '5CBB')]!.measuredSnr, -2.0);
    expect(snap.edges.containsKey(('1312', 'A277')), isFalse);
    expect(graph.egressCandidates().single.repeaterHash, 'A277');
    expect(graph.egressCandidates().single.tier, EvidenceTier.proven);
  });

  test('round-trip trace fills both directions', () {
    // Out and back: me -> A277 -> 1312 -> A277
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, 7.0]);
    final snap = graph.snapshot();
    expect(snap.edges[('A277', '1312')]!.measuredSnr, 6.5);
    expect(snap.edges[('1312', 'A277')]!.measuredSnr, 7.0);
  });

  test('traced corridor routes once the far doorstep is proven', () {
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 8.0, 8.0]);
    // Hearing the contact through 1312 only guesses their doorstep…
    graph.observePath(
        Uint8List.fromList([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed('b0' 'b0'),
        lastHopHeard: false);
    expect((graph.findPath('b0' 'b0') as FloodResult).reason,
        FloodReason.noProvenEndpoint);
    // …a delivered send through it proves it, and the traced corridor
    // carries the route.
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: 'b0' 'b0');
    final result = graph.findPath('b0' 'b0');
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(result.hopProbabilities.single, greaterThan(0.8),
        reason: 'measured 8 dB plus a delivery');
  });

  test('repeat traces refine SNR by EWMA', () {
    graph.observeTrace(['A277', '1312'], [9.0, 10.0]);
    graph.observeTrace(['A277', '1312'], [9.0, 0.0]);
    final snr = graph.snapshot().edges[('A277', '1312')]!.measuredSnr!;
    expect(snr, closeTo(6.0, 1e-9)); // 10*0.6 + 0*0.4
    expect(graph.snapshot().edges[('A277', '1312')]!.n, 2);
  });
}
