import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/widgets/app_map.dart';

/// Styles held in memory: no asset bundle, so no fake-async hang in tests.
class _MemoryStyles implements StyleSource {
  @override
  Future<List<String>> ids() async => ['osm-dark', 'osm-light'];

  @override
  Future<Map<String, Object?>> load(String id) async => {
    'version': 8,
    'name': id,
    'metadata': {
      'ovm:map': 'osm',
      'ovm:theme': id.endsWith('dark') ? 'dark' : 'light',
      'ovm:requires': ['osm'],
    },
    'sources': {
      'osm': {'type': 'vector', 'url': 'pmtiles://{pack:osm}'},
    },
    'layers': [
      {'id': 'bg', 'type': 'background'},
    ],
  };
}

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

/// Online tiles that never touch the network or disk.
class _BlankTiles extends MapTileCacheService {
  @override
  fm.TileProvider get tileProvider => _BlankTileProvider();
}

class _BlankTileProvider extends fm.TileProvider {
  // A 1×1 transparent PNG.
  static final _png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(fm.TileCoordinates c, fm.TileLayer options) =>
      MemoryImage(_png);
}

void main() {
  late Directory tmp;
  late MapPacksService maps;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('appmap');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(_MemoryStyles()),
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
          ChangeNotifierProvider<AppSettingsService>(
            create: (_) => AppSettingsService(),
          ),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: _BlankTiles()),
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

  testWidgets('with nothing installed: online tiles and the OSM credit', (
    tester,
  ) async {
    await pumpMap(tester);
    expect(find.byType(OfflineMapView), findsOneWidget);
    expect(
      tester.widget<OfflineMapView>(find.byType(OfflineMapView)).styleId,
      'osm-light',
    );
    expect(find.byType(fm.TileLayer), findsOneWidget);
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('Not for navigation'), findsNothing);
  });

  testWidgets('the map follows the app theme', (tester) async {
    await pumpMap(tester, brightness: Brightness.dark);
    expect(
      tester.widget<OfflineMapView>(find.byType(OfflineMapView)).styleId,
      'osm-dark',
    );
  });
}
