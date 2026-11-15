import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A line across a chat with a label in its middle, drawn as a shallow wave:
/// the day headings and the NEW MESSAGES line.
class WavyDivider extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? labelStyle;

  const WavyDivider({
    super.key,
    required this.label,
    required this.color,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final wave = Expanded(
      child: CustomPaint(
        size: const Size.fromHeight(_WavePainter.height),
        painter: _WavePainter(color),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          wave,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label, style: labelStyle),
          ),
          wave,
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  static const height = 8.0;
  static const _amplitude = 1.6;
  static const _wavelength = 22.0;

  final Color color;

  const _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    for (var x = 1.0; x <= size.width; x += 1) {
      path.lineTo(
        x,
        mid + _amplitude * math.sin(x / _wavelength * 2 * math.pi),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
