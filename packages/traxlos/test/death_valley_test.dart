import 'dart:io';

import 'package:test/test.dart';
import 'package:traxlos/traxlos.dart';

import 'support/fixtures.dart';

/// Real z13 tiles from the production contours packs (test/fixtures).
void main() {
  late Directory dir;
  late String feet, metres;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('traxlos_dv');
    // Leaf directories, as in the real packs.
    feet = fixturePack('norcal-contours-20ft', dir, leafSize: 8);
    metres = fixturePack('norcal-contours-10m', dir);
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  ContourTerrain terrain([List<String>? packs]) => ContourTerrain(
    contours: [
      for (final p in packs ?? [feet]) ContourPack(p, coverage: deathValley),
    ],
  );

  group('Dantes View to Badwater (3.8 km)', () {
    test('today\'s tiles never give Clear: Badwater is below the lowest '
        'line', () {
      final t = terrain();
      for (final (a, b) in [(1.5, 1.5), (2.5, 1.5), (6.0, 6.0), (30.0, 30.0)]) {
        for (final flip in [false, true]) {
          final ends = [
            LinkEnd(dantesView, antennaM: a),
            LinkEnd(badwater, antennaM: b),
          ];
          final r = flip
              ? t.lineOfSight(ends[1], ends[0])
              : t.lineOfSight(ends[0], ends[1]);
          expect(r.verdict, Verdict.unknown, reason: '$a/$b $flip');
          final end = flip ? r.fromGround : r.toGround;
          expect(end.issue, HeightIssue.belowLowestContour);
        }
      }
    });

    test('with Badwater\'s true height it is Blocked by about 76 m near '
        '3.3 km', () {
      final t = terrain();
      final r = t.lineOfSight(
        const LinkEnd(dantesView),
        const LinkEnd(badwater, groundM: badwaterGroundM),
      );
      expect(r.verdict, Verdict.blocked);
      expect(r.distanceM, closeTo(3786, 2));
      expect(r.deciding!.distanceM, closeTo(3300, 100));
      expect(r.deciding!.aboveLineM, closeTo(76, 3));
      expect(r.nearRadio, NearRadio.none);
      expect(r.fromGround.source, HeightSource.contours);
      expect(r.credits, ['USGS 3DEP']);
      // The same with Dantes View's lidar height.
      final lidar = t.lineOfSight(
        const LinkEnd(dantesView, groundM: 1670.1),
        const LinkEnd(badwater, groundM: badwaterGroundM),
      );
      expect(lidar.verdict, Verdict.blocked);
      expect(lidar.deciding!.aboveLineM, closeTo(76, 3));
    });

    test('the 10 m pack can\'t tell Badwater\'s height either', () {
      final g = terrain([metres]).groundAt(badwater);
      expect(g.groundM, isNull);
      expect(g.issue, HeightIssue.belowLowestContour);
    });
  });

  test('Dantes View to Furnace Creek (29.6 km) with Furnace Creek\'s true '
      'height: Clear, decided by the ground next to Furnace Creek', () {
    final r = terrain().lineOfSight(
      const LinkEnd(dantesView),
      const LinkEnd(furnaceCreek, groundM: -57.5),
      frequencyMHz: 910.525,
    );
    expect(r.verdict, Verdict.clear);
    expect(r.distanceM, closeTo(29570, 10));
    expect(r.nearRadio, NearRadio.to);
    expect(
      r.beyondNearGround!.aboveLineM,
      lessThan(-r.beyondNearGround!.neededM),
    );
  });

  test('across the salt pan, where the pack has no tile: no lines, not '
      '"not downloaded"', () {
    final west = destination(badwater, 270, 4000);
    expect(fixtureAbsent('norcal-contours-20ft'), contains('1437/3210'));
    final r = terrain().lineOfSight(
      const LinkEnd(badwater, groundM: badwaterGroundM),
      LinkEnd(west, groundM: -84.8),
    );
    expect(r.notDownloaded, isEmpty);
    expect(r.verdict, isNot(Verdict.unknown));
    expect(r.profile.kinds.where((k) => k & PointKind.crossing != 0), isEmpty);
  });

  test('a line along a tile edge counts each crossing once', () {
    final t = terrain();
    const edge = 1440 / 8192 * 360 - 180;
    List<(double, double)> crossings(double eastM) {
      final lon = edge + eastM / (111320 * 0.8068);
      final r = t.lineOfSight(
        LinkEnd(Geo(36.200, lon), groundM: 1000),
        LinkEnd(Geo(36.245, lon), groundM: 1000),
      );
      return [
        for (var i = 0; i < r.profile.kinds.length; i++)
          if (r.profile.kinds[i] & PointKind.crossing != 0)
            (r.profile.distancesM[i], r.profile.groundM[i]),
      ];
    }

    final on = crossings(0);
    expect(on.length, greaterThan(150));
    // A hilltop's line touches the edge line once without crossing it: it
    // keeps its height, between two lower crossings of the same line.
    final touches = [
      for (var i = 1; i + 1 < on.length; i++)
        if (on[i - 1].$2 == on[i + 1].$2 && on[i - 1].$2 < on[i].$2) on[i],
    ];
    expect(touches, isNotEmpty);
    // No line counted from both tiles.
    for (var i = 1; i < on.length; i++) {
      expect(
        on[i].$2 == on[i - 1].$2 && on[i].$1 - on[i - 1].$1 < 1.5,
        isFalse,
      );
    }
    // 0.1 m either side meets the same lines, give or take one hilltop
    // whose tip touches the edge.
    for (final side in [-0.1, 0.1]) {
      expect((crossings(side).length - on.length).abs(), lessThanOrEqualTo(1));
    }
  });

  test('past the end of the downloaded area: can\'t tell, with the '
      'stretch', () {
    final t = ContourTerrain(
      contours: [
        ContourPack(feet, coverage: box(36.10, -117.00, 36.60, -116.70)),
      ],
    );
    final east = destination(dantesView, 90, 6000);
    final r = t.lineOfSight(
      const LinkEnd(dantesView),
      LinkEnd(east, groundM: 600),
    );
    expect(r.verdict, Verdict.unknown);
    expect(r.unknownReasons, {UnknownReason.notDownloaded});
    final s = r.notDownloaded.single;
    expect(s.startM, closeTo(2390, 30));
    expect(s.endM, closeTo(6000, 1));
    expect(s.start.lon, closeTo(-116.70, 0.001));
  });

  group('end heights from rays', () {
    test('against USGS lidar spot heights', () {
      final t = terrain();
      expect(t.groundAt(dantesView).groundM, closeTo(1670.1, 8));
      expect(t.groundAt(blackMountainsSlope).groundM, closeTo(1476.1, 3));
    });

    test('the salt pan is below the lowest line: can\'t tell', () {
      final t = terrain();
      for (final p in [badwater, saltPan]) {
        expect(t.groundAt(p).issue, HeightIssue.belowLowestContour);
      }
    });
  });

  test('the 20 ft pack wins where both are installed', () {
    final end = destination(badwater, 90, 1200);
    List<double> levels(List<String> packs) {
      final r = terrain(packs).lineOfSight(
        const LinkEnd(badwater, groundM: badwaterGroundM),
        LinkEnd(end, groundM: 500),
      );
      return [
        for (var i = 0; i < r.profile.kinds.length; i++)
          if (r.profile.kinds[i] & PointKind.crossing != 0)
            r.profile.groundM[i],
      ];
    }

    final both = levels([feet, metres]);
    expect(both, isNotEmpty);
    for (final l in both) {
      expect((l / 0.3048).round() % 20, 0);
      expect(l / 0.3048, closeTo((l / 0.3048).roundToDouble(), 1e-6));
    }
    final m = levels([metres]);
    expect(m, isNotEmpty);
    for (final l in m) {
      expect(l % 10, 0);
    }
  });
}
