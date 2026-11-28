import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/meshtrax_dm.dart';
import 'package:meshtrax/helpers/meshtrax_packet.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxproto/traxproto.dart';

// A DM to a contact whose phone runs MeshTrax goes out as MeshTrax's own
// packet, through the same retry ladder as a firmware DM, and MeshTrax's ACK
// delivers it. Who runs MeshTrax is learned on the air: a phone that gets a
// firmware DM answers once with a MeshTrax ACK. The keys are the simulation
// keys of passing_copy_connector_test.
Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);
final secret =
    _hex('6AE94F988F1088625142CA4FC203441B0FCB04CFAB09C1519DE71CA518911707');
// B's stored route to A.
final routeToA = _hex('BEEFAD77A277');
// A's firmware DM "hello B" to B (MeshCore's own bytes), as a flood that
// passed A277.
final firmwareDmFlooded =
    _hex('0941A277E7C33A54219B42238925027937BB7F0A51F893E3');

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

  /// DMs handed to the radio to send the firmware's way.
  List<Uint8List> get firmwareDms =>
      frames.where((f) => f[0] == cmdSendTxtMsg).toList();

  /// MeshTrax's own packets handed to the radio.
  List<Uint8List> get ours => frames
      .where((f) =>
          f.length > 2 &&
          f[0] == cmdSendRawPacket &&
          (f[2] >> 2) & 0x0F == payloadTypeGRPDATA)
      .toList();
}

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _deviceInfo() {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = 14;
  f[2] = 175;
  f[3] = 40;
  f.setRange(60, 67, utf8.encode('v1.18.0'));
  f[81] = 1; // 2-byte path hashes
  return f;
}

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(bPub);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(_u32(910525));
  w.add(_u32(62500));
  w.add([7, 5]);
  w.add(utf8.encode('B'));
  return w.toBytes();
}

Uint8List _contactFrame({bool route = true}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(aPub);
  w.addByte(advTypeChat);
  w.addByte(0);
  if (route) {
    w.addByte(0x43); // 3 hops, 2 bytes each
    w.add(Uint8List(maxPathSize)..setRange(0, routeToA.length, routeToA));
  } else {
    w.addByte(0xFF);
    w.add(Uint8List(maxPathSize));
  }
  w.add(Uint8List(maxNameSize)..setRange(0, 1, 'A'.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _rxLog(List<int> packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

/// A MeshTrax ACK from A to B, flooded through A277.
Uint8List _ackFromA({
  int number = 0,
  int tryNumber = 0,
  int? triesArrived,
  List<int>? cameBy,
}) =>
    _rxLog([
  (payloadTypeGRPDATA << 2) | 0x01,
  0x41, 0xA2, 0x77,
  ...MeshTraxPacket.seal(
    secret,
    toByte: bPub[0],
    fromByte: aPub[0],
    dataType: dataTypeMeshTraxAck,
    blob: frameDirect(
      DirectAck(
        number: number,
        tryNumber: tryNumber,
        triesArrived: triesArrived ?? 1 << tryNumber,
        cameBy: cameBy,
      ).encode(),
      senderSortsAbove: false,
    ),
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late MessageRetryService retry;
  late Contact a;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  /// The app holds a send back until the radio has been quiet a moment
  /// after the last packet it heard.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await settle();
  }

  Future<Message> mine(String text) async => (await c.loadMessagesFor(a))
      .singleWhere((m) => m.isOutgoing && m.text == text);

  /// What a MeshTrax packet handed to the radio holds, which must be routed
  /// on the stored route to A.
  ({int dataType, bool senderSortsAbove, Uint8List message}) opened(
      Uint8List frame) {
    expect(frame.sublist(0, 4 + routeToA.length), [
      cmdSendRawPacket, 0, (payloadTypeGRPDATA << 2) | 0x02, 0x43, ...routeToA,
    ]);
    final payload = frame.sublist(4 + routeToA.length);
    expect(payload.sublist(0, 2), [aPub[0], bPub[0]], reason: 'to A, from B');
    final o = MeshTraxPacket.open(secret, payload)!;
    final framed = unframeDirect(o.blob)!;
    return (
      dataType: o.dataType,
      senderSortsAbove: framed.senderSortsAbove,
      message: framed.message,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    retry = MessageRetryService();
    c = _Connector()..initialize(retryService: retry);
    c.handleFrameForTest(_deviceInfo());
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

  test('a contact not known to run MeshTrax gets the firmware DM', () async {
    await c.sendMessage(a, 'one');
    await settle();
    expect(c.firmwareDms, hasLength(1));
    expect(c.ours, isEmpty);
    expect((await mine('one')).viaMeshTrax, isNull,
        reason: 'nothing to say about the way it went');
  });

  // Owner, 2026-11-27: the message box counts against "the flood figure,
  // 126 packed bytes".
  test('the room the message box counts against is 126 packed bytes', () {
    expect(c.meshTraxDmTextRoom, 126);
  });

  test('a text of exactly that room goes as MeshTrax, one byte more does not',
      () async {
    // The radio holds no route: the try floods, as the box assumes.
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(route: false));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    a = c.contacts.single;
    c.handleFrameForTest(_ackFromA());
    // Nothing Smaz can shrink.
    final fits = List.generate(126, (i) => 'Q7#Z'[i % 4]).join();
    await c.sendMessage(a, fits);
    await until(() => c.ours.isNotEmpty);
    expect(c.ours, hasLength(1));
    expect(c.firmwareDms, isEmpty);
    expect(c.ours.single.length - 2, lessThanOrEqualTo(heardPacketMaxBytes - 16),
        reason: 'still heard after eight repeaters added their codes');
    expect((await mine(fits)).viaMeshTrax, isTrue);
  });

  test("a firmware DM from them is answered once with MeshTrax's hello",
      () async {
    c.handleFrameForTest(_rxLog(firmwareDmFlooded));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final hello = opened(c.ours.single);
    expect(hello.dataType, dataTypeMeshTraxAck);
    expect(hello.senderSortsAbove, isTrue);
    final ack = DirectAck.decode(hello.message)!;
    expect(ack.number, 0, reason: 'it answers no MeshTrax DM');
    expect(ack.level, 12);
    expect(ack.route, routeToA);

    // Another copy, and another DM of theirs: no second hello.
    c.handleFrameForTest(_rxLog(firmwareDmFlooded));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(c.ours, hasLength(1));
  });

  test("after their MeshTrax ACK, a DM goes as MeshTrax's packet and their "
      'ACK delivers it', () async {
    c.handleFrameForTest(_ackFromA());
    expect(c.runsMeshTrax(a.publicKeyHex), isTrue);

    await c.sendMessage(a, 'Meet at the trailhead at nine');
    await until(() => c.ours.isNotEmpty);
    expect(c.firmwareDms, isEmpty, reason: 'not the firmware way as well');
    final sent = opened(c.ours.single);
    expect(sent.dataType, dataTypeMeshTraxDm);
    expect(sent.senderSortsAbove, isTrue, reason: "B's key sorts above A's");
    final dm = DirectMessage.decode(sent.message)!;
    expect(dm.tryNumber, 0);
    expect(dm.route, routeToA, reason: 'the route it was sent on');
    expect(MeshTraxDmText.unpack(dm.packing, dm.text),
        'Meet at the trailhead at nine');
    expect(dm.packing, textSmaz, reason: 'packed without a setting');
    final stored = await mine('Meet at the trailhead at nine');
    expect(stored.status, MessageStatus.sent);
    expect(stored.viaMeshTrax, isTrue, reason: 'the way it went');
    expect(dm.time, stored.timestamp.millisecondsSinceEpoch ~/ 1000);

    // An ACK for another try or another message changes nothing.
    c.handleFrameForTest(_ackFromA(number: dm.number, tryNumber: 1));
    c.handleFrameForTest(_ackFromA(number: dm.number + 1));
    await settle();
    expect((await mine('Meet at the trailhead at nine')).status,
        MessageStatus.sent);

    c.handleFrameForTest(_ackFromA(number: dm.number));
    await settle();
    expect((await mine('Meet at the trailhead at nine')).status,
        MessageStatus.delivered);
  });

  // Owner, 2026-11-28: the ACK's data must not go to waste. Their ACK lists
  // every try of the message that reached them.
  test('their ACK of a later try names a try whose own ACK never came: '
      'Pathfinder is told it arrived', () async {
    c.handleFrameForTest(_ackFromA());
    final arrived = <List<int>>[];
    c.onMeshTraxTryArrived = (contact, route) =>
        arrived.add(route.pathBytes.sublist(0, route.hopCount * route.hashSize));
    await c.sendMessage(a, 'did the first one get there');
    await until(() => c.ours.isNotEmpty);
    final dm = DirectMessage.decode(opened(c.ours.single).message)!;

    // An ACK that lists only its own try says nothing of another.
    c.handleFrameForTest(_ackFromA(number: dm.number, tryNumber: 1));
    expect(arrived, isEmpty);
    // Try 1's ACK, listing tries 0 and 1.
    c.handleFrameForTest(
        _ackFromA(number: dm.number, tryNumber: 2, triesArrived: 5));
    expect(arrived, [routeToA]);
    // Told once.
    c.handleFrameForTest(
        _ackFromA(number: dm.number, tryNumber: 3, triesArrived: 13));
    expect(arrived, hasLength(1));
  });

  test("a text too long to be heard goes the firmware's way", () async {
    c.handleFrameForTest(_ackFromA());
    // Nothing Smaz can shrink.
    final long = List.generate(150, (i) => 'Q7#Z'[i % 4]).join();
    await c.sendMessage(a, long);
    await until(() => c.firmwareDms.isNotEmpty);
    expect(c.ours, isEmpty);
    expect(c.firmwareDms, hasLength(1));
    expect((await mine(long)).viaMeshTrax, isFalse,
        reason: 'to a contact on MeshTrax, but as a standard message');
  });

  // The radio holds no route to them, so the try floods; MeshTrax's ACK
  // names the repeaters that flood passed, as a path reply does.
  test("a flooded try's ACK tells Pathfinder the way the flood took",
      () async {
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(route: false));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    a = c.contacts.single;
    final replies = <(String, List<int>, int)>[];
    c.onPathReplyHeard =
        (contact, path, width) => replies.add((contact.publicKeyHex, path, width));
    c.handleFrameForTest(_ackFromA());

    await c.sendMessage(a, 'which way');
    await until(() => c.ours.isNotEmpty);
    final frame = c.ours.single;
    expect(frame.sublist(0, 4),
        [cmdSendRawPacket, 1, (payloadTypeGRPDATA << 2) | 0x01, 0x40],
        reason: 'a flood, 2-byte codes');
    final framed =
        unframeDirect(MeshTraxPacket.open(secret, frame.sublist(4))!.blob)!;
    final dm = DirectMessage.decode(framed.message)!;
    expect(dm.route, isEmpty, reason: 'a flood carries no route');

    c.handleFrameForTest(
        _ackFromA(number: dm.number, cameBy: _hex('A2771000')));
    await settle();
    final (key, path, width) = replies.single;
    expect(key, a.publicKeyHex);
    expect(path, _hex('A2771000'));
    expect(width, 2);
    expect((await mine('which way')).status, MessageStatus.delivered);
  });

  test('my two lists go in the DM when there is room beside the text',
      () async {
    c.meshTraxEnds =
        (width) => (hears: _hex('BEEF88'), heardBy: _hex('BEEF00A2777F'));
    c.handleFrameForTest(_ackFromA());

    await c.sendMessage(a, 'short one');
    await until(() => c.ours.isNotEmpty);
    final short = DirectMessage.decode(opened(c.ours.last).message)!;
    expect(short.hears, _hex('BEEF88'));
    expect(short.heardBy, _hex('BEEF00A2777F'));
    c.handleFrameForTest(_ackFromA(number: short.number));

    // Nothing Smaz can shrink, sized to fit the packet only without them.
    final long = List.generate(130, (i) => 'Q7#Z'[i % 4]).join();
    await c.sendMessage(a, long);
    await until(() => c.ours.length > 1);
    final tight = DirectMessage.decode(opened(c.ours.last).message)!;
    expect(utf8.decode(tight.text), long);
    expect(tight.hears, isEmpty, reason: 'the text comes first');
    expect(tight.heardBy, isEmpty);
    expect(c.firmwareDms, isEmpty);
  });

  test('two messages get different numbers', () async {
    c.handleFrameForTest(_ackFromA());
    await c.sendMessage(a, 'first');
    await until(() => c.ours.isNotEmpty);
    c.handleFrameForTest(_ackFromA(
        number: DirectMessage.decode(opened(c.ours.single).message)!.number));
    await c.sendMessage(a, 'second');
    await until(() => c.ours.length > 1);
    final numbers = [
      for (final f in c.ours) DirectMessage.decode(opened(f).message)!.number,
    ];
    expect(numbers, hasLength(2));
    expect(numbers[0], isNot(numbers[1]));
  });
}
