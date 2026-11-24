import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// The photo is stored sideways with EXIF orientation 6, as Android's image
/// picker and the Mac's gallery can hand it over: upright it's 32 wide and
/// 64 tall, red on top, blue below (scripts/make-oriented-jpeg.py).
void main() {
  test('a photo decodes the right way up, from its orientation tag', () async {
    final bytes = File('test/fixtures/photo-orientation-6.jpg')
        .readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    expect((image.width, image.height), (32, 64));
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    int red(int x, int y) => rgba.getUint8((y * image.width + x) * 4);
    expect(red(16, 8), greaterThan(200), reason: 'red on top');
    expect(red(16, 56), lessThan(60), reason: 'blue below');
  });
}
