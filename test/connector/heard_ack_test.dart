import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/passing_copy.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio counts a plain ACK at any hop, but a MULTIPART ACK only once its
// path is used up (Mesh.cpp onRecvPacket), and it forgets all but its last
// 8 sends. The RX log shows every ACK it hears, so the app counts the ones
// for its own DMs that the radio doesn't confirm.
Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

// The firmware's own keys, as in test/helpers/passing_copy_test.dart: this
// radio is B, the contact is A.
final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);

class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];

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
  Future<Uint8List?> exportPrivateKey() async => bPrivateExport;

  @override
  Future<({String name, Uint8List key})?> getDefaultFloodScope() async => null;

  List<Uint8List> get dms =>
      frames.where((f) => f[0] == cmdSendTxtMsg).toList();
}

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(bPub);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(_u32(910525000));
  w.add(_u32(62500));
  w.add([7, 5]);
  w.add(utf8.encode('B'));
  return w.toBytes();
}

Uint8List _contactFrame() {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(aPub);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final name = Uint8List(maxNameSize)..setRange(0, 1, 'A'.codeUnits);
  w.add(name);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _sent(int ack) =>
    Uint8List.fromList([respCodeSent, 0, ..._u32(ack), ..._u32(5000)]);

Uint8List _confirmed(int ack) =>
    Uint8List.fromList([pushCodeSendConfirmed, ..._u32(ack), ..._u32(2500)]);

Uint8List _rxLog(List<int> packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

/// A MULTIPART ACK routed on BEEF, one 2-byte hop still to go.
List<int> _multipartOnItsWay(int ack) =>
    [0x2A, 0x41, 0xBE, 0xEF, 0x10 | payloadTypeACK, ..._u32(ack), 0x00, 0x7F];

/// A plain ACK routed on BEEF, one hop still to go.
List<int> _plainOnItsWay(int ack) =>
    [0x0E, 0x41, 0xBE, 0xEF, ..._u32(ack), 0x00, 0x7F];

/// A's path reply to my flooded DM, carrying the ACK (createPathReturn:
/// path length, path, extra type, extra), flooded through A277.
List<int> _pathReply(int ack) {
  // B's secret with A is A's with B; read it from B's side.
  final shared = PassingCopyOpener(privateKey: bPrivateExport, selfKey: bPub)
      .sharedSecret(aPub)!;
  final data = Uint8List(16)
    ..setAll(0, [0x00, payloadTypeACK, ..._u32(ack), 0x00, 0x7F]);
  final aes = AESEngine()..init(true, KeyParameter(shared.sublist(0, 16)));
  final enc = Uint8List(16);
  aes.processBlock(data, 0, enc, 0);
  final mac = crypto.Hmac(crypto.sha256, shared).convert(enc).bytes;
  return [
    (payloadTypePATH << 2) | 0x01,
    0x41, 0xA2, 0x77,
    bPub[0], aPub[0], mac[0], mac[1], ...enc,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late MessageRetryService retry;
  late Contact a;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));
  Future<void> pastGrace() =>
      Future<void>.delayed(const Duration(milliseconds: 1300));

  int ackOf(Uint8List frame) => MessageRetryService.computeExpectedAckHash(
    ByteData.sublistView(frame, 3, 7).getUint32(0, Endian.little),
    frame[2],
    utf8.decode(frame.sublist(13, frame.length - 1)),
    bPub,
  );

  Future<Message> mine(String text) async => (await c.loadMessagesFor(a))
      .singleWhere((m) => m.isOutgoing && m.text == text);

  /// Sends [text] to A, and the radio reports it sent: its ACK code.
  Future<int> send(String text) async {
    await c.sendMessage(a, text);
    await settle();
    final ack = ackOf(c.dms.last);
    c.handleFrameForTest(_sent(ack));
    await settle();
    expect((await mine(text)).status, MessageStatus.sent);
    return ack;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    retry = MessageRetryService();
    c = _Connector()..initialize(retryService: retry);
    c.handleFrameForTest(_selfInfo());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame());
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    a = c.contacts.single;
    await c.preparePassingCopiesForTest();
  });

  tearDown(() => retry.dispose());

  test('a MULTIPART ACK on its way, which the radio drops, delivers the DM',
      () async {
    final ack = await send('one');
    c.handleFrameForTest(_rxLog(_multipartOnItsWay(ack)));
    await settle();
    expect((await mine('one')).status, MessageStatus.sent,
        reason: 'the radio gets its moment first');
    await pastGrace();
    expect((await mine('one')).status, MessageStatus.delivered);
  });

  test("an ACK the radio confirms itself is the radio's", () async {
    final ack = await send('two');
    c.handleFrameForTest(_rxLog(_plainOnItsWay(ack)));
    c.handleFrameForTest(_confirmed(ack));
    await settle();
    final m = await mine('two');
    expect(m.status, MessageStatus.delivered);
    expect(m.tripTimeMs, 2500);
    await pastGrace();
    expect((await mine('two')).tripTimeMs, 2500);
  });

  test('an ACK for a send the radio forgot still delivers the DM', () async {
    final ack = await send('three');
    // A plain ACK on its way that the radio no longer waits on.
    c.handleFrameForTest(_rxLog(_plainOnItsWay(ack)));
    await pastGrace();
    expect((await mine('three')).status, MessageStatus.delivered);
  });

  test("the ACK in a path reply to my flooded DM delivers it", () async {
    final ack = await send('four');
    c.handleFrameForTest(_rxLog(_pathReply(ack)));
    await pastGrace();
    expect((await mine('four')).status, MessageStatus.delivered);
  });

  test("someone else's ACK changes nothing", () async {
    final ack = await send('five');
    c.handleFrameForTest(_rxLog(_multipartOnItsWay(ack ^ 0x5A5A5A5A)));
    c.handleFrameForTest(_rxLog(_plainOnItsWay(ack ^ 0x01)));
    await pastGrace();
    expect((await mine('five')).status, MessageStatus.sent);
  });
}
