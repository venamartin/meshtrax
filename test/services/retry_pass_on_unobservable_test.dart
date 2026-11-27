import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// #117: no false Retrying or Failed on a send whose echo can never be seen;
// the flood echo watch arms only when the repeated packet fits the RX log,
// which carries 173 bytes of packet at most. #384's pass-on watch for routed
// tries takes the same check (regression audit, 2026-11-27).

const _timeoutMs = 20000;
const _airtimeMs = 600;

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 26),
);

// Five repeaters: the first one's copy still has four to go (8 bytes).
final _far = PathSelection(
  pathBytes: const [0xA2, 0x77, 0xBE, 0xEF, 0xA4, 0x77, 0x10, 0x00, 0xE8, 0xC5],
  hopCount: 5,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.6,
);

void main() {
  group('isRoutedCopyObservable', () {
    test('a 150-byte text: seen with 4 repeaters still to go, not with 8', () {
      final text = 'x' * 150;
      // Header, path length, the hops to go, dest, src, MAC, 160 bytes of
      // ciphertext: 172 bytes with 6 path bytes, 174 with 8.
      expect(isRoutedCopyObservable(text, 6), isTrue);
      expect(isRoutedCopyObservable(text, 8), isFalse);
    });

    test('from attempt 4 the two hidden attempt bytes count', () {
      final text = 'x' * 139; // 144 bytes of plaintext fill 9 blocks exactly
      expect(isRoutedCopyObservable(text, 8), isTrue);
      expect(isRoutedCopyObservable(text, 8, attempt: 4), isFalse);
    });
  });

  test("a 150-byte DM on a five-repeater route: the first repeater's copy "
      'cannot reach the RX log, so its silence neither ends the try early '
      'nor counts against my doorstep', () {
    final text = 'x' * 150;
    fakeAsync((async) {
      final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
      final svc = MessageRetryService(
          clock: () => DateTime(2026, 11, 26).add(async.elapsed));
      final sends = <({int attempt, int ts})>[];
      final reported = <({bool delivered, int? hopsHeard})>[];
      svc.initialize(RetryServiceConfig(
        sendMessage: (_, t, attempt, ts) =>
            sends.add((attempt: attempt, ts: ts)),
        addMessage: (_, _) {},
        updateMessage: (_) {},
        clearContactPath: (_) {},
        setContactPath: (_, _, _, _) {},
        calculateTimeout: (_, _, {contact}) => _timeoutMs,
        getSelfPublicKey: () => selfKey,
        pathHashByteWidth: () => 2,
        estimateAirtime: (_) => _airtimeMs,
        graphRoutes: (_) => [_far],
        hearsPassOnBy: (_, _) => true, // A277 was heard a minute ago
        onAttemptResult: (_, sel, delivered, _, hopsHeard) =>
            reported.add((delivered: delivered, hopsHeard: hopsHeard)),
      ));
      svc.setMaxRetries(5);
      svc.sendMessageWithRetry(contact: _bob, text: text);
      async.flushMicrotasks();
      int ack(int i) => MessageRetryService.computeExpectedAckHash(
          sends[i].ts, sends[i].attempt, text, selfKey);
      svc.updateMessageFromSent(ack(0), 0, isFlood: false);
      final wait = TimeoutHelper.passOnWaitMs(_airtimeMs);
      async.elapse(Duration(milliseconds: 2 * wait + 2));
      async.flushMicrotasks();
      expect(sends, hasLength(1), reason: 'no second copy');
      expect(reported, isEmpty,
          reason: 'nothing could be heard, so nothing is judged before the '
              'ACK wait ends');
    });
  });
}
