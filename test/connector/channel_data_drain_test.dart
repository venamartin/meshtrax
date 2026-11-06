import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio queues every channel datagram it can read, from any app, and the
// app takes them off one by one with the other queued messages. A datagram the
// drain did not count held it for the 5 s timeout, and four in a row stopped it.
class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];
  int get syncRequests => sent.where((f) => f[0] == cmdSyncNextMessage).length;

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
}

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

// RESP_CODE_CHANNEL_DATA_RECV as companion firmware 1.18 writes it
// (MeshCore/examples/companion_radio/MyMesh.cpp onChannelDataRecv).
Uint8List _datagram() => Uint8List.fromList([
  respCodeChannelDataRecv,
  0x14, // SNR x4
  0, 0, // reserved
  1, // channel slot
  0xFF, // arrived direct
  0x54, 0xFF, // data type, little-endian
  3, // data length
  1, 2, 3,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    c.sent.clear();
  });

  Future<void> startDrain() async {
    c.handleFrameForTest([pushCodeMsgWaiting]);
    await pumpEventQueue();
    expect(c.isSyncingQueuedMessages, isTrue);
    expect(c.syncRequests, 1);
  }

  test('a datagram asks for the next message at once', () async {
    await startDrain();

    c.handleFrameForTest(_datagram());
    await pumpEventQueue();

    expect(c.syncRequests, 2, reason: 'no 5 s wait for the timeout');
  });

  test('four datagrams in a row do not stop the drain', () async {
    await startDrain();

    for (var i = 0; i < 4; i++) {
      c.handleFrameForTest(_datagram());
      await pumpEventQueue();
    }
    expect(c.syncRequests, 5);
    expect(c.isSyncingQueuedMessages, isTrue);

    c.handleFrameForTest([respCodeNoMoreMessages]);
    await pumpEventQueue();
    expect(c.isSyncingQueuedMessages, isFalse);
  });
}
