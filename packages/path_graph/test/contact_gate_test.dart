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
///
/// What counts (owner, 2026-11-24: one missed ACK is no reason to drop a
/// learned route): not a missed ACK by itself, which two radios sending at
/// once explains as well, but a miss through the doorstep followed by a
/// delivery that came another way. Twice in a row, and it stops ending
/// routes.
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

  /// F5EE and A277 both hear me (proven). The room's advert came via BEEF,
  /// its replies since via F5EE (its doorstep now, heard-only, BEEF left
  /// as a fallback), and A277→BEEF is a known corridor to BEEF.
  void setupMesh() {
    graph.reportSendResult(path(f5ee), true);
    graph.reportSendResult(path(a277), true);
    graph.observePath(path([...a277, ...beef]), 2,
        const ObservationOrigin.anonymous(), lastHopHeard: false);
    graph.observePath(path(beef), 2,
        const ObservationOrigin.pubkeyConfirmed(roomPk),
        messageId: 'advert');
    for (final id in ['reply', 'post']) {
      graph.observePath(path(f5ee), 2,
          const ObservationOrigin.pubkeyConfirmed(roomPk),
          messageId: id);
    }
  }

  List<int> bytesOf(PathResult r) => (r as RouteResult).pathBytes;

  /// A post went out on [route], F5EE was heard passing it on (so my own
  /// end is not in question), and no ACK came.
  void missed([List<int> route = f5ee]) => graph.reportSendResult(
      path(route), false,
      contactPubkey: roomPk, hopsHeard: 1);

  /// Twice a post missed through F5EE and then got through as a flood (a
  /// room sends no path reply, so by a way nobody named).
  void holdF5ee() {
    for (var i = 0; i < 2; i++) {
      missed();
      graph.reportFloodDelivered(roomPk);
    }
  }

  test('missed ACKs alone stop nothing', () {
    setupMesh();
    expect(bytesOf(graph.findPath(roomPk)), f5ee, reason: 'one hop beats two');
    for (var i = 0; i < 4; i++) {
      missed();
    }
    expect(bytesOf(graph.findPath(roomPk)), f5ee);
  });

  test('twice a miss through a doorstep and then a delivery another way: '
      'routes stop ending there', () {
    setupMesh();
    missed();
    missed();
    graph.reportFloodDelivered(roomPk);
    expect(bytesOf(graph.findPath(roomPk)), f5ee,
        reason: 'once is chance, however many tries missed');
    missed();
    graph.reportFloodDelivered(roomPk);

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef],
        reason: 'F5EE no longer ends routes to the room');
  });

  test('a delivery on a route ending elsewhere counts like the flood', () {
    setupMesh();
    for (var i = 0; i < 2; i++) {
      missed();
      graph.reportSendResult(path([...a277, ...beef]), true,
          contactPubkey: roomPk);
    }
    final theirs = graph.ingressCandidates(roomPk)
        .firstWhere((c) => c.repeaterHash == 'F5EE');
    expect(graph.doorstepFailsThem(theirs), isTrue);
  });

  test('a flood that got through by the same doorstep clears it: the '
      'misses were chance', () {
    setupMesh();
    missed();
    graph.reportFloodDelivered(roomPk);
    missed();
    missed();
    // Their path reply names the way the flood took: it ended at F5EE.
    graph.reportSendResult(path(f5ee), true,
        contactPubkey: roomPk, tally: false);
    graph.reportFloodDelivered(roomPk);
    final theirs = graph.ingressCandidates(roomPk)
        .firstWhere((c) => c.repeaterHash == 'F5EE');
    expect(theirs.failedSinceProof, 0);
    expect(bytesOf(graph.findPath(roomPk)), f5ee);
  });

  test('a packet that never left my own doorstep says nothing about '
      'theirs', () {
    setupMesh();
    for (var i = 0; i < 2; i++) {
      graph.reportSendResult(path([...a277, ...f5ee]), false,
          contactPubkey: roomPk, hopsHeard: 0);
      graph.reportFloodDelivered(roomPk);
    }
    final theirs = graph.ingressCandidates(roomPk)
        .firstWhere((c) => c.repeaterHash == 'F5EE');
    expect(theirs.failedSinceProof, 0);
  });

  test('a miss from long before the delivery is not held against it', () {
    setupMesh();
    for (var i = 0; i < 2; i++) {
      missed();
      nowMillis += 16 * 60 * 1000;
      graph.reportFloodDelivered(roomPk);
    }
    final theirs = graph.ingressCandidates(roomPk)
        .firstWhere((c) => c.repeaterHash == 'F5EE');
    expect(theirs.failedSinceProof, 0);
  });

  test('the flooded ACK of a delivery through the doorstep reopens it', () {
    setupMesh();
    holdF5ee();
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
    holdF5ee();
    // The room's next reply arrives via F5EE: proves room→F5EE, not F5EE→room.
    graph.observePath(path(f5ee), 2,
        const ObservationOrigin.pubkeyConfirmed(roomPk),
        messageId: 'reply-2');

    expect(bytesOf(graph.findPath(roomPk)), [...a277, ...beef]);
  });

  test('a delivery through the doorstep reopens it', () {
    setupMesh();
    holdF5ee();
    graph.reportSendResult(path(f5ee), true, contactPubkey: roomPk);

    expect(bytesOf(graph.findPath(roomPk)), f5ee);
  });

  test('my own echoes resetting my doorstep do not reopen theirs', () {
    setupMesh();
    holdF5ee();
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
    holdF5ee();

    expect((graph.findPath(roomPk) as FloodResult).reason,
        FloodReason.theirDoorstepsFailing);
  });

  test('a live PATH route ending at a failing doorstep steps aside', () {
    setupMesh();
    // The room's PATH reply names F5EE as the route my flood took: a live
    // route that leads for ten minutes, and one delivery proved through F5EE.
    graph.reportSendResult(path(f5ee), true, contactPubkey: roomPk, tally: false);
    expect(bytesOf(graph.findPath(roomPk)), f5ee);
    // Then twice a post misses at F5EE and gets through as a flood, on
    // routes other than the live one (a failure on its exact hops drops
    // it anyway).
    missed([...a277, ...f5ee]);
    graph.reportFloodDelivered(roomPk);
    missed([...beef, ...f5ee]);
    graph.reportFloodDelivered(roomPk);

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
