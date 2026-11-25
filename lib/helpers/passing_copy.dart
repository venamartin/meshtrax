import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pinenacl/tweetnacl.dart';
import 'package:pointycastle/export.dart';

import '../connector/meshcore_protocol.dart';
import 'path_helper.dart';

const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeDirect = 0x02;
const int _macSize = 2;
const int _blockSize = 16;

/// An ACK for this radio seen on the air. [pathReply]: it came in a path
/// reply, so the DM reached them by flood; a plain or MULTIPART ACK answers
/// a routed copy (BaseChatMesh::onPeerDataRecv). [attempt]: the byte the
/// receiver copies from the DM's tail into its ACK, the attempt number
/// itself above 3 and 0 at or below; null when the ACK doesn't carry it.
typedef HeardAck = ({int code, bool pathReply, int? attempt});

/// A DM or room post the radio heard while its copy still had hops left in
/// the path. The firmware opens a routed packet only from the copy whose path
/// is used up, the last repeater's (MeshCore Mesh.cpp, onRecvPacket: a copy
/// with hops left goes to the next hop or is released unopened). So a copy
/// heard straight from the sender, or from an earlier repeater, is dropped
/// even when it is addressed to this radio. [PassingCopyOpener] opens it.
class PassingCopy {
  /// The contact it came from: the sender of a DM, or the room server.
  final Uint8List senderKey;

  /// Seconds, by the sender's clock.
  final int timestamp;

  /// The attempt number from the flags byte (0-3).
  final int attempt;

  /// A room server's post: [authorPrefix] names the author.
  final bool isRoomPost;
  final Uint8List? authorPrefix;

  /// The text as the radio would hand it over: the bytes up to the
  /// terminator, still Smaz-packed if the sender packed it.
  final Uint8List textBytes;

  /// The hops the copy still had to go, [hopWidth] bytes each.
  final List<int> hopsLeft;
  final int hopWidth;

  /// The ACK the firmware would send for it: 6 bytes for a DM, 4 for a room
  /// post (BaseChatMesh::onPeerDataRecv).
  final Uint8List ack;

  const PassingCopy({
    required this.senderKey,
    required this.timestamp,
    required this.attempt,
    required this.isRoomPost,
    required this.authorPrefix,
    required this.textBytes,
    required this.hopsLeft,
    required this.hopWidth,
    required this.ack,
  });

  String get text => utf8.decode(textBytes, allowMalformed: true);

  int get hopsLeftCount => hopsLeft.length ~/ hopWidth;

  /// The hops still to go, e.g. "BEEF" or "AD77,BEEF".
  String get hopsLeftHex =>
      PathHelper.formatPathHex(hopsLeft, stride: hopWidth);
}

/// Opens routed DMs and room posts addressed to this radio from copies the
/// firmware drops (see [PassingCopy]), with the radio's own private key, and
/// builds the ACK packets the firmware would have sent.
class PassingCopyOpener {
  /// The 64-byte private key CMD_EXPORT_PRIVATE_KEY returns, and the radio's
  /// public key.
  PassingCopyOpener({
    required Uint8List privateKey,
    required Uint8List selfKey,
    Random? random,
  }) : _scalar = Uint8List.fromList(privateKey.sublist(0, 32)),
       _selfKey = Uint8List.fromList(selfKey),
       _random = random ?? Random.secure();

  final Uint8List _scalar;
  final Uint8List _selfKey;
  final Random _random;
  final Map<String, Uint8List?> _secrets = {};

  /// The radio this opener holds the key of.
  Uint8List get selfKey => _selfKey;

  /// Opens a routed TXT_MSG copy from the radio's RX log (its path_len byte,
  /// path and payload) when it is addressed to this radio and still has hops
  /// to go, from one of [contactKeys]. Null otherwise: a copy the radio opens
  /// itself (no hops left), another radio's, a sender it has no key for, a
  /// MAC that fails, or a text type the radio keeps (CLI data).
  PassingCopy? open({
    required int pathLenRaw,
    required List<int> pathBytes,
    required List<int> payload,
    required Iterable<Uint8List> contactKeys,
  }) {
    if (PathHelper.pathLenHops(pathLenRaw) <= 0) return null;
    return _open(pathLenRaw, pathBytes, payload, contactKeys);
  }

  /// Any copy of a DM or room post to this radio, the ones the radio opens
  /// itself too (the last routed copy, any flood), read for the ACK the app
  /// sends beside the radio's. A flood's path is the hops it travelled, not
  /// hops to go, so its hops left read as none.
  PassingCopy? openAny({
    required bool flood,
    required int pathLenRaw,
    required List<int> pathBytes,
    required List<int> payload,
    required Iterable<Uint8List> contactKeys,
  }) {
    if (flood) {
      final none = PathHelper.encodePathLen(
        0,
        PathHelper.pathLenWidth(pathLenRaw),
      );
      return _open(none, const [], payload, contactKeys);
    }
    if (PathHelper.pathLenHops(pathLenRaw) < 0) return null;
    return _open(pathLenRaw, pathBytes, payload, contactKeys);
  }

  PassingCopy? _open(
    int pathLenRaw,
    List<int> pathBytes,
    List<int> payload,
    Iterable<Uint8List> contactKeys,
  ) {
    final width = PathHelper.pathLenWidth(pathLenRaw);
    if (width > 3) return null;
    if (pathBytes.length != PathHelper.pathLenBytes(pathLenRaw)) return null;
    if (payload.length < 2 + _macSize + _blockSize) return null;
    if (payload[0] != _selfKey[0]) return null;
    final srcHash = payload[1];
    // From a contact who shares this radio's first key byte, a copy reads
    // the same as this radio's own DM to them echoed back: the secret is the
    // same both ways and the text names no direction (BaseChatMesh
    // composeMsgPacket). The radio marks its own sends seen and opens
    // theirs itself (Mesh.cpp onRecvPacket), so the app leaves these alone,
    // as the path graph does.
    if (srcHash == _selfKey[0]) return null;
    final macAndData = Uint8List.fromList(payload.sublist(2));
    for (final key in contactKeys) {
      if (key.length != pubKeySize || key[0] != srcHash) continue;
      final secret = sharedSecret(key);
      if (secret == null) continue;
      final plain = macThenDecrypt(secret, macAndData);
      if (plain == null) continue;
      return _read(plain, key, List.unmodifiable(pathBytes), width);
    }
    return null;
  }

  PassingCopy? _read(
    Uint8List plain,
    Uint8List senderKey,
    List<int> hopsLeft,
    int width,
  ) {
    if (plain.length <= 5) return null;
    final timestamp = ByteData.sublistView(plain).getUint32(0, Endian.little);
    final flags = plain[4] >> 2;
    final attempt = plain[4] & 0x03;
    if (flags == txtTypePlain) {
      final end = _textEnd(plain, 5);
      // The hash proves the text arrived; then the extended attempt byte
      // after the text's terminator, and one random byte.
      final hash = _sha256(plain.sublist(0, end), senderKey);
      final ack = Uint8List(6)
        ..setRange(0, 4, hash)
        ..[4] = end + 1 < plain.length ? plain[end + 1] : 0
        ..[5] = _random.nextInt(256);
      return PassingCopy(
        senderKey: senderKey,
        timestamp: timestamp,
        attempt: attempt,
        isRoomPost: false,
        authorPrefix: null,
        textBytes: Uint8List.fromList(plain.sublist(5, end)),
        hopsLeft: hopsLeft,
        hopWidth: width,
        ack: ack,
      );
    }
    if (flags == txtTypeSigned && plain.length > 9) {
      final end = _textEnd(plain, 9);
      // A room post's ACK hashes in this radio's own key, not the sender's.
      final hash = _sha256(plain.sublist(0, end), _selfKey);
      return PassingCopy(
        senderKey: senderKey,
        timestamp: timestamp,
        attempt: attempt,
        isRoomPost: true,
        authorPrefix: plain.sublist(5, 9),
        textBytes: Uint8List.fromList(plain.sublist(9, end)),
        hopsLeft: hopsLeft,
        hopWidth: width,
        ack: Uint8List.fromList(hash.sublist(0, 4)),
      );
    }
    return null;
  }

  /// A copy of a DM this radio sent to one of [contactKeys], read from its
  /// RX log: a repeater passing it on. The MAC passes only with their key
  /// and this radio's, so it is this radio's packet and no other. [attempt]
  /// is the number it was sent with: the tail byte above 3, else the two
  /// bits in the flags (BaseChatMesh::composeMsgPacket). Null for anything
  /// else, and for a contact who shares this radio's first key byte: a copy
  /// to them reads the same as one from them.
  ({Uint8List contactKey, int timestamp, int attempt, Uint8List textBytes})?
  openOwn({
    required List<int> payload,
    required Iterable<Uint8List> contactKeys,
  }) {
    if (payload.length < 2 + _macSize + _blockSize) return null;
    if (payload[1] != _selfKey[0] || payload[0] == _selfKey[0]) return null;
    final macAndData = Uint8List.fromList(payload.sublist(2));
    for (final key in contactKeys) {
      if (key.length != pubKeySize || key[0] != payload[0]) continue;
      final secret = sharedSecret(key);
      if (secret == null) continue;
      final plain = macThenDecrypt(secret, macAndData);
      if (plain == null || plain.length <= 5) continue;
      if (plain[4] >> 2 != txtTypePlain) return null;
      final end = _textEnd(plain, 5);
      final tail = end + 1 < plain.length ? plain[end + 1] : 0;
      return (
        contactKey: key,
        timestamp: ByteData.sublistView(plain).getUint32(0, Endian.little),
        attempt: tail > 3 ? tail : plain[4] & 0x03,
        textBytes: Uint8List.fromList(plain.sublist(5, end)),
      );
    }
    return null;
  }

  /// The ACK code inside a path reply to this radio from one of
  /// [contactKeys]: a DM it sent reached them by flood, and the reply
  /// carries the ACK (BaseChatMesh::onPeerDataRecv, createPathReturn: path
  /// length, path, extra type, extra). Null for any other packet.
  HeardAck? pathReplyAck({
    required List<int> payload,
    required Iterable<Uint8List> contactKeys,
  }) {
    final plain = _openPathPacket(payload, contactKeys)?.plain;
    if (plain == null) return null;
    final extraAt = 1 + PathHelper.pathLenBytes(plain[0]);
    if (plain.length < extraAt + 5) return null;
    if ((plain[extraAt] & 0x0F) != payloadTypeACK) return null;
    // The encrypted reply is padded with zeroes, so a 0 here may be an
    // older receiver's 4-byte ACK: only a number above 3 is trusted.
    final attempt = plain.length > extraAt + 5 ? plain[extraAt + 5] : 0;
    return (
      code: ByteData.sublistView(plain, extraAt + 1, extraAt + 5)
          .getUint32(0, Endian.little),
      pathReply: true,
      attempt: attempt > 3 ? attempt : null,
    );
  }

  /// The route a path packet to this radio from one of [contactKeys] hands
  /// it: the way this radio's packets reach them. In their reply to a flood
  /// of mine it is the path that flood travelled to them, first hop first
  /// (Mesh::createPathReturn). Null for any other packet.
  ({Uint8List contactKey, int pathLenRaw, Uint8List path})? pathReplyRoute({
    required List<int> payload,
    required Iterable<Uint8List> contactKeys,
  }) {
    final opened = _openPathPacket(payload, contactKeys);
    if (opened == null) return null;
    final plain = opened.plain;
    final bytes = PathHelper.pathLenBytes(plain[0]);
    if (PathHelper.pathLenHops(plain[0]) < 0 || plain.length < 1 + bytes) {
      return null;
    }
    return (
      contactKey: opened.key,
      pathLenRaw: plain[0],
      path: Uint8List.fromList(plain.sublist(1, 1 + bytes)),
    );
  }

  /// A path packet's payload, decrypted, with the contact it came from.
  ({Uint8List key, Uint8List plain})? _openPathPacket(
    List<int> payload,
    Iterable<Uint8List> contactKeys,
  ) {
    if (payload.length < 2 + _macSize + _blockSize) return null;
    if (payload[0] != _selfKey[0]) return null;
    final macAndData = Uint8List.fromList(payload.sublist(2));
    for (final key in contactKeys) {
      if (key.length != pubKeySize || key[0] != payload[1]) continue;
      final secret = sharedSecret(key);
      if (secret == null) continue;
      final plain = macThenDecrypt(secret, macAndData);
      if (plain != null) return (key: key, plain: plain);
    }
    return null;
  }

  /// A path packet for [contactKey], the firmware's own kind
  /// (Mesh::createPathReturn with nothing extra): it hands their radio
  /// [wayBack] ([wayBackLen] is its path length byte) as the way to reach
  /// this one, and their radio stores it in place of the route it holds
  /// (BaseChatMesh::onContactPathRecv). Sent direct on [routePath]
  /// ([routePathLen]), so it asks for no path in return. Null without a
  /// secret for them, or without a route for either.
  Uint8List? wayBackPacket({
    required Uint8List contactKey,
    required int wayBackLen,
    required List<int> wayBack,
    required int routePathLen,
    required List<int> routePath,
  }) {
    if (PathHelper.pathLenHops(wayBackLen) < 0 ||
        PathHelper.pathLenHops(routePathLen) < 0) {
      return null;
    }
    final secret = sharedSecret(contactKey);
    if (secret == null) return null;
    return Uint8List.fromList([
      (payloadTypePATH << 2) | _routeDirect,
      routePathLen & 0xFF,
      ...routePath.sublist(0, PathHelper.pathLenBytes(routePathLen)),
      contactKey[0],
      _selfKey[0],
      ...encryptThenMac(secret, [
        wayBackLen & 0xFF,
        ...wayBack.sublist(0, PathHelper.pathLenBytes(wayBackLen)),
        // No extra: a dummy type and four random bytes keep the packet
        // from repeating an earlier one, as the firmware does.
        0xFF,
        for (var i = 0; i < 4; i++) _random.nextInt(256),
      ]),
    ]);
  }

  /// The ACK a plain or MULTIPART ACK packet carries, else null.
  static HeardAck? heardAck(int payloadType, List<int> payload) {
    final at = switch (payloadType) {
      payloadTypeACK => 0,
      payloadTypeMULTIPART
          when payload.isNotEmpty && (payload[0] & 0x0F) == payloadTypeACK =>
        1,
      _ => null,
    };
    if (at == null || payload.length < at + 4) return null;
    return (
      code: ByteData.sublistView(Uint8List.fromList(payload), at, at + 4)
          .getUint32(0, Endian.little),
      pathReply: false,
      attempt: payload.length > at + 4 ? payload[at + 4] : null,
    );
  }

  /// The firmware's shared secret with [contactKey] (ed25519_key_exchange:
  /// X25519 of this radio's clamped scalar and the contact's key moved to
  /// Montgomery form), or null for a key that isn't a curve point.
  Uint8List? sharedSecret(Uint8List contactKey) {
    final id = base64.encode(contactKey);
    if (_secrets.containsKey(id)) return _secrets[id];
    final montgomery = Uint8List(32);
    Uint8List? secret;
    if (TweetNaClExt.crypto_sign_ed25519_pk_to_x25519_pk(
          montgomery,
          contactKey,
        ) ==
        0) {
      secret = Uint8List(32);
      TweetNaCl.crypto_scalarmult(secret, _scalar, montgomery);
    }
    return _secrets[id] = secret;
  }

  /// Utils::MACThenDecrypt: a 2-byte HMAC-SHA256 (keyed with the whole
  /// 32-byte secret) over the ciphertext, then AES-128-ECB with the first 16
  /// bytes of the secret. Null when the MAC doesn't match.
  static Uint8List? macThenDecrypt(Uint8List secret, Uint8List macAndData) {
    final encLen = macAndData.length - _macSize;
    if (encLen <= 0 || encLen % _blockSize != 0) return null;
    final enc = macAndData.sublist(_macSize);
    final mac = crypto.Hmac(crypto.sha256, secret).convert(enc).bytes;
    if (mac[0] != macAndData[0] || mac[1] != macAndData[1]) return null;
    final aes = AESEngine()
      ..init(false, KeyParameter(Uint8List.fromList(secret.sublist(0, 16))));
    final out = Uint8List(encLen);
    for (var off = 0; off < encLen; off += _blockSize) {
      aes.processBlock(enc, off, out, off);
    }
    return out;
  }

  /// Utils::encryptThenMAC: AES-128-ECB with the first 16 bytes of the
  /// secret, the last block padded with zeroes, and in front of it the
  /// 2-byte HMAC-SHA256 of the ciphertext, keyed with the whole secret.
  static Uint8List encryptThenMac(Uint8List secret, List<int> plain) {
    final blocks = (plain.length + _blockSize - 1) ~/ _blockSize;
    final padded = Uint8List(blocks * _blockSize)..setAll(0, plain);
    final aes = AESEngine()
      ..init(true, KeyParameter(Uint8List.fromList(secret.sublist(0, 16))));
    final enc = Uint8List(padded.length);
    for (var off = 0; off < padded.length; off += _blockSize) {
      aes.processBlock(padded, off, enc, off);
    }
    final mac = crypto.Hmac(crypto.sha256, secret).convert(enc).bytes;
    return Uint8List.fromList([mac[0], mac[1], ...enc]);
  }

  /// The raw packets for CMD_SEND_RAW_PACKET that carry [ack] back the way
  /// BaseChatMesh::sendAckTo does: on the radio's stored route to the sender
  /// ([routePathLen] and [routePath], 0xFF when there is none), with an extra
  /// MULTIPART copy first when the radio sends extra ACKs; with no route, one
  /// flood at [floodWidth] bytes per hop, carrying the scope's transport code
  /// when [scopeKey] is set (MyMesh::sendFloodScoped).
  static List<Uint8List> ackPackets(
    Uint8List ack, {
    required int routePathLen,
    required List<int> routePath,
    required bool extraAck,
    required int floodWidth,
    Uint8List? scopeKey,
  }) {
    if (PathHelper.pathLenHops(routePathLen) >= 0) {
      final path = routePath.sublist(0, PathHelper.pathLenBytes(routePathLen));
      Uint8List direct(int type, List<int> payload) => Uint8List.fromList([
        (type << 2) | _routeDirect,
        routePathLen & 0xFF,
        ...path,
        ...payload,
      ]);
      return [
        if (extraAck)
          direct(payloadTypeMULTIPART, [(1 << 4) | payloadTypeACK, ...ack]),
        direct(payloadTypeACK, ack),
      ];
    }
    final pathLen = PathHelper.encodePathLen(0, floodWidth);
    if (scopeKey == null) {
      return [
        Uint8List.fromList([
          (payloadTypeACK << 2) | _routeFlood,
          pathLen,
          ...ack,
        ]),
      ];
    }
    final code = transportCode(scopeKey, payloadTypeACK, ack);
    return [
      Uint8List.fromList([
        (payloadTypeACK << 2) | _routeTransportFlood,
        code & 0xFF,
        code >> 8,
        0,
        0,
        pathLen,
        ...ack,
      ]),
    ];
  }

  /// The second ACK, in the form of the firmware's own extra ACK
  /// (sendAckTo's createMultiAck, remaining 1): a MULTIPART packet on
  /// [routePath]. Repeaters drop a packet they have seen, and the packet
  /// hash leaves the path out (Packet::calculatePacketHash), so a plain copy
  /// of the first ACK would die at the first repeater that carried it; the
  /// MULTIPART one gets a new chance at every hop. With no route, a plain
  /// flood: repeaters don't pass a flooded MULTIPART on (Mesh.cpp).
  static List<Uint8List> secondAckPackets(
    Uint8List ack, {
    required int routePathLen,
    required List<int> routePath,
    required int floodWidth,
    Uint8List? scopeKey,
  }) {
    if (PathHelper.pathLenHops(routePathLen) < 0) {
      return ackPackets(
        ack,
        routePathLen: 0xFF,
        routePath: const [],
        extraAck: false,
        floodWidth: floodWidth,
        scopeKey: scopeKey,
      );
    }
    return [
      Uint8List.fromList([
        (payloadTypeMULTIPART << 2) | _routeDirect,
        routePathLen & 0xFF,
        ...routePath.sublist(0, PathHelper.pathLenBytes(routePathLen)),
        (1 << 4) | payloadTypeACK,
        ...ack,
      ]),
    ];
  }

  /// TransportKey::calcTransportCode: a 2-byte HMAC-SHA256, keyed with the
  /// 16-byte scope key, over the payload type and the payload; 0000 and FFFF
  /// are reserved.
  static int transportCode(Uint8List scopeKey, int payloadType, List<int> payload) {
    final mac = crypto.Hmac(
      crypto.sha256,
      scopeKey,
    ).convert([payloadType, ...payload]).bytes;
    final code = mac[0] | (mac[1] << 8);
    if (code == 0) return 1;
    if (code == 0xFFFF) return 0xFFFE;
    return code;
  }

  static int _textEnd(Uint8List plain, int start) {
    final end = plain.indexOf(0, start);
    return end < 0 ? plain.length : end;
  }

  static List<int> _sha256(List<int> data, List<int> key) =>
      crypto.sha256.convert([...data, ...key]).bytes;
}
