import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Audit repro r1-7-0: a Custom path is written into the radio by
// setPathOverride; switching back to Automatic never resets the radio, and
// _appWrittenPath is memory-only. After an app restart the contact list
// carries the app-written route with no override, wroteContactPath() is
// false, and PathGraphService proves its first hop as "hears me"
// (self-proving loop; owner rules 3 and 4).
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
  }
}

final _bob = Uint8List.fromList(List.generate(32, (i) => 0xC0 + i));
final _custom = Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]);

Uint8List _deviceInfoWidth2() {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = 10;
  f[2] = 50;
  f[3] = 8;
  f[81] = 1; // path hash mode 1 -> 2-byte hops
  return f;
}

Uint8List _contactFrame({int pathLen = 0xFF, Uint8List? path}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(_bob);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(pathLen);
  final p = Uint8List(maxPathSize);
  if (path != null) p.setRange(0, path.length, path);
  w.add(p);
  final name = Uint8List(maxNameSize);
  name.setRange(0, 3, 'BOB'.codeUnits);
  w.add(name);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Future<void> _download(_Connector c, Uint8List contactFrame) async {
  await c.getContacts();
  c.handleFrameForTest(
      Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
  c.handleFrameForTest(contactFrame);
  c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test(
      'a Custom path left on the radio after switching to Automatic is not '
      'proven as a firmware route after an app restart', () async {
    // Session 1: user sets Custom path A277,BEEF on Bob, then Automatic.
    final s1 = _Connector();
    s1.handleFrameForTest(_deviceInfoWidth2());
    expect(s1.pathHashByteWidth, 2);
    await _download(s1, _contactFrame());
    final bob1 = s1.contacts.single;
    s1.frames.clear();
    await s1.setPathOverride(bob1, pathLen: 2, pathBytes: _custom);
    expect(s1.frames.where((f) => f[0] == cmdAddUpdateContact), isNotEmpty,
        reason: 'sanity: Custom path was written to the radio');
    s1.frames.clear();
    await s1.setPathOverride(s1.contacts.single, pathLen: null);
    expect(s1.contacts.single.pathOverride, isNull);
    expect(s1.frames.where((f) => f[0] == cmdResetPath), isEmpty,
        reason: 'sanity: Automatic leaves the Custom route on the radio');

    // App restart: fresh connector; the radio still holds out_path A277,BEEF
    // (2 hops, 2-byte width => path_len byte 0x42).
    final s2 = _Connector();
    s2.handleFrameForTest(_deviceInfoWidth2());
    final service = PathGraphService();
    await service.start(s2, database: NativeDatabase.memory());
    await _download(s2, _contactFrame(pathLen: 0x42, path: _custom));
    // Connector notifications are debounced; let the batched notify fire.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final bob2 = s2.contacts.single;
    expect(bob2.pathOverride, isNull);
    expect(bob2.pathLength, 2);

    final proven = service.graph!
        .egressCandidates()
        .where((c) => c.proven)
        .map((c) => c.repeaterHash.toUpperCase())
        .toList();
    await service.stop();

    expect(proven, isNot(contains('A277')),
        reason: 'A277 only ever carried a route this app wrote (a Custom '
            'path that never delivered); nothing proved it hears this radio');
  });
}
