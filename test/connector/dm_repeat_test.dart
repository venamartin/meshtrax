import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A DM whose first copy arrived but whose ACK was lost comes again with a
// new timestamp when the sender resends it (MeshTrax's own Retry button
// does). Within five minutes of wire time, the same text from the same
// sender is that message, not a second one (owner, 2026-11-03).
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

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([0, 0, 0, 1]);
  w.add(_u32(910525000));
  w.add(_u32(62500));
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactFrame(Uint8List pubKey, String name, int type) {
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

Uint8List _dm(Uint8List from, int secs, String text) => Uint8List.fromList([
      respCodeContactMsgRecvV3, 0x14, 0, 0,
      ...from.sublist(0, 6),
      0, // path len: direct
      txtTypePlain,
      ..._u32(secs),
      ...utf8.encode(text),
    ]);

Uint8List _roomPost(Uint8List room, List<int> author, int secs, String text) =>
    Uint8List.fromList([
      respCodeContactMsgRecvV3, 0x14, 0, 0,
      ...room.sublist(0, 6),
      0,
      txtTypeSigned,
      ..._u32(secs),
      ...author,
      ...utf8.encode(text),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final roomKey = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  late _Connector c;
  late Contact whale;
  late Contact room;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey));
    // SELF_INFO's load of the empty store would replace the list below.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(chatKey, 'WHALE', advTypeChat));
    c.handleFrameForTest(_contactFrame(roomKey, 'Summit', advTypeRoom));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    whale = c.contacts.firstWhere((x) => x.name == 'WHALE');
    room = c.contacts.firstWhere((x) => x.name == 'Summit');
  });

  tearDown(() => c.dispose());

  /// Feeds [frame] and waits until its ingest has finished.
  Future<List<String>> receive(Contact into, Uint8List frame) async {
    c.handleFrameForTest(frame);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return [for (final m in await c.loadMessagesFor(into)) m.text];
  }

  test('a resend with a new timestamp inside 5 minutes shows once', () async {
    await receive(whale, _dm(chatKey, now, 'Are you there?'));
    expect(await receive(whale, _dm(chatKey, now + 95, 'Are you there?')),
        ['Are you there?']);
  });

  test('the same text 5 minutes or more apart is a new message', () async {
    await receive(whale, _dm(chatKey, now - 400, 'ok'));
    expect(await receive(whale, _dm(chatKey, now, 'ok')), ['ok', 'ok']);
  });

  test('other text inside the window is a new message', () async {
    await receive(whale, _dm(chatKey, now, 'ok'));
    expect(await receive(whale, _dm(chatKey, now + 20, 'ok!')), ['ok', 'ok!']);
  });

  test('a copy with the same timestamp still shows once', () async {
    await receive(whale, _dm(chatKey, now, 'hello'));
    expect(await receive(whale, _dm(chatKey, now, 'hello')), ['hello']);
  });

  test('in a room the author counts: two members saying the same is two',
      () async {
    const ann = [0xC1, 0xC2, 0xC3, 0xC4];
    const bob = [0xB1, 0xB2, 0xB3, 0xB4];
    await receive(room, _roomPost(roomKey, ann, now, 'yes'));
    expect(await receive(room, _roomPost(roomKey, bob, now + 5, 'yes')),
        ['yes', 'yes']);
    expect(await receive(room, _roomPost(roomKey, ann, now + 60, 'yes')),
        ['yes', 'yes']);
  });
}
