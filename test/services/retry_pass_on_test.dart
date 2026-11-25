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
  _Rig({int budget = 5, DateTime Function()? clock})
      : svc = MessageRetryService(clock: clock) {
    svc.initialize(RetryServiceConfig(
      // As the connector does: wait for a quiet radio, then send only a
      // copy that is still wanted.
      sendMessage: (_, text, attempt, ts) async {
        if (quietWait > Duration.zero) await Future<void>.delayed(quietWait);
        if (!svc.awaitsAck(_bob.publicKeyHex, ts, text, attempt)) {
          skipped++;
          return;
        }
        sends.add((text: text, attempt: attempt, ts: ts));
      },
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) => kinds.add('flood'),
      setContactPath: (_, bytes, _, _) {
        written.add(_hex(bytes));
        kinds.add(_hex(bytes));
      },
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
  Duration quietWait = Duration.zero;
  int skipped = 0;
  List<PathSelection> routes = [_home];
  final asked = <String>[];
  final sends = <({String text, int attempt, int ts})>[];
  final written = <String>[];
  // What each send went out as: its route, or a flood.
  final kinds = <String>[];
  final proofs = <String>[];
  final reported = <({String route, bool delivered, int? hopsHeard})>[];
  final MessageRetryService svc;

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  void sentLast({bool flood = false}) =>
      svc.updateMessageFromSent(ackFor(sends.length - 1), 0, isFlood: flood);

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

  // Simulator, 2026-11-24: a message came in as the try went out, so the
  // second copy waited five seconds for a quiet radio. The try's ACK wait
  // ran out first, on one copy, and the copy then went out as the next try.
  test('the second copy waits for a quiet radio: the try waits with it', () {
    fakeAsync((async) {
      final r = start(async)..quietWait = const Duration(seconds: 12);
      async.elapse(_wait);
      async.elapse(const Duration(seconds: 11));
      expect(r.sends, hasLength(1));
      expect(r.reported, isEmpty, reason: 'the try is not over on one copy');

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(r.sends, hasLength(2));
      expect(r.sends[1], r.sends[0]);
      r.quietWait = Duration.zero;
      r.sentLast();
      r.copyOf(1, _afterA277);
      async.elapse(const Duration(milliseconds: _timeoutMs - 100));
      expect(r.reported, isEmpty, reason: 'its ACK wait starts with the copy');
    });
  });

  test('a copy still waiting when its try ends is not sent: it would pass '
      'for the next try, and one unheard copy says nothing', () {
    fakeAsync((async) {
      final r = start(async)..quietWait = const Duration(seconds: 19);
      async.elapse(_wait);
      // The radio never takes the copy: the try ends on its safety timer.
      async.elapse(const Duration(seconds: 15));
      expect(r.reported, isEmpty);
      r.quietWait = Duration.zero;

      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(r.skipped, 1, reason: 'the copy came out of its wait too late');
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(r.sends.map((s) => s.attempt), [0, 1]);
    });
  });

  group('the next route ends at another repeater', () {
    const elsewhere = PathSelection(
      pathBytes: [0xA2, 0x77, 0xC0, 0xDE],
      hopCount: 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.3,
    );

    _Rig begin(FakeAsync async) {
      final r = _Rig()..routes = [_home, elsewhere];
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      r.sentLast();
      return r;
    }

    void nextTry(FakeAsync async) {
      async.elapse(
          const Duration(milliseconds: MessageRetryService.retryBackoffMs));
      async.flushMicrotasks();
    }

    test('heard passed on and no ACK: the route was tried, the other '
        'repeater is next', () {
      fakeAsync((async) {
        final r = begin(async);
        r.copyOf(0, _afterA277);
        async.elapse(const Duration(milliseconds: _timeoutMs + 1));
        nextTry(async);
        expect(r.written.last, _hex(elsewhere.pathBytes));
      });
    });

    test('not heard passing on either copy: nothing of the route was tried, '
        'so it is next again', () {
      fakeAsync((async) {
        final r = begin(async);
        async.elapse(_wait);
        async.flushMicrotasks();
        r.sentLast();
        async.elapse(_wait);
        nextTry(async);
        expect(r.sends, hasLength(3));
        expect(r.written.last, _hex(_home.pathBytes));
      });
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

  // Simulator, 2026-11-24: a contact who had moved and sent nothing kept
  // the old way back to this radio, so no routed DM to them was ever
  // answered (0 of 60); only floods were. Three routes were tried before
  // every flood, and a DM took twice as long as on the code before.
  group('routed tries to a contact keep going unanswered', () {
    final second = _route([0xA2, 0x77, 0xBE, 0xEF, 0xAA, 0x77]);
    final home = _hex(_home.pathBytes);
    final other = _hex(second.pathBytes);

    void send(_Rig r, FakeAsync async, String text) {
      r.svc.sendMessageWithRetry(contact: _bob, text: text);
      async.flushMicrotasks();
    }

    /// The try in flight gets no ACK, and the next one goes out.
    void fail(_Rig r, FakeAsync async) {
      r.sentLast();
      async.elapse(const Duration(milliseconds: _timeoutMs + 1));
      async.elapse(
          const Duration(milliseconds: MessageRetryService.retryBackoffMs));
      async.flushMicrotasks();
    }

    void deliver(_Rig r, FakeAsync async, {bool flood = false}) {
      r.sentLast(flood: flood);
      r.svc.handleAckReceived(r.ackFor(r.sends.length - 1), 1500);
      async.flushMicrotasks();
    }

    /// Three routed tries of one message unanswered, then its flood got
    /// through. Nobody could be listened for.
    _Rig threeUnanswered(FakeAsync async, {DateTime Function()? clock}) {
      final r = _Rig(clock: clock)
        ..hears = false
        ..routes = [_home, second];
      send(r, async, 'one');
      fail(r, async);
      fail(r, async);
      fail(r, async);
      deliver(r, async, flood: true);
      expect(r.kinds, [home, home, other, 'flood']);
      r.kinds.clear();
      return r;
    }

    test('three in a row: the next message tries only the best route (twice, '
        'being a likely one), then floods', () {
      fakeAsync((async) {
        final r = threeUnanswered(async);
        send(r, async, 'two');
        fail(r, async);
        fail(r, async);
        deliver(r, async, flood: true);
        expect(r.kinds, [home, home, 'flood']);
      });
    });

    test('a best route that is unlikely to work gets its one try, then '
        'floods', () {
      fakeAsync((async) {
        PathSelection weak(List<int> bytes, double est) => PathSelection(
              pathBytes: bytes,
              hopCount: bytes.length ~/ 2,
              hashSize: 2,
              useFlood: false,
              source: RouteSource.graph,
              estDelivery: est,
            );
        final w1 = weak([0xA2, 0x77, 0x88, 0xA9, 0xFD, 0x33], 0.2);
        final w2 = weak([0xA2, 0x77, 0xBE, 0xEF, 0xFD, 0x33], 0.15);
        final w3 = weak([0xA2, 0x77, 0x10, 0x00, 0xFD, 0x33], 0.1);
        final r = _Rig()
          ..hears = false
          ..routes = [w1, w2, w3];
        send(r, async, 'one');
        fail(r, async);
        fail(r, async);
        fail(r, async);
        deliver(r, async, flood: true);
        expect(r.kinds, [
          _hex(w1.pathBytes),
          _hex(w2.pathBytes),
          _hex(w3.pathBytes),
          'flood',
        ]);

        r.kinds.clear();
        send(r, async, 'two');
        fail(r, async);
        deliver(r, async, flood: true);
        expect(r.kinds, [_hex(w1.pathBytes), 'flood']);
      });
    });

    test('one routed try answered, and the other routes are tried again', () {
      fakeAsync((async) {
        final r = threeUnanswered(async);
        send(r, async, 'two');
        deliver(r, async);
        r.kinds.clear();

        send(r, async, 'three');
        fail(r, async);
        fail(r, async);
        expect(r.kinds, [home, home, other]);
      });
    });

    test('tries that never left my own repeater are not counted', () {
      fakeAsync((async) {
        final r = _Rig()..routes = [_home, second];
        send(r, async, 'one');
        for (var i = 0; i < 3; i++) {
          r.sentLast();
          async.elapse(_wait);
          async.flushMicrotasks();
          r.sentLast();
          async.elapse(_wait);
          async.elapse(
              const Duration(milliseconds: MessageRetryService.retryBackoffMs));
          async.flushMicrotasks();
        }
        deliver(r, async, flood: true);
        expect(r.kinds.last, 'flood');

        r
          ..hears = false
          ..kinds.clear();
        send(r, async, 'two');
        fail(r, async);
        fail(r, async);
        expect(r.kinds, [home, home, other]);
      });
    });

    test('an hour later it is forgotten', () {
      fakeAsync((async) {
        var now = DateTime(2026, 11, 24, 12);
        final r = threeUnanswered(async, clock: () => now);
        now = now.add(const Duration(minutes: 61));
        send(r, async, 'two');
        fail(r, async);
        fail(r, async);
        expect(r.kinds, [home, home, other]);
      });
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
