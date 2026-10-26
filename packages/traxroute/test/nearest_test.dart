import 'dart:io';

import 'package:test/test.dart';
import 'package:traxroute/traxroute.dart';

/// A straight-line world: any path type reaches latitudes up to its limit,
/// so the paved limit is the nearest point a paved route can reach.
class FakeEngine implements RoutingEngine {
  final Map<PathType, double> reach;
  int calls = 0;

  FakeEngine(this.reach);

  @override
  Future<RouteResult> route(RouteRequest request) async {
    calls++;
    final end = request.destination;
    if (end.lat > reach[request.pathType]!) {
      throw const RouteError('No path could be found for input');
    }
    final start = request.points.first;
    final points = [
      for (var i = 0; i <= 100; i++)
        (lat: start.lat + (end.lat - start.lat) * i / 100, lon: start.lon),
    ];
    return RouteResult(
      pathType: request.pathType,
      points: points,
      elevations: const [],
      elevationIntervalM: 30,
      km: kmBetween(start, end),
      seconds: 0,
      maneuvers: const [],
      kmShortOfDestination: kmBetween(points.last, end),
    );
  }

  @override
  Future<void> open(File tiles) async {}

  @override
  Future<void> close() async {}
}

void main() {
  const start = (lat: 38.0, lon: -107.7);
  const summit = (lat: 38.1, lon: -107.7);

  test('a reachable destination is a plain route', () async {
    final engine = FakeEngine({
      PathType.paved: 39,
      PathType.dirt: 39,
      PathType.hiking: 39,
    });
    final r = await routeOrNearest(
      engine,
      const RouteRequest([start, summit], PathType.paved),
    );
    expect(r.reachesDestination, isTrue);
    expect(engine.calls, 1);
  });

  test('stops at the nearest point the chosen type reaches', () async {
    final engine = FakeEngine({
      PathType.paved: 38.04,
      PathType.dirt: 38.08,
      PathType.hiking: 39,
    });
    final paved = await routeOrNearest(
      engine,
      const RouteRequest([start, summit], PathType.paved),
    );
    expect(paved.points.last.lat, closeTo(38.04, 0.002));
    expect(paved.kmShortOfDestination, closeTo(6.7, 0.3));
    expect(engine.calls, lessThan(15));
    final jeep = await routeOrNearest(
      engine,
      const RouteRequest([start, summit], PathType.dirt),
    );
    expect(jeep.points.last.lat, closeTo(38.08, 0.002));
  });

  test('no looser route either: the error stands', () async {
    final engine = FakeEngine({
      PathType.paved: 38.04,
      PathType.dirt: 38.04,
      PathType.hiking: 38.04,
    });
    expect(
      () => routeOrNearest(
        engine,
        const RouteRequest([start, summit], PathType.hiking),
      ),
      throwsA(isA<RouteError>()),
    );
  });
}
