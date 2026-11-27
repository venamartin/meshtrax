import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/passing_copy.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio logs every packet it hears, so it logs its first repeater
// passing on a routed DM this radio just sent. The app reads that copy with
// the radio's key and knows the DM left the repeater; not heard, it has the
// radio send the same packet once more (field 2026-11-24). Keys as in
// test/helpers/passing_copy_test.dart: this radio is B, the contact A.
Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);

// Pathfinder's route to A, which the radio already holds.
final route = _hex('BEEFAD77A277');
final toA = PathSelection(
  pathBytes: route,
  hopCount: 3,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.7,
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

  List<Uint8List> get dms =>
      sent.where((f) => f.isNotEmpty && f[0] == cmdSendTxtMsg).toList();
}

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(bPub);
  w.add(Uint8List(8));
  w.add([1, 0, 0, 1]);
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
  w.add(Uint8List(maxPathSize)..setRange(0, route.length, route));
  w.add(Uint8List(maxNameSize)..setRange(0, 1, 'A'.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _rxLog(List<int> packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

// A channel message that came by flood with BEEF as its last repeater: the
// radio hears BEEF.
final heardBeef = _rxLog([0x15, 0x41, 0xBE, 0xEF, ...List.filled(24, 0x5A)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Contact a;
  late List<String> proved;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    final settings = AppSettingsService();
    await settings.setPathGraphEnabled(true);
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.graphRouteCandidates = (_) => [toA];
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame());
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await c.preparePassingCopiesForTest();
    a = c.contacts.firstWhere((x) => x.name == 'A');
    proved = [];
    c.onOwnCopyPassedOn = (contact, selection) => proved.add(
        '${contact.name} ${selection.pathBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}');
  });

  tearDown(() => c.dispose());

  Future<void> until(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// The radio takes the DM in [frame]: its SENT, on a route.
  void radioTook(Uint8List frame) {
    final ack = MessageRetryService.computeExpectedAckHash(
      ByteData.sublistView(frame, 3, 7).getUint32(0, Endian.little),
      frame[2],
      utf8.decode(frame.sublist(13, frame.length - 1)),
      bPub,
    );
    c.handleFrameForTest(Uint8List.fromList([
      respCodeSent,
      0,
      ...(ByteData(8)
            ..setUint32(0, ack, Endian.little)
            ..setUint32(4, 9000, Endian.little))
          .buffer
          .asUint8List(),
    ]));
  }

  /// The DM in [frame] as a repeater passes it on, [hopsLeft] still to go:
  /// built the way the radio builds it (BaseChatMesh::composeMsgPacket).
  Uint8List passedOn(Uint8List frame, List<int> hopsLeft) {
    final secret = PassingCopyOpener(privateKey: bPrivateExport, selfKey: bPub)
        .sharedSecret(aPub)!;
    return _rxLog([
      0x0A,
      0x40 | hopsLeft.length ~/ 2,
      ...hopsLeft,
      aPub[0],
      bPub[0],
      ...PassingCopyOpener.encryptThenMac(secret, [
        ...frame.sublist(3, 7),
        frame[2] & 3,
        ...frame.sublist(13, frame.length - 1),
      ]),
    ]);
  }

  test('BEEF is heard passing my DM on: Pathfinder is told it heard me, and '
      'the DM is not sent again', () async {
    c.handleFrameForTest(heardBeef);
    unawaited(c.sendMessage(a, 'hello A'));
    await until(() => c.dms.isNotEmpty);
    radioTook(c.dms.single);

    c.handleFrameForTest(passedOn(c.dms.single, _hex('AD77A277')));
    expect(proved, ['A BEEFAD77A277']);

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(c.dms, hasLength(1));
  });

  test('BEEF is not heard passing it on: the radio is handed the same DM once '
      'more', () async {
    c.handleFrameForTest(heardBeef);
    unawaited(c.sendMessage(a, 'hello A'));
    await until(() => c.dms.isNotEmpty);
    radioTook(c.dms.single);

    await until(() => c.dms.length > 1);
    expect(c.dms, hasLength(2));
    expect(c.dms[1], c.dms[0], reason: 'the same number, time and text');
    expect(proved, isEmpty);
  });

  test('a repeater this radio has not heard lately is not waited for',
      () async {
    unawaited(c.sendMessage(a, 'hello A'));
    await until(() => c.dms.isNotEmpty);
    radioTook(c.dms.single);

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(c.dms, hasLength(1));
  });

  test("another radio's DM to A with my first key byte is not mine: its MAC "
      'fails', () async {
    c.handleFrameForTest(heardBeef);
    unawaited(c.sendMessage(a, 'hello A'));
    await until(() => c.dms.isNotEmpty);
    radioTook(c.dms.single);

    final copy = passedOn(c.dms.single, _hex('AD77A277'));
    copy[copy.length - 1] ^= 1;
    c.handleFrameForTest(copy);
    expect(proved, isEmpty);
  });

  // Another radio's channel flood with 1-byte path codes, last passed on
  // by some repeater whose code starts with BE. That is not BEEF: BEEF has
  // not been heard at all, so its silence says nothing (regression audit,
  // 2026-11-27).
  test('a 1-byte flood ending at BE is not a sighting of BEEF', () async {
    c.handleFrameForTest(
        _rxLog([0x15, 0x01, 0xBE, ...List.filled(24, 0x5A)]));
    unawaited(c.sendMessage(a, 'hello A'));
    await until(() => c.dms.isNotEmpty);
    radioTook(c.dms.single);

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(c.dms, hasLength(1),
        reason: 'the DM is not sent again for a repeater never heard');
  });
}
