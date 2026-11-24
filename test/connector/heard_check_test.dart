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
import 'package:traxheard/traxheard.dart';

// "Check sends with observers": the connector says when a channel send went
// on air, with all that decides its packet hash, and takes a sighting as
// proof that it is on air.
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

/// The radio's log of our own channel text coming back through repeater
/// AB, sealed as the firmware seals it: no terminator in the plaintext.
Uint8List _echo(int secs, String text) {
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
  late List<
      ({
        String messageId,
        Uint8List channelKey,
        String senderName,
        String text,
        int secs,
        String? region,
      })> stamped;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    stamped = [];
    c.onChannelSendStamped = stamped.add;
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
  });

  Future<ChannelMessage> row() async =>
      (await c.loadChannelMessagesFor(channel)).single;

  test('the hash worked out for a send is the hash of its heard copy',
      () async {
    final echoes = <(String, String)>[];
    c.onOwnChannelEcho = (id, hash) => echoes.add((id, hash));

    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
    final send = stamped.single;
    expect(send.messageId, (await row()).messageId);
    expect(send.channelKey, _psk);
    expect(send.senderName, 'GWQ');
    expect(send.text, 'Pine cones are free');

    c.handleFrameForTest(_echo(send.secs, send.text));
    await pumpEventQueue(times: 200);

    expect(echoes, [
      (
        send.messageId,
        channelTextPacketHash(
          channelKey: send.channelKey,
          senderName: send.senderName,
          text: send.text,
          timestampSecs: send.secs,
        ),
      ),
    ]);
  });

  test('a sighting stops the waits and settles the send as sent', () async {
    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
    final id = stamped.single.messageId;
    expect(c.isChannelMessageRetrying(id), isTrue);

    c.confirmChannelSendHeard(id);
    await pumpEventQueue(times: 200);

    expect(c.isChannelMessageRetrying(id), isFalse,
        reason: 'no resend for a message an observer heard');
    expect((await row()).status, ChannelMessageStatus.sent,
        reason: 'on air, but only our radio hearing a repeat says delivered');
  });

  test('a sighting turns a failed send back to sent', () async {
    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
    final id = stamped.single.messageId;
    c.markChannelMessageFailed(channel.index, id);
    await pumpEventQueue(times: 200);
    expect((await row()).status, ChannelMessageStatus.failed);

    c.confirmChannelSendHeard(id);
    await pumpEventQueue(times: 200);
    expect((await row()).status, ChannelMessageStatus.sent);
  });

  test('a reaction is not a message: no hook', () async {
    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
    stamped.clear();
    await c.sendChannelMessage(channel, '@[Bob]👍\nabcdefgh');
    await pumpEventQueue(times: 200);
    expect(stamped, isEmpty);
  });
}
