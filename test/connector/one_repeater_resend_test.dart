import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The owner, 2026-11-19: one heard repeat ended a channel send even when
// only his home repeater carried it, and no observer heard it. While
// observers hear this radio, such a message goes out once more
// (packages/traxheard/README.md).
class _Connector extends MeshCoreConnector {
  bool connected = true;
  final written = <Uint8List>[];

  @override
  bool get isConnected => connected;

  @override
  Future<void> writeToTransport(Uint8List data) async => written.add(data);

  List<Uint8List> get channelSends =>
      written.where((f) => f[0] == cmdSendChannelTxtMsg).toList();
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

/// The radio's log of our own channel text coming back through [hops]
/// (2-byte repeater codes), sealed as the firmware seals it.
Uint8List _echo(int secs, String text, List<int> hops) {
  final plain = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List())
    ..addByte(0)
    ..add(utf8.encode('GWQ: $text'));
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
    (0x05 << 2) | 0x01, // group text, flood
    (1 << 6) | hops.length, // 2-byte codes
    for (final hop in hops) ...[hop >> 8, hop & 0xFF],
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

typedef _Send = ({String messageId, int secs, String text});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repeatWait = MeshCoreConnector.channelRepeatWait;
  late _Connector c;
  late Channel channel;
  late AppSettingsService settings;
  late List<_Send> stamped;
  late List<String> resent;
  late bool observersHearUs;
  late Set<String> carRepeaters;

  setUp(() async {
    MeshCoreConnector.channelRepeatWait = const Duration(milliseconds: 300);
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    settings = AppSettingsService();
    await settings.loadSettings();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    stamped = [];
    resent = [];
    observersHearUs = true;
    carRepeaters = {};
    c.onChannelSendStamped = (s) =>
        stamped.add((messageId: s.messageId, secs: s.secs, text: s.text));
    c.mayResendAfterOneRepeater = (_) => observersHearUs;
    c.onResentAfterOneRepeater = resent.add;
    c.isCarRepeater = (hop, width) =>
        carRepeaters.contains(PathHelper.hopHex(hop));
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
  });

  tearDown(() {
    // A send still waiting for radio quiet goes nowhere.
    c.connected = false;
    MeshCoreConnector.channelRepeatWait = repeatWait;
  });

  Future<void> wait(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Sends a message and the radio takes it: Sent, and the wait for a
  /// repeat starts.
  Future<_Send> send() async {
    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeOk]);
    await pumpEventQueue(times: 200);
    return stamped.last;
  }

  Future<void> hear(_Send send, List<int> hops) async {
    c.handleFrameForTest(_echo(send.secs, send.text, hops));
    await pumpEventQueue(times: 200);
  }

  Future<ChannelMessage> row() async =>
      (await c.loadChannelMessagesFor(channel)).single;

  test('one repeater and no observer: sent once more, still delivered',
      () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    expect((await row()).status, ChannelMessageStatus.delivered);
    expect(resent, isEmpty, reason: 'it waits for the observer asks');

    await wait(500);
    expect(resent, [sent.messageId]);
    expect((await row()).status, ChannelMessageStatus.delivered);
  });

  test('two repeaters are enough', () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    expect(c.isChannelMessageRetrying(sent.messageId), isTrue);
    await hear(sent, [0xBEEF]);
    expect(c.isChannelMessageRetrying(sent.messageId), isFalse);
    await wait(500);
    expect(resent, isEmpty);
    expect(c.channelSends, hasLength(1));
  });

  test('one copy that came through two repeaters is enough', () async {
    final sent = await send();
    await hear(sent, [0xA277, 0xBEEF]);
    await wait(500);
    expect(resent, isEmpty);
  });

  test('the same repeater twice is still one', () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    await hear(sent, [0xA277, 0xA277]);
    await wait(500);
    expect(resent, [sent.messageId]);
  });

  test('a car repeater does not count', () async {
    carRepeaters = {'A277'};
    final sent = await send();
    await hear(sent, [0xA277, 0xBEEF]);
    await wait(500);
    expect(resent, [sent.messageId], reason: 'only BEEF counts');
  });

  test('an observer that heard it first stops it', () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    c.confirmChannelSendHeard(sent.messageId);
    await wait(500);
    expect(resent, isEmpty);
  });

  test('while observers do not hear this radio, one repeat is enough',
      () async {
    observersHearUs = false;
    final sent = await send();
    await hear(sent, [0xA277]);
    expect(c.isChannelMessageRetrying(sent.messageId), isFalse);
    await wait(500);
    expect(resent, isEmpty);
    expect(c.channelSends, hasLength(1));
  });

  test('observers stop hearing this radio during the wait: not sent',
      () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    observersHearUs = false;
    await wait(500);
    expect(resent, isEmpty);
  });

  test('channel retries set to 0: no resends at all', () async {
    await settings.setMaxChannelMessageRetries(0);
    final sent = await send();
    await hear(sent, [0xA277]);
    await wait(500);
    expect(resent, isEmpty);
  });

  test('the one more send goes out stamped anew, and only once', () async {
    final sent = await send();
    await hear(sent, [0xA277]);
    // It goes out after 3 s of radio quiet since the copy was heard.
    await wait(3500);
    expect(c.channelSends, hasLength(2));
    final again = stamped.last;
    expect(again.messageId, sent.messageId);
    expect(again.secs, greaterThan(sent.secs));

    c.handleFrameForTest([respCodeOk]);
    await pumpEventQueue(times: 200);
    expect((await row()).status, ChannelMessageStatus.delivered);
    expect(c.isChannelMessageRetrying(sent.messageId), isFalse);

    await hear(again, [0xA277]);
    await wait(500);
    expect(resent, [sent.messageId]);
    expect(c.channelSends, hasLength(2));
    expect((await row()).status, ChannelMessageStatus.delivered);
  });
}
