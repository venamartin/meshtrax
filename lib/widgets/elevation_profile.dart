import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../helpers/geo_format.dart';
import '../models/app_settings.dart';

/// A route's heights from start to end, with the lowest and highest point
/// labelled in [units].
class ElevationProfile extends StatelessWidget {
  final List<double> elevations;
  final UnitSystem units;
  final Color color;

  const ElevationProfile({
    super.key,
    required this.elevations,
    required this.units,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _ProfilePainter(
        elevations: elevations,
        units: units,
        color: color,
        grid: theme.colorScheme.outlineVariant,
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
  final UnitSystem units;
  final Color color;
  final Color grid;
  final TextStyle text;

  _ProfilePainter({
    required this.elevations,
    required this.units,
    required this.color,
    required this.grid,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.length < 2) return;
    final lo = elevations.reduce(math.min);
    final hi = elevations.reduce(math.max);
    final span = math.max(hi - lo, 20.0);
    final labels = [
      for (final h in [hi, lo])
        TextPainter(
          text: TextSpan(text: GeoFormat.heightText(h, units), style: text),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final left = labels.map((l) => l.width).reduce(math.max) + 8;
    final w = size.width - left;
    final h = size.height;
    Offset at(int i) => Offset(
      left + w * i / (elevations.length - 1),
      h - (elevations[i] - lo) / span * h,
    );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(left, 0), Offset(size.width, 0), gridPaint)
      ..drawLine(Offset(left, h), Offset(size.width, h), gridPaint);
    labels[0].paint(canvas, const Offset(0, 0));
    labels[1].paint(canvas, Offset(0, h - labels[1].height));

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < elevations.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, h)
      ..lineTo(left, h)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = color.withValues(alpha: 0.15))
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.elevations != elevations || old.color != color || old.units != units;
}
