import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/dm_measure_log.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// The measurement lines for the weeks of measuring: one fixed, versioned
// format; contacts by the first two bytes of their key, areas as a hash
// keyed with the phone's own secret, never a name, a message or the area
// key itself (owner, 2026-10-25).

const _area = 'c8463_-27186';

void main() {
  group('MeasureLog', () {
    test('a line: the version, the kind, and the fields that are known', () {
      final lines = <String>[];
      MeasureLog(write: lines.add)
          .line('try', {'c': 'AABB', 'n': 2, 'est': 0.666, 'live': null});
      expect(lines, ['M1 try c=AABB n=2 est=0.67']);
    });

    test('a contact is the first two bytes of its key', () {
      expect(MeasureLog.contact('aabbccdd'), 'AABB');
    });

    test('an area is a keyed hash: the same on one phone, another on the '
        'next, never the key, and none without a secret', () {
      String? hash(String? salt, String? key) =>
          MeasureLog(write: (_) {}, areaKey: () => key, salt: () => salt).area();
      final mine = hash('secret one', _area);
      expect(mine, matches(RegExp(r'^[0-9A-F]{8}$')));
      expect(hash('secret one', _area), mine);
      expect(hash('secret two', _area), isNot(mine));
      expect(hash(null, _area), isNull);
      expect(hash('secret one', null), isNull);
      expect(mine, isNot(contains('8463')));
    });

    test('who this radio heard: one line per repeater and way, each hour and '
        'area, with the mean level', () {
      final lines = <String>[];
      var now = DateTime.utc(2026, 11, 27, 21, 10);
      var area = _area;
      final log = MeasureLog(
          write: lines.add,
          areaKey: () => area,
          salt: () => 'secret',
          clock: () => now);
      log.noteHeard('BEEF', 6, from: 'flood');
      log.noteHeard('BEEF', 4, from: 'flood');
      log.noteHeard('A277', -3, from: 'advert');
      expect(lines, isEmpty, reason: 'counted until the hour is over');
      now = now.add(const Duration(hours: 1));
      log.noteHeard('BEEF', 5, from: 'flood');
      expect(lines, hasLength(2));
      expect(lines[0], startsWith('M1 hear a='));
      expect(lines[0], endsWith('r=A277 from=advert n=1 db=-3.00'));
      expect(lines[1], endsWith('r=BEEF from=flood n=2 db=5.00'));
      expect(lines[1], contains('hour='));
      area = 'c8464_-27186'; // moved to the next area
      log.noteHeard('BEEF', 5, from: 'flood');
      expect(lines, hasLength(3), reason: 'the hour so far is written first');
      log.flushHeard();
      expect(lines, hasLength(4));
      expect(lines.any((l) => l.contains('8463') || l.contains('8464')),
          isFalse);
    });
  });

  group('the retry service', () {
    final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
    final bob = Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
      name: 'Bob',
      type: 1,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime(2026, 11, 26),
    );
    const route = PathSelection(
      pathBytes: [0xA2, 0x77, 0xAA, 0x77],
      hopCount: 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.66,
    );

    test('a DM writes its try, its ACK and its end, by key and never by name '
        'or text', () {
      fakeAsync((async) {
        final lines = <String>[];
        final sends = <({int attempt, int ts})>[];
        // The service's own clock, like the DM's stamp: the seconds in the
        // end line count from the send.
        final svc = MessageRetryService();
        svc.initialize(RetryServiceConfig(
          sendMessage: (_, _, attempt, ts) async =>
              sends.add((attempt: attempt, ts: ts)),
          addMessage: (_, _) {},
          updateMessage: (_) {},
          clearContactPath: (_) {},
          setContactPath: (_, _, _, _) {},
          calculateTimeout: (_, _, {contact}) => 20000,
          getSelfPublicKey: () => selfKey,
          pathHashByteWidth: () => 2,
          estimateAirtime: (_) => 564,
          graphRoutes: (_) => const [route],
          hearsPassOnBy: (_, _) => true,
          measureLog: MeasureLog(
              write: lines.add,
              areaKey: () => _area,
              salt: () => 'secret'),
        ));
        svc.setMaxRetries(4);
        svc.sendMessageWithRetry(contact: bob, text: 'meet at the cabin');
        async.flushMicrotasks();
        final ack = MessageRetryService.computeExpectedAckHash(
            sends[0].ts, sends[0].attempt, 'meet at the cabin', selfKey);
        svc.updateMessageFromSent(ack, 20000, isFlood: false);
        // The first repeater, A277, passes it on.
        svc.noteOwnCopy(bob.publicKeyHex, sends[0].ts, 0,
            'meet at the cabin'.codeUnits, const [0xAA, 0x77], 2);
        async.elapse(const Duration(seconds: 3));
        svc.handleAckReceived(ack, 2400);
        async.flushMicrotasks();

        final hex = ack.toRadixString(16).padLeft(8, '0');
        expect(lines, [
          matches(RegExp('^M1 try c=AAAB ts=${sends[0].ts} n=1 of=4 '
              'r=A277,AA77 w=2 by=best est=0.66 h=$hex a=[0-9A-F]{8}\$')),
          matches(RegExp('^M1 out c=AAAB ts=${sends[0].ts} n=1 r=A277 w=2 '
              'hops=1 of=2 a=[0-9A-F]{8}\$')),
          'M1 ack h=$hex c=AAAB ts=${sends[0].ts} n=1 ms=2400',
          matches(RegExp('^M1 end c=AAAB ts=${sends[0].ts} ok=1 on=1 of=4 '
              r'sent=1 s=\d+$')),
        ]);
        expect(
            lines.any((l) =>
                l.contains('Bob') || l.contains('cabin') || l.contains('8463')),
            isFalse);
      });
    });
  });
}
