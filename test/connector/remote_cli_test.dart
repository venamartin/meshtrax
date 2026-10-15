import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/companion_cli_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firmware 1.18 remote CLI. A command for another companion goes out as
// CMD_SEND_TXT_MSG with txt_type 3. When a contact WITHOUT the remote-CLI
// flag sends one to us, our radio does not run it: it queues it to the app
// as a txt_type 3 contact message.
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
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(Uint8List(8));
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

Uint8List _dm(Uint8List sender, int txtType, String text) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.add([0xFF, txtType]);
  w.add((ByteData(4)..setUint32(0, 1760500000, Endian.little))
      .buffer
      .asUint8List());
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Connector c;
  late List<String> heard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey));
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(peerKey, 'WHALE'));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    heard = [];
    c.onContactMessageHeard = (pk, _, _) => heard.add(pk);
  });

  test('a command for a companion goes out as txt_type 3', () {
    final frame = buildSendCliCommandFrame(peerKey, '0A|ver',
        txtType: txtTypeCliCommand);

    expect(frame[0], cmdSendTxtMsg);
    expect(frame[1], txtTypeCliCommand);
    expect(frame.sublist(7, 13), peerKey.sublist(0, 6));
    expect(buildSendCliCommandFrame(peerKey, 'ver')[1], txtTypeCliData,
        reason: 'repeaters, rooms and sensors keep type 1');
  });

  test('a blocked command is reported, never shown as a message', () async {
    final reported = <BlockedCliCommand>[];
    c.blockedCliCommands.listen(reported.add);

    c.handleFrameForTest(_dm(peerKey, txtTypeCliCommand, 'get wifi.pwd'));
    await Future<void>.delayed(Duration.zero);

    expect(reported.single.contactName, 'WHALE');
    expect(reported.single.command, 'get wifi.pwd');
    expect(reported.single.contactKeyHex, pubKeyToHex(peerKey));
    expect(heard, isEmpty, reason: 'it never reached the message path');
    expect(c.getTotalUnreadCount(), 0);
  });

  test('an ordinary DM still goes the message path', () async {
    final reported = <BlockedCliCommand>[];
    c.blockedCliCommands.listen(reported.add);

    c.handleFrameForTest(_dm(peerKey, txtTypePlain, 'hello'));
    await Future<void>.delayed(Duration.zero);

    expect(reported, isEmpty);
    expect(heard, [pubKeyToHex(peerKey)]);
  });

  test('the parsed reply carries its text type', () {
    expect(parseContactMessageText(_dm(peerKey, txtTypeCliData, '0A|> v1'))!
        .txtType, txtTypeCliData);
    expect(parseContactMessageText(_dm(peerKey, txtTypePlain, 'hi'))!.txtType,
        txtTypePlain);
  });
}
