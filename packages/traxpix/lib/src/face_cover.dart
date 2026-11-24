import 'dart:math' as math;
import 'dart:typed_data';

// Faces in a photo, found with MediaPipe's two BlazeFace models and covered
// before the photo is coded: the AI that rebuilds photos can't draw faces,
// so it makes them up. Ported from the tests that chose the settings (68 of
// 68 photos sent and shown, 2026-11-23): the short-range model on the whole
// photo, kept at 0.75 or more; the full-range model on the whole photo and
// on four overlapping quarters, at 0.5; boxes merged by MediaPipe's weighted
// suppression; boxes whose points can't be a face dropped. The pictures go
// into the models as Pillow's bilinear resize makes them, bit for bit, and
// the blurs are scipy's, so this finds what the tests found.

/// Side of the square photo faces are found and covered in.
const int kFaceSide = 512;

/// One BlazeFace model's outputs for one picture: 16 regressors and one
/// score logit per anchor.
typedef FaceModelOutput = ({Float32List regressors, Float32List logits});

/// Runs a BlazeFace model on `[1, side, side, 3]` floats in -1..1: the
/// full-range model (192 px) when [fullRange], the short-range one (128 px)
/// otherwise.
typedef FaceModelRunner =
    FaceModelOutput Function(Float32List input, {required bool fullRange});

/// A face in a [kFaceSide] photo, in its pixels: the detector's box and six
/// points, each x then y: right eye, left eye, nose tip, mouth, right ear,
/// left ear (the person's right and left).
class FoundFace {
  final double score;
  final double x;
  final double y;
  final double w;
  final double h;
  final List<double> points;

  const FoundFace(this.score, this.x, this.y, this.w, this.h, this.points);
}

const double _shortRangeAt = 0.75;
const double _fullRangeAt = 0.5;
const double _sameFace = 0.3;

/// Faces at most this many pixels across get a flat tone, not a blur.
const int _small = 32;

/// How far a blurred face is pulled towards grey.
const double _grey = 0.85;

/// The fallback cover's tone, when the blurred photo doesn't pass the
/// safety check.
const double _dark = 45;

const _tiles = [
  (0, 0, kFaceSide),
  (0, 0, 320),
  (192, 0, 320),
  (0, 192, 320),
  (192, 192, 320),
];

final _shortAnchors = _anchors(128, const [(8, 2), (16, 6)]);
final _fullAnchors = _anchors(192, const [(4, 1)]);

/// MediaPipe's SSD anchors with fixed_anchor_size, x then y: one centre per
/// cell, repeated per anchor; layers that share a stride are merged.
Float64List _anchors(int size, List<(int, int)> groups) {
  final out = <double>[];
  for (final (stride, perCell) in groups) {
    final g = size ~/ stride;
    for (var y = 0; y < g; y++) {
      for (var x = 0; x < g; x++) {
        for (var k = 0; k < perCell; k++) {
          out
            ..add((x + 0.5) / g)
            ..add((y + 0.5) / g);
        }
      }
    }
  }
  return Float64List.fromList(out);
}

/// The faces in [rgb], packed 8-bit RGB of a [kFaceSide] square photo.
List<FoundFace> findFaces(Uint8List rgb, FaceModelRunner run) {
  if (rgb.length != kFaceSide * kFaceSide * 3) {
    throw ArgumentError('expected a $kFaceSide x $kFaceSide RGB photo');
  }
  final found = <_Detection>[..._detect(run, rgb, kFaceSide, fullRange: false)];
  for (final (x0, y0, side) in _tiles) {
    final tile = side == kFaceSide ? rgb : _crop(rgb, x0, y0, side);
    for (final d in _detect(run, tile, side, fullRange: true)) {
      found.add(d.within(x0, y0, side));
    }
  }
  return [
    for (final d in _mergeOverlapping(found))
      if (_plausible(d.inPixels())) d.inPixels(),
  ];
}

/// One detection, its box and points in 0..1 of the picture it was found in.
class _Detection {
  final double score;
  final Float64List values; // x, y, w, h, then the six points

  _Detection(this.score, this.values);

  /// From a tile at ([x0], [y0]), [side] pixels, to 0..1 of the photo.
  _Detection within(int x0, int y0, int side) {
    final v = Float64List(16);
    v[0] = (x0 + values[0] * side) / kFaceSide;
    v[1] = (y0 + values[1] * side) / kFaceSide;
    v[2] = values[2] * side / kFaceSide;
    v[3] = values[3] * side / kFaceSide;
    for (var i = 4; i < 16; i++) {
      v[i] = ((i.isEven ? x0 : y0) + values[i] * side) / kFaceSide;
    }
    return _Detection(score, v);
  }

  FoundFace inPixels() => FoundFace(
    score,
    values[0] * kFaceSide,
    values[1] * kFaceSide,
    values[2] * kFaceSide,
    values[3] * kFaceSide,
    [for (var i = 4; i < 16; i++) values[i] * kFaceSide],
  );
}

List<_Detection> _detect(
  FaceModelRunner run,
  Uint8List rgb,
  int side, {
  required bool fullRange,
}) {
  final size = fullRange ? 192 : 128;
  final anchors = fullRange ? _fullAnchors : _shortAnchors;
  final at = fullRange ? _fullRangeAt : _shortRangeAt;
  final scaled = pillowBilinear(rgb, side, size);
  final input = Float32List(scaled.length);
  for (var i = 0; i < scaled.length; i++) {
    input[i] = scaled[i] / 127.5 - 1.0;
  }
  final out = run(input, fullRange: fullRange);
  final n = anchors.length ~/ 2;
  if (out.logits.length != n || out.regressors.length != n * 16) {
    throw StateError('BlazeFace gave the wrong number of outputs');
  }
  final found = <_Detection>[];
  for (var i = 0; i < n; i++) {
    final logit = out.logits[i].clamp(-100.0, 100.0);
    final score = 1 / (1 + math.exp(-logit));
    if (score < at) continue;
    final r = i * 16;
    final ax = anchors[2 * i];
    final ay = anchors[2 * i + 1];
    final reg = out.regressors;
    final w = reg[r + 2] / size;
    final h = reg[r + 3] / size;
    final v = Float64List(16)
      ..[0] = reg[r] / size + ax - w / 2
      ..[1] = reg[r + 1] / size + ay - h / 2
      ..[2] = w
      ..[3] = h;
    for (var k = 0; k < 6; k++) {
      v[4 + 2 * k] = reg[r + 4 + 2 * k] / size + ax;
      v[5 + 2 * k] = reg[r + 5 + 2 * k] / size + ay;
    }
    found.add(_Detection(score, v));
  }
  return found;
}

Uint8List _crop(Uint8List rgb, int x0, int y0, int side) {
  final out = Uint8List(side * side * 3);
  for (var y = 0; y < side; y++) {
    final from = ((y0 + y) * kFaceSide + x0) * 3;
    out.setRange(y * side * 3, (y + 1) * side * 3, rgb, from);
  }
  return out;
}

double _overlap(Float64List a, Float64List b) {
  final ix = math.max(
    0.0,
    math.min(a[0] + a[2], b[0] + b[2]) - math.max(a[0], b[0]),
  );
  final iy = math.max(
    0.0,
    math.min(a[1] + a[3], b[1] + b[3]) - math.max(a[1], b[1]),
  );
  final inter = ix * iy;
  final union = a[2] * a[3] + b[2] * b[3] - inter;
  return union > 0 ? inter / union : 0.0;
}

/// MediaPipe's WEIGHTED suppression: each group of boxes overlapping the
/// best remaining one becomes their score-weighted mean, points too.
List<_Detection> _mergeOverlapping(List<_Detection> found) {
  final order = List<int>.generate(found.length, (i) => i)
    ..sort((a, b) {
      final c = found[b].score.compareTo(found[a].score);
      return c != 0 ? c : a.compareTo(b);
    });
  var rest = [for (final i in order) found[i]];
  final out = <_Detection>[];
  while (rest.isNotEmpty) {
    final top = rest.first;
    final group = [
      for (final d in rest)
        if (_overlap(top.values, d.values) > _sameFace) d,
    ];
    rest = [
      for (final d in rest)
        if (_overlap(top.values, d.values) <= _sameFace) d,
    ];
    final total = group.fold(0.0, (s, d) => s + d.score);
    final mean = Float64List(16);
    for (final d in group) {
      for (var i = 0; i < 16; i++) {
        mean[i] += d.score * d.values[i];
      }
    }
    for (var i = 0; i < 16; i++) {
      mean[i] /= total;
    }
    out.add(_Detection(top.score, mean));
  }
  return out;
}

/// Whether the six points can be a face: the mouth well below the eyes and
/// the nose not above them.
bool _plausible(FoundFace f) {
  final p = f.points;
  final midX = (p[0] + p[2]) / 2;
  final midY = (p[1] + p[3]) / 2;
  final e = math.sqrt(math.pow(p[2] - p[0], 2) + math.pow(p[3] - p[1], 2));
  if (e <= 0) return false;
  final ux = (p[2] - p[0]) / e;
  final uy = (p[3] - p[1]) / e;
  var vx = -uy;
  var vy = ux;
  if (vy < 0) {
    vx = -vx;
    vy = -vy;
  }
  final mouth = (p[6] - midX) * vx + (p[7] - midY) * vy;
  final nose = (p[4] - midX) * vx + (p[5] - midY) * vy;
  return mouth >= 0.25 * f.w && nose >= 0.05 * f.w;
}

/// An oval over a face: its centre, half width and half height, and its
/// across and down directions.
typedef _Oval = ({
  double cx,
  double cy,
  double hw,
  double hh,
  double ux,
  double uy,
  double vx,
  double vy,
});

/// Fitted to the six points: tilted with the eyes, ear to ear across, from a
/// little above the brows to the chin; points that don't make a face give an
/// oval inside the box.
_Oval _faceOval(FoundFace f) {
  final p = f.points;
  final (rex, rey, lex, ley) = (p[0], p[1], p[2], p[3]);
  final (mx, my, rax, ray, lax, lay) = (p[6], p[7], p[8], p[9], p[10], p[11]);
  final eyesX = (rex + lex) / 2;
  final eyesY = (rey + ley) / 2;
  final eyes = math.sqrt(math.pow(lex - rex, 2) + math.pow(ley - rey, 2));
  var ux = 1.0;
  var uy = 0.0;
  if (eyes > 1) {
    ux = (lex - rex) / eyes;
    uy = (ley - rey) / eyes;
  }
  var vx = -uy;
  var vy = ux;
  if (vy < 0) {
    vx = -vx;
    vy = -vy;
  }
  final d = (mx - eyesX) * vx + (my - eyesY) * vy;
  if (eyes <= 1 || d < 0.3 * eyes) {
    return (
      cx: f.x + f.w / 2,
      cy: f.y + f.h / 2,
      hw: 0.45 * f.w,
      hh: 0.55 * f.h,
      ux: 1,
      uy: 0,
      vx: 0,
      vy: 1,
    );
  }
  final ears = ((lax - rax) * ux + (lay - ray) * uy).abs();
  final hw = math.max(ears, 2.2 * eyes) / 2 * 1.05;
  final top = -0.55 * d;
  final bottom = 1.9 * d;
  final acrossX = (eyesX + (rax + lax) / 2) / 2;
  final acrossY = (eyesY + (ray + lay) / 2) / 2;
  final down =
      (top + bottom) / 2 - ((acrossX - eyesX) * vx + (acrossY - eyesY) * vy);
  return (
    cx: acrossX + vx * down,
    cy: acrossY + vy * down,
    hw: hw,
    hh: (bottom - top) / 2,
    ux: ux,
    uy: uy,
    vx: vx,
    vy: vy,
  );
}

/// The pixels a cover takes, 1 inside and 0 outside, with the box of the
/// pixels that are 1.
class _Mask {
  final Float32List values = Float32List(kFaceSide * kFaceSide);
  int x0 = kFaceSide;
  int y0 = kFaceSide;
  int x1 = 0;
  int y1 = 0;

  /// Adds the pixels whose centre-free coordinates fall in [o], as numpy's
  /// grid does: `(a / hw)^2 + (b / hh)^2 <= 1`.
  void add(_Oval o) {
    final ex = math.sqrt(math.pow(o.hw * o.ux, 2) + math.pow(o.hh * o.vx, 2));
    final ey = math.sqrt(math.pow(o.hw * o.uy, 2) + math.pow(o.hh * o.vy, 2));
    final xa = math.max(0, (o.cx - ex).floor() - 1);
    final xb = math.min(kFaceSide - 1, (o.cx + ex).ceil() + 1);
    final ya = math.max(0, (o.cy - ey).floor() - 1);
    final yb = math.min(kFaceSide - 1, (o.cy + ey).ceil() + 1);
    for (var y = ya; y <= yb; y++) {
      for (var x = xa; x <= xb; x++) {
        final a = ((x - o.cx) * o.ux + (y - o.cy) * o.uy) / o.hw;
        final b = ((x - o.cx) * o.vx + (y - o.cy) * o.vy) / o.hh;
        if (a * a + b * b <= 1.0) {
          values[y * kFaceSide + x] = 1;
          if (x < x0) x0 = x;
          if (y < y0) y0 = y;
          if (x + 1 > x1) x1 = x + 1;
          if (y + 1 > y1) y1 = y + 1;
        }
      }
    }
  }

  bool get isEmpty => x1 <= x0 || y1 <= y0;
}

/// An oval inside the detector's box, so a turned face is covered too.
_Oval _boxOval(FoundFace f, [double grow = 1.0]) => (
  cx: f.x + f.w / 2,
  cy: f.y + f.h * 0.55,
  hw: 0.5 * f.w * grow,
  hh: 0.6 * f.h * grow,
  ux: 1,
  uy: 0,
  vx: 0,
  vy: 1,
);

/// [rgb] with each face blurred and pulled towards grey, or under a flat
/// tone when it's small enough that a blur could still be read as a face.
Uint8List blurFaces(Uint8List rgb, List<FoundFace> faces) {
  var out = rgb;
  for (final f in faces) {
    final o = _faceOval(f);
    final mask = _Mask();
    final size = math.max(f.w, f.h);
    if (size < _small) {
      mask
        ..add((
          cx: o.cx,
          cy: o.cy,
          hw: o.hw * 1.2,
          hh: o.hh * 1.2,
          ux: o.ux,
          uy: o.uy,
          vx: o.vx,
          vy: o.vy,
        ))
        ..add(_boxOval(f, 1.2));
      out = _flatTone(out, mask, size);
    } else {
      mask
        ..add(o)
        ..add(_boxOval(f));
      out = _blurInside(out, mask, math.max(o.hw, 0.5 * f.w));
    }
  }
  return out;
}

/// [rgb] with each face painted dark grey: the fallback when the blurred
/// photo doesn't pass the safety check.
Uint8List darkenFaces(Uint8List rgb, List<FoundFace> faces) {
  var out = rgb;
  for (final f in faces) {
    final mask = _Mask()
      ..add(_faceOval(f))
      ..add(_boxOval(f));
    out = _paint(out, mask, math.max(f.w, f.h), (_) => (_dark, _dark, _dark));
  }
  return out;
}

const _lumR = 0.299;
const _lumG = 0.587;
const _lumB = 0.114;

Uint8List _blurInside(Uint8List rgb, _Mask mask, double halfWidth) {
  if (mask.isEmpty) return rgb;
  final radius = math.max(3.0, halfWidth / 2.5);
  final edge = math.max(1.0, halfWidth * 0.08);
  final (x0, y0, x1, y1) = _grown(mask, edge);
  const n = kFaceSide * kFaceSide;
  final den = _gaussian(mask.values, radius, x0, y0, x1, y1);
  final num = <Float32List>[];
  for (var c = 0; c < 3; c++) {
    final plane = Float32List(n);
    for (var i = 0; i < n; i++) {
      plane[i] = rgb[i * 3 + c] * mask.values[i];
    }
    num.add(_gaussian(plane, radius, x0, y0, x1, y1));
  }
  final soft = _gaussian(mask.values, edge, x0, y0, x1, y1);
  final out = Uint8List.fromList(rgb);
  final blurred = Float64List(3);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * kFaceSide + x;
      final s = soft[i].clamp(0.0, 1.0);
      for (var c = 0; c < 3; c++) {
        blurred[c] = den[i] > 1e-3
            ? num[c][i] / math.max(den[i], 1e-3)
            : rgb[i * 3 + c].toDouble();
      }
      final lum = blurred[0] * _lumR + blurred[1] * _lumG + blurred[2] * _lumB;
      for (var c = 0; c < 3; c++) {
        final toned = _grey * lum + (1 - _grey) * blurred[c];
        out[i * 3 + c] = _byte(rgb[i * 3 + c] * (1 - s) + toned * s);
      }
    }
  }
  return out;
}

Uint8List _flatTone(Uint8List rgb, _Mask mask, double width) {
  final mean = Float64List(3);
  var count = 0;
  for (var i = 0; i < kFaceSide * kFaceSide; i++) {
    if (mask.values[i] > 0.5) {
      count++;
      for (var c = 0; c < 3; c++) {
        mean[c] += rgb[i * 3 + c];
      }
    }
  }
  if (count == 0) {
    for (var i = 0; i < kFaceSide * kFaceSide; i++) {
      for (var c = 0; c < 3; c++) {
        mean[c] += rgb[i * 3 + c];
      }
    }
    count = kFaceSide * kFaceSide;
  }
  for (var c = 0; c < 3; c++) {
    mean[c] /= count;
  }
  final lum = mean[0] * _lumR + mean[1] * _lumG + mean[2] * _lumB;
  final tone = [
    for (var c = 0; c < 3; c++) _grey * lum + (1 - _grey) * mean[c],
  ];
  return _paint(rgb, mask, width, (_) => (tone[0], tone[1], tone[2]));
}

/// [rgb] with [colour] laid over [mask], its edge softened in proportion to
/// [width].
Uint8List _paint(
  Uint8List rgb,
  _Mask mask,
  double width,
  (double, double, double) Function(int i) colour,
) {
  if (mask.isEmpty) return rgb;
  final edge = math.max(1.0, width * 0.08);
  final (x0, y0, x1, y1) = _grown(mask, edge);
  final soft = _gaussian(mask.values, edge, x0, y0, x1, y1);
  final out = Uint8List.fromList(rgb);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * kFaceSide + x;
      final s = soft[i].clamp(0.0, 1.0);
      final (r, g, b) = colour(i);
      out[i * 3] = _byte(rgb[i * 3] * (1 - s) + r * s);
      out[i * 3 + 1] = _byte(rgb[i * 3 + 1] * (1 - s) + g * s);
      out[i * 3 + 2] = _byte(rgb[i * 3 + 2] * (1 - s) + b * s);
    }
  }
  return out;
}

int _byte(double v) => (v + 0.5).clamp(0.0, 255.0).toInt();

/// The mask's box grown by the reach of a [sigma] blur of it: outside, the
/// softened mask is 0 and the photo stays as it was.
(int, int, int, int) _grown(_Mask mask, double sigma) {
  final r = _reach(sigma);
  return (
    math.max(0, mask.x0 - r),
    math.max(0, mask.y0 - r),
    math.min(kFaceSide, mask.x1 + r),
    math.min(kFaceSide, mask.y1 + r),
  );
}

/// scipy.ndimage.gaussian_filter1d's reach: truncated at 4 sigma.
int _reach(double sigma) => (4.0 * sigma + 0.5).toInt();

int _reflect(int i, int n) {
  while (i < 0 || i >= n) {
    i = i < 0 ? -i - 1 : 2 * n - i - 1;
  }
  return i;
}

/// [plane] blurred as scipy.ndimage.gaussian_filter blurs it (truncated at
/// 4 sigma, mirrored at the photo's edges, down the columns and then along
/// the rows), worked out only in the box [x0], [y0] to [x1], [y1]; 0 outside.
Float32List _gaussian(
  Float32List plane,
  double sigma,
  int x0,
  int y0,
  int x1,
  int y1,
) {
  const side = kFaceSide;
  final r = _reach(sigma);
  final weights = Float64List(2 * r + 1);
  var sum = 0.0;
  for (var k = -r; k <= r; k++) {
    sum += weights[k + r] = math.exp(-0.5 / (sigma * sigma) * k * k);
  }
  for (var k = 0; k < weights.length; k++) {
    weights[k] /= sum;
  }
  final cx0 = math.max(0, x0 - r);
  final cx1 = math.min(side, x1 + r);
  final rows = [for (var y = y0 - r; y < y1 + r; y++) _reflect(y, side)];
  final mid = Float32List(side * side);
  for (var y = y0; y < y1; y++) {
    for (var x = cx0; x < cx1; x++) {
      var s = 0.0;
      for (var k = 0; k <= 2 * r; k++) {
        s += weights[k] * plane[rows[y - y0 + k] * side + x];
      }
      mid[y * side + x] = s;
    }
  }
  final cols = [for (var x = x0 - r; x < x1 + r; x++) _reflect(x, side)];
  final out = Float32List(side * side);
  for (var y = y0; y < y1; y++) {
    final row = y * side;
    for (var x = x0; x < x1; x++) {
      var s = 0.0;
      for (var k = 0; k <= 2 * r; k++) {
        s += weights[k] * mid[row + cols[x - x0 + k]];
      }
      out[row + x] = s;
    }
  }
  return out;
}

const _precision = 22;

/// [rgb], packed 8-bit RGB of a [side] square, scaled to [size] square
/// exactly as Pillow's `Image.resize(..., Image.BILINEAR)` does it: a
/// triangle filter as wide as the scale, in Pillow's fixed point, across
/// and then down.
Uint8List pillowBilinear(Uint8List rgb, int side, int size) {
  final (bounds, k, ksize) = _pillowCoefficients(side, size);
  final across = Uint8List(side * size * 3);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < size; x++) {
      final min = bounds[2 * x];
      final count = bounds[2 * x + 1];
      for (var c = 0; c < 3; c++) {
        var s = 1 << (_precision - 1);
        for (var j = 0; j < count; j++) {
          s += rgb[(y * side + min + j) * 3 + c] * k[x * ksize + j];
        }
        across[(y * size + x) * 3 + c] = _clip8(s);
      }
    }
  }
  final out = Uint8List(size * size * 3);
  for (var y = 0; y < size; y++) {
    final min = bounds[2 * y];
    final count = bounds[2 * y + 1];
    for (var x = 0; x < size; x++) {
      for (var c = 0; c < 3; c++) {
        var s = 1 << (_precision - 1);
        for (var j = 0; j < count; j++) {
          s += across[((min + j) * size + x) * 3 + c] * k[y * ksize + j];
        }
        out[(y * size + x) * 3 + c] = _clip8(s);
      }
    }
  }
  return out;
}

int _clip8(int s) => (s >> _precision).clamp(0, 255);

/// Pillow's precompute_coeffs and normalize_coeffs_8bpc for the bilinear
/// filter: for each output pixel, its first input pixel and how many, and
/// their weights in fixed point.
(Int32List, Int64List, int) _pillowCoefficients(int inSize, int outSize) {
  final scale = inSize / outSize;
  final filterScale = math.max(scale, 1.0);
  final support = 1.0 * filterScale;
  final ksize = support.ceil() * 2 + 1;
  final bounds = Int32List(outSize * 2);
  final k = Int64List(outSize * ksize);
  final w = Float64List(ksize);
  for (var xx = 0; xx < outSize; xx++) {
    final center = (xx + 0.5) * scale;
    final ss = 1.0 / filterScale;
    final xmin = math.max(0, (center - support + 0.5).toInt());
    final xmax = math.min(inSize, (center + support + 0.5).toInt()) - xmin;
    var ww = 0.0;
    for (var x = 0; x < xmax; x++) {
      final t = ((x + xmin - center + 0.5) * ss).abs();
      ww += w[x] = t < 1.0 ? 1.0 - t : 0.0;
    }
    for (var x = 0; x < xmax; x++) {
      final v = ww != 0.0 ? w[x] / ww : w[x];
      k[xx * ksize + x] = v < 0
          ? (-0.5 + v * (1 << _precision)).toInt()
          : (0.5 + v * (1 << _precision)).toInt();
    }
    bounds[2 * xx] = xmin;
    bounds[2 * xx + 1] = xmax;
  }
  return (bounds, k, ksize);
}
