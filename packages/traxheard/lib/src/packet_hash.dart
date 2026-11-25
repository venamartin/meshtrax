import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// The room a radio gives `name: text` in a channel text (MAX_TEXT_LEN).
const _maxTextBytes = 160;

/// MeshCore's payload type of a channel text (PAYLOAD_TYPE_GRP_TXT).
const _groupText = 0x05;

/// The hash the mesh gives a channel text that a MeshCore companion radio
/// sends: the same in every copy, whatever path it took, and the hash an
/// observer server files it under. 16 lower-case hex characters.
///
/// [channelKey] is the channel's secret (16 bytes, or 32), [senderName] the
/// radio's own name, [text] the exact text the app handed the radio, and
/// [timestampSecs] the timestamp it was handed with.
///
/// The radio seals the timestamp (4 bytes), a 0 and `name: text`
/// (sendGroupMessage) with AES-128-ECB, zero padding and a 2-byte
/// HMAC-SHA256, behind the
/// channel's 1-byte hash (createGroupDatagram). The packet's hash is
/// SHA-256 over the type byte and that payload, cut to 8 bytes
/// (calculatePacketHash). None of it is random, so the hash is known
/// before the radio sends.
String channelTextPacketHash({
  required Uint8List channelKey,
  required String senderName,
  required String text,
  required int timestampSecs,
}) {
  final prefix = utf8.encode('$senderName: ');
  var body = utf8.encode(text);
  final room = max(0, _maxTextBytes - prefix.length);
  if (body.length > room) body = body.sublist(0, room);
  final plain = BytesBuilder()
    ..add(
      (ByteData(4)..setUint32(0, timestampSecs, Endian.little))
          .buffer
          .asUint8List(),
    )
    ..addByte(0)
    ..add(prefix)
    ..add(body);
  final payload = BytesBuilder()
    ..addByte(_channelHash(channelKey))
    ..add(_seal(channelKey, plain.toBytes()));
  final digest = sha256.convert([_groupText, ...payload.toBytes()]).bytes;
  return [
    for (final b in digest.take(8)) b.toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// MeshCore's payload type of channel data (PAYLOAD_TYPE_GRP_DATA).
const _groupData = 0x06;

/// The hash the mesh gives a channel datagram that a MeshCore companion
/// radio sends (CMD_SEND_CHANNEL_DATA): [data] of data type [dataType], on
/// the channel with secret [channelKey]. 16 lower-case hex characters, the
/// hash an observer server files it under.
///
/// The radio seals the data type (2 bytes, little-endian), the length (1)
/// and the data (sendGroupData) as it seals a text, behind the channel's
/// 1-byte hash. None of it is random, so the hash is known before the radio
/// sends, and a copy sent again has the same one.
String channelDataPacketHash({
  required Uint8List channelKey,
  required int dataType,
  required List<int> data,
}) {
  final plain = Uint8List.fromList([
    dataType & 0xFF,
    (dataType >> 8) & 0xFF,
    data.length,
    ...data,
  ]);
  final payload = BytesBuilder()
    ..addByte(_channelHash(channelKey))
    ..add(_seal(channelKey, plain));
  final digest = sha256.convert([_groupData, ...payload.toBytes()]).bytes;
  return [
    for (final b in digest.take(8)) b.toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// The radio hashes all 32 bytes only when the second half isn't empty.
int _channelHash(Uint8List key) {
  final wide = key.length > 16 && key.skip(16).any((b) => b != 0);
  return sha256.convert(wide ? key : key.sublist(0, 16)).bytes[0];
}

/// AES-128-ECB with the first 16 bytes, zero-padded to whole blocks, behind
/// the first 2 bytes of an HMAC-SHA256 over the result. The radio keys the
/// HMAC with 32 bytes; a 16-byte secret is zero-filled, which HMAC's own
/// key padding makes the same as the 16 bytes alone.
Uint8List _seal(Uint8List key, Uint8List plain) {
  final padded = Uint8List((plain.length + 15) ~/ 16 * 16)
    ..setRange(0, plain.length, plain);
  final aes = ECBBlockCipher(AESEngine())
    ..init(true, KeyParameter(Uint8List.fromList(key.sublist(0, 16))));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    aes.processBlock(padded, i, sealed, i);
  }
  final mac = Hmac(sha256, key).convert(sealed).bytes;
  return Uint8List.fromList([mac[0], mac[1], ...sealed]);
}
