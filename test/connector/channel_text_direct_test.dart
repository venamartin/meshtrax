import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A channel text heard from its sender's own radio shows Direct: a flood's
// first copy, or a zero-hop one from a Nearby only channel, which comes
// DIRECT with no path, and with path length 0xFF in the radio's frame.
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

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

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

Uint8List _channelInfo() => Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(1, '#test', _psk).sublist(1),
    ]);

/// The radio's log of [sender]'s group text, sealed with the channel key as
/// the firmware seals it: flooded through [path] (1-byte codes; none for
/// the sender's own copy), or DIRECT with no path when [zeroHop].
Uint8List _heard(
  int secs,
  String sender,
  String text, {
  List<int> path = const [],
  bool zeroHop = false,
}) {
  final plain = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List())
    ..addByte(0)
    ..add(utf8.encode('$sender: $text'))
    ..addByte(0);
  final bytes = plain.toBytes();
  final padded = Uint8List((bytes.length + 15) ~/ 16 * 16)
    ..setRange(0, bytes.length, bytes);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(_psk));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, sealed, i);
  }
  final key32 = Uint8List(32)..setRange(0, 16, _psk);
  final mac = crypto.Hmac(crypto.sha256, key32).convert(sealed).bytes;
  return Uint8List.fromList([
    pushCodeLogRxData, 0x14, 0xA0, // SNR, RSSI
    (0x05 << 2) | (zeroHop ? 0x02 : 0x01), // group text, DIRECT or flood
    path.length, ...path,
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

/// The same text as the radio hands it over (V3), with the path length it
/// reports: 0xFF when it came direct.
Uint8List _frame(int secs, String sender, String text, int pathLen) =>
    Uint8List.fromList([
      respCodeChannelMsgRecvV3, 0x14, 0, 0, // SNR, reserved
      1, pathLen, 0, // channel slot, path length, plain text
      secs & 0xFF, (secs >> 8) & 0xFF, (secs >> 16) & 0xFF, (secs >> 24) & 0xFF,
      ...utf8.encode('$sender: $text'),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Channel channel;
  final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 30;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
  });

  Future<ChannelMessage> row(List<Uint8List> frames) async {
    for (final frame in frames) {
      c.handleFrameForTest(frame);
      await pumpEventQueue(times: 200);
    }
    return (await c.loadChannelMessagesFor(channel)).single;
  }

  group('a zero-hop text, as from a Nearby only channel, is Direct', () {
    test('heard in the raw log', () async {
      final m = await row([_heard(secs, 'Ann', 'At the gate', zeroHop: true)]);
      expect(m.heardDirect, isTrue);
      expect(m.pathLength, 0);
    });

    test('handed over by the radio, path length 0xFF', () async {
      final m = await row([_frame(secs, 'Ann', 'At the gate', 0xFF)]);
      expect(m.heardDirect, isTrue);
      expect(m.pathLength, 0, reason: 'Packet Path says Direct, not Flood');
    });

    test('both ways, as the radio gives it', () async {
      final m = await row([
        _heard(secs, 'Ann', 'At the gate', zeroHop: true),
        _frame(secs, 'Ann', 'At the gate', 0xFF),
      ]);
      expect(m.heardDirect, isTrue);
      expect(m.pathLength, 0);
    });
  });

  test('a flood heard before any repeater passed it on is Direct', () async {
    final m = await row([_heard(secs, 'Ann', 'Hello')]);
    expect(m.heardDirect, isTrue);
  });

  test('a text a repeater passed on is not', () async {
    final m = await row([
      _heard(secs, 'Ann', 'Hello', path: [0xAB]),
      _frame(secs, 'Ann', 'Hello', 1),
    ]);
    expect(m.heardDirect, isFalse);
    expect(m.pathLength, 1);
  });
}
