import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Replicates the SHA-256 computation from [MessageRetryService.computeExpectedAckHash]
/// so tests can cross-check without calling the real implementation twice.
int _manualAckHash(
  int timestampSeconds,
  int attemptMasked, // already masked to 0x03
  String text,
  Uint8List senderPubKey,
) {
  final textBytes = utf8.encode(text);
  final buffer = Uint8List(4 + 1 + textBytes.length + senderPubKey.length);
  int offset = 0;

  buffer[offset++] = timestampSeconds & 0xFF;
  buffer[offset++] = (timestampSeconds >> 8) & 0xFF;
  buffer[offset++] = (timestampSeconds >> 16) & 0xFF;
  buffer[offset++] = (timestampSeconds >> 24) & 0xFF;
  buffer[offset++] = attemptMasked & 0xFF;

  buffer.setRange(offset, offset + textBytes.length, textBytes);
  offset += textBytes.length;
  buffer.setRange(offset, offset + senderPubKey.length, senderPubKey);

  final hash = sha256.convert(buffer);
  final bytes = Uint8List.fromList(hash.bytes.sublist(0, 4));
  return (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | bytes[0];
}

Uint8List _makeKey(int seed) {
  final key = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    key[i] = (seed + i) & 0xFF;
  }
  return key;
}

Uint8List _makeRecipientKey() {
  final key = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    key[i] = (0xAA + i) & 0xFF;
  }
  return key;
}

Contact _makeContact({
  required Uint8List publicKey,
  int pathLength = -1,
  List<int> path = const [],
  int? pathOverride,
  List<int>? pathOverrideBytes,
}) {
  return Contact(
    publicKey: publicKey,
    name: 'Test',
    type: 1,
    pathLength: pathLength,
    path: Uint8List.fromList(path),
    pathOverride: pathOverride,
    pathOverrideBytes: pathOverrideBytes == null
        ? null
        : Uint8List.fromList(pathOverrideBytes),
    lastSeen: DateTime.now(),
  );
}

/// A retry service wired to fakes that record what reached the radio.
class _Harness {
  final retryService = MessageRetryService();
  final selfKey = _makeKey(0x42);
  final sends = <({int attempt, int timestamp})>[];
  final pathPushes = <List<int>>[];
  int pathResets = 0;
  Message? lastUpdate;
  static const timeoutMs = 2000;

  _Harness() {
    retryService.initialize(
      RetryServiceConfig(
        sendMessage: (_, _, attempt, ts) =>
            sends.add((attempt: attempt, timestamp: ts)),
        addMessage: (_, message) => lastUpdate = message,
        updateMessage: (message) => lastUpdate = message,
        clearContactPath: (_) => pathResets++,
        setContactPath: (_, bytes, _) => pathPushes.add(bytes.toList()),
        calculateTimeout: (_, _, {contact}) => timeoutMs,
        getSelfPublicKey: () => selfKey,
      ),
    );
  }

  int ackHashFor(int sendIndex, String text) {
    final s = sends[sendIndex];
    return MessageRetryService.computeExpectedAckHash(
      s.timestamp,
      s.attempt,
      text,
      selfKey,
    );
  }

  /// Simulates RESP_CODE_SENT for the most recent send.
  void sent(String text) {
    retryService.updateMessageFromSent(ackHashFor(sends.length - 1, text), 0);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Fixed inputs reused across groups
  const int fixedTs = 1700000000;
  const String fixedText = 'Hello mesh';
  final Uint8List fixedKey = _makeKey(0x11);
  final Uint8List recipientKey = _makeRecipientKey();

  // -------------------------------------------------------------------------
  group('computeExpectedAckHash — attempt masking', () {
    test('attempts 0–3 all produce different hashes', () {
      final hashes = List.generate(
        4,
        (i) => MessageRetryService.computeExpectedAckHash(
          fixedTs,
          i,
          fixedText,
          fixedKey,
        ),
      );

      // All four must be pairwise distinct
      for (int i = 0; i < hashes.length; i++) {
        for (int j = i + 1; j < hashes.length; j++) {
          expect(
            hashes[i],
            isNot(equals(hashes[j])),
            reason: 'attempt $i and attempt $j should produce different hashes',
          );
        }
      }
    });

    test('attempt 4 produces same hash as attempt 0 (4 & 0x03 == 0)', () {
      final hash0 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        0,
        fixedText,
        fixedKey,
      );
      final hash4 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        4,
        fixedText,
        fixedKey,
      );
      expect(hash4, equals(hash0));
    });

    test('attempt 5 produces same hash as attempt 1 (5 & 0x03 == 1)', () {
      final hash1 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        1,
        fixedText,
        fixedKey,
      );
      final hash5 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        5,
        fixedText,
        fixedKey,
      );
      expect(hash5, equals(hash1));
    });

    test('attempt 7 produces same hash as attempt 3 (7 & 0x03 == 3)', () {
      final hash3 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        3,
        fixedText,
        fixedKey,
      );
      final hash7 = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        7,
        fixedText,
        fixedKey,
      );
      expect(hash7, equals(hash3));
    });

    test('same inputs always produce the same hash (deterministic)', () {
      final first = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        2,
        fixedText,
        fixedKey,
      );
      final second = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        2,
        fixedText,
        fixedKey,
      );
      expect(first, equals(second));
    });

    test('hash matches manual SHA-256 computation', () {
      for (int attempt = 0; attempt < 4; attempt++) {
        final actual = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          attempt,
          fixedText,
          fixedKey,
        );
        final expected = _manualAckHash(fixedTs, attempt, fixedText, fixedKey);
        expect(
          actual,
          equals(expected),
          reason: 'mismatch at attempt $attempt',
        );
      }
    });

    test('different timestamps produce different hashes', () {
      final hashA = MessageRetryService.computeExpectedAckHash(
        1700000000,
        0,
        fixedText,
        fixedKey,
      );
      final hashB = MessageRetryService.computeExpectedAckHash(
        1700000001,
        0,
        fixedText,
        fixedKey,
      );
      expect(hashA, isNot(equals(hashB)));
    });

    test('different texts produce different hashes', () {
      final hashA = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        0,
        'Hello mesh',
        fixedKey,
      );
      final hashB = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        0,
        'Hello mesh!',
        fixedKey,
      );
      expect(hashA, isNot(equals(hashB)));
    });

    test('different sender keys produce different hashes', () {
      final keyA = _makeKey(0x01);
      final keyB = _makeKey(0x02);
      final hashA = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        0,
        fixedText,
        keyA,
      );
      final hashB = MessageRetryService.computeExpectedAckHash(
        fixedTs,
        0,
        fixedText,
        keyB,
      );
      expect(hashA, isNot(equals(hashB)));
    });
  });

  // -------------------------------------------------------------------------
  group('buildSendTextMsgFrame — attempt encoding', () {
    // Frame layout: [cmd(1)][txtType(1)][attempt(1)][timestamp(4)][pubKeyPrefix(6)][text][null(1)]
    // So byte index 2 carries the raw attempt & 0xFF.

    test('attempt 0 → byte[2] is 0', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 0,
        timestampSeconds: fixedTs,
      );
      expect(frame[2], equals(0));
    });

    test('attempt 3 → byte[2] is 3', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 3,
        timestampSeconds: fixedTs,
      );
      expect(frame[2], equals(3));
    });

    test('attempt 4 → byte[2] is 4 (raw value, not clamped to 3)', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 4,
        timestampSeconds: fixedTs,
      );
      expect(frame[2], equals(4));
    });

    test('attempt 255 → byte[2] is 255', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 255,
        timestampSeconds: fixedTs,
      );
      expect(frame[2], equals(255));
    });

    test('attempt 256 → byte[2] is 255 (clamped, not wrapped)', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 256,
        timestampSeconds: fixedTs,
      );
      expect(frame[2], equals(255));
    });

    test('byte[0] is cmdSendTxtMsg (2)', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 0,
        timestampSeconds: fixedTs,
      );
      expect(frame[0], equals(cmdSendTxtMsg));
    });

    test('byte[1] is txtTypePlain (0)', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 0,
        timestampSeconds: fixedTs,
      );
      expect(frame[1], equals(txtTypePlain));
    });

    test('timestamp bytes[3..6] are little-endian encoded', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 0,
        timestampSeconds: fixedTs,
      );
      final decoded =
          frame[3] | (frame[4] << 8) | (frame[5] << 16) | (frame[6] << 24);
      expect(decoded, equals(fixedTs));
    });

    test(
      'pub key prefix (bytes 7..12) matches first 6 bytes of recipient key',
      () {
        final frame = buildSendTextMsgFrame(
          recipientKey,
          'hi',
          attempt: 0,
          timestampSeconds: fixedTs,
        );
        expect(frame.sublist(7, 13), equals(recipientKey.sublist(0, 6)));
      },
    );

    test('frame is null-terminated after text', () {
      final frame = buildSendTextMsgFrame(
        recipientKey,
        'hi',
        attempt: 0,
        timestampSeconds: fixedTs,
      );
      expect(frame.last, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  group(
    'ACK hash consistency between computeExpectedAckHash and firmware behavior',
    () {
      // The firmware reads the raw attempt byte from the frame, then masks it
      // with & 3 when computing the ACK hash.  Flutter does the same masking
      // inside computeExpectedAckHash.  So the two sides must agree.

      test('attempt 4: flutter hash (4 & 3 = 0) equals hash for attempt 0', () {
        // Flutter sends raw byte 4 in the frame, but computes hash with 4&3=0.
        // Firmware reads 4, masks to 0, computes same hash → they match.
        final hashFor4 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          4,
          fixedText,
          fixedKey,
        );
        final hashFor0 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          0,
          fixedText,
          fixedKey,
        );
        expect(hashFor4, equals(hashFor0));

        // Also confirm the frame byte is raw 4, not 0
        final frame = buildSendTextMsgFrame(
          recipientKey,
          fixedText,
          attempt: 4,
          timestampSeconds: fixedTs,
        );
        expect(frame[2], equals(4), reason: 'frame carries raw attempt byte');
      });

      test(
        'attempt 3: flutter hash equals hash computed directly for attempt 3',
        () {
          // 3 & 3 == 3, so no wrapping — both sides agree.
          final hashFor3 = MessageRetryService.computeExpectedAckHash(
            fixedTs,
            3,
            fixedText,
            fixedKey,
          );
          final hashFor3Direct = _manualAckHash(
            fixedTs,
            3,
            fixedText,
            fixedKey,
          );
          expect(hashFor3, equals(hashFor3Direct));

          final frame = buildSendTextMsgFrame(
            recipientKey,
            fixedText,
            attempt: 3,
            timestampSeconds: fixedTs,
          );
          expect(frame[2], equals(3));
        },
      );

      test(
        'attempt 3 and attempt 4 produce DIFFERENT hashes (3&3=3 vs 4&3=0)',
        () {
          final hash3 = MessageRetryService.computeExpectedAckHash(
            fixedTs,
            3,
            fixedText,
            fixedKey,
          );
          final hash4 = MessageRetryService.computeExpectedAckHash(
            fixedTs,
            4,
            fixedText,
            fixedKey,
          );
          expect(hash3, isNot(equals(hash4)));
        },
      );

      test('attempt 8 (8&3=0) produces the same hash as attempt 0', () {
        final hash8 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          8,
          fixedText,
          fixedKey,
        );
        final hash0 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          0,
          fixedText,
          fixedKey,
        );
        expect(hash8, equals(hash0));
      });

      test(
        'hash cycle repeats every 4 attempts (modular arithmetic holds)',
        () {
          for (int base = 0; base < 4; base++) {
            final hashBase = MessageRetryService.computeExpectedAckHash(
              fixedTs,
              base,
              fixedText,
              fixedKey,
            );
            final hashPlus4 = MessageRetryService.computeExpectedAckHash(
              fixedTs,
              base + 4,
              fixedText,
              fixedKey,
            );
            final hashPlus8 = MessageRetryService.computeExpectedAckHash(
              fixedTs,
              base + 8,
              fixedText,
              fixedKey,
            );
            expect(
              hashPlus4,
              equals(hashBase),
              reason: 'attempt ${base + 4} should match attempt $base',
            );
            expect(
              hashPlus8,
              equals(hashBase),
              reason: 'attempt ${base + 8} should match attempt $base',
            );
          }
        },
      );
    },
  );

  // -------------------------------------------------------------------------
  group('_AckHashMapping.attemptIndex — indirect verification via public API', () {
    // _AckHashMapping is private; we validate its purpose indirectly: that
    // computeExpectedAckHash records the correct per-attempt hash so that the
    // right hash is matched when an ACK arrives.

    test('each attempt index 0–3 produces a distinct 4-byte hash', () {
      final hashes = <String, int>{};
      for (int attempt = 0; attempt < 4; attempt++) {
        final hash = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          attempt,
          fixedText,
          fixedKey,
        );
        final hex = hash.toRadixString(16).padLeft(8, '0');
        expect(
          hashes.containsKey(hex),
          isFalse,
          reason: 'attempt $attempt collides with attempt ${hashes[hex]}',
        );
        hashes[hex] = attempt;
      }
      expect(hashes.length, equals(4));
    });

    test(
      'attempt index wraps: hash for attempt 4 matches stored hash for attempt 0',
      () {
        final storedHash = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          0,
          fixedText,
          fixedKey,
        );
        // Simulates firmware reading raw attempt=4 and masking to 0 for hash.
        final firmwareComputedHash = _manualAckHash(
          fixedTs,
          4 & 0x03, // firmware masks here
          fixedText,
          fixedKey,
        );
        expect(firmwareComputedHash, equals(storedHash));
      },
    );

    test(
      'attempt index 1 and 5 map to the same slot — ACK from either retry is matched',
      () {
        final hashForAttempt1 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          1,
          fixedText,
          fixedKey,
        );
        final hashForAttempt5 = MessageRetryService.computeExpectedAckHash(
          fixedTs,
          5,
          fixedText,
          fixedKey,
        );
        // Both should produce the identical bytes, confirming the service
        // would record and match the correct attempt index.
        expect(hashForAttempt5, equals(hashForAttempt1));
      },
    );
  });

  group('sendMessageWithRetry — path resolution', () {
    test(
      'uses the contact path when no override is set',
      () async {
        final retryService = MessageRetryService();
        Message? addedMessage;
        final contact = _makeContact(
          publicKey: recipientKey,
          pathLength: 2,
          path: const [0x10, 0x20],
        );

        retryService.initialize(
          RetryServiceConfig(
            sendMessage: (_, _, _, _) {},
            addMessage: (_, message) => addedMessage = message,
            updateMessage: (_) {},
            clearContactPath: (_) {},
            setContactPath: (_, _, _) {},
          ),
        );

        await retryService.sendMessageWithRetry(
          contact: contact,
          text: 'hello',
        );

        expect(addedMessage, isNotNull);
        expect(addedMessage!.pathLength, equals(2));
        expect(
          addedMessage!.pathBytes,
          equals(Uint8List.fromList([0x10, 0x20])),
        );
      },
    );

    test('uses flood when contact is in flood mode', () async {
      final retryService = MessageRetryService();
      Message? addedMessage;
      final contact = _makeContact(
        publicKey: recipientKey,
        pathLength: -1,
        path: const [],
      );

      retryService.initialize(
        RetryServiceConfig(
          sendMessage: (_, _, _, _) {},
          addMessage: (_, message) => addedMessage = message,
          updateMessage: (_) {},
          clearContactPath: (_) {},
          setContactPath: (_, _, _) {},
        ),
      );

      await retryService.sendMessageWithRetry(contact: contact, text: 'hello');

      expect(addedMessage, isNotNull);
      expect(addedMessage!.pathLength, equals(-1));
      expect(addedMessage!.pathBytes, isEmpty);
    });
  });

  group('attempt ladder — firmware owns the route', () {
    const text = 'hello';
    const retryGap = _Harness.timeoutMs + MessageRetryService.retryBackoffMs;

    test('a known route is used as-is, then a retry resets it and floods', () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(
          publicKey: recipientKey,
          pathLength: 2,
          path: const [0x10, 0x20],
        );

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        h.sent(text);

        expect(h.sends.map((s) => s.attempt), equals([0]));
        expect(h.pathPushes, isEmpty, reason: 'never writes a firmware route');
        expect(h.pathResets, equals(0));
        expect(h.lastUpdate!.pathLength, equals(2));

        async.elapse(const Duration(milliseconds: retryGap));
        h.sent(text);

        expect(h.sends.map((s) => s.attempt), equals([0, 1]));
        expect(h.pathResets, equals(1));
        expect(h.lastUpdate!.pathLength, equals(-1));
        expect(h.lastUpdate!.status, equals(MessageStatus.sent));
      });
    });

    test('no route floods from the first attempt', () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(publicKey: recipientKey);

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();

        expect(h.sends.length, equals(1));
        expect(h.pathResets, equals(1));
        expect(h.lastUpdate!.pathLength, equals(-1));
      });
    });

    test('forced flood floods on every attempt', () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(
          publicKey: recipientKey,
          pathLength: 2,
          path: const [0x10, 0x20],
          pathOverride: -1,
        );

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        h.sent(text);
        async.elapse(const Duration(milliseconds: retryGap));
        h.sent(text);

        expect(h.sends.length, equals(2));
        expect(h.pathResets, equals(2));
        expect(h.pathPushes, isEmpty);
      });
    });

    test('a custom path is pushed on the first attempt only', () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(
          publicKey: recipientKey,
          pathOverride: 1,
          pathOverrideBytes: const [0x33],
        );

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        h.sent(text);

        expect(h.pathPushes, equals([[0x33]]));
        expect(h.pathResets, equals(0));

        async.elapse(const Duration(milliseconds: retryGap));

        expect(h.sends.length, equals(2));
        expect(h.pathPushes.length, equals(1));
        expect(h.pathResets, equals(1));
      });
    });

    test('fails after maxRetries, and a late ACK still delivers', () {
      fakeAsync((async) {
        final h = _Harness();
        h.retryService.setMaxRetries(3);
        final contact = _makeContact(publicKey: recipientKey);

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        for (var i = 0; i < 3; i++) {
          h.sent(text);
          async.elapse(const Duration(milliseconds: retryGap));
        }

        expect(h.sends.length, equals(3));
        expect(h.lastUpdate!.status, equals(MessageStatus.failed));

        async.elapse(const Duration(minutes: 1));
        h.retryService.handleAckReceived(h.ackHashFor(1, text), 61000);

        expect(h.lastUpdate!.status, equals(MessageStatus.delivered));
        expect(h.lastUpdate!.tripTimeMs, equals(61000));
        expect(h.lastUpdate!.deliveredLate, isTrue);
        expect(h.lastUpdate!.retryCount, equals(1),
            reason: 'credited to the attempt that was acknowledged');
      });
    });

    test('with 4 attempts the route gets a second try before flooding', () {
      fakeAsync((async) {
        final h = _Harness();
        h.retryService.setMaxRetries(4);
        final contact = _makeContact(
          publicKey: recipientKey,
          pathLength: 2,
          path: const [0x10, 0x20],
        );

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        h.sent(text);
        async.elapse(const Duration(milliseconds: retryGap));
        h.sent(text);

        expect(h.sends.map((s) => s.attempt), equals([0, 1]));
        expect(h.pathResets, equals(0), reason: 'attempt 1 stays on the route');
        expect(h.lastUpdate!.pathLength, equals(2));

        async.elapse(const Duration(milliseconds: retryGap));
        h.sent(text);

        expect(h.sends.length, equals(3));
        expect(h.pathResets, equals(1), reason: 'attempt 2 floods');
        expect(h.lastUpdate!.pathLength, equals(-1));
      });
    });

    test('floodFirst floods attempt 0 even with a known route', () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(
          publicKey: recipientKey,
          pathLength: 2,
          path: const [0x10, 0x20],
        );

        h.retryService.sendMessageWithRetry(
          contact: contact,
          text: text,
          floodFirst: true,
        );
        async.flushMicrotasks();

        expect(h.sends.length, equals(1));
        expect(h.pathResets, equals(1));
        expect(h.lastUpdate!.pathLength, equals(-1));
      });
    });

    test('an ACK for an earlier attempt delivers while a retry is pending',
        () {
      fakeAsync((async) {
        final h = _Harness();
        final contact = _makeContact(publicKey: recipientKey);

        h.retryService.sendMessageWithRetry(contact: contact, text: text);
        async.flushMicrotasks();
        h.sent(text);
        async.elapse(const Duration(milliseconds: retryGap));
        h.sent(text);
        expect(h.sends.length, equals(2));

        h.retryService.handleAckReceived(h.ackHashFor(0, text), 9000);

        expect(h.lastUpdate!.status, equals(MessageStatus.delivered));
        expect(h.lastUpdate!.retryCount, equals(0));
        expect(h.lastUpdate!.deliveredLate, isFalse);
        async.elapse(const Duration(minutes: 10));
        expect(h.sends.length, equals(2), reason: 'no further attempts');
        expect(h.retryService.hasPendingMessages, isFalse);
      });
    });
  });
}
