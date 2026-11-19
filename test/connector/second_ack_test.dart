import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Two ACKs wanted and Pathfinder on: the radio sends one ACK and the app the
// second, on another of Pathfinder's routes to the sender (owner,
// 2026-11-19: "either the companion sends two acks or it sends one and the
// app sends the second"). The keys and packets are the firmware's own, as
// in test/helpers/passing_copy_test.dart.
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
final payload = dmFromAd77.sublist(4);
// The copy the radio opens itself: no hops left.
final dmLastCopy = Uint8List.fromList([0x0A, 0x40, ...payload]);
// The same DM by flood, two repeaters travelled.
final dmFlood = Uint8List.fromList([0x09, 0x42, 0xA2, 0x77, 0xAD, 0x77, ...payload]);
final ackHash = _hex('1FEE94EB00');

// The radio's stored route back to A, which the keeper keeps as
// Pathfinder's best; and Pathfinder's second.
final stored = _hex('BEEFAD77A277');
final pf1 = PathSelection(pathBytes: stored, hopCount: 3, hashSize: 2, useFlood: false);
final pf2 = PathSelection(
  pathBytes: _hex('5B98A277'),
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
);

class _Connector extends MeshCoreConnector {
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
  Future<Uint8List?> exportPrivateKey() async => bPrivateExport;

  @override
  Future<({String name, Uint8List key})?> getDefaultFloodScope() async => null;

  List<Uint8List> get acks =>
      sent.where((f) => f.isNotEmpty && f[0] == cmdSendRawPacket).toList();

  /// The multi_acks byte of each CMD_SET_OTHER_PARAMS sent.
  List<int> get radioMultiAcks => [
    for (final f in sent)
      if (f.isNotEmpty && f[0] == cmdSetOtherParams) f[4],
  ];
}

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(bPub);
  w.add(Uint8List(8));
  w.add([1, 0, 0, 1]); // the radio sends two ACKs
  w.add((ByteData(8)
        ..setUint32(0, 910525, Endian.little)
        ..setUint32(4, 62500, Endian.little))
      .buffer
      .asUint8List());
  w.add([7, 5]);
  w.add(utf8.encode('B'));
  return w.toBytes();
}

Uint8List _deviceInfo() {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = 14;
  f[2] = 175;
  f[3] = 40;
  f.setRange(60, 67, utf8.encode('v1.18.0'));
  f[81] = 1;
  return f;
}

Uint8List _contactFrame() {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(aPub);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0x43);
  w.add(Uint8List(maxPathSize)..setRange(0, stored.length, stored));
  w.add(Uint8List(maxNameSize)..setRange(0, 1, 'A'.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _rxLog(Uint8List packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  tearDown(() => c.dispose());

  Future<void> connect({
    bool pathfinder = true,
    List<PathSelection> routes = const [],
  }) async {
    final settings = AppSettingsService();
    await settings.setPathGraphEnabled(pathfinder);
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    if (pathfinder) c.graphRouteCandidates = (_) => routes;
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo());
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame());
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await c.preparePassingCopiesForTest();
  }

  Future<List<Uint8List>> acks(int count) async {
    for (var i = 0; i < 60 && c.acks.length < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return c.acks;
  }

  /// An ACK frame for CMD_SEND_RAW_PACKET, routed on [route] (2-byte hops),
  /// up to its random last byte.
  List<int> routedAck(List<int> route) => [
    cmdSendRawPacket, 0, 0x0E, 0x40 | route.length ~/ 2, ...route, ...ackHash,
  ];

  test('the radio is set to one ACK and the app sends the second, on '
      "Pathfinder's route the radio isn't holding", () async {
    await connect(routes: [pf1, pf2]);
    expect(c.radioMultiAcks, [0]);
    expect(c.twoAcks, isTrue, reason: 'the choice outlives the radio\'s one');

    c.handleFrameForTest(_rxLog(dmLastCopy));
    final sent = await acks(1);
    expect(sent, hasLength(1));
    expect(sent.single.sublist(0, 13), routedAck(pf2.pathBytes));
  });

  test('a DM that came by flood: the second ACK on Pathfinder\'s best route',
      () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFlood));
    final sent = await acks(1);
    expect(sent.single.sublist(0, 15), routedAck(stored));
  });

  test('one route only: the second ACK on that route again', () async {
    await connect(routes: [pf1]);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    final sent = await acks(1);
    expect(sent.single.sublist(0, 15), routedAck(stored));
  });

  test('a passing copy: the first ACK on the stored route, the second on '
      'the other', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    final sent = await acks(2);
    expect(sent, hasLength(2));
    expect(sent[0].sublist(0, 15), routedAck(stored));
    expect(sent[1].sublist(0, 13), routedAck(pf2.pathBytes));
  });

  test('every copy of one DM: one second ACK', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFlood));
    c.handleFrameForTest(_rxLog(dmFlood));
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await acks(1);
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(c.acks, hasLength(1));
  });

  test('Pathfinder off: the radio keeps sending both, the app none', () async {
    await connect(pathfinder: false);
    expect(c.radioMultiAcks, isEmpty);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(c.acks, isEmpty);
  });

  test('a manual disconnect gives the radio its second ACK back', () async {
    await connect(routes: [pf1, pf2]);
    expect(c.radioMultiAcks, [0]);
    await c.disconnect();
    expect(c.radioMultiAcks, [0, 1]);
  });

  test('turning Multi-ACKs off: one ACK, from the radio', () async {
    await connect(routes: [pf1, pf2]);
    await c.setTwoAcks(false);
    expect(c.twoAcks, isFalse);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(c.acks, isEmpty);
  });
}
