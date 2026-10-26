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

// An incoming DM's path line shows the repeaters its own packet passed,
// read from the radio's raw log; the radio decrypts DMs itself and reports
// only the hop count. It used to show our stored route to the sender when
// the hop counts happened to match (owner, 2026-10-25: RedTail1's "Yup"
// read "via A277,AA77", our route in our order).
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

Uint8List _contactFrame(Uint8List pubKey, String name, {int pathLen = 0xFF,
    List<int> path = const []}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(pathLen);
  final pathField = Uint8List(maxPathSize)..setRange(0, path.length, path);
  w.add(pathField);
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

/// The decoded message, as the companion hands it over (V3: SNR first).
Uint8List _msgFrame(Uint8List sender, int pathLen, {int snr = 0x14,
    String text = 'hello', int txtType = txtTypePlain}) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, snr, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(pathLen);
  w.addByte(txtType);
  w.add((ByteData(4)..setUint32(0, 1752854400, Endian.little))
      .buffer
      .asUint8List());
  w.add(utf8.encode(text));
  return w.toBytes();
}

/// The radio's raw log of a flooded TXT_MSG: [0x88][snr][rssi], then
/// [header][path_len][path][dest][src][mac 2][ciphertext] (Packet.h).
Uint8List _rawDm({
  required int dest,
  required int src,
  required int pathLen,
  required List<int> path,
  int snr = 0x14,
  // Stands for the ciphertext: one value per message, the same in every
  // copy of that message.
  int cipher = 0x33,
}) {
  final w = BytesBuilder();
  w.add([pushCodeLogRxData, snr, 0xA0]);
  w.addByte(0x09); // payload type TXT_MSG (2) << 2 | route type flood (1)
  w.addByte(pathLen);
  w.add(path);
  w.add([dest, src, 0x11, 0x22]);
  w.add(List.filled(16, cipher));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  // Two hops at two bytes a hop: path_len 0x42.
  const twoByTwo = 0x42;
  const viaPath = [0xAA, 0x77, 0xA2, 0x77];

  late _Connector c;
  late Contact whale;

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
    // Our own route to them: two hops too, the other way round.
    c.handleFrameForTest(_contactFrame(chatKey, 'WHALE',
        pathLen: twoByTwo, path: const [0xA2, 0x77, 0xAA, 0x77]));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    whale = c.contacts.single;
  });

  tearDown(() => c.dispose());

  Future<Message> received() async {
    for (var i = 0; i < 50; i++) {
      final rows = await c.loadMessagesFor(whale);
      if (rows.isNotEmpty) return rows.single;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('the message was never stored');
  }

  test('the path comes from the logged copy of the packet', () async {
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo, path: viaPath));
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo));

    final m = await received();
    expect(m.pathBytes, viaPath);
    expect(m.pathHashSize, 2);
    expect(m.pathLength, 2);
    expect(m.pathFromPacket, isTrue);
  });

  test('no logged copy: the hop count only, never our route', () async {
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo));

    final m = await received();
    expect(m.pathLength, 2);
    expect(m.pathBytes, isEmpty);
    expect(m.pathFromPacket, isFalse);
  });

  test('copies that disagree on the path show none', () async {
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo, path: viaPath));
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0],
        src: chatKey[0],
        pathLen: twoByTwo,
        path: const [0xBE, 0xEF, 0xA2, 0x77]));
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo));

    expect((await received()).pathBytes, isEmpty);
  });

  test('a copy from someone else, or at another level, is not this one',
      () async {
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: 0x01, pathLen: twoByTwo, path: viaPath));
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0],
        src: chatKey[0],
        pathLen: twoByTwo,
        path: viaPath,
        snr: 0x28));
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo, snr: 0x14));

    expect((await received()).pathBytes, isEmpty);
  });

  test('copies of a message already shown never stand in for another',
      () async {
    // Message one, heard through two repeaters at two levels; the radio
    // decodes the first copy.
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo, path: viaPath,
        snr: 0x14, cipher: 0x31));
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo,
        path: const [0xBE, 0xEF, 0xA2, 0x77], snr: 0x0D, cipher: 0x31));
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo, snr: 0x14, text: 'one'));
    // The same way round again, heard after it was shown: the leftovers
    // agree, which is what let them pass for message two's path.
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo,
        path: const [0xBE, 0xEF, 0xA2, 0x77], snr: 0x0D, cipher: 0x31));
    // Message two never reached the radio's log (too long for it), and
    // arrives at the leftovers' level.
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo, snr: 0x0D, text: 'two'));

    List<Message> rows = [];
    for (var i = 0; i < 50 && rows.length < 2; i++) {
      rows = await c.loadMessagesFor(whale);
      if (rows.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    final byText = {for (final m in rows) m.text: m};
    expect(byText['one']!.pathBytes, viaPath);
    expect(byText['two']!.pathBytes, isEmpty);
    expect(byText['two']!.pathFromPacket, isFalse);
  });

  test('a CLI reply uses up its copy too', () async {
    // A flooded command reply (never stored as a message)...
    c.handleFrameForTest(_rawDm(
        dest: selfKey[0], src: chatKey[0], pathLen: twoByTwo, path: viaPath,
        cipher: 0x41));
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo,
        text: '0A|OK', txtType: txtTypeCliData));
    // ...then a message whose own copy was never logged, at the same level.
    c.handleFrameForTest(_msgFrame(chatKey, twoByTwo, text: 'the post'));

    final m = await received();
    expect(m.text, 'the post');
    expect(m.pathBytes, isEmpty);
  });
}
