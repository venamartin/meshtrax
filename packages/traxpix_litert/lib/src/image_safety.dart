import 'dart:typed_data';

/// Side of the square picture the safety classifier takes.
const int kImageSafetySide = 224;

/// The classifier's three scores for one picture, each 0–1, summing to 1.
class ImageSafetyScores {
  /// Gore.
  final double nsfl;

  /// Nudity, pornographic or highly suggestive.
  final double nsfw;

  /// Neither.
  final double sfw;

  const ImageSafetyScores({
    required this.nsfl,
    required this.nsfw,
    required this.sfw,
  });

  @override
  String toString() =>
      'NSFL ${nsfl.toStringAsFixed(4)}, NSFW ${nsfw.toStringAsFixed(4)}, '
      'SFW ${sfw.toStringAsFixed(4)}';
}

/// Where a picture is flagged. Each class has its own line, so an injury
/// photo's gore score never adds to its nudity score; [combined] catches a
/// picture whose probability is split between the two.
class ImageSafetyThresholds {
  final double nsfw;
  final double nsfl;
  final double combined;

  const ImageSafetyThresholds({
    required this.nsfw,
    required this.nsfl,
    required this.combined,
  });

  /// The limits chosen on 2026-11-18 (owner). Checked against 190 real trip
  /// photos, scored as the app scores them (before sending and after a
  /// rebuild): none was flagged. The highest was a close-up of a bare arm and
  /// leg in shorts, 0.443 combined before sending; nothing else passed 0.16,
  /// and no rebuild passed 0.145. Strict on purpose: recall can't be measured
  /// without unsafe pictures, which this project never handles.
  static const standard = ImageSafetyThresholds(
    nsfw: 0.30,
    nsfl: 0.30,
    combined: 0.50,
  );

  bool flags(ImageSafetyScores scores) =>
      scores.nsfw >= nsfw ||
      scores.nsfl >= nsfl ||
      scores.nsfw + scores.nsfl >= combined;
}

/// A rebuilt photo. [rgb] is null when the picture was flagged: flagged
/// pixels never leave the package.
class RebuiltImage {
  final ImageSafetyScores scores;
  final bool flagged;

  /// Packed 8-bit RGB, `512 * 512 * 3` bytes, or null when [flagged].
  final Uint8List? rgb;

  const RebuiltImage({required this.scores, required this.flagged, this.rgb});
}

/// A rebuilt photo enlarged 4x. [rgb] is null when the enlarged picture was
/// flagged: flagged pixels never leave the package.
class EnhancedImage {
  final ImageSafetyScores scores;
  final bool flagged;

  /// Packed 8-bit RGB, `2048 * 2048 * 3` bytes, or null when [flagged].
  final Uint8List? rgb;

  const EnhancedImage({required this.scores, required this.flagged, this.rgb});
}

/// A photo coded for sending. [bitstream] is null when the original was
/// flagged: a flagged photo is never encoded.
class EncodedImage {
  final ImageSafetyScores scores;
  final bool flagged;

  /// The rANS bitstream, payload only, or null when [flagged].
  final Uint8List? bitstream;

  const EncodedImage({
    required this.scores,
    required this.flagged,
    this.bitstream,
  });
}

/// Packed 8-bit RGB, `side * side * 3` bytes -> the classifier's input,
/// `[1, 3, 224, 224]` float32 in 0–255. The whole picture is scaled, never
/// cropped, so nothing at the edges escapes the check. Each output pixel is
/// the area-weighted mean of the source pixels it covers.
Float32List imageSafetyInput(Uint8List rgb, int side) {
  const out = kImageSafetySide;
  if (rgb.length != side * side * 3) {
    throw ArgumentError(
      'expected ${side * side * 3} RGB bytes, got ${rgb.length}',
    );
  }
  final spans = _areaSpans(side, out);
  final rows = Float32List(out * side * 3);
  for (var y = 0; y < out; y++) {
    for (final (src, weight) in spans[y]) {
      for (var x = 0; x < side * 3; x++) {
        rows[y * side * 3 + x] += rgb[src * side * 3 + x] * weight;
      }
    }
  }
  final chw = Float32List(3 * out * out);
  for (var y = 0; y < out; y++) {
    for (var x = 0; x < out; x++) {
      for (final (src, weight) in spans[x]) {
        final i = (y * side + src) * 3;
        for (var c = 0; c < 3; c++) {
          chw[(c * out + y) * out + x] += rows[i + c] * weight;
        }
      }
    }
  }
  return chw;
}

/// For each of [out] cells, the source indices it overlaps and the share of
/// the cell each covers.
List<List<(int, double)>> _areaSpans(int size, int out) {
  final scale = size / out;
  return [
    for (var i = 0; i < out; i++)
      [
        for (
          var s = (i * scale).floor();
          s < ((i + 1) * scale).ceil() && s < size;
          s++
        )
          (
            s,
            ((s + 1).clamp(i * scale, (i + 1) * scale) -
                    s.clamp(i * scale, (i + 1) * scale)) /
                scale,
          ),
      ],
  ];
}
