import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/line_of_sight_map_screen.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('losmap');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  testWidgets('endpoints are map markers, the panel sits above the map, '
      'and a long-press adds a point', (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MeshCoreConnector()),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LineOfSightMapScreen(
            title: 'Line of sight',
            candidates: [
              LineOfSightEndpoint(
                label: 'Hilltop',
                point: ll.LatLng(41.80, -71.40),
                color: Colors.green,
                icon: Icons.router,
              ),
              LineOfSightEndpoint(
                label: 'College Hill',
                point: ll.LatLng(41.83, -71.40),
                color: Colors.green,
                icon: Icons.router,
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    List<MapMarker> markers() => tester
        .widget<AppMap>(find.byType(AppMap))
        .overlays
        .whereType<MapMarker>()
        .toList();
    expect(markers().map((m) => m.label), ['Hilltop', 'College Hill']);
    expect(markers().first.onTap, isNotNull);
    expect(markers().first.labelMinZoom, 7.5);

    final mapRect = tester.getRect(find.byType(AppMap));
    final appBarRect = tester.getRect(find.byType(AppBar));
    expect(
      mapRect.top,
      greaterThan(appBarRect.bottom + 100),
      reason: 'the control panel is docked between the app bar and the map',
    );

    await tester.longPressAt(mapRect.center);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(markers().map((m) => m.label), contains('Custom 1'));
  });
}
