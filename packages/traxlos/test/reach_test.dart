import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:traxlos/traxlos.dart';

import 'support/fixtures.dart';
import 'support/mvt_writer.dart';

void main() {
  late Directory dir;
  late ContourTerrain dv;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('traxlos_reach');
    dv = ContourTerrain(
      contours: [
        ContourPack(
          fixturePack('norcal-contours-20ft', dir),
          coverage: deathValley,
        ),
      ],
    );
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  void expectWhole(Reach r) {
    expect(r.runs, hasLength(r.rays));
    for (final ray in r.runs) {
      expect(ray.first.startM, 0);
      expect(ray.last.endM, r.radiusM);
      for (var i = 1; i < ray.length; i++) {
        expect(ray[i].startM, ray[i - 1].endM);
        expect(ray[i].verdict, isNot(ray[i - 1].verdict));
      }
    }
    expect(r.share(Verdict.values.toSet()), closeTo(1, 1e-9));
  }

  test('from Dantes View: hidden behind the ridges, open toward the valley, '
      'with each person\'s full answer', () async {
    final progress = <double>[];
    final r = (await dv.reach(
      const LinkEnd(dantesView),
      radiusM: 3000,
      rays: 72,
      targets: const [LinkEnd(badwater), LinkEnd(blackMountainsSlope)],
      onProgress: progress.add,
    ))!;
    expectWhole(r);
    expect(r.centerGround.source, HeightSource.contours);
    expect(r.share({Verdict.blocked}), greaterThan(0.2));
    expect(r.share({Verdict.clear, Verdict.marginal}), greaterThan(0.1));
    expect(r.credits, ['USGS 3DEP']);
    // Badwater is below the lowest line; the slope point has an answer.
    expect(r.targets.map((t) => t.verdict).first, Verdict.unknown);
    expect(r.targets.last.verdict, isNot(Verdict.unknown));
    expect(r.targets.last.from, dantesView);
    expect(progress.last, 1);
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
    // To draw: one outline per patch of ground, not a slice per run, with
    // the same area as the runs.
    const open = {Verdict.clear, Verdict.marginal};
    final areas = r.areas(open);
    expect(areas, isNotEmpty);
    final runsOpen = r.runs
        .expand((ray) => ray)
        .where((x) => open.contains(x.verdict))
        .length;
    expect(areas.length, lessThan(runsOpen / 4));
    for (final a in areas) {
      expect(a.outline.first, a.outline.last);
    }
    expect(
      areas.fold(0.0, (sum, a) => sum + areaM2(a)),
      closeTo(r.share(open) * math.pi * 3000 * 3000, 0.02 * 3000 * 3000 * 3),
    );
  });

  test('from Badwater at its true height: the salt pan around is "can\'t '
      'tell", the fan to the east is not', () async {
    final r = (await dv.reach(
      const LinkEnd(badwater, groundM: badwaterGroundM),
      radiusM: 2000,
      rays: 36,
    ))!;
    expectWhole(r);
    Verdict at(double bearing, double d) => r.runs[(bearing / 10).round() % 36]
        .firstWhere((run) => run.startM <= d && d <= run.endM)
        .verdict;
    expect(at(270, 1500), Verdict.unknown); // the salt pan to the west
    expect(at(0, 1000), Verdict.unknown); // and along the valley
    expect(at(90, 1500), isNot(Verdict.unknown)); // the Black Mountains
  });

  test('from a point below the lowest line without a height: all can\'t '
      'tell', () async {
    final r = (await dv.reach(
      const LinkEnd(badwater),
      radiusM: 2000,
      rays: 8,
      targets: const [LinkEnd(dantesView)],
    ))!;
    expect(r.centerGround.issue, HeightIssue.belowLowestContour);
    expect(r.share({Verdict.unknown}), 1);
    expect(r.targets.single.verdict, Verdict.unknown);
  });

  test('stops on a flag set by another event while it runs', () async {
    var stop = false;
    Timer.run(() => stop = true);
    final progress = <double>[];
    final r = await dv.reach(
      const LinkEnd(dantesView),
      radiusM: 4500,
      rays: 3600,
      onProgress: progress.add,
      shouldStop: () => stop,
    );
    expect(stop, isTrue);
    expect(r, isNull);
    expect(progress, isNot(contains(1)));
  });

  test('stops when asked, and closes its files', () async {
    final path = syntheticPack(dir, 'flat', {
      (tx, ty): contourTile([vertical(100, 1000)]),
    });
    final t = ContourTerrain(
      contours: [ContourPack(path, coverage: tileSquare())],
    );
    var calls = 0;
    final r = await t.reach(
      LinkEnd(at(2048, 2048), groundM: 20),
      radiusM: 1500,
      rays: 3600,
      stepM: 10,
      shouldStop: () => ++calls >= 1,
    );
    expect(r, isNull);
    expect(calls, 1);
    // Files closed: the pack can go away and the next call still answers.
    File(path).deleteSync();
    final after = await t.reach(LinkEnd(at(2048, 2048), groundM: 20));
    expect(after!.share({Verdict.unknown}), 1);
  });

  test('flat ground: hand-helds are clear only close in, then marginal, and '
      'blocked by the earth\'s curve past the radio horizon', () async {
    final path = syntheticPack(dir, 'none', {(tx, ty): contourTile([])});
    final t = ContourTerrain(
      contours: [ContourPack(path, coverage: box(30, -140, 60, -100))],
    );
    final r = (await t.reach(
      LinkEnd(at(2048, 2048), groundM: 1000),
      radiusM: 12000,
      rays: 8,
      stepM: 50,
    ))!;
    for (final ray in r.runs) {
      expect(ray.map((x) => x.verdict), [
        Verdict.clear,
        Verdict.marginal,
        Verdict.blocked,
      ]);
      // The ground fills 60% of the Fresnel zone past about 75 m.
      expect(ray.first.endM, lessThan(100));
      // Two 1.5 m antennas see each other to about 10.1 km.
      expect(ray.last.startM, closeTo(10100, 100));
    }
  });

  group('areas to draw', () {
    const blocked = Verdict.blocked, clear = Verdict.clear;

    /// A reach of [rays] rays, each clear on the stretches [clearOn] gives
    /// it and blocked elsewhere, out to 10 km.
    Reach reachOf(int rays, List<(double, double)> Function(int ray) clearOn) {
      const radius = 10000.0;
      return Reach(
        center: dantesView,
        centerGround: const EndHeight(1600, HeightSource.contours),
        antennaM: 1.5,
        targetAntennaM: 1.5,
        radiusM: radius,
        stepM: 100,
        frequencyMHz: 915,
        rays: rays,
        runs: [
          for (var k = 0; k < rays; k++)
            () {
              final out = <ReachRun>[];
              var at = 0.0;
              for (final (s, e) in clearOn(k)) {
                if (s > at) out.add(ReachRun(at, s, blocked));
                out.add(ReachRun(s, e, clear));
                at = e;
              }
              if (at < radius) out.add(ReachRun(at, radius, blocked));
              return out;
            }(),
        ],
        targets: const [],
        credits: const [],
        skippedPacks: const [],
      );
    }

    /// The area the runs cover, as the areas should draw it (their edges
    /// are chords of the rays' arcs).
    double expected(Reach r) {
      final wedge = 2 * math.pi / r.rays;
      final chord = math.sin(wedge) / wedge;
      var sum = 0.0;
      for (final ray in r.runs) {
        for (final x in ray) {
          if (x.verdict == clear) {
            sum += (x.endM * x.endM - x.startM * x.startM) * wedge / 2;
          }
        }
      }
      return sum * chord;
    }

    void expectArea(Reach r, List<ReachArea> areas) {
      final want = expected(r);
      expect(
        areas.fold(0.0, (sum, a) => sum + areaM2(a)),
        closeTo(want, want * 0.002 + 1),
      );
    }

    test('one patch over several rays is one area', () {
      final r = reachOf(36, (k) => k >= 3 && k <= 8 ? [(1000, 5000)] : []);
      final areas = r.areas({clear});
      expect(areas, hasLength(1));
      expect(areas.single.holes, isEmpty);
      expectArea(r, areas);
    });

    test('ground all round: one area; a band all round leaves a hole', () {
      final disc = reachOf(36, (_) => [(0, 8000)]);
      expect(disc.areas({clear}), hasLength(1));
      expect(disc.areas({clear}).single.holes, isEmpty);
      expectArea(disc, disc.areas({clear}));
      final band = reachOf(36, (_) => [(2000, 8000)]);
      expect(band.areas({clear}), hasLength(1));
      expect(band.areas({clear}).single.holes, hasLength(1));
      expectArea(band, band.areas({clear}));
    });

    test('a patch across north is one area', () {
      final r = reachOf(36, (k) => k >= 34 || k <= 1 ? [(0, 4000)] : []);
      expect(r.areas({clear}), hasLength(1));
      expectArea(r, r.areas({clear}));
    });

    test('patches apart, or meeting only at a corner, stay apart', () {
      final apart = reachOf(
        36,
        (k) => k <= 2 || (k >= 10 && k <= 12) ? [(0, 3000)] : [],
      );
      expect(apart.areas({clear}), hasLength(2));
      expectArea(apart, apart.areas({clear}));
      final corner = reachOf(
        36,
        (k) => switch (k) {
          5 => [(1000, 2000)],
          6 => [(2000, 3000)],
          _ => [],
        },
      );
      expect(corner.areas({clear}), hasLength(2));
      expectArea(corner, corner.areas({clear}));
    });

    test('an island in a hole is an area of its own', () {
      final r = reachOf(
        36,
        (k) => k < 10
            ? [(0, 3000), if (k >= 3 && k <= 5) (4000, 5000), (6000, 10000)]
            : [(0, 10000)],
      );
      final areas = r.areas({clear});
      expect(areas, hasLength(2));
      expect(areas.map((a) => a.holes.length).toList()..sort(), [0, 1]);
      expectArea(r, areas);
    });

    test('any pattern: the areas cover just the runs', () {
      for (var seed = 0; seed < 20; seed++) {
        final random = math.Random(seed);
        final r = reachOf(72, (_) {
          final out = <(double, double)>[];
          var at = 0.0;
          while (true) {
            final s = at + random.nextInt(4) * 500.0;
            final e = s + (1 + random.nextInt(4)) * 500.0;
            if (e > 10000) break;
            out.add((s, e));
            at = e + 500;
          }
          return out;
        });
        final areas = r.areas({clear});
        for (final a in areas) {
          expect(a.outline.first, a.outline.last);
          for (final h in a.holes) {
            expect(h.first, h.last);
          }
        }
        expectArea(r, areas);
      }
    });
  });
}

/// [a]'s area in square metres: its outline less its holes.
double areaM2(ReachArea a) {
  double ring(List<Geo> points) {
    final lat0 = points.first.lat * math.pi / 180;
    const m = 6371008.8 * math.pi / 180;
    var sum = 0.0;
    for (var i = 0; i + 1 < points.length; i++) {
      final p = points[i], q = points[i + 1];
      sum +=
          (p.lon * m * math.cos(lat0)) * (q.lat * m) -
          (q.lon * m * math.cos(lat0)) * (p.lat * m);
    }
    return sum.abs() / 2;
  }

  return ring(a.outline) - a.holes.fold(0.0, (sum, h) => sum + ring(h));
}
