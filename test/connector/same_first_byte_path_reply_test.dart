import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/passing_copy.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// #365: a copy from a contact who shares this radio's first key byte reads
// the same as this radio's own DM to them, echoed back by a repeater; the
// guard is in PassingCopyOpener._open and openOwn. Path packets, read since
// #384 for their route and their ACK, take the same guard (regression
// audit, 2026-11-27). Keys as in test/helpers/passing_copy_test.dart: this
// radio is B.

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);

class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];
  @override
  bool get isConnected => true;
  @override
  Future<void> sendFrame(Uint8List data,
      {String? channelSendQueueId, bool expectsGenericAck = false}) async {
    sent.add(data);
  }

  @override
  Future<Uint8List?> exportPrivateKey() async => bPrivateExport;
  @override
  Future<({String name, Uint8List key})?> getDefaultFloodScope() async => null;
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

Uint8List _contactFrame(Uint8List key, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(key);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF); // no stored route
  w.add(Uint8List(maxPathSize));
  w.add(Uint8List(maxNameSize)..setRange(0, name.length, name.codeUnits));
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _rxLog(List<int> packet) =>
    Uint8List.fromList([pushCodeLogRxData, 0x30, 0xEC, ...packet]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("my own flooded path return to a contact who shares my first key "
      "byte, heard as a repeater passes it on, is not read as theirs",
      () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    final settings = AppSettingsService();
    await settings.setPathGraphEnabled(true);
    final c = _Connector()
      ..initialize(retryService: MessageRetryService(), appSettingsService: settings);
    c.graphRouteCandidates = (_) => const [];

    final opener = PassingCopyOpener(privateKey: bPrivateExport, selfKey: bPub);
    // A contact X whose key starts with this radio's first byte (1 in 256).
    Uint8List? xPub;
    for (var i = 0; i < 256 && xPub == null; i++) {
      final k = Uint8List.fromList(aPub)
        ..[0] = bPub[0]
        ..[31] = i;
      if (opener.sharedSecret(k) != null) xPub = k;
    }
    expect(xPub, isNotNull);

    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(xPub!, 'X'));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await c.preparePassingCopiesForTest();

    final heard = <String>[];
    c.onPathReplyHeard = (contact, path, width) => heard.add(
        '${contact.name} ${path.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}');

    // X's flooded DM reached me via AD77 then BEEF. My radio answers it the
    // firmware's way (BaseChatMesh::onPeerDataRecv): a flooded PATH to X
    // carrying THAT path (X's way TO me) plus the ACK. A277 passes my flood
    // on and my radio logs A277's copy.
    final secret = opener.sharedSecret(xPub)!;
    final myPathReturnToX = [
      (payloadTypePATH << 2) | 0x01, // PATH, flood
      0x41, 0xA2, 0x77, // heard from A277, one hop so far
      xPub[0], bPub[0], // dest X, src me: both 0xE7
      ...PassingCopyOpener.encryptThenMac(secret, [
        0x42, 0xAD, 0x77, 0xBE, 0xEF, // path X's DM took to me
        payloadTypeACK, 1, 2, 3, 4, 0, 9, // the ACK for X's DM
      ]),
    ];
    c.handleFrameForTest(_rxLog(myPathReturnToX));
    expect(heard, isEmpty,
        reason: 'this is my own packet: AD77,BEEF is the way X reaches me, '
            'not a route for me to reach X');
    c.dispose();
  });
}
