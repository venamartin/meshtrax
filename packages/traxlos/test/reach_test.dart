import 'dart:async';
import 'dart:io';

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
    // Rings to draw: closed, four or five corners each.
    final areas = r.areas({Verdict.clear});
    expect(areas, isNotEmpty);
    for (final ring in areas) {
      expect(ring.first, ring.last);
      expect(ring.length, anyOf(4, 5));
    }
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
}
