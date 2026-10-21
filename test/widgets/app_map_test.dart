import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/format_bytes.dart';
import 'package:meshtrax/widgets/app_map.dart';

import '../../packages/traxmap/test/support/fake_pmtiles.dart';
import '../helpers/map_fakes.dart';

/// The live charts files from maps.meshtrax.io, kept in traxmap's tests.
final _chartsIndex = File('packages/traxmap/test/support/charts_index.json')
    .readAsStringSync();
final _chartAreas = File('packages/traxmap/test/support/chart_areas.geojson')
    .readAsStringSync();

const _ri = 'north-america/us/rhode-island';

class _Downloads implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();

  @override
  Stream<PackDownload> get updates => _updates.stream;
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
      downloader: _Downloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpMap(
    WidgetTester tester, {
    Brightness? brightness,
    bool compact = false,
    LatLng center = const LatLng(41.8, -71.4),
  }) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>(
            create: (_) => MeshCoreConnector(),
          ),
          ChangeNotifierProvider<AppSettingsService>.value(value: settings),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness ?? Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppMap(
              initialCamera: MapCamera(center: center, zoom: 10),
              compact: compact,
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

  /// [maps] with the live charts catalogue, following [downloads].
  Future<void> withCharts(WidgetTester tester, _Downloads downloads) async {
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: downloads,
      cacheDir: tmp,
      indexUrl: Uri.parse('https://maps.example/maps/index.json'),
      styles: StyleRegistry(MemoryStyles(maps: ['osm', 'charts'])),
      client: MockClient(
        (request) async => switch (request.url.path) {
          '/maps/index.json' => http.Response.bytes(
            utf8.encode(_chartsIndex),
            200,
          ),
          '/maps/chart_areas.geojson' => http.Response.bytes(
            utf8.encode(_chartAreas),
            200,
          ),
          _ => http.Response('', 404),
        },
      ),
    );
    await tester.runAsync(() async {
      await maps.start();
      await maps.refresh();
    });
    await settings.setMapSource('offline');
    await settings.setMapType('charts');
  }

  testWidgets('offline on the Charts map: the card offers the area here', (
    tester,
  ) async {
    final downloads = _Downloads();
    await withCharts(tester, downloads);
    await pumpMap(tester);
    final ri = maps.chartPackOf('charts/us/rhode-island')!;
    expect(find.text('No charts here'), findsOneWidget);
    expect(find.text('No offline map here'), findsNothing);
    expect(
      find.text('Download Rhode Island NOAA charts · ${formatBytes(ri.bytes)}'),
      findsOneWidget,
    );

    await tester.tap(find.text('No charts here'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester
          .widget<OfflineMapsScreen>(find.byType(OfflineMapsScreen))
          .initialChartArea,
      'charts/us/rhode-island',
    );

    // Back on the map while it downloads: no second offer of it.
    await tester.pageBack();
    downloads._updates.add(
      PackDownload(ri, PackDownloadState.running, progress: 0.2),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('No charts here'), findsOneWidget);
    expect(find.textContaining('Download Rhode Island'), findsNothing);
    expect(find.text('Offline maps'), findsOneWidget);
  });

  testWidgets('where areas overlap, one downloading: no neighbour offered', (
    tester,
  ) async {
    final downloads = _Downloads();
    await withCharts(tester, downloads);
    // Fishers Island Sound: Rhode Island, Connecticut and New York.
    const here = LatLng(41.3, -71.85);
    final areas = maps.chartAreas!.areasAt(here);
    expect(areas.length, greaterThan(1));
    downloads._updates.add(
      PackDownload(
        maps.chartPackOf(areas.first.packRegion)!,
        PackDownloadState.running,
        progress: 0.2,
      ),
    );
    await pumpMap(tester, center: here);
    expect(find.text('No charts here'), findsOneWidget);
    expect(find.textContaining('Download '), findsNothing);
    expect(find.text('Offline maps'), findsOneWidget);
  });

  testWidgets('auto goes offline with a street map, not charts or contours', (
    tester,
  ) async {
    Future<void> install(String id, String kind, String region) =>
        tester.runAsync(() async {
          await maps.manager.root.create(recursive: true);
          File('${maps.manager.root.path}/$id.pmtiles').writeAsBytesSync(
            fakePmTiles(metadata: {'kind': kind, 'region': region}),
          );
          await maps.reloadInstalled();
        });
    await install('charts-us-ri-charts', 'charts', 'charts/us/rhode-island');
    await install('us-ri-contours-20ft', 'contours', _ri);
    expect(maps.installed, hasLength(2));
    await pumpMap(tester);
    expect(switchState(tester), {true});
    expect(find.text('No offline map here'), findsNothing);

    await install('us-rhode-island-osm', 'osm', _ri);
    await tester.pump();
    expect(switchState(tester), {false});
  });

  testWidgets('compact: no switch and no card, but follows the setting', (
    tester,
  ) async {
    await settings.setMapSource('offline');
    await pumpMap(tester, compact: true);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('No offline map here'), findsNothing);
    expect(find.byType(fm.TileLayer), findsNothing, reason: 'offline');
    expect(find.textContaining('OpenStreetMap'), findsNothing);
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
