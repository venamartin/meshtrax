import 'dart:io';

import 'package:test/test.dart';
import 'package:traxroute/traxroute.dart';

/// End to end on real data, when the Pi has it: VALHALLA_SERVICE is the
/// valhalla_service program (3.9.x) and SAN_JUANS_BUNDLE the test region's
/// routing bundle (.tar.gz) from traxmapmaker's local catalogue.
void main() {
  final service = Platform.environment['VALHALLA_SERVICE'];
  final bundle = Platform.environment['SAN_JUANS_BUNDLE'];
  final skip = service == null || bundle == null
      ? 'set VALHALLA_SERVICE and SAN_JUANS_BUNDLE'
      : null;

  const ouray = (lat: 38.0228, lon: -107.6714);
  const silverton = (lat: 37.8119, lon: -107.6645);
  const campBird = (lat: 37.9706, lon: -107.7253);
  const boxCanyonFalls = (lat: 38.0179, lon: -107.6727);
  const sneffelsSummit = (lat: 38.0038, lon: -107.7923);

  group('San Juans through valhalla_service', skip: skip, () {
    late Directory tmp;
    late ValhallaServiceEngine engine;

    setUpAll(() async {
      tmp = Directory.systemTemp.createTempSync('traxroute-e2e');
      final store = RoutingStore(Directory('${tmp.path}/routing'));
      await store.install('test', {'test/san-juans': (File(bundle!), 'x')});
      engine = ValhallaServiceEngine(
        executable: service!,
        workDir: Directory('${tmp.path}/engine'),
        port: 8772,
      );
      await engine.open(store.tileFile!);
    });
    tearDownAll(() async {
      await engine.close();
      tmp.deleteSync(recursive: true);
    });

    test('each path type routes', () async {
      final paved = await engine.route(
        const RouteRequest([ouray, silverton], PathType.paved),
      );
      final jeep = await engine.route(
        const RouteRequest([ouray, campBird], PathType.dirtAndJeep),
      );
      final hike = await engine.route(
        const RouteRequest([ouray, boxCanyonFalls], PathType.hiking),
      );
      for (final r in [paved, jeep, hike]) {
        expect(r.reachesDestination, isTrue, reason: '${r.pathType}');
        expect(r.elevations, isNotEmpty);
      }
      expect(paved.km, inInclusiveRange(30, 45));
      expect(jeep.km, inInclusiveRange(5, 15));
      expect(hike.km, lessThan(3));
      expect(paved.climb.up, greaterThan(500));
    });

    test('a summit is out of reach by car: the route stops short', () async {
      const request = RouteRequest([ouray, sneffelsSummit], PathType.paved);
      expect(() => engine.route(request), throwsA(isA<RouteError>()));
      final r = await routeOrNearest(engine, request);
      expect(r.reachesDestination, isFalse);
      expect(r.kmShortOfDestination, inInclusiveRange(0.3, 15));
      final jeep = await routeOrNearest(
        engine,
        const RouteRequest([ouray, sneffelsSummit], PathType.dirtAndJeep),
      );
      expect(
        jeep.kmShortOfDestination,
        lessThan(r.kmShortOfDestination),
        reason: 'dirt roads get closer to the summit than pavement',
      );
    });

    test('routes are quick', () async {
      final s = Stopwatch()..start();
      await engine.route(
        const RouteRequest([ouray, silverton], PathType.dirtAndJeep),
      );
      expect(s.elapsedMilliseconds, lessThan(2000));
    });
  });
}
