@TestOn('mac-os')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix/traxpix.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

/// A large bright subject on black, which the VAE in half precision rebuilds
/// as nothing but NaN. Needs, from the environment:
///   TRAXPIX_LITERT_LIB    the Mac's libCLiteRT_mac.dylib
///   TRAXPIX_LITERT_DIR    the .tflite files and aeic_cdf_ft8.bin
void main() {
  final env = Platform.environment;
  final lib = env['TRAXPIX_LITERT_LIB'];
  final dir = env['TRAXPIX_LITERT_DIR'];

  test(
    'a large bright subject on black is rebuilt',
    () async {
      final session = await ImageCodecSession.spawn(
        ImageCodecBundle.inDirectory(dir!, weightCache: false),
        libraryPath: lib,
      );
      try {
        final sent = await session.encode(_subjectOnBlack());
        final rebuilt = await session.rebuild(sent.bitstream!);
        expect(rebuilt.flagged, isFalse);
        final rgb = rebuilt.rgb!;
        expect(rgb[(256 * 512 + 256) * 3], greaterThan(150));
        expect(rgb[(10 * 512 + 10) * 3], lessThan(16));
      } finally {
        await session.dispose();
      }
    },
    skip: lib == null || dir == null
        ? 'set TRAXPIX_LITERT_LIB and TRAXPIX_LITERT_DIR'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// A light 400 x 300 ellipse, shaded top to bottom, with everything around it
/// black, as Subject only leaves it.
Uint8List _subjectOnBlack() {
  const side = 512;
  final rgb = Uint8List(side * side * 3);
  final alpha = Uint8List(side * side);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final dx = (x - 256) / 200, dy = (y - 256) / 150;
      final i = y * side + x;
      alpha[i] = dx * dx + dy * dy < 1 ? 255 : 0;
      final shade = (235 - 40 * dy).clamp(0, 255).round();
      rgb[i * 3] = rgb[i * 3 + 1] = rgb[i * 3 + 2] = shade;
    }
  }
  return blackOutside(rgb, alpha);
}
