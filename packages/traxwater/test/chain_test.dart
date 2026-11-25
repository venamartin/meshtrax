import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:traxwater/src/wrm.dart' show tileDeg;
import 'package:traxwater/traxwater.dart';

import 'support/synthetic.dart';

/// Two columns of tiles joined at the bottom, the way between S and G:
///
///     row 404   S  G
///     row 403   A  F
///     row 402   B  E
///     row 401   C  D
///
/// A, F, B and E have a strip of water down the middle of them, and C and D
/// are all water. In [_wall], S and G are strips too: the tiles touch, but
/// their water doesn't. In [_shallow], it does, through water too shallow
/// for the boat.
Map<String, WaterTile> _tiles(List<Water> s, List<Water> g) => {
  for (final t in [
    waterTile(800, 404, s),
    waterTile(801, 404, g),
    for (final iy in [402, 403]) ...[
      waterTile(800, iy, [water(0.25, 0, 0.5, 1)]),
      waterTile(801, iy, [water(0.25, 0, 0.5, 1)]),
    ],
    waterTile(800, 401, [water(0, 0, 1, 1)]),
    waterTile(801, 401, [water(0, 0, 1, 1)]),
  ])
    tileName(t.ix, t.iy): t,
};

final _wall = _tiles([water(0.25, 0, 0.5, 1)], [water(0.25, 0, 0.5, 1)]);
final _shallow = _tiles(
  [water(0, 0, 0.75, 1), water(0.75, 0, 1, 1, depth: 1)],
  [water(0, 0, 0.25, 1, depth: 1), water(0.25, 0, 1, 1)],
);

final _s = at(800, 404, 0.375, 0.5), _g = at(801, 404, 0.375, 0.5);

WaterTrip _trip(
  Map<String, WaterTile> tiles, {
  LatLon? to,
  int maxTriangles = 1 << 30,
}) => routeOnWater(
  _s,
  to ?? _g,
  hasTile: (ix, iy) => tiles.containsKey(tileName(ix, iy)),
  tileAt: (ix, iy) => tiles[tileName(ix, iy)],
  options: const WaterRouteOptions(offLandNm: null),
  when: DateTime.utc(2026, 11, 25),
  maxTriangles: maxTriangles,
);

double _south(WaterTrip trip) =>
    trip.waypoints.map((p) => p.lat).reduce(math.min);

void main() {
  const row402 = 402 * tileDeg - 90;

  test('goes round where tiles touch but their water doesn\'t', () {
    final trip = _trip(_wall);
    expect(trip.endsShort, isNull);
    expect(trip.stats.searches, 1);
    expect(trip.outsideM, lessThan(0.01));
    expect(_south(trip), lessThan(row402 + 1e-6));
  });

  test('follows the deep water on past the tiles it loads first', () {
    final trip = _trip(_shallow);
    expect(trip.endsShort, isNull);
    expect(trip.stats.searches, 2);
    expect(trip.outsideM, lessThan(0.01));
    expect(_south(trip), lessThan(row402 + 1e-6));
  });

  test('ends short as too long where the way takes too many triangles', () {
    // S and G take 4 triangles each, A and F 2: B and the rest don't fit.
    final trip = _trip(_shallow, maxTriangles: 12);
    expect(trip.endsShort?.reason, EndsShortReason.tooLong);
    expect(trip.endsShort!.remainingM, greaterThan(0));
    expect(trip.stats.searches, 2);
  });

  test('ends short where no water joins the ends', () {
    final touching = {
      for (final t in [
        waterTile(800, 404, [water(0.25, 0, 0.5, 1)]),
        waterTile(801, 404, [water(0.25, 0, 0.5, 1)]),
      ])
        tileName(t.ix, t.iy): t,
    };
    final trip = _trip(touching);
    expect(trip.endsShort?.reason, EndsShortReason.noConnection);
    expect(trip.stats.searches, 1);

    final apart = {
      for (final t in [
        waterTile(800, 404, [water(0, 0, 1, 1)]),
        waterTile(810, 404, [water(0, 0, 1, 1)]),
      ])
        tileName(t.ix, t.iy): t,
    };
    final far = _trip(apart, to: at(810, 404, 0.5, 0.5));
    expect(far.endsShort?.reason, EndsShortReason.noConnection);
    expect(far.endsShort!.remainingM, greaterThan(200000));
    expect(far.stats.searches, 1);
  });

  test('an end more than two tiles from any tile', () {
    expect(
      () => _trip(_wall, to: at(805, 404, 0.5, 0.5)),
      throwsA(
        isA<WaterRoutingException>().having(
          (e) => e.problem,
          'problem',
          WaterRoutingProblem.noTiles,
        ),
      ),
    );
  });
}
