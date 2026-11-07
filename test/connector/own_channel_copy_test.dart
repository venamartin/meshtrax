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

// Martin sent to Public and his own message came back unread (2026-11-07). A
// repeater's copy of a send reaches the app as anyone else's message would,
// and only a guess by text and name tied it to the sent row: a copy whose
// text differed from the row's was stored as a second message, counted
// unread.
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

// RESP_CODE_CHANNEL_INFO has the same layout as CMD_SET_CHANNEL.
Uint8List _channelInfo() => Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(1, '#test', _psk).sublist(1),
    ]);

/// The radio's log of a flood copy one repeater passed on: a group text
/// sealed with the channel key as the firmware seals it.
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
    pushCodeLogRxData, 0x14, 0xA0, // SNR, RSSI
    (0x05 << 2) | 0x01, // group text, flood
    1, 0xAB, // one hop, through repeater AB
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Channel channel;

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

  /// Sends [wire] and has the radio hear a repeater pass it on.
  Future<List<ChannelMessage>> sendAndHearCopy(
    String wire, {
    ChannelMessage? replyTo,
  }) async {
    await c.sendChannelMessage(channel, wire, replyTarget: replyTo);
    await pumpEventQueue(times: 200);
    final sent = (await c.loadChannelMessagesFor(channel)).single;
    c.handleFrameForTest(_heardCopy(sent.sentWireSecs.last, 'GWQ', wire));
    await pumpEventQueue(times: 200);
    return c.loadChannelMessagesFor(channel);
  }

  Future<int> unread() => c.watchChannelUnreadCounts().first.then(
        (counts) => counts[channel.idKey] ?? 0,
      );

  test('a copy of my message merges into it and is never unread', () async {
    final rows = await sendAndHearCopy('Good morning.');

    expect(rows, hasLength(1));
    expect(rows.single.isOutgoing, isTrue);
    expect(rows.single.repeatCount, 1);
    expect(rows.single.status, ChannelMessageStatus.delivered);
    expect(await unread(), 0);
    expect(await c.oldestUnreadChannelMessage(channel, 1), isNull,
        reason: 'no NEW MESSAGES line on my own message');
  });

  test('a reply sent as a bare mention: its copy is still mine', () async {
    // Too long for the quote snippet, a reply goes out as "@[Name]\n<body>"
    // and the row keeps the body alone, so the texts never matched.
    final target = ChannelMessage(
      senderName: 'Ann',
      text: 'Are you coming?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isOutgoing: false,
      channelIndex: 1,
    );
    final rows = await sendAndHearCopy(
      '@[Ann]\nOn my way',
      replyTo: target,
    );

    expect(rows, hasLength(1), reason: 'no second copy of my reply');
    expect(rows.single.text, 'On my way');
    expect(rows.single.repeatCount, 1);
    expect(await unread(), 0);
  });

  // What Martin saw on the Chats row: a post written just before his send
  // reached the radio after it, so in the order the chat shows it stands
  // above his message, and the row previewed his own message beside its
  // badge.
  test('an earlier-stamped post after my send is the unread one', () async {
    await c.sendChannelMessage(channel, 'Good morning.');
    await pumpEventQueue(times: 200);
    final sent = (await c.loadChannelMessagesFor(channel)).single;
    c.handleFrameForTest(
      _heardCopy(sent.sentWireSecs.last - 3, 'Ann', 'Morning all'),
    );
    await pumpEventQueue(times: 200);

    final shown = await c.loadChannelMessagesFor(channel);
    expect(shown.map((m) => m.text), ['Morning all', 'Good morning.'],
        reason: 'written first, so it stands above mine');
    expect(await unread(), 1);
    expect(c.latestChannelMessage(channel)?.text, 'Good morning.');
    expect(c.newestUnreadChannelMessage(channel)?.text, 'Morning all');
  });

  test('a namesake on another radio is not me', () async {
    await c.sendChannelMessage(channel, 'Good morning.');
    await pumpEventQueue(times: 200);
    final sent = (await c.loadChannelMessagesFor(channel)).single;
    c.handleFrameForTest(_heardCopy(sent.sentWireSecs.last + 90, 'GWQ', 'Hi'));
    await pumpEventQueue(times: 200);

    final rows = await c.loadChannelMessagesFor(channel);
    expect(rows, hasLength(2));
    expect(await unread(), 1);
  });
}
