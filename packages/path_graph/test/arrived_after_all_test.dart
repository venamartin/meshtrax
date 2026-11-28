import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';

const a277 = [0xA2, 0x77];
const ad77 = [0xAD, 0x77];
const beef = [0xBE, 0xEF];

/// Owner, 2026-11-28: "get our ACK data to properly improve the graph and
/// not let valuable data go to waste". MeshTrax's ACK lists the tries of a
/// message that arrived. A try whose own ACK was lost was counted as a
/// failed send; the ACK of a later try says it arrived.
void main() {
  late PathGraph graph;
  const nowMillis = 1000000000;
  final route = path([...a277, ...ad77, ...beef]);

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.reportSendResult(path(a277), true);
    for (var i = 0; i < 30; i++) {
      graph.observePath(route, 2, const ObservationOrigin.pubkeyConfirmed(bobPk),
          messageId: 'bob-$i', lastHopHeard: false);
    }
  });

  tearDown(() => graph.dispose());

  EdgeState link(String from, String to) => graph.snapshot().edges[(from, to)]!;
  double rating(String from, String to) =>
      graph.estimator.calibratedP(link(from, to), nowMillis);
  Candidate mine() =>
      graph.egressCandidates().firstWhere((c) => c.repeaterHash == 'A277');

  test('the failure is taken back and the send is a delivery', () {
    final before = rating('A277', 'AD77');
    graph.reportSendResult(route, false, contactPubkey: bobPk);
    expect(rating('A277', 'AD77'), lessThan(before));
    expect(mine().failedSinceProof, 1);

    graph.reportArrivedAfterAll(route, contactPubkey: bobPk);
    for (final (from, to) in [('A277', 'AD77'), ('AD77', 'BEEF')]) {
      final e = link(from, to);
      expect(e.failuresAt(nowMillis, 24), 0, reason: '$from>$to');
      expect(e.s, 1, reason: '$from>$to');
      expect(e.n, 1, reason: 'one send, counted once');
    }
    expect(rating('A277', 'AD77'), greaterThan(before));
    expect(mine().failedSinceProof, 0);
    final theirs = graph
        .ingressCandidates(bobPk)
        .firstWhere((c) => c.repeaterHash == 'BEEF');
    expect(theirs.proven, isTrue);
  });

  test('a failure of another send stays', () {
    graph.reportSendResult(route, false, contactPubkey: bobPk);
    graph.reportSendResult(route, false, contactPubkey: bobPk);
    graph.reportArrivedAfterAll(route, contactPubkey: bobPk);
    expect(link('A277', 'AD77').failuresAt(nowMillis, 24), 1);
    expect(link('A277', 'AD77').s, 1);
  });

  test('a link heard passing it on was credited then, and is not twice', () {
    // Heard as far as AD77: A277>AD77 carried it, AD77>BEEF was in doubt.
    graph.reportSendResult(route, false, contactPubkey: bobPk, hopsHeard: 2);
    expect(link('A277', 'AD77').s, 1);
    graph.reportArrivedAfterAll(route, contactPubkey: bobPk, hopsHeard: 2);
    expect(link('A277', 'AD77').s, 1);
    expect(link('AD77', 'BEEF').s, 1);
    expect(link('AD77', 'BEEF').failuresAt(nowMillis, 24), 0);
  });

  test('the missed end is not held against their doorstep at the next '
      'delivery', () {
    graph.reportSendResult(route, false, contactPubkey: bobPk);
    graph.reportArrivedAfterAll(route, contactPubkey: bobPk);
    // A delivery another way would have settled the miss against BEEF.
    graph.reportSendResult(path([...a277, ...ad77]), true,
        contactPubkey: bobPk);
    final theirs = graph
        .ingressCandidates(bobPk)
        .firstWhere((c) => c.repeaterHash == 'BEEF');
    expect(theirs.failedSinceProof, 0);
  });
}
