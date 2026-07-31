import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';

Contact _contact({
  required int firstByte,
  required String name,
  required int type,
}) {
  final key = Uint8List(32)..[0] = firstByte;
  return Contact(
    publicKey: key,
    name: name,
    type: type,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime.now(),
  );
}

void main() {
  test('resolvePathNames ignores chat nodes and keeps repeater/room nodes', () {
    final contacts = [
      _contact(firstByte: 0xF2, name: 'MunTui', type: advTypeChat),
      _contact(firstByte: 0x7E, name: 'zrepeater', type: advTypeRepeater),
      _contact(firstByte: 0xBA, name: 'USS Ronald Reagan', type: advTypeRoom),
    ];

    final resolved = PathHelper.resolvePathNames([0xF2, 0x7E, 0xBA], contacts);

    expect(resolved, equals('F2 → zrepeater → USS Ronald Reagan'));
  });

  group('isRoundTrip', () {
    test('flags a symmetric 3-hop route as already round trip', () {
      // A2 → F5 → A2
      expect(PathHelper.isRoundTrip([0xA2, 0xF5, 0xA2]), isTrue);
    });

    test('rejects a one-way path', () {
      // A2 → F5
      expect(PathHelper.isRoundTrip([0xA2, 0xF5]), isFalse);
    });

    test('rejects a single hop', () {
      expect(PathHelper.isRoundTrip([0xA2]), isFalse);
      expect(PathHelper.isRoundTrip([]), isFalse);
    });

    test('honors 2-byte hop stride', () {
      // AA77 → BB88 → AA77
      expect(
        PathHelper.isRoundTrip(
          [0xAA, 0x77, 0xBB, 0x88, 0xAA, 0x77],
          stride: 2,
        ),
        isTrue,
      );
      // AA77 → BB88 (one way) is not a round trip
      expect(
        PathHelper.isRoundTrip([0xAA, 0x77, 0xBB, 0x88], stride: 2),
        isFalse,
      );
    });
  });

  group('roundTripPath', () {
    test('expands a one-way path and back', () {
      // A2 → F5  becomes  A2 → F5 → A2
      expect(
        PathHelper.roundTripPath([0xA2, 0xF5]),
        equals(Uint8List.fromList([0xA2, 0xF5, 0xA2])),
      );
    });

    test('doubles an already-round-trip path (the bug the guard prevents)', () {
      // Without the isRoundTrip guard in buildPath, re-expanding a complete
      // round trip appends a second return leg.
      expect(
        PathHelper.roundTripPath([0xA2, 0xF5, 0xA2]),
        equals(Uint8List.fromList([0xA2, 0xF5, 0xA2, 0xF5, 0xA2])),
      );
    });
  });
}
