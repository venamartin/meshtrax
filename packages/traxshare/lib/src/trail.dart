import 'dart:math';
import 'dart:typed_data';

/// A point on a trail, in degrees.
typedef TrailPoint = ({double lat, double lon});

/// The trail a report carries: points newest first, without the report's
/// own position, on a grid of [gridM] metres.
typedef Trail = ({int gridM, List<TrailPoint> points});

const _metresPerDegree = 111320.0;

/// A report's position as the wire carries it, in 0.00001° steps. A trail
/// is measured from it, so both ends start from the same point.
TrailPoint wirePosition(double lat, double lon) =>
    (lat: latUnits(lat) / 100000 - 90, lon: lonUnits(lon) / 100000 - 180);

int latUnits(double lat) => ((lat.clamp(-90.0, 90.0) + 90) * 100000).round();

int lonUnits(double lon) => ((lon + 180) * 100000).round() % 36000000;

/// The trail's bits, MSB first: for each point, newest first, its step east
/// then north from the point before it (the first from [anchor]), in grid
/// units, zigzag then exp-Golomb order 3. Zero bits pad the last byte.
Uint8List encodeTrail(TrailPoint anchor, Trail trail) {
  final w = _BitWriter();
  final frame = _Frame(anchor, trail.gridM);
  var px = 0, py = 0;
  for (final p in trail.points) {
    final (x, y) = frame.units(p);
    w.expGolomb(_zigzag(x - px), 3);
    w.expGolomb(_zigzag(y - py), 3);
    px = x;
    py = y;
  }
  return w.finish();
}

/// [count] points read from [data] at [offset], and the bytes they took;
/// null when the bits run out or make no sense.
({List<TrailPoint> points, int bytes})? decodeTrail(
  TrailPoint anchor,
  int gridM,
  int count,
  Uint8List data,
  int offset,
) {
  if (gridM <= 0 || offset > data.length) return null;
  final r = _BitReader(data, offset);
  final frame = _Frame(anchor, gridM);
  final points = <TrailPoint>[];
  var x = 0, y = 0;
  for (var i = 0; i < count; i++) {
    final dx = r.expGolomb(3);
    final dy = dx == null ? null : r.expGolomb(3);
    if (dx == null || dy == null) return null;
    x += _unzigzag(dx);
    y += _unzigzag(dy);
    points.add(frame.point(x, y));
  }
  return (points: points, bytes: (r.read + 7) >> 3);
}

/// The finest trail of [points] (newest first, without [anchor]) in
/// [maxBytes] and 255 points: Douglas–Peucker from 15 m, doubled until it
/// fits, then bisected to within 1 m, on a grid of max(8, ⌈ε/2⌉) m. A trail
/// too long for even the coarsest grid loses its oldest points.
Trail? fitTrail(TrailPoint anchor, List<TrailPoint> points, int maxBytes) {
  var rest = points;
  while (rest.isNotEmpty && maxBytes > 0) {
    final fit = _fit(anchor, rest, maxBytes);
    if (fit != null) return fit;
    rest = rest.sublist(0, rest.length * 3 ~/ 4);
  }
  return null;
}

Trail? _fit(TrailPoint anchor, List<TrailPoint> points, int maxBytes) {
  Trail? attempt(double epsilon) {
    final grid = max(8, (epsilon / 2).ceil());
    if (grid > 255) return null;
    final kept = simplify([anchor, ...points], epsilon).sublist(1);
    if (kept.length > 255) return null;
    final trail = (gridM: grid, points: kept);
    return encodeTrail(anchor, trail).length <= maxBytes ? trail : null;
  }

  var epsilon = 15.0;
  var fit = attempt(epsilon);
  if (fit != null) return fit;
  var failed = epsilon;
  while (fit == null) {
    epsilon *= 2;
    if (epsilon > 510) return null;
    fit = attempt(epsilon);
    if (fit == null) failed = epsilon;
  }
  while (epsilon - failed > 1) {
    final mid = (failed + epsilon) / 2;
    final finer = attempt(mid);
    if (finer == null) {
      failed = mid;
    } else {
      epsilon = mid;
      fit = finer;
    }
  }
  return fit;
}

/// Douglas–Peucker in 2D: the points of [line] that keep it within
/// [epsilonM] metres, always the first and the last.
List<TrailPoint> simplify(List<TrailPoint> line, double epsilonM) {
  if (line.length <= 2) return line;
  final frame = _Frame(line.first, 1);
  final xy = [for (final p in line) frame.metres(p)];
  final keep = List<bool>.filled(line.length, false);
  keep[0] = true;
  keep[line.length - 1] = true;
  final spans = <(int, int)>[(0, line.length - 1)];
  while (spans.isNotEmpty) {
    final (a, b) = spans.removeLast();
    var worst = -1.0;
    var at = -1;
    for (var i = a + 1; i < b; i++) {
      final d = _distanceToSegment(xy[i], xy[a], xy[b]);
      if (d > worst) {
        worst = d;
        at = i;
      }
    }
    if (at >= 0 && worst > epsilonM) {
      keep[at] = true;
      spans
        ..add((a, at))
        ..add((at, b));
    }
  }
  return [
    for (var i = 0; i < line.length; i++)
      if (keep[i]) line[i],
  ];
}

double _distanceToSegment(
  (double, double) p,
  (double, double) a,
  (double, double) b,
) {
  final (px, py) = p;
  final (ax, ay) = a;
  final (bx, by) = b;
  final dx = bx - ax, dy = by - ay;
  final length2 = dx * dx + dy * dy;
  final t = length2 == 0
      ? 0.0
      : (((px - ax) * dx + (py - ay) * dy) / length2).clamp(0.0, 1.0);
  final ex = ax + t * dx - px, ey = ay + t * dy - py;
  return sqrt(ex * ex + ey * ey);
}

/// Metres east and north of an anchor, on a grid; a longitude difference is
/// wrapped into ±180°, so a trail across 180° doesn't jump round the world.
class _Frame {
  _Frame(this.anchor, this.gridM)
    : _cos = max(cos(anchor.lat * pi / 180), 0.01);

  final TrailPoint anchor;
  final int gridM;
  final double _cos;

  (double, double) metres(TrailPoint p) => (
    _wrap(p.lon - anchor.lon) * _cos * _metresPerDegree,
    (p.lat - anchor.lat) * _metresPerDegree,
  );

  (int, int) units(TrailPoint p) {
    final (x, y) = metres(p);
    return ((x / gridM).round(), (y / gridM).round());
  }

  TrailPoint point(int x, int y) => (
    lat: (anchor.lat + y * gridM / _metresPerDegree).clamp(-90.0, 90.0),
    lon: _wrap(anchor.lon + x * gridM / (_metresPerDegree * _cos)),
  );

  static double _wrap(double lon) => (lon + 180) % 360 - 180;
}

int _zigzag(int v) => v >= 0 ? 2 * v : -2 * v - 1;

int _unzigzag(int u) => u.isEven ? u ~/ 2 : -(u + 1) ~/ 2;

class _BitWriter {
  final _bytes = <int>[];
  int _current = 0;
  int _count = 0;

  void bit(int b) {
    _current = _current << 1 | b;
    if (++_count == 8) {
      _bytes.add(_current);
      _current = 0;
      _count = 0;
    }
  }

  void bits(int value, int width) {
    for (var i = width - 1; i >= 0; i--) {
      bit(value >> i & 1);
    }
  }

  /// `q = u >> k`, `m = ⌊log2(q + 1)⌋`: m zero bits, q + 1 in m + 1 bits,
  /// then the low k bits of u.
  void expGolomb(int u, int k) {
    final q = u >> k;
    final m = (q + 1).bitLength - 1;
    for (var i = 0; i < m; i++) {
      bit(0);
    }
    bits(q + 1, m + 1);
    bits(u & (1 << k) - 1, k);
  }

  Uint8List finish() {
    if (_count > 0) _bytes.add(_current << (8 - _count));
    return Uint8List.fromList(_bytes);
  }
}

class _BitReader {
  _BitReader(this._data, this._offset);

  final Uint8List _data;
  final int _offset;

  /// Bits read so far.
  int read = 0;

  int? bit() {
    final i = _offset + (read >> 3);
    if (i >= _data.length) return null;
    final b = _data[i] >> (7 - (read & 7)) & 1;
    read++;
    return b;
  }

  int? bits(int width) {
    var v = 0;
    for (var i = 0; i < width; i++) {
      final b = bit();
      if (b == null) return null;
      v = v << 1 | b;
    }
    return v;
  }

  /// Null at the end of the data, or past 20 leading zeros, which no real
  /// step needs.
  int? expGolomb(int k) {
    var m = 0;
    while (true) {
      final b = bit();
      if (b == null) return null;
      if (b == 1) break;
      if (++m > 20) return null;
    }
    final rest = bits(m);
    final low = rest == null ? null : bits(k);
    if (rest == null || low == null) return null;
    return ((1 << m | rest) - 1) << k | low;
  }
}
