import 'package:test/test.dart';
import 'package:traxwater/traxwater.dart';

import 'support/fixture.dart';

const nm = 1852.0;

void main() {
  // The builder's test router's trips over each set, compared as the
  // fixture's README says.
  for (final name in ['monterey', 'carquinez', 'antimeridian']) {
    final set = FixtureSet(name);
    group(name, () {
      for (final t in set.trips.cast<Map<String, Object?>>()) {
        test(t['name'] as String, () {
          final args = (t['args'] as List).cast<String>();
          final want = t['result'] as Map<String, Object?>;
          final trip = tripOf(set, args);
          if (want['error'] == 'no route') {
            expect(trip.endsShort, isNotNull);
            return;
          }
          expect(trip.endsShort, isNull);
          final distance = want['distance_nm'] as num;
          expect(trip.distanceM / nm, closeTo(distance, distance * 0.01));
          expect(trip.legs, hasLength(closeTo(want['legs'] as num, 3)));
          expect(trip.outsideM, lessThan(0.01));

          final through = want['through'] as Map<String, Object?>;
          expect(
            trip.securityZoneM / nm,
            closeTo(through['security_zone_nm'] as num, 0.05),
          );
          expect(
            trip.lowestClearance?.clearanceM,
            (through['lowest_clearance'] as Map)['clearance_m'],
          );

          final theirs = {
            for (final a in (through['areas'] as List).cast<Map>())
              a['id'] as String: a,
          };
          final ours = {for (final a in trip.areas) a.area.id: a};
          for (final MapEntry(key: id, value: a) in theirs.entries) {
            if ((a['nm'] as num) >= 0.05) {
              expect(ours[id]?.metres, isNotNull, reason: id);
              expect(
                ours[id]!.metres / nm,
                closeTo(a['nm'] as num, 0.05),
                reason: id,
              );
            }
            expect(_note(ours[id]?.note), a['air_draft'], reason: id);
          }
          for (final a in trip.areas) {
            if (a.metres >= 0.05 * nm || a.note != null) {
              expect(theirs, contains(a.area.id));
            }
          }

          final offLand = through['off_land'] as Map<String, Object?>?;
          expect(trip.offLand == null, offLand == null);
          if (offLand == null) return;
          final kept = trip.offLand!;
          expect(kept.reachesDistance, offLand['reaches_distance']);
          expect(
            kept.insideElsewhereM / nm,
            closeTo(offLand['nm_inside_elsewhere'] as num, 0.05),
          );
          expect(
            kept.insideInApproachesM / nm,
            closeTo(offLand['nm_inside_in_approaches'] as num, 0.05),
          );
          final stretches = (offLand['couldnt_keep'] as List).cast<Map>();
          expect(kept.couldntKeep, hasLength(stretches.length));
          for (var i = 0; i < stretches.length; i++) {
            expect(
              kept.couldntKeep[i].fromM / nm,
              closeTo(stretches[i]['from_nm'] as num, 0.05),
            );
            expect(
              kept.couldntKeep[i].metres / nm,
              closeTo(stretches[i]['nm'] as num, 0.05),
            );
          }
        });
      }
    });
  }

  final carquinez = FixtureSet('carquinez');
  const sanPabloToSuisun = ['--from=-122.42,38.01', '--to=-122.05,38.06'];

  test(
    'ends short where the only way is under a bridge lower than the mast',
    () {
      // Counted closed, the Union Pacific lift bridge (21.3 m) is lower than a
      // 25 m mast, and every way east passes under it.
      final trip = tripOf(carquinez, [
        ...sanPabloToSuisun,
        '--margin-ft',
        '0',
        '--air-draft-m',
        '25',
        '--avoid-opening-bridges',
      ]);
      final short = trip.endsShort!;
      expect(short.reason, EndsShortReason.mastHeight);
      expect(
        [for (final a in short.lowObjects) a.name],
        ['Union Pacific Railroad Lift Bridge'],
      );
      expect(trip.waypoints.last.lon, lessThan(-122.12));
      expect(short.remainingM, greaterThan(5000));
    },
  );

  test('ends short where every way on is too shallow, saying how deep the '
      'deepest is', () {
    final trip = tripOf(
      carquinez,
      sanPabloToSuisun,
      options: const WaterRouteOptions(
        draftM: 20 * ft,
        underKeelM: 0,
        offLandNm: null,
      ),
    );
    expect(trip.from.moved, EndMoved.depth);
    expect(trip.endsShort!.reason, EndsShortReason.depth);
    expect(trip.endsShort!.deepestWayM, closeTo(5.4, 0.01));
  });

  group('an end the boat can\'t use moves to the nearest water it can', () {
    final monterey = FixtureSet('monterey');
    const toMossLanding = '--to=-121.7915,36.8045';

    test('from land', () {
      final trip = tripOf(monterey, ['--from=-121.8915,36.596', toMossLanding]);
      expect(trip.from.moved, EndMoved.notInWater);
      expect(trip.from.movedM, greaterThan(100));
      expect(trip.waypoints.first, trip.from.at);
      expect(trip.endsShort, isNull);
    });

    test('from water too shallow', () {
      // Monterey harbour's 12 ft, for 12 ft and 2 ft under the keel.
      final trip = tripOf(monterey, [
        '--from=-121.8915,36.605',
        toMossLanding,
      ], options: const WaterRouteOptions(draftM: 12 * ft, offLandNm: null));
      expect(trip.from.moved, EndMoved.depth);
      expect(trip.from.depthM! / ft, closeTo(12, 0.5));
      expect(trip.endsShort, isNull);
    });
  });

  test('legs are rhumb lines, with magnetic courses from WMM2025', () {
    final when = DateTime.utc(2026, 11, 24);
    final trip = tripOf(FixtureSet('antimeridian'), [
      '--from=179.8,51.4',
      '--to=-179.8,51.4',
    ]);
    final leg = trip.legs.single;
    expect(leg.courseTrue, closeTo(90, 1e-9));
    expect(
      leg.courseMagnetic,
      closeTo((90 - magneticDeclination(51.4, 179.8, when)) % 360, 1e-9),
    );
    expect(leg.time.inSeconds, closeTo(leg.distanceM / (6 * nm / 3600), 1));
    expect(trip.magneticModelExpired, isFalse);
  });

  test('no tiles', () {
    expect(
      () => routeOnWater(
        (lat: 36.6, lon: -121.9),
        (lat: 36.8, lon: -121.8),
        (ix, iy) => null,
      ),
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

String? _note(BridgeNote? note) => switch (note) {
  BridgeNote.needsOpening => 'needs opening',
  BridgeNote.clearsClosed => 'clears closed',
  null => null,
};
