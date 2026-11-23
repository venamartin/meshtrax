import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
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
  final _clock = Stopwatch()..start();

  /// When each ACK went out, in ms, in the order of [acks].
  final ackAtMs = <int>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
    if (data.isNotEmpty && data[0] == cmdSendRawPacket) {
      ackAtMs.add(_clock.elapsedMilliseconds);
    }
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

Uint8List _deviceInfo({bool clientRepeat = false}) {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = 14;
  f[2] = 175;
  f[3] = 40;
  f.setRange(60, 67, utf8.encode('v1.18.0'));
  f[80] = clientRepeat ? 1 : 0;
  f[81] = 1;
  return f;
}

/// Contact A as the radio holds it: with the stored route back, or none.
Uint8List _contactFrame({bool routeBack = true}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(aPub);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(routeBack ? 0x43 : 0xFF);
  w.add(Uint8List(maxPathSize)
    ..setRange(0, routeBack ? stored.length : 0, stored));
  w.add(Uint8List(maxNameSize)..setRange(0, 1, 'A'.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

bool _same(List<int> a, List<int> b) =>
    a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

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
    bool routeBack = true,
    bool clientRepeat = false,
  }) async {
    final settings = AppSettingsService();
    await settings.setPathGraphEnabled(pathfinder);
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    if (pathfinder) c.graphRouteCandidates = (_) => routes;
    c.handleFrameForTest(_deviceInfo(clientRepeat: clientRepeat));
    c.handleFrameForTest(_selfInfo());
    // SELF_INFO loads this radio's cached contacts, which replaces the list:
    // let it finish before the radio's contacts come in, or a test that waits
    // finds the contact gone.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(routeBack: routeBack));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await c.preparePassingCopiesForTest();
  }

  Future<List<Uint8List>> acks(int count) async {
    for (var i = 0; i < 60 && c.acks.length < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return c.acks;
  }

  /// A plain ACK for CMD_SEND_RAW_PACKET, routed on [route] (2-byte hops),
  /// up to its random last byte.
  List<int> plainAck(List<int> route, [List<int>? hash]) => [
    cmdSendRawPacket, 0, 0x0E, 0x40 | route.length ~/ 2, ...route,
    ...(hash ?? ackHash),
  ];

  /// The second ACK: MULTIPART, remaining 1, as the firmware's extra ACK.
  /// Repeaters drop a packet they've seen and the hash leaves the path out,
  /// so a plain copy of the first ACK would die at the first shared hop.
  List<int> secondAck(List<int> route, [List<int>? hash]) => [
    cmdSendRawPacket, 0, 0x2A, 0x40 | route.length ~/ 2, ...route, 0x13,
    ...(hash ?? ackHash),
  ];

  test('the radio is set to one ACK and the app sends the second, on '
      "Pathfinder's route the radio isn't holding", () async {
    await connect(routes: [pf1, pf2]);
    expect(c.radioMultiAcks, [0]);
    expect(c.twoAcks, isTrue, reason: 'the choice outlives the radio\'s one');

    c.handleFrameForTest(_rxLog(dmLastCopy));
    final sent = await acks(1);
    expect(sent, hasLength(1));
    expect(sent.single.sublist(0, 14), secondAck(pf2.pathBytes));
  });

  // The owner, 2026-11-22: Pathfinder ranks a contact's doorsteps by their
  // record, so its best route can end where they were heard before. An ACK
  // has one shot, and the flood copy's first repeater heard them seconds
  // ago.
  test('a DM that came by flood: the second ACK ends at the repeater that '
      'heard it, when Pathfinder has a route there', () async {
    final elsewhere = PathSelection(
      pathBytes: _hex('BEEF1000'),
      hopCount: 2,
      hashSize: 2,
      useFlood: false,
    );
    await connect(routes: [elsewhere, pf2]);
    c.handleFrameForTest(_rxLog(dmFlood)); // heard first by A277
    final sent = await acks(1);
    expect(sent.single.sublist(0, 14), secondAck(pf2.pathBytes),
        reason: 'pf2 ends at A277; the best route does not');
  });

  test('a DM that came by flood, with no route to the repeater that heard '
      'it: the second ACK on Pathfinder\'s best route', () async {
    final elsewhere = PathSelection(
      pathBytes: _hex('BEEF1000'),
      hopCount: 2,
      hashSize: 2,
      useFlood: false,
    );
    await connect(routes: [elsewhere]);
    c.handleFrameForTest(_rxLog(dmFlood));
    final sent = await acks(1);
    expect(sent.single.sublist(0, 14), secondAck(elsewhere.pathBytes));
  });

  test('a DM that came by flood: the second ACK on Pathfinder\'s best route',
      () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFlood));
    final sent = await acks(1);
    expect(sent.single.sublist(0, 16), secondAck(stored));
  });

  // Simulator, 2026-11-21: the radio hands the decoded DM over a sync
  // round-trip after it logs the copy, so the first DM after a contact
  // moved got its second ACK by where they were heard before.
  test('a flooded DM tells Pathfinder who heard the sender before the '
      'second ACK picks its route', () async {
    await connect(routes: [pf1]);
    // Pathfinder's ranking, which changes once it knows of the sighting.
    var routes = [pf1];
    c.graphRouteCandidates = (_) => routes;
    final opened = <({String contact, List<int> path, int width, int snr})>[];
    c.onFloodCopyOpened = (contact, path, width, snr, heard) {
      opened.add((contact: contact, path: path, width: width, snr: snr));
      expect(heard, payload);
      routes = [pf2, pf1];
    };

    c.handleFrameForTest(_rxLog(dmFlood));
    c.handleFrameForTest(_rxLog(dmFlood)); // another copy of the same send
    final sent = await acks(1);
    expect(opened, hasLength(1));
    expect(_hex(opened.single.contact), aPub);
    expect(opened.single.path, [0xA2, 0x77, 0xAD, 0x77],
        reason: 'the way the copy came: A277 heard the sender');
    expect(opened.single.width, 2);
    expect(opened.single.snr, 0x30);
    expect(sent.single.sublist(0, 14), secondAck(pf2.pathBytes));
  });

  test('a routed copy says nothing about who heard the sender', () async {
    await connect(routes: [pf1, pf2]);
    var opened = 0;
    c.onFloodCopyOpened = (_, _, _, _, _) => opened++;
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await acks(1);
    expect(opened, 0);
  });

  test('with Pathfinder itself: the second ACK goes by the repeater that '
      'just heard the sender, and the sighting counts once', () async {
    final settings = AppSettingsService();
    await settings.setPathGraphEnabled(true);
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo());
    final service = PathGraphService();
    await service.start(c, openDatabase: (_) => NativeDatabase.memory());
    addTearDown(service.stop);
    for (var i = 0; i < 100 && service.graph?.selfPubkey == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final graph = service.graph!;
    // SELF_INFO's load of the empty store would replace the list below.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame());
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await c.preparePassingCopiesForTest();
    // AD77 hears this radio and reaches A277, and nothing says yet who
    // hears A: Pathfinder has no route, only the radio's stored one.
    graph.reportSendResult(_hex('AD77A277'), true);
    final a = pubKeyToHex(aPub);
    expect(graph.ingressCandidates(a), isEmpty);

    c.handleFrameForTest(_rxLog(dmFlood)); // A's flood came A277, AD77
    final sent = await acks(1);
    expect(sent.single.sublist(0, 14), secondAck(_hex('AD77A277')),
        reason: 'A277 just heard A; the stored route is BEEF,AD77,A277');

    // The radio's decoded message, a sync round-trip later.
    c.handleFrameForTest(Uint8List.fromList([
      respCodeContactMsgRecvV3, 0x30, 0, 0,
      ...aPub.sublist(0, 6),
      0x42, // by flood, two 2-byte hops
      txtTypePlain,
      ...(ByteData(4)..setUint32(0, 1795283000, Endian.little))
          .buffer
          .asUint8List(),
      ...utf8.encode('hello'),
    ]));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final doorstep = graph.ingressCandidates(a).single;
    expect(doorstep.repeaterHash, 'A277');
    expect(doorstep.finalCount, 1, reason: 'one message, one sighting');
    expect(doorstep.weight, closeTo(3.0, 0.01));
  });

  test('one route only: the second ACK on that route again', () async {
    await connect(routes: [pf1]);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    final sent = await acks(1);
    expect(sent.single.sublist(0, 16), secondAck(stored));
  });

  test('a passing copy: a plain ACK on the stored route, then a MULTIPART '
      'one on the other, so no repeater takes it for the first', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    final sent = await acks(2);
    expect(sent, hasLength(2));
    expect(sent[0].sublist(0, 15), plainAck(stored));
    expect(sent[1].sublist(0, 14), secondAck(pf2.pathBytes));
  });

  test('the second ACK still follows the stand-in, which waited a moment, '
      'by the gap sendAckTo keeps', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    await acks(2);
    expect(c.ackAtMs, hasLength(2));
    expect(c.ackAtMs[1] - c.ackAtMs[0],
        greaterThanOrEqualTo(TimeoutHelper.extraAckGapMs - 50));
  });

  test("a passing copy, then the radio's own copy: the radio's ACK is the "
      'first, and the app sends only its second', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    // The last repeater's copy comes while the app still holds its ACKs.
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await acks(2);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(c.acks, hasLength(1));
    expect(c.acks.single.sublist(0, 14), secondAck(pf2.pathBytes));
  });

  test("the radio's copy handled just after the stand-in was due, by a busy "
      'app, still drops it', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    // The stand-in's time comes while the app is busy; the radio's own copy,
    // already waiting, is handled only after it (simulator, 2026-11-22).
    final hold = c.passingCopyHoldMsForTest(dmFromAd77.length, 1);
    await Future<void>.delayed(Duration(milliseconds: hold + 40));
    expect(c.acks, isEmpty, reason: 'the stand-in waits a moment first');
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await acks(1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(c.acks, hasLength(1));
    expect(c.acks.single.sublist(0, 14), secondAck(pf2.pathBytes));
  });

  test("the radio's copy after the app's ACKs went out: nothing more from "
      'the app', () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    await acks(2);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(c.acks, hasLength(2));
  });

  test("the radio's copy of another message leaves this one's stand-in",
      () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    // Another DM from A, the copy the radio opens itself.
    c.handleFrameForTest(_rxLog(_hex(
        '0A40E7C393761A4A07DC0918917FCB35FAED48C03AC74A7423DA8746EFCDAD090FFF9B5C3935')));
    final sent = await acks(3);
    expect(sent, hasLength(3));
    expect(sent.where((f) => _same(f.sublist(0, 15), plainAck(stored))), hasLength(1),
        reason: 'the stand-in for the first DM still goes');
  });

  test("the radio's flood copy of the message takes over the first ACK too",
      () async {
    await connect(routes: [pf1, pf2]);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    c.handleFrameForTest(_rxLog(dmFlood));
    await acks(2);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(c.acks, hasLength(1));
    expect(c.acks.single.sublist(0, 14), secondAck(pf2.pathBytes));
  });

  test('with repeat on, a copy the radio passes on itself keeps its stand-in',
      () async {
    // The next hop is this radio's own hash: it forwards the copy and marks
    // it seen, so it never opens the last repeater's copy (Mesh.cpp).
    await connect(routes: [pf1, pf2], clientRepeat: true);
    c.handleFrameForTest(_rxLog(Uint8List.fromList(
        [0x0A, 0x41, bPub[0], bPub[1], ...payload])));
    c.handleFrameForTest(_rxLog(dmLastCopy));
    final sent = await acks(2);
    expect(sent, hasLength(2));
    expect(sent[0].sublist(0, 15), plainAck(stored));
  });

  test("Pathfinder off: the radio sends both ACKs to its own copy, so the "
      "app's stand-ins are dropped", () async {
    await connect(pathfinder: false);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(c.acks, isEmpty);
  });

  test("Pathfinder off, no copy from the radio: the app's stand-ins go, "
      'both of them, as the radio would send them', () async {
    await connect(pathfinder: false);
    c.handleFrameForTest(_rxLog(dmFromAd77));
    final sent = await acks(2);
    expect(sent, hasLength(2));
    expect(sent[0].sublist(0, 16), secondAck(stored));
    expect(sent[1].sublist(0, 15), plainAck(stored));
  });

  test('each resend brings a new route in, then a flood', () async {
    // One DM sent three times (attempts 0-2, the same timestamp) on a
    // zero-hop route, as the firmware made them; the radio keeps holding
    // PF1 for the radio's own ACKs.
    final pf3 = PathSelection(
      pathBytes: _hex('77AA'),
      hopCount: 1,
      hashSize: 2,
      useFlood: false,
    );
    await connect(routes: [pf1, pf2, pf3]);
    final copies = [
      ('0A40E7C393761A4A07DC0918917FCB35FAED48C03AC74A7423DA8746EFCDAD090FFF9B5C3935', '11D715BA00'),
      ('0A40E7C3107AD378CE640B4D4963FBCC6609D301A6EF4A7423DA8746EFCDAD090FFF9B5C3935', '4F92885800'),
      ('0A40E7C38F00738E228366484BCAB03084A743013F4D4A7423DA8746EFCDAD090FFF9B5C3935', '783A0F9200'),
    ];
    // Back to back: the route for each is chosen as its copy is heard.
    for (final (frame, _) in copies) {
      c.handleFrameForTest(_rxLog(_hex(frame)));
    }
    final sent = await acks(3);
    expect(sent, hasLength(3));
    expect(sent[0].sublist(0, 14), secondAck(pf2.pathBytes, _hex(copies[0].$2)));
    expect(sent[1].sublist(0, 12), secondAck(pf3.pathBytes, _hex(copies[1].$2)));
    // Every route tried: a plain flood (a flooded MULTIPART goes nowhere).
    expect(sent[2].sublist(0, 9), [
      cmdSendRawPacket, 1, 0x0D, 0x40, ..._hex(copies[2].$2),
    ]);
  });

  test('no route back and none known: no second ACK, it would be the '
      "radio's flood again", () async {
    await connect(routes: const [], routeBack: false);
    c.handleFrameForTest(_rxLog(dmLastCopy));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(c.acks, isEmpty);
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
