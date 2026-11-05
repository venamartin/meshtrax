import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:traxroute/src/valhalla.dart';
import 'package:traxroute/traxroute.dart';

void main() {
  const ouray = (lat: 38.0228, lon: -107.6714);
  const campBird = (lat: 37.9706, lon: -107.7253);

  test('each path type asks Valhalla for the agreed costing', () {
    expect(valhallaCosting(PathType.paved).$1, 'auto');
    expect(valhallaCosting(PathType.paved).$2, {'exclude_unpaved': true});
    expect(valhallaCosting(PathType.dirt).$1, 'auto');
    expect(valhallaCosting(PathType.dirt).$2, {
      'use_tracks': 1.0,
      'use_distance': 0.8,
      'disable_hierarchy_pruning': true,
    });
    final (costing, options) = valhallaCosting(PathType.hiking);
    expect(costing, 'pedestrian');
    expect(options, {
      'use_hills': 1.0,
      'use_tracks': 1.0,
      'max_hiking_difficulty': 3,
      'destination_only_penalty': 0,
      'use_ferry': 0.0,
    });
  });

  test('changed options change the costing; defaults add nothing', () {
    const avoidAll = RouteOptions(
      avoidHighways: true,
      avoidTolls: true,
      avoidFerries: true,
    );
    expect(valhallaCosting(PathType.paved, avoidAll).$2, {
      'exclude_unpaved': true,
      'use_highways': 0.0,
      'use_tolls': 0.0,
      'use_ferry': 0.0,
    });
    for (final (dirt, weight) in [
      (DirtPreference.fastest, 0.0),
      (DirtPreference.balanced, 0.8),
      (DirtPreference.direct, 1.0),
    ]) {
      expect(
        valhallaCosting(PathType.dirt, RouteOptions(dirt: dirt)).$2,
        containsPair('use_distance', weight),
      );
    }
    final hike = valhallaCosting(
      PathType.hiking,
      const RouteOptions(
        hardestTrail: 5,
        climbs: ClimbPreference.avoid,
        pace: HikingPace.slow,
        avoidTolls: true,
      ),
    ).$2;
    expect(hike['max_hiking_difficulty'], 5);
    expect(hike['use_hills'], 0.0);
    expect(hike['walking_speed'], 4.0);
    expect(hike, isNot(contains('use_tolls')), reason: 'walkers pay no tolls');
    expect(
      valhallaCosting(PathType.hiking, const RouteOptions()).$2,
      isNot(contains('walking_speed')),
      reason: "Normal is Valhalla's own pace",
    );
  });

  test('the request carries points, costing and heights', () {
    final req = valhallaRouteRequest(
      const RouteRequest([ouray, campBird], PathType.dirt),
    );
    expect(req['locations'], [
      {'lat': 38.0228, 'lon': -107.6714},
      {'lat': 37.9706, 'lon': -107.7253},
    ]);
    expect(req['costing'], 'auto');
    expect(req['elevation_interval'], 30);
    final direct = valhallaRouteRequest(
      const RouteRequest(
        [ouray, campBird],
        PathType.dirt,
        options: RouteOptions(dirt: DirtPreference.direct),
      ),
    );
    expect(
      (direct['costing_options'] as Map)['auto'],
      containsPair('use_distance', 1.0),
    );
  });

  test("reads Valhalla's answer: Ouray to Camp Bird Mine by dirt road", () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/ouray_camp_bird_auto.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final r = parseValhallaRoute(
      const RouteRequest([ouray, campBird], PathType.dirt),
      json,
    );
    expect(r.km, closeTo(9.492, 1e-9));
    expect(r.seconds, closeTo(1514.188, 1e-9));
    expect(r.maneuvers, hasLength(6));
    expect(r.maneuvers.first.instruction, 'Drive west on 6th Avenue.');
    expect(r.points.first.lat, closeTo(ouray.lat, 0.001));
    expect(r.elevations, hasLength(318));
    expect(r.reachesDestination, isTrue);
    expect(r.climb.up, greaterThan(400));
    expect(r.maneuvers.last.startIndex, lessThan(r.points.length));
  });

  test('a route through tiles without heights has none', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/ouray_camp_bird_auto.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    // Valhalla's answer where a region was built without elevation: about
    // -500 m, here over the last part of the route.
    final leg = (json['trip']['legs'] as List).first as Map<String, dynamic>;
    final heights = (leg['elevation'] as List).cast<num>().toList();
    for (var i = heights.length ~/ 2; i < heights.length; i++) {
      heights[i] = i.isEven ? -500.0 : -499.9;
    }
    leg['elevation'] = heights;
    final r = parseValhallaRoute(
      const RouteRequest([ouray, campBird], PathType.dirt),
      json,
    );
    expect(r.elevations, isEmpty);
    expect(r.climb, (up: 0.0, down: 0.0));
    expect(r.km, closeTo(9.492, 1e-9));
  });

  test('an error answer is a RouteError', () {
    expect(
      () => parseValhallaRoute(
        const RouteRequest([ouray, campBird], PathType.paved),
        {'error_code': 171, 'error': 'No suitable edges near location'},
      ),
      throwsA(isA<RouteError>()),
    );
  });

  test('climb ignores small wiggles', () {
    RouteResult withHeights(List<double> h) => RouteResult(
      pathType: PathType.hiking,
      points: const [(lat: 0, lon: 0)],
      elevations: h,
      elevationIntervalM: 30,
      km: 1,
      seconds: 1,
      maneuvers: const [],
      kmShortOfDestination: 0,
    );
    expect(withHeights([100, 102, 99, 101, 100]).climb, (up: 0.0, down: 0.0));
    expect(withHeights([100, 110, 105, 130, 120]).climb, (
      up: 35.0,
      down: 15.0,
    ));
    expect(withHeights([100, 103, 106, 109, 112]).climb, (up: 12.0, down: 0.0));
  });

  test('decodes encoded polylines with 6 decimals', () {
    expect(decodePolyline6('_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI'), [
      (lat: 38.5, lon: -120.2),
      (lat: 40.7, lon: -120.95),
      (lat: 43.252, lon: -126.453),
    ]);
  });
}
