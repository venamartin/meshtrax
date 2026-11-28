import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxshare/traxshare.dart';

/// Version 2, kind 1, from B4E1029C, sent 2026-11-21 18:30:05 UTC. Every
/// later version starts the same way.
const _v2 = [0x21, 0xB4, 0xE1, 0x02, 0x9C, 0x2D, 0xE3, 0x01, 0x6B];

void main() {
  test('the header of version 2, both ways', () {
    final h = TraxHeader.decode(Uint8List.fromList(_v2))!;
    expect(h.version, 2);
    expect(h.kind, 1);
    expect(h.senderPrefix, [0xB4, 0xE1, 0x02, 0x9C]);
    expect(h.sentAt, DateTime.utc(2026, 11, 21, 18, 30, 5));
    expect(h.encode(), _v2);
  });

  test('a packet from the future reads the same: a later version, another '
      'kind and more bytes after the header', () {
    final h = TraxHeader.decode(
      Uint8List.fromList([0xF9, ..._v2.skip(1), ...List.filled(40, 0xFF)]),
    )!;
    expect(h.version, 15);
    expect(h.kind, 9);
    expect(h.senderPrefix, [0xB4, 0xE1, 0x02, 0x9C]);
    expect(h.sentAt, DateTime.utc(2026, 11, 21, 18, 30, 5));
  });

  test('version 1 and earlier, kind 0 and a short packet have none', () {
    for (final first in [0x12, 0x13, 0x01, 0x20]) {
      expect(
        TraxHeader.decode(Uint8List.fromList([first, ..._v2.skip(1)])),
        isNull,
        reason: first.toRadixString(16),
      );
    }
    expect(TraxHeader.decode(Uint8List.fromList(_v2.sublist(0, 8))), isNull);
  });
}
