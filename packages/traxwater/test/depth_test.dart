import 'package:test/test.dart';
import 'package:traxwater/traxwater.dart';

import 'support/fixture.dart' show ft;
import 'support/synthetic.dart';

/// Deep water either side of a canal charted in two bands, 6–18 ft and then
/// 6–12 ft (1.8–5.4 and 1.8–3.6 m), as the charts give the Erie Canal.
final _canal = waterTile(800, 404, [
  water(0, 0, 0.3, 1),
  water(0.3, 0, 0.5, 1, depth: 1.8, to: 5.4),
  water(0.5, 0, 0.7, 1, depth: 1.8, to: 3.6),
  water(0.7, 0, 1, 1),
]);

WaterTrip _trip(double draftFt, double underKeelFt) => routeOnWater(
  at(800, 404, 0.15, 0.5),
  at(800, 404, 0.85, 0.5),
  hasTile: (ix, iy) => ix == 800 && iy == 404,
  tileAt: (ix, iy) => _canal,
  options: WaterRouteOptions(
    draftM: draftFt * ft,
    underKeelM: underKeelFt * ft,
    offLandNm: null,
  ),
  when: DateTime.utc(2026, 11, 25),
);

void main() {
  test('a band too shallow for the boat ends the trip short, with the band '
      'and the deepest draft that gets through', () {
    final short = _trip(6, 2).endsShort!;
    expect(short.reason, EndsShortReason.depth);
    expect(short.deepestWayM, closeTo(1.8, 1e-6));
    expect(short.deepestWayToM, closeTo(3.6, 1e-6));
    expect(short.deepestDraftM! / ft, closeTo(4.07, 0.01));
  });

  test('a trip through bands gives the band at its least depth', () {
    final trip = _trip(6, 0);
    expect(trip.endsShort, isNull);
    expect(trip.leastDepthM, closeTo(1.8, 1e-6));
    expect(trip.leastDepthToM, closeTo(3.6, 1e-6));
  });
}
