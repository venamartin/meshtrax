import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// The quick resend of a flood nobody passed on (#384, _park) sends the same
// packet again, and that copy may wait for quiet air like any other. The
// attempt waits for it (as a routed attempt's second copy does since #407),
// and a DM that failed or was delivered never sends another copy, nor comes
// back to life (regression audit, 2026-11-27).

const _timeoutMs = 20000;
const _airtimeMs = 564;

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 26),
);

typedef _Send = ({int n, int attempt, int ts, String text, Duration at});

class _Rig {
  /// [holdFor]: how long send number n (0 = the first) waits for quiet air
  /// before the sender checks awaitsAck, as the connector's
  /// _sendMessageDirect does, then radioTakes, then hands the frame over.
  _Rig(this.async,
      {required int budget, required Duration Function(int n) holdFor})
      : svc = MessageRetryService(
            clock: () => DateTime(2026, 11, 26).add(async.elapsed)) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (contact, text, attempt, ts) async {
        final n = calls++;
        final hold = holdFor(n);
        if (hold > Duration.zero) await Future<void>.delayed(hold);
        if (!svc.awaitsAck(contact.publicKeyHex, ts, text, attempt)) {
          dropped.add(n);
          return;
        }
        svc.radioTakes(contact.publicKeyHex, ts, text);
        sends.add((n: n, attempt: attempt, ts: ts, text: text, at: async.elapsed));
      },
      maxSendHoldMs: TimeoutHelper.maxSendHoldMs,
      addMessage: (_, _) {},
      updateMessage: (m) => updates.add((message: m, at: async.elapsed)),
      clearContactPath: (_) {},
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      estimateAirtime: (_) => _airtimeMs,
      graphRoutes: (_) => const [], // Pathfinder knows nothing: every try floods
    ));
    svc.setMaxRetries(budget);
  }

  final FakeAsync async;
  final MessageRetryService svc;
  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  int calls = 0;
  final dropped = <int>[];
  final sends = <_Send>[];
  final updates = <({Message message, Duration at})>[];

  int _ackFor(_Send s) =>
      MessageRetryService.computeExpectedAckHash(s.ts, s.attempt, s.text, selfKey);

  /// The radio's RESP_CODE_SENT for send [i].
  void sent(int i) => svc.updateMessageFromSent(_ackFor(sends[i]), 0);
  void sentLast() => sent(sends.length - 1);

  /// A repeater is heard passing on the latest flood to Bob: no further
  /// quick resend of it.
  void passedOn() => svc.noteOwnFloodEcho(_bob.publicKey[0]);

  List<Duration> failedAt(String text) => [
        for (final u in updates)
          if (u.message.text == text && u.message.status == MessageStatus.failed)
            u.at,
      ];
}

void main() {
  final echoWait = Duration(
      milliseconds: TimeoutHelper.echoWaitMs(_airtimeMs, _timeoutMs) + 1);

  test('a quick resend that waits 12 s for quiet air goes out, and the next '
      'try waits for its ACK', () {
    fakeAsync((async) {
      final r = _Rig(async,
          budget: 3,
          holdFor: (n) => n == 1 ? const Duration(seconds: 12) : Duration.zero);
      r.svc.noteRepeaterHeard(); // a repeater was heard just now
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      expect(r.sends, hasLength(1));
      r.sentLast(); // SENT: the ACK wait and the echo watch start
      async.elapse(echoWait); // no repeater passed it on: the quick resend
      async.elapse(const Duration(seconds: 13)); // past the first ACK wait
      expect(r.dropped, isEmpty);
      expect(r.sends, hasLength(2));
      expect(r.sends[1].attempt, 0, reason: 'the same packet once more');
      r.sentLast(); // SENT for the copy: its ACK wait starts now
      r.passedOn();
      async.elapse(const Duration(seconds: 19));
      expect(r.sends, hasLength(2), reason: 'the copy is still being waited for');
      async.elapse(const Duration(seconds: 7)); // its wait and the 5 s backoff
      expect(r.sends, hasLength(3));
      expect(r.sends[2].attempt, 1);
    });
  });

  test('on the last try the copy holds the DM open: it fails once, after the '
      "copy's ACK wait, and never comes back", () {
    fakeAsync((async) {
      final r = _Rig(async,
          budget: 1,
          holdFor: (n) => n == 1 ? const Duration(seconds: 12) : Duration.zero);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(echoWait);
      async.elapse(const Duration(seconds: 10)); // the first ACK wait is over
      expect(r.failedAt('hi'), isEmpty);
      async.elapse(const Duration(seconds: 3));
      expect(r.sends, hasLength(2));
      r.sentLast();
      r.passedOn();
      async.elapse(const Duration(seconds: 21));
      expect(r.failedAt('hi'), hasLength(1));
      async.elapse(const Duration(minutes: 6));
      expect(r.sends, hasLength(2));
      expect(r.updates.last.message.status, MessageStatus.failed);
      expect(r.svc.hasPendingMessages, isFalse,
          reason: 'the late-ACK grace cleaned it up');
    });
  });

  test("a failed DM's held copy never goes out, and the DM is still cleaned "
      'up', () {
    fakeAsync((async) {
      // Held longer than the copy's own safety wait (15 s plus the 18 s
      // the sender may hold it), the attempt is given up first.
      final r = _Rig(async,
          budget: 1,
          holdFor: (n) => n == 1 ? const Duration(seconds: 40) : Duration.zero);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(echoWait);
      async.elapse(const Duration(seconds: 34));
      expect(r.failedAt('hi'), hasLength(1));
      async.elapse(const Duration(seconds: 7)); // the hold ends
      expect(r.dropped, [1]);
      expect(r.sends, hasLength(1));
      async.elapse(const Duration(minutes: 6));
      expect(r.svc.hasPendingMessages, isFalse);
    });
  });

  test('radioTakes leaves a failed DM alone: its late-ACK grace still ends '
      'it', () {
    fakeAsync((async) {
      final r = _Rig(async, budget: 1, holdFor: (_) => Duration.zero);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(const Duration(seconds: 21)); // no repeater heard: it fails
      expect(r.failedAt('hi'), hasLength(1));
      r.svc.radioTakes(_bob.publicKeyHex, r.sends[0].ts, 'hi');
      async.elapse(const Duration(minutes: 6));
      expect(r.svc.hasPendingMessages, isFalse);
    });
  });

  test('a second DM to the same contact never goes out while the first still '
      'waits, and nothing of the first goes out after it failed', () {
    fakeAsync((async) {
      final r = _Rig(async,
          budget: 1,
          holdFor: (n) => n == 1 ? const Duration(seconds: 12) : Duration.zero);
      r.svc.noteRepeaterHeard();
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
      async.flushMicrotasks();
      r.sent(0);
      async.elapse(echoWait); // nobody passed 'one' on: its quick resend
      async.elapse(const Duration(seconds: 13)); // the copy's hold ends
      expect(r.sends, hasLength(2));
      r.sentLast();
      r.passedOn(); // the copy was passed on; no answer comes
      for (var step = 0; step < 12; step++) {
        final before = r.sends.length;
        async.elapse(const Duration(seconds: 10));
        for (var i = before; i < r.sends.length; i++) {
          r.sent(i);
          r.passedOn();
        }
      }
      final oneFailed = r.failedAt('one');
      expect(oneFailed, hasLength(1));
      final ones = r.sends.where((s) => s.text == 'one');
      final twos = r.sends.where((s) => s.text == 'two');
      expect(ones.every((s) => s.at <= oneFailed.single), isTrue);
      expect(twos, isNotEmpty);
      expect(twos.every((s) => s.at >= oneFailed.single), isTrue);
    });
  });
}
