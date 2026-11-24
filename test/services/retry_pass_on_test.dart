import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Field 2026-11-24: a routed DM whose ACK did not come was waited out in
// full, then the next try went out as a flood, although the repeater 30 m
// away had most likely never got the packet (two radios sending at once).
// The radio hears its first repeater pass a routed packet on. Not heard,
// the same packet goes out once more: a repeater that did pass the first on
// drops the second, one that missed it passes it on now.

PathSelection _route(List<int> bytes) => PathSelection(
      pathBytes: bytes,
      hopCount: bytes.length ~/ 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.6,
    );

final _home = _route([0xA2, 0x77, 0xAA, 0x77]);
const _afterA277 = [0xAA, 0x77];
const _timeoutMs = 9000;
const _airtimeMs = 300;
final _wait = Duration(milliseconds: TimeoutHelper.passOnWaitMs(_airtimeMs) + 1);

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

class _Rig {
  _Rig({int budget = 5}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) {},
      setContactPath: (_, bytes, _, _) => written.add(_hex(bytes)),
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      estimateAirtime: (_) => _airtimeMs,
      graphRoutes: (_) => routes,
      hearsPassOnBy: (hop, width) {
        asked.add(_hex(hop));
        return hears;
      },
      onPassedOn: (_, sel) => proofs.add(_hex(sel.pathBytes)),
      onAttemptResult: (_, sel, delivered, _, hopsHeard) => reported.add((
        route: sel.useFlood ? 'flood' : _hex(sel.pathBytes),
        delivered: delivered,
        hopsHeard: hopsHeard,
      )),
    ));
    svc.setMaxRetries(budget);
  }

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  bool hears = true;
  List<PathSelection> routes = [_home];
  final asked = <String>[];
  final sends = <({String text, int attempt, int ts})>[];
  final written = <String>[];
  final proofs = <String>[];
  final reported = <({String route, bool delivered, int? hopsHeard})>[];
  final svc = MessageRetryService();

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  void sentLast() => svc.updateMessageFromSent(ackFor(sends.length - 1), 0,
      isFlood: false);

  /// A repeater's copy of send [i], heard with [hopsLeft] still to go.
  void copyOf(int i, List<int> hopsLeft, {String? text}) => svc.noteOwnCopy(
      _bob.publicKeyHex,
      sends[i].ts,
      sends[i].attempt,
      utf8.encode(text ?? sends[i].text),
      hopsLeft,
      2);
}

final _bob = Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
  name: 'Bob',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 11, 24),
);

void main() {
  _Rig start(FakeAsync async, {bool hears = true, int budget = 5}) {
    final r = _Rig(budget: budget)..hears = hears;
    r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
    async.flushMicrotasks();
    r.sentLast();
    return r;
  }

  test('heard passed on: one copy is enough, and the wait for the ACK runs on',
      () {
    fakeAsync((async) {
      final r = start(async);
      expect(r.asked, ['a277'], reason: 'the first repeater of the route');
      async.elapse(const Duration(milliseconds: 900));
      r.copyOf(0, _afterA277);
      expect(r.proofs, [_hex(_home.pathBytes)]);

      async.elapse(_wait);
      expect(r.sends, hasLength(1));
      expect(r.reported, isEmpty);

      async.elapse(const Duration(milliseconds: _timeoutMs));
      expect(r.reported, [
        (route: _hex(_home.pathBytes), delivered: false, hopsHeard: 1),
      ]);
    });
  });

  test('not heard: the same packet goes out once more, under the same number',
      () {
    fakeAsync((async) {
      final r = start(async);
      async.elapse(_wait);
      async.flushMicrotasks();
      expect(r.sends, hasLength(2));
      expect(r.sends[1], r.sends[0], reason: 'the same packet, bit for bit');
      expect(r.reported, isEmpty, reason: 'the try is still running');
    });
  });

  test('the second copy is heard passed on: the try gets its full wait from '
      'there', () {
    fakeAsync((async) {
      final r = start(async);
      async.elapse(_wait);
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(const Duration(milliseconds: 800));
      r.copyOf(1, _afterA277);

      async.elapse(const Duration(milliseconds: _timeoutMs - 900));
      expect(r.reported, isEmpty, reason: 'counted from the second copy');
      async.elapse(const Duration(milliseconds: 200));
      expect(r.reported.single.hopsHeard, 1);
      expect(r.sends, hasLength(2), reason: 'never a third copy');
    });
  });

  test('not heard twice: the try is over at once, and the next goes out after '
      'the usual pause', () {
    fakeAsync((async) {
      final r = start(async);
      async.elapse(_wait);
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(_wait);
      expect(r.reported, [
        (route: _hex(_home.pathBytes), delivered: false, hopsHeard: 0),
      ]);
      expect(r.sends, hasLength(2));

      async.elapse(
          const Duration(milliseconds: MessageRetryService.retryBackoffMs));
      async.flushMicrotasks();
      expect(r.sends, hasLength(3));
      expect(r.sends[2].attempt, 1, reason: 'a new try, a new packet');
    });
  });

  test('the last try keeps its whole wait, heard or not: nothing follows '
      'that could use the time', () {
    fakeAsync((async) {
      final r = start(async, budget: 1);
      async.elapse(_wait);
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(_wait);
      expect(r.sends, hasLength(2), reason: 'the same packet once more');
      expect(r.reported, isEmpty, reason: 'still waiting for its ACK');

      async.elapse(const Duration(milliseconds: _timeoutMs));
      expect(r.reported.single.hopsHeard, 0);
    });
  });

  test('its ACK still counts after the try was called over', () {
    fakeAsync((async) {
      final r = start(async);
      async.elapse(_wait);
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(_wait);
      r.svc.handleAckReceived(r.ackFor(0), 6000);
      async.flushMicrotasks();
      expect(r.reported.last.delivered, isTrue);
      async.elapse(const Duration(seconds: 30));
      expect(r.sends, hasLength(2), reason: 'delivered: no further try');
    });
  });

  test('the last repeater heard too: two hops carried it, proved once', () {
    fakeAsync((async) {
      final r = start(async);
      r.copyOf(0, _afterA277);
      r.copyOf(0, const []);
      r.copyOf(0, _afterA277);
      expect(r.proofs, hasLength(1));
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      expect(r.reported.single.hopsHeard, 2);
    });
  });

  test('only the last repeater heard: the first heard this radio all the same',
      () {
    fakeAsync((async) {
      final r = start(async);
      r.copyOf(0, const []);
      expect(r.proofs, hasLength(1));
      async.elapse(_wait);
      expect(r.sends, hasLength(1));
    });
  });

  test('a repeater not heard lately is not listened for', () {
    fakeAsync((async) {
      final r = start(async, hears: false);
      async.elapse(_wait);
      async.flushMicrotasks();
      expect(r.sends, hasLength(1));
      async.elapse(const Duration(milliseconds: _timeoutMs));
      expect(r.reported.single.hopsHeard, isNull);
    });
  });

  test('a route of 1-byte codes is not listened for: too many repeaters '
      'share one', () {
    fakeAsync((async) {
      final r = _Rig()
        ..routes = [
          const PathSelection(
            pathBytes: [0xA2, 0xAA],
            hopCount: 2,
            hashSize: 1,
            useFlood: false,
            source: RouteSource.graph,
            estDelivery: 0.6,
          ),
        ];
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      async.elapse(_wait);
      async.flushMicrotasks();
      expect(r.asked, isEmpty);
      expect(r.sends, hasLength(1));
    });
  });

  test('a copy that is not this try is not counted', () {
    fakeAsync((async) {
      final r = start(async);
      r.copyOf(0, const [0xBE, 0xEF]); // not the rest of its route
      r.copyOf(0, _home.pathBytes); // nobody has passed it on yet
      r.copyOf(0, _afterA277, text: 'ho'); // another text
      r.svc.noteOwnCopy(_bob.publicKeyHex, r.sends[0].ts + 1,
          r.sends[0].attempt, utf8.encode('hi'), _afterA277, 2);
      r.svc.noteOwnCopy(_bob.publicKeyHex, r.sends[0].ts, 1,
          utf8.encode('hi'), _afterA277, 2);
      r.svc.noteOwnCopy(_bob.publicKeyHex, r.sends[0].ts, r.sends[0].attempt,
          utf8.encode('hi'), const [0x77], 1);
      expect(r.proofs, isEmpty);
      async.elapse(_wait);
      async.flushMicrotasks();
      expect(r.sends, hasLength(2));
    });
  });

  test('a delivered try says whether its first repeater was heard', () {
    fakeAsync((async) {
      final r = start(async);
      r.copyOf(0, _afterA277);
      r.svc.handleAckReceived(r.ackFor(0), 1500);
      async.flushMicrotasks();
      expect(r.reported, [
        (route: _hex(_home.pathBytes), delivered: true, hopsHeard: 1),
      ]);
    });
  });
}
