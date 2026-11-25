import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// Owner, 2026-11-24: somewhere with no record of who hears the radio, one
// Discover goes out before the DM, and the DM then goes by the repeater that
// answered. The retry service only gives Pathfinder the moment it asks for,
// and plans the ladder again when it is over.

final _viaF5ee = PathSelection(
  pathBytes: const [0xF5, 0xEE, 0xAA, 0x77],
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
  lastSeen: DateTime(2026, 11, 24),
);

class _Rig {
  _Rig({required this.wait}) {
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) => sends.add(onRadio),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) => onRadio = 'flood',
      setContactPath: (_, bytes, _, _) => onRadio =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      calculateTimeout: (_, _, {contact}) => 9000,
      getSelfPublicKey: () =>
          Uint8List.fromList(List.generate(32, (i) => 0x42 + i)),
      pathHashByteWidth: () => 2,
      graphRoutes: (_) => routes,
      beforeFirstAttempt: (_) {
        asked++;
        return wait;
      },
    ));
    svc.setMaxRetries(3);
  }

  final Future<void>? wait;
  int asked = 0;
  // Nobody is known to hear the radio here: Pathfinder would flood.
  List<PathSelection> routes = const [];
  String onRadio = '';
  final sends = <String>[];
  final svc = MessageRetryService();
}

void main() {
  test('no moment asked for: the DM goes at once', () {
    fakeAsync((async) {
      final r = _Rig(wait: null);
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.flushMicrotasks();
      expect(r.asked, 1);
      expect(r.sends, ['flood']);
    });
  });

  test('a moment asked for: nothing goes out until it is over, and then the '
      'DM goes by the route the answers gave', () {
    fakeAsync((async) {
      final r = _Rig(wait: Future<void>.delayed(const Duration(seconds: 5)));
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.elapse(const Duration(seconds: 4));
      expect(r.sends, isEmpty);
      expect(r.svc.isSendingTo(_bob.publicKeyHex), isTrue,
          reason: 'a later DM to them waits behind it');

      // F5EE answered the Discover: Pathfinder has a route now.
      r.routes = [_viaF5ee];
      async.elapse(const Duration(seconds: 2));
      expect(r.sends, ['f5eeaa77']);
    });
  });

  test('a moment that ends in an error still sends the DM', () {
    fakeAsync((async) {
      final r = _Rig(
          wait: Future<void>.delayed(const Duration(seconds: 1))
              .then((_) => throw StateError('the radio dropped')));
      r.svc.sendMessageWithRetry(contact: _bob, text: 'hi');
      async.elapse(const Duration(seconds: 2));
      expect(r.sends, ['flood']);
    });
  });

  test('a second DM queued behind the first is not asked about until its '
      'turn', () {
    fakeAsync((async) {
      final r = _Rig(wait: Future<void>.delayed(const Duration(seconds: 5)));
      r.svc.sendMessageWithRetry(contact: _bob, text: 'one');
      r.svc.sendMessageWithRetry(contact: _bob, text: 'two');
      async.flushMicrotasks();
      expect(r.asked, 1);
    });
  });
}
