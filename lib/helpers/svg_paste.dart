import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;

import 'svg_drawing.dart';

enum SvgPasteProblem { empty, tooBig, unreadable, nothing }

class SvgPasteError implements Exception {
  final SvgPasteProblem problem;
  const SvgPasteError(this.problem);
}

/// An SVG file or path data that you paste on your own phone, turned into
/// strokes for [SvgWriter]. Only your own input comes here: messages from
/// others are read by [SvgDrawing], which knows nothing but path data. So
/// this can use the full SVG reader behind flutter_svg, which applies
/// transforms and styles and drops what is invisible.
abstract final class SvgPaste {
  static const maxBytes = 20 * 1024;
  static const maxPoints = 50000;

  static final _svgTag = RegExp(r'<svg\b', caseSensitive: false);

  /// Throws [SvgPasteError].
  static List<List<SvgPoint>> strokes(String text) {
    var source = text.trim();
    if (source.isEmpty) throw const SvgPasteError(SvgPasteProblem.empty);
    if (utf8.encode(source).length > maxBytes) {
      throw const SvgPasteError(SvgPasteProblem.tooBig);
    }
    if (!source.startsWith('<')) {
      final d = const HtmlEscape(HtmlEscapeMode.attribute).convert(source);
      source = '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1">'
          '<path d="$d"/></svg>';
    }
    vg.VectorInstructions instructions;
    try {
      instructions = vg.parseWithoutOptimizers(source);
    } catch (_) {
      // A file with neither a viewBox nor a size makes the reader give up,
      // though its paths are fine; positions don't depend on the size.
      try {
        instructions = vg.parseWithoutOptimizers(
          source.replaceFirst(_svgTag, '<svg width="1" height="1"'),
        );
      } catch (_) {
        throw const SvgPasteError(SvgPasteProblem.unreadable);
      }
    }

    final paths = [
      for (final c in instructions.commands)
        if (c.type == vg.DrawCommandType.path && c.objectId != null)
          instructions.paths[c.objectId!],
    ];
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    void grow(double x, double y) {
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    for (final path in paths) {
      for (final c in path.commands) {
        switch (c) {
          case vg.MoveToCommand(:final x, :final y):
          case vg.LineToCommand(:final x, :final y):
            grow(x, y);
          case vg.CubicToCommand():
            grow(c.x1, c.y1);
            grow(c.x2, c.y2);
            grow(c.x3, c.y3);
          default:
        }
      }
    }
    final size = math.max(maxX - minX, maxY - minY);
    if (!size.isFinite) throw const SvgPasteError(SvgPasteProblem.nothing);
    final step = math.max(size, 1e-9) / 400;

    final out = <List<SvgPoint>>[];
    var count = 0;
    for (final path in paths) {
      List<SvgPoint>? current;
      SvgPoint start = (x: 0, y: 0), at = (x: 0, y: 0);
      void open() {
        if (current == null) {
          current = [at];
          out.add(current!);
        }
      }

      for (final c in path.commands) {
        switch (c) {
          case vg.MoveToCommand(:final x, :final y):
            at = start = (x: x, y: y);
            current = null;
          case vg.LineToCommand(:final x, :final y):
            open();
            at = (x: x, y: y);
            current!.add(at);
            count++;
          case vg.CubicToCommand():
            open();
            final from = at;
            final reach = _distance(from, (x: c.x1, y: c.y1)) +
                _distance((x: c.x1, y: c.y1), (x: c.x2, y: c.y2)) +
                _distance((x: c.x2, y: c.y2), (x: c.x3, y: c.y3));
            final steps = (reach / step).ceil().clamp(1, 200);
            for (var i = 1; i <= steps; i++) {
              final t = i / steps, u = 1 - t;
              current!.add((
                x: u * u * u * from.x +
                    3 * u * u * t * c.x1 +
                    3 * u * t * t * c.x2 +
                    t * t * t * c.x3,
                y: u * u * u * from.y +
                    3 * u * u * t * c.y1 +
                    3 * u * t * t * c.y2 +
                    t * t * t * c.y3,
              ));
            }
            count += steps;
            at = (x: c.x3, y: c.y3);
          case vg.CloseCommand():
            if (current != null) current!.add(start);
            at = start;
            current = null;
        }
        if (count > maxPoints) throw const SvgPasteError(SvgPasteProblem.tooBig);
      }
    }
    if (out.isEmpty) throw const SvgPasteError(SvgPasteProblem.nothing);
    return out;
  }

  static double _distance(SvgPoint a, SvgPoint b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}
