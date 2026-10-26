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

  test('one icon per spot: the most notable wins', () {
    final places = [
      place(2, 'amenity=toilets', ''),
      place(3, 'amenity=toilets', '', lat: 38.03),
      place(1, 'tourism=museum', 'Ouray County Museum', rank: 1),
    ];
    expect(ids(places, 15), [1, 3]);
  });
}
