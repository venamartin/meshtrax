import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A reply to a reply never linked when the replier's app doesn't read replies
// (field 2026-11-16): it quotes the parent as it went out, quote line and all,
// while MeshTrax keeps only the parent's body as its text.
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

/// The radio's log of a group text one repeater passed on, sealed with the
/// channel key as the firmware seals it.
Uint8List _heard(int secs, String sender, String text) {
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

  Future<void> hear(int secondsAgo, String sender, String text) async {
    final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000 - secondsAgo;
    c.handleFrameForTest(_heard(secs, sender, text));
    await pumpEventQueue(times: 200);
  }

  test('a reply quoting a reply, quote line and all, links to it', () async {
    await hear(180, 'Bob', 'Pine cones are free');
    await hear(120, 'Ann', '@[Bob]\n>Pine cones..\nI got mine at the store');
    await hear(60, 'Bob', '@[Ann]\n>>Pine cone..\nHow many?');

    final rows = await c.loadChannelMessagesFor(channel);
    final original = rows.singleWhere((m) => m.text == 'Pine cones are free');
    final first = rows.singleWhere((m) => m.text == 'I got mine at the store');
    final second = rows.singleWhere((m) => m.text == 'How many?');
    expect(first.replyToMessageId, original.messageId);
    expect(second.replyToMessageId, first.messageId);
    expect(second.replyToText, 'I got mine at the store');
  });

  // Field 2026-11-17: a reply to a three-day-old post kept the sender's short
  // quote, because only the last 48 hours of arrivals were searched. A tap
  // on the quote found the post, so the reply now links the same way.
  test('a reply to a message that arrived days ago links to it', () async {
    await hear(120, 'Bob', 'Pine cones are free');
    await AppDatabase.instance.customStatement(
      'UPDATE channel_message_rows SET received_at_us = ?',
      [
        DateTime.now()
            .subtract(const Duration(days: 3))
            .microsecondsSinceEpoch,
      ],
    );
    await hear(60, 'Ann', '@[Bob]\n>Pine cones..\nNot yet');

    final rows = await c.loadChannelMessagesFor(channel);
    final original = rows.singleWhere((m) => m.text == 'Pine cones are free');
    final reply = rows.singleWhere((m) => m.text == 'Not yet');
    expect(reply.replyToMessageId, original.messageId);
    expect(reply.replyToText, 'Pine cones are free');
  });

  // Field 2026-11-17: a 🍻 to a post from 86 hours before showed as a stub,
  // because only the last 48 hours of arrivals were searched.
  test('a reaction to a message that arrived days ago lands on it', () async {
    final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
    c.handleFrameForTest(_heard(secs, 'Bob', 'Pine cones are free'));
    await pumpEventQueue(times: 200);
    await AppDatabase.instance.customStatement(
      'UPDATE channel_message_rows SET received_at_us = ?',
      [
        DateTime.now()
            .subtract(const Duration(days: 3))
            .microsecondsSinceEpoch,
      ],
    );
    final hash =
        ReactionHelper.computeMeshCoreOneHash('Pine cones are free', secs);
    await hear(30, 'Ann', '@[Bob]🍻\n$hash');

    final rows = await c.loadChannelMessagesFor(channel);
    expect(rows.map((m) => m.text), ['Pine cones are free'],
        reason: 'no stub row for the reaction');
    expect(rows.single.reactions, {'🍻': 1});
  });

  test('a reply to a message never heard keeps its quote', () async {
    await hear(60, 'Ann', '@[Bob]\n>Pine cones..\nNot yet');

    final reply = (await c.loadChannelMessagesFor(channel)).single;
    expect(reply.replyToMessageId, isNull);
    expect(reply.replyToSenderName, 'Bob');
    expect(reply.replyToText, 'Pine cones');
  });
}
