import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'geo.dart';

/// Compression codes used in a PMTiles v3 header.
enum PmCompression { unknown, none, gzip, brotli, zstd }

/// Tile payload types used in a PMTiles v3 header.
enum PmTileType { unknown, mvt, png, jpeg, webp, avif }

/// The fixed 127-byte header at the start of every PMTiles v3 archive.
///
/// See https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md
class PmTilesHeader {
  static const int length = 127;

  final int specVersion;
  final int rootDirectoryOffset;
  final int rootDirectoryLength;
  final int metadataOffset;
  final int metadataLength;
  final int leafDirectoriesOffset;
  final int leafDirectoriesLength;
  final int tileDataOffset;
  final int tileDataLength;
  final int addressedTiles;
  final int tileEntries;
  final int tileContents;
  final bool clustered;
  final PmCompression internalCompression;
  final PmCompression tileCompression;
  final PmTileType tileType;
  final int minZoom;
  final int maxZoom;
  final LatLngBounds bounds;
  final int centerZoom;
  final LatLng center;

  const PmTilesHeader({
    required this.specVersion,
    required this.rootDirectoryOffset,
    required this.rootDirectoryLength,
    required this.metadataOffset,
    required this.metadataLength,
    required this.leafDirectoriesOffset,
    required this.leafDirectoriesLength,
    required this.tileDataOffset,
    required this.tileDataLength,
    required this.addressedTiles,
    required this.tileEntries,
    required this.tileContents,
    required this.clustered,
    required this.internalCompression,
    required this.tileCompression,
    required this.tileType,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    required this.centerZoom,
    required this.center,
  });

  /// Parses a header from the first [length] bytes of an archive.
  factory PmTilesHeader.parse(Uint8List bytes) {
    if (bytes.length < length) {
      throw const FormatException('PMTiles header is shorter than 127 bytes');
    }
    if (ascii.decode(bytes.sublist(0, 7), allowInvalid: true) != 'PMTiles') {
      throw const FormatException('Not a PMTiles archive (bad magic)');
    }
    final version = bytes[7];
    if (version != 3) {
      throw FormatException('Unsupported PMTiles version $version');
    }
    final d = ByteData.sublistView(bytes);
    int u64(int o) => d.getUint64(o, Endian.little);
    double e7(int o) => d.getInt32(o, Endian.little) / 1e7;
    T pick<T extends Enum>(List<T> values, int code) =>
        code < values.length ? values[code] : values.first;

    return PmTilesHeader(
      specVersion: version,
      rootDirectoryOffset: u64(8),
      rootDirectoryLength: u64(16),
      metadataOffset: u64(24),
      metadataLength: u64(32),
      leafDirectoriesOffset: u64(40),
      leafDirectoriesLength: u64(48),
      tileDataOffset: u64(56),
      tileDataLength: u64(64),
      addressedTiles: u64(72),
      tileEntries: u64(80),
      tileContents: u64(88),
      clustered: bytes[96] == 1,
      internalCompression: pick(PmCompression.values, bytes[97]),
      tileCompression: pick(PmCompression.values, bytes[98]),
      tileType: pick(PmTileType.values, bytes[99]),
      minZoom: bytes[100],
      maxZoom: bytes[101],
      bounds: LatLngBounds(
        south: e7(106),
        west: e7(102),
        north: e7(114),
        east: e7(110),
      ),
      centerZoom: bytes[118],
      center: LatLng(e7(123), e7(119)),
    );
  }

  /// Reads and parses the header of the archive at [file].
  static Future<PmTilesHeader> read(File file) async {
    final raf = await file.open();
    try {
      return PmTilesHeader.parse(await raf.read(length));
    } finally {
      await raf.close();
    }
  }

  /// Reads the archive's JSON metadata (name, attribution, `vector_layers`).
  ///
  /// Returns null if the archive has no metadata or uses a compression
  /// that dart:io cannot decode (brotli, zstd).
  Future<Map<String, Object?>?> readMetadata(File file) async {
    if (metadataLength == 0) return null;
    final raf = await file.open();
    try {
      await raf.setPosition(metadataOffset);
      final raw = await raf.read(metadataLength);
      final List<int> json;
      switch (internalCompression) {
        case PmCompression.none:
          json = raw;
        case PmCompression.gzip:
          json = gzip.decode(raw);
        default:
          return null;
      }
      final decoded = jsonDecode(utf8.decode(json));
      return decoded is Map<String, Object?> ? decoded : null;
    } finally {
      await raf.close();
    }
  }
}
