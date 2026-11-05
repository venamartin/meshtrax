import 'dart:math' as math;

/// Which map a drawing is drawn over. The letter is what the message's map
/// line carries; Standard has none.
enum DrawingMapType {
  standard(''),
  usgs('u'),
  charts('c');

  final String letter;
  const DrawingMapType(this.letter);

  /// A letter this reader doesn't know draws Standard.
  static DrawingMapType fromLetter(String letter) => values.firstWhere(
        (t) => t.letter == letter.toLowerCase(),
        orElse: () => standard,
      );
}

/// The map behind a drawing: a frame [width] × [height] map pixels at [zoom],
/// centred on [lat], [lon]. Zoom counts 256-pixel tiles, as openstreetmap.org
/// does, so `map=16/36.9695/-121.9525` there shows the same place. Over a
/// map, a drawing's numbers are positions on this frame, 0–100 across and
/// 0–75 down. See docs/message-format.md, "Map background".
class DrawingMap {
  static const width = 400.0;
  static const height = 300.0;

  /// The zooms a writer snaps to: about a continent down to a building.
  static const minZoom = 3;
  static const maxZoom = 18;
  static const _maxLatitude = 85.05112878;

  final int zoom;
  final double lat, lon;
  final DrawingMapType type;

  const DrawingMap({
    required this.zoom,
    required this.lat,
    required this.lon,
    this.type = DrawingMapType.standard,
  });

  /// [zoom] to a whole step and the centre to the 4 decimals a message
  /// carries, so the frame drawn on is exactly the one everyone receives.
  factory DrawingMap.snap({
    required double zoom,
    required double lat,
    required double lon,
    DrawingMapType type = DrawingMapType.standard,
  }) {
    double round4(double v) => (v * 1e4).round() / 1e4;
    return DrawingMap(
      zoom: zoom.round().clamp(minZoom, maxZoom),
      lat: round4(lat.clamp(-_maxLatitude, _maxLatitude)),
      lon: round4((lon + 180) % 360 - 180),
      type: type,
    );
  }

  static final _line = RegExp(
    r'^map=(\d{1,2})/(-?\d{1,2}(?:\.\d{1,7})?)/(-?\d{1,3}(?:\.\d{1,7})?)'
    r'(?:/([a-z]))?$',
    caseSensitive: false,
  );

  /// The map in a message's [line], or null when it isn't one.
  static DrawingMap? tryParse(String line) {
    final m = _line.firstMatch(line.trim());
    if (m == null) return null;
    final zoom = int.parse(m.group(1)!);
    final lat = double.parse(m.group(2)!);
    final lon = double.parse(m.group(3)!);
    if (zoom > maxZoom || lat.abs() > _maxLatitude || lon.abs() > 180) {
      return null;
    }
    return DrawingMap(
      zoom: zoom,
      lat: lat,
      lon: lon,
      type: DrawingMapType.fromLetter(m.group(4) ?? ''),
    );
  }

  String toLine() {
    String n(double v) {
      var s = v.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
      if (s == '-0') s = '0';
      return s;
    }

    final type = this.type.letter.isEmpty ? '' : '/${this.type.letter}';
    return 'map=$zoom/${n(lat)}/${n(lon)}$type';
  }

  DrawingMap withType(DrawingMapType type) =>
      DrawingMap(zoom: zoom, lat: lat, lon: lon, type: type);

  /// How far the frame reaches across.
  double get metersAcross =>
      width * 156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);

  /// Web Mercator, with the whole world 0–1 across and down.
  static ({double x, double y}) project(double lat, double lon) {
    final s = math.sin(lat.clamp(-_maxLatitude, _maxLatitude) * math.pi / 180);
    return (
      x: (lon + 180) / 360,
      y: 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi),
    );
  }

  double get _worldPixels => 256 * math.pow(2, zoom).toDouble();

  /// A point on this frame, in map pixels from its top left, on the world.
  ({double x, double y}) toWorld(({double x, double y}) p) {
    final c = project(lat, lon);
    return (
      x: c.x + (p.x - width / 2) / _worldPixels,
      y: c.y + (p.y - height / 2) / _worldPixels,
    );
  }

  /// A world point on this frame, in map pixels from its top left.
  ({double x, double y}) fromWorld(({double x, double y}) w) {
    final c = project(lat, lon);
    return (
      x: (w.x - c.x) * _worldPixels + width / 2,
      y: (w.y - c.y) * _worldPixels + height / 2,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DrawingMap &&
      other.zoom == zoom &&
      other.lat == lat &&
      other.lon == lon &&
      other.type == type;

  @override
  int get hashCode => Object.hash(zoom, lat, lon, type);
}
