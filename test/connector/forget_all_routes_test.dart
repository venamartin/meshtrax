import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// "Forget all routes" resets every learned route on the radio, one
// acknowledged CMD_RESET_PATH at a time, so each relearns at the radio's
// current hash width on its next flood.
class _Connector extends MeshCoreConnector {
  bool connected = true;
  final resets = <Uint8List>[];
  // Reply per reset, in order; a missing entry means OK.
  final replies = <int>[];
  // Drop the link after this many resets have been sent.
  int? dropAfter;

  @override
  bool get isConnected => connected;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] != cmdResetPath) return;
    resets.add(data.sublist(1, 33));
    final reply = resets.length <= replies.length
        ? replies[resets.length - 1]
        : respCodeOk;
    if (dropAfter != null && resets.length >= dropAfter!) connected = false;
    scheduleMicrotask(() => handleFrameForTest(Uint8List.fromList([reply])));
  }
}

Uint8List _contactFrame(Uint8List pubKey, String name, {int pathLen = 0xFF}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeRepeater);
  w.addByte(0);
  w.addByte(pathLen);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final routed1 = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));
  final routed2 = Uint8List.fromList(List.generate(32, (i) => 0xBE + i));
  final flood = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Connector c;

  Contact byName(String n) => c.allContacts.firstWhere((x) => x.name == n);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 3, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(routed1, 'ONE', pathLen: 0x01));
    c.handleFrameForTest(_contactFrame(routed2, 'TWO', pathLen: 0x42));
    c.handleFrameForTest(_contactFrame(flood, 'FLOOD'));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
  });

  test('resets only the contacts that hold a route, keeping overrides', () async {
    await c.setPathOverride(byName('TWO'), pathLen: -1);

    final done = await c.forgetAllRoutes();

    expect(done, 2);
    expect(c.resets, [routed1, routed2]);
    expect(byName('ONE').pathLength, -1);
    expect(byName('TWO').pathLength, -1);
    expect(byName('TWO').pathOverride, -1, reason: 'the choice is kept');
    expect(byName('FLOOD').pathLength, -1);
  });

  test('a rejected reset leaves that route alone and is not counted', () async {
    c.replies.add(respCodeErr);

    final done = await c.forgetAllRoutes();

    expect(done, 1);
    expect(byName('ONE').pathLength, 1, reason: 'radio said no');
    expect(byName('TWO').pathLength, -1);
  });

  test('a link drop stops the run', () async {
    c.dropAfter = 1;

    final done = await c.forgetAllRoutes();

    expect(done, 1);
    expect(c.resets, hasLength(1));
  });
}
