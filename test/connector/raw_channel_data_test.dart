import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Photo chunks from the radio's raw log: a channel datagram routed through a
// repeater is decrypted with the live channel's key and handed over as a
// CHANNEL_DATA push would hand it over.
class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x40 + i));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 920000, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('Base'));
  return w.toBytes();
}

Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, 'Trip', _psk).sublist(1),
]);

/// [blob] as data type [type] on the channel keyed [key], sealed as the
/// firmware seals a GRP_DATA packet, and logged after the repeaters in
/// [path] ([width]-byte codes; repeater AB by default), sent direct unless
/// [flood].
Uint8List _logged(
  int type,
  List<int> blob,
  Uint8List key, {
  bool flood = false,
  List<int> path = const [0xAB],
  int width = 1,
}) {
  final plain = [type & 0xFF, type >> 8, blob.length, ...blob];
  final padded = Uint8List((plain.length + 15) ~/ 16 * 16)
    ..setRange(0, plain.length, plain);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, sealed, i);
  }
  final mac = crypto.Hmac(
    crypto.sha256,
    Uint8List(32)..setRange(0, 16, key),
  ).convert(sealed).bytes;
  return Uint8List.fromList([
    pushCodeLogRxData, 0x14, 0xA0, // SNR, RSSI
    (0x06 << 2) | (flood ? 0x01 : 0x02), // group datagram, flood or direct
    ((width - 1) << 6) | (path.length ~/ width), ...path, // its path
    crypto.sha256.convert(key).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late List<(int, int, List<int>, List<int>, int)> heard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    heard = [];
    c.onRawChannelData = (slot, type, blob, path, width) =>
        heard.add((slot, type, List.of(blob), List.of(path), width));
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
  });

  test('a photo chunk routed through a repeater is handed over', () {
    final blob = List.generate(157, (i) => i);
    c.handleFrameForTest(_logged(0x0170, blob, _psk));
    expect(heard, hasLength(1));
    expect(heard.single.$1, 1);
    expect(heard.single.$2, 0x0170);
    expect(heard.single.$3, blob);
    // A direct copy's path is the hops still to go, not who carried it.
    expect(heard.single.$4, isEmpty);
  });

  test('a flooded copy says which repeaters carried it', () {
    final blob = List.generate(157, (i) => 255 - i);
    c.handleFrameForTest(
      _logged(
        0x0170,
        blob,
        _psk,
        flood: true,
        path: [0xA2, 0x77, 0xBE, 0xEF],
        width: 2,
      ),
    );
    expect(heard, hasLength(1));
    expect(heard.single.$3, blob);
    expect(heard.single.$4, [0xA2, 0x77, 0xBE, 0xEF]);
    expect(heard.single.$5, 2);
  });

  test('a datagram for a channel this radio lacks is not', () {
    final other = Uint8List.fromList(List.filled(16, 0x11));
    c.handleFrameForTest(_logged(0x0170, [1, 2, 3], other));
    expect(heard, isEmpty);
  });

  test('deleting a channel message says which, for its photo', () async {
    final deleted = <String>[];
    c.onChannelMessageDeleted = deleted.add;
    final message = ChannelMessage(
      senderName: 'Alex',
      text: '📷 Photo #3a',
      timestamp: DateTime(2026, 11, 20, 12),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
    );
    await c.deleteChannelMessage(message);
    expect(deleted, [message.messageId]);
  });
}
