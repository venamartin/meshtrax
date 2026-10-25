import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

import '../renderer/sprite_sheets.dart';
import '../styles/asset_style_source.dart';
import '../styles/style_registry.dart';

/// A feature as one of a style's layers would draw it: the legend asks the
/// style, so a legend never drifts from the map.
class LegendSample {
  /// The style layer's id.
  final String layer;

  /// The feature's properties, enough to pass the layer's filter.
  final Map<String, Object?> properties;

  /// What a text layer prints (a sounding, a light's rhythm).
  final String? text;

  const LegendSample(this.layer, [this.properties = const {}, this.text]);

  static const _zoom = 15.0;

  /// The zoom [layer] is drawn at: 15, or its first zoom if later.
  static double _zoomFor(vt.ThemeLayer layer) => math.max(_zoom, layer.minzoom);

  /// The context [layer] draws this sample in: the first geometry type its
  /// filter accepts, starting with the layer type's own.
  vt.EvalContext context(vt.ThemeLayer layer) {
    final zoom = _zoomFor(layer);
    final own = switch (layer) {
      vt.FillThemeLayer() => 'Polygon',
      vt.LineThemeLayer() => 'LineString',
      _ => 'Point',
    };
    for (final type in {own, 'Polygon', 'LineString', 'Point'}) {
      final ctx = vt.EvalContext(
        zoom: zoom,
        properties: properties,
        geometryType: type,
      );
      if (_truthy(layer.filter(ctx))) return ctx;
    }
    return vt.EvalContext(
      zoom: zoom,
      properties: properties,
      geometryType: own,
    );
  }

  /// Whether [layer]'s filter accepts this sample as some geometry type.
  bool drawnBy(vt.ThemeLayer layer) =>
      _truthy(layer.filter(context(layer))) && layer.maxzoom > _zoomFor(layer);

  static bool _truthy(Object? v) => v != null && v != false;
}

/// A style read for drawing [LegendSample]s: its layers and sprite sheet.
class LegendStyle {
  final vt.Theme theme;
  final vt.SpriteAtlas? sprites;
  final Map<String, vt.ThemeLayer> _layers;

  LegendStyle(this.theme, this.sprites)
    : _layers = {for (final l in theme.layers) l.id: l};

  vt.ThemeLayer? layer(String id) => _layers[id];

  static final _cache = <String, Future<LegendStyle>>{};

  /// Style [id] from [registry], with the bundled sprite sheet it names.
  static Future<LegendStyle> load(StyleRegistry registry, String id) =>
      _cache[id] ??= _load(registry, id);

  static Future<LegendStyle> _load(StyleRegistry registry, String id) async {
    final raw = await registry.loadRaw(id);
    final sprite = raw['sprite'];
    return LegendStyle(
      const vt.ThemeReader().read(raw, id: id),
      await loadSpriteSheet(
        sprite is String
            ? sprite.replaceFirst('{sprite}', bundledSprites)
            : null,
      ),
    );
  }
}

/// [samples] drawn over [ground], as [style] draws them on the map.
class LegendSymbol extends StatelessWidget {
  final LegendStyle style;
  final List<LegendSample> samples;
  final LegendSample? ground;
  final Size size;

  const LegendSymbol({
    super.key,
    required this.style,
    required this.samples,
    this.ground,
    this.size = const Size(48, 32),
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: size,
      painter: _LegendPainter(
        style,
        samples,
        ground,
        DefaultTextStyle.of(context).style,
      ),
    ),
  );
}

class _LegendPainter extends CustomPainter {
  final LegendStyle style;
  final List<LegendSample> samples;
  final LegendSample? ground;

  /// The app's text style, for the font text samples print in.
  final TextStyle font;

  _LegendPainter(this.style, this.samples, this.ground, this.font);

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.clipRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)));
    if (ground case final ground?) _paint(canvas, box, ground, null);
    final icons = _Icons.of(style, samples, box);
    for (final sample in samples) {
      _paint(canvas, box, sample, icons);
    }
  }

  void _paint(Canvas canvas, Rect box, LegendSample sample, _Icons? icons) {
    final layer = style.layer(sample.layer);
    if (layer == null) return;
    final ctx = sample.context(layer);
    switch (layer) {
      case vt.BackgroundThemeLayer():
        canvas.drawRect(
          box,
          Paint()
            ..color = _fade(layer.color.eval(ctx), layer.opacity.eval(ctx)),
        );
      case vt.FillThemeLayer():
        canvas.drawRect(
          box,
          Paint()
            ..color = _fade(layer.color.eval(ctx), layer.opacity.eval(ctx)),
        );
        if (layer.outlineColor case final outline?) {
          canvas.drawRect(
            box.deflate(0.5),
            Paint()
              ..color = outline.eval(ctx)
              ..style = PaintingStyle.stroke,
          );
        }
      case vt.LineThemeLayer():
        _line(canvas, box, layer, ctx);
      case vt.CircleThemeLayer():
        final r = layer.radius.eval(ctx) * 1.5;
        canvas.drawCircle(
          box.center,
          r,
          Paint()
            ..color = _fade(layer.color.eval(ctx), layer.opacity.eval(ctx)),
        );
        final stroke = layer.strokeWidth.eval(ctx);
        if (stroke > 0) {
          canvas.drawCircle(
            box.center,
            r,
            Paint()
              ..color = layer.strokeColor.eval(ctx)
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke,
          );
        }
      case vt.SymbolThemeLayer():
        if (sample.text case final text?) {
          _text(canvas, box, layer, ctx, text);
        } else {
          icons?.paint(canvas, sample);
        }
      default:
    }
  }

  void _line(
    Canvas canvas,
    Rect box,
    vt.LineThemeLayer layer,
    vt.EvalContext ctx,
  ) {
    final width = layer.width.eval(ctx);
    final opacity = layer.opacity.eval(ctx);
    final y = box.center.dy;
    final from = box.left + 4, to = box.right - 4;
    final name = layer.pattern?.eval(ctx);
    final sprite = name == null ? null : style.sprites?.sprites[name];
    if (sprite != null) {
      // Stamped as tall as the line is wide, as the map does; ticks drawn
      // down in the sprite fall on the line's right, inside the area.
      final scale = width / (sprite.height / sprite.pixelRatio);
      final w = sprite.width / sprite.pixelRatio * scale;
      final paint = Paint()..color = Color.fromRGBO(0, 0, 0, opacity);
      for (var x = from; x < to; x += w) {
        final part = math.min(w, to - x) / w;
        canvas.drawImageRect(
          style.sprites!.image,
          Rect.fromLTWH(sprite.x, sprite.y, sprite.width * part, sprite.height),
          Rect.fromLTWH(x, y - width / 2, w * part, width),
          paint,
        );
      }
      return;
    }
    final paint = Paint()
      ..color = _fade(layer.color.eval(ctx), opacity)
      ..strokeWidth = width;
    final dashes = layer.dashArray?.eval(ctx) ?? const [];
    if (dashes.length < 2) {
      canvas.drawLine(Offset(from, y), Offset(to, y), paint);
      return;
    }
    // Dash lengths are in line widths, as in MapLibre.
    var x = from;
    for (var i = 0; x < to; i++) {
      final len = dashes[i % dashes.length] * math.max(width, 1);
      if (i.isEven && len > 0) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + len, to), y), paint);
      }
      x += len;
    }
  }

  void _text(
    Canvas canvas,
    Rect box,
    vt.SymbolThemeLayer layer,
    vt.EvalContext ctx,
    String text,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: font.copyWith(
          color: _fade(layer.textColor.eval(ctx), layer.textOpacity.eval(ctx)),
          fontSize: layer.textSize.eval(ctx).clamp(10, 12),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final scale = math.min(1.0, (box.width - 4) / painter.width);
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.scale(scale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
    painter.dispose();
  }

  static Color _fade(Color c, double opacity) =>
      c.withValues(alpha: c.a * opacity.clamp(0.0, 1.0));

  @override
  bool shouldRepaint(_LegendPainter old) =>
      old.style != style ||
      old.samples != samples ||
      old.ground != ground ||
      old.font != font;
}

/// The icons of a box's samples, placed around one point as the map places
/// them, then moved and scaled to fill the box together (up to [_largest]
/// times their size on the map, for legibility).
class _Icons {
  final vt.SpriteAtlas atlas;
  final Map<LegendSample, (vt.Sprite, Rect, double)> placed;
  final Offset shift;
  final double scale;
  final Offset centre;

  _Icons(this.atlas, this.placed, this.shift, this.scale, this.centre);

  static const _largest = 1.6;

  static _Icons? of(LegendStyle style, List<LegendSample> samples, Rect box) {
    final atlas = style.sprites;
    if (atlas == null) return null;
    final placed = <LegendSample, (vt.Sprite, Rect, double)>{};
    Rect? bounds;
    for (final sample in samples) {
      final layer = style.layer(sample.layer);
      if (layer is! vt.SymbolThemeLayer || sample.text != null) continue;
      final ctx = sample.context(layer);
      final sprite = atlas.sprites[layer.iconImage?.eval(ctx)];
      if (sprite == null) continue;
      final size = layer.iconSize.eval(ctx);
      final w = sprite.width / sprite.pixelRatio * size;
      final h = sprite.height / sprite.pixelRatio * size;
      final offset = layer.iconOffset.eval(ctx);
      final at = Offset(
        offset.isNotEmpty ? offset[0] * size : 0,
        offset.length > 1 ? offset[1] * size : 0,
      );
      final anchor = layer.iconAnchor.eval(ctx);
      final rect = Rect.fromLTWH(
        at.dx + _start(anchor, 'left', 'right', w),
        at.dy + _start(anchor, 'top', 'bottom', h),
        w,
        h,
      );
      final angle = layer.iconRotate.eval(ctx) * math.pi / 180;
      placed[sample] = (sprite, rect, angle);
      final turned = _turned(rect, angle);
      bounds = bounds?.expandToInclude(turned) ?? turned;
    }
    if (bounds == null) return null;
    final room = box.deflate(2);
    final scale = math.min(
      _largest,
      math.min(room.width / bounds.width, room.height / bounds.height),
    );
    return _Icons(atlas, placed, -bounds.center, scale, box.center);
  }

  /// Where a box of [length] starts from its anchor point, along one axis.
  static double _start(String anchor, String low, String high, double length) {
    if (anchor.contains(low)) return 0;
    if (anchor.contains(high)) return -length;
    return -length / 2;
  }

  /// [rect]'s bounds once turned [angle] about the anchor point (origin).
  static Rect _turned(Rect rect, double angle) {
    if (angle == 0) return rect;
    final c = math.cos(angle), s = math.sin(angle);
    final corners = [
      for (final p in [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ])
        Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c),
    ];
    final xs = corners.map((p) => p.dx), ys = corners.map((p) => p.dy);
    return Rect.fromLTRB(
      xs.reduce(math.min),
      ys.reduce(math.min),
      xs.reduce(math.max),
      ys.reduce(math.max),
    );
  }

  void paint(Canvas canvas, LegendSample sample) {
    final placement = placed[sample];
    if (placement == null) return;
    final (sprite, rect, angle) = placement;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    canvas.translate(shift.dx, shift.dy);
    canvas.rotate(angle);
    canvas.drawImageRect(
      atlas.image,
      Rect.fromLTWH(sprite.x, sprite.y, sprite.width, sprite.height),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }
}
