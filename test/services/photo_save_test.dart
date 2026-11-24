import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/services/photo_save.dart';
import 'package:meshtrax/widgets/photo_footprint_mark.dart';

void main() {
  testWidgets('a saved copy carries the footprint in its lower-right corner '
      'and leaves the rest of the picture alone', (tester) async {
    await tester.runAsync(() async {
      const side = 512;
      const grey = 64;
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 512, 512),
        Paint()..color = const Color.fromARGB(255, grey, grey, grey),
      );
      final picture = await recorder.endRecording().toImage(side, side);
      final png = await markedPng(picture, 'AI reconstructed');
      final saved = await decodePng(png);
      final rgba = (await saved.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      int red(int x, int y) => rgba[(y * side + x) * 4];

      final f = photoFootprintFor(side.toDouble());
      var brightest = 0;
      for (
        var y = side - (f.bottom + f.height).round();
        y < side - f.bottom;
        y++
      ) {
        for (
          var x = side - (f.right + f.height).round();
          x < side - f.right;
          x++
        ) {
          brightest = red(x, y) > brightest ? red(x, y) : brightest;
        }
      }
      expect(brightest, greaterThan(170), reason: 'white footprint');
      expect(red(side ~/ 2, side ~/ 2), grey, reason: 'the middle untouched');
      expect(red(side - 2, 2), grey, reason: 'the top-right untouched');
      expect(Uint8List.fromList(png).isNotEmpty, isTrue);
    });
  });
}
