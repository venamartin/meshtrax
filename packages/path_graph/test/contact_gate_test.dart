import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const roomPk = 'c0' 'c0' 'c0';

const a277 = [0xA2, 0x77];
const f5ee = [0xF5, 0xEE];
const beef = [0xBE, 0xEF];

/// Field 2026-10-24 (indoors, Monterey Bay): F5EE heard the room and heard
/// this radio, the room did not hear F5EE. Four posts went out on F5EE and
/// none was answered; every flood that followed echoed via F5EE and reset
/// my own doorstep's failure count, so F5EE was tried again and again. The
/// contact's end now keeps its own count (owner, 2026-10-24).
void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;

  setUp(() async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
  });

  tearDown(() => graph.dispose());

  /// F5EE and A277 both hear me (proven). The room's reply came via F5EE
  /// (its doorstep, heard-only) and A277→BEEF is a known corridor to the
  /// room's other doorstep BEEF.
  void setupMesh() {
    graph.reportSendResult(path(f5ee), true);
    graph.reportSendResult(path(a277), true);
    for (final id in ['reply', 'post']) {
      graph.observePath(path(f5ee), 2,
          const ObservationOrigin.pubkeyConfirmed(roomPk),
          messageId: id);
    }
    graph.observePath(path([...a277, ...beef]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path(beef), 2,
        const ObservationOrigin.pubkeyConfirmed(roomPk),
        messageId: 'advert');
  }

  List<int> bytesOf(PathResult r) => (r as RouteResult).pathBytes;

  test('two failed deliveries through a doorstep stop routes ending there',
      () {
    setupMesh();
    expect(bytesOf(graph.findPath(roomPk)), f5ee, reason: 'one hop beats two');

    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    expect(bytesOf(graph.findPath(roomPk)), f5ee, reason: 'one failure is noise');
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef],
        reason: 'F5EE no longer ends routes to the room');
  });

  test('the flooded ACK of a delivery through the doorstep reopens it', () {
    setupMesh();
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef]);
    // My flood got through and its ACK came back via F5EE: a delivery.
    graph.observeContactSender(roomPk, path(f5ee), 2,
        confirmed: true, deliveredAck: true);
    final theirs = graph.ingressCandidates(roomPk)
        .firstWhere((c) => c.repeaterHash == 'F5EE');
    expect(graph.doorstepFailsThem(theirs), isFalse,
        reason: 'their end is open again (my own F5EE row keeps its D1 count)');
  });

  test('hearing them via the doorstep again does not reopen it', () {
    setupMesh();
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    // The room's next reply arrives via F5EE: proves room→F5EE, not F5EE→room.
    graph.observePath(path(f5ee), 2,
        const ObservationOrigin.pubkeyConfirmed(roomPk),
        messageId: 'reply-2');

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef]);
  });

  test('a delivery through the doorstep reopens it', () {
    setupMesh();
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), true, contactPubkey: roomPk);

    expect(bytesOf(graph.findPath(roomPk)), f5ee);
  });

  test('my own echoes resetting my doorstep do not reopen theirs', () {
    setupMesh();
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    // The flood rung's echo: F5EE heard me — true, and beside the point.
    graph.observeOwnEcho(path(f5ee), 2);

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef]);
  });

  test('with every doorstep failing the flood says so', () {
    graph.reportSendResult(path(f5ee), true);
    graph.reportSendResult(path(a277), true); // my end stays open
    graph.observePath(path(f5ee), 2,
        const ObservationOrigin.pubkeyConfirmed(roomPk),
        messageId: 'reply');
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);
    graph.reportSendResult(path(f5ee), false, contactPubkey: roomPk);

    expect((graph.findPath(roomPk) as FloodResult).reason,
        FloodReason.theirDoorstepsFailing);
  });

  test('a live PATH route ending at a failing doorstep steps aside', () {
    setupMesh();
    // The room's PATH reply names F5EE as the route my flood took: a live
    // route that leads for ten minutes, and one delivery proved through F5EE.
    graph.reportSendResult(path(f5ee), true, contactPubkey: roomPk, tally: false);
    expect(bytesOf(graph.findPath(roomPk)), f5ee);
    // Then two deliveries fail at F5EE, on routes other than the live one
    // (a failure on its exact hops drops it anyway) and from first hops
    // that leave my own doorsteps open.
    graph.reportSendResult(path([...a277, ...f5ee]), false, contactPubkey: roomPk);
    graph.reportSendResult(path([...beef, ...f5ee]), false, contactPubkey: roomPk);

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef],
        reason: 'the live route ends at a doorstep that fails them');
  });

  test('a failed splice charges neither end', () {
    setupMesh();
    graph.reportSendResult(path([...a277, ...f5ee]), false,
        contactPubkey: roomPk, guessedLinks: const [true]);
    graph.reportSendResult(path([...a277, ...f5ee]), false,
        contactPubkey: roomPk, guessedLinks: const [true]);

    expect(bytesOf(graph.findPath(roomPk)), f5ee,
        reason: 'guesses that fail say nothing about the doorsteps');
  });
}
