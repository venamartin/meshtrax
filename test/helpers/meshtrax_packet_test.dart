import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:meshtrax/helpers/meshtrax_packet.dart';

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

// The shared secret of the two simulation radios in passing_copy_test (made
// by MeshCore's own code), whose keys start C3 and E7.
final secret =
    _hex('6AE94F988F1088625142CA4FC203441B0FCB04CFAB09C1519DE71CA518911707');
final blob = _hex('0102030405');

// The bytes on the air must never change: a phone on an older MeshTrax
// reads them.
final payload = _hex('E7C3D585F490823A954D34661E6BC341A26F0D31');

void main() {
  test('the sealed payload, byte for byte', () {
    expect(
      MeshTraxPacket.seal(secret,
          toByte: 0xE7, fromByte: 0xC3, dataType: dataTypeMeshTraxDm, blob: blob),
      payload,
    );
  });

  test('it opens to the data type and the blob, without the padding', () {
    final opened = MeshTraxPacket.open(secret, payload)!;
    expect(opened.dataType, dataTypeMeshTraxDm);
    expect(opened.blob, blob);
  });

  test('another secret, a changed byte or a short payload opens nothing', () {
    final other = Uint8List.fromList(secret)..[0] ^= 1;
    expect(MeshTraxPacket.open(other, payload), isNull);
    final changed = Uint8List.fromList(payload)..[10] ^= 1;
    expect(MeshTraxPacket.open(secret, changed), isNull);
    expect(MeshTraxPacket.open(secret, payload.sublist(0, 12)), isNull);
  });

  test('a blob of every length up to 141 comes back whole', () {
    for (var n = 0; n <= 141; n++) {
      final b = Uint8List.fromList([for (var i = 0; i < n; i++) i]);
      final sealed = MeshTraxPacket.seal(secret,
          toByte: 1, fromByte: 2, dataType: dataTypeMeshTraxAck, blob: b);
      final opened = MeshTraxPacket.open(secret, sealed)!;
      expect(opened.dataType, dataTypeMeshTraxAck);
      expect(opened.blob, b, reason: '$n bytes');
    }
  });

  test('the packets handed to the radio, byte for byte', () {
    expect(
      MeshTraxPacket.routed(payload, _hex('A277AD77BEEF'), 2),
      _hex('1A43A277AD77BEEFE7C3D585F490823A954D34661E6BC341A26F0D31'),
      reason: 'group data, routed, three 2-byte repeaters',
    );
    expect(
      MeshTraxPacket.flood(payload, 2),
      _hex('1940E7C3D585F490823A954D34661E6BC341A26F0D31'),
    );
    expect(
      MeshTraxPacket.flood(payload, 2,
          scopeKey: _hex('000102030405060708090A0B0C0D0E0F')),
      _hex('18C876000040E7C3D585F490823A954D34661E6BC341A26F0D31'),
      reason: 'the region code, then two zero bytes, as the radio writes them',
    );
  });

  // Owner, 2026-11-27: "make sure you know the maximum packet size that
  // still allows us to sniff." A flood grows by a repeater's code at each
  // one; past 173 bytes on the air the app never sees the packet.
  group('room for the blob while the packet can still be heard', () {
    int onAir(int blobBytes, int pathBytes, {bool scoped = false}) {
      final sealed = MeshTraxPacket.seal(secret,
          toByte: 1,
          fromByte: 2,
          dataType: dataTypeMeshTraxDm,
          blob: Uint8List(blobBytes));
      return 2 + (scoped ? 4 : 0) + pathBytes + sealed.length;
    }

    test('the largest blob fits and one byte more does not', () {
      for (final scoped in [false, true]) {
        for (var pathBytes = 0; pathBytes <= 64; pathBytes += 2) {
          final room =
              MeshTraxPacket.roomFor(pathBytes: pathBytes, scoped: scoped);
          expect(onAir(room, pathBytes, scoped: scoped),
              lessThanOrEqualTo(heardPacketMaxBytes));
          expect(onAir(room + 1, pathBytes, scoped: scoped),
              greaterThan(heardPacketMaxBytes));
        }
      }
    });

    test('the numbers a format is planned with', () {
      expect(MeshTraxPacket.roomFor(pathBytes: 12), 141,
          reason: 'routed over six repeaters');
      expect(MeshTraxPacket.roomFor(pathBytes: 16, scoped: true), 141,
          reason: 'a region flood heard after eight repeaters');
      expect(MeshTraxPacket.roomFor(pathBytes: 32, scoped: true), 125,
          reason: 'after sixteen');
    });
  });
}
