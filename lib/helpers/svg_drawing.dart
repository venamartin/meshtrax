import 'dart:convert';
import 'dart:math' as math;

import 'package:path_parsing/path_parsing.dart';

import 'drawing_map.dart';

typedef SvgPoint = ({double x, double y});

/// The limits on a received drawing, part of the format in
/// docs/message-format.md. A message is far smaller; these are a backstop.
abstract final class SvgLimits {
  static const pathBytes = 300;

  /// Lines after curves and arcs are broken into them.
  static const segments = 2000;
  static const coordinate = 1e6;
  static const captionBytes = 200;
}

/// What a path command leaves after `path_parsing` normalises it: arcs and
/// quadratics become cubics, and every command is absolute.
sealed class _Segment {
  const _Segment();
}

final class _Move extends _Segment {
  final double x, y;
  const _Move(this.x, this.y);
}

final class _Line extends _Segment {
  final double x, y;
  const _Line(this.x, this.y);
}

final class _Cubic extends _Segment {
  final double x1, y1, x2, y2, x, y;
  const _Cubic(this.x1, this.y1, this.x2, this.y2, this.x, this.y);
}

final class _Close extends _Segment {
  const _Close();
}

class _Collector extends PathProxy {
  final segments = <_Segment>[];

  @override
  void moveTo(double x, double y) => segments.add(_Move(x, y));

  @override
  void lineTo(double x, double y) => segments.add(_Line(x, y));

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      segments.add(_Cubic(x1, y1, x2, y2, x3, y3));

  @override
  void close() => segments.add(const _Close());
}

/// A drawing from a message: SVG path data on one line, then an optional
/// caption. Path data alone means `fill="none"`, stroked in the reader's pen
/// color with round ends; that convention is part of the format, since bare
/// SVG would fill paths black and draw no lines.
///
/// Only path data is read, never markup: a stranger's text reaches nothing
/// but the path grammar, and with no loops in it the work a message causes
/// grows only with its length.
class SvgDrawing {
  final String pathData;

  /// Empty when there is none.
  final String caption;

  /// The map the drawing is drawn over, if any. Its numbers are then
  /// positions on the map's frame rather than a shape to fit.
  final DrawingMap? map;
  final List<_Segment> _segments;

  SvgDrawing._(this.pathData, this.caption, this.map, this._segments);

  static final _hasDigit = RegExp(r'\d');

  /// The drawing in [text] (what follows `SVG:`), or null when it isn't one:
  /// markup, broken path data, a path past the limits or one that draws
  /// nothing stays ordinary text.
  static SvgDrawing? tryParse(String text) {
    final lines = text.split('\n');
    var path = lines.first.trim();
    var segments = _read(path);
    if (segments == null) return null;
    // Another tool may have wrapped long path data: a line that only reads
    // as more path data continues it. A map line comes next; anything else
    // starts the caption.
    var next = 1;
    while (next < lines.length &&
        _hasDigit.hasMatch(lines[next]) &&
        DrawingMap.tryParse(lines[next]) == null) {
      final joined = '$path ${lines[next].trim()}';
      final more = _read(joined);
      if (more == null) break;
      path = joined;
      segments = more;
      next++;
    }
    final map = next < lines.length ? DrawingMap.tryParse(lines[next]) : null;
    if (map != null) next++;
    final caption = lines.skip(next).join('\n').trim();
    if (utf8.encode(caption).length > SvgLimits.captionBytes) return null;
    final drawing = SvgDrawing._(path, caption, map, segments!);
    final lines0 = drawing.polylines();
    if (lines0 == null || lines0.isEmpty) return null;
    return drawing;
  }

  static List<_Segment>? _read(String path) {
    if (path.isEmpty || utf8.encode(path).length > SvgLimits.pathBytes) {
      return null;
    }
    final collector = _Collector();
    try {
      // It hands over segments before it fails, so nothing is used until it
      // has read the whole path. It throws StateError, which is an Error.
      writeSvgPathDataToPath(path, collector);
    } catch (_) {
      return null;
    }
    bool ok(double v) => v.isFinite && v.abs() <= SvgLimits.coordinate;
    for (final s in collector.segments) {
      final good = switch (s) {
        _Move(:final x, :final y) || _Line(:final x, :final y) => ok(x) && ok(y),
        _Cubic() => ok(s.x1) && ok(s.y1) && ok(s.x2) && ok(s.y2) && ok(s.x) &&
            ok(s.y),
        _Close() => true,
      };
      if (!good) return null;
    }
    return collector.segments;
  }

  /// Every line the path draws, with curves broken into lines finely enough
  /// for the drawing's size. Null past [SvgLimits.segments]. A zero-length
  /// line stays as two equal points, which round ends draw as a dot.
  List<List<SvgPoint>>? polylines() {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    void grow(double x, double y) {
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    for (final s in _segments) {
      switch (s) {
        case _Move(:final x, :final y) || _Line(:final x, :final y):
          grow(x, y);
        case _Cubic():
          grow(s.x1, s.y1);
          grow(s.x2, s.y2);
          grow(s.x, s.y);
        case _Close():
      }
    }
    final size = math.max(math.max(maxX - minX, maxY - minY), 1e-9);

    final out = <List<SvgPoint>>[];
    var count = 0;
    List<SvgPoint>? current;
    SvgPoint start = (x: 0, y: 0), at = (x: 0, y: 0);
    void add(SvgPoint p) {
      current!.add(p);
      count++;
    }

    for (final s in _segments) {
      switch (s) {
        case _Move(:final x, :final y):
          at = start = (x: x, y: y);
          current = null;
        case _Line(:final x, :final y):
          if (current == null) {
            current = [at];
            out.add(current);
          }
          at = (x: x, y: y);
          add(at);
        case _Cubic():
          if (current == null) {
            current = [at];
            out.add(current);
          }
          final reach = _distance(at, (x: s.x1, y: s.y1)) +
              _distance((x: s.x1, y: s.y1), (x: s.x2, y: s.y2)) +
              _distance((x: s.x2, y: s.y2), (x: s.x, y: s.y));
          final steps = (reach / size * 40).ceil().clamp(1, 64);
          final from = at;
          for (var i = 1; i <= steps; i++) {
            final t = i / steps, u = 1 - t;
            add((
              x: u * u * u * from.x +
                  3 * u * u * t * s.x1 +
                  3 * u * t * t * s.x2 +
                  t * t * t * s.x,
              y: u * u * u * from.y +
                  3 * u * u * t * s.y1 +
                  3 * u * t * t * s.y2 +
                  t * t * t * s.y,
            ));
          }
          at = (x: s.x, y: s.y);
        case _Close():
          if (current != null) add(start);
          at = start;
          current = null;
      }
      if (count > SvgLimits.segments) return null;
    }
    return out;
  }

  static double _distance(SvgPoint a, SvgPoint b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

/// Something drawn on the sketch pad, in the pad's own units.
sealed class SvgItem {
  const SvgItem();

  /// This item with every point passed through [to] and every length
  /// multiplied by [scale]: how a drawing follows the ground when its map
  /// moves.
  SvgItem transformed(SvgPoint Function(SvgPoint) to, double scale) =>
      switch (this) {
        SvgStroke(:final points) => SvgStroke([for (final p in points) to(p)]),
        SvgRoute(:final points) => SvgRoute([for (final p in points) to(p)]),
        SvgLineItem(:final a, :final b) => SvgLineItem(to(a), to(b)),
        SvgRect(:final a, :final b) => SvgRect(to(a), to(b)),
        SvgArrow(:final a, :final b) => SvgArrow(to(a), to(b)),
        SvgEllipse(:final center, :final rx, :final ry) =>
          SvgEllipse(to(center), rx * scale, ry * scale),
        SvgCross(:final center, :final half) =>
          SvgCross(to(center), half * scale),
      };

  /// The lines this item draws, near enough to show what was drawn. The
  /// message's own lines come from [SvgWriter].
  List<List<SvgPoint>> get outline {
    SvgPoint p(double x, double y) => (x: x, y: y);
    return switch (this) {
      SvgStroke(:final points) || SvgRoute(:final points) => [
          points.length == 1 ? [points.first, points.first] : points,
        ],
      SvgLineItem(:final a, :final b) => [
          [a, b],
        ],
      SvgRect(:final a, :final b) => [
          [a, p(b.x, a.y), b, p(a.x, b.y), a],
        ],
      SvgEllipse(:final center, :final rx, :final ry) => [
          [
            for (var i = 0; i <= 48; i++)
              p(
                center.x + rx * math.cos(i * math.pi / 24),
                center.y + ry * math.sin(i * math.pi / 24),
              ),
          ],
        ],
      SvgCross(:final center, :final half) => [
          [p(center.x - half, center.y - half), p(center.x + half, center.y + half)],
          [p(center.x + half, center.y - half), p(center.x - half, center.y + half)],
        ],
      SvgArrow(:final a, :final b) => () {
          final dx = b.x - a.x, dy = b.y - a.y;
          final length = math.max(math.sqrt(dx * dx + dy * dy), 1e-9);
          final head = (length * 0.18).clamp(6.0, 48.0);
          final ux = dx / length, uy = dy / length;
          final c = math.cos(math.pi / 6), s = math.sin(math.pi / 6);
          return [
            [a, b],
            [
              p(b.x - head * (ux * c - uy * s), b.y - head * (uy * c + ux * s)),
              b,
              p(b.x - head * (ux * c + uy * s), b.y - head * (uy * c - ux * s)),
            ],
          ];
        }(),
    };
  }
}

/// A finger stroke. The writer simplifies these to fit.
final class SvgStroke extends SvgItem {
  final List<SvgPoint> points;
  const SvgStroke(this.points);
}

/// Straight segments through tapped points, written exactly.
final class SvgRoute extends SvgItem {
  final List<SvgPoint> points;
  const SvgRoute(this.points);
}

/// An X: two lines through [center], each end [half] from it across and
/// down.
final class SvgCross extends SvgItem {
  final SvgPoint center;
  final double half;
  const SvgCross(this.center, this.half);
}

final class SvgLineItem extends SvgItem {
  final SvgPoint a, b;
  const SvgLineItem(this.a, this.b);
}

final class SvgRect extends SvgItem {
  final SvgPoint a, b;
  const SvgRect(this.a, this.b);
}

final class SvgEllipse extends SvgItem {
  final SvgPoint center;
  final double rx, ry;
  const SvgEllipse(this.center, this.rx, this.ry);
}

final class SvgArrow extends SvgItem {
  final SvgPoint a, b;
  const SvgArrow(this.a, this.b);
}

/// One subpath on the 0–99 grid: a start, lines or arcs, maybe a close.
class SvgSubpath {
  final SvgPoint start;
  final List<SvgSegment> segments;
  final bool close;

  const SvgSubpath(this.start, this.segments, {this.close = false});
}

class SvgSegment {
  final SvgPoint to;

  /// Radii for a whole-ellipse arc (large and sweep flags set); null for a
  /// straight line.
  final double? rx, ry;

  const SvgSegment.line(this.to) : rx = null, ry = null;
  const SvgSegment.arc(this.to, double this.rx, double this.ry);
}

/// What [SvgWriter.fit] chose.
class SvgFit {
  final String pathData;

  /// The whole message: `SVG:`, the path, and the caption line if any.
  final String wire;
  final int bytes;
  final int points;

  /// How far a simplified stroke may stray, in grid units (the drawing's
  /// longer side is 99). Zero when every point was kept.
  final double tolerance;
  final bool fits;

  /// Grid to pad units: pad = origin + grid / scale.
  final SvgPoint origin;
  final double scale;

  const SvgFit({
    required this.pathData,
    required this.wire,
    required this.bytes,
    required this.points,
    required this.tolerance,
    required this.fits,
    required this.origin,
    required this.scale,
  });
}

/// Writes drawings as the shortest path data: whole numbers on a 0–99 grid
/// fitted to the drawing, each command absolute or relative as is shorter,
/// implicit repeats, and a minus sign doubling as the separator. This is
/// the minimizer; nothing needs to run over the result afterwards.
abstract final class SvgWriter {
  static int _bytes(String s) => utf8.encode(s).length;

  static String _number(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    var s = ((v * 10).round() / 10).toString();
    if (s.startsWith('0.')) {
      s = s.substring(1);
    } else if (s.startsWith('-0.')) {
      s = '-${s.substring(2)}';
    }
    return s;
  }

  static String _numbers(List<double> values) {
    final out = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      final s = _number(values[i]);
      if (i > 0 && !s.startsWith('-')) out.write(' ');
      out.write(s);
    }
    return out.toString();
  }

  /// The shortest path data for [subpaths].
  static String encode(List<SvgSubpath> subpaths) {
    final out = StringBuffer();
    String? last;
    var cur = (x: 0.0, y: 0.0);
    var first = true;

    String piece(String letter, List<double> values) {
      final implied = letter != 'M' &&
          letter != 'm' &&
          (letter == last ||
              (letter == 'L' && last == 'M') ||
              (letter == 'l' && last == 'm'));
      final s = _numbers(values);
      if (!implied) return '$letter$s';
      return s.startsWith('-') ? s : ' $s';
    }

    void take(List<(String, List<double>)> candidates) {
      var best = candidates.first;
      var text = piece(best.$1, best.$2);
      for (final c in candidates.skip(1)) {
        final t = piece(c.$1, c.$2);
        if (t.length < text.length) {
          best = c;
          text = t;
        }
      }
      out.write(text);
      last = best.$1;
    }

    for (final sp in subpaths) {
      final s = sp.start;
      take(first
          ? [('M', [s.x, s.y])]
          : [('M', [s.x, s.y]), ('m', [s.x - cur.x, s.y - cur.y])]);
      first = false;
      cur = s;
      for (final seg in sp.segments) {
        final p = seg.to, dx = p.x - cur.x, dy = p.y - cur.y;
        final rx = seg.rx;
        if (rx != null) {
          take([
            ('a', [rx, seg.ry!, 0, 1, 1, dx, dy]),
            ('A', [rx, seg.ry!, 0, 1, 1, p.x, p.y]),
          ]);
        } else {
          take([
            ('l', [dx, dy]),
            ('L', [p.x, p.y]),
            if (dy == 0) ('h', [dx]),
            if (dy == 0) ('H', [p.x]),
            if (dx == 0) ('v', [dy]),
            if (dx == 0) ('V', [p.y]),
          ]);
        }
        cur = p;
      }
      if (sp.close) {
        out.write('z');
        last = 'z';
        cur = s;
      }
    }
    return out.toString();
  }

  /// Ramer–Douglas–Peucker: the points a polyline needs to stay within
  /// [tolerance] of where it was.
  static List<SvgPoint> simplify(List<SvgPoint> points, double tolerance) {
    if (points.length < 3 || tolerance <= 0) return List.of(points);
    final keep = List.filled(points.length, false);
    keep[0] = keep[points.length - 1] = true;
    final stack = [(0, points.length - 1)];
    while (stack.isNotEmpty) {
      final (s, e) = stack.removeLast();
      final a = points[s], b = points[e];
      final dx = b.x - a.x, dy = b.y - a.y;
      final length = math.sqrt(dx * dx + dy * dy);
      var far = -1.0;
      var at = -1;
      for (var i = s + 1; i < e; i++) {
        final p = points[i];
        final d = length > 0
            ? (dy * p.x - dx * p.y + b.x * a.y - b.y * a.x).abs() / length
            : SvgDrawing._distance(p, a);
        if (d > far) {
          far = d;
          at = i;
        }
      }
      if (far > tolerance) {
        keep[at] = true;
        stack
          ..add((s, at))
          ..add((at, e));
      }
    }
    return [
      for (var i = 0; i < points.length; i++)
        if (keep[i]) points[i],
    ];
  }

  /// Over a [map] the grid is the map's frame (pad units are its map
  /// pixels, 4 to a grid step); without one it's fitted to the drawing.
  static (List<SvgSubpath>, int, SvgPoint, double) _subpaths(
    List<SvgItem> items,
    double tolerance, {
    DrawingMap? map,
  }) {
    var minX = 0.0, minY = 0.0;
    var scale = 100 / DrawingMap.width;
    if (map == null) {
      final all = <SvgPoint>[];
      for (final item in items) {
        switch (item) {
          case SvgStroke(:final points) || SvgRoute(:final points):
            all.addAll(points);
          case SvgEllipse(:final center, :final rx, :final ry):
            all
              ..add((x: center.x - rx, y: center.y - ry))
              ..add((x: center.x + rx, y: center.y + ry));
          case SvgCross(:final center, :final half):
            all
              ..add((x: center.x - half, y: center.y - half))
              ..add((x: center.x + half, y: center.y + half));
          case SvgLineItem(:final a, :final b) ||
                SvgRect(:final a, :final b) ||
                SvgArrow(:final a, :final b):
            all
              ..add(a)
              ..add(b);
        }
      }
      minX = minY = double.infinity;
      var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final p in all) {
        minX = math.min(minX, p.x);
        maxX = math.max(maxX, p.x);
        minY = math.min(minY, p.y);
        maxY = math.max(maxY, p.y);
      }
      final span = math.max(maxX - minX, maxY - minY);
      scale = span > 0 ? 99 / span : 1.0;
    }
    SvgPoint grid(SvgPoint p) =>
        (x: (p.x - minX) * scale, y: (p.y - minY) * scale);
    SvgPoint round(SvgPoint p) =>
        (x: p.x.roundToDouble(), y: p.y.roundToDouble());

    final out = <SvgSubpath>[];
    var points = 0;
    for (final item in items) {
      switch (item) {
        case SvgStroke(points: final stroke):
          final kept = <SvgPoint>[];
          for (final p in simplify([for (final p in stroke) grid(p)], tolerance)
              .map(round)) {
            if (kept.isEmpty || kept.last != p) kept.add(p);
          }
          points += kept.length;
          out.add(SvgSubpath(kept.first, [
            // A tap is a zero-length line, which round ends draw as a dot.
            for (final p in kept.length > 1 ? kept.skip(1) : kept)
              SvgSegment.line(p),
          ]));
        case SvgRoute(points: final route):
          final kept = <SvgPoint>[];
          for (final p in route.map((p) => round(grid(p)))) {
            if (kept.isEmpty || kept.last != p) kept.add(p);
          }
          points += kept.length;
          out.add(SvgSubpath(kept.first, [
            for (final p in kept.length > 1 ? kept.skip(1) : kept)
              SvgSegment.line(p),
          ]));
        case SvgCross(:final center, :final half):
          // From its rounded corners, which never pass 99 as a rounded
          // centre plus a rounded reach can.
          final a = round(grid((x: center.x - half, y: center.y - half)));
          final b = round(grid((x: center.x + half, y: center.y + half)));
          points += 4;
          out
            ..add(SvgSubpath(a, [SvgSegment.line(b)]))
            ..add(SvgSubpath((x: b.x, y: a.y), [
              SvgSegment.line((x: a.x, y: b.y)),
            ]));
        case SvgLineItem(:final a, :final b):
          points += 2;
          out.add(SvgSubpath(round(grid(a)), [SvgSegment.line(round(grid(b)))]));
        case SvgRect(:final a, :final b):
          final p = round(grid(a)), q = round(grid(b));
          final x0 = math.min(p.x, q.x), x1 = math.max(p.x, q.x);
          final y0 = math.min(p.y, q.y), y1 = math.max(p.y, q.y);
          points += 4;
          out.add(SvgSubpath((x: x0, y: y0), [
            SvgSegment.line((x: x1, y: y0)),
            SvgSegment.line((x: x1, y: y1)),
            SvgSegment.line((x: x0, y: y1)),
          ], close: true));
        case SvgEllipse(:final center, :final rx, :final ry):
          // Started from its rightmost point, which never rounds past 99 as
          // a rounded center plus a rounded radius can.
          final start = round(grid((x: center.x + rx, y: center.y)));
          final gx = math.max(1.0, (rx * scale).roundToDouble());
          final gy = math.max(1.0, (ry * scale).roundToDouble());
          points += 1;
          // One arc ending just short of its start; `z` closes the gap and
          // puts the position back on whole numbers.
          out.add(SvgSubpath(start, [
            SvgSegment.arc((x: start.x, y: start.y - 0.1), gx, gy),
          ], close: true));
        case SvgArrow(:final a, :final b):
          final p = round(grid(a)), q = round(grid(b));
          final dx = q.x - p.x, dy = q.y - p.y;
          final length = math.max(math.sqrt(dx * dx + dy * dy), 1e-9);
          final head = (length * 0.18).roundToDouble().clamp(3.0, 12.0);
          final ux = dx / length, uy = dy / length;
          final c = math.cos(math.pi / 6), s = math.sin(math.pi / 6);
          final h1 = round((
            x: q.x - head * (ux * c - uy * s),
            y: q.y - head * (uy * c + ux * s),
          ));
          final h2 = round((
            x: q.x - head * (ux * c + uy * s),
            y: q.y - head * (uy * c - ux * s),
          ));
          points += 4;
          out
            ..add(SvgSubpath(p, [SvgSegment.line(q)]))
            ..add(SvgSubpath(h1, [SvgSegment.line(q), SvgSegment.line(h2)]));
      }
    }
    return (out, points, (x: minX, y: minY), scale);
  }

  /// The finest simplification of [items] whose message, with `SVG:`, the
  /// [map] line and [caption], fits [budget] bytes. Shapes stay exact; only
  /// finger strokes are simplified. When even the coarsest doesn't fit,
  /// [SvgFit.fits] is false and the coarsest is returned.
  static SvgFit fit(
    List<SvgItem> items, {
    required int budget,
    String caption = '',
    DrawingMap? map,
  }) {
    final tail = '${map == null ? '' : '\n${map.toLine()}'}'
        '${caption.isEmpty ? '' : '\n$caption'}';
    final room = budget - _bytes('SVG:$tail');
    SvgFit at(double tolerance, {bool fits = true}) {
      final (subpaths, points, origin, scale) =
          _subpaths(items, tolerance, map: map);
      final path = encode(subpaths);
      final wire = 'SVG:$path$tail';
      return SvgFit(
        pathData: path,
        wire: wire,
        bytes: _bytes(wire),
        points: points,
        tolerance: tolerance,
        fits: fits && _bytes(path) <= room,
        origin: origin,
        scale: scale,
      );
    }

    final exact = at(0);
    if (exact.fits) return exact;
    var lo = 0.0, hi = 40.0;
    var best = at(hi);
    if (!best.fits) return best;
    for (var i = 0; i < 22; i++) {
      final mid = (lo + hi) / 2;
      final t = at(mid);
      if (t.fits) {
        best = t;
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return best;
  }
}
