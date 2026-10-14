import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Field finding 2026-10-14: GWQ (no GPS) learned A277 at home, moved 20
// miles to Aptos where 8802 heard it, and every DM still started at A277.
// My own end must forget by proof, without a position.

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

  Candidate? egress(String hash) =>
      graph.egressCandidates().where((c) => c.repeaterHash == hash).firstOrNull;

  void echo(List<int> firstHop) => graph.observeOwnEcho(path(firstHop), 2);

  // The raw feed files the same echo first: I heard its first hop, at a
  // level (the field order, frame_adapter).
  void heardEcho(List<int> firstHop, double rxSnr) {
    graph.observePath(path(firstHop), 2, const ObservationOrigin.anonymous(),
        rxSnr: rxSnr);
    echo(firstHop);
  }

  test('hearing a proven doorstep neither feeds nor refreshes "hears me"', () {
    echo([0xA2, 0x77]);
    final proven = egress('A277')!.weight;

    nowMillis += 90 * minute;
    graph.observePath(
        path([0x13, 0x12, 0xA2, 0x77]), 2, const ObservationOrigin.anonymous());

    final after = egress('A277')!;
    expect(after.weight, lessThan(proven * 0.75),
        reason: 'ages from the last proof, 90 minutes ago');
    expect(after.finalCount, 1, reason: 'the hearing is still counted');
  });

  test('my doorstep weight is capped', () {
    for (var i = 0; i < 50; i++) {
      echo([0xA2, 0x77]);
    }
    expect(egress('A277')!.weight, lessThanOrEqualTo(12));
  });

  test(
      'doorsteps that echo the same sends are never slashed, whatever the '
      'echo order', () {
    // Sends 20 minutes apart: every echo but the first finds the others
    // stale, and A277's always arrives first.
    for (var i = 0; i < 6; i++) {
      nowMillis += 20 * minute;
      echo([0xA2, 0x77]);
      nowMillis += 20 * 1000;
      echo([0xAD, 0x77]);
    }
    expect(egress('A277')!.weight, closeTo(12, 0.5));
    expect(egress('AD77')!.weight, closeTo(12, 0.5));
  });

  test(
      'after a quiet hour a send slashes only the doorstep that stayed '
      'silent, once', () {
    for (var i = 0; i < 4; i++) {
      echo([0xA2, 0x77]);
      echo([0xAD, 0x77]);
      echo([0x5B, 0x98]);
    }
    nowMillis += 60 * minute;
    echo([0xA2, 0x77]); // opens the epoch: AD77 and 5B98 are stale
    nowMillis += 30 * 1000;
    echo([0xBE, 0xEF]); // same epoch: no second slash
    nowMillis += 30 * 1000;
    echo([0xAD, 0x77]); // echoed this send too: slash undone

    expect(egress('A277')!.weight, closeTo(12, 0.1));
    expect(egress('AD77')!.weight, closeTo(12, 0.01));
    expect(egress('BEEF')!.weight, closeTo(3, 0.01));
    // 5B98: 12 × 0.5, aged an hour from its last proof.
    expect(egress('5B98')!.weight, lessThan(5));
  });

  test('a delivered direct send slashes nobody: it only tried one doorstep',
      () {
    echo([0xA2, 0x77]);
    echo([0xAD, 0x77]);
    nowMillis += 30 * minute;
    graph.reportSendResult(path([0xA2, 0x77, 0xAA, 0x77]), true,
        contactPubkey: bobPk);
    expect(egress('AD77')!.weight, greaterThan(2.5),
        reason: '3 aged half an hour from its proof, not halved');
  });

  test('a proven repeater I keep hearing stays in the routes-back list', () {
    // Review finding: proof weight is slashed and no longer fed by
    // hearing, so it must not rank the heard list.
    graph.observePath(
        path([0x13, 0x12, 0xBE, 0xEF]), 2, const ObservationOrigin.anonymous());
    graph.observeTrace(['BEEF'], [5.0]);
    nowMillis += 16 * minute;
    for (var i = 0; i < 10; i++) {
      graph.observePath(path([0x13, 0x12, 0xBE, 0xEF]), 2,
          const ObservationOrigin.anonymous());
      echo([0xA2, 0x77]);
      nowMillis += 3 * minute;
    }
    expect(graph.findReturnPathFromRepeater('1312'), isA<RouteResult>());
  });

  test('moving away hands the route to the doorstep that hears me now', () {
    // Home: A277 traced at 11.9 dB with a measured link to AA77, and a
    // delivered DM proves AA77 reaches Bob.
    for (var i = 0; i < 10; i++) {
      graph.observeTrace(['A277', 'AA77'], [11.9, 11.75, 11.0]);
      graph.reportSendResult(path([0xA2, 0x77, 0xAA, 0x77]), true,
          contactPubkey: bobPk);
    }
    // 8802's corridor to AA77 is two links only ever overheard.
    graph.observePath(path([0x88, 0x02, 0xEC, 0x34, 0xAA, 0x77]), 2,
        const ObservationOrigin.anonymous());

    String firstHop() {
      final r = graph.findPath(bobPk) as RouteResult;
      final b = r.pathBytes;
      return [for (final x in b.take(2)) x.toRadixString(16).padLeft(2, '0')]
          .join();
    }

    expect(firstHop(), 'a277');

    // An hour later, 20 miles away: 8802 echoes my sends, A277 is silent.
    nowMillis += 60 * minute;
    heardEcho([0x88, 0x02], 9.7);
    expect(firstHop(), 'a277',
        reason: 'one echo is not yet a move: the measured corridor wins');

    nowMillis += 3 * minute;
    heardEcho([0x88, 0x02], 9.7);
    nowMillis += 3 * minute;
    heardEcho([0x88, 0x02], 9.7);
    expect(firstHop(), '8802',
        reason: 'A277 has proved nothing for an hour while 8802 keeps proving');
    expect(graph.egressCandidates().first.repeaterHash, '8802');
  });
}
