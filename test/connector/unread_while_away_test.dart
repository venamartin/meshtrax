import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A message reaching the chat on screen is read as it lands, but only while
// the app is in front. Backgrounded, it has to stay unread for the badge and
// the NEW MESSAGES divider (owner, 2026-10-31).
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
  w.add([0, 0, 0, 1]);
  w.add((ByteData(8)
        ..setUint32(0, 910525000, Endian.little)
        ..setUint32(4, 62500, Endian.little))
      .buffer
      .asUint8List());
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactFrame(Uint8List pubKey, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeChat);
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

Uint8List _msgFrame(Uint8List sender, String text, int seconds) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(0);
  w.addByte(txtTypePlain);
  w.add((ByteData(4)..setUint32(0, seconds, Endian.little))
      .buffer
      .asUint8List());
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Connector c;
  late Contact whale;

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
        Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(chatKey, 'WHALE'));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    whale = c.contacts.single;
    c.setActiveContact(whale.publicKeyHex);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() => c.dispose());

  Future<void> receive(int count, String text) async {
    c.handleFrameForTest(_msgFrame(chatKey, text, 1752854400 + count));
    for (var i = 0; i < 50; i++) {
      if ((await c.loadMessagesFor(whale)).length >= count) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await c.loadMessagesFor(whale), hasLength(count));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  int unread() => c.getUnreadCountForContactKey(whale.publicKeyHex);

  test('in front: a message to the open chat is read as it lands', () async {
    await receive(1, 'hello');
    expect(unread(), 0);
  });

  test('the notification shade does not stop the reading', () async {
    c.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await receive(1, 'hello');
    expect(unread(), 0);
  });

  test('backgrounded: messages stay unread until the chat is read', () async {
    c.didChangeAppLifecycleState(AppLifecycleState.inactive);
    c.didChangeAppLifecycleState(AppLifecycleState.hidden);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await receive(1, 'one');
    await receive(2, 'two');
    expect(unread(), 2);

    // On the way back, before fully resumed.
    c.didChangeAppLifecycleState(AppLifecycleState.hidden);
    c.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await receive(3, 'three');
    expect(unread(), 3);

    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(unread(), 3, reason: 'resuming alone reads nothing: the screen does');

    c.setActiveContact(whale.publicKeyHex);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(unread(), 0);
  });
}
