import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../helpers/svg_drawing.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../utils/app_logger.dart';

/// "monospace" only exists on Android.
const drawingCodeStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas', 'DejaVu Sans Mono'],
);

/// How drawings look on this phone, from the settings. A message only says
/// what to draw.
class DrawingLook {
  /// Near-black green, the dark of an Apple II monitor.
  static const screen = Color(0xFF010A03);

  final Color pen;

  /// In dp, whatever the drawing's scale.
  final double lineWidth;

  /// 0 to 100.
  final int glow;

  /// 0 to 100.
  final int scanlines;

  const DrawingLook({
    required this.pen,
    required this.lineWidth,
    required this.glow,
    required this.scanlines,
  });

  factory DrawingLook.of(AppSettings settings) => DrawingLook(
        pen: Color(settings.drawingPenColor),
        lineWidth: settings.drawingLineWidth,
        glow: settings.drawingGlow,
        scanlines: settings.drawingScanlines,
      );

  @override
  bool operator ==(Object other) =>
      other is DrawingLook &&
      other.pen == pen &&
      other.lineWidth == lineWidth &&
      other.glow == glow &&
      other.scanlines == scanlines;

  @override
  int get hashCode => Object.hash(pen, lineWidth, glow, scanlines);
}

Paint _strokePaint(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..color = color
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// [lines] in device pixels, fitted to [size] with a margin whatever the
/// drawing's units, keeping its shape.
Path _fitted(List<List<SvgPoint>> lines, Size size, double ratio) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final line in lines) {
    for (final p in line) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }
  final margin = math.max(16.0, size.shortestSide * 0.08);
  final spanX = maxX - minX, spanY = maxY - minY;
  final fit = math.min(
    spanX > 0 ? (size.width - 2 * margin) / spanX : double.infinity,
    spanY > 0 ? (size.height - 2 * margin) / spanY : double.infinity,
  );
  final scale = fit.isFinite ? fit : 1.0;
  final midX = (minX + maxX) / 2, midY = (minY + maxY) / 2;
  double px(double x) => (size.width / 2 + (x - midX) * scale) * ratio;
  double py(double y) => (size.height / 2 + (y - midY) * scale) * ratio;
  final path = Path();
  for (final line in lines) {
    path.moveTo(px(line.first.x), py(line.first.y));
    for (final p in line.skip(1)) {
      path.lineTo(px(p.x), py(p.y));
    }
  }
  return path;
}

/// The drawing on its screen, as one bitmap. Showing a bitmap costs one
/// texture however many lines the drawing has, where a live painter would
/// replay every line and the glow on every frame that redraws.
ui.Image rasterizeDrawing(
  List<List<SvgPoint>> lines,
  DrawingLook look,
  Size size,
  double ratio,
) {
  final width = (size.width * ratio).round();
  final height = (size.height * ratio).round();
  final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, bounds);
  canvas.drawRect(bounds, Paint()..color = DrawingLook.screen);

  // Under the lines, so they don't break the lines up.
  if (look.scanlines > 0) {
    final paint = Paint()
      ..color = look.pen.withValues(alpha: look.scanlines / 100 * 0.22);
    final period = math.max(2, (3 * ratio).round());
    final band = math.max(1, ratio.round()).toDouble();
    for (var y = 0; y < height; y += period) {
      canvas.drawRect(
        Rect.fromLTWH(0, y.toDouble(), width.toDouble(), band),
        paint,
      );
    }
  }

  final path = _fitted(lines, size, ratio);
  final strokeWidth = look.lineWidth * ratio;
  final glow = look.glow / 100;
  if (glow > 0) {
    // A blurred copy of the lines over what is already painted, as phosphor
    // glows: a wide haze and a tight halo. Each is one blur over one layer,
    // so it costs by the card's size, not by the drawing.
    for (final (sigma, opacity, lift) in [
      ((6 + glow * 12) * ratio, glow * 0.9, 2.4),
      ((1.5 + glow * 2.5) * ratio, math.min(glow * 1.5, 1.0), 1.2),
    ]) {
      canvas.saveLayer(
        bounds,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          )
          ..color = Color.fromRGBO(0, 0, 0, opacity)
          ..blendMode = BlendMode.screen,
      );
      canvas.drawPath(
        path,
        _strokePaint(
          Color.from(
            alpha: 1,
            red: math.min(look.pen.r * lift, 1),
            green: math.min(look.pen.g * lift, 1),
            blue: math.min(look.pen.b * lift, 1),
          ),
          strokeWidth,
        ),
      );
      canvas.restore();
    }
  }
  canvas.drawPath(path, _strokePaint(look.pen, strokeWidth));

  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

/// Shows [drawing] on the green screen. It draws when it first appears and
/// keeps only the bitmap, so what a drawing costs in memory follows what is
/// on screen.
class DrawingCanvas extends StatefulWidget {
  final SvgDrawing drawing;
  final DrawingLook look;
  final Size size;

  const DrawingCanvas({
    super.key,
    required this.drawing,
    required this.look,
    required this.size,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  ui.Image? _image;
  Object? _paintedFor;

  void _paintIfChanged(double ratio) {
    final wanted = (widget.drawing.pathData, widget.look, widget.size, ratio);
    if (wanted == _paintedFor) return;
    _paintedFor = wanted;
    final sw = Stopwatch()..start();
    final lines = widget.drawing.polylines() ?? const [];
    _image?.dispose();
    _image = lines.isEmpty
        ? null
        : rasterizeDrawing(lines, widget.look, widget.size, ratio);
    appLogger.perf('Drawing', sw, detail: '${lines.length} strokes');
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size.isEmpty) return const SizedBox.shrink();
    _paintIfChanged(MediaQuery.devicePixelRatioOf(context));
    final image = _image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.fromSize(
        size: widget.size,
        child: image == null
            ? const ColoredBox(color: DrawingLook.screen)
            : Semantics(
                image: true,
                label: context.l10n.tray_drawing,
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
      ),
    );
  }
}
