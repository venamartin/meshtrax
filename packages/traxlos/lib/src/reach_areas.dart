import 'dart:math' as math;

import 'geo.dart';

/// One part of a radio reach to draw: its outline and the rings cut out
/// of it, each closed (the first point again at the end).
class ReachArea {
  final List<Geo> outline;
  final List<List<Geo>> holes;

  const ReachArea(this.outline, this.holes);
}

/// The outlines of the stretches [parts] of each of the rays around
/// [center]: ray k covers the wedge of bearings k ± ½ of 360° / rays.
/// Neighbouring rays' stretches join, so one patch of ground is one area
/// rather than a fan of slices (which a map draws with seams between them).
///
/// Works in (ray edge, metres) space, where each stretch is a rectangle:
/// the rectangles' boundary edges, each with the area on its left, are
/// followed into rings, which become outlines (anticlockwise) or holes
/// (clockwise) on the ground.
List<ReachArea> reachAreas(Geo center, List<List<(double, double)>> parts) {
  final rays = parts.length;
  final edges = <_Edge>[];
  for (var k = 0; k < rays; k++) {
    final next = (k + 1) % rays;
    for (final (s, e) in parts[k]) {
      edges
        ..add(_Edge(k, s, next, s, _Dir.clockwise))
        ..add(_Edge(next, e, k, e, _Dir.anticlockwise));
    }
    // Ray edge k lies between ray k - 1 (left) and ray k (right).
    final left = parts[(k - 1 + rays) % rays];
    for (final (a, c) in _minus(parts[k], left)) {
      edges.add(_Edge(k, c, k, a, _Dir.inward));
    }
    for (final (a, c) in _minus(left, parts[k])) {
      edges.add(_Edge(k, a, k, c, _Dir.outward));
    }
  }

  final starting = <(int, double), List<_Edge>>{};
  for (final e in edges) {
    (starting[(e.edge0, e.m0)] ??= []).add(e);
  }

  Geo at(int edge, double m) =>
      m <= 0 ? center : destination(center, (edge - 0.5) * 360 / rays, m);

  final outlines = <(List<Geo>, double)>[];
  final holes = <(List<Geo>, double)>[];
  for (final first in edges) {
    if (first.used) continue;
    final ring = <Geo>[];
    var e = first;
    var closed = false;
    while (true) {
      e.used = true;
      final from = starting[(e.edge1, e.m1)] ?? const <_Edge>[];
      // Where two areas meet only at a corner, turning left keeps them
      // apart.
      final next = [e.dir.left, e.dir, e.dir.right]
          .expand(
            (d) => from.where(
              (x) => x.dir == d && (!x.used || identical(x, first)),
            ),
          )
          .firstOrNull;
      if (next == null) break;
      // A straight run along one ray edge needs no corner.
      if (!(next.dir == e.dir && e.dir.radial)) {
        final p = at(e.edge1, e.m1);
        if (ring.isEmpty || ring.last != p) ring.add(p);
      }
      if (identical(next, first)) {
        closed = true;
        break;
      }
      e = next;
    }
    if (!closed) continue;
    if (ring.length > 1 && ring.first == ring.last) ring.removeLast();
    if (ring.length < 3) continue;
    ring.add(ring.first);
    final area = _signedArea(ring);
    if (area == 0) continue;
    (area > 0 ? outlines : holes).add((ring, area));
  }

  final cut = [for (final _ in outlines) <List<Geo>>[]];
  for (final (hole, _) in holes) {
    final probe = _midpoint(hole[0], hole[1]);
    int? best;
    for (var i = 0; i < outlines.length; i++) {
      if (_inside(outlines[i].$1, probe) &&
          (best == null || outlines[i].$2 < outlines[best].$2)) {
        best = i;
      }
    }
    if (best != null) cut[best].add(hole);
  }
  return [
    for (var i = 0; i < outlines.length; i++) ReachArea(outlines[i].$1, cut[i]),
  ];
}

/// The parts of [a] that [b] doesn't cover; both sorted, apart.
List<(double, double)> _minus(
  List<(double, double)> a,
  List<(double, double)> b,
) {
  final out = <(double, double)>[];
  var j = 0;
  for (final (s, e) in a) {
    var from = s;
    while (j < b.length && b[j].$2 <= from) {
      j++;
    }
    var k = j;
    while (k < b.length && b[k].$1 < e) {
      if (b[k].$1 > from) out.add((from, b[k].$1));
      from = math.max(from, b[k].$2);
      k++;
    }
    if (from < e) out.add((from, e));
  }
  return out;
}

/// Each one a left turn from the one before, in (ray edge, metres) space.
enum _Dir {
  clockwise,
  outward,
  anticlockwise,
  inward;

  bool get radial => this == outward || this == inward;
  _Dir get left => _Dir.values[(index + 1) % 4];
  _Dir get right => _Dir.values[(index + 3) % 4];
}

class _Edge {
  final int edge0;
  final double m0;
  final int edge1;
  final double m1;
  final _Dir dir;
  var used = false;

  _Edge(this.edge0, this.m0, this.edge1, this.m1, this.dir);
}

/// Twice the area in a flat local projection: positive anticlockwise.
double _signedArea(List<Geo> ring) {
  final c = math.cos(ring.first.lat * math.pi / 180);
  var sum = 0.0;
  for (var i = 0; i + 1 < ring.length; i++) {
    final a = ring[i], b = ring[i + 1];
    sum += (a.lon * c) * b.lat - (b.lon * c) * a.lat;
  }
  return sum;
}

Geo _midpoint(Geo a, Geo b) => Geo((a.lat + b.lat) / 2, (a.lon + b.lon) / 2);

bool _inside(List<Geo> ring, Geo p) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.lat > p.lat) != (b.lat > p.lat) &&
        p.lon < a.lon + (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat)) {
      inside = !inside;
    }
  }
  return inside;
}
