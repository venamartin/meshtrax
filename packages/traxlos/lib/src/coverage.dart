import 'dart:math' as math;
import 'dart:typed_data';

import 'geo.dart';

/// Where contour data has been downloaded: the union of the installed
/// packs' region outlines, in world units.
///
/// A missing tile inside it means "no lines there" (flat within one
/// interval, or below the lowest line); outside it means "not downloaded".
class Coverage {
  /// Polygons, each its outer ring followed by any holes, as x, y pairs.
  final List<List<Float64List>> _polygons;

  /// Each polygon's box: minX, minY, maxX, maxY.
  final List<Float64List> _boxes;

  Coverage(Iterable<List<List<Geo>>> polygons)
    : _polygons = [
        for (final p in polygons)
          if (p.isNotEmpty && p.first.length >= 3)
            [
              for (final ring in p)
                Float64List.fromList([
                  for (final g in ring) ...[worldX(g.lon), worldY(g.lat)],
                ]),
            ],
      ],
      _boxes = [] {
    for (final p in _polygons) {
      final outer = p.first;
      var x0 = double.infinity, y0 = double.infinity;
      var x1 = -double.infinity, y1 = -double.infinity;
      for (var i = 0; i < outer.length; i += 2) {
        x0 = math.min(x0, outer[i]);
        x1 = math.max(x1, outer[i]);
        y0 = math.min(y0, outer[i + 1]);
        y1 = math.max(y1, outer[i + 1]);
      }
      _boxes.add(Float64List.fromList([x0, y0, x1, y1]));
    }
  }

  bool get isEmpty => _polygons.isEmpty;

  bool contains(double x, double y) {
    for (var p = 0; p < _polygons.length; p++) {
      final b = _boxes[p];
      if (x < b[0] || x > b[2] || y < b[1] || y > b[3]) continue;
      var inside = false;
      for (final ring in _polygons[p]) {
        if (_inRing(ring, x, y)) inside = !inside;
      }
      if (inside) return true;
    }
    return false;
  }

  /// The parts of the segment a→b inside the coverage, as t0, t1 pairs
  /// along it (0 at a, 1 at b), in order.
  List<double> coveredParts(double ax, double ay, double bx, double by) {
    final mnx = math.min(ax, bx), mxx = math.max(ax, bx);
    final mny = math.min(ay, by), mxy = math.max(ay, by);
    final ts = <double>[0, 1];
    for (var p = 0; p < _polygons.length; p++) {
      final b = _boxes[p];
      if (mxx < b[0] || mnx > b[2] || mxy < b[1] || mny > b[3]) continue;
      for (final ring in _polygons[p]) {
        final n = ring.length;
        for (var i = 0, j = n - 2; i < n; j = i, i += 2) {
          final px = ring[j], py = ring[j + 1], qx = ring[i], qy = ring[i + 1];
          if (math.max(px, qx) < mnx || math.min(px, qx) > mxx) continue;
          if (math.max(py, qy) < mny || math.min(py, qy) > mxy) continue;
          final t = _cross(ax, ay, bx, by, px, py, qx, qy);
          if (t != null) ts.add(t);
        }
      }
    }
    ts.sort();
    // Each stretch between edge crossings is wholly in or out: test its
    // middle, which never lies on an edge.
    final out = <double>[];
    for (var i = 0; i + 1 < ts.length; i++) {
      final t0 = ts[i], t1 = ts[i + 1];
      if (t1 - t0 < 1e-12) continue;
      final m = (t0 + t1) / 2;
      if (!contains(ax + (bx - ax) * m, ay + (by - ay) * m)) continue;
      if (out.isNotEmpty && out.last == t0) {
        out.last = t1;
      } else {
        out.addAll([t0, t1]);
      }
    }
    return out;
  }

  /// Even-odd test against one ring of x, y pairs.
  static bool _inRing(Float64List r, double x, double y) {
    var inside = false;
    final n = r.length;
    for (var i = 0, j = n - 2; i < n; j = i, i += 2) {
      final yi = r[i + 1], yj = r[j + 1];
      if ((yi > y) != (yj > y)) {
        final xc = r[i] + (r[j] - r[i]) * (y - yi) / (yj - yi);
        if (x < xc) inside = !inside;
      }
    }
    return inside;
  }

  /// Where a→b crosses the edge p→q, as a parameter along a→b.
  static double? _cross(
    double ax,
    double ay,
    double bx,
    double by,
    double px,
    double py,
    double qx,
    double qy,
  ) {
    final rx = bx - ax, ry = by - ay, sx = qx - px, sy = qy - py;
    final den = rx * sy - ry * sx;
    if (den == 0) return null;
    final t = ((px - ax) * sy - (py - ay) * sx) / den;
    final u = ((px - ax) * ry - (py - ay) * rx) / den;
    if (t <= 0 || t >= 1 || u < 0 || u > 1) return null;
    return t;
  }
}
