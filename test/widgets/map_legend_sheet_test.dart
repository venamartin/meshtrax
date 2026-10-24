import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/map_legend_sheet.dart';

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
}

void main() {
  late Directory tmp;
  late MapPacksService maps;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('legend');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: bundledStyles(),
    );
    settings = AppSettingsService();
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pump(WidgetTester tester) async {
    // The styles come from the asset bundle: real I/O, outside fake time.
    await tester.runAsync(() async {
      while (maps.styleId(MapType.charts, dark: false) == null) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await LegendStyle.load(
        maps.styles,
        maps.styleId(MapType.charts, dark: false)!,
      );
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapLegendSheet(
              counts: (located: 3, unlocated: 2, pins: 1, guessed: 0),
            ),
          ),
        ),
      ),
    );
    // The loaded style reaches the sheet through the real event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('a map without charts shows the Mesh part only', (tester) async {
    await pump(tester);
    expect(find.text('Mesh'), findsOneWidget);
    expect(find.text('Nodes: 3'), findsOneWidget);
    expect(find.text(': 5'), findsOneWidget, reason: 'with and without');
    expect(find.text('Repeater'), findsOneWidget);
    expect(find.text('Chart symbols'), findsNothing);
  });

  testWidgets('the chart map adds its symbols by section', (tester) async {
    await settings.setMapSource('offline');
    await settings.setMapType('charts');
    await pump(tester);
    expect(find.text('Chart symbols'), findsOneWidget);
    expect(find.text('Not for navigation · Why?'), findsOneWidget);
    expect(find.text('Green can buoy'), findsNothing, reason: 'collapsed');

    await tester.tap(find.text('Buoys and beacons'));
    await tester.pumpAndSettle();
    expect(find.text('Green can buoy'), findsOneWidget);
    expect(
      find.byType(LegendSymbol),
      findsNWidgets(ChartLegendItem.of(ChartLegendSection.buoys).length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('depth areas read in the user\'s units', (tester) async {
    await settings.setMapSource('offline');
    await settings.setMapType('charts');
    await settings.setUnitSystem(UnitSystem.imperial);
    await pump(tester);
    await tester.scrollUntilVisible(find.text('Depths and seabed'), 100);
    await tester.tap(find.text('Depths and seabed'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Deeper than 98 ft'), 100);
    expect(find.text('0 to 16 ft'), findsOneWidget);
    expect(find.text('16 to 59 ft'), findsOneWidget);
  });
}
