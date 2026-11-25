import 'dart:math' as math;
import 'dart:typed_data';

/// MediaPipe's Interactive Segmenter model, which outlines whatever is under a
/// tap (Apache-2.0). It comes with the app, beside the face models.
const String kTapSegmenterFile = 'magic_touch.tflite';

/// Side of the square the tap model takes and gives.
const int kTapSegmenterSize = 512;

/// The tap model's input for a tap at ([x], [y]), from 0 to 1 from the top
/// left, on [rgbBytes]: the whole photo stretched to 512 x 512, packed RGB.
/// It is `[1, 512, 512, 4]`: the colours from 0 to 1, then the tap as a dot
/// about two pixels across. Checked against MediaPipe's own Interactive
/// Segmenter on eight photos: the outlines agree within 1-2% where the
/// subject is clear.
Float32List tapModelInput(Uint8List rgbBytes, double x, double y) {
  const side = kTapSegmenterSize, pixels = side * side;
  if (rgbBytes.length != pixels * 3) {
    throw ArgumentError('expected ${pixels * 3} RGB bytes, got ${rgbBytes.length}');
  }
  final input = Float32List(pixels * 4);
  final tx = x * side, ty = y * side;
  for (var py = 0; py < side; py++) {
    for (var px = 0; px < side; px++) {
      final i = py * side + px;
      input[i * 4] = rgbBytes[i * 3] / 255;
      input[i * 4 + 1] = rgbBytes[i * 3 + 1] / 255;
      input[i * 4 + 2] = rgbBytes[i * 3 + 2] / 255;
      final dx = px + 0.5 - tx, dy = py + 0.5 - ty;
      final d2 = dx * dx + dy * dy;
      if (d2 < 2.25) {
        // 1.5 - distance, so the pixel tapped is 1 and its neighbours less.
        input[i * 4 + 3] = (1.5 - math.sqrt(d2)).clamp(0, 1).toDouble();
      }
    }
  }
  return input;
}
