import 'dart:math' as math;

/// A WGS84 coordinate.
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'LatLng(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

/// An axis-aligned WGS84 bounding box. Does not handle the antimeridian.
class LatLngBounds {
  final double south;
  final double west;
  final double north;
  final double east;

  const LatLngBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  /// Parses a `[west, south, east, north]` array, as used in the pack index.
  factory LatLngBounds.fromList(List<Object?> wsen) {
    final v = wsen.map((e) => (e as num).toDouble()).toList();
    if (v.length != 4) {
      throw FormatException('bbox must have 4 numbers, got ${v.length}');
    }
    return LatLngBounds(west: v[0], south: v[1], east: v[2], north: v[3]);
  }

  List<double> toList() => [west, south, east, north];

  LatLng get center => LatLng((south + north) / 2, (west + east) / 2);

  bool contains(LatLng p) =>
      p.latitude >= south &&
      p.latitude <= north &&
      p.longitude >= west &&
      p.longitude <= east;

  bool intersects(LatLngBounds o) =>
      o.west <= east && o.east >= west && o.south <= north && o.north >= south;

  /// Fraction of [o]'s area covered by this box, 0..1, in degree space.
  double coverageOf(LatLngBounds o) {
    final w = math.min(east, o.east) - math.max(west, o.west);
    final h = math.min(north, o.north) - math.max(south, o.south);
    final area = (o.east - o.west) * (o.north - o.south);
    if (w <= 0 || h <= 0 || area <= 0) return 0;
    return (w * h) / area;
  }

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds &&
      other.south == south &&
      other.west == west &&
      other.north == north &&
      other.east == east;

  @override
  int get hashCode => Object.hash(south, west, north, east);

  @override
  String toString() => 'LatLngBounds(w $west, s $south, e $east, n $north)';
}
