import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../helpers/geo_format.dart';
import '../models/app_settings.dart';

/// Heights from start to end, with the lowest and highest point labelled
/// in [units]: a route's, or the ground under a radio line.
class ElevationProfile extends StatelessWidget {
  /// Metres; NaN where the height isn't known, drawn as a grey gap.
  final List<double> elevations;

  /// Metres from the start for each height: the heights then stand at
  /// their distances, with the length labelled under them. Without them
  /// they are evenly spaced.
  final List<double>? distances;
  final UnitSystem units;
  final Color color;

  /// A straight line over the ground from [line].start metres at the start
  /// to [line].end at the end (a radio line), with a light band [band]
  /// metres either side of it at each point.
  final ({double start, double end})? line;
  final List<double>? band;
  final Color? lineColor;

  /// A spot on the ground to mark, metres from the start.
  final double? mark;

  const ElevationProfile({
    super.key,
    required this.elevations,
    required this.units,
    required this.color,
    this.distances,
    this.line,
    this.band,
    this.lineColor,
    this.mark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _ProfilePainter(
        elevations: elevations,
        distances: distances,
        units: units,
        color: color,
        line: line,
        band: band,
        lineColor: lineColor ?? theme.colorScheme.primary,
        mark: mark,
        grid: theme.colorScheme.outlineVariant,
        gap: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        text: theme.textTheme.bodySmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      size: Size.infinite,
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<double> elevations;
  final List<double>? distances;
  final UnitSystem units;
  final Color color;
  final ({double start, double end})? line;
  final List<double>? band;
  final Color lineColor;
  final double? mark;
  final Color grid;
  final Color gap;
  final TextStyle text;

  _ProfilePainter({
    required this.elevations,
    required this.distances,
    required this.units,
    required this.color,
    required this.line,
    required this.band,
    required this.lineColor,
    required this.mark,
    required this.grid,
    required this.gap,
    required this.text,
  });

  TextPainter _label(String s) => TextPainter(
    text: TextSpan(text: s, style: text),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = elevations.length;
    if (n < 2) return;
    final d = distances;
    final length = d == null ? (n - 1).toDouble() : d.last;
    if (length <= 0) return;
    double xOf(int i) => d == null ? i.toDouble() : d[i];
    final l = line;
    double lineAt(double x) => l!.start + (l.end - l.start) * x / length;

    // The heights the chart has to hold.
    var lo = double.infinity, hi = double.negativeInfinity;
    void take(double v) {
      if (!v.isFinite) return;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }

    for (final e in elevations) {
      take(e);
    }
    if (l != null) {
      for (var i = 0; i < n; i++) {
        final w = band?[i] ?? 0;
        take(lineAt(xOf(i)) - w);
        take(lineAt(xOf(i)) + w);
      }
    }
    if (!lo.isFinite) return;
    final span = math.max(hi - lo, 20.0);

    final labels = [
      for (final h in [hi, lo]) _label(GeoFormat.heightText(h, units)),
    ];
    final left = labels.map((l) => l.width).reduce(math.max) + 8;
    final lengthLabel = d == null
        ? null
        : _label(GeoFormat.distanceText(length, units));
    final w = size.width - left;
    final h = size.height - (lengthLabel == null ? 0 : lengthLabel.height + 2);
    double px(double x) => left + w * x / length;
    double py(double v) => h - (v - lo) / span * h;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(left, 0), Offset(size.width, 0), gridPaint)
      ..drawLine(Offset(left, h), Offset(size.width, h), gridPaint);
    labels[0].paint(canvas, Offset.zero);
    labels[1].paint(canvas, Offset(0, h - labels[1].height));

    // Where the height isn't known: grey from top to bottom.
    final gapPaint = Paint()..color = gap;
    for (var i = 0; i < n; i++) {
      if (!elevations[i].isNaN) continue;
      var j = i;
      while (j + 1 < n && elevations[j + 1].isNaN) {
        j++;
      }
      final x0 = px(xOf(i > 0 ? i - 1 : i)),
          x1 = px(xOf(j < n - 1 ? j + 1 : j));
      canvas.drawRect(Rect.fromLTRB(x0, 0, math.max(x1, x0 + 1), h), gapPaint);
      i = j;
    }

    // The room the signal needs, around the radio line.
    if (l != null && band != null) {
      final area = Path()..moveTo(px(0), py(l.start + band![0]));
      for (var i = 1; i < n; i++) {
        area.lineTo(px(xOf(i)), py(lineAt(xOf(i)) + band![i]));
      }
      for (var i = n - 1; i >= 0; i--) {
        area.lineTo(px(xOf(i)), py(lineAt(xOf(i)) - band![i]));
      }
      area.close();
      canvas.drawPath(area, Paint()..color = lineColor.withValues(alpha: 0.12));
    }

    // The ground: filled below, each known stretch on its own.
    final fill = Paint()..color = color.withValues(alpha: 0.15);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < n; i++) {
      if (elevations[i].isNaN) continue;
      var j = i;
      while (j + 1 < n && !elevations[j + 1].isNaN) {
        j++;
      }
      final ground = Path()..moveTo(px(xOf(i)), py(elevations[i]));
      for (var k = i + 1; k <= j; k++) {
        ground.lineTo(px(xOf(k)), py(elevations[k]));
      }
      final area = Path.from(ground)
        ..lineTo(px(xOf(j)), h)
        ..lineTo(px(xOf(i)), h)
        ..close();
      canvas
        ..drawPath(area, fill)
        ..drawPath(ground, stroke);
      i = j;
    }

    if (l != null) {
      canvas.drawLine(
        Offset(px(0), py(l.start)),
        Offset(px(length), py(l.end)),
        Paint()
          ..color = lineColor
          ..strokeWidth = 2,
      );
    }

    final m = mark;
    double? markX;
    if (m != null && d != null) {
      var k = 0;
      while (k + 1 < n && d[k + 1] < m) {
        k++;
      }
      final a = elevations[k], b = elevations[math.min(k + 1, n - 1)];
      final t = k + 1 < n && d[k + 1] > d[k]
          ? (m - d[k]) / (d[k + 1] - d[k])
          : 0;
      final y = a.isNaN ? b : (b.isNaN ? a : a + (b - a) * t.clamp(0, 1));
      if (y.isFinite) {
        markX = px(m);
        canvas
          ..drawLine(
            Offset(markX, py(y)),
            Offset(markX, h),
            Paint()
              ..color = lineColor
              ..strokeWidth = 1,
          )
          ..drawCircle(Offset(markX, py(y)), 5, Paint()..color = lineColor)
          ..drawCircle(
            Offset(markX, py(y)),
            5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
      }
    }

    // The length, and where the marked spot is, under the chart.
    if (lengthLabel != null) {
      final y = h + 2;
      final right = size.width - lengthLabel.width;
      lengthLabel.paint(canvas, Offset(right, y));
      if (markX != null) {
        final at = _label(GeoFormat.distanceText(m!, units));
        final x = (markX - at.width / 2).clamp(left, size.width - at.width);
        if (x + at.width < right - 8) at.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.elevations != elevations ||
      old.distances != distances ||
      old.color != color ||
      old.units != units ||
      old.line != line ||
      old.band != band ||
      old.lineColor != lineColor ||
      old.mark != mark ||
      old.text != text;
}
