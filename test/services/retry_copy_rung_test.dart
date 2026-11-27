import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// A parked try goes out again under a new attempt number, above the
// ladder's, so the repeaters that heard the first copy don't drop it. When
// the radio learned a route meanwhile, that resend goes out routed, and a
// repeater's copy of it then carries the resend's number. The copy belongs
// to the try that sent it, not to the try with that number (regression
// audit, 2026-11-27).

const _timeoutMs = 20000;
const _airtimeMs = 564;

final _home = PathSelection(
  pathBytes: const [0xA2, 0x77, 0xAA, 0x77],
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.6,
);

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 26),
);

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('a routed resend\'s copy is filed under the try that sent it', () {
    fakeAsync((async) {
      var routes = const <PathSelection>[];
      final sends = <({int attempt, int ts, String text})>[];
      final proofs = <String>[];
      late final MessageRetryService svc;
      svc = MessageRetryService(
          clock: () => DateTime(2026, 11, 26).add(async.elapsed))
        ..initialize(RetryServiceConfig(
          sendMessage: (contact, text, attempt, ts) async {
            // As the connector does when the radio stored a route while the
            // try waited: the try is planned again on it.
            svc.rechooseRoute(contact, ts, text);
            sends.add((attempt: attempt, ts: ts, text: text));
          },
          addMessage: (_, _) {},
          updateMessage: (_) {},
          clearContactPath: (_) {},
          setContactPath: (_, _, _, _) {},
          calculateTimeout: (_, _, {contact}) => _timeoutMs,
          getSelfPublicKey: () =>
              Uint8List.fromList(List.generate(32, (i) => 0x42 + i)),
          pathHashByteWidth: () => 2,
          estimateAirtime: (_) => _airtimeMs,
          graphRoutes: (_) => routes,
          hearsPassOnBy: (_, _) => true,
          onPassedOn: (_, sel) => proofs.add(_hex(sel.pathBytes)),
        ))
        ..setMaxRetries(3);

      // A repeater was heard two minutes ago: no quick resend, a park.
      svc.noteRepeaterHeard();
      async.elapse(const Duration(minutes: 2));
      svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      expect(sends, hasLength(1));
      svc.updateMessageFromSent(
          MessageRetryService.computeExpectedAckHash(
              sends[0].ts, sends[0].attempt, 'hi',
              Uint8List.fromList(List.generate(32, (i) => 0x42 + i))),
          0,
          isFlood: true);
      async.elapse(Duration(
          milliseconds: TimeoutHelper.echoWaitMs(_airtimeMs, _timeoutMs) + 1));
      // Parked. The radio learns a route to Bob; then a repeater is heard.
      routes = [_home];
      async.elapse(
          const Duration(milliseconds: MessageRetryService.repeaterCooldownMs));
      svc.noteRepeaterHeard();
      async.flushMicrotasks();
      expect(sends, hasLength(2));
      final resend = sends[1];
      expect(resend.attempt, greaterThan(2),
          reason: 'a resend goes out under a number above the ladder');

      // Its first repeater, A277, is heard passing it on.
      svc.noteOwnCopy(_bob.publicKeyHex, resend.ts, resend.attempt,
          utf8.encode('hi'), const [0xAA, 0x77], 2);
      expect(proofs, [_hex(_home.pathBytes)]);
    });
  });
}
