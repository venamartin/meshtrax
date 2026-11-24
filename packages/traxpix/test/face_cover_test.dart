import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxpix/src/face_cover.dart';

Uint8List small(int n) => Uint8List.fromList([
  for (var y = 0; y < n; y++)
    for (var x = 0; x < n; x++)
      for (var c = 0; c < 3; c++) (x * 31 + y * 17 + c * 7) % 256,
]);

Uint8List pattern() => Uint8List.fromList([
  for (var y = 0; y < kFaceSide; y++)
    for (var x = 0; x < kFaceSide; x++) ...[
      (x * 3 + y * 5) % 256,
      (x * 7) % 256,
      (y * 2 + 40) % 256,
    ],
]);

FoundFace face(double s, List<double> box, List<double> points) =>
    FoundFace(s, box[0], box[1], box[2], box[3], points);

// A big face, a small one (flat tone) and one whose points can't be a face
// (an oval inside its box).
final faces = [
  face(
    0.9,
    [200, 150, 120, 140],
    [230, 200, 290, 200, 260, 230, 260, 260, 205, 210, 315, 210],
  ),
  face(
    0.8,
    [60, 400, 24, 26],
    [66, 408, 78, 408, 72, 414, 72, 419, 61, 410, 83, 410],
  ),
  face(
    0.7,
    [400, 60, 60, 70],
    [
      for (var i = 0; i < 6; i++) ...[430, 90],
    ],
  ),
];

List<int> at(Uint8List rgb, int y, int x) => [
  for (var c = 0; c < 3; c++) rgb[(y * kFaceSide + x) * 3 + c],
];

/// What scipy and Pillow gave for the same picture and faces with the tests'
/// own Python (blur_face.py, auto_blur2.py, cover_variants.py).
void matchesPython(
  Uint8List out,
  Uint8List before, {
  required int sum,
  required int changed,
  required List<List<int>> samples,
}) {
  var total = 0;
  var diff = 0;
  for (var i = 0; i < out.length; i++) {
    total += out[i];
    if (out[i] != before[i]) diff++;
  }
  expect(total, closeTo(sum, sum * 1e-5));
  expect(diff, closeTo(changed, changed * 1e-3));
  const points = [(220, 260), (170, 210), (413, 72), (95, 430), (300, 300)];
  for (var i = 0; i < points.length; i++) {
    final (y, x) = points[i];
    final got = at(out, y, x);
    for (var c = 0; c < 3; c++) {
      expect(got[c], closeTo(samples[i][c], 1), reason: 'pixel $y, $x');
    }
  }
  expect(at(out, 0, 0), [0, 0, 40], reason: 'far from every face');
}

void main() {
  group('pillowBilinear', () {
    test('matches Pillow byte for byte', () {
      expect(pillowBilinear(small(9), 9, 4), [
        40, 47, 54, 102, 109, 116, 174, 177, 184, 176, 162, 133, //
        75, 82, 89, 137, 144, 151, 194, 181, 188, 102, 69, 76, //
        113, 120, 127, 173, 180, 183, 140, 132, 135, 66, 62, 69, //
        148, 155, 162, 183, 190, 173, 67, 74, 57, 88, 95, 102,
      ]);
      expect(pillowBilinear(small(12), 12, 5), [
        45, 52, 59, 112, 119, 126, 186, 184, 191, 124, 117, 90, 74, 81, 86, //
        82, 89, 96, 149, 156, 163, 186, 162, 169, 79, 67, 74, 109, 116, 123,
        123, 130, 137, 179, 186, 182, 107, 100, 100, 86, 90, 97, 150, 157, 164,
        163, 170, 176, 160, 167, 136, 63, 70, 67, 123, 130, 137, 190, 193, 200,
        196, 184, 189, 105, 93, 78, 86, 93, 100, 160, 167, 174, 198, 168, 175,
      ]);
    });
  });

  group('covers', () {
    final before = pattern();

    test('blur, and a flat tone for a small face, as Python made them', () {
      matchesPython(
        blurFaces(before, faces),
        before,
        sum: 100156710,
        changed: 93232,
        samples: [
          [129, 129, 133],
          [188, 179, 126],
          [132, 132, 127],
          [142, 142, 150],
          [109, 88, 122],
        ],
      );
    });

    test('the dark fallback, as Python made it', () {
      matchesPython(
        darkenFaces(before, faces),
        before,
        sum: 94579452,
        changed: 123210,
        samples: [
          [45, 45, 45],
          [153, 146, 100],
          [45, 45, 45],
          [45, 45, 45],
          [71, 49, 88],
        ],
      );
    });

    test('no faces, no change', () {
      expect(blurFaces(before, const []), same(before));
      expect(darkenFaces(before, const []), same(before));
    });
  });

  group('findFaces', () {
    // The short-range model's first anchor sits at 1/32 of the picture.
    const anchor = 0.5 / 16;
    double px(double v) => (v - anchor) * 128;

    FaceModelOutput output(int anchors, {bool withFace = false}) {
      final logits = Float32List(anchors)..fillRange(0, anchors, -50);
      final regressors = Float32List(anchors * 16);
      if (withFace) {
        logits[0] = 10;
        regressors.setAll(0, [
          px(0.5), px(0.5), 32, 32, // a box at the middle, a quarter wide
          px(0.45), px(0.47), px(0.55), px(0.47), // eyes
          px(0.5), px(0.5), px(0.5), px(0.56), // nose, mouth
          px(0.4), px(0.48), px(0.6), px(0.48), // ears
        ]);
      }
      return (regressors: regressors, logits: logits);
    }

    test('finds nothing when the models score nothing', () {
      expect(
        findFaces(
          pattern(),
          (input, {required fullRange}) => output(fullRange ? 2304 : 896),
        ),
        isEmpty,
      );
    });

    test('decodes a face to the photo\'s pixels', () {
      final found = findFaces(pattern(), (input, {required fullRange}) {
        expect(input.length, fullRange ? 192 * 192 * 3 : 128 * 128 * 3);
        expect(input.every((v) => v >= -1 && v <= 1), isTrue);
        return fullRange ? output(2304) : output(896, withFace: true);
      });
      expect(found, hasLength(1));
      final f = found.single;
      expect(f.score, closeTo(1 / (1 + math.exp(-10)), 1e-9));
      for (final (got, want) in [
        (f.x, 192.0),
        (f.y, 192.0),
        (f.w, 128.0),
        (f.h, 128.0),
        (f.points[0], 0.45 * 512),
        (f.points[7], 0.56 * 512),
      ]) {
        expect(got, closeTo(want, 1e-3));
      }
    });

    test('drops points that can\'t be a face: the mouth above the eyes', () {
      final found = findFaces(pattern(), (input, {required fullRange}) {
        if (fullRange) return output(2304);
        final o = output(896, withFace: true);
        o.regressors[11] = px(0.40); // mouth up above the eyes
        return o;
      });
      expect(found, isEmpty);
    });

    test('refuses a photo of the wrong size', () {
      expect(
        () => findFaces(Uint8List(10), (i, {required fullRange}) => output(1)),
        throwsArgumentError,
      );
    });
  });
}
