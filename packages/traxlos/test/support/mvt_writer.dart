import 'dart:convert';
import 'dart:typed_data';

/// A contour line for [contourTile]: its stored height (feet or metres)
/// and its points in tile coordinates.
typedef Line = (num ele, List<(int, int)> points);

/// A peak for [peakTile].
typedef PeakFeature = (String name, num ele, int x, int y, String cls);

/// An MVT tile with a `contour` layer of [lines], heights in `ele_ft`
/// (or `ele_m` when not [feet]). Whole heights are stored as sint values,
/// or as int values with [plainInts] (negative ones then take ten bytes).
Uint8List contourTile(
  List<Line> lines, {
  bool feet = true,
  bool plainInts = false,
  int extent = 4096,
}) {
  final values = <List<int>>[];
  final features = <List<int>>[];
  for (final (ele, pts) in lines) {
    values.add(_number(ele, plainInts));
    final g = <int>[];
    var x = 0, y = 0;
    for (var i = 0; i < pts.length; i++) {
      if (i == 0) g.add(1 | 1 << 3);
      if (i == 1) g.add(2 | (pts.length - 1) << 3);
      g
        ..add(_zz(pts[i].$1 - x))
        ..add(_zz(pts[i].$2 - y));
      x = pts[i].$1;
      y = pts[i].$2;
    }
    features.add(_feature([0, values.length - 1], 2, g));
  }
  return _tile(
    _layer('contour', extent, [feet ? 'ele_ft' : 'ele_m'], values, features),
  );
}

/// An MVT tile with a `mountain_peak` layer of point [peaks].
Uint8List peakTile(List<PeakFeature> peaks, {int extent = 4096}) {
  final values = <List<int>>[];
  final features = <List<int>>[];
  for (final (name, ele, x, y, cls) in peaks) {
    values
      ..add(_string(name))
      ..add(_number(ele, false))
      ..add(_string(cls));
    final n = values.length;
    features.add(
      _feature([0, n - 3, 1, n - 2, 2, n - 1], 1, [1 | 1 << 3, _zz(x), _zz(y)]),
    );
  }
  return _tile(
    _layer('mountain_peak', extent, ['name', 'ele', 'class'], values, features),
  );
}

Uint8List _tile(List<int> layer) =>
    Uint8List.fromList([..._key(3, 2), ..._varint(layer.length), ...layer]);

List<int> _layer(
  String name,
  int extent,
  List<String> keys,
  List<List<int>> values,
  List<List<int>> features,
) => [
  ..._key(15, 0),
  ..._varint(2),
  ..._bytes(1, utf8.encode(name)),
  for (final f in features) ..._bytes(2, f),
  for (final k in keys) ..._bytes(3, utf8.encode(k)),
  for (final v in values) ..._bytes(4, v),
  ..._key(5, 0),
  ..._varint(extent),
];

List<int> _feature(List<int> tags, int type, List<int> geometry) => [
  ..._bytes(2, [for (final t in tags) ..._varint(t)]),
  ..._key(3, 0),
  ..._varint(type),
  ..._bytes(4, [for (final g in geometry) ..._varint(g)]),
];

List<int> _number(num v, bool plainInts) {
  if (v is int || v == v.roundToDouble()) {
    final i = v.toInt();
    return plainInts
        ? [..._key(4, 0), ..._varint(i)]
        : [..._key(6, 0), ..._varint(_zz(i))];
  }
  final b = ByteData(8)..setFloat64(0, v.toDouble(), Endian.little);
  return [..._key(3, 1), ...b.buffer.asUint8List()];
}

List<int> _string(String s) => _bytes(1, utf8.encode(s));

List<int> _bytes(int field, List<int> b) => [
  ..._key(field, 2),
  ..._varint(b.length),
  ...b,
];

List<int> _key(int field, int wire) => _varint(field << 3 | wire);

int _zz(int v) => (v << 1) ^ (v >> 63);

List<int> _varint(int v) {
  final out = <int>[];
  while (v & ~0x7f != 0) {
    out.add((v & 0x7f) | 0x80);
    v >>>= 7;
  }
  out.add(v);
  return out;
}
