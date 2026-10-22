import 'package:latlong2/latlong.dart';

import '../models/app_settings.dart';

/// Distance and direction from one point to another, worded for a label on
/// a card ("2.1 km NE").
class GeoFormat {
  const GeoFormat._();

  static const _distance = Distance();
  static const _compass = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  /// A radio with no position reports 0,0.
  static bool isValidPosition(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    const epsilon = 1e-6;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat.abs() <= 90 &&
        lon.abs() <= 180;
  }

  /// One of the 8 compass points for a bearing in degrees (any range).
  static String compass8(double bearing) {
    final normalized = (bearing % 360 + 360) % 360;
    return _compass[((normalized + 22.5) ~/ 45) % 8];
  }

  /// "850 m", "2.1 km", "374 km"; "0.4 mi", "12 mi" in imperial.
  static String distanceText(double meters, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      final miles = meters / 1609.344;
      if (miles < 0.1) return '${(meters * 3.28084).round()} ft';
      return miles < 10 ? '${miles.toStringAsFixed(1)} mi' : '${miles.round()} mi';
    }
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// "34 m"; "112 ft" in imperial.
  static String heightText(double meters, UnitSystem units) =>
      units == UnitSystem.imperial
      ? '${(meters * 3.28084).round()} ft'
      : '${meters.round()} m';

  /// How far [to] is from [from], and which way.
  static GeoOffset offset(LatLng from, LatLng to, UnitSystem units) {
    final meters = _distance.as(LengthUnit.Meter, from, to);
    final bearing = _distance.bearing(from, to);
    return GeoOffset(
      meters: meters,
      bearing: bearing,
      text: '${distanceText(meters, units)} ${compass8(bearing)}',
    );
  }
}

class GeoOffset {
  final double meters;

  /// Degrees clockwise from north, -180 to 180.
  final double bearing;

  /// "2.1 km NE".
  final String text;

  const GeoOffset({
    required this.meters,
    required this.bearing,
    required this.text,
  });
}
