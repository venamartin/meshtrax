import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/geo_format.dart';
import 'package:meshtrax/models/app_settings.dart';

void main() {
  test('compass points, including the edges', () {
    expect(GeoFormat.compass8(0), 'N');
    expect(GeoFormat.compass8(22.4), 'N');
    expect(GeoFormat.compass8(22.6), 'NE');
    expect(GeoFormat.compass8(135), 'SE');
    expect(GeoFormat.compass8(-90), 'W');
    expect(GeoFormat.compass8(-135), 'SW');
    expect(GeoFormat.compass8(359), 'N');
    expect(GeoFormat.compass8(337.6), 'N');
  });

  test('distance text, metric and imperial', () {
    expect(GeoFormat.distanceText(850, UnitSystem.metric), '850 m');
    expect(GeoFormat.distanceText(2100, UnitSystem.metric), '2.1 km');
    expect(GeoFormat.distanceText(374200, UnitSystem.metric), '374 km');
    expect(GeoFormat.distanceText(100, UnitSystem.imperial), '328 ft');
    expect(GeoFormat.distanceText(650, UnitSystem.imperial), '0.4 mi');
    expect(GeoFormat.distanceText(20000, UnitSystem.imperial), '12 mi');
  });

  test('a radio with no position reports 0,0', () {
    expect(GeoFormat.isValidPosition(0, 0), isFalse);
    expect(GeoFormat.isValidPosition(null, 15), isFalse);
    expect(GeoFormat.isValidPosition(91, 15), isFalse);
    expect(GeoFormat.isValidPosition(36.9, -121.7), isTrue);
  });

  test('offset from the radio to a point', () {
    // Watsonville to a spot 2 km north-east, and to the ocean off Point
    // Conception (the mock-up's 374 km SW).
    const me = LatLng(36.91, -121.76);
    final near =
        GeoFormat.offset(me, const LatLng(36.923858, -121.745599), UnitSystem.metric);
    expect(near.text, '2.0 km NE');
    final ocean =
        GeoFormat.offset(me, const LatLng(34.234153, -124.227803), UnitSystem.metric);
    expect(ocean.text, endsWith(' SW'));
    expect(ocean.meters, greaterThan(300000));
  });
}
