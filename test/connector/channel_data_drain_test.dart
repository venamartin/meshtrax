import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel_datagram.dart';
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
  0x71, 0x01, // data type, little-endian
  3, // data length
  1, 2, 3,
]);

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x40 + i));

Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, 'Desert trip', _psk).sublist(1),
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

  group('the datagrams themselves', () {
    late List<ChannelDatagram> got;

    setUp(() async {
      got = [];
      c.channelDatagrams.listen(got.add);
      c.handleFrameForTest([respCodeDeviceInfo, 14, 0, 0, 0, 0, 0, 0]);
      c.handleFrameForTest(_channelInfo());
      await pumpEventQueue(times: 200);
    });

    test('a datagram on a known channel comes out with its channel', () async {
      await startDrain();
      c.handleFrameForTest(_datagram());
      await pumpEventQueue();

      expect(got, hasLength(1));
      expect(got.single.channel.name, 'Desert trip');
      expect(got.single.dataType, 0x0171);
      expect(got.single.payload, [1, 2, 3]);
      expect(got.single.fromBacklog, isTrue, reason: 'the first drain');
    });

    test('a datagram cut short is only counted', () async {
      await startDrain();
      c.handleFrameForTest(_datagram().sublist(0, 10));
      await pumpEventQueue();

      expect(got, isEmpty);
      expect(c.syncRequests, 2);
    });

    test('a send floods the payload to the channel\'s slot, and the radio '
        'says whether it took it', () async {
      final channel = c.channels.single;
      final sent = c.sendChannelData(
        channel,
        0x0171,
        Uint8List.fromList([9, 8]),
      );
      await pumpEventQueue();
      expect(c.sent.last, [cmdSendChannelData, 1, 0xFF, 0x71, 0x01, 9, 8]);
      c.handleFrameForTest([respCodeOk]);
      expect(await sent, isTrue);

      final refused = c.sendChannelData(channel, 0x0171, Uint8List(1));
      await pumpEventQueue();
      c.handleFrameForTest([respCodeErr, 3]);
      expect(await refused, isFalse);
    });

    test('a radio before companion 1.15 sends none', () async {
      c.handleFrameForTest([respCodeDeviceInfo, 10, 0, 0, 0, 0, 0, 0]);
      c.sent.clear();
      expect(
        await c.sendChannelData(c.channels.single, 0x0171, Uint8List(1)),
        isFalse,
      );
      expect(c.sent, isEmpty);
    });
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
