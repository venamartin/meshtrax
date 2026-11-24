import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Who can see the radio's location, the widest first: anyone who hears
/// its adverts, the people who may ask it, or only you.
enum LocationAudience { onlyYou, people, adverts }

/// The radio's GPS as the location icon shows it: on with a fix, on with
/// no fix yet, or off. A radio with no GPS counts as off.
enum LocationGps { on, noFix, off }

/// The My location icon (Martin, 2026-11-21): its shape says who can see
/// the location (a pin, a person in the pin, waves), filled while the GPS
/// is on and an outline while it is off. With no fix yet it is a dashed
/// pin, whoever can see it.
class LocationIcon extends StatelessWidget {
  const LocationIcon({
    super.key,
    required this.audience,
    required this.gps,
    this.size,
    this.color,
  });

  final LocationAudience audience;
  final LocationGps gps;

  /// The icon theme's size when null, as [Icon].
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _LocationIconPainter(
          audience,
          gps,
          color ?? theme.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LocationIconPainter extends CustomPainter {
  _LocationIconPainter(this.audience, this.gps, this.color);

  final LocationAudience audience;
  final LocationGps gps;
  final Color color;

  // The shapes on a 24 × 24 grid, as drawn on the design canvas.
  static final _pin = Path()
    ..moveTo(12, 2.5)
    ..cubicTo(8.4, 2.5, 5.5, 5.4, 5.5, 9)
    ..cubicTo(5.5, 13.9, 12, 21.5, 12, 21.5)
    ..cubicTo(12, 21.5, 18.5, 13.9, 18.5, 9)
    ..cubicTo(18.5, 5.4, 15.6, 2.5, 12, 2.5)
    ..close();
  static final _dot = Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 9), radius: 2.3));
  static final _person = Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 7.3), radius: 1.8))
    ..moveTo(8.8, 12.4)
    ..cubicTo(9.4, 10.8, 10.6, 10, 12, 10)
    ..cubicTo(13.4, 10, 14.6, 10.8, 15.2, 12.4)
    ..close();
  static final _smallPin = Path()
    ..moveTo(12, 6.2)
    ..cubicTo(9.7, 6.2, 7.8, 8.1, 7.8, 10.4)
    ..cubicTo(7.8, 13.6, 12, 18.6, 12, 18.6)
    ..cubicTo(12, 18.6, 16.2, 13.6, 16.2, 10.4)
    ..cubicTo(16.2, 8.1, 14.3, 6.2, 12, 6.2)
    ..close();
  static final _smallDot = Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 10.4), radius: 1.5));
  static final _waves = Path()
    ..moveTo(5.6, 5.2)
    ..arcToPoint(
      const Offset(5.6, 15.6),
      radius: const Radius.circular(9),
      clockwise: false,
    )
    ..moveTo(18.4, 5.2)
    ..arcToPoint(const Offset(18.4, 15.6), radius: const Radius.circular(9))
    ..moveTo(2.8, 3)
    ..arcToPoint(
      const Offset(2.8, 17.8),
      radius: const Radius.circular(12.5),
      clockwise: false,
    )
    ..moveTo(21.2, 3)
    ..arcToPoint(const Offset(21.2, 17.8), radius: const Radius.circular(12.5));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final fill = Paint()..color = color;
    Paint stroke(double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (gps == LocationGps.noFix) {
      canvas.drawPath(_dashed(_pin, 2.6, 2.2), stroke(2));
      return;
    }
    final on = gps == LocationGps.on;
    if (audience == LocationAudience.adverts) {
      if (on) {
        canvas.drawPath(_holed(_smallPin, _smallDot), fill);
      } else {
        canvas.drawPath(_smallPin, stroke(1.6));
      }
      canvas.drawPath(_waves, stroke(1.8));
      return;
    }
    final mark = audience == LocationAudience.people ? _person : _dot;
    if (on) {
      canvas.drawPath(_holed(_pin, mark), fill);
    } else {
      canvas.drawPath(mark, fill);
    }
    canvas.drawPath(_pin, stroke(2));
  }

  /// [shape] with [holes] cut out, so the bar shows through.
  static Path _holed(Path shape, Path holes) => Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(shape, Offset.zero)
    ..addPath(holes, Offset.zero);

  static Path _dashed(Path source, double dash, double gap) {
    final dashes = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        dashes.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return dashes;
  }

  @override
  bool shouldRepaint(_LocationIconPainter old) =>
      old.audience != audience || old.gps != gps || old.color != color;
}
