import 'package:traxmap/traxmap.dart' show LatLng, LatLngBounds, MapCamera;
import 'package:traxpoi/traxpoi.dart' show PlaceData, PoiRegion;

/// A place on the map and the download it came from (for its sheet).
typedef MapPlace = ({PoiRegion region, PlaceData place});

/// Kinds the map marks and names itself, with a triangle.
const _namedByMap = {
  'natural=peak',
  'natural=volcano',
  'natural=saddle',
  'mountain_pass=yes',
  'natural=cliff',
  'natural=rock',
  'natural=stone',
};

/// The zoom (package zoom) from which the map shows [place]: places with a
/// Wikipedia article first, then named places, then unnamed ones. Null for
/// a peak, pass or cliff without an article: the map already names it
/// (Martin, 2026-10-26).
double? placeMinZoom(PlaceData place) {
  if (place.rank > 0) return 12;
  if (_namedByMap.contains(place.kind)) return null;
  return place.name.isNotEmpty ? 13 : 14;
}

/// Every place inside [bounds] in [regions]. A place in two regions' files
/// (near a border) comes once.
Future<List<MapPlace>> placesIn(
  List<PoiRegion> regions,
  LatLngBounds bounds,
) async {
  final found = <String, MapPlace>{};
  for (final region in regions) {
    final places = await region.placesIn(
      north: bounds.north,
      south: bounds.south,
      east: bounds.east,
      west: bounds.west,
    );
    for (final place in places) {
      final key =
          place.wikidata ??
          place.osm ??
          '${place.kind}|${place.name}|'
              '${place.lat.toStringAsFixed(4)},${place.lon.toStringAsFixed(4)}';
      found.putIfAbsent(key, () => (region: region, place: place));
    }
  }
  return found.values.toList();
}

/// The places to draw at [camera]: those its zoom shows, the most notable
/// first, and at most one in each [cell]-pixel square, so icons never pile
/// up.
List<MapPlace> placesToShow(
  Iterable<MapPlace> places,
  MapCamera camera, {
  double cell = 40,
}) {
  final shown = [
    for (final p in places)
      if (placeMinZoom(p.place) case final z? when camera.zoom >= z) p,
  ]..sort((a, b) => placeMinZoom(a.place)!.compareTo(placeMinZoom(b.place)!));
  final taken = <(int, int)>{};
  return [
    for (final p in shown)
      if (taken.add(_cellOf(camera, p, cell))) p,
  ];
}

(int, int) _cellOf(MapCamera camera, MapPlace p, double cell) {
  final world = camera.project(LatLng(p.place.lat, p.place.lon));
  return ((world.dx / cell).floor(), (world.dy / cell).floor());
}
