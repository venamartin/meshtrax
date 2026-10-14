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

  test('traced corridor routes as soon as the far doorstep is heard', () {
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 8.0, 8.0]);
    // Hearing the contact through 1312 is enough: it heard them, so it
    // reaches them, and the traced corridor carries the route.
    graph.observePath(
        Uint8List.fromList([0x13, 0x12]), 2,
        const ObservationOrigin.pubkeyConfirmed('b0' 'b0'),
        lastHopHeard: false);
    final result = graph.findPath('b0' 'b0');
    expect(result, isA<RouteResult>());
    expect((result as RouteResult).pathBytes, [0xA2, 0x77, 0x13, 0x12]);
    expect(result.ingressProven, isFalse);
    expect(result.hopProbabilities.single, greaterThan(0.7),
        reason: 'measured 8 dB');
    // A delivered send through it upgrades the end to proven; same route.
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true,
        contactPubkey: 'b0' 'b0');
    final after = graph.findPath('b0' 'b0') as RouteResult;
    expect(after.pathBytes, result.pathBytes);
    expect(after.ingressProven, isTrue);
  });

  test('a round trip measures my doorstep both ways', () {
    // Firmware appends how I heard the last hop: four levels for three hops.
    graph.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, 7.0, 8.5]);
    final a277 = graph.egressCandidates().single;
    expect(a277.proven, isTrue);
    expect(a277.uplinkSnr, 9.0, reason: 'A277 heard me at 9 dB');
    expect(a277.downlinkSnr, 8.5, reason: 'I heard A277 at 8.5 dB');

    graph.observeTrace(['A277', '1312', 'A277'], [4.0, 6.5, 7.0, 3.5]);
    final again = graph.egressCandidates().single;
    expect(again.uplinkSnr, closeTo(7.0, 1e-9)); // 9*0.6 + 4*0.4
    expect(again.downlinkSnr, closeTo(6.5, 1e-9)); // 8.5*0.6 + 3.5*0.4
  });

  test('a one-way trace hears its last hop directly', () {
    graph.observeTrace(['A277', '5CBB'], [9.0, 3.0, -4.0]);
    final byHash = {
      for (final c in graph.egressCandidates()) c.repeaterHash: c
    };
    expect(byHash['A277']!.proven, isTrue);
    expect(byHash['5CBB']!.proven, isFalse,
        reason: 'I heard 5CBB; nothing says it hears me');
    expect(byHash['5CBB']!.heard, isTrue);
    expect(byHash['5CBB']!.downlinkSnr, -4.0);
  });

  test('repeat traces refine SNR by EWMA', () {
    graph.observeTrace(['A277', '1312'], [9.0, 10.0]);
    graph.observeTrace(['A277', '1312'], [9.0, 0.0]);
    final snr = graph.snapshot().edges[('A277', '1312')]!.measuredSnr!;
    expect(snr, closeTo(6.0, 1e-9)); // 10*0.6 + 0*0.4
    expect(graph.snapshot().edges[('A277', '1312')]!.n, 2);
  });
}
