import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Field 2026-10-17: a failed route attempt was reported to Pathfinder only
// when the message ended, and the ladder was planned once, so rungs 2 and
// 3 repeated rung 1's stale first hop. Each timeout is reported at once
// and the remaining rungs are re-planned.

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
  _Rig({required int budget}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) {},
      setContactPath: (_, bytes, _, _) => written.add(_hex(bytes)),
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      graphRoutes: (_) {
        planned++;
        return graph;
      },
      onAttemptResult: (_, sel, delivered, _) => reported.add((
        route: sel.useFlood ? 'flood' : _hex(sel.pathBytes),
        delivered: delivered,
      )),
    ));
    svc.setMaxRetries(budget);
  }

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  List<PathSelection> graph = [_g1, _g2];
  int planned = 0;
  final sends = <({String text, int attempt, int ts})>[];
  final written = <String>[];
  final reported = <({String route, bool delivered})>[];
  final svc = MessageRetryService();

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  void sentLast() => svc.updateMessageFromSent(ackFor(sends.length - 1), 0);
}

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 10, 17),
);

void main() {
  test('a timed-out route attempt is reported before the retry goes out', () {
    fakeAsync((async) {
      final r = _Rig(budget: 4);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      expect(r.written, [_hex(_g1.pathBytes)]);

      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(r.reported, [(route: _hex(_g1.pathBytes), delivered: false)],
          reason: 'reported at the timeout, during the backoff');
      expect(r.sends, hasLength(1), reason: 'the retry has not gone out yet');
    });
  });

  test('the remaining rungs are re-planned from what the failure taught', () {
    fakeAsync((async) {
      final r = _Rig(budget: 4);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      final plansBefore = r.planned;

      // Pathfinder, told of the failure, now ranks a route from another
      // doorstep first.
      r.graph = [_g3];
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(r.planned, greaterThan(plansBefore), reason: 're-planned');
      async.elapse(const Duration(milliseconds: MessageRetryService.retryBackoffMs));
      async.flushMicrotasks();
      expect(r.written.last, _hex(_g3.pathBytes),
          reason: 'rung 2 follows the new ranking, not the old plan');
      expect(r.sends, hasLength(2));
    });
  });

  test('a late ACK for a reported attempt adds a delivery, not a second failure',
      () {
    fakeAsync((async) {
      final r = _Rig(budget: 4);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(r.reported, hasLength(1));

      r.svc.handleAckReceived(r.ackFor(0), 9000);
      async.flushMicrotasks();
      expect(r.reported, [
        (route: _hex(_g1.pathBytes), delivered: false),
        (route: _hex(_g1.pathBytes), delivered: true),
      ]);
    });
  });

  test('a failed message reports each timed-out attempt exactly once', () {
    fakeAsync((async) {
      final r = _Rig(budget: 2); // one route, one flood
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(const Duration(
          milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 1));
      async.flushMicrotasks();
      r.sentLast(); // the flood
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      async.elapse(MessageRetryService.lateAckGrace);
      expect(r.reported, [(route: _hex(_g1.pathBytes), delivered: false)],
          reason: 'floods are never reported; the route once');
    });
  });
}
