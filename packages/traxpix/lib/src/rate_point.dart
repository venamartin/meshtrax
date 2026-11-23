// Adapted from meshcore-open lib/widgets/image_send_codec_binding.dart (MIT,
// see the repository's LICENSE), commit 3944c4f.

/// The photo quality named by the low bits of the chunk-0 metadata byte.
///
/// MeshTrax sends one quality, AEIC-SE `ft8`: people, animals and small
/// objects come through, in three to six packets with the repair packet.
enum ImageCodecRatePoint {
  /// AEIC-SE `ft8`. See [ImageCodecRateStats.ft8] for its sizes.
  ft8,
}

/// Bitstream sizes for a quality, in bytes, so a sender can show a likely
/// range before the encode finishes.
class ImageCodecRateStats {
  final int meanBytes;
  final int minBytes;
  final int maxBytes;

  const ImageCodecRateStats({
    required this.meanBytes,
    required this.minBytes,
    required this.maxBytes,
  });

  /// Real coded sizes (2026-11-18): 190 real trip photos
  /// (208–740 bytes, mean 402, median 388; 3–6 packets with the repair packet)
  /// plus 12 close-up crops (383–796). Busy scenes cost the most: a crowd of
  /// kettles took 796 bytes.
  static const ImageCodecRateStats ft8 = ImageCodecRateStats(
    meanBytes: 410,
    minBytes: 208,
    maxBytes: 796,
  );
}
