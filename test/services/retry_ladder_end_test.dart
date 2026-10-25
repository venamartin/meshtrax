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
  late List<bool> floods;

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  setUp(() {
    svc = MessageRetryService();
    sends = [];
    ended = [];
    outcomes = [];
    floods = [];
    svc.initialize(RetryServiceConfig(
      onFloodAttemptEnded: (_, {required delivered}) => floods.add(delivered),
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

  test('a flood attempt that went on the air reports its end', () {
    fakeAsync((async) {
      svc.setMaxRetries(2);
      svc.sendMessageWithRetry(contact: bob, text: 'flooded', floodFirst: true);
      async.flushMicrotasks();
      svc.updateMessageFromSent(ackFor(0), _timeoutMs);
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(floods, [false], reason: 'the first flood timed out');
      async.elapse(const Duration(milliseconds: MessageRetryService.retryBackoffMs + 1));
      svc.updateMessageFromSent(ackFor(1), _timeoutMs);
      svc.handleAckReceived(ackFor(1), 100);
      async.flushMicrotasks();
      expect(floods, [false, true], reason: 'the second one was acked');
      async.elapse(MessageRetryService.lateAckGrace);
    });
  });

  test('a flood nobody echoed is parked and reported, and still counts as '
      'waiting', () {
    fakeAsync((async) {
      final withEcho = MessageRetryService();
      final ended = <bool>[];
      withEcho.initialize(RetryServiceConfig(
        sendMessage: (_, text, attempt, ts) =>
            sends.add((text: text, attempt: attempt, ts: ts)),
        addMessage: (_, _) {},
        updateMessage: (_) {},
        clearContactPath: (_) {},
        calculateTimeout: (_, _, {contact}) => 30000,
        getSelfPublicKey: () => selfKey,
        pathHashByteWidth: () => 2,
        estimateAirtime: (_) => 200,
        onFloodAttemptEnded: (_, {required delivered}) => ended.add(delivered),
      ));
      withEcho.sendMessageWithRetry(contact: bob, text: 'anyone?', floodFirst: true);
      async.flushMicrotasks();
      withEcho.updateMessageFromSent(ackFor(0), 30000);
      async.elapse(const Duration(seconds: 15)); // past the echo wait
      expect(ended, [false], reason: 'parked: no repeater heard it');
      expect(withEcho.hasMessagesInFlight, isFalse,
          reason: 'nothing is on the air');
      expect(withEcho.hasMessagesWaiting, isTrue,
          reason: 'but the message still wants to go');
      withEcho.dispose();
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
