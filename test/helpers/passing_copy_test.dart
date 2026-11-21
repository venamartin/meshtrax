import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

import 'package:meshtrax/helpers/passing_copy.dart';

// Every value below was made by MeshCore's own code (src/Mesh.cpp,
// src/helpers/BaseChatMesh.cpp, src/Utils.cpp, src/Identity.cpp, compiled
// unchanged on a PC with a simulated radio): companion A sends companion B a
// DM, then a room-style signed post, on the route A277,AD77,BEEF. B heard
// each copy; its firmware opened only BEEF's (path used up) and sent the ACK
// shown. The keys are simulation keys, nobody's radio.
Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

final aPub = _hex('C36D3E093B444308FFFFB22761C81E6083FAE25E13ACB21E58101A3A315D688F');
final bPub = _hex('E7A1BD85D5BBFAED3993642E929D8147370FA489F3D7E6DFB3A482332E01ACE3');
final bPrivateExport = _hex(
  'B858735F5199592E891F93AF8A0BF28D09863C220B4A5D49F38A84D7D776576B'
  '9DC78FB0C1780A36F11825D1D1D4459BFAE1C107EA24B10C997317C716C7A8F5',
);
final secretBA = _hex('6AE94F988F1088625142CA4FC203441B0FCB04CFAB09C1519DE71CA518911707');

// The DM as B heard it from AD77 (BEEF still to go) and from A itself.
final dmFromAd77 = _hex('0A41BEEFE7C33A54219B42238925027937BB7F0A51F893E3');
final dmFromA = _hex('0A43A277AD77BEEFE7C33A54219B42238925027937BB7F0A51F893E3');
// B's firmware ACK once it opened BEEF's copy: 4-byte hash, attempt byte, a
// random byte.
final dmAckPayload = _hex('1FEE94EB00A7');
final roomFromAd77 = _hex(
  '0A41BEEFE7C3BAF83AF36DB76A1C352D65DAD2E4D40135C72967AF4E0916A707DDA7F31DC5FA8F49',
);
final roomAck = _hex('1967AA54');

PassingCopyOpener _opener() => PassingCopyOpener(
  privateKey: bPrivateExport,
  selfKey: bPub,
  random: Random(1),
);

// Splits a routed packet the way the connector's parser does: header,
// path_len, path, payload.
PassingCopy? _open(Uint8List raw, List<Uint8List> keys) {
  final width = ((raw[1] >> 6) & 3) + 1;
  final pathEnd = 2 + (raw[1] & 0x3F) * width;
  return _opener().open(
    pathLenRaw: raw[1],
    pathBytes: raw.sublist(2, pathEnd),
    payload: raw.sublist(pathEnd),
    contactKeys: keys,
  );
}

void main() {
  test('the shared secret matches the firmware key exchange', () {
    expect(_opener().sharedSecret(aPub), secretBA);
  });

  test('opens a routed DM heard with BEEF still to go', () {
    final copy = _open(dmFromAd77, [bPub, aPub])!;
    expect(copy.text, 'hello B');
    expect(copy.timestamp, 1795046400);
    expect(copy.attempt, 0);
    expect(copy.isRoomPost, isFalse);
    expect(copy.senderKey, aPub);
    expect(copy.hopsLeftHex, 'BEEF');
    expect(copy.ack.length, 6);
    expect(copy.ack.sublist(0, 5), dmAckPayload.sublist(0, 5),
        reason: 'the ACK the firmware sent, but for its random last byte');
  });

  test("opens the sender's own copy, all three hops still to go", () {
    final copy = _open(dmFromA, [aPub])!;
    expect(copy.text, 'hello B');
    expect(copy.hopsLeftHex, 'A277,AD77,BEEF');
  });

  test('opens a room post, with the 4-byte ACK the firmware sent', () {
    final copy = _open(roomFromAd77, [aPub])!;
    expect(copy.isRoomPost, isTrue);
    expect(copy.text, 'room post');
    expect(copy.authorPrefix, _hex('A277F94F'));
    expect(copy.attempt, 1);
    expect(copy.ack, roomAck);
  });

  group('leaves alone', () {
    test('a copy with no hops left: the radio opens that one itself', () {
      final last = Uint8List.fromList([0x0A, 0x40, ...dmFromAd77.sublist(4)]);
      expect(_open(last, [aPub]), isNull);
    });

    test('a DM addressed to another radio', () {
      final other = Uint8List.fromList(dmFromAd77)..[4] = 0x00;
      expect(_open(other, [aPub]), isNull);
    });

    test('a sender it has no key for', () {
      expect(_open(dmFromAd77, [bPub]), isNull);
    });

    test('a copy whose MAC fails', () {
      final bad = Uint8List.fromList(dmFromAd77)..[dmFromAd77.length - 1] ^= 1;
      expect(_open(bad, [aPub]), isNull);
    });

    test("a contact sharing this radio's first key byte: it reads the same as "
        'my own DM to them, echoed back', () {
      // A contact keyed like this radio itself shares its first byte, and
      // the copy below opens with their shared secret: without the rule it
      // would be taken for a DM from them.
      final secret = _opener().sharedSecret(bPub)!;
      final plain = Uint8List(16)..setAll(0, [0x10, 0x20, 0x30, 0x40, 0x00, 0x68, 0x69]);
      final aes = AESEngine()..init(true, KeyParameter(secret.sublist(0, 16)));
      final enc = Uint8List(16);
      aes.processBlock(plain, 0, enc, 0);
      final mac = crypto.Hmac(crypto.sha256, secret).convert(enc).bytes;
      final macAndData = Uint8List.fromList([mac[0], mac[1], ...enc]);
      expect(PassingCopyOpener.macThenDecrypt(secret, macAndData), isNotNull,
          reason: 'the copy is readable');
      final copy = Uint8List.fromList(
          [0x0A, 0x41, 0xBE, 0xEF, bPub[0], bPub[0], ...macAndData]);
      expect(_open(copy, [bPub]), isNull);
    });
  });

  group('ACK packets, built as BaseChatMesh::sendAckTo builds them', () {
    test('with no route back: one flood, as the firmware sent it', () {
      final packets = PassingCopyOpener.ackPackets(
        dmAckPayload,
        routePathLen: 0xFF,
        routePath: const [],
        extraAck: true,
        floodWidth: 1,
      );
      expect(packets, [_hex('0D001FEE94EB00A7')]);
    });

    test('in a flood scope: the transport code TransportKey makes', () {
      final key = _hex('101112131415161718191A1B1C1D1E1F');
      expect(PassingCopyOpener.transportCode(key, 3, dmAckPayload), 0x6834);
      final packets = PassingCopyOpener.ackPackets(
        dmAckPayload,
        routePathLen: 0xFF,
        routePath: const [],
        extraAck: false,
        floodWidth: 2,
        scopeKey: key,
      );
      expect(packets, [_hex('0C34680000401FEE94EB00A7')]);
    });

    test('on a stored route: the extra MULTIPART ACK first, then the ACK', () {
      // A second DM, B now holding the route BEEF,AD77,A277 back to A with
      // extra ACKs on: the two packets B's firmware sent.
      final packets = PassingCopyOpener.ackPackets(
        _hex('E51A1F1F00B4'),
        routePathLen: 0x43,
        routePath: _hex('BEEFAD77A277'),
        extraAck: true,
        floodWidth: 2,
      );
      expect(packets, [
        _hex('2A43BEEFAD77A27713E51A1F1F00B4'),
        _hex('0E43BEEFAD77A277E51A1F1F00B4'),
      ]);
    });
  });
}
