import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/svg_drawing.dart';
import '../helpers/svg_paste.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/drawing_canvas.dart';

enum _Tool { pen, line, rect, circle, ellipse, arrow }

/// Draw with a finger or paste an SVG, and see what will be sent: the pad
/// shows the message's own drawing over what you drew, simplified to the
/// finest detail that fits. Pops the message text, or null.
class DrawingComposeScreen extends StatefulWidget {
  /// What the message box has left, after any reply's quote.
  final int maxBytes;

  const DrawingComposeScreen({super.key, required this.maxBytes});

  static Future<String?> open(BuildContext context, {required int maxBytes}) =>
      Navigator.push<String>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DrawingComposeScreen(maxBytes: maxBytes),
        ),
      );

  @override
  State<DrawingComposeScreen> createState() => _DrawingComposeScreenState();
}

class _DrawingComposeScreenState extends State<DrawingComposeScreen>
    with SingleTickerProviderStateMixin {
  /// The pad's own units, so a drawing keeps its place when the pad changes
  /// size.
  static const _pad = Size(400, 300);

  late final _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final _caption = TextEditingController();
  final _paste = TextEditingController();
  final _items = <SvgItem>[];
  var _tool = _Tool.pen;
  List<SvgPoint>? _stroke;
  SvgPoint? _start;
  SvgFit? _fit;

  /// The message's drawing, in pad units, to draw over what you drew.
  List<List<SvgPoint>> _sent = const [];
  String? _pasteNote;
  var _pasteFailed = false;

  @override
  void dispose() {
    _tabs.dispose();
    _caption.dispose();
    _paste.dispose();
    super.dispose();
  }

  void _refit() {
    final caption = _caption.text.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
    final fit = _items.isEmpty
        ? null
        : SvgWriter.fit(_items, budget: widget.maxBytes, caption: caption);
    final lines =
        fit == null ? null : SvgDrawing.tryParse(fit.pathData)?.polylines();
    setState(() {
      _fit = fit;
      _sent = fit == null || lines == null
          ? const []
          : [
              for (final line in lines)
                [
                  for (final p in line)
                    (
                      x: fit.origin.x + p.x / fit.scale,
                      y: fit.origin.y + p.y / fit.scale,
                    ),
                ],
            ];
    });
  }

  SvgItem _shape(SvgPoint a, SvgPoint b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    return switch (_tool) {
      _Tool.line || _Tool.pen => SvgLineItem(a, b),
      _Tool.rect => SvgRect(a, b),
      _Tool.circle => () {
          final r = math.sqrt(dx * dx + dy * dy);
          return SvgEllipse(a, r, r);
        }(),
      _Tool.ellipse => SvgEllipse(
          (x: (a.x + b.x) / 2, y: (a.y + b.y) / 2),
          dx.abs() / 2,
          dy.abs() / 2,
        ),
      _Tool.arrow => SvgArrow(a, b),
    };
  }

  SvgPoint _toPad(Offset at, Size size) => (
        x: (at.dx / size.width * _pad.width).clamp(0, _pad.width),
        y: (at.dy / size.height * _pad.height).clamp(0, _pad.height),
      );

  void _down(Offset at, Size size) {
    final p = _toPad(at, size);
    _start = p;
    if (_tool == _Tool.pen) {
      _stroke = [p];
      _items.add(SvgStroke(_stroke!));
    } else {
      _items.add(_shape(p, p));
    }
    setState(() {});
  }

  void _move(Offset at, Size size) {
    final start = _start;
    if (start == null) return;
    final p = _toPad(at, size);
    final stroke = _stroke;
    if (stroke != null) {
      final last = stroke.last;
      if ((p.x - last.x).abs() + (p.y - last.y).abs() < 0.8) return;
      stroke.add(p);
    } else {
      _items[_items.length - 1] = _shape(start, p);
    }
    setState(() {});
  }

  void _up() {
    if (_start == null) return;
    _start = null;
    _stroke = null;
    _refit();
  }

  void _usePaste() {
    final l10n = context.l10n;
    try {
      final strokes = SvgPaste.strokes(_paste.text);
      var minX = double.infinity, minY = double.infinity;
      var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final s in strokes) {
        for (final p in s) {
          minX = math.min(minX, p.x);
          maxX = math.max(maxX, p.x);
          minY = math.min(minY, p.y);
          maxY = math.max(maxY, p.y);
        }
      }
      final k = math.min(
        _pad.width * 0.84 / math.max(maxX - minX, 1e-9),
        _pad.height * 0.84 / math.max(maxY - minY, 1e-9),
      );
      final ox = (_pad.width - (maxX - minX) * k) / 2;
      final oy = (_pad.height - (maxY - minY) * k) / 2;
      _items
        ..clear()
        ..addAll([
          for (final s in strokes)
            SvgStroke([
              for (final p in s)
                (x: ox + (p.x - minX) * k, y: oy + (p.y - minY) * k),
            ]),
        ]);
      _pasteNote = l10n.drawing_pasteNote;
      _pasteFailed = false;
      _refit();
    } on SvgPasteError catch (e) {
      setState(() {
        _pasteFailed = true;
        _pasteNote = switch (e.problem) {
          SvgPasteProblem.empty => l10n.drawing_pasteEmpty,
          SvgPasteProblem.tooBig => l10n.drawing_pasteTooBig,
          SvgPasteProblem.unreadable => l10n.drawing_pasteUnreadable,
          SvgPasteProblem.nothing => l10n.drawing_pasteNothing,
        };
      });
    }
  }

  Widget _tools() {
    final l10n = context.l10n;
    return SegmentedButton<_Tool>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final (tool, icon, label) in [
          (_Tool.pen, const Icon(Icons.gesture), l10n.drawing_toolPen),
          (_Tool.line, const Icon(Icons.horizontal_rule), l10n.drawing_toolLine),
          (_Tool.rect, const Icon(Icons.crop_square), l10n.drawing_toolRect),
          (_Tool.circle, const Icon(Icons.circle_outlined), l10n.drawing_toolCircle),
          (_Tool.ellipse, const _OvalIcon(), l10n.drawing_toolEllipse),
          (_Tool.arrow, const Icon(Icons.arrow_right_alt), l10n.drawing_toolArrow),
        ])
          ButtonSegment(value: tool, icon: icon, tooltip: label),
      ],
      selected: {_tool},
      onSelectionChanged: (s) => setState(() => _tool = s.first),
    );
  }

  Widget _pastePanel() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _paste,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          style: drawingCodeStyle.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.drawing_pasteHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: _usePaste,
              child: Text(l10n.drawing_pasteUse),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pasteNote ?? l10n.drawing_pasteNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _pasteFailed ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _status() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fit = _fit;
    if (fit == null) {
      return Text(l10n.drawing_empty, style: theme.textTheme.bodySmall);
    }
    final bytes = l10n.drawing_bytes(fit.bytes, widget.maxBytes);
    if (!fit.fits) {
      return Text(
        '$bytes. ${l10n.drawing_tooDetailed}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final detail = fit.tolerance == 0
        ? l10n.drawing_keptAll
        : l10n.drawing_simplified(fit.tolerance.toStringAsFixed(1));
    return Text(
      '$bytes · ${l10n.drawing_points(fit.points)}. $detail',
      style: theme.textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final look = context.select<AppSettingsService, DrawingLook>(
      (s) => DrawingLook.of(s.settings),
    );
    final fit = _fit;
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.tray_drawing),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: l10n.drawing_undo,
            onPressed: _items.isEmpty
                ? null
                : () {
                    _items.removeLast();
                    _refit();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.common_clear,
            onPressed: _items.isEmpty
                ? null
                : () {
                    _items.clear();
                    _refit();
                  },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.drawing_tabDraw),
            Tab(text: l10n.drawing_tabPaste),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_tabs.index == 0) _tools() else _pastePanel(),
              const SizedBox(height: 12),
              // Not in a scroll view: a drag on the pad must draw, not
              // scroll. Its 4:3 is the card's shape; the keyboard shrinks it.
              Flexible(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: AspectRatio(
                    aspectRatio: _pad.width / _pad.height,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Listener(
                            onPointerDown: (e) => _down(e.localPosition, size),
                            onPointerMove: (e) => _move(e.localPosition, size),
                            onPointerUp: (_) => _up(),
                            onPointerCancel: (_) => _up(),
                            child: CustomPaint(
                              size: size,
                              painter: _PadPainter(
                                items: List.of(_items),
                                sent: _sent,
                                look: look,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _caption,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.drawing_caption,
                  hintText: l10n.drawing_captionHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _refit(),
              ),
              const SizedBox(height: 8),
              _status(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: fit == null || !fit.fits
                      ? null
                      : () => Navigator.pop(context, fit.wire),
                  child: Text(l10n.dialog_insert),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An ellipse outline the size and color of the icons around it. Neither
/// icon set has one; its egg reads as a teardrop.
class _OvalIcon extends StatelessWidget {
  const _OvalIcon();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Container(
          width: size * 0.92,
          height: size * 0.6,
          decoration: ShapeDecoration(
            shape: OvalBorder(
              side: BorderSide(
                color: theme.color ?? Theme.of(context).colorScheme.onSurface,
                width: size / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What you drew, faintly, and over it the drawing the message carries.
class _PadPainter extends CustomPainter {
  final List<SvgItem> items;
  final List<List<SvgPoint>> sent;
  final DrawingLook look;

  _PadPainter({required this.items, required this.sent, required this.look});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = DrawingLook.screen);
    final k = size.width / _DrawingComposeScreenState._pad.width;
    Offset at(SvgPoint p) => Offset(p.x * k, p.y * k);

    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.pen.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final item in items) {
      switch (item) {
        case SvgStroke(:final points):
          final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
          for (final p in points.skip(1)) {
            path.lineTo(at(p).dx, at(p).dy);
          }
          if (points.length == 1) path.lineTo(at(points.first).dx, at(points.first).dy);
          canvas.drawPath(path, faint);
        case SvgLineItem(:final a, :final b) || SvgArrow(:final a, :final b):
          canvas.drawLine(at(a), at(b), faint);
        case SvgRect(:final a, :final b):
          canvas.drawRect(Rect.fromPoints(at(a), at(b)), faint);
        case SvgEllipse(:final center, :final rx, :final ry):
          canvas.drawOval(
            Rect.fromCenter(center: at(center), width: rx * 2 * k, height: ry * 2 * k),
            faint,
          );
      }
    }

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.pen
      ..strokeWidth = look.lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (final line in sent) {
      path.moveTo(at(line.first).dx, at(line.first).dy);
      for (final p in line.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
    }
    canvas.drawPath(path, ink);
  }

  @override
  bool shouldRepaint(_PadPainter old) => true;
}
