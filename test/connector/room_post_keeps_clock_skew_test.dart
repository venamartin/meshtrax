import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// An incoming room post proves the session but carries no clock. It must
// not erase the skew the LOGIN_OK measured: the clock-skew banner and the
// reaction stamp window for our own posts both read it.
class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

Uint8List _contactFrame(Uint8List pubKey, String name, {int type = advTypeRoom}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(type);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _u32(int v) => Uint8List.fromList(
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.addByte(respCodeSelfInfo);
  w.addByte(advTypeChat);
  w.addByte(22);
  w.addByte(22);
  w.add(pubKey);
  w.add(_u32(0));
  w.add(_u32(0));
  w.add([0, 0, 0, 0]);
  w.add(_u32(920000000));
  w.add(_u32(250000));
  w.add([11, 5]);
  w.add('ME'.codeUnits);
  w.addByte(0);
  return w.toBytes();
}

Future<void> settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x11 + i));
  final roomKey = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.initialize(retryService: MessageRetryService());
    c.handleFrameForTest(_selfInfo(selfKey));
    await settle();
    await c.getContacts();
    c.handleFrameForTest(
      Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]),
    );
    c.handleFrameForTest(_contactFrame(roomKey, 'ROOM'));
    c.handleFrameForTest(
      Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]),
    );
    await settle();
  });

  test('a room post does not erase the skew measured by the clocked LOGIN_OK',
      () async {
    final room = c.allContacts.firstWhere((x) => x.name == 'ROOM');
    expect(room.type, equals(advTypeRoom));

    // LOGIN_OK (14-byte form): server clock 180 s ahead of ours.
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    c.handleFrameForTest(Uint8List.fromList([
      pushCodeLoginSuccess,
      0, // not admin
      ...roomKey.sublist(0, 6),
      ..._u32(nowSecs + 180),
      0, // permissions
      1, // firmware level
    ]));
    await settle();

    final skewAfterLogin = c.roomSkewSecs(room)!;
    expect(skewAfterLogin, inInclusiveRange(178, 182),
        reason: 'LOGIN_OK measured the skew');
    expect(c.lastMeasuredRoomLogin(room.publicKeyHex)!.serverClock, isNotNull);

    // The room server then pushes a member's post (signed, V3).
    c.handleFrameForTest(Uint8List.fromList([
      respCodeContactMsgRecvV3,
      40, 0, 0, // snr, reserved
      ...roomKey.sublist(0, 6),
      0, // path len: direct
      txtTypeSigned,
      ..._u32(nowSecs + 181),
      0xC1, 0xC2, 0xC3, 0xC4, // author prefix
      ...'hello room'.codeUnits,
      0,
    ]));
    await settle();

    // The post still proves the session (auto-login reads this)...
    expect(c.lastRoomLoginEvent(room.publicKeyHex)!.implied, isTrue);
    // ...and the measurement survives it.
    final measured = c.lastMeasuredRoomLogin(room.publicKeyHex)!;
    expect(measured.serverClock, isNotNull,
        reason: 'the clock-skew banner reads serverClock from this event');
    expect(measured.role, 0, reason: 'the role badge reads it too');
    expect(c.roomSkewSecs(room), inInclusiveRange(178, 182),
        reason: 'the room clock has not changed; a post carries no clock');
  });
}
