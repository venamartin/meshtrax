import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A routed DM to this radio that still has hops to go is dropped unopened by
// the firmware, even when the radio hears it loud and clear (bench, 1.18.0,
// 2026-11-19). The app opens it from the radio's RX log, stores it like any
// DM, and sends the ACK the firmware would have sent. The keys and packets
// are the firmware's own, the same as in test/helpers/passing_copy_test.dart.
Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);
final dmFromAd77 = _hex('0A41BEEFE7C33A54219B42238925027937BB7F0A51F893E3');
final dmFromA = _hex('0A43A277AD77BEEFE7C33A54219B42238925027937BB7F0A51F893E3');
final roomFromAd77 = _hex(
  '0A41BEEFE7C3BAF83AF36DB76A1C352D65DAD2E4D40135C72967AF4E0916A707DDA7F31DC5FA8F49',
);
const dmTimestamp = 1795046400;
// B's stored route back to A.
final routeBack = _hex('BEEFAD77A277');

class _Connector extends MeshCoreConnector {
  _Connector({this.keyExport = true});

  final bool keyExport;
  final sent = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }

  @override
  Future<Uint8List?> exportPrivateKey() async =>
      keyExport ? bPrivateExport : null;

  @override
  Future<({String name, Uint8List key})?> getDefaultFloodScope() async => null;

  List<Uint8List> get rawPackets =>
      sent.where((f) => f.isNotEmpty && f[0] == cmdSendRawPacket).toList();
}

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([1, 0, 0, 1]); // multi_acks on
  w.add((ByteData(8)
        ..setUint32(0, 910525, Endian.little)
        ..setUint32(4, 62500, Endian.little))
      .buffer
      .asUint8List());
  w.add([7, 5]);
  w.add(utf8.encode('B'));
  return w.toBytes();
}

Uint8List _deviceInfo(int verCode) {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = verCode;
  f[2] = 175;
  f[3] = 40;
  f.setRange(60, 67, utf8.encode('v1.18.0'));
  f[81] = 1; // 2-byte path hashes
  return f;
}

Uint8List _contactFrame(Uint8List pubKey, String name, int type) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(type);
  w.addByte(0);
  w.addByte(0x43); // 3 hops, 2 bytes each
  w.add(Uint8List(maxPathSize)..setRange(0, routeBack.length, routeBack));
  final nameBytes = Uint8List(maxNameSize)
    ..setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _rxLog(Uint8List packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

/// The radio handing over the same DM, had it opened BEEF's copy.
Uint8List _radiosOwn() => Uint8List.fromList([
  respCodeContactMsgRecvV3, 0x30, 0, 0,
  ...aPub.sublist(0, 6),
  0xFF,
  txtTypePlain,
  ...(ByteData(4)..setUint32(0, dmTimestamp, Endian.little)).buffer.asUint8List(),
  ...utf8.encode('hello B'),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Contact a;

  Future<void> connect({
    bool keyExport = true,
    int verCode = 14,
    int type = advTypeChat,
  }) async {
    c = _Connector(keyExport: keyExport);
    c.handleFrameForTest(_deviceInfo(verCode));
    c.handleFrameForTest(_selfInfo(bPub));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(aPub, 'A', type));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    a = c.contacts.single;
    await c.preparePassingCopiesForTest();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  tearDown(() => c.dispose());

  Future<List<Message>> rows({int atLeast = 1}) async {
    var found = <Message>[];
    for (var i = 0; i < 100; i++) {
      found = await c.loadMessagesFor(a);
      if (found.length >= atLeast) return found;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return found;
  }

  Future<List<Uint8List>> rawPackets(int count) async {
    for (var i = 0; i < 100 && c.rawPackets.length < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return c.rawPackets;
  }

  test('opens a DM the radio drops, and sends the ACK on the route back',
      () async {
    await connect();
    c.handleFrameForTest(_rxLog(dmFromAd77));

    final m = (await rows()).single;
    expect(m.text, 'hello B');
    expect(m.isOutgoing, isFalse);
    expect(m.timestamp.millisecondsSinceEpoch, dmTimestamp * 1000);
    expect(m.passingCopyHopsLeft, 'BEEF');

    // As BaseChatMesh::sendAckTo: the extra MULTIPART ACK, then the ACK,
    // both routed on BEEF,AD77,A277. The ACK's last byte is random.
    final acks = await rawPackets(2);
    expect(acks, hasLength(2));
    expect(acks[0].sublist(0, 16), [
      cmdSendRawPacket, 0, 0x2A, 0x43, ...routeBack, 0x13,
      ..._hex('1FEE94EB00'),
    ]);
    expect(acks[1].sublist(0, 15), [
      cmdSendRawPacket, 0, 0x0E, 0x43, ...routeBack, ..._hex('1FEE94EB00'),
    ]);
  });

  test("the radio's own copy of it later is the same message", () async {
    await connect();
    c.handleFrameForTest(_rxLog(dmFromAd77));
    await rows();
    c.handleFrameForTest(_radiosOwn());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final stored = await rows();
    expect(stored, hasLength(1));
    expect(stored.single.passingCopyHopsLeft, 'BEEF');
  });

  test('several copies of one DM: one message, one ACK', () async {
    await connect();
    c.handleFrameForTest(_rxLog(dmFromA));
    c.handleFrameForTest(_rxLog(dmFromAd77));

    final stored = await rows();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect((await rows()), hasLength(1));
    expect(stored.single.passingCopyHopsLeft, 'A277,AD77,BEEF',
        reason: 'the first copy heard, the sender\'s own');
    await rawPackets(2);
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(c.rawPackets, hasLength(2));
  });

  test('a room post: stored with its author, and the 4-byte ACK', () async {
    await connect(type: advTypeRoom);
    c.handleFrameForTest(_rxLog(roomFromAd77));

    final m = (await rows()).single;
    expect(m.text, 'room post');
    expect(m.fourByteRoomContactKey, _hex('A277F94F'));
    expect(m.passingCopyHopsLeft, 'BEEF');
    final acks = await rawPackets(2);
    expect(acks.last, [
      cmdSendRawPacket, 0, 0x0E, 0x43, ...routeBack, ..._hex('1967AA54'),
    ]);
  });

  test('firmware before 1.16: the message, but no ACK it cannot send',
      () async {
    await connect(verCode: 12);
    c.handleFrameForTest(_rxLog(dmFromAd77));

    expect((await rows()).single.text, 'hello B');
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(c.rawPackets, isEmpty);
  });

  test('a radio that keeps its key to itself: nothing opened', () async {
    await connect(keyExport: false);
    c.handleFrameForTest(_rxLog(dmFromAd77));

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(await c.loadMessagesFor(a), isEmpty);
    expect(c.rawPackets, isEmpty);
  });

  test('a copy with no hops left is the radio\'s to open', () async {
    await connect();
    final last = Uint8List.fromList([0x0A, 0x40, ...dmFromAd77.sublist(4)]);
    c.handleFrameForTest(_rxLog(last));

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(await c.loadMessagesFor(a), isEmpty);
    expect(c.rawPackets, isEmpty);
  });
}
