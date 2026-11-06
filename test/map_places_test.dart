import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/map_places.dart';
import 'package:traxmap/traxmap.dart' show LatLng, MapCamera;
import 'package:traxpoi/traxpoi.dart';

void main() {
  final region = PoiRegion.open();
  MapPlace place(
    int id,
    String kind,
    String name, {
    int rank = 0,
    double lat = 38.0228,
  }) => (
    region: region,
    place: PlaceData(
      id: id,
      kind: kind,
      name: name,
      lat: lat,
      lon: -107.6714,
      sources: 'osm',
      rank: rank,
    ),
  );
  List<int> ids(List<MapPlace> places, double zoom) => [
    for (final p in placesToShow(
      places,
      MapCamera(center: const LatLng(38.02, -107.67), zoom: zoom),
    ))
      p.place.id,
  ];

  test('places with an article first, then named, then unnamed', () {
    final places = [
      place(3, 'amenity=toilets', '', lat: 38.01),
      place(2, 'highway=trailhead', 'Cascade Falls', lat: 38.03),
      place(1, 'historic=mine', 'Camp Bird Mine', rank: 1),
    ];
    expect(ids(places, 11), isEmpty);
    expect(ids(places, 12), [1]);
    expect(ids(places, 13), [1, 2]);
    expect(ids(places, 14), [1, 2, 3]);
  });

  test('peaks, passes and cliffs only with an article: the map names them', () {
    expect(placeMinZoom(place(1, 'natural=peak', 'Sister Peak').place), null);
    expect(placeMinZoom(place(2, 'natural=cliff', 'Stump Wall').place), null);
    expect(
      placeMinZoom(place(3, 'mountain_pass=yes', 'Imogene Pass').place),
      null,
    );
    expect(
      placeMinZoom(place(4, 'natural=peak', 'Mount Sneffels', rank: 1).place),
      12,
    );
  });

  test('names close in, only where the map has none, never crowded', () {
    const center = LatLng(38.0228, -107.6714);
    MapCamera at(double zoom) => MapCamera(center: center, zoom: zoom);
    // Two places 60 px apart at zoom 16 inside one 120 px name square:
    // separate icons, one name.
    final z16 = at(16);
    final edge = (z16.project(center).dy / 120).floor() * 120.0;
    double latAt(double y) =>
        z16.unproject(Offset(z16.project(center).dx, y)).latitude;
    final mine = place(
      1,
      'man_made=adit',
      'Chief Ouray Mine',
      lat: latAt(edge + 10),
    );
    final falls = place(
      2,
      'waterway=waterfall',
      'Cascade Falls',
      lat: latAt(edge + 70),
    );
    final camp = place(3, 'tourism=camp_site', 'Amphitheater', lat: 38.03);
    final toilets = place(4, 'amenity=toilets', '', lat: 38.026);
    Set<int> named(MapCamera camera) => {
      for (final p in placesToName(
        placesToShow([mine, falls, camp, toilets], camera),
        camera,
      ))
        p.place.id,
    };

    expect(named(at(15)), isEmpty);
    // The map names campgrounds itself; an unnamed place has none.
    expect(named(z16), hasLength(1));
    expect(named(z16).single, anyOf(1, 2));
    expect(named(at(18)), {1, 2});
  });

  test('one icon per spot: the most notable wins', () {
    final places = [
      place(2, 'amenity=toilets', ''),
      place(3, 'amenity=toilets', '', lat: 38.03),
      place(1, 'tourism=museum', 'Ouray County Museum', rank: 1),
    ];
    expect(ids(places, 15), [1, 3]);
  });

  test('icons keep a gap: 64 px zoomed out, 40 px from zoom 14', () {
    const center = LatLng(38.0228, -107.6714);
    List<int> drawn(double zoom, double apart) {
      final camera = MapCamera(center: center, zoom: zoom);
      final y = camera.project(center).dy + apart;
      final lat = camera.unproject(Offset(camera.project(center).dx, y));
      return [
        for (final p in placesToShow([
          place(1, 'historic=mine', 'Camp Bird Mine', rank: 1),
          place(2, 'highway=trailhead', 'Cascade Falls', lat: lat.latitude),
        ], camera))
          p.place.id,
      ];
    }

    expect(drawn(13, 50), [1]);
    expect(drawn(13, 70), [1, 2]);
    // Side by side, as one per grid square allowed across a square's edge.
    expect(drawn(14, 30), [1]);
    expect(drawn(14, 45), [1, 2]);
  });
}
