import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Builds a minimal PMTiles v3 archive: a header, gzipped JSON metadata and,
/// when [tiles] are given, a root directory and the tiles' bytes (stored as
/// is). Without tiles it's enough for header and metadata reads; with them
/// a [LocalPmTilesVectorTileProvider] can serve it.
Uint8List fakePmTiles({
  Map<String, Object?> metadata = const {},
  int minZoom = 6,
  int maxZoom = 14,
  List<double> wsen = const [-122.0, 36.5, -121.7, 37.0],
  Map<(int, int, int), List<int>> tiles = const {},
}) {
  final meta = gzip.encode(utf8.encode(jsonEncode(metadata)));

  // Root directory: entries sorted by tile id, tile data laid out in order.
  final sorted = [
    for (final MapEntry(key: (z, x, y), :value) in tiles.entries)
      (vt.zxyToTileId(z, x, y), value),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final dir = <int>[];
  void varint(int v) {
    while (v >= 0x80) {
      dir.add((v & 0x7f) | 0x80);
      v >>= 7;
    }
    dir.add(v);
  }

  varint(sorted.length);
  var last = 0;
  for (final (id, _) in sorted) {
    varint(id - last);
    last = id;
  }
  for (final _ in sorted) {
    varint(1); // run length
  }
  for (final (_, bytes) in sorted) {
    varint(bytes.length);
  }
  for (var i = 0; i < sorted.length; i++) {
    varint(i == 0 ? 1 : 0); // offset + 1, then "contiguous"
  }
  final root = sorted.isEmpty ? <int>[] : gzip.encode(dir);
  final data = [for (final (_, bytes) in sorted) ...bytes];

  final header = ByteData(127);
  final magic = ascii.encode('PMTiles');
  for (var i = 0; i < magic.length; i++) {
    header.setUint8(i, magic[i]);
  }
  header.setUint8(7, 3);
  header.setUint64(8, 127, Endian.little); // root directory
  header.setUint64(16, root.length, Endian.little);
  header.setUint64(24, 127 + root.length, Endian.little); // metadata
  header.setUint64(32, meta.length, Endian.little);
  final leafAt = 127 + root.length + meta.length;
  header.setUint64(40, leafAt, Endian.little); // no leaf directories
  header.setUint64(56, leafAt, Endian.little); // tile data
  header.setUint64(64, data.length, Endian.little);
  header.setUint64(72, sorted.length, Endian.little);
  header.setUint64(80, sorted.length, Endian.little);
  header.setUint64(88, sorted.length, Endian.little);
  header.setUint8(97, 2); // internal compression: gzip
  header.setUint8(98, 2); // tile compression: gzip
  header.setUint8(99, 1); // tile type: mvt
  header.setUint8(100, minZoom);
  header.setUint8(101, maxZoom);
  int e7(double v) => (v * 1e7).round();
  header.setInt32(102, e7(wsen[0]), Endian.little);
  header.setInt32(106, e7(wsen[1]), Endian.little);
  header.setInt32(110, e7(wsen[2]), Endian.little);
  header.setInt32(114, e7(wsen[3]), Endian.little);
  header.setUint8(118, 10);
  header.setInt32(119, e7((wsen[0] + wsen[2]) / 2), Endian.little);
  header.setInt32(123, e7((wsen[1] + wsen[3]) / 2), Endian.little);
  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...root,
    ...meta,
    ...data,
  ]);
}
