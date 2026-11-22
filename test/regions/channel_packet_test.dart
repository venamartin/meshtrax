import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/channel_packet.dart';
import 'package:traxheard/traxheard.dart';

// The zero-hop channel text the app builds must be the radio's own packet
// byte for byte. traxheard's hash of a channel text matched the hash of a
// real heard copy (test/connector/heard_check_test.dart), and the hash
// covers the whole payload, so equal hashes mean an equal payload.
String _hashOf(Uint8List packet) {
  final payload = packet.sublist(2);
  final digest = crypto.sha256.convert([0x05, ...payload]).bytes;
  return [for (final b in digest.take(8)) b.toRadixString(16).padLeft(2, '0')]
      .join();
}

void main() {
  final key = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

  Uint8List build(String text, {String name = 'GWQ', int secs = 1795306877}) =>
      ChannelPacket.zeroHopText(
        channelKey: key,
        senderName: name,
        text: Uint8List.fromList(utf8.encode(text)),
        timestampSecs: secs,
      );

  test('a group text sent DIRECT with an empty path', () {
    final packet = build('hello');
    expect(packet[0], (0x05 << 2) | 0x02);
    expect(packet[1], 0, reason: 'zero hop');
    expect(packet[2], crypto.sha256.convert(key).bytes[0],
        reason: "the channel's 1-byte hash");
  });

  test('the payload is the one the radio would seal', () {
    for (final text in ['hello', 'Trailhead parking is full 🚗', '']) {
      expect(
        _hashOf(build(text)),
        channelTextPacketHash(
          channelKey: key,
          senderName: 'GWQ',
          text: text,
          timestampSecs: 1795306877,
        ),
        reason: text,
      );
    }
  });

  test('name and text are cut at 160 bytes, as the radio cuts them', () {
    final long = 'x' * 300;
    expect(
      _hashOf(build(long)),
      channelTextPacketHash(
        channelKey: key,
        senderName: 'GWQ',
        text: long,
        timestampSecs: 1795306877,
      ),
    );
    // timestamp 4 + type 1 + 160, padded to 176, behind hash and MAC.
    expect(build(long).length, 2 + 1 + 2 + 176);
  });
}
