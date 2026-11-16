import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:traxlos/src/pmtiles.dart' show tileId;

/// Writes a PMTiles v3 archive (directories and metadata gzipped) to
/// [path]. [tiles] maps z, x, y to the tile's bytes as stored; with
/// [gzipTiles] they are gzipped first. [leafSize] splits the directory
/// into leaves of that many entries.
void writePmtiles(
  String path,
  Map<(int, int, int), List<int>> tiles,
  Map<String, Object?> metadata, {
  bool gzipTiles = false,
  int? leafSize,
}) {
  final entries = [
    for (final MapEntry(key: (z, x, y), :value) in tiles.entries)
      (
        id: tileId(z, x, y),
        z: z,
        bytes: gzipTiles ? gzip.encode(value) : value,
      ),
  ]..sort((a, b) => a.id.compareTo(b.id));
  final data = BytesBuilder();
  final dir = <_Entry>[];
  for (final e in entries) {
    dir.add(_Entry(e.id, data.length, e.bytes.length, 1));
    data.add(e.bytes);
  }
  List<int> root;
  var leaves = <int>[];
  if (leafSize != null && dir.length > leafSize) {
    final rootEntries = <_Entry>[];
    final leafBytes = BytesBuilder();
    for (var i = 0; i < dir.length; i += leafSize) {
      final chunk = dir.sublist(i, (i + leafSize).clamp(0, dir.length));
      final b = _encode(chunk);
      rootEntries.add(_Entry(chunk.first.id, leafBytes.length, b.length, 0));
      leafBytes.add(b);
    }
    root = _encode(rootEntries);
    leaves = leafBytes.toBytes();
  } else {
    root = _encode(dir);
  }
  final meta = gzip.encode(utf8.encode(jsonEncode(metadata)));
  final rootOff = 127;
  final metaOff = rootOff + root.length;
  final leafOff = metaOff + meta.length;
  final dataOff = leafOff + leaves.length;
  final zooms = entries.map((e) => e.z);
  final h = ByteData(127);
  final magic = 'PMTiles'.codeUnits;
  for (var i = 0; i < 7; i++) {
    h.setUint8(i, magic[i]);
  }
  h.setUint8(7, 3);
  var o = 8;
  for (final v in [
    rootOff,
    root.length,
    metaOff,
    meta.length,
    leafOff,
    leaves.length,
    dataOff,
    data.length,
    dir.length,
    dir.length,
    dir.length,
  ]) {
    h.setUint64(o, v, Endian.little);
    o += 8;
  }
  h
    ..setUint8(96, 1) // clustered
    ..setUint8(97, 2) // internal compression: gzip
    ..setUint8(98, 2) // tile compression: gzip
    ..setUint8(99, 1) // MVT
    ..setUint8(100, zooms.isEmpty ? 0 : zooms.reduce((a, b) => a < b ? a : b))
    ..setUint8(101, zooms.isEmpty ? 0 : zooms.reduce((a, b) => a > b ? a : b));
  File(path).writeAsBytesSync([
    ...h.buffer.asUint8List(),
    ...root,
    ...meta,
    ...leaves,
    ...data.toBytes(),
  ]);
}

class _Entry {
  final int id, offset, length, run;

  _Entry(this.id, this.offset, this.length, this.run);
}

List<int> _encode(List<_Entry> es) {
  final b = BytesBuilder();
  void v(int x) {
    while (x >= 0x80) {
      b.addByte((x & 0x7f) | 0x80);
      x >>= 7;
    }
    b.addByte(x);
  }

  v(es.length);
  var last = 0;
  for (final e in es) {
    v(e.id - last);
    last = e.id;
  }
  for (final e in es) {
    v(e.run);
  }
  for (final e in es) {
    v(e.length);
  }
  for (var i = 0; i < es.length; i++) {
    final contiguous =
        i > 0 && es[i].offset == es[i - 1].offset + es[i - 1].length;
    v(contiguous ? 0 : es[i].offset + 1);
  }
  return gzip.encode(b.toBytes());
}
