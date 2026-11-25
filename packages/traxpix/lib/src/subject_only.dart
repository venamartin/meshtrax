import 'dart:math' as math;
import 'dart:typed_data';

// "Subject only" and Auto crop: the sender taps what matters in a photo, a
// small model outlines it, and the photo is cropped to a square around it,
// with everything else made black for Subject only. The outline is a mask
// over the whole photo stretched to a square (the model's own input), so a
// mask pixel (mx, my) covers the photo around (mx + 0.5, my + 0.5) * w/side,
// * h/side.

/// A square in photo pixels; it may run past the photo's edges, where black
/// fills in.
typedef PhotoSquare = ({double left, double top, double side});

/// The square around the outlined subject: the middle 96% of its mask (so
/// stray specks don't widen it), 8% of margin on each side, at least a
/// quarter of the photo's short side, and kept on the photo where it fits.
/// Null when the mask holds next to nothing.
PhotoSquare? subjectSquare(Uint8List mask, int maskSide, int photoW, int photoH) {
  final xs = <double>[], ys = <double>[];
  final sx = photoW / maskSide, sy = photoH / maskSide;
  for (var my = 0; my < maskSide; my++) {
    final row = my * maskSide;
    for (var mx = 0; mx < maskSide; mx++) {
      if (mask[row + mx] > 127) {
        xs.add((mx + 0.5) * sx);
        ys.add((my + 0.5) * sy);
      }
    }
  }
  if (xs.length < 0.01 * maskSide * maskSide) return null;
  xs.sort();
  ys.sort();
  double at(List<double> v, double p) => v[((v.length - 1) * p).round()];
  final x0 = at(xs, 0.02), x1 = at(xs, 0.98);
  final y0 = at(ys, 0.02), y1 = at(ys, 0.98);
  final side = math.max(
    math.max(x1 - x0, y1 - y0) * 1.16,
    0.25 * math.min(photoW, photoH),
  );
  var left = (x0 + x1) / 2 - side / 2;
  var top = (y0 + y1) / 2 - side / 2;
  if (side <= photoW) left = left.clamp(0, photoW - side).toDouble();
  if (side <= photoH) top = top.clamp(0, photoH - side).toDouble();
  return (left: left, top: top, side: side);
}

/// The mask over the part of the photo in [square], as [out] x [out] alpha
/// (0 past the photo's edges), sampled bilinearly.
Uint8List cropMask(
  Uint8List mask,
  int maskSide,
  int photoW,
  int photoH,
  PhotoSquare square, {
  int out = 512,
}) {
  final alpha = Uint8List(out * out);
  final step = square.side / out;
  for (var v = 0; v < out; v++) {
    final py = square.top + (v + 0.5) * step;
    if (py < 0 || py >= photoH) continue;
    final my = py / photoH * maskSide - 0.5;
    final y0 = my.floor().clamp(0, maskSide - 1);
    final y1 = (y0 + 1).clamp(0, maskSide - 1);
    final fy = (my - y0).clamp(0.0, 1.0);
    for (var u = 0; u < out; u++) {
      final px = square.left + (u + 0.5) * step;
      if (px < 0 || px >= photoW) continue;
      final mx = px / photoW * maskSide - 0.5;
      final x0 = mx.floor().clamp(0, maskSide - 1);
      final x1 = (x0 + 1).clamp(0, maskSide - 1);
      final fx = (mx - x0).clamp(0.0, 1.0);
      final top = mask[y0 * maskSide + x0] * (1 - fx) + mask[y0 * maskSide + x1] * fx;
      final bottom =
          mask[y1 * maskSide + x0] * (1 - fx) + mask[y1 * maskSide + x1] * fx;
      alpha[v * out + u] = (top * (1 - fy) + bottom * fy).round();
    }
  }
  return alpha;
}

/// [rgb] ([side] x [side], packed) with everything outside [alpha] black.
/// The outline fades inward over about [fade] px: the codec spends a third
/// of a photo's bytes along it, and a soft edge costs a little less.
Uint8List blackOutside(
  Uint8List rgb,
  Uint8List alpha, {
  int side = 512,
  int fade = 8,
}) {
  final soft = _blur(alpha, side, fade);
  final out = Uint8List(rgb.length);
  for (var i = 0, o = 0; i < alpha.length; i++, o += 3) {
    final a = math.min(soft[i], alpha[i]) / 255;
    out[o] = (rgb[o] * a).round();
    out[o + 1] = (rgb[o + 1] * a).round();
    out[o + 2] = (rgb[o + 2] * a).round();
  }
  return out;
}

/// About a Gaussian of [sigma] px: two box blurs each way.
Uint8List _blur(Uint8List values, int side, int sigma) {
  final r = math.max(1, (sigma * 1.1).round());
  var a = Float64List.fromList([for (final v in values) v.toDouble()]);
  for (var pass = 0; pass < 2; pass++) {
    a = _boxRows(a, side, r);
    a = _boxColumns(a, side, r);
  }
  return Uint8List.fromList([for (final v in a) v.round().clamp(0, 255)]);
}

Float64List _boxRows(Float64List a, int side, int r) {
  final out = Float64List(a.length);
  for (var y = 0; y < side; y++) {
    final row = y * side;
    var sum = 0.0;
    for (var x = -r; x <= r; x++) {
      sum += a[row + x.clamp(0, side - 1)];
    }
    for (var x = 0; x < side; x++) {
      out[row + x] = sum / (2 * r + 1);
      sum += a[row + (x + r + 1).clamp(0, side - 1)] -
          a[row + (x - r).clamp(0, side - 1)];
    }
  }
  return out;
}

Float64List _boxColumns(Float64List a, int side, int r) {
  final out = Float64List(a.length);
  for (var x = 0; x < side; x++) {
    var sum = 0.0;
    for (var y = -r; y <= r; y++) {
      sum += a[y.clamp(0, side - 1) * side + x];
    }
    for (var y = 0; y < side; y++) {
      out[y * side + x] = sum / (2 * r + 1);
      sum += a[(y + r + 1).clamp(0, side - 1) * side + x] -
          a[(y - r).clamp(0, side - 1) * side + x];
    }
  }
  return out;
}

/// The part of a Subject only picture that isn't black, with 4% of margin,
/// as fractions of its side (left, top, right, bottom), for a viewer to open
/// zoomed in on. Null when nothing is lit or the subject fills the picture.
({double left, double top, double right, double bottom})? litBox(
  Uint8List rgb, {
  int side = 512,
  int threshold = 24,
}) {
  var x0 = side, y0 = side, x1 = -1, y1 = -1;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final o = (y * side + x) * 3;
      if (math.max(rgb[o], math.max(rgb[o + 1], rgb[o + 2])) > threshold) {
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
      }
    }
  }
  if (x1 < 0) return null;
  const m = 0.04;
  final box = (
    left: math.max(0.0, x0 / side - m),
    top: math.max(0.0, y0 / side - m),
    right: math.min(1.0, (x1 + 1) / side + m),
    bottom: math.min(1.0, (y1 + 1) / side + m),
  );
  if (box.right - box.left > 0.95 && box.bottom - box.top > 0.95) return null;
  return box;
}
