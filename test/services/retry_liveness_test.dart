import 'dart:async';
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
// Fail fast (Martin, 2026-11-16): it parks only when a repeater was heard
// in the last 10 minutes, and a park that hears none for 10 minutes fails,
// so the messages queued behind it to the same contact can go.

const _timeoutMs = 20000;
const _airtimeMs = 564;
final _echoWait = TimeoutHelper.echoWaitMs(_airtimeMs, _timeoutMs);

class _Rig {
  _Rig(FakeAsync async,
      {required int budget,
      List<PathSelection>? graph,
      this.routeWriteThrows})
      : svc = MessageRetryService(
            clock: () => DateTime(2026, 11, 16).add(async.elapsed)) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      sendOnRoute: routeWriteThrows == null
          ? null
          : (_, _, send) async {
              routeWrites++;
              if (routeWriteThrows!(routeWrites)) {
                throw StateError('BLE write failed');
              }
              await send();
            },
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
  final MessageRetryService svc;
  // Which route write (1 = the first send's) fails, as a radio write can.
  final bool Function(int write)? routeWriteThrows;
  int routeWrites = 0;

  Message get last => updates.last;
  Message lastOf(String text) => updates.lastWhere((m) => m.text == text);

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
  test('a flood nobody echoes is parked when a repeater was heard lately: '
      'status sent, waiting for a repeater', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 3, graph: const []); // Pathfinder: every rung floods
      r.svc.noteRepeaterHeard(); // a moment ago
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
      final r = _Rig(async, budget: 3, graph: const []);
      r.svc.noteRepeaterHeard();
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
      final r = _Rig(async, budget: 3, graph: const []);
      r.svc.noteRepeaterHeard();
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
      final r = _Rig(async, budget: 2, graph: const []);
      r.svc.noteRepeaterHeard();
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
        expect(r.sends.last.attempt, 4 * resend,
            reason: 'a new packet: a radio drops one it has heard');
        expect(r.ackFor(r.sends.length - 1), r.ackFor(0),
            reason: 'the same rung, same ACK');
        expect(r.last.waitingForRepeater, isFalse,
            reason: 'sent again: the line goes');
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

  void parkThenResend(_Rig r, FakeAsync async, String text) {
    r.svc.noteRepeaterHeard();
    r.svc.sendMessageWithRetry(contact: _bob, text: text);
    async.flushMicrotasks();
    r.sentLast();
    async.elapse(Duration(milliseconds: _echoWait + 1));
    expect(r.last.waitingForRepeater, isTrue);
    async.elapse(
        const Duration(milliseconds: MessageRetryService.repeaterCooldownMs + 1));
    r.svc.noteRepeaterHeard();
    async.flushMicrotasks();
  }

  test('a resend never takes the number a later rung goes out with', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 5, graph: const []);
      parkThenResend(r, async, 'hi');
      expect(r.sends.map((s) => s.attempt), [0, 8],
          reason: 'attempt 4 is the fifth rung\'s');
    });
  });

  test('an ACK to a resend delivers the message on the rung it repeats', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 3, graph: const []);
      parkThenResend(r, async, 'hi');
      r.sentLast();
      r.svc.handleAckReceived(r.ackFor(1), 4000);
      async.flushMicrotasks();
      expect(r.last.status, MessageStatus.delivered);
      expect(r.last.retryCount, 0);
    });
  });

  test('a resend whose longer packet could not echo visibly is not parked '
      'again', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 2, graph: const []);
      // 154 bytes: seen at attempt 0, but the attempt number's two extra
      // bytes take the packet past what the raw log carries.
      parkThenResend(r, async, 'a' * 154);
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isFalse);
      async.elapse(const Duration(
          milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 1));
      async.flushMicrotasks();
      expect(r.sends.last.attempt, 1, reason: 'the ladder moved on');
    });
  });

  test('an ACK while parked delivers it, and the park limit stays quiet', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 3, graph: const []);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isTrue);

      r.svc.handleAckReceived(r.ackFor(0), 4000);
      async.flushMicrotasks();
      expect(r.last.status, MessageStatus.delivered);
      expect(r.last.waitingForRepeater, isFalse);

      final updates = r.updates.length;
      async.elapse(MessageRetryService.parkLimit * 2);
      expect(r.updates, hasLength(updates), reason: 'no timer left behind');
      expect(r.sends, hasLength(1));
    });
  });

  test('a later message to the same contact waits behind a parked one, and '
      'goes once it is delivered', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 3, graph: const []);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      async.flushMicrotasks();
      r.sentLast();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
      async.flushMicrotasks();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.lastOf('one').waitingForRepeater, isTrue, reason: 'parked');

      async.elapse(const Duration(minutes: 5));
      final two = r.added.firstWhere((m) => m.text == 'two').messageId;
      expect(r.sends.map((s) => s.text), ['one']);
      expect(r.svc.isQueued(two), isTrue);

      r.svc.handleAckReceived(r.ackFor(0), 4000);
      async.flushMicrotasks();
      expect(r.lastOf('one').status, MessageStatus.delivered);
      expect(r.sends.map((s) => s.text), ['one', 'two']);
      expect(r.svc.isQueued(two), isFalse);
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
      final r = _Rig(async, budget: 3, graph: [route]);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r.last.waitingForRepeater, isFalse, reason: 'a route, not a flood');

      final r2 = _Rig(async, budget: 3, graph: const []);
      r2.svc.noteRepeaterHeard();
      r2.svc.sendMessageWithRetry(contact: _bob, text: 'a' * 158);
      async.flushMicrotasks();
      r2.sentLast();
      async.elapse(Duration(milliseconds: _echoWait + 1));
      expect(r2.last.waitingForRepeater, isFalse,
          reason: 'its echo could never reach the raw log');
    });
  });

  group('fail fast', () {
    for (final heardAgo in [null, const Duration(minutes: 11)]) {
      test('with no repeater heard in the last 10 minutes '
          '(${heardAgo == null ? 'none ever' : 'one 11 min ago'}) a flood '
          'nobody echoes is not parked: the ladder goes on and fails', () {
        fakeAsync((async) {
          final r = _Rig(async, budget: 3, graph: const []);
          if (heardAgo != null) {
            r.svc.noteRepeaterHeard();
            async.elapse(heardAgo);
          }
          r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
          for (var rung = 0; rung < 3; rung++) {
            async.flushMicrotasks();
            expect(r.sends, hasLength(rung + 1));
            r.sentLast();
            async.elapse(Duration(milliseconds: _echoWait + 1));
            expect(r.last.waitingForRepeater, isFalse);
            expect(r.last.status, MessageStatus.sent,
                reason: 'still waiting for its ACK');
            expect(r.svc.hasMessagesInFlight, isTrue);
            async.elapse(Duration(
                milliseconds: _timeoutMs -
                    _echoWait +
                    MessageRetryService.retryBackoffMs));
          }
          expect(r.sends.map((s) => s.attempt), [0, 1, 2],
              reason: 'each rung once, no resends');
          expect(r.last.status, MessageStatus.failed);
          expect(r.updates.where((m) => m.waitingForRepeater), isEmpty,
              reason: 'never shown waiting for a repeater');
          expect(r.svc.hasMessagesWaiting, isFalse);
          expect(r.svc.isSendingTo(_bob.publicKeyHex), isFalse);
        });
      });
    }

    test('a repeater heard 5 minutes ago: it parks, and the message says so',
        () {
      fakeAsync((async) {
        final r = _Rig(async, budget: 3, graph: const []);
        r.svc.noteRepeaterHeard();
        async.elapse(const Duration(minutes: 5));
        r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        async.elapse(Duration(milliseconds: _echoWait + 1));
        expect(r.last.waitingForRepeater, isTrue,
            reason: 'the row the chat shows');
        expect(r.last.status, MessageStatus.sent);
        expect(r.svc.hasMessagesWaiting, isTrue);
        expect(r.svc.hasMessagesInFlight, isFalse);
      });
    });

    test('a park that hears no repeater for 10 minutes fails, and the message '
        'queued behind it goes', () {
      fakeAsync((async) {
        final r = _Rig(async, budget: 3, graph: const []);
        r.svc.noteRepeaterHeard();
        r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
        async.flushMicrotasks();
        r.sentLast();
        r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
        async.flushMicrotasks();
        async.elapse(Duration(milliseconds: _echoWait + 1));
        expect(r.lastOf('one').waitingForRepeater, isTrue);

        async.elapse(MessageRetryService.parkLimit - const Duration(seconds: 1));
        expect(r.lastOf('one').status, MessageStatus.sent, reason: 'parked');
        expect(r.sends.map((s) => s.text), ['one']);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        final one = r.lastOf('one');
        expect(one.status, MessageStatus.failed);
        expect(one.waitingForRepeater, isFalse);
        expect(r.sends.map((s) => s.text), ['one', 'two'],
            reason: 'the queue moved on, and no rung of "one" after the limit');
        expect(r.svc.isQueued(
                r.added.firstWhere((m) => m.text == 'two').messageId),
            isFalse);
      });
    });

    test('a repeater heard after the cooldown sends it again and ends that '
        'park; parked again, it gets a fresh 10 minutes', () {
      fakeAsync((async) {
        final r = _Rig(async, budget: 3, graph: const []);
        r.svc.noteRepeaterHeard();
        r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        async.elapse(Duration(milliseconds: _echoWait + 1));
        expect(r.last.waitingForRepeater, isTrue);

        async.elapse(const Duration(minutes: 9));
        r.svc.noteRepeaterHeard();
        async.flushMicrotasks();
        expect(r.sends.map((s) => s.attempt), [0, 4]);
        expect(r.last.status, MessageStatus.pending);
        expect(r.last.waitingForRepeater, isFalse,
            reason: 'sent again: the line goes');

        r.sentLast();
        async.elapse(const Duration(minutes: 2));
        expect(r.last.status, MessageStatus.sent,
            reason: 'the first park\'s limit ended with it');
        expect(r.last.waitingForRepeater, isTrue, reason: 'parked again');

        async.elapse(const Duration(minutes: 9));
        expect(r.last.status, MessageStatus.failed);
        expect(r.last.waitingForRepeater, isFalse);
        expect(r.sends, hasLength(2));
      });
    });

    test('a late ACK after the park limit delivers it within the grace, and '
        'not after', () {
      for (final (wait, delivered) in [
        (const Duration(minutes: 4), true),
        (MessageRetryService.lateAckGrace + const Duration(seconds: 1), false),
      ]) {
        fakeAsync((async) {
          final r = _Rig(async, budget: 3, graph: const []);
          r.svc.noteRepeaterHeard();
          r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
          async.flushMicrotasks();
          r.sentLast();
          async.elapse(Duration(milliseconds: _echoWait + 1));
          async.elapse(MessageRetryService.parkLimit);
          expect(r.last.status, MessageStatus.failed);

          async.elapse(wait);
          r.svc.handleAckReceived(r.ackFor(0), 4000);
          async.flushMicrotasks();
          if (delivered) {
            expect(r.last.status, MessageStatus.delivered);
            expect(r.last.deliveredLate, isTrue);
            expect(r.last.waitingForRepeater, isFalse);
          } else {
            expect(r.last.status, MessageStatus.failed,
                reason: 'past the grace, as for any failed message');
          }
        });
      }
    });

    test('a retry whose radio write throws fails the message, the queue moves '
        'on, and a late ACK for its first copy still delivers it', () {
      fakeAsync((async) {
        // Write 1 is the first copy's, write 2 the retry's.
        final r =
            _Rig(async, budget: 3, graph: const [], routeWriteThrows: (n) => n == 2);
        r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
        r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
        async.flushMicrotasks();
        r.sentLast();
        async.elapse(const Duration(
            milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 1));
        async.flushMicrotasks();
        expect(r.routeWrites, 3);
        expect(r.lastOf('one').status, MessageStatus.failed);
        expect(r.sends.map((s) => s.text), ['one', 'two']);

        r.svc.handleAckReceived(r.ackFor(0), 4000);
        async.flushMicrotasks();
        expect(r.lastOf('one').status, MessageStatus.delivered);
        expect(r.lastOf('one').deliveredLate, isTrue);
      });
    });

    test('a parked resend whose radio write throws fails the message and the '
        'queue moves on', () {
      fakeAsync((async) {
        final r =
            _Rig(async, budget: 3, graph: const [], routeWriteThrows: (n) => n == 2);
        r.svc.noteRepeaterHeard();
        r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
        r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
        async.flushMicrotasks();
        r.sentLast();
        async.elapse(Duration(milliseconds: _echoWait + 1));
        expect(r.lastOf('one').waitingForRepeater, isTrue);

        async.elapse(const Duration(
            milliseconds: MessageRetryService.repeaterCooldownMs + 1));
        r.svc.noteRepeaterHeard();
        async.flushMicrotasks();
        expect(r.routeWrites, 3);
        final one = r.lastOf('one');
        expect(one.status, MessageStatus.failed);
        expect(one.waitingForRepeater, isFalse);
        expect(r.sends.map((s) => s.text), ['one', 'two']);
      });
    });

    test('a send that throws after the ladder moved on leaves the new '
        'attempt alone', () {
      fakeAsync((async) {
        final writes = <Completer<void>>[];
        final updates = <Message>[];
        final svc = MessageRetryService();
        svc.initialize(RetryServiceConfig(
          // Each write to the radio hangs until the test ends it.
          sendMessage: (_, _, _, _) {
            final w = Completer<void>();
            writes.add(w);
            return w.future;
          },
          addMessage: (_, _) {},
          updateMessage: updates.add,
          calculateTimeout: (_, _, {contact}) => _timeoutMs,
          pathHashByteWidth: () => 2,
          graphRoutes: (_) => const [],
        ));
        svc.setMaxRetries(3);
        svc.sendMessageWithRetry(contact: _bob, text: 'one');
        async.flushMicrotasks();
        expect(writes, hasLength(1));

        // No SENT: the pre-send timer moves the ladder on to rung 2, then
        // rung 1's write fails at last.
        async.elapse(const Duration(seconds: 15 + 5, milliseconds: 1));
        expect(writes, hasLength(2));
        expect(updates.last.retryCount, 1);
        writes.first.completeError(StateError('BLE write failed'));
        async.flushMicrotasks();
        expect(updates.last.status, MessageStatus.pending,
            reason: 'rung 2 is on its way, with its own timer');
        expect(updates.where((m) => m.status == MessageStatus.failed), isEmpty);
        svc.dispose();
      });
    });
  });
}
