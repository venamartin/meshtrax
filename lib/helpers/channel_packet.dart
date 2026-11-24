import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

/// A channel text built by the app the way a companion radio builds it
/// (BaseChatMesh::sendGroupMessage, Mesh::createGroupDatagram), so the app
/// can hand the radio a zero-hop copy (CMD_SEND_RAW_PACKET). The radio has
/// no command to send a channel text zero-hop.
class ChannelPacket {
  /// The room a radio gives `name: text` (MAX_TEXT_LEN).
  static const int maxTextBytes = 160;

  static const int _groupText = 0x05; // PAYLOAD_TYPE_GRP_TXT
  static const int _routeDirect = 0x02; // ROUTE_TYPE_DIRECT

  /// A zero-hop channel text: route DIRECT with an empty path, which every
  /// radio in range opens and none passes on (Mesh::onRecvPacket only
  /// forwards floods, and a DIRECT packet only to the next hop in its path).
  ///
  /// [text] is the exact bytes the app would hand the radio. The radio
  /// always seals a 0 (plain text) after the timestamp.
  static Uint8List zeroHopText({
    required Uint8List channelKey,
    required String senderName,
    required Uint8List text,
    required int timestampSecs,
  }) {
    final prefix = utf8.encode('$senderName: ');
    final room = max(0, maxTextBytes - prefix.length);
    final body = text.length > room ? text.sublist(0, room) : text;
    final plain = BytesBuilder()
      ..add(
        (ByteData(4)..setUint32(0, timestampSecs, Endian.little))
            .buffer
            .asUint8List(),
      )
      ..addByte(0)
      ..add(prefix)
      ..add(body);
    return Uint8List.fromList([
      (_groupText << 2) | _routeDirect,
      0, // path length 0: zero hop
      _channelHash(channelKey),
      ..._seal(channelKey, plain.toBytes()),
    ]);
  }

  /// The radio hashes all 32 bytes only when the second half isn't empty.
  static int _channelHash(Uint8List key) {
    final wide = key.length > 16 && key.skip(16).any((b) => b != 0);
    return crypto.sha256.convert(wide ? key : key.sublist(0, 16)).bytes[0];
  }

  /// AES-128-ECB with the first 16 bytes, zero-padded, behind the first 2
  /// bytes of an HMAC-SHA256 over it (Utils::encryptThenMAC).
  static Uint8List _seal(Uint8List key, Uint8List plain) {
    final padded = Uint8List((plain.length + 15) ~/ 16 * 16)
      ..setRange(0, plain.length, plain);
    final aes = ECBBlockCipher(AESEngine())
      ..init(true, KeyParameter(Uint8List.fromList(key.sublist(0, 16))));
    final sealed = Uint8List(padded.length);
    for (var i = 0; i < padded.length; i += 16) {
      aes.processBlock(padded, i, sealed, i);
    }
    final mac = crypto.Hmac(crypto.sha256, key).convert(sealed).bytes;
    return Uint8List.fromList([mac[0], mac[1], ...sealed]);
  }
}
