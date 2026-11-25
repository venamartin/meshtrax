import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxpix/traxpix.dart';

/// A [side] x [side] mask, 255 inside the block from (x0, y0) to (x1, y1),
/// ends excluded.
Uint8List block(int side, int x0, int y0, int x1, int y1) {
  final m = Uint8List(side * side);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      m[y * side + x] = 255;
    }
  }
  return m;
}

void main() {
  group('the square around the subject', () {
    test('frames the subject with 8% each side, on a wide photo', () {
      // A 2048 x 1024 photo stretched to 512: one mask pixel is 4 x 2.
      final sq = subjectSquare(block(512, 100, 200, 200, 300), 512, 2048, 1024)!;
      // The subject runs about 402..798 across and 401..599 down; its middle
      // 96% is about 380 across.
      expect(sq.side, closeTo(396 * 0.96 * 1.16, 4));
      expect(sq.left + sq.side / 2, closeTo(600, 4));
      expect(sq.top + sq.side / 2, closeTo(500, 4));
    });

    test('stays on the photo where it fits', () {
      // A subject at the top left corner.
      final sq = subjectSquare(block(512, 0, 0, 100, 100), 512, 1024, 1024)!;
      expect(sq.left, 0);
      expect(sq.top, 0);
    });

    test('runs past a wide photo where the subject is wider than it is tall',
        () {
      final sq = subjectSquare(block(512, 20, 100, 490, 400), 512, 2048, 512)!;
      expect(sq.side, greaterThan(512));
      expect(sq.top, lessThan(0), reason: 'black fills in above and below');
    });

    test('is at least a quarter of the short side', () {
      // About 117 x 94 photo px, so 8% margins make 130: the floor is 200.
      final sq = subjectSquare(block(512, 226, 226, 286, 286), 512, 1000, 800)!;
      expect(sq.side, closeTo(200, 0.001));
    });

    test('is null for a mask with next to nothing in it', () {
      expect(subjectSquare(block(512, 0, 0, 10, 10), 512, 1000, 1000), isNull);
    });
  });

  test('the mask cut to the square is 0 past the photo', () {
    final mask = Uint8List(64 * 64)..fillRange(0, 64 * 64, 255);
    // A square half off the left of a 640 x 640 photo.
    final alpha = cropMask(
      mask,
      64,
      640,
      640,
      (left: -320.0, top: 0.0, side: 640.0),
      out: 64,
    );
    expect(alpha[10 * 64 + 5], 0, reason: 'past the photo');
    expect(alpha[10 * 64 + 50], 255);
  });

  group('black outside', () {
    final rgb = Uint8List(64 * 64 * 3)..fillRange(0, 64 * 64 * 3, 200);
    final alpha = block(64, 16, 16, 48, 48);
    final out = blackOutside(rgb, alpha, side: 64, fade: 4);

    test('is black outside the outline and the photo inside', () {
      expect(out[(2 * 64 + 2) * 3], 0);
      expect(out[(32 * 64 + 32) * 3], 200);
    });

    test('fades inward along the outline, never outward', () {
      final edge = out[(32 * 64 + 16) * 3];
      expect(edge, greaterThan(0));
      expect(edge, lessThan(200));
      expect(out[(32 * 64 + 15) * 3], 0);
    });
  });

  group('the lit box a viewer zooms to', () {
    test('frames what isn\'t black, with a margin', () {
      final rgb = Uint8List(100 * 100 * 3);
      for (var y = 40; y < 60; y++) {
        for (var x = 30; x < 50; x++) {
          rgb[(y * 100 + x) * 3 + 1] = 180;
        }
      }
      final box = litBox(rgb, side: 100)!;
      expect(box.left, closeTo(0.26, 0.001));
      expect(box.top, closeTo(0.36, 0.001));
      expect(box.right, closeTo(0.54, 0.001));
      expect(box.bottom, closeTo(0.64, 0.001));
    });

    test('is null when all is black or nothing is', () {
      expect(litBox(Uint8List(100 * 100 * 3), side: 100), isNull);
      expect(
        litBox(Uint8List(100 * 100 * 3)..fillRange(0, 30000, 90), side: 100),
        isNull,
      );
    });
  });
}
