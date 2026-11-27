import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Field 2026-11-26: before a DM try goes out the sender may wait up to 18 s
// for a quiet radio. The 15 s the radio has to answer ran from before that
// wait, so a try that waited 16 s was given up as it went out and the
// attempt was lost. The 15 s now run from the moment the radio takes it.

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 26),
);

class _Rig {
  /// [hold]: how long each try waits for a quiet radio. [says]: whether the
  /// sender then says that the radio takes it.
  _Rig({required Duration hold, bool says = true}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (contact, text, attempt, ts) async {
        await Future<void>.delayed(hold);
        if (!svc.awaitsAck(contact.publicKeyHex, ts, text, attempt)) {
          dropped++;
          return;
        }
        if (says) svc.radioTakes(contact.publicKeyHex, ts, text);
        sent.add(attempt);
      },
      maxSendHoldMs: 18000,
      addMessage: (_, _) {},
      updateMessage: (m) => last = m,
      clearContactPath: (_) {},
      setContactPath: (_, _, _, _) {},
      calculateTimeout: (_, _, {contact}) => 9000,
      getSelfPublicKey: () =>
          Uint8List.fromList(List.generate(32, (i) => 0x42 + i)),
      pathHashByteWidth: () => 2,
    ));
    svc.setMaxRetries(3);
  }

  final svc = MessageRetryService();
  final sent = <int>[];
  int dropped = 0;
  Message? last;
}

void main() {
  test('a try held 16 s for a quiet radio still goes out', () {
    fakeAsync((async) {
      final r = _Rig(hold: const Duration(seconds: 16));
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.elapse(const Duration(seconds: 17));
      expect(r.sent, [0]);
      expect(r.dropped, 0);
    });
  });

  test('once the radio has the try, its answer is due within 15 s', () {
    fakeAsync((async) {
      final r = _Rig(hold: const Duration(seconds: 16));
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      // Taken at 16 s; the radio never answers.
      async.elapse(const Duration(seconds: 30));
      expect(r.last?.retryCount ?? 0, 0, reason: 'still inside the 15 s');
      async.elapse(const Duration(seconds: 2));
      expect(r.last?.retryCount, 1, reason: 'given up 15 s after it was taken');
    });
  });

  test('a sender that never says the radio took it is still given up on',
      () {
    fakeAsync((async) {
      final r = _Rig(hold: const Duration(seconds: 1), says: false);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.elapse(const Duration(seconds: 32));
      expect(r.last?.retryCount ?? 0, 0);
      async.elapse(const Duration(seconds: 2));
      expect(r.last?.retryCount, 1,
          reason: 'after the longest hold and the 15 s');
    });
  });
}
