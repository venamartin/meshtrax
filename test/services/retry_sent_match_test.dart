import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// A RESP_CODE_SENT the app cannot match by its ACK hash used to go to the
// oldest DM waiting for one, whoever it was to. Bob's parked DM and
// Carol's parked SOS woke on one relayed packet; Bob's ACK came, then the
// SENT for his resend, which carries the same hash. Carol's SOS took it,
// and Bob's radio ACKing the resend showed her SOS delivered although
// Carol sent nothing back.

const _timeoutMs = 20000;
const _airtimeMs = 564;
final _echoWait = TimeoutHelper.echoWaitMs(_airtimeMs, _timeoutMs);
const _sos = 'SOS: hurt at the spring';

Contact _person(String name, int seed) => Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
  name: name,
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 10, 17),
);

final _bob = _person('Bob', 0xAA);
final _carol = _person('Carol', 0x10);

class _Rig {
  _Rig() {
    svc.initialize(
      RetryServiceConfig(
        sendMessage: (contact, text, attempt, ts) =>
            sends.add((to: contact.name, text: text, attempt: attempt, ts: ts)),
        addMessage: (_, m) => seen.add(m),
        updateMessage: seen.add,
        clearContactPath: (_) {},
        calculateTimeout: (_, _, {contact}) => _timeoutMs,
        getSelfPublicKey: () => appKey,
        pathHashByteWidth: () => 2,
        estimateAirtime: (_) => _airtimeMs,
        graphRoutes: (_) => const <PathSelection>[], // every rung floods
      ),
    );
    svc.setMaxRetries(3);
  }

  // The radio always hashes with its own key; the app knows it once
  // SELF_INFO is in.
  final radioKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  late Uint8List? appKey = radioKey;
  final sends = <({String to, String text, int attempt, int ts})>[];
  final seen = <Message>[];
  final svc = MessageRetryService();

  /// The ACK hash the radio reports for the send to [to] numbered
  /// [attempt].
  int ackOf(String to, int attempt) {
    final s = sends.singleWhere((s) => s.to == to && s.attempt == attempt);
    return MessageRetryService.computeExpectedAckHash(
      s.ts,
      s.attempt,
      s.text,
      radioKey,
    );
  }

  Message last(String text) => seen.lastWhere((m) => m.text == text);
}

void main() {
  for (final carolFirst in [false, true]) {
    test('a SENT for Bob\'s resend after his ACK never lands on Carol\'s SOS '
        '(${carolFirst ? 'hers the older DM' : 'his parked first'})', () {
      fakeAsync((async) {
        final r = _Rig();
        for (final (contact, text)
            in carolFirst
                ? [(_carol, _sos), (_bob, 'one')]
                : [(_bob, 'one'), (_carol, _sos)]) {
          r.svc.sendMessageWithRetry(contact: contact, text: text);
          async.flushMicrotasks();
          r.svc.updateMessageFromSent(r.ackOf(contact.name, 0), 0);
          async.elapse(const Duration(seconds: 1));
        }
        // Nobody echoed either flood: both are parked, cooldowns run out.
        async.elapse(
          Duration(
            milliseconds: _echoWait + MessageRetryService.repeaterCooldownMs,
          ),
        );
        expect(r.last('one').waitingForRepeater, isTrue);
        expect(r.last(_sos).waitingForRepeater, isTrue);

        // Bob's path return is relayed: one packet wakes both.
        r.svc.noteRepeaterHeard();
        async.flushMicrotasks();
        final bobAck = r.ackOf('Bob', 0);
        expect(r.ackOf('Bob', 4), bobAck, reason: 'a resend keeps its ACK');
        expect(r.last(_sos).status, MessageStatus.pending);

        // The ACK it carries delivers Bob's DM; his resend's SENT follows.
        r.svc.handleAckReceived(bobAck, 3000);
        async.flushMicrotasks();
        expect(r.last('one').status, MessageStatus.delivered);
        expect(
          r.svc.updateMessageFromSent(bobAck, 0),
          isTrue,
          reason: 'Bob\'s own copy: nothing else may take it',
        );
        expect(r.last(_sos).status, MessageStatus.pending);

        // Bob's radio ACKs the resend.
        r.svc.handleAckReceived(bobAck, 2000);
        async.flushMicrotasks();
        expect(
          r.last(_sos).status,
          MessageStatus.pending,
          reason: 'Carol sent nothing back',
        );

        // Carol's own SENT and ACK still find her SOS.
        final carolAck = r.ackOf('Carol', 4);
        expect(r.svc.updateMessageFromSent(carolAck, 0), isTrue);
        expect(r.last(_sos).status, MessageStatus.sent);
        r.svc.handleAckReceived(carolAck, 2500);
        async.flushMicrotasks();
        expect(r.last(_sos).status, MessageStatus.delivered);
      });
    });
  }

  test('a DM sent before the radio\'s key is known still takes its SENT', () {
    fakeAsync((async) {
      final r = _Rig()..appKey = null;
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      async.flushMicrotasks();
      final ack = r.ackOf('Bob', 0);
      expect(r.svc.updateMessageFromSent(ack, 0), isTrue);
      expect(r.last('one').status, MessageStatus.sent);
      expect(r.last('one').expectedAckHash, ack);

      r.svc.handleAckReceived(ack, 2500);
      async.flushMicrotasks();
      expect(r.last('one').status, MessageStatus.delivered);
    });
  });

  test('a SENT that matches nothing goes to the DM sent without a hash, '
      'not to an older one with its own', () {
    fakeAsync((async) {
      final r = _Rig();
      r.svc.sendMessageWithRetry(contact: _carol, text: _sos);
      async.flushMicrotasks();
      // A reconnect: SELF_INFO is not in yet when Bob's DM goes.
      r.appKey = null;
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      async.flushMicrotasks();

      expect(r.svc.updateMessageFromSent(r.ackOf('Bob', 0), 0), isTrue);
      expect(r.last('one').status, MessageStatus.sent);
      expect(r.last(_sos).status, MessageStatus.pending);
      expect(r.svc.updateMessageFromSent(r.ackOf('Carol', 0), 0), isTrue);
      expect(r.last(_sos).status, MessageStatus.sent);
    });
  });
}
