import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:traxheard/traxheard.dart';

final _key = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

/// A channel text sealed step by step as the radio does it, and the hash
/// of the packet, written out apart from the package's own code.
String _sealedHash(Uint8List key, int secs, String plainText) {
  final plain = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List())
    ..addByte(0)
    ..add(utf8.encode(plainText));
  final bytes = plain.toBytes();
  final padded = Uint8List((bytes.length + 15) ~/ 16 * 16)
    ..setRange(0, bytes.length, bytes);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, sealed, i);
  }
  final key32 = Uint8List(32)..setRange(0, 16, key);
  final mac = Hmac(sha256, key32).convert(sealed).bytes;
  final payload = [sha256.convert(key).bytes[0], mac[0], mac[1], ...sealed];
  return sha256
      .convert([0x05, ...payload])
      .bytes
      .take(8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

void main() {
  test('the hash of the packet the radio seals', () {
    for (final text in ['hi', 'Pine cones are free', 'x' * 40, 'héllo 🌲']) {
      expect(
        channelTextPacketHash(
          channelKey: _key,
          senderName: 'Ann',
          text: text,
          timestampSecs: 1794935150,
        ),
        _sealedHash(_key, 1794935150, 'Ann: $text'),
        reason: text,
      );
    }
  });

  test('16 lower-case hex characters', () {
    expect(
      channelTextPacketHash(
        channelKey: _key,
        senderName: 'Ann',
        text: 'hi',
        timestampSecs: 1,
      ),
      matches(RegExp(r'^[0-9a-f]{16}$')),
    );
  });

  test('a resend is a new packet: its new timestamp gives a new hash', () {
    String at(int secs) => channelTextPacketHash(
          channelKey: _key,
          senderName: 'Ann',
          text: 'hi',
          timestampSecs: secs,
        );
    expect(at(1000), isNot(at(1031)));
  });

  test('the radio cuts "<name>: <text>" to 160 bytes', () {
    final long = 'y' * 200;
    expect(
      channelTextPacketHash(
        channelKey: _key,
        senderName: 'Ann',
        text: long,
        timestampSecs: 5,
      ),
      _sealedHash(_key, 5, 'Ann: ${'y' * 155}'),
    );
  });

  test('a 32-byte secret with an empty second half is the 16-byte one', () {
    final wide = Uint8List(32)..setRange(0, 16, _key);
    String hash(Uint8List key) => channelTextPacketHash(
          channelKey: key,
          senderName: 'Ann',
          text: 'hi',
          timestampSecs: 5,
        );
    expect(hash(wide), hash(_key));
  });
}
