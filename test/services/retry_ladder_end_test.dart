import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// While a DM ladder runs it owns the route stored on the radio; when the
// last one to a contact ends, Pathfinder's route keeper takes it back.

const _timeoutMs = 2000;

void main() {
  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  final bob = Contact(
    publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
    name: 'Bob',
    type: 1,
    pathLength: -1,
    path: Uint8List(0),
    pathHashSize: 2,
    lastSeen: DateTime(2026, 10, 16),
  );

  late MessageRetryService svc;
  late List<({String text, int attempt, int ts})> sends;
  late List<String> ended;
  late List<({String key, bool delivered, bool? echoHeard})> outcomes;

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  setUp(() {
    svc = MessageRetryService();
    sends = [];
    ended = [];
    outcomes = [];
    svc.initialize(RetryServiceConfig(
      onSendOutcome: (key, {required delivered, required echoHeard}) =>
          outcomes.add((key: key, delivered: delivered, echoHeard: echoHeard)),
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) {},
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      onLadderEnded: ended.add,
    ));
  });

  test('ends once, after the last queued message to the contact', () {
    fakeAsync((async) {
      svc.sendMessageWithRetry(contact: bob, text: 'one');
      svc.sendMessageWithRetry(contact: bob, text: 'two');
      async.flushMicrotasks();
      expect(svc.isSendingTo(bob.publicKeyHex), isTrue);

      svc.updateMessageFromSent(ackFor(0), _timeoutMs);
      svc.handleAckReceived(ackFor(0), 100);
      async.flushMicrotasks();
      expect(ended, isEmpty, reason: '"two" is on its ladder now');
      expect(svc.isSendingTo(bob.publicKeyHex), isTrue);

      svc.updateMessageFromSent(ackFor(1), _timeoutMs);
      svc.handleAckReceived(ackFor(1), 100);
      async.flushMicrotasks();
      expect(ended, [bob.publicKeyHex]);
      expect(svc.isSendingTo(bob.publicKeyHex), isFalse);
      expect(outcomes.map((o) => o.delivered), [true, true],
          reason: 'one outcome per message, as each is resolved');
    });
  });

  test('a message that times out reports an outcome with no echo verdict '
      'when no flood of it was observable', () {
    fakeAsync((async) {
      svc.setMaxRetries(1);
      svc.sendMessageWithRetry(contact: bob, text: 'lost');
      async.flushMicrotasks();
      svc.updateMessageFromSent(ackFor(0), _timeoutMs);
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(outcomes, hasLength(1));
      expect(outcomes.single.delivered, isFalse);
      expect(outcomes.single.echoHeard, isNull,
          reason: 'no airtime estimator: the echo watch never armed');
      async.elapse(MessageRetryService.lateAckGrace);
    });
  });

  test('a ladder that runs out of attempts ends too', () {
    fakeAsync((async) {
      svc.setMaxRetries(1);
      svc.sendMessageWithRetry(contact: bob, text: 'lost');
      async.flushMicrotasks();
      svc.updateMessageFromSent(ackFor(0), _timeoutMs);
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(ended, [bob.publicKeyHex]);
      async.elapse(MessageRetryService.lateAckGrace);
    });
  });
}
