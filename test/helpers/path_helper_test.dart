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

// A 2-hop route at 2-byte width: A277 → BEEF. Read at 1-byte width the same
// bytes look like four hops, which is the mislabel this helper exists to end.
const _twoByteRoute = [0xA2, 0x77, 0xBE, 0xEF];

void main() {
  group('path_len byte codec', () {
    test('decodes hop count and width', () {
      expect(PathHelper.pathLenHops(0x42), 2);
      expect(PathHelper.pathLenWidth(0x42), 2);
      expect(PathHelper.pathLenBytes(0x42), 4);

      expect(PathHelper.pathLenHops(0x04), 4);
      expect(PathHelper.pathLenWidth(0x04), 1);
      expect(PathHelper.pathLenBytes(0x04), 4);

      expect(PathHelper.pathLenHops(0x00), 0);
      expect(PathHelper.pathLenWidth(0x00), 1);
    });

    test('0xFF is no route, also when read signed', () {
      for (final b in [0xFF, -1]) {
        expect(PathHelper.pathLenHops(b), -1);
        expect(PathHelper.pathLenWidth(b), 1);
      }
    });

    test('encodes and round-trips every width and hop count', () {
      expect(PathHelper.encodePathLen(2, 2), 0x42);
      expect(PathHelper.encodePathLen(4, 1), 0x04);
      expect(PathHelper.encodePathLen(-1, 2), 0xFF);
      for (var width = 1; width <= 3; width++) {
        for (var hops = 0; hops <= 63; hops++) {
          final b = PathHelper.encodePathLen(hops, width);
          expect(PathHelper.pathLenHops(b), hops);
          expect(PathHelper.pathLenWidth(b), width);
          expect(PathHelper.pathLenBytes(b), hops * width);
        }
      }
    });

    test('trace flags are log2 of the width; 3 bytes cannot be traced', () {
      expect(PathHelper.traceFlags(1), 0);
      expect(PathHelper.traceFlags(2), 1);
      expect(PathHelper.traceFlags(3), isNull);
      expect(PathHelper.traceFlags(4), 2);
    });

    test('hash mode is width minus one', () {
      expect(PathHelper.hashModeFromWidth(1), 0);
      expect(PathHelper.hashModeFromWidth(2), 1);
    });

    test('editor limits follow the width', () {
      expect(PathHelper.maxHops(1), 64);
      expect(PathHelper.maxHops(2), 32);
      expect(PathHelper.maxPathInputChars(1), 191);
      expect(PathHelper.maxPathInputChars(2), 159);
    });
  });

  group('formatPathHex', () {
    test('groups bytes per hop at the given width', () {
      expect(PathHelper.formatPathHex(_twoByteRoute, stride: 2), 'A277,BEEF');
      expect(
        PathHelper.formatPathHex(_twoByteRoute, stride: 1),
        'A2,77,BE,EF',
      );
      expect(PathHelper.formatPathHex([], stride: 2), '');
    });

    test('stops at a slot whose first byte is zero, keeps 0xAA00', () {
      expect(
        PathHelper.formatPathHex([0xA2, 0x77, 0x00, 0x11], stride: 2),
        'A277',
      );
      expect(
        PathHelper.formatPathHex([0xAA, 0x00, 0xBE, 0xEF], stride: 2),
        'AA00,BEEF',
      );
    });
  });

  group('getHopCount / getHops / lastHop', () {
    test('counts hops at the given width', () {
      expect(PathHelper.getHopCount(_twoByteRoute, stride: 2), 2);
      expect(PathHelper.getHopCount(_twoByteRoute, stride: 1), 4);
      expect(PathHelper.getHopCount([], stride: 2), 0);
    });

    test('splits into hops and finds the last one', () {
      final hops = PathHelper.getHops(_twoByteRoute, stride: 2);
      expect(hops.map(PathHelper.hopHex), ['A277', 'BEEF']);
      expect(PathHelper.lastHop(_twoByteRoute, stride: 2), [0xBE, 0xEF]);
      expect(PathHelper.lastHopHex(_twoByteRoute, stride: 1), 'EF');
      expect(PathHelper.lastHop([], stride: 2), isNull);
    });
  });

  group('parsePathHex', () {
    test('parses tokens at the given width', () {
      final parsed = PathHelper.parsePathHex('A277, BEEF', stride: 2);
      expect(parsed.path, Uint8List.fromList(_twoByteRoute));
      expect(parsed.invalid, isEmpty);
    });

    test('rejects tokens that are too short or not hex', () {
      final parsed = PathHelper.parsePathHex('A2, BEEF, ZZZZ', stride: 2);
      expect(parsed.path, Uint8List.fromList([0xBE, 0xEF]));
      expect(parsed.invalid, ['A2', 'ZZZZ']);
    });
  });

  test('resolvePathNames ignores chat nodes and keeps repeater/room nodes', () {
    final contacts = [
      _contact(firstByte: 0xF2, name: 'MunTui', type: advTypeChat),
      _contact(firstByte: 0x7E, name: 'zrepeater', type: advTypeRepeater),
      _contact(firstByte: 0xBA, name: 'USS Ronald Reagan', type: advTypeRoom),
    ];

    final resolved = PathHelper.resolvePathNames(
      [0xF2, 0x7E, 0xBA],
      contacts,
      stride: 1,
    );

    expect(resolved, equals('F2 → zrepeater → USS Ronald Reagan'));
  });

  group('isRoundTrip', () {
    test('flags a symmetric 3-hop route as already round trip', () {
      // A2 → F5 → A2
      expect(PathHelper.isRoundTrip([0xA2, 0xF5, 0xA2], stride: 1), isTrue);
    });

    test('rejects a one-way path', () {
      // A2 → F5
      expect(PathHelper.isRoundTrip([0xA2, 0xF5], stride: 1), isFalse);
    });

    test('rejects a single hop', () {
      expect(PathHelper.isRoundTrip([0xA2], stride: 1), isFalse);
      expect(PathHelper.isRoundTrip([], stride: 1), isFalse);
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
        PathHelper.roundTripPath([0xA2, 0xF5], stride: 1),
        equals(Uint8List.fromList([0xA2, 0xF5, 0xA2])),
      );
    });

    test('doubles an already-round-trip path (the bug the guard prevents)', () {
      // Without the isRoundTrip guard in buildPath, re-expanding a complete
      // round trip appends a second return leg.
      expect(
        PathHelper.roundTripPath([0xA2, 0xF5, 0xA2], stride: 1),
        equals(Uint8List.fromList([0xA2, 0xF5, 0xA2, 0xF5, 0xA2])),
      );
    });
  });
}
