import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix_litert/src/image_safety.dart';

void main() {
  group('imageSafetyInput', () {
    test('keeps a flat colour exactly, in channel planes', () {
      final rgb = Uint8List(512 * 512 * 3);
      for (var i = 0; i < rgb.length; i += 3) {
        rgb[i] = 10;
        rgb[i + 1] = 200;
        rgb[i + 2] = 255;
      }
      final chw = imageSafetyInput(rgb, 512);
      expect(chw.length, 3 * 224 * 224);
      const plane = 224 * 224;
      for (final (c, want) in [(0, 10.0), (1, 200.0), (2, 255.0)]) {
        for (final i in [0, plane ~/ 2, plane - 1]) {
          expect(chw[c * plane + i], closeTo(want, 1e-3));
        }
      }
    });

    test('keeps the mean brightness and the picture the right way up', () {
      // Top half black, bottom half white.
      final rgb = Uint8List(512 * 512 * 3);
      rgb.fillRange(256 * 512 * 3, rgb.length, 255);
      final chw = imageSafetyInput(rgb, 512);
      final red = chw.sublist(0, 224 * 224);
      final mean = red.reduce((a, b) => a + b) / red.length;
      expect(mean, closeTo(127.5, 1e-2));
      expect(red.first, 0);
      expect(red.last, closeTo(255, 1e-3));
    });

    test('scales the whole picture, so an edge pixel still counts', () {
      final rgb = Uint8List(512 * 512 * 3);
      final last = (511 * 512 + 511) * 3;
      rgb[last] = 255;
      final chw = imageSafetyInput(rgb, 512);
      expect(chw[224 * 224 - 1], greaterThan(0));
    });

    test('refuses the wrong size', () {
      expect(() => imageSafetyInput(Uint8List(10), 512), throwsArgumentError);
    });
  });

  group('ImageSafetyThresholds', () {
    const t = ImageSafetyThresholds(nsfw: 0.3, nsfl: 0.3, combined: 0.5);
    ImageSafetyScores s(double nsfl, double nsfw) =>
        ImageSafetyScores(nsfl: nsfl, nsfw: nsfw, sfw: 1 - nsfl - nsfw);

    test('passes a safe picture', () => expect(t.flags(s(0.05, 0.05)), false));
    test('flags nudity alone', () => expect(t.flags(s(0, 0.3)), true));
    test('flags gore alone', () => expect(t.flags(s(0.3, 0)), true));
    test('flags a score split between the two', () {
      expect(t.flags(s(0.26, 0.26)), true);
    });
  });
}
