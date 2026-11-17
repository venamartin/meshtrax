import 'dart:io';

import 'package:test/test.dart';
import 'package:traxlos/traxlos.dart';

import 'support/fixtures.dart';
import 'support/mvt_writer.dart';

const ft = 0.3048;
const interval = 20 * ft;

/// A square ring of half-size [r] around the synthetic tile's centre.
Line ring(num ele, int r) => (
  ele,
  [
    (2048 - r, 2048 - r),
    (2048 + r, 2048 - r),
    (2048 + r, 2048 + r),
    (2048 - r, 2048 + r),
    (2048 - r, 2048 - r),
  ],
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('traxlos_terrain'));
  tearDown(() => dir.deleteSync(recursive: true));

  ContourTerrain terrainOf(
    List<Line> lines, {
    List<List<List<Geo>>>? coverage,
    List<String> peakPacks = const [],
  }) {
    final path = syntheticPack(dir, 'c', {(tx, ty): contourTile(lines)});
    return ContourTerrain(
      contours: [ContourPack(path, coverage: coverage ?? tileSquare())],
      peakPacks: peakPacks,
    );
  }

  /// Across the tile at y = 2048 from x0 to x1, ends at the given ground.
  LineOfSight across(
    ContourTerrain t,
    int x0,
    int x1, {
    double ground = 28,
    double antenna = 2,
  }) => t.lineOfSight(
    LinkEnd(at(x0.toDouble(), 2048), antennaM: antenna, groundM: ground),
    LinkEnd(at(x1.toDouble(), 2048), antennaM: antenna, groundM: ground),
  );

  List<(double, double, int)> points(LineOfSight r, int kind) => [
    for (var i = 0; i < r.profile.kinds.length; i++)
      if (r.profile.kinds[i] & kind != 0)
        (r.profile.distancesM[i], r.profile.groundM[i], r.profile.kinds[i]),
  ];

  group('profile', () {
    test('straight slopes between lines of different heights', () {
      final t = terrainOf([vertical(100, 1000), vertical(120, 1500)]);
      final r = across(t, 500, 2000);
      final crossings = points(r, PointKind.crossing);
      expect(crossings.map((p) => p.$2), [100 * ft, 120 * ft]);
      final mid = (crossings[0].$1 + crossings[1].$1) / 2;
      expect(r.profile.groundAt(mid), closeTo(110 * ft, 1e-9));
      // Every gap is filled at least every 50 m for the earth's curve.
      final d = r.profile.distancesM;
      for (var i = 1; i < d.length; i++) {
        expect(d[i] - d[i - 1], lessThanOrEqualTo(50.001));
      }
    });

    test('a hill between two crossings of the same line rises where the '
        'slopes meet, at most one interval', () {
      final t = terrainOf([
        vertical(100, 800),
        vertical(120, 1300),
        vertical(120, 2700),
        vertical(100, 3200),
      ]);
      final r = across(t, 500, 3500);
      final apex = points(r, PointKind.apex).single;
      expect(apex.$2, closeTo(120 * ft + interval, 1e-9));
      expect(apex.$3 & PointKind.crest, isNot(0));
      final c = points(r, PointKind.crossing);
      expect(apex.$1, closeTo((c[1].$1 + c[2].$1) / 2, 0.01));
    });

    test('a valley the same way down', () {
      final t = terrainOf([
        vertical(120, 800),
        vertical(100, 1300),
        vertical(100, 2700),
        vertical(120, 3200),
      ]);
      final apex = points(across(t, 500, 3500), PointKind.apex).single;
      expect(apex.$2, closeTo(100 * ft - interval, 1e-9));
      expect(apex.$3 & PointKind.crest, 0);
    });

    test('Clear allows for a hilltop one interval higher than drawn', () {
      final t = terrainOf([
        vertical(100, 800),
        vertical(120, 1300),
        vertical(120, 2700),
        vertical(100, 3200),
      ]);
      // The line passes 11 m over the drawn hilltop: more than the room
      // the signal needs there (about 8.4 m), less than that plus 6.1 m.
      final r = across(t, 500, 3500, ground: 51.7);
      expect(r.verdict, Verdict.marginal);
      expect(r.deciding!.crest, isTrue);
      expect(-r.deciding!.aboveLineM, greaterThan(r.deciding!.neededM));
      expect(across(t, 500, 3500, ground: 58).verdict, Verdict.clear);
    });

    test('a line the path only touches keeps its height, and the slopes '
        'either side become uncertain', () {
      final t = terrainOf([
        vertical(100, 1000),
        (120, [(1300, 1200), (1500, 2048), (1700, 1200)]),
        vertical(100, 2000),
      ]);
      final r = across(t, 500, 2500);
      final crossings = points(r, PointKind.crossing);
      expect(crossings.map((p) => p.$2), [100 * ft, 120 * ft, 100 * ft]);
      expect(r.uncertain, hasLength(2));
      expect(r.uncertain.first.startM, greaterThan(crossings[0].$1));
      expect(r.uncertain.last.endM, lessThan(crossings[2].$1));
    });

    test('both radios in one place: nothing in the way', () {
      final t = terrainOf([vertical(100, 1000)]);
      final r = t.lineOfSight(
        LinkEnd(at(500, 2048), groundM: 20),
        LinkEnd(at(500, 2048), groundM: 20),
      );
      expect(r.distanceM, 0);
      expect(r.verdict, Verdict.clear);
    });

    test('a step of more than one interval may hide lines', () {
      final t = terrainOf([vertical(100, 1000), vertical(140, 1500)]);
      final r = across(t, 500, 2000);
      expect(r.uncertain, hasLength(1));
    });
  });

  group('coverage', () {
    final lines = [vertical(100, 1000), vertical(120, 2000)];

    test('a missing tile inside the outline means no lines there', () {
      final t = terrainOf(lines, coverage: tileSquare(0, 8192));
      final r = across(t, 500, 4096 + 2000, ground: 40);
      expect(r.notDownloaded, isEmpty);
      expect(r.verdict, isNot(Verdict.unknown));
    });

    test('outside every outline is not downloaded: can\'t tell', () {
      final t = terrainOf(lines);
      final r = across(t, 500, 4096 + 2000, ground: 40);
      expect(r.verdict, Verdict.unknown);
      expect(r.unknownReasons, {UnknownReason.notDownloaded});
      final s = r.notDownloaded.single;
      expect(s.startM, closeTo(distanceM(at(500, 2048), at(4096, 2048)), 1));
      expect(s.endM, closeTo(r.distanceM, 1e-6));
      expect(r.profile.groundAt(s.startM + 10), isNaN);
    });
  });

  group('end heights', () {
    test('between the nearest lines of the two levels around the point', () {
      final t = terrainOf([
        vertical(80, 500),
        vertical(100, 1000),
        vertical(120, 2000),
        vertical(140, 2500),
      ]);
      final g = t.groundAt(at(1250, 2048));
      expect(g.source, HeightSource.contours);
      // 250 and 750 units away: a quarter of the way up.
      expect(g.groundM, closeTo(105 * ft, 0.01));
    });

    test('inside a closed hill: the level plus slope times distance, at '
        'most one interval', () {
      final t = terrainOf([ring(200, 300), ring(180, 600)]);
      expect(
        t.groundAt(at(2048, 2048)).groundM,
        closeTo(200 * ft + interval, 1e-6),
      );
    });

    test('inside a closed pit the same way down', () {
      final t = terrainOf([ring(200, 300), ring(220, 600)]);
      expect(
        t.groundAt(at(2048, 2048)).groundM,
        closeTo(200 * ft - interval, 1e-6),
      );
    });

    test('inside a pit at one of the lowest lines: can\'t tell, it may be '
        'below sea level', () {
      for (final level in [20, 40, 60]) {
        final t = terrainOf([ring(level, 300), ring(level + 20, 600)]);
        final g = t.groundAt(at(2048, 2048));
        expect(g.groundM, isNull, reason: '$level ft');
        expect(g.issue, HeightIssue.belowLowestContour);
      }
      final t = terrainOf([ring(80, 300), ring(100, 600)]);
      expect(
        t.groundAt(at(2048, 2048)).groundM,
        closeTo(80 * ft - interval, 1e-6),
      );
    });

    test('a given height wins; a fallback only where the contours can\'t '
        'tell', () {
      final pit = terrainOf([ring(20, 300), ring(40, 600)]);
      final r = pit.lineOfSight(
        LinkEnd(at(2048, 2048), groundM: -10, groundIsFallback: true),
        LinkEnd(at(2048, 3000), groundM: 30),
      );
      expect(r.fromGround.source, HeightSource.given);
      expect(r.fromGround.groundM, -10);
      final hill = terrainOf([ring(200, 300), ring(180, 600)]);
      final h = hill.lineOfSight(
        LinkEnd(at(2048, 2048), groundM: 500, groundIsFallback: true),
        LinkEnd(at(2048, 3000), groundM: 30),
      );
      expect(h.fromGround.source, HeightSource.contours);
      final given = hill.lineOfSight(
        LinkEnd(at(2048, 2048), groundM: 500),
        LinkEnd(at(2048, 3000), groundM: 30),
      );
      expect(given.fromGround.groundM, 500);
    });

    test('no lines within 15 km, or not downloaded: can\'t tell', () {
      final t = terrainOf([]);
      expect(t.groundAt(at(2048, 2048)).issue, HeightIssue.noLinesNearby);
      expect(t.groundAt(at(2048, 5000)).issue, HeightIssue.notDownloaded);
      final r = t.lineOfSight(LinkEnd(at(1000, 2048)), LinkEnd(at(3000, 2048)));
      expect(r.verdict, Verdict.unknown);
      expect(r.unknownReasons, {
        UnknownReason.fromHeight,
        UnknownReason.toHeight,
      });
      expect(r.deciding, isNull);
    });
  });

  group('peaks', () {
    final hill = [ring(200, 300), ring(180, 600)];
    const top = 200 * ft + interval; // the contours' own hilltop

    test('a named peak within 50 m sets an end\'s height when it fits the '
        'contours', () {
      for (final (ele, used) in [
        (70.0, true),
        // Up to three intervals above the contours' own top.
        (top + 2.9 * interval, true),
        (top + 3.1 * interval, false),
        (65.0, false),
      ]) {
        final t = terrainOf(
          hill,
          peakPacks: [
            peakPack(dir, tx, ty, [('Hill', ele, 2060, 2048, 'peak')]),
          ],
        );
        final r = t.lineOfSight(
          LinkEnd(at(2048, 2048)),
          LinkEnd(at(2048, 3500), groundM: 30),
        );
        expect(
          r.fromGround.source,
          used ? HeightSource.peak : HeightSource.contours,
          reason: '$ele',
        );
        if (used) {
          expect(r.fromGround.groundM, ele);
          expect(r.peaksUsed.single.name, 'Hill');
          expect(r.credits, contains('Test map credit'));
        } else {
          expect(r.fromGround.groundM, closeTo(top, 1e-6));
          expect(r.peaksUsed, isEmpty);
          expect(r.credits, isNot(contains('Test map credit')));
        }
      }
    });

    test('a named peak within 30 m of the line sets the hilltop there', () {
      for (final (y, used) in [(2060, true), (2100, false)]) {
        final t = terrainOf(
          hill,
          peakPacks: [
            peakPack(dir, tx, ty, [('Hill', 70, 2100, y, 'peak')]),
          ],
        );
        final r = across(t, 1000, 3100, ground: 50);
        final apex = points(r, PointKind.apex).single;
        expect(apex.$2, used ? 70 : closeTo(top, 1e-6), reason: '$y');
        expect(r.peaksUsed.length, used ? 1 : 0);
      }
    });
  });

  group('packs', () {
    test('each tile comes from the first pack that has it', () {
      final feet = syntheticPack(dir, 'ft', {
        (tx, ty): contourTile([vertical(100, 1000)]),
      });
      final metres = syntheticPack(dir, 'm', {
        (tx, ty): contourTile([vertical(30, 1000)], feet: false),
        (tx + 1, ty): contourTile([vertical(40, 1000)], feet: false),
      }, interval: '10m');
      List<double> levels(List<String> order) {
        final t = ContourTerrain(
          contours: [
            for (final p in order)
              ContourPack(p, coverage: tileSquare(0, 8192)),
          ],
        );
        final r = across(t, 500, 4096 + 2000, ground: 20);
        return [for (final p in points(r, PointKind.crossing)) p.$2];
      }

      expect(levels([feet, metres]), [100 * ft, 40]);
      expect(levels([metres, feet]), [30, 40]);
    });

    test('pack files are closed after each call, and a replaced pack is '
        'read afresh', () {
      final path = syntheticPack(dir, 'c', {
        (tx, ty): contourTile([vertical(100, 1000)]),
      });
      final t = ContourTerrain(
        contours: [ContourPack(path, coverage: tileSquare())],
      );
      double first() =>
          points(across(t, 500, 2000), PointKind.crossing).first.$2;
      expect(first(), 100 * ft);
      if (Platform.isLinux) {
        final open = Directory('/proc/self/fd')
            .listSync()
            .whereType<Link>()
            .map((l) {
              try {
                return l.targetSync();
              } on FileSystemException {
                return '';
              }
            });
        expect(open, isNot(contains(path)));
      }
      syntheticPack(dir, 'c', {
        (tx, ty): contourTile([vertical(140, 1000), vertical(160, 1100)]),
      });
      expect(first(), 140 * ft);
    });

    test('a pack that can\'t be read is skipped and its area counts as not '
        'downloaded', () {
      final path = syntheticPack(dir, 'c', {
        (tx, ty): contourTile([vertical(100, 1000)]),
      });
      final t = ContourTerrain(
        contours: [ContourPack(path, coverage: tileSquare())],
      );
      expect(across(t, 500, 2000).verdict, isNot(Verdict.unknown));
      File(path).deleteSync();
      final r = across(t, 500, 2000);
      expect(r.verdict, Verdict.unknown);
      expect(r.skippedPacks, [path]);
      expect(r.unknownReasons, {UnknownReason.notDownloaded});
    });
  });
}
