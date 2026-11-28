import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/meshtrax_dm.dart';
import 'package:meshtrax/helpers/meshtrax_packet.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxproto/traxproto.dart';

// MeshTrax's own DM: a packet the other phone built, which the radio knows
// no channel for and only logs. The app opens it from any copy heard, stores
// it like any DM, and answers with MeshTrax's ACK on its own route to the
// sender. Bench, 2026-11-27, 920.000 MHz, through repeater A277: such a
// packet floods and routes, and both radios hand every copy to the app. The
// keys are the simulation keys of passing_copy_connector_test.
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
const sentAt = 1795046400;
const said = 'Are you at the trailhead yet?';
// B's stored route back to A.
final routeBack = _hex('BEEFAD77A277');

/// A's DM to B (A's key sorts below B's), as its payload.
Uint8List _dm({
  int number = 7,
  int tryNumber = 0,
  List<int>? route,
  List<int>? hears,
  List<int>? heardBy,
}) {
  final text = MeshTraxDmText.pack(said);
  return MeshTraxPacket.seal(
    secret,
    toByte: bPub[0],
    fromByte: aPub[0],
    dataType: dataTypeMeshTraxDm,
    blob: frameDirect(
      DirectMessage(
        number: number,
        tryNumber: tryNumber,
        time: sentAt,
        route: route,
        hears: hears,
        heardBy: heardBy,
        packing: text.packing,
        text: text.bytes,
      ).encode(),
      senderSortsAbove: false,
    ),
  );
}

/// [payload] as a flood that has passed [path].
Uint8List _flooded(Uint8List payload, String path) => Uint8List.fromList([
  (payloadTypeGRPDATA << 2) | 0x01,
  0x40 | (path.length ~/ 4),
  ..._hex(path),
  ...payload,
]);

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

Uint8List _contactFrame(Uint8List pubKey, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0x43); // 3 hops, 2 bytes each
  w.add(Uint8List(maxPathSize)..setRange(0, routeBack.length, routeBack));
  w.add(Uint8List(maxNameSize)..setRange(0, name.length, name.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

// Heard at +12 dB.
Uint8List _rxLog(Uint8List packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Contact a;

  Future<void> connect({bool keyExport = true, int verCode = 14}) async {
    c = _Connector(keyExport: keyExport);
    c.handleFrameForTest(_deviceInfo(verCode));
    c.handleFrameForTest(_selfInfo(bPub));
    // SELF_INFO loads the contact cache, which replaces the list a moment
    // later: contacts fed before that are lost.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(aPub, 'A'));
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

  /// The ACK inside the raw-send frame [frame], which must be routed on the
  /// stored route back.
  DirectAck ackIn(Uint8List frame) {
    expect(frame.sublist(0, 4 + routeBack.length), [
      cmdSendRawPacket, 0, (payloadTypeGRPDATA << 2) | 0x02, 0x43, ...routeBack,
    ]);
    final payload = frame.sublist(4 + routeBack.length);
    expect(payload.sublist(0, 2), [aPub[0], bPub[0]], reason: 'to A, from B');
    final opened = MeshTraxPacket.open(secret, payload)!;
    expect(opened.dataType, dataTypeMeshTraxAck);
    final framed = unframeDirect(opened.blob)!;
    expect(framed.senderSortsAbove, isTrue, reason: "B's key sorts above A's");
    return DirectAck.decode(framed.message)!;
  }

  test('a flooded DM is stored and answered with our ACK on my route to them',
      () async {
    await connect();
    expect(c.runsMeshTrax(a.publicKeyHex), isFalse);
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));

    final m = (await rows()).single;
    expect(m.text, said);
    expect(m.isOutgoing, isFalse);
    expect(m.timestamp.millisecondsSinceEpoch, sentAt * 1000);
    expect(c.runsMeshTrax(a.publicKeyHex), isTrue);

    final ack = ackIn((await rawPackets(1)).single);
    expect(ack.number, 7);
    expect(ack.tryNumber, 0);
    expect(ack.triesArrived, 1);
    expect(ack.cameBy, _hex('A277'), reason: 'the repeaters the flood passed');
    expect(ack.level, 12);
    expect(ack.route, routeBack);
  });

  test('another copy of the same try: one message, one ACK', () async {
    await connect();
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277BEEF')));
    await rawPackets(1);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(await rows(), hasLength(1));
    expect(c.rawPackets, hasLength(1));
  });

  test('the next try of the same message: still one message, its own ACK',
      () async {
    await connect();
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
    await rawPackets(1);
    c.handleFrameForTest(_rxLog(_flooded(_dm(tryNumber: 1), 'A277')));

    final acks = await rawPackets(2);
    expect(acks, hasLength(2));
    final second = ackIn(acks[1]);
    expect(second.tryNumber, 1);
    expect(second.triesArrived, 3, reason: 'tries 0 and 1 have arrived');
    expect(acks[0], isNot(acks[1]),
        reason: 'the same bytes would die at every repeater that carried '
            'the first');
    expect(await rows(), hasLength(1));
  });

  test('a routed copy heard with hops to go is opened, and says how far it '
      'had come', () async {
    await connect();
    final payload = _dm(route: _hex('A277AD77BEEF'));
    // As AD77 passes it on: BEEF still to go.
    c.handleFrameForTest(_rxLog(Uint8List.fromList([
      (payloadTypeGRPDATA << 2) | 0x02, 0x41, 0xBE, 0xEF, ...payload,
    ])));

    expect((await rows()).single.text, said);
    final ack = ackIn((await rawPackets(1)).single);
    expect(ack.cameBy, _hex('A277AD77'));
  });

  test('my own packet, heard as a repeater passes it on, is not from them',
      () async {
    await connect();
    final mine = MeshTraxPacket.seal(
      secret,
      toByte: aPub[0],
      fromByte: bPub[0],
      dataType: dataTypeMeshTraxDm,
      blob: frameDirect(
        DirectMessage(number: 1, time: sentAt, text: utf8.encode('mine'))
            .encode(),
        senderSortsAbove: true,
      ),
    );
    c.handleFrameForTest(_rxLog(_flooded(mine, 'A277')));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(await rows(atLeast: 0), isEmpty);
    expect(c.rawPackets, isEmpty);
  });

  test("their ACK is handed over, and marks them as on MeshTrax", () async {
    await connect();
    final heard = <DirectAck>[];
    c.onMeshTraxAckHeard = (contact, ack) {
      expect(contact.publicKeyHex, a.publicKeyHex);
      heard.add(ack);
    };
    final ack = MeshTraxPacket.seal(
      secret,
      toByte: bPub[0],
      fromByte: aPub[0],
      dataType: dataTypeMeshTraxAck,
      blob: frameDirect(
        DirectAck(number: 3, tryNumber: 2, triesArrived: 4, level: -6).encode(),
        senderSortsAbove: false,
      ),
    );
    c.handleFrameForTest(_rxLog(_flooded(ack, 'BEEF')));
    expect(heard.single.number, 3);
    expect(heard.single.tryNumber, 2);
    expect(heard.single.level, -6);
    expect(c.runsMeshTrax(a.publicKeyHex), isTrue);
    expect(await rows(atLeast: 0), isEmpty);
    expect(c.rawPackets, isEmpty, reason: 'an ACK is not answered');
  });

  test('a later version, or a packing this MeshTrax does not know, is left '
      'unread', () async {
    await connect();
    final later = MeshTraxPacket.seal(secret,
        toByte: bPub[0],
        fromByte: aPub[0],
        dataType: dataTypeMeshTraxDm,
        blob: [0x20, ...DirectMessage(number: 1, text: utf8.encode('x')).encode()]);
    final packed = MeshTraxPacket.seal(secret,
        toByte: bPub[0],
        fromByte: aPub[0],
        dataType: dataTypeMeshTraxDm,
        blob: frameDirect(
            DirectMessage(number: 2, packing: 9, text: [1, 2, 3]).encode(),
            senderSortsAbove: false));
    c.handleFrameForTest(_rxLog(_flooded(later, 'A277')));
    c.handleFrameForTest(_rxLog(_flooded(packed, 'A277')));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(await rows(atLeast: 0), isEmpty);
    expect(c.rawPackets, isEmpty);
  });

  // Owner, 2026-11-28, a contact who has driven from home to Santa Cruz:
  // the route the radio holds leads to where they were. With Pathfinder
  // running the ACK goes Pathfinder's way or by flood, and each further
  // try's ACK takes another way.
  group("with Pathfinder running, the ACK goes Pathfinder's way", () {
    PathSelection way(String hex, double est) => PathSelection(
          pathBytes: _hex(hex),
          hopCount: hex.length ~/ 4,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: est,
        );

    /// How the raw-send frame [frame] goes: its route as hex, or 'flood'.
    String wayOf(Uint8List frame) {
      if (frame[2] & 0x03 != 0x02) return 'flood';
      final hops = frame[3] & 0x3F;
      return frame
          .sublist(4, 4 + hops * 2)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
    }

    test('no route from Pathfinder: a flood, not the route the radio holds',
        () async {
      await connect();
      c.graphRouteCandidates = (_) => const [];
      c.handleFrameForTest(_rxLog(_flooded(_dm(), '1000')));
      final frame = (await rawPackets(1)).single;
      expect(wayOf(frame), 'flood',
          reason: 'the stored route BEEF,AD77,A277 leads to where they were');
      final ack = DirectAck.decode(unframeDirect(
              MeshTraxPacket.open(secret, frame.sublist(4))!.blob)!
          .message)!;
      expect(ack.route, isEmpty);
    });

    test('each try of a message is answered another way, then by flood',
        () async {
      await connect();
      c.graphRouteCandidates =
          (_) => [way('10007777', 0.6), way('1000C419', 0.5)];
      for (var t = 0; t < 4; t++) {
        c.handleFrameForTest(_rxLog(_flooded(_dm(tryNumber: t), '1000')));
        await rawPackets(t + 1);
      }
      expect([for (final f in c.rawPackets) wayOf(f)],
          ['10007777', '1000C419', 'flood', 'flood']);
    });

    test('the next message starts from the best way again', () async {
      await connect();
      c.graphRouteCandidates =
          (_) => [way('10007777', 0.6), way('1000C419', 0.5)];
      c.handleFrameForTest(_rxLog(_flooded(_dm(number: 7), '1000')));
      await rawPackets(1);
      c.handleFrameForTest(_rxLog(_flooded(_dm(number: 8), '1000')));
      await rawPackets(2);
      expect([for (final f in c.rawPackets) wayOf(f)], ['10007777', '10007777']);
    });

    // Owner, 2026-11-28: the ACK's data must not go to waste. A message
    // sent again says the ACK of the try before did not arrive.
    test('they send it again: Pathfinder is told the way that lost the ACK',
        () async {
      await connect();
      c.graphRouteCandidates =
          (_) => [way('10007777', 0.6), way('1000C419', 0.5)];
      final lost = <String>[];
      c.onMeshTraxAckLost = (contact, route) => lost.add(
          '${contact.name}:${PathHelper.formatPathHex(route.pathBytes, stride: 2)}');
      c.handleFrameForTest(_rxLog(_flooded(_dm(), '1000')));
      await rawPackets(1);
      // Another copy of the same try says nothing.
      c.handleFrameForTest(_rxLog(_flooded(_dm(), '1000BEEF')));
      expect(lost, isEmpty);
      c.handleFrameForTest(_rxLog(_flooded(_dm(tryNumber: 1), '1000')));
      await rawPackets(2);
      expect(lost, ['A:1000,7777']);
      // The third try's ACK went by 1000,C419; the fourth's is a flood, and
      // a flood has no route to hold anything against.
      c.handleFrameForTest(_rxLog(_flooded(_dm(tryNumber: 2), '1000')));
      await rawPackets(3);
      c.handleFrameForTest(_rxLog(_flooded(_dm(tryNumber: 3), '1000')));
      await rawPackets(4);
      expect(lost, ['A:1000,7777', 'A:1000,C419']);
    });

    test('a route the user pinned is used as the radio holds it', () async {
      await connect();
      c.graphRouteCandidates = (_) => [way('10007777', 0.6)];
      await c.setPathOverride(a, pathLen: 3, pathBytes: routeBack);
      a = c.contacts.single;
      c.handleFrameForTest(_rxLog(_flooded(_dm(), '1000')));
      expect(wayOf((await rawPackets(1)).single), 'BEEFAD77A277');
    });
  });

  // What Pathfinder is told: as of a flooded firmware DM the app opened,
  // the repeaters the copy had passed, whose first heard the sender.
  group('Pathfinder hears of it', () {
    late List<(String, List<int>, int, int)> told;
    Future<void> listen() async {
      await connect();
      told = [];
      c.onFloodCopyOpened = (key, path, width, snr, payload) =>
          told.add((key, path, width, snr));
    }

    test('a flooded DM: the path it came by', () async {
      await listen();
      c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277BEEF')));
      final (key, path, width, snr) = told.single;
      expect(key, a.publicKeyHex);
      expect(path, _hex('A277BEEF'));
      expect(width, 2);
      expect(snr, 0x30);
    });

    test('a routed DM on its way: its route as far as it had come', () async {
      await listen();
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x41, 0xBE, 0xEF,
        ..._dm(route: _hex('A277AD77BEEF')),
      ])));
      expect(told.single.$2, _hex('A277AD77'));
    });

    test('a routed DM heard from their own radio: no repeater between us',
        () async {
      await listen();
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x43, ..._hex('A277AD77BEEF'),
        ..._dm(route: _hex('A277AD77BEEF')),
      ])));
      expect(told.single.$2, isEmpty);
    });

    test('a routed packet: the links between the repeaters it passed, each '
        'once', () async {
      await listen();
      final links = <(List<int>, int)>[];
      c.onMeshTraxRouteTravelled =
          (travelled, width) => links.add((travelled, width));
      final payload = _dm(route: _hex('A277AD771000BEEF'));
      // As AD77 passes it on, then as BEEF hands it over.
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x42, ..._hex('1000BEEF'), ...payload,
      ])));
      expect(links.single.$1, _hex('A277AD77'));
      expect(links.single.$2, 2);
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x40, ...payload,
      ])));
      expect(links, hasLength(2));
      expect(links[1].$1, _hex('AD771000BEEF'),
          reason: 'from the last repeater told of: A277>AD77 is not twice');
      // The same copy again adds nothing.
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x40, ...payload,
      ])));
      expect(links, hasLength(2));
    });

    test('a flood, or a route of one repeater, has no link inside it',
        () async {
      await listen();
      var called = 0;
      c.onMeshTraxRouteTravelled = (_, _) => called++;
      c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277BEEF')));
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x40, ..._dm(number: 9, route: _hex('A277')),
      ])));
      expect(called, 0);
    });

    test('a route that does not fit the hops still to go says nothing',
        () async {
      await listen();
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x41, 0xBE, 0xEF,
        ..._dm(route: _hex('A2771000')),
      ])));
      expect(told, isEmpty);
      expect((await rows()).single.text, said, reason: 'still a message');
    });

    test('their ACK: the way it came', () async {
      await listen();
      final ack = MeshTraxPacket.seal(
        secret,
        toByte: bPub[0],
        fromByte: aPub[0],
        dataType: dataTypeMeshTraxAck,
        blob: frameDirect(
          DirectAck(number: 3, route: _hex('A277BEEF')).encode(),
          senderSortsAbove: false,
        ),
      );
      // As A277 passes it on: BEEF still to go.
      c.handleFrameForTest(_rxLog(Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | 0x02, 0x41, 0xBE, 0xEF, ...ack,
      ])));
      expect(told.single.$2, _hex('A277'));
    });
  });

  // Owner, 2026-11-27: "We know what we can hear and we know what can hear
  // us." Each phone sends its two lists; Pathfinder gets the other phone's.
  group('the repeaters each phone hears and is heard by', () {
    test("their lists in a DM are handed to Pathfinder", () async {
      await connect();
      final got = <(List<int>, List<int>, int)>[];
      c.onMeshTraxEnds =
          (contact, hears, heardBy, width) => got.add((hears, heardBy, width));
      c.handleFrameForTest(_rxLog(_flooded(
          _dm(hears: _hex('100085'), heardBy: _hex('A2778A630B00')), 'A277')));
      final (hears, heardBy, width) = got.single;
      expect(hears, _hex('100085'));
      expect(heardBy, _hex('A2778A630B00'));
      expect(width, 2);
    });

    test('a DM without them hands nothing over', () async {
      await connect();
      var calls = 0;
      c.onMeshTraxEnds = (_, _, _, _) => calls++;
      c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
      expect(calls, 0);
    });

    test("my lists go in the ACK", () async {
      await connect();
      c.meshTraxEnds = (width) {
        expect(width, 2);
        return (hears: _hex('BEEF88'), heardBy: _hex('BEEF00A2777F'));
      };
      c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
      final ack = ackIn((await rawPackets(1)).single);
      expect(ack.hears, _hex('BEEF88'));
      expect(ack.heardBy, _hex('BEEF00A2777F'));
    });
  });

  // Owner, 2026-11-27: "a photo send would tell us too."
  test('a photo packet on a channel marks its sender, and it is remembered',
      () async {
    await connect();
    var told = 0;
    c.addListener(() => told++);
    // RESP_CODE_CHANNEL_DATA_RECV: slot 0, data type 0x0172, a photo packet
    // that starts with the first two bytes of A's key.
    final blob = [aPub[0], aPub[1], 7, 0x12, 0, 1, 2, 3];
    c.handleFrameForTest(Uint8List.fromList(
        [27, 0x30, 0, 0, 0, 0xFF, 0x72, 0x01, blob.length, ...blob]));
    expect(c.runsMeshTrax(a.publicKeyHex), isTrue);
    // Redraws are gathered up and sent a moment later.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(told, greaterThan(0), reason: 'the contact list redraws');

    // Another run of the app.
    c.dispose();
    c = _Connector();
    expect(c.runsMeshTrax(a.publicKeyHex), isTrue);
  });

  test('a photo packet from a key no chat contact starts with marks nobody',
      () async {
    await connect();
    final blob = [0x11, 0x22, 7, 0x12, 0, 1, 2, 3];
    c.handleFrameForTest(Uint8List.fromList(
        [27, 0x30, 0, 0, 0, 0xFF, 0x72, 0x01, blob.length, ...blob]));
    expect(c.runsMeshTrax(a.publicKeyHex), isFalse);
  });

  test("without the radio's key nothing is opened", () async {
    await connect(keyExport: false);
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(await rows(atLeast: 0), isEmpty);
    expect(c.rawPackets, isEmpty);
  });

  test('firmware before 1.16: the message, but no ACK it cannot send',
      () async {
    await connect(verCode: 12);
    c.handleFrameForTest(_rxLog(_flooded(_dm(), 'A277')));
    expect((await rows()).single.text, said);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(c.rawPackets, isEmpty);
  });
}
