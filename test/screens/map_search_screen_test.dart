import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/helpers/poi_kinds.dart';
import 'package:meshtrax/screens/map_search_screen.dart';
import 'package:meshtrax/widgets/place_sheet.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxpoi/traxpoi.dart';

const _here = GeoPoint(38.0228, -107.6714);

/// A places file the way the build makes one: an unnamed toilet about
/// 0.1 mi north-east of [_here] by a picnic area, and a named one 7 mi
/// west.
Future<PoiRegion> _region(Directory dir) async {
  final file = File('${dir.path}/points-of-interest.sqlite');
  final build = PointsDatabase(
    NativeDatabase(
      file,
      setup: (db) {
        db.execute(
          File('packages/traxpoi/lib/src/db/points_schema.drift')
              .readAsStringSync(),
        );
        for (final (id, kind, name, lat, lon) in [
          (1, 'amenity=toilets', '', 38.0240, -107.6700),
          (2, 'amenity=toilets', 'Pit Toilet', 38.0228, -107.8030),
          (3, 'tourism=picnic_site', 'Cascade Picnic Area', 38.0242, -107.6700),
          (4, 'natural=spring', 'Cold Spring', 38.0300, -107.6714),
        ]) {
          db.execute(
            'INSERT INTO place (id, kind, name, lat, lon, sources) '
            "VALUES (?, ?, ?, ?, ?, 'osm')",
            [id, kind, name, lat, lon],
          );
          db.execute('INSERT INTO place_area VALUES (?, ?, ?, ?, ?)', [
            id,
            lat,
            lat,
            lon,
            lon,
          ]);
        }
        db.execute(
          "INSERT INTO name (place_id, name, norm, role) "
          "VALUES (2, 'Pit Toilet', 'pit toilet', 'main')",
        );
        db.execute(
          "INSERT INTO name (place_id, name, norm, role) "
          "VALUES (4, 'Cold Spring', 'cold spring', 'main')",
        );
        db.execute("INSERT INTO name_search (name_search) VALUES ('rebuild')");
        db.execute('PRAGMA user_version = 1');
      },
    ),
  );
  await build.metaValue('build').get();
  await build.close();
  return PoiRegion.open(points: file);
}

void main() {
  testWidgets('"toilet" lists the nearest toilets, named or not, with the '
      'distance and direction from you, and what an unnamed one is near', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('map_search');
    final region = (await tester.runAsync(() => _region(dir)))!;
    addTearDown(() async {
      await tester.runAsync(region.close);
      dir.deleteSync(recursive: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapSearchScreen(
          regions: [region],
          near: _here,
          units: UnitSystem.imperial,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'toilet');
    await tester.pump(const Duration(milliseconds: 200));
    for (
      var i = 0;
      i < 200 && find.byType(ListTile).evaluate().length < 2;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }

    final rows = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    String text(Widget? w) {
      final t = w! as Text;
      return t.data ?? t.textSpan!.toPlainText();
    }
    expect(
      [for (final r in rows) (text(r.title), text(r.subtitle))],
      [
        ('Toilets', 'near Cascade Picnic Area · 0.1 mi NE'),
        ('Pit Toilet', 'Toilets · 7.2 mi W'),
      ],
    );
  });

  testWidgets('a spring says it may be dry or unsafe, in the list and on '
      'its sheet', (tester) async {
    final dir = Directory.systemTemp.createTempSync('map_search');
    final region = (await tester.runAsync(() => _region(dir)))!;
    addTearDown(() async {
      await tester.runAsync(region.close);
      dir.deleteSync(recursive: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapSearchScreen(
          regions: [region],
          near: _here,
          units: UnitSystem.imperial,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'cold spring');
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 200 && find.byType(ListTile).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    const caveat =
        "May be dry or unsafe: treat before drinking, and don't count on it";
    final row = tester.widget<ListTile>(find.byType(ListTile).first);
    expect(
      (row.subtitle! as Text).textSpan!.toPlainText(),
      'Spring · 0.5 mi N\n$caveat',
    );

    final detail = (await tester.runAsync(() => region.detail(4)))!;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlaceSheet(
            detail: detail,
            format: CoordFormat.decimalDegrees,
            units: UnitSystem.imperial,
            onRoute: null,
          ),
        ),
      ),
    );
    expect(find.text(caveat), findsOneWidget);
  });

  testWidgets('a drinking-water tap may be turned off; a hot spring and '
      'other kinds carry nothing', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );
    const tap = 'May be turned off: check before you count on it';
    expect(poiKindCaveat(l10n, 'amenity=drinking_water'), tap);
    expect(poiKindCaveat(l10n, 'amenity=water_point'), tap);
    expect(poiKindCaveat(l10n, 'natural=hot_spring'), isNull);
    expect(poiKindCaveat(l10n, 'amenity=toilets'), isNull);
  });
}
