/// Routes on the water, worked out offline from the installed water-routing
/// tiles (WRM2, FINDINGS 1.11 in traxmapmaker): a triangle mesh of NOAA's
/// charted water, each triangle with its depth, distance off land, hazards,
/// survey quality, the areas it lies in and the objects over it.
///
/// For trip planning, not navigation. Pure Dart: run it in an isolate.
library;

export 'src/magnetic.dart'
    show decimalYear, magneticDeclination, magneticModelValidUntil;
export 'src/route.dart' show routeOnWater;
export 'src/trip.dart';
export 'src/wrm.dart' show WaterArea, WaterTile, ringsNm, tileName;
