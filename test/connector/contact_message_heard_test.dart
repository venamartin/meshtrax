import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A decrypted DM or room post is handed to the path graph with the
// sender's full key and the frame's own path_len and SNR bytes — before
// the stored route's width replaces the packet's.
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

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([0, 0, 0, 1]); // multi_acks, advert loc policy, telemetry, manual add
  w.add((ByteData(8)
        ..setUint32(0, 910525000, Endian.little)
        ..setUint32(4, 62500, Endian.little))
      .buffer
      .asUint8List());
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactFrame(Uint8List pubKey, String name, int type,
    {int pathLen = 0xFF}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(type);
  w.addByte(0);
  w.addByte(pathLen);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _msgFrame({
  required int code,
  required Uint8List sender,
  required int pathLen,
  int txtType = 0,
  Uint8List? author,
  int snr = 0x14,
  String text = 'hello',
}) {
  final w = BytesBuilder();
  w.addByte(code);
  if (code == respCodeContactMsgRecvV3) w.add([snr, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(pathLen);
  w.addByte(txtType);
  w.add((ByteData(4)..setUint32(0, 1752854400, Endian.little))
      .buffer
      .asUint8List());
  if (author != null) w.add(author);
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final roomKey = Uint8List.fromList(List.generate(32, (i) => 0xC4 + i));

  late _Connector c;
  late List<(String, int, int?)> heard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey));
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]));
    // The chat contact holds a 1-byte route of the same hop count as the
    // floods below, so the width mismatch is on the table.
    c.handleFrameForTest(_contactFrame(chatKey, 'WHALE', advTypeChat,
        pathLen: 0x02));
    c.handleFrameForTest(_contactFrame(roomKey, 'ROOM', advTypeRoom));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    heard = [];
    c.onContactMessageHeard = (pk, pathLen, snr) => heard.add((pk, pathLen, snr));
  });

  test('a flooded DM reports the full key, the packet\'s path_len and SNR',
      () {
    c.handleFrameForTest(_msgFrame(
        code: respCodeContactMsgRecvV3,
        sender: chatKey,
        pathLen: 0x42,
        snr: 0xEC));

    expect(heard, [(pubKeyToHex(chatKey), 0x42, -20)]);
  });

  test('a room post reports the room, not the author', () {
    c.handleFrameForTest(_msgFrame(
        code: respCodeContactMsgRecvV3,
        sender: roomKey,
        pathLen: 0x41,
        txtType: txtTypeSigned,
        author: chatKey.sublist(0, 4)));

    expect(heard.single.$1, pubKeyToHex(roomKey));
    expect(heard.single.$2, 0x41);
  });

  test('a direct message is reported as such; the pre-V3 frame has no SNR',
      () {
    c.handleFrameForTest(_msgFrame(
        code: respCodeContactMsgRecvV3, sender: chatKey, pathLen: 0xFF));
    c.handleFrameForTest(_msgFrame(
        code: respCodeContactMsgRecv, sender: chatKey, pathLen: 0x42));

    expect(heard.map((h) => h.$2), [0xFF, 0x42]);
    expect(heard.map((h) => h.$3), [20, null]);
  });

  test('an unknown sender is not reported', () {
    final stranger = Uint8List.fromList(List.generate(32, (i) => 0x11 + i));
    c.handleFrameForTest(_msgFrame(
        code: respCodeContactMsgRecvV3, sender: stranger, pathLen: 0x42));

    expect(heard, isEmpty);
  });
}
