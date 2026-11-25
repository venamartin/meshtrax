import 'dart:convert';
import 'dart:typed_data';

import 'package:traxwater/src/wrm.dart' show tileDeg, tileUnits;
import 'package:traxwater/traxwater.dart';

/// A rectangle of open water in a tile, [depth] metres deep: x from [x0] to
/// [x1] and y from [y0] to [y1], as fractions of the tile from its
/// south-west corner.
typedef Water = ({double x0, double y0, double x1, double y1, double depth});

Water water(double x0, double y0, double x1, double y1, {double depth = 50}) =>
    (x0: x0, y0: y0, x1: x1, y1: y1, depth: depth);

/// A point in tile (ix, iy), at fractions of it from its south-west corner.
LatLon at(int ix, int iy, double x, double y) =>
    (lat: (iy + y) * tileDeg - 90, lon: (ix + x) * tileDeg - 180);

/// A WRM2 tile (FINDINGS 1.11) of rectangles of [waters]. Rectangles join
/// where they share a whole side.
WaterTile waterTile(int ix, int iy, List<Water> waters) {
  const le = Endian.little;
  final vertices = <int>[], index = <(int, int), int>{};
  int vertex(double x, double y) => index.putIfAbsent(
    (
      (ix * tileUnits - 1800000000 + x * tileUnits).round(),
      (iy * tileUnits - 900000000 + y * tileUnits).round(),
    ),
    () {
      vertices.addAll([
        (ix * tileUnits - 1800000000 + x * tileUnits).round(),
        (iy * tileUnits - 900000000 + y * tileUnits).round(),
      ]);
      return vertices.length ~/ 2 - 1;
    },
  );
  final triangles = <int>[], rows = <int>[], depths = <double>[];
  for (final w in waters) {
    final a = vertex(w.x0, w.y0), b = vertex(w.x1, w.y0);
    final c = vertex(w.x1, w.y1), d = vertex(w.x0, w.y1);
    // Counter-clockwise.
    triangles.addAll([a, b, c, a, c, d]);
    if (!depths.contains(w.depth)) depths.add(w.depth);
    rows.addAll([depths.indexOf(w.depth), depths.indexOf(w.depth)]);
  }
  // Neighbour k is across the edge from vertex k to vertex k + 1.
  final neighbours = List.filled(triangles.length, -1),
      edges = <(int, int), int>{};
  for (var j = 0; j < triangles.length; j++) {
    final p = triangles[j], q = triangles[j - j % 3 + (j + 1) % 3];
    final other = edges.remove((q, p));
    if (other == null) {
      edges[(p, q)] = j;
    } else {
      neighbours[j] = other ~/ 3;
      neighbours[other] = j ~/ 3;
    }
  }
  final json = utf8.encode(
    jsonEncode({
      'areas': [],
      'sets': [[]],
      'build': {'build': '2026112401'},
    }),
  );
  final nt = triangles.length ~/ 3;
  final b = ByteData(
    42 + 4 * vertices.length + 26 * nt + 28 * depths.length + 4 + json.length,
  );
  var o = 0;
  void u8(int v) => b.setUint8(o++, v);
  void u16(int v) {
    b.setUint16(o, v, le);
    o += 2;
  }

  void i32(int v) {
    b.setInt32(o, v, le);
    o += 4;
  }

  void f32(double v) {
    b.setFloat32(o, v, le);
    o += 4;
  }

  'WRM2'.codeUnits.forEach(u8);
  u16(2);
  [ix, iy, vertices.length ~/ 2, nt, depths.length].forEach(i32);
  '2026112401'.padRight(16, '\x00').codeUnits.forEach(u8);
  vertices.forEach(i32);
  triangles.forEach(i32);
  neighbours.forEach(i32);
  rows.forEach(u16);
  for (final depth in depths) {
    // DRVAL1, flags, orientation, ring, CATZOC, the hazards within 15 and
    // 100 m, clearance, DRVAL2 and area set.
    f32(depth);
    [0, 0].forEach(u16);
    [6, 1].forEach(u8);
    [double.nan, double.nan, double.nan, double.nan].forEach(f32);
    u16(0);
  }
  i32(json.length);
  json.forEach(u8);
  return WaterTile.parse(b.buffer.asUint8List());
}
