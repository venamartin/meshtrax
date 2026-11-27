import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A reply to a message of mine is a mention (Martin, 2026-11-27: "A reply is
// also a mention"). It notifies through the channel's mute as a mention
// does, even when it names me otherwise, as after a rename.
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

Uint8List _selfInfo(String name) {
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
  w.add(utf8.encode(name));
  return w.toBytes();
}

Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, '#trip', _psk).sublist(1),
]);

/// The radio's log of a flood copy one repeater passed on, sealed with the
/// channel key as the firmware seals it.
Uint8List _heardCopy(int secs, String sender, String text) {
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
    pushCodeLogRxData, 0x14, 0xA0,
    (0x05 << 2) | 0x01, // group text, flood
    1, 0xAB, // one hop, through repeater AB
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

/// [body], replying to [to]'s [quote], as it goes on the air.
String _reply(String to, String quote, String body) =>
    ChannelMessage.buildReplyWireText(
      targetName: to,
      quoteText: quote,
      body: body,
      fits: (_) => true,
    )!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Channel channel;
  final shown = <ShownNotification>[];
  late int now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    final settings = AppSettingsService();
    await settings.loadSettings();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.handleFrameForTest(_selfInfo('GWQ'));
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
    await settings.muteChannel(channel.idKey);
    shown.clear();
    NotificationService.debugOnShow = shown.add;
    now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  });

  tearDown(() => NotificationService.debugOnShow = null);

  Future<void> hear(int secs, String sender, String text) async {
    c.handleFrameForTest(_heardCopy(secs, sender, text));
    await pumpEventQueue(times: 200);
  }

  Future<void> say(String text) async {
    await c.sendChannelMessage(channel, text);
    await pumpEventQueue(times: 200);
  }

  /// Bob's reply.
  Future<ChannelMessage> bobs() async => (await c.loadChannelMessagesFor(
    channel,
  )).lastWhere((m) => m.senderName == 'Bob');

  test('a reply to my message notifies through the mute, as a mention',
      () async {
    await say('Store run today?');
    await hear(now, 'Bob', _reply('GWQ', 'Store run today?', 'Not today'));
    final reply = await bobs();
    expect(reply.replyToMessageId, isNotNull);
    expect(shown.single.payload, 'mention:1:${reply.messageId}');
  });

  test('after a rename, a reply to a message I sent under my old name '
      'still notifies', () async {
    await say('Store run today?');
    c.handleFrameForTest(_selfInfo('GWQ∆'));
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    expect(c.selfName, 'GWQ∆');

    await hear(now, 'Bob', _reply('GWQ', 'Store run today?', 'Not today'));
    final reply = await bobs();
    expect(reply.replyToMessageId, isNotNull);
    expect(shown.single.payload, 'mention:1:${reply.messageId}');
  });

  test('a reply to someone else\'s message stays quiet in a muted channel',
      () async {
    await hear(now - 20, 'Ann', 'Store run today?');
    await hear(now - 10, 'Bob', _reply('Ann', 'Store run today?', 'Not today'));
    expect((await bobs()).replyToMessageId, isNotNull);
    expect(shown, isEmpty);
  });
}
