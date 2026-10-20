import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';

import '../helpers/map_fakes.dart';

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
    settings = AppSettingsService();
    tmp = await Directory.systemTemp.createTemp('appmap');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpMap(WidgetTester tester, {Brightness? brightness}) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettingsService>.value(value: settings),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness ?? Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AppMap(
              initialCamera: MapCamera(center: LatLng(41.8, -71.4), zoom: 10),
            ),
          ),
        ),
      ),
    );
    // Style list, style load, renderer load, map ready, then the coverage
    // check 250 ms after the camera settles.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Set<bool> switchState(WidgetTester tester) => tester
      .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
      .selected;

  testWidgets('with nothing downloaded: online tiles and the OSM credit', (
    tester,
  ) async {
    await pumpMap(tester);
    expect(find.byType(OfflineMapView), findsOneWidget);
    expect(
      tester.widget<OfflineMapView>(find.byType(OfflineMapView)).styleId,
      'osm-light',
    );
    expect(switchState(tester), {true}, reason: 'auto: online');
    expect(find.byType(fm.TileLayer), findsOneWidget);
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('No offline map here'), findsNothing);
    expect(find.text('Not for navigation'), findsNothing);
  });

  testWidgets('offline: no online tiles, and a card where nothing is drawn', (
    tester,
  ) async {
    await settings.setMapSource('offline');
    await pumpMap(tester);
    expect(switchState(tester), {false});
    expect(find.byType(fm.TileLayer), findsNothing);
    expect(find.textContaining('OpenStreetMap contributors'), findsNothing);
    expect(find.text('No offline map here'), findsOneWidget);
    expect(find.text('Offline maps'), findsOneWidget, reason: 'no catalogue');
  });

  testWidgets('the switch changes the setting', (tester) async {
    await pumpMap(tester);
    await tester.tap(find.text('Offline'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(settings.settings.mapSource, 'offline');
    expect(switchState(tester), {false});
    expect(find.byType(fm.TileLayer), findsNothing);
  });

  testWidgets('the map is light, even in a dark app, unless set dark', (
    tester,
  ) async {
    String styleId() =>
        tester.widget<OfflineMapView>(find.byType(OfflineMapView)).styleId;
    await settings.setMapSource('offline');
    await pumpMap(tester, brightness: Brightness.dark);
    expect(styleId(), 'osm-light');

    await settings.setMapTheme('dark');
    await tester.pump();
    expect(styleId(), 'osm-dark');

    await settings.setMapSource('online');
    await tester.pump();
    expect(styleId(), 'osm-light', reason: 'online is the standard look');
  });
}
