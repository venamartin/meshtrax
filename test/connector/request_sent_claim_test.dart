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

// The radio answers a DM, a login, a status/telemetry/binary/anon request
// and a trace with RESP_CODE_SENT. A request's SENT used to fall through to
// "promote the newest pending DM to sent", so a DM still queued in the app
// showed as sent although it never went out.
class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    recordOutgoingForTest(data);
  }
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

// RESP_CODE_SENT: [6][flood][tag x4][est_timeout x4]
Uint8List _sent(int tag) => Uint8List.fromList([
      respCodeSent,
      1,
      ...(ByteData(8)
            ..setUint32(0, tag, Endian.little)
            ..setUint32(4, 5000, Endian.little))
          .buffer
          .asUint8List(),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final sensorKey = Uint8List.fromList(List.generate(32, (i) => 0x31 + i));

  late _Connector c;
  Contact byName(String n) => c.allContacts.firstWhere((x) => x.name == n);

  Future<MessageStatus> dmStatus() async {
    final rows = await c.loadMessagesFor(byName('WHALE'));
    return rows.singleWhere((m) => m.isOutgoing).status;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey));
    // SELF_INFO starts the connector's own contact sync a moment later,
    // which clears the list; answer that sync rather than racing it.
    await settle();
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(peerKey, 'WHALE', advTypeChat));
    c.handleFrameForTest(_contactFrame(sensorKey, 'SENSOR', advTypeSensor));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    // A DM still in the app's hands: its own SENT never arrives here.
    await c.sendMessage(byName('WHALE'), 'hello');
    await settle();
    expect(await dmStatus(), MessageStatus.pending);
  });

  test("a request's SENT leaves a queued DM pending", () async {
    await c.sendFrame(buildSendBinaryReq(sensorKey,
        payload: Uint8List.fromList([reqTypeGetTelemetry])));
    c.handleFrameForTest(_sent(0x6712A3F0));
    await settle();

    expect(await dmStatus(), MessageStatus.pending);
  });

  test('every request kind claims its own SENT', () async {
    for (final frame in [
      buildSendStatusRequestFrame(sensorKey),
      buildSendTelemetryReq(sensorKey),
      buildSendBinaryReq(sensorKey, payload: Uint8List.fromList([0x05, 0, 0])),
    ]) {
      await c.sendFrame(frame);
      c.handleFrameForTest(_sent(0x6712A3F0));
    }
    await settle();

    expect(await dmStatus(), MessageStatus.pending);
  });

  test('an unclaimed SENT still reaches the pending-DM fallback', () async {
    // Self telemetry names no contact: the radio pushes the reading
    // straight back instead of answering SENT, so it claims nothing.
    await c.sendFrame(buildSendTelemetryReq(null));
    c.handleFrameForTest(_sent(0x11223344));
    await settle();

    expect(await dmStatus(), MessageStatus.sent);
  });
}
