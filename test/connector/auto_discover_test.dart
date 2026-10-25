import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// What the connector gives the automatic Discover: the radio's OK for the
// request is claimed (a queued channel message must not take it), the
// dialog can tell whose Discover it was, and Discovers that are not ours
// are noticed, because repeaters answer 4 per 2 minutes for everyone.
class _Connector extends MeshCoreConnector {
  final sent = <({int code, bool expectsAck})>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add((code: data[0], expectsAck: expectsGenericAck));
  }
}

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => seed + i));

Uint8List _answer(Uint8List key, int tag) {
  final w = BytesBuilder();
  w.add([pushCodeControlData, 35, 0xA0, 0]);
  w.add([ctlTypeNodeDiscoverResp | advTypeRepeater, 26]);
  w.add((ByteData(4)..setUint32(0, tag, Endian.little)).buffer.asUint8List());
  w.add(key);
  return w.toBytes();
}

Uint8List _request() {
  final w = BytesBuilder();
  w.add([pushCodeControlData, 35, 0xA0, 0]);
  w.add([ctlTypeNodeDiscoverReq, 0x04, 1, 2, 3, 4, 0, 0, 0, 0]);
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test('the request claims its OK and remembers who asked', () async {
    final c = _Connector();
    await c.sendRepeaterDiscovery(automatic: true);
    expect(c.sent.single.code, cmdSendControlData);
    expect(c.sent.single.expectsAck, isTrue);
    expect(c.lastDiscoverAutomatic, isTrue);
    await c.sendRepeaterDiscovery();
    expect(c.lastDiscoverAutomatic, isFalse);
  });

  test('a Discover that is not ours is noticed, ours is not', () async {
    final c = _Connector();
    expect(c.foreignDiscoverHeardAt, isNull);
    await c.sendRepeaterDiscovery();
    c.handleFrameForTest(_answer(_key(0x10), c.pendingDiscoverTag!));
    expect(c.foreignDiscoverHeardAt, isNull, reason: 'our own answer');
    c.handleFrameForTest(_answer(_key(0x20), c.pendingDiscoverTag! ^ 1));
    expect(c.foreignDiscoverHeardAt, isNotNull, reason: 'another tag');
    c.handleFrameForTest(_request());
    expect(c.foreignDiscoverHeardAt, isNotNull, reason: 'a request');
  });
}
