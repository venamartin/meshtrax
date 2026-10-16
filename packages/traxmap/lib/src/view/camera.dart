import 'dart:math' as math;
import 'dart:ui';

import '../packs/geo.dart';

/// Map camera in Web Mercator: a centre point and a fractional zoom level.
///
/// Zoom follows MapLibre's 512px-tile convention, the same one the styles,
/// the browser viewer and the pack pipeline use: at zoom 14 a z14 tile spans
/// 512 logical pixels. (flutter_map's own zoom is one higher for the same view.)
class MapCamera {
  static const double tileSize = 512;
  static const double maxLatitude = 85.05112878;

  final LatLng center;
  final double zoom;

  const MapCamera({required this.center, required this.zoom});

  /// flutter_map (256px tiles) zoom for a package zoom: one level higher.
  /// Use when porting zoom numbers from flutter_map code such as MeshTrax.
  static double toFlutterMapZoom(double zoom) => zoom + 1;

  /// Package zoom for a flutter_map zoom: one level lower.
  static double fromFlutterMapZoom(double zoom) => zoom - 1;

  MapCamera copyWith({LatLng? center, double? zoom}) =>
      MapCamera(center: center ?? this.center, zoom: zoom ?? this.zoom);

  double get worldSize => tileSize * math.pow(2, zoom);

  /// World pixel position of [p] at this zoom.
  Offset project(LatLng p) {
    final lat = p.latitude.clamp(-maxLatitude, maxLatitude) * math.pi / 180;
    final x = (p.longitude + 180) / 360;
    final y = (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2;
    return Offset(x * worldSize, y * worldSize);
  }

  LatLng unproject(Offset world) {
    final x = world.dx / worldSize;
    final y = world.dy / worldSize;
    final lng = x * 360 - 180;
    final lat = math.atan(_sinh(math.pi * (1 - 2 * y))) * 180 / math.pi;
    return LatLng(lat, lng);
  }

  /// Screen position of [p] in a viewport of [size].
  Offset toScreen(LatLng p, Size size) =>
      project(p) - project(center) + size.center(Offset.zero);

  LatLng fromScreen(Offset screen, Size size) =>
      unproject(screen - size.center(Offset.zero) + project(center));

  LatLngBounds visibleBounds(Size size) {
    final nw = fromScreen(Offset.zero, size);
    final se = fromScreen(Offset(size.width, size.height), size);
    return LatLngBounds(
      south: se.latitude,
      west: nw.longitude,
      north: nw.latitude,
      east: se.longitude,
    );
  }

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  @override
  String toString() => 'MapCamera($center, z${zoom.toStringAsFixed(2)})';
}
