import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// The retry ladder follows the user's route choice when it changes while a
// message is still being sent (as master's resolve-at-each-attempt did),
// keeps Pathfinder's planned length, and reports to Pathfinder only the
// attempts that actually went on the air.

const _g1 = PathSelection(
  pathBytes: [0xA2, 0x77, 0x10, 0xAA],
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.8,
);
const _f = [0xBE, 0x41, 0x10, 0xAA];
const _custom = [0x33, 0x33];
const _timeoutMs = 2000;
const _gap = _timeoutMs + MessageRetryService.retryBackoffMs;

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

class _Rig {
  _Rig({List<PathSelection>? graph, required int budget}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) => sends
          .add((text: text, attempt: attempt, ts: ts, onAir: radioPath)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) => radioPath = null,
      setContactPath: (_, bytes, _, _) {
        written.add(_hex(bytes));
        radioPath = _hex(bytes);
      },
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      graphRoutes: graph == null ? null : (_) => graph,
      onAttemptResult: (_, sel, delivered, _) => reported.add((
        bytes: sel.useFlood ? 'flood' : _hex(sel.pathBytes),
        delivered: delivered,
      )),
    ));
    svc.setMaxRetries(budget);
  }

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  // The radio's stored out_path for Bob; null = none (it floods).
  String? radioPath = _hex(_f);
  final sends = <({String text, int attempt, int ts, String? onAir})>[];
  final written = <String>[];
  final reported = <({String bytes, bool delivered})>[];
  final svc = MessageRetryService();

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  void sentLast() => svc.updateMessageFromSent(ackFor(sends.length - 1), 0);

  /// The current attempt times out and the next one goes out.
  void nextAttempt(FakeAsync async, {bool sent = true}) {
    async.elapse(const Duration(milliseconds: _gap));
    async.flushMicrotasks();
    if (sent) sentLast();
  }
}

Contact _bob({int? override, List<int>? overrideBytes}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
      name: 'Bob',
      type: 1,
      pathLength: 2,
      path: Uint8List.fromList(_f),
      pathHashSize: 2,
      pathOverride: override,
      pathOverrideBytes:
          overrideBytes == null ? null : Uint8List.fromList(overrideBytes),
      pathOverrideHashSize: overrideBytes == null ? null : 2,
      lastSeen: DateTime(2026, 10, 14),
    );

void main() {
  group('a route choice changed mid-send', () {
    test('Custom, then Always flood: the next attempt floods', () {
      fakeAsync((async) {
        final r = _Rig(budget: 4); // Pathfinder off
        r.svc.sendMessageWithRetry(
            contact: _bob(override: 1, overrideBytes: _custom), text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        expect(r.sends[0].onAir, _hex(_custom));

        r.svc.updatePendingContact(_bob(override: -1));
        r.written.clear();
        r.nextAttempt(async);
        expect(r.sends[1].onAir, isNull, reason: 'the route was cleared');
        expect(r.written, isEmpty,
            reason: 'the removed Custom route is never written back');
      });
    });

    test('Pathfinder ladder, then a Custom route: no graph route is written '
        'again', () {
      fakeAsync((async) {
        final r = _Rig(graph: const [_g1], budget: 4);
        r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        expect(r.sends[0].onAir, _hex(_g1.pathBytes));

        r.svc.updatePendingContact(_bob(override: 1, overrideBytes: _custom));
        r.written.clear();
        r.nextAttempt(async);
        expect(r.sends[1].onAir, _hex(_custom));
        r.nextAttempt(async);
        r.nextAttempt(async);
        expect(r.written, isNot(contains(_hex(_g1.pathBytes))));
      });
    });

    test('Pathfinder off: each attempt reads the live contact, as on master',
        () {
      fakeAsync((async) {
        final r = _Rig(budget: 4); // two route tries, then floods
        r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        expect(r.sends[0].onAir, _hex(_f), reason: 'the radio\'s own route');

        r.svc.updatePendingContact(_bob(override: 1, overrideBytes: _custom));
        r.nextAttempt(async);
        r.nextAttempt(async);
        r.nextAttempt(async);
        expect([for (final s in r.sends) s.onAir],
            [_hex(_f), _hex(_custom), null, null]);
      });
    });
  });

  test('Pathfinder\'s ladder keeps its planned length when the setting moves',
      () {
    fakeAsync((async) {
      final r = _Rig(graph: const [_g1], budget: 4);
      r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      r.svc.setMaxRetries(2);
      for (var i = 0; i < 5; i++) {
        r.nextAttempt(async);
      }
      expect([for (final s in r.sends) s.onAir],
          [_hex(_g1.pathBytes), null, null, null],
          reason: 'the planned four attempts, ending on the planned floods');
    });
  });

  group('only attempts that went on the air count as failures', () {
    test('an attempt the radio never accepted is not held against its route',
        () {
      fakeAsync((async) {
        final g2 = PathSelection(
            pathBytes: const [0xAD, 0x77, 0x10, 0xAA],
            hopCount: 2,
            hashSize: 2,
            useFlood: false,
            source: RouteSource.graph,
            estDelivery: 0.6);
        final r = _Rig(graph: [_g1, g2], budget: 4);
        r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
        async.flushMicrotasks();
        // No SENT: the link dropped. The 15 s safety timer moves on.
        async.elapse(const Duration(
            milliseconds: 15000 + MessageRetryService.retryBackoffMs + 100));
        async.flushMicrotasks();
        r.sentLast();
        r.svc.handleAckReceived(r.ackFor(1), 900);
        expect(r.reported, [(bytes: _hex(g2.pathBytes), delivered: true)]);
      });
    });

    test('an attempt that went out and timed out is reported failed', () {
      fakeAsync((async) {
        final r = _Rig(graph: const [_g1], budget: 4);
        r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
        async.flushMicrotasks();
        r.sentLast();
        r.nextAttempt(async);
        r.svc.handleAckReceived(r.ackFor(1), 900);
        expect(r.reported, [(bytes: _hex(_g1.pathBytes), delivered: false)]);
      });
    });

    test('a message that never reached the air reports nothing', () {
      fakeAsync((async) {
        final r = _Rig(graph: const [_g1], budget: 2);
        r.svc.sendMessageWithRetry(contact: _bob(), text: 'hi');
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 40));
        async.elapse(MessageRetryService.lateAckGrace);
        async.flushMicrotasks();
        expect(r.reported, isEmpty);
      });
    });
  });
}
