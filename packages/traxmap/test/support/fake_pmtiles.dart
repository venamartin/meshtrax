import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Builds a minimal PMTiles v3 archive: a header and gzipped JSON metadata,
/// with no directory or tiles. Enough to exercise header and metadata reads.
Uint8List fakePmTiles({
  Map<String, Object?> metadata = const {},
  int minZoom = 6,
  int maxZoom = 14,
  List<double> wsen = const [-122.0, 36.5, -121.7, 37.0],
}) {
  final meta = gzip.encode(utf8.encode(jsonEncode(metadata)));
  final header = ByteData(127);
  final magic = ascii.encode('PMTiles');
  for (var i = 0; i < magic.length; i++) {
    header.setUint8(i, magic[i]);
  }
  header.setUint8(7, 3);
  header.setUint64(24, 127, Endian.little); // metadata offset
  header.setUint64(32, meta.length, Endian.little);
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
  return Uint8List.fromList([...header.buffer.asUint8List(), ...meta]);
}
