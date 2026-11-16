import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxlos/traxlos.dart';

import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/line_of_sight.dart';
import 'package:meshtrax/services/line_of_sight_session.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import '../helpers/los_fakes.dart';

const dantes = LatLng(36.2209, -116.7266);
const badwater = LatLng(36.2302, -116.7672);
const nevada = LatLng(36.38, -116.35);

void main() {
  late Directory tmp;
  late MapPacksService maps;
  late LosWorker worker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('los');
    maps = await losMaps(tmp);
    worker = LosWorker();
  });
  tearDown(() async {
    worker.dispose();
    await tmp.delete(recursive: true);
  });

  group('the packs', () {
    test('installed contours with their region\'s outline, 20 ft first', () {
      final packs = losPacksFrom(maps, UnitSystem.metric);
      expect(
        packs.contours.single.path,
        endsWith('norcal-contours-20ft.pmtiles'),
      );
      expect(packs.peaks, isEmpty);
      expect(covers(packs, geoOf(dantes)), isTrue);
      expect(covers(packs, geoOf(nevada)), isFalse);
    });

    test('where contours are missing: the region to download, or none', () {
      final m = missingContours(maps, UnitSystem.imperial, [nevada]);
      expect(m.offers.single.region.name, 'Nevada');
      expect(m.offers.single.pack.id, 'us-nevada-contours-20ft');
      expect(m.noData, isFalse);
      expect(
        missingContours(maps, UnitSystem.metric, [
          nevada,
        ]).offers.single.pack.id,
        'us-nevada-contours-10m',
      );
      // Mexico has no contours packs; the sea has no region.
      final mexico = missingContours(maps, UnitSystem.imperial, [
        const LatLng(31.0, -115.0),
        const LatLng(30.0, -130.0),
      ]);
      expect(mexico.offers, isEmpty);
      expect(mexico.noData, isTrue);
      // Already installed: nothing to offer.
      expect(
        missingContours(maps, UnitSystem.imperial, [dantes]).offers,
        isEmpty,
      );
    });

    test('without a catalogue nothing can be offered', () async {
      final bare = await Directory.systemTemp.createTemp('los-bare');
      addTearDown(() => bare.delete(recursive: true));
      final none = await losMaps(bare, catalogue: false);
      final m = missingContours(none, UnitSystem.imperial, [nevada]);
      expect(m.noCatalogue, isTrue);
      expect(m.offers, isEmpty);
    });
  });

  group('the worker isolate', () {
    test('Badwater at its GPS height to Dantes View: Blocked by about 75 m '
        'half a kilometre out', () async {
      final r = await worker.line(
        losPacksFrom(maps, UnitSystem.imperial),
        LinkEnd(geoOf(badwater), groundM: -82.6),
        LinkEnd(geoOf(dantes)),
        frequencyMHz: 910.525,
      );
      expect(r.verdict, Verdict.blocked);
      expect(r.deciding!.distanceM, closeTo(490, 100));
      expect(r.deciding!.aboveLineM, closeTo(75, 4));
      expect(r.credits, ['USGS 3DEP']);
      // Asked again with another antenna: answered from the kept tiles.
      final again = await worker.line(
        losPacksFrom(maps, UnitSystem.imperial),
        LinkEnd(geoOf(badwater), groundM: -82.6, antennaM: 6),
        LinkEnd(geoOf(dantes)),
        frequencyMHz: 910.525,
      );
      expect(again.fromAntennaM, 6);
    });

    test(
      'into Nevada: can\'t tell, with the stretch that has no contours',
      () async {
        final r = await worker.line(
          losPacksFrom(maps, UnitSystem.imperial),
          LinkEnd(geoOf(dantes), groundM: 1668.6),
          LinkEnd(geoOf(nevada)),
          frequencyMHz: 915,
        );
        expect(r.verdict, Verdict.unknown);
        expect(r.notDownloaded, isNotEmpty);
        final offer = missingContours(
          maps,
          UnitSystem.imperial,
          pointsAlong(r.notDownloaded),
        );
        expect(offer.offers.single.region.name, 'Nevada');
      },
    );

    test('a sweep reports progress and stops when asked', () async {
      final progress = <double>[];
      final r = await worker.reach(
        losPacksFrom(maps, UnitSystem.imperial),
        LinkEnd(geoOf(dantes), groundM: 1668.6),
        radiusM: 3000,
        rays: 72,
        targets: [LinkEnd(geoOf(badwater))],
        frequencyMHz: 915,
        onProgress: progress.add,
      );
      expect(r!.runs, hasLength(72));
      expect(r.targets.single.verdict, Verdict.unknown);
      expect(r.areas({Verdict.clear, Verdict.marginal}), isNotEmpty);
      final stopped = worker.reach(
        losPacksFrom(maps, UnitSystem.imperial),
        LinkEnd(geoOf(dantes), groundM: 1668.6),
        radiusM: 20000,
        rays: 7200,
        targets: const [],
        frequencyMHz: 915,
      );
      worker.stop();
      expect(await stopped, isNull);
    });

    test('closes: what is asked after fails, nothing hangs', () async {
      final pending = worker.line(
        losPacksFrom(maps, UnitSystem.imperial),
        LinkEnd(geoOf(dantes)),
        LinkEnd(geoOf(badwater)),
        frequencyMHz: 915,
      );
      worker.dispose();
      await expectLater(pending, throwsStateError);
    });
  });

  group('a session', () {
    late AppSettingsService settings;
    setUp(() async {
      settings = AppSettingsService();
      await settings.setUnitSystem(UnitSystem.imperial);
    });

    Future<void> idle(LineOfSightSession s) async {
      for (var i = 0; i < 200 && s.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    LineOfSightSession session({
      LosMode mode = LosMode.line,
      LosPlace? from,
      LosPlace? to,
      List<LosPlace> people = const [],
    }) {
      final s = LineOfSightSession(
        worker: worker,
        maps: maps,
        settings: settings,
        mode: mode,
        frequencyMHz: 910.525,
        people: () => people,
        from: from,
        to: to,
      );
      addTearDown(s.dispose);
      return s;
    }

    final me = LosPlace.me(
      badwater,
      source: MyPosition.gps,
      seenAt: DateTime(2026, 11, 16, 12),
      groundM: -82.6,
    );

    test('nothing runs until there is a To; then each change works it out '
        'again', () async {
      final s = session(from: me);
      expect(s.busy, isFalse);
      expect(s.line, isNull);
      s.tap(const LosPlace.point(dantes));
      expect(s.busy, isTrue);
      await idle(s);
      expect(s.currentLine!.verdict, Verdict.blocked);
      expect(s.currentLine!.fromAntennaM, Antenna.handHeldM);
      // A higher antenna of mine: worked out again, and remembered.
      s.setFromAntenna(s.fromAntenna.withKind(AntennaKind.vehicle));
      await idle(s);
      expect(s.currentLine!.fromAntennaM, Antenna.vehicleM);
      expect(settings.settings.losAntenna, 'vehicle');
      // A tap moves only To.
      s.tap(const LosPlace.point(LatLng(36.21, -116.71)));
      await idle(s);
      expect(s.from, same(me));
      expect(s.currentLine!.to, geoOf(const LatLng(36.21, -116.71)));
    });

    test('repeaters start raised, others hand-held; my end starts with my '
        'choice', () async {
      await settings.setLosAntenna('raised', raisedM: 9);
      final s = session(
        from: me,
        to: const LosPlace.contact(
          dantes,
          name: 'Peak',
          key: 'k',
          repeater: true,
        ),
      );
      expect(s.fromAntenna, const Antenna(AntennaKind.raised, raisedM: 9));
      expect(s.toAntenna.kind, AntennaKind.raised);
      expect(s.toAntenna.metres, closeTo(6.096, 1e-9));
      s.tap(const LosPlace.contact(badwater, name: 'Ana', key: 'a'));
      expect(s.toAntenna.kind, AntennaKind.handHeld);
    });

    test(
      'without a position of mine, the first tap is where it starts',
      () async {
        final s = session();
        expect(s.from, isNull);
        s.tap(const LosPlace.point(badwater));
        expect(s.from!.position, badwater);
        expect(s.to, isNull);
        s.tap(const LosPlace.point(dantes));
        expect(s.to!.position, dantes);
      },
    );

    test('radio reach: the list of people in range, and a row opens that '
        'line', () async {
      final ana = LosPlace.contact(
        const LatLng(36.21, -116.71),
        name: 'Ana',
        key: 'a',
      );
      final far = LosPlace.contact(
        const LatLng(37.5, -118.0),
        name: 'Far',
        key: 'f',
      );
      final s = session(
        mode: LosMode.reach,
        from: LosPlace.me(dantes, source: MyPosition.byHand),
        people: [me, ana, far],
      );
      await idle(s);
      expect(s.reach, isNotNull);
      expect(s.reachRadiusM, LineOfSightSession.nearRadiusM);
      expect(s.reachPeople.map((p) => p.name), ['Ana']);
      expect(s.reach!.targets, hasLength(1));
      s.openLine(ana);
      expect(s.mode, LosMode.line);
      expect(s.canGoBack, isTrue);
      await idle(s);
      expect(s.currentLine!.to, geoOf(ana.position));
      s.backToReach();
      expect(s.mode, LosMode.reach);
      expect(s.reach, isNotNull);
      s.lookFurther();
      expect(s.reachRadiusM, LineOfSightSession.farRadiusM);
      await idle(s);
      expect(s.reach!.radiusM, LineOfSightSession.farRadiusM);
    });
  });
}
