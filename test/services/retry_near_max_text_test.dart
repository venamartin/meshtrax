import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Firmware BaseChatMesh::composeMsgPacket refuses attempt > 3 when the text
// is longer than MAX_TEXT_LEN - 2 (158 bytes): the fifth attempt of a
// near-max DM could never go out and the ladder waited 15 s for nothing.

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
    lastSeen: DateTime(2026, 10, 17),
  );

  /// Sends [text] with Max Message Retries 5, lets every attempt time out,
  /// and returns how many attempts went out and the final status.
  (int, MessageStatus?) run(String text, {bool pathfinder = false}) {
    late (int, MessageStatus?) result;
    fakeAsync((async) {
      final sends = <({String text, int attempt, int ts})>[];
      Message? last;
      final svc = MessageRetryService()
        ..initialize(RetryServiceConfig(
          sendMessage: (_, t, attempt, ts) =>
              sends.add((text: t, attempt: attempt, ts: ts)),
          addMessage: (_, _) {},
          updateMessage: (m) => last = m,
          clearContactPath: (_) {},
          calculateTimeout: (_, _, {contact}) => _timeoutMs,
          getSelfPublicKey: () => selfKey,
          pathHashByteWidth: () => 2,
          graphRoutes: pathfinder ? (_) => const [] : null,
        ))
        ..setMaxRetries(5);
      svc.sendMessageWithRetry(contact: bob, text: text);
      for (var i = 0; i < 6; i++) {
        async.flushMicrotasks();
        if (sends.length > i) {
          svc.updateMessageFromSent(
              MessageRetryService.computeExpectedAckHash(
                  sends[i].ts, sends[i].attempt, sends[i].text, selfKey),
              0);
        }
        async.elapse(const Duration(
            milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 1));
      }
      result = (sends.length, last?.status);
    });
    return result;
  }

  test('a 159-byte text stops after four attempts', () {
    expect(run('a' * 159), (4, MessageStatus.failed));
    expect(run('a' * 160, pathfinder: true), (4, MessageStatus.failed));
  });

  test('a 158-byte text keeps all five', () {
    expect(run('a' * 158), (5, MessageStatus.failed));
    expect(run('a' * 20, pathfinder: true), (5, MessageStatus.failed));
  });
}
