import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/server_login_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The login ladder: a login goes by the radio's route when it has one and by
// flood when it has none. On Automatic, a route that times out is reset so
// the next attempt floods, because only a flooded login is answered with a
// PATH return, which is how the radio learns the route again.
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];
  final resets = <String>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
  }

  @override
  Future<void> clearContactPath(Contact contact) async {
    resets.add(contact.publicKeyHex);
  }

  int get logins => frames.where((f) => f[0] == cmdSendLogin).length;
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0xC0 + i));

Contact _server({
  int type = advTypeRoom,
  int pathLength = -1,
  List<int> path = const [],
  int? pathOverride,
  List<int>? pathOverrideBytes,
}) =>
    Contact(
      publicKey: _key,
      name: 'ROOM',
      type: type,
      pathLength: pathLength,
      path: Uint8List.fromList(path),
      pathHashSize: 1,
      pathOverride: pathOverride,
      pathOverrideBytes:
          pathOverrideBytes == null ? null : Uint8List.fromList(pathOverrideBytes),
      lastSeen: DateTime.now(),
    );

Uint8List _loginPush(int code, {int adminByte = 0}) => Uint8List.fromList([
      code,
      adminByte,
      ..._key.sublist(0, 6),
      0, 0, 0, 0, 0, 0,
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
  });

  // The ladder's own timeout for an attempt: the connector's estimate for a
  // full frame plus the two-second margin.
  Duration attemptTimeout(int pathLength) => Duration(
        milliseconds: c.calculateTimeout(
              pathLength: pathLength,
              messageBytes: maxFrameSize,
            ) +
            2001,
      );

  test('Automatic: a route that times out is reset and the login floods', () {
    fakeAsync((async) {
      final room = _server(pathLength: 2, path: const [0x10, 0x20]);
      LoginOutcome? outcome;
      ServerLoginService(c)
          .login(room, 'pw', maxAttempts: 3)
          .then((o) => outcome = o);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.logins, equals(1));
      expect(c.resets, isEmpty);

      async.elapse(attemptTimeout(2));
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.resets, equals([room.publicKeyHex]),
          reason: 'the route gets one try, then the ladder floods');
      expect(c.logins, equals(2));

      c.handleFrameForTest(_loginPush(pushCodeLoginSuccess));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(outcome?.success, isTrue);
      expect(outcome?.isAdmin, isFalse);
      expect(c.logins, equals(2));
    });
  });

  // Field 2026-10-24: the relearn after a flooded post said "login by
  // flood" but went out on the route the keeper had just written (F5EE),
  // and timed out. The relearn exists to earn the PATH reply only a
  // flooded login gets, so it must flood whatever is stored.
  test('forced flood: the stored route is reset and the first attempt floods',
      () {
    fakeAsync((async) {
      final room = _server(pathLength: 1, path: const [0xF5]);
      ServerLoginService(c).login(room, '', maxAttempts: 1, forceFlood: true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.resets, equals([room.publicKeyHex]),
          reason: 'the route is cleared before the login goes out');
      expect(c.logins, equals(1));
    });
  });

  test('no route: floods from the first attempt, nothing to reset', () {
    fakeAsync((async) {
      final room = _server();
      LoginOutcome? outcome;
      ServerLoginService(c)
          .login(room, 'pw', maxAttempts: 2)
          .then((o) => outcome = o);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.logins, equals(1));
      async.elapse(attemptTimeout(-1));
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.logins, equals(2));
      expect(c.resets, isEmpty);

      c.handleFrameForTest(_loginPush(pushCodeLoginSuccess, adminByte: 1));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      expect(outcome?.success, isTrue);
      expect(outcome?.isAdmin, isTrue);
    });
  });

  test('a custom path is never reset by the ladder', () {
    fakeAsync((async) {
      final room = _server(pathOverride: 1, pathOverrideBytes: const [0x33]);
      LoginOutcome? outcome;
      ServerLoginService(c)
          .login(room, 'pw', maxAttempts: 2)
          .then((o) => outcome = o);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      async.elapse(attemptTimeout(1));
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      async.elapse(attemptTimeout(1));
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.logins, equals(2));
      expect(c.resets, isEmpty);
      expect(outcome?.success, isNull, reason: 'both attempts timed out');
    });
  });

  test('a refused login stops the ladder', () {
    fakeAsync((async) {
      final room = _server();
      LoginOutcome? outcome;
      ServerLoginService(c)
          .login(room, 'wrong', maxAttempts: 5)
          .then((o) => outcome = o);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      c.handleFrameForTest(_loginPush(pushCodeLoginFail));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(outcome?.success, isFalse);
      expect(c.logins, equals(1));
    });
  });

  test('a repeater login follows the same ladder', () {
    fakeAsync((async) {
      final repeater = _server(
        type: advTypeRepeater,
        pathLength: 1,
        path: const [0x10],
      );
      ServerLoginService(c).login(repeater, 'pw', maxAttempts: 2);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      async.elapse(attemptTimeout(1));
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));

      expect(c.resets, equals([repeater.publicKeyHex]));
      expect(c.logins, equals(2));
    });
  });

  test('the frame carries the password, blank when there is none', () {
    fakeAsync((async) {
      ServerLoginService(c).login(_server(), '', maxAttempts: 1);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      final frame = c.frames.single;
      expect(frame[0], equals(cmdSendLogin));
      expect(frame.sublist(1, 33), equals(_key));
      expect(frame.sublist(33), equals([0]), reason: 'empty password');
    });
  });
}
