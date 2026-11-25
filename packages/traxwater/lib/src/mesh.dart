import 'dart:math' as math;
import 'dart:typed_data';

import 'trip.dart';
import 'wrm.dart';

/// Metres per degree at the middle latitude, as the builder's test router
/// has it.
const _metresPerDeg = 111320.0;
const _unit = 1e-7;

/// The Mercator latitude of [lat], in degrees.
double _psi(double lat) =>
    math.log(math.tan(math.pi / 4 + lat * math.pi / 360)) * 180 / math.pi;

/// A trip's tiles joined into one mesh, in a Mercator projection true to
/// scale in the middle of them: x = (lon − lon0) × k and y = (ψ(lat) −
/// ψ(lat0)) × k, with ψ the Mercator latitude in degrees and k = cos(lat0) ×
/// 111,320 m. A straight line in it is a rhumb line, as a chart draws a leg.
class WaterMesh {
  WaterMesh._(
    this.tileCount,
    this.buildInfo,
    this._lon0,
    this._psi0,
    this._kx,
    this.xy,
    this.tri,
    this.nbr,
    this.linkStart,
    this.linkTo,
    this.linkXY,
    this.centroid,
    this.row,
    this.depth,
    this.depthTo,
    this.flags,
    this.ring,
    this.zoc,
    this.hazardInner,
    this.hazardOuter,
    this.rowSet,
    this.sets,
    this.frontierTri,
    this.frontierTile,
    Float64List box,
  ) : _index = _Index(box, row.length);

  /// Joins [tiles], each once, into one mesh.
  ///
  /// Tiles join along the stretches their border edges share, and across
  /// the 180° meridian tile 1439's east edge meets tile 0's west edge:
  /// longitudes run on from the first tile's, past 180 where the tiles
  /// cross it. Throws a [WaterRoutingException] for tiles of two builds.
  factory WaterMesh.load(List<WaterTile> tiles) {
    if ({for (final t in tiles) t.build}.length > 1) {
      throw const WaterRoutingException(WaterRoutingProblem.mixedBuilds);
    }
    final first = tiles.isEmpty ? 0 : tiles.first.ix;
    final cols = [
      for (final t in tiles)
        t.ix + tileColumns * ((first - t.ix) / tileColumns).round(),
    ];
    double middle(List<int> cells, double offset) => cells.isEmpty
        ? 0
        : (cells.reduce(math.min) + cells.reduce(math.max) + 1) / 2 * tileDeg -
              offset;
    final lon0 = middle(cols, 180);
    final lat0 = middle([for (final t in tiles) t.iy], 90);
    final kx = math.cos(lat0 * math.pi / 180) * _metresPerDeg;
    final psi0 = _psi(lat0);
    var nv = 0, nt = 0, na = 0;
    for (final t in tiles) {
      nv += t.vertices.length ~/ 2;
      nt += t.triangleCount;
      na += t.depth.length;
    }
    final xy = Float64List(2 * nv);
    final tri = Int32List(3 * nt), nbr = Int32List(3 * nt), row = Int32List(nt);
    final depth = Float32List(na), depthTo = Float32List(na);
    final hazardInner = Float32List(na), hazardOuter = Float32List(na);
    final flags = Uint16List(na), ring = Uint8List(na), zoc = Uint8List(na);
    final rowSet = Int32List(na);
    final byId = <String, WaterArea>{};
    final setOf = <String, int>{};
    final sets = <List<WaterArea>>[];
    final tileBase = <int>[];
    var vo = 0, to = 0, ro = 0;
    for (var i = 0; i < tiles.length; i++) {
      final t = tiles[i], shift = (cols[i] - t.ix) * tileUnits;
      tileBase.add(to);
      final v = t.vertices;
      for (var j = 0; j < v.length; j += 2) {
        xy[2 * vo + j] = ((v[j] + shift) * _unit - lon0) * kx;
        xy[2 * vo + j + 1] = (_psi(v[j + 1] * _unit) - psi0) * kx;
      }
      for (var j = 0; j < t.triangles.length; j++) {
        tri[3 * to + j] = t.triangles[j] + vo;
        final b = t.neighbours[j];
        nbr[3 * to + j] = b < 0 ? -1 : b + to;
      }
      for (var j = 0; j < t.triangleCount; j++) {
        row[to + j] = t.rows[j] + ro;
      }
      final global = [
        for (final st in t.sets)
          setOf.putIfAbsent(
            ([for (final a in st) t.areas[a].id]..sort()).join(','),
            () {
              sets.add([
                for (final a in st)
                  byId.putIfAbsent(t.areas[a].id, () => t.areas[a]),
              ]);
              return sets.length - 1;
            },
          ),
      ];
      for (var j = 0; j < t.depth.length; j++) {
        depth[ro + j] = t.depth[j];
        depthTo[ro + j] = t.depthTo[j];
        flags[ro + j] = t.flags[j];
        ring[ro + j] = t.ring[j];
        zoc[ro + j] = t.zoc[j];
        hazardInner[ro + j] = t.hazardInner[j];
        hazardOuter[ro + j] = t.hazardOuter[j];
        rowSet[ro + j] = global[t.areaSet[j]];
      }
      vo += v.length ~/ 2;
      to += t.triangleCount;
      ro += t.depth.length;
    }

    final centroid = Float64List(2 * nt), box = Float64List(4 * nt);
    for (var t = 0; t < nt; t++) {
      final a = 2 * tri[3 * t], b = 2 * tri[3 * t + 1], c = 2 * tri[3 * t + 2];
      centroid[2 * t] = (xy[a] + xy[b] + xy[c]) / 3;
      centroid[2 * t + 1] = (xy[a + 1] + xy[b + 1] + xy[c + 1]) / 3;
      box[4 * t] = math.min(xy[a], math.min(xy[b], xy[c]));
      box[4 * t + 1] = math.min(xy[a + 1], math.min(xy[b + 1], xy[c + 1]));
      box[4 * t + 2] = math.max(xy[a], math.max(xy[b], xy[c]));
      box[4 * t + 3] = math.max(xy[a + 1], math.max(xy[b + 1], xy[c + 1]));
    }

    // Border edges by tile side (0 west, 1 east, 2 south, 3 north): lo, hi
    // along the border in units, and the triangle.
    final sides = <int, List<int>>{};
    int sideKey(int col, int iy, int side) =>
        ((col + 2 * tileColumns) * tileRows + iy) * 4 + side;
    for (var i = 0; i < tiles.length; i++) {
      final t = tiles[i], col = cols[i], shift = (col - t.ix) * tileUnits;
      final x0 = col * tileUnits - 1800000000, x1 = x0 + tileUnits;
      final y0 = t.iy * tileUnits - 900000000, y1 = y0 + tileUnits;
      final v = t.vertices;
      void add(int side, int p, int q, int triangle) =>
          (sides[sideKey(col, t.iy, side)] ??= []).addAll([
            math.min(p, q),
            math.max(p, q),
            triangle,
          ]);
      for (var j = 0; j < t.triangles.length; j++) {
        if (t.neighbours[j] >= 0) continue;
        final a = 2 * t.triangles[j];
        final b = 2 * t.triangles[j - j % 3 + (j + 1) % 3];
        final ax = v[a] + shift, ay = v[a + 1];
        final bx = v[b] + shift, by = v[b + 1];
        final g = tileBase[i] + j ~/ 3;
        if (ax == bx && ax == x0) add(0, ay, by, g);
        if (ax == bx && ax == x1) add(1, ay, by, g);
        if (ay == by && ay == y0) add(2, ax, bx, g);
        if (ay == by && ay == y1) add(3, ax, bx, g);
      }
    }
    // Where the water runs on into a tile that isn't loaded.
    final loaded = {
      for (var i = 0; i < tiles.length; i++) sideKey(cols[i], tiles[i].iy, 0),
    };
    final frontierTri = <int>[], frontierTile = <int>[];
    for (var i = 0; i < tiles.length; i++) {
      final col = cols[i], iy = tiles[i].iy;
      for (final (side, dc, dr) in [
        (0, -1, 0),
        (1, 1, 0),
        (2, 0, -1),
        (3, 0, 1),
      ]) {
        final segs = sides[sideKey(col, iy, side)], r = iy + dr;
        if (segs == null ||
            r < 0 ||
            r >= tileRows ||
            loaded.contains(sideKey(col + dc, r, 0))) {
          continue;
        }
        for (var j = 0; j < segs.length; j += 3) {
          frontierTri.add(segs[j + 2]);
          frontierTile.add(r * tileColumns + (col + dc) % tileColumns);
        }
      }
    }

    final from = <int>[], toTri = <int>[], pts = <double>[];
    for (var i = 0; i < tiles.length; i++) {
      final col = cols[i], iy = tiles[i].iy;
      for (final (side, other, vertical) in [
        (1, sideKey(col + 1, iy, 0), true),
        (3, sideKey(col, iy + 1, 2), false),
      ]) {
        final segs = sides[sideKey(col, iy, side)], others = sides[other];
        if (segs == null || others == null) continue;
        final line = vertical
            ? (col + 1) * tileUnits - 1800000000
            : (iy + 1) * tileUnits - 900000000;
        final order = List.generate(others.length ~/ 3, (j) => 3 * j)
          ..sort((p, q) {
            for (var d = 0; d < 3; d++) {
              final c = others[p + d].compareTo(others[q + d]);
              if (c != 0) return c;
            }
            return 0;
          });
        for (var j = 0; j < segs.length; j += 3) {
          final lo = segs[j], hi = segs[j + 1], g = segs[j + 2];
          for (final o in order) {
            if (others[o] >= hi) break;
            final a = math.max(lo, others[o]), b = math.min(hi, others[o + 1]);
            if (b <= a) continue;
            final ends = [
              for (final p in [a, b])
                ...vertical
                    ? [
                        (line * _unit - lon0) * kx,
                        (_psi(p * _unit) - psi0) * kx,
                      ]
                    : [
                        (p * _unit - lon0) * kx,
                        (_psi(line * _unit) - psi0) * kx,
                      ],
            ];
            from.addAll([g, others[o + 2]]);
            toTri.addAll([others[o + 2], g]);
            pts.addAll([...ends, ...ends]);
          }
        }
      }
    }
    final linkStart = Int32List(nt + 1);
    for (final f in from) {
      linkStart[f + 1]++;
    }
    for (var t = 0; t < nt; t++) {
      linkStart[t + 1] += linkStart[t];
    }
    final fill = Int32List.fromList(linkStart.sublist(0, nt));
    final linkTo = Int32List(from.length),
        linkXY = Float64List(4 * from.length);
    for (var j = 0; j < from.length; j++) {
      final at = fill[from[j]]++;
      linkTo[at] = toTri[j];
      linkXY.setRange(4 * at, 4 * at + 4, pts, 4 * j);
    }

    return WaterMesh._(
      tiles.length,
      tiles.isEmpty ? null : tiles.first.buildInfo,
      lon0,
      psi0,
      kx,
      xy,
      tri,
      nbr,
      linkStart,
      linkTo,
      linkXY,
      centroid,
      row,
      depth,
      depthTo,
      flags,
      ring,
      zoc,
      hazardInner,
      hazardOuter,
      rowSet,
      sets,
      Int32List.fromList(frontierTri),
      Int32List.fromList(frontierTile),
      box,
    );
  }

  final int tileCount;

  /// The build the tiles are from (their areas JSON's `build` object).
  final Map<String, Object?>? buildInfo;
  final double _lon0, _psi0, _kx;

  /// Vertices: x, y in metres.
  final Float64List xy;

  /// Three vertex indices per triangle, counter-clockwise.
  final Int32List tri;

  /// Three per triangle: the triangle across edge k (vertex k to k + 1), or
  /// −1.
  final Int32List nbr;

  /// Triangle t's links across tile edges are linkStart[t] ..<
  /// linkStart[t + 1], each to [linkTo] across the stretch in [linkXY]
  /// (ax, ay, bx, by).
  final Int32List linkStart;
  final Int32List linkTo;
  final Float64List linkXY;

  /// x, y per triangle.
  final Float64List centroid;

  /// Each triangle's attribute row; the rows of every tile follow.
  final Int32List row;
  final Float32List depth, depthTo;
  final Uint16List flags;
  final Uint8List ring;
  final Uint8List zoc;
  final Float32List hazardInner;
  final Float32List hazardOuter;

  /// Each row's area set, in [sets].
  final Int32List rowSet;

  /// The area sets of every tile, joined by area id.
  final List<List<WaterArea>> sets;

  /// Where the water runs on into a tile that isn't in the mesh: the
  /// triangle at the edge, and that tile (iy × 1440 + ix).
  final Int32List frontierTri, frontierTile;

  final _Index _index;

  int get triangleCount => row.length;

  /// Into the projection, taking the longitude nearest the middle (past 180
  /// across the meridian).
  (double, double) toXY(double lat, double lon) {
    final d = lon - _lon0;
    return (
      (d - 360 * (d / 360).roundToDouble()) * _kx,
      (_psi(lat) - _psi0) * _kx,
    );
  }

  /// Back to degrees, with the longitude between −180 and 180.
  ({double lat, double lon}) toLatLon(double x, double y) {
    final psi = (y / _kx + _psi0) * math.pi / 180;
    return (
      lat: math.atan((math.exp(psi) - math.exp(-psi)) / 2) * 180 / math.pi,
      lon: (x / _kx + _lon0 + 180) % 360 - 180,
    );
  }

  /// The stretch a step from triangle [t] crosses: [via] 0 to 2 is t's edge
  /// from vertex via to via + 1, 3 and up a link across a tile edge.
  (double, double, double, double) portal(int t, int via) {
    if (via >= 3) {
      final j = 4 * (via - 3);
      return (linkXY[j], linkXY[j + 1], linkXY[j + 2], linkXY[j + 3]);
    }
    final a = 2 * tri[3 * t + via], b = 2 * tri[3 * t + (via + 1) % 3];
    return (xy[a], xy[a + 1], xy[b], xy[b + 1]);
  }

  /// The triangle holding a point, the first by index where two do, or −1.
  int locate(double x, double y) {
    var found = -1;
    _index.visit(x, y, x, y, 0, (t) {
      if ((found < 0 || t < found) && _holds(t, x, y, 0)) found = t;
      return false;
    });
    return found;
  }

  /// Whether a triangle [usable] takes holds the point, or comes within
  /// [eps] of it.
  bool inWater(double x, double y, double eps, bool Function(int t) usable) {
    var found = false;
    _index.visit(
      x,
      y,
      x,
      y,
      eps,
      (t) => found = usable(t) && _holds(t, x, y, eps),
    );
    return found;
  }

  bool _holds(int t, double x, double y, double eps) {
    for (var k = 0; k < 3; k++) {
      final a = 2 * tri[3 * t + k], b = 2 * tri[3 * t + (k + 1) % 3];
      final ex = xy[b] - xy[a], ey = xy[b + 1] - xy[a + 1];
      final d = ex * (y - xy[a + 1]) - ey * (x - xy[a]);
      if (d < 0 && d + eps * math.sqrt(ex * ex + ey * ey) < 0) return false;
    }
    return true;
  }

  /// Calls [found] with every triangle whose box comes within [eps] of the
  /// line from (px, py) to (qx, qy).
  void nearLine(
    double px,
    double py,
    double qx,
    double qy,
    double eps,
    void Function(int t) found,
  ) => _index.visit(px, py, qx, qy, eps, (t) {
    found(t);
    return false;
  });
}

/// A static R-tree over the triangles' boxes, packed in the Hilbert order
/// of their centres.
class _Index {
  factory _Index(Float64List itemBox, int n) {
    final levels = <(Float64List, Int32List, Int32List)>[];
    if (n == 0) return _Index._(levels, Int32List(0), itemBox);
    final order = _hilbertOrder(itemBox, n);
    var (box, count) = (itemBox, n);
    var members = order;
    while (levels.isEmpty || count > 1) {
      final up = (count / _fan).ceil();
      final upBox = Float64List(4 * up), lo = Int32List(up), hi = Int32List(up);
      for (var j = 0; j < up; j++) {
        lo[j] = j * _fan;
        hi[j] = math.min(count, lo[j] + _fan);
        var x0 = double.infinity, y0 = double.infinity;
        var x1 = double.negativeInfinity, y1 = double.negativeInfinity;
        for (var i = lo[j]; i < hi[j]; i++) {
          final c = 4 * members[i];
          x0 = math.min(x0, box[c]);
          y0 = math.min(y0, box[c + 1]);
          x1 = math.max(x1, box[c + 2]);
          y1 = math.max(y1, box[c + 3]);
        }
        upBox
          ..[4 * j] = x0
          ..[4 * j + 1] = y0
          ..[4 * j + 2] = x1
          ..[4 * j + 3] = y1;
      }
      levels.add((upBox, lo, hi));
      (box, count) = (upBox, up);
      members = Int32List.fromList(List.generate(up, (i) => i));
    }
    return _Index._(levels, order, itemBox);
  }

  _Index._(this._levels, this._order, this._itemBox);

  static const _fan = 16;

  /// Bottom first: each level's node boxes, and each node's children (the
  /// level below, or [_order] for the bottom) as lo ..< hi.
  final List<(Float64List, Int32List, Int32List)> _levels;
  final Int32List _order;
  final Float64List _itemBox;

  /// The items by the Hilbert index of their boxes' centres on a 65,536
  /// grid over them all (a radix sort).
  static Int32List _hilbertOrder(Float64List box, int n) {
    var x0 = double.infinity, y0 = double.infinity;
    var x1 = double.negativeInfinity, y1 = double.negativeInfinity;
    for (var i = 0; i < n; i++) {
      final cx = box[4 * i] + box[4 * i + 2],
          cy = box[4 * i + 1] + box[4 * i + 3];
      x0 = math.min(x0, cx);
      y0 = math.min(y0, cy);
      x1 = math.max(x1, cx);
      y1 = math.max(y1, cy);
    }
    final sx = 65535 / math.max(x1 - x0, 1e-9),
        sy = 65535 / math.max(y1 - y0, 1e-9);
    final keys = Uint32List(n);
    for (var i = 0; i < n; i++) {
      var x = ((box[4 * i] + box[4 * i + 2] - x0) * sx).floor();
      var y = ((box[4 * i + 1] + box[4 * i + 3] - y0) * sy).floor();
      var d = 0;
      for (var s = 1 << 15; s > 0; s >>= 1) {
        final rx = x & s != 0 ? 1 : 0, ry = y & s != 0 ? 1 : 0;
        d += s * s * ((3 * rx) ^ ry);
        if (ry == 0) {
          if (rx == 1) (x, y) = (65535 - x, 65535 - y);
          (x, y) = (y, x);
        }
      }
      keys[i] = d;
    }
    var ids = Int32List.fromList(List.generate(n, (i) => i)),
        spare = Int32List(n);
    for (final shift in [0, 16]) {
      final at = Int32List(65537);
      for (final i in ids) {
        at[((keys[i] >> shift) & 0xffff) + 1]++;
      }
      for (var b = 0; b < 65536; b++) {
        at[b + 1] += at[b];
      }
      for (final i in ids) {
        spare[at[(keys[i] >> shift) & 0xffff]++] = i;
      }
      (ids, spare) = (spare, ids);
    }
    return ids;
  }

  /// Whether the line from (px, py) by (dx, dy) comes within [eps] of box
  /// [j] of [box].
  static bool _meets(
    Float64List box,
    int j,
    double px,
    double py,
    double dx,
    double dy,
    double eps,
  ) {
    var t0 = 0.0, t1 = 1.0;
    for (var axis = 0; axis < 2; axis++) {
      final p = axis == 0 ? px : py, d = axis == 0 ? dx : dy;
      final lo = box[4 * j + axis] - eps, hi = box[4 * j + 2 + axis] + eps;
      if (d == 0) {
        if (p < lo || p > hi) return false;
        continue;
      }
      var a = (lo - p) / d, b = (hi - p) / d;
      if (a > b) (a, b) = (b, a);
      t0 = math.max(t0, a);
      t1 = math.min(t1, b);
      if (t0 > t1) return false;
    }
    return true;
  }

  void visit(
    double px,
    double py,
    double qx,
    double qy,
    double eps,
    bool Function(int t) found,
  ) {
    if (_levels.isEmpty) return;
    final dx = qx - px, dy = qy - py;
    final stack = <int>[_levels.length - 1, 0];
    while (stack.isNotEmpty) {
      final j = stack.removeLast(), level = stack.removeLast();
      final (box, lo, hi) = _levels[level];
      if (!_meets(box, j, px, py, dx, dy, eps)) continue;
      if (level == 0) {
        for (var i = lo[j]; i < hi[j]; i++) {
          final t = _order[i];
          if (_meets(_itemBox, t, px, py, dx, dy, eps) && found(t)) return;
        }
      } else {
        for (var c = lo[j]; c < hi[j]; c++) {
          stack.addAll([level - 1, c]);
        }
      }
    }
  }
}
