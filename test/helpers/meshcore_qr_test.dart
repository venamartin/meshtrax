import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/meshcore_qr.dart';

final _key = List.generate(32, (i) => 0x70 + i);
final _keyHex =
    _key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// A raw advert packet (Packet.h): header, transport codes for the
/// transport route types, path_len, path, then pubkey, timestamp,
/// signature and app_data (AdvertDataHelpers.h).
String card({
  int header = 0x11, // flood, advert
  List<int> transport = const [],
  int pathLen = 0,
  List<int> path = const [],
  int flags = 0x81, // chat, has name
  List<int> latLon = const [],
  String name = '¿🟦?',
}) {
  final bytes = [
    header,
    ...transport,
    pathLen,
    ...path,
    ..._key,
    0x93, 0x64, 0xE7, 0x6A, // timestamp
    ...List.filled(64, 0x5A), // signature: never checked
    flags,
    ...latLon,
    ...utf8.encode(name),
  ];
  return 'meshcore://${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

void main() {
  group('parseAdvertCard', () {
    test('reads the key, type and name, emoji and all', () {
      final c = MeshCoreQr.parseAdvertCard(card())!;
      expect(c.pubKeyHex, _keyHex);
      expect(c.type, 1);
      expect(c.name, '¿🟦?');
      expect(c.latitude, isNull);
    });

    test('reads a position when the advert carries one', () {
      final ll = ByteData(8)
        ..setInt32(0, 36974000, Endian.little)
        ..setInt32(4, -122030000, Endian.little);
      final c = MeshCoreQr.parseAdvertCard(card(
          flags: 0x93, latLon: ll.buffer.asUint8List(), name: 'Hill'))!;
      expect(c.type, 3);
      expect(c.latitude, 36.974);
      expect(c.longitude, -122.03);
      expect(c.name, 'Hill');
    });

    test('an exported contact keeps the path and transport codes it was heard with', () {
      final c = MeshCoreQr.parseAdvertCard(card(
          header: 0x10, // transport flood, advert
          transport: [1, 2, 3, 4],
          pathLen: 0x42, // two 2-byte hops
          path: [0xA2, 0x77, 0xBE, 0xEF]))!;
      expect(c.pubKeyHex, _keyHex);
      expect(c.name, '¿🟦?');
    });

    test('hex case, a trailing newline and wrapped lines do not matter', () {
      final link = card();
      final hex = link.substring('meshcore://'.length).toUpperCase();
      final wrapped = 'MeshCore://${hex.substring(0, 60)}\n'
          '${hex.substring(60)}\n';
      expect(MeshCoreQr.parseAdvertCard(wrapped)?.pubKeyHex, _keyHex);
    });

    test('anything else is not a card', () {
      expect(MeshCoreQr.parseAdvertCard(card(header: 0x09)), isNull,
          reason: 'a DM packet');
      final full = card();
      expect(
          MeshCoreQr.parseAdvertCard(
              full.substring(0, 'meshcore://'.length + 120)),
          isNull,
          reason: 'cut short');
      expect(MeshCoreQr.parseAdvertCard('meshcore://zz$_keyHex'), isNull);
      expect(MeshCoreQr.parseAdvertCard(_keyHex), isNull,
          reason: 'a bare key has its own path');
      expect(
          MeshCoreQr.parseAdvertCard(
              'meshcore://contact/add?name=A&public_key=$_keyHex&type=1'),
          isNull);
    });
  });
}
