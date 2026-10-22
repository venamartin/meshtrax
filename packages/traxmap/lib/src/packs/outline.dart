import 'geo.dart';

// Outline helpers shared by the pack server's GeoJSON region files
// (picker.geojson, chart_areas.geojson).

/// A Polygon or MultiPolygon geometry as polygons, each its outer ring
/// followed by any holes, with GeoJSON's `[lon, lat]` turned into [LatLng].
List<List<List<LatLng>>> parsePolygons(Map<String, Object?> geometry) {
  List<LatLng> ring(Object? r) => [
    for (final c in r as List<Object?>)
      LatLng(
        ((c as List<Object?>)[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      ),
  ];
  List<List<LatLng>> polygon(Object? p) => [
    for (final r in p as List<Object?>) ring(r),
  ];
  final coordinates = geometry['coordinates'] as List<Object?>;
  return switch (geometry['type']) {
    'Polygon' => [polygon(coordinates)],
    'MultiPolygon' => [for (final p in coordinates) polygon(p)],
    final type => throw FormatException('unsupported geometry $type'),
  };
}

/// The box around [polygons]' outer rings.
LatLngBounds outerExtent(List<List<List<LatLng>>> polygons) {
  final points = [
    for (final p in polygons)
      if (p.isNotEmpty) ...p.first,
  ];
  if (points.isEmpty) throw const FormatException('empty outline');
  var south = points.first.latitude, north = south;
  var west = points.first.longitude, east = west;
  for (final q in points) {
    if (q.latitude < south) south = q.latitude;
    if (q.latitude > north) north = q.latitude;
    if (q.longitude < west) west = q.longitude;
    if (q.longitude > east) east = q.longitude;
  }
  return LatLngBounds(south: south, west: west, north: north, east: east);
}

/// A box's size in square degrees, for comparing boxes.
double boxArea(LatLngBounds b) => (b.east - b.west) * (b.north - b.south);

/// Whether [polygon] (its outer ring, then holes) contains [p].
bool polygonContains(List<List<LatLng>> polygon, LatLng p) {
  if (polygon.isEmpty || !_inRing(polygon.first, p)) return false;
  return !polygon.skip(1).any((hole) => _inRing(hole, p));
}

/// Even-odd ray casting in degree space: ring winding doesn't matter, and
/// it's fine because rings never cross ±180°.
bool _inRing(List<LatLng> ring, LatLng p) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.latitude > p.latitude) != (b.latitude > p.latitude) &&
        p.longitude <
            (b.longitude - a.longitude) *
                    (p.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}
