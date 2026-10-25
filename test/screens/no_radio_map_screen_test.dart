import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/no_radio_map_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';

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
  late UiViewStateService viewState;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    viewState = UiViewStateService();
    settings = AppSettingsService();
    tmp = await Directory.systemTemp.createTemp('noradiomap');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles(maps: ['osm', 'charts'])),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(800, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: viewState),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NoRadioMapScreen(),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('opens where the map was left; no radio parts', (tester) async {
    const left = MapCamera(center: LatLng(41.8, -71.4), zoom: 11);
    viewState.setMapCamera(left);
    await pumpScreen(tester);

    final map = tester.widget<AppMap>(find.byType(AppMap));
    expect(map.initialCamera?.center, left.center);
    expect(map.initialCamera?.zoom, left.zoom);
    expect(map.overlays, isEmpty);
    expect(find.byType(QuickSwitchBar), findsNothing);
    expect(find.text('Map'), findsOneWidget);
  });

  testWidgets('the layers sheet has no node types', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Map type'), findsOneWidget);
    expect(find.text('Map details'), findsOneWidget);
    expect(find.text('Nodes'), findsNothing);
    expect(find.text('More filters'), findsNothing);
    expect(find.text('Offline maps'), findsOneWidget);
  });

  testWidgets('no radio: no My location', (tester) async {
    await pumpScreen(tester);
    expect(find.byTooltip('My location'), findsNothing);
    expect(find.byTooltip('Map layers'), findsOneWidget);
  });

  testWidgets('the layers sheet scrolls with the mouse wheel when short', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(800, 300));
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final before = tester.getTopLeft(find.text('Map details')).dy;
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    mouse.hover(tester.getCenter(find.text('Map type')));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 200)));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Map details')).dy, lessThan(before));
  });

  testWidgets('the legend button shows on offline maps with symbols', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byTooltip('Legend'), findsNothing, reason: 'online');
    await settings.setMapSource('offline');
    await tester.pump();
    expect(find.byTooltip('Legend'), findsOneWidget, reason: 'OSM icons');

    await settings.setChartsNoticeDismissed(true);
    await settings.setMapSource('offline');
    await settings.setMapType('charts');
    await tester.pump();
    await tester.tap(find.byTooltip('Legend'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Chart symbols'), findsOneWidget);
    expect(find.text('Mesh'), findsNothing, reason: 'no radio, no nodes');
  });
}
