import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// The firmware hashes only an attempt's low two bits into its ACK
// (BaseChatMesh::composeMsgPacket), so with Max Message Retries at 5 the
// first attempt (a route) and the fifth (a flood) share one ACK code. Which
// one an ACK was for shows in the ACK itself: a path reply answers the
// flooded copy, a plain ACK the routed one, and the receiver copies the
// attempt number above 3 into the ACK's fifth byte.

PathSelection _route(List<int> bytes) => PathSelection(
      pathBytes: bytes,
      hopCount: bytes.length ~/ 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.6,
    );

final _g1 = _route([0xA2, 0x77, 0x10, 0x00]);
final _g2 = _route([0xA2, 0x77, 0xBE, 0xEF]);
final _g3 = _route([0x2D, 0xF9, 0x10, 0x00]);
const _timeoutMs = 2000;

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

class _Rig {
  _Rig({this.graph = const []}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) {},
      setContactPath: (_, _, _, _) {},
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      graphRoutes: (_) => graph.isEmpty ? [_g1, _g2, _g3] : graph,
      onAttemptStarted: (_, sel, _) => routes.add(sel),
      onAttemptResult: (_, sel, delivered, _) => reported.add((
        route: sel.useFlood ? 'flood' : _hex(sel.pathBytes),
        delivered: delivered,
      )),
      onFloodAttemptEnded: (_, {required delivered}) {
        if (delivered) floodsDelivered++;
      },
    ));
    svc.setMaxRetries(5);
  }

  final List<PathSelection> graph;
  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  final sends = <({String text, int attempt, int ts})>[];
  final routes = <PathSelection>[];
  final reported = <({String route, bool delivered})>[];
  int floodsDelivered = 0;
  final svc = MessageRetryService();

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  /// Sends the DM and lets every attempt go out, the first four timing out.
  void sendAllFive(FakeAsync async, {String text = 'hi'}) {
    svc.sendMessageWithRetry(contact: _bob, text: text);
    async.flushMicrotasks();
    for (var i = 0; i < 5; i++) {
      svc.updateMessageFromSent(ackFor(i), 0, isFlood: routes[i].useFlood);
      if (i == 4) break;
      async.elapse(const Duration(
          milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 1));
      async.flushMicrotasks();
    }
  }

  List<String> get delivered =>
      [for (final r in reported) if (r.delivered) r.route];
}

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 21),
);

void main() {
  test('the first and fifth attempts share an ACK code', () {
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      expect(r.sends.map((s) => s.attempt), [0, 1, 2, 3, 4]);
      expect(r.routes.first.useFlood, isFalse);
      expect(r.routes.last.useFlood, isTrue);
      expect(r.ackFor(4), r.ackFor(0));
    });
  });

  test('a plain ACK was for the routed first attempt: its route is proven',
      () {
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      r.svc.handleAckReceived(r.ackFor(0), 9000, viaPathReply: false);
      async.flushMicrotasks();
      expect(r.delivered, [_hex(_g1.pathBytes)]);
      expect(r.floodsDelivered, 0);
    });
  });

  test('a path reply was for the flooded fifth attempt: no route proven', () {
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      r.svc.handleAckReceived(r.ackFor(0), 900, viaPathReply: true);
      async.flushMicrotasks();
      expect(r.delivered, isEmpty);
      expect(r.floodsDelivered, 1);
    });
  });

  test('the attempt byte alone tells them apart', () {
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      r.svc.handleAckReceived(r.ackFor(0), 900, wireAttempt: 4);
      async.flushMicrotasks();
      expect(r.delivered, isEmpty);
      expect(r.floodsDelivered, 1);
    });
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      r.svc.handleAckReceived(r.ackFor(0), 9000, wireAttempt: 0);
      async.flushMicrotasks();
      expect(r.delivered, [_hex(_g1.pathBytes)]);
    });
  });

  test('a send whose text fills its blocks is never ruled out by the byte',
      () {
    // Every attempt floods: the path reply can't tell them apart, only the
    // attempt byte can. At 11 bytes of text (5 + 11 = 16) the first
    // attempt's byte is whatever the receiver's stack held.
    final flood = PathSelection.flood(2);
    fakeAsync((async) {
      final r = _Rig(graph: [flood])..sendAllFive(async, text: 'hello world');
      expect(r.routes.every((s) => s.useFlood), isTrue);
      r.svc.handleAckReceived(r.ackFor(0), 900,
          viaPathReply: true, wireAttempt: 4);
      async.flushMicrotasks();
      expect(r.floodsDelivered, 0, reason: "can't tell which flood it was");
    });
    fakeAsync((async) {
      final r = _Rig(graph: [flood])..sendAllFive(async, text: 'hello');
      r.svc.handleAckReceived(r.ackFor(0), 900,
          viaPathReply: true, wireAttempt: 4);
      async.flushMicrotasks();
      expect(r.floodsDelivered, 1, reason: 'the byte names the fifth');
    });
  });

  test('an ACK the app did not see credits neither attempt', () {
    fakeAsync((async) {
      final r = _Rig()..sendAllFive(async);
      final failedBefore = r.reported.length;
      r.svc.handleAckReceived(r.ackFor(0), 900);
      async.flushMicrotasks();
      expect(r.delivered, isEmpty, reason: 'no route credited');
      expect(r.floodsDelivered, 0, reason: 'nor the flood');
      expect(r.reported.length, failedBefore,
          reason: 'and the first attempt is not failed a second time');
    });
  });
}
