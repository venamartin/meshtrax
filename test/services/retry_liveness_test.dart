import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Drive 2026-10-17: 29 of 77 DMs were heard by no repeater and burned the
// whole ladder before showing "failed". A flood nobody echoes is parked
// with "No repeater heard you" and sent again when a repeater is heard.

const _timeoutMs = 20000;
const _airtimeMs = 564;
final _echoWait = TimeoutHelper.echoWaitMs(_airtimeMs, _timeoutMs);

class _Rig {
  _Rig({required int budget, List<PathSelection>? graph}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, m) => added.add(m),
      updateMessage: (m) => updates.add(m),
      clearContactPath: (_) {},
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      estimateAirtime: (_) => _airtimeMs,
      graphRoutes: graph == null ? null : (_) => graph,
    ));
    svc.setMaxRetries(budget);
  }

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  final sends = <({String text, int attempt, int ts})>[];
  final added = <Message>[];
  final updates = <Message>[];
  final svc = MessageRetryService();

  Message get last => updates.last;

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
  test('a flood nobody echoes is parked: status sent, waiting for a repeater',
      () {
    fakeAsync((async) {
      final r = _Rig(budget: 3, graph: const []); // Pathfinder: every rung floods
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      expect(r.svc.hasMessagesInFlight, isTrue);

      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isTrue);
      expect(r.last.status, MessageStatus.sent);
      expect(r.svc.isSendingTo(_bob.publicKeyHex), isTrue,
          reason: 'the ladder still owns the route');
      expect(r.svc.hasMessagesInFlight, isFalse,
          reason: 'nothing is on the air for it');

      async.elapse(const Duration(milliseconds: _timeoutMs));
      expect(r.sends, hasLength(1), reason: 'no ladder timeout while parked');
      expect(r.last.status, MessageStatus.sent);
    });
  });

  test('a repeater\'s copy of my flood keeps the normal ACK wait', () {
    fakeAsync((async) {
      final r = _Rig(budget: 3, graph: const []);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(const Duration(seconds: 3));
      r.svc.noteOwnFloodEcho(_bob.publicKey[0]);
      async.elapse(Duration(milliseconds: _echoWait));
      expect(r.last.waitingForRepeater, isFalse);

      async.elapse(const Duration(milliseconds: _timeoutMs));
      async.flushMicrotasks();
      expect(r.sends, hasLength(2), reason: 'the ladder timed out as usual');
    });
  });

  test('an echo for another contact changes nothing', () {
    fakeAsync((async) {
      final r = _Rig(budget: 3, graph: const []);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      r.svc.noteOwnFloodEcho(_bob.publicKey[0] ^ 0xFF);
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isTrue);
    });
  });

  test('a repeater heard after the cooldown sends it again, three times at '
      'most, then the ladder moves on', () {
    fakeAsync((async) {
      final r = _Rig(budget: 2, graph: const []);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isTrue);

      r.svc.noteRepeaterHeard();
      async.flushMicrotasks();
      expect(r.sends, hasLength(1), reason: 'inside the cooldown: nothing');

      for (var resend = 1; resend <= MessageRetryService.maxAutoResends; resend++) {
        async.elapse(const Duration(
            milliseconds: MessageRetryService.repeaterCooldownMs + 1));
        r.svc.noteRepeaterHeard();
        async.flushMicrotasks();
        expect(r.sends, hasLength(1 + resend));
        expect(r.sends.last.attempt, 0, reason: 'the same rung, same ACK');
        r.sentLast();
        async.elapse(Duration(milliseconds: _echoWait + 1));
        expect(r.last.waitingForRepeater, isTrue);
      }

      // The cap is reached: the next repeater moves the ladder on (rung 2).
      async.elapse(const Duration(
          milliseconds: MessageRetryService.repeaterCooldownMs + 1));
      r.svc.noteRepeaterHeard();
      async.elapse(const Duration(
          milliseconds: MessageRetryService.retryBackoffMs + 1));
      async.flushMicrotasks();
      expect(r.sends.last.attempt, 1);
    });
  });

  test('an ACK while parked delivers it', () {
    fakeAsync((async) {
      final r = _Rig(budget: 3, graph: const []);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isTrue);

      r.svc.handleAckReceived(r.ackFor(0), 4000);
      async.flushMicrotasks();
      expect(r.last.status, MessageStatus.delivered);
      expect(r.last.waitingForRepeater, isFalse);
    });
  });

  test('a later message to the same contact waits behind a parked one', () {
    fakeAsync((async) {
      final r = _Rig(budget: 3, graph: const []);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      async.flushMicrotasks();
      r.sentLast();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
      async.flushMicrotasks();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.sends.map((s) => s.text), ['one']);
      expect(
          r.svc.isQueued(
              r.added.firstWhere((m) => m.text == 'two').messageId),
          isTrue);
    });
  });

  test('a route attempt and a near-max text never arm the watch', () {
    fakeAsync((async) {
      final route = PathSelection(
          pathBytes: const [0xA2, 0x77],
          hopCount: 1,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: 0.9);
      final r = _Rig(budget: 3, graph: [route]);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isFalse, reason: 'a route, not a flood');

      final r2 = _Rig(budget: 3, graph: const []);
      r2.svc.sendMessageWithRetry(contact: _bob, text: 'a' * 158);
      async.flushMicrotasks();
      r2.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r2.last.waitingForRepeater, isFalse,
          reason: 'its echo could never reach the raw log');
    });
  });
}
