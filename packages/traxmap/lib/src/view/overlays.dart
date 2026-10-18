import 'package:flutter/widgets.dart';

import '../packs/geo.dart';

/// Base for app-supplied features drawn above the map. Apps (e.g. MeshTrax)
/// map their own concepts such as nodes, paths and coverage onto these.
sealed class MapOverlay {
  final String id;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const MapOverlay({required this.id, this.onTap, this.onLongPress});

  bool get hasHandlers => onTap != null || onLongPress != null;
}

/// A point marker: the default circle, or any widget.
class MapMarker extends MapOverlay {
  final LatLng position;

  /// Default circle look, used when [child] is null.
  final Color color;
  final double radius;

  /// Custom marker widget, laid out in [size].
  final Widget? child;
  final Size? size;

  /// Which point of the marker sits on [position], like MapLibre's
  /// `icon-anchor`: [Alignment.center] for dots, [Alignment.bottomCenter]
  /// for pins.
  final Alignment anchor;

  /// Text drawn in a pill above the marker (see `MapLabelStyle`), shown from
  /// [labelMinZoom] (package zoom) up, or always when that is null.
  final String? label;
  final double? labelMinZoom;

  /// False lets taps pass through to the map (e.g. a highlight pin). Markers
  /// without handlers are never interactive.
  final bool interactive;

  const MapMarker({
    required super.id,
    required this.position,
    this.color = const Color(0xFFD32F2F),
    this.radius = 6,
    this.child,
    this.size,
    this.anchor = Alignment.center,
    this.label,
    this.labelMinZoom,
    this.interactive = true,
    super.onTap,
    super.onLongPress,
  });

  Size get effectiveSize =>
      size ?? Size.square(child == null ? radius * 2 + 16 : 32);

  bool get receivesGestures => interactive && hasHandlers;
}

enum MapLinePattern { solid, dashed, dotted }

class MapLine extends MapOverlay {
  final List<LatLng> points;
  final Color color;
  final double width;
  final MapLinePattern pattern;

  const MapLine({
    required super.id,
    required this.points,
    this.color = const Color(0xFF1976D2),
    this.width = 3,
    this.pattern = MapLinePattern.solid,
    super.onTap,
    super.onLongPress,
  });
}

class MapPolygon extends MapOverlay {
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const MapPolygon({
    required super.id,
    required this.points,
    this.fillColor = const Color(0x332E7D32),
    this.strokeColor = const Color(0xFF2E7D32),
    this.strokeWidth = 1.5,
    super.onTap,
    super.onLongPress,
  });
}

/// Look of marker labels. The default matches MeshTrax's node labels.
class MapLabelStyle {
  final Color background;
  final TextStyle textStyle;
  final double maxWidth;
  final double radius;

  const MapLabelStyle({
    this.background = const Color(0x8A000000),
    this.textStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    this.maxWidth = 120,
    this.radius = 8,
  });
}
