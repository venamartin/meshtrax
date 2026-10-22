import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';

import '../helpers/map_fakes.dart';

/// Real catalogue files from maps.meshtrax.io/dev (kept in traxmap's tests).
final _index = File('packages/traxmap/test/support/sample_index.json')
    .readAsStringSync();
final _picker = File('packages/traxmap/test/support/picker.geojson')
    .readAsStringSync();

class _FakeDownloader implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final started = <String>[];
  final cancelled = <String>[];

  void emit(PackDownload d) => _updates.add(d);

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {
    started.add(entry.id);
    _updates.add(PackDownload(entry, PackDownloadState.queued, progress: 0));
  }

  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async => cancelled.add(packId);
}

void main() {
  late Directory tmp;
  late _FakeDownloader downloader;
  late MapPacksService maps;

  Future<MapPacksService> catalogue(String index) async {
    final maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: downloader,
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.example/dev/index.json'),
      styles: StyleRegistry(MemoryStyles()),
      client: MockClient(
        (request) async => switch (request.url.path) {
          '/dev/index.json' => http.Response.bytes(utf8.encode(index), 200),
          '/dev/picker.geojson' => http.Response(_picker, 200),
          _ => http.Response('', 404),
        },
      ),
    );
    await maps.start();
    await maps.refresh();
    return maps;
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('offlinemaps');
    downloader = _FakeDownloader();
    maps = await catalogue(_index);
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> open(
    WidgetTester tester, {
    required Size size,
    String? region,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>(
            create: (_) => MeshCoreConnector(),
          ),
          ChangeNotifierProvider<AppSettingsService>(
            create: (_) => AppSettingsService(),
          ),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OfflineMapsScreen(initialRegionPath: region),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone: browse to Rhode Island and download it', (tester) async {
    await open(tester, size: const Size(400, 900));

    // Nothing installed: the screen opens on Maps, at the top level.
    expect(find.text('World'), findsOneWidget);
    expect(find.textContaining('North America'), findsOneWidget);
    expect(find.textContaining('Geofabrik'), findsOneWidget);

    await tester.tap(find.textContaining('North America'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('United States'));
    await tester.pumpAndSettle();
    expect(find.text('Regions in United States of America'), findsOneWidget);
    // Map 34.1 MB + metric contours 1.0 MB (the default units).
    expect(find.textContaining('Rhode Island  35 MB'), findsOneWidget);
    expect(find.textContaining('California  2 inside'), findsOneWidget);

    await tester.tap(find.textContaining('Rhode Island'));
    await tester.pumpAndSettle();
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('USGS topo map'), findsOneWidget);
    expect(
      find.text('North America › United States of America'),
      findsOneWidget,
    );
    expect(find.text('Download 35 MB'), findsOneWidget);

    await tester.tap(find.text('Download 35 MB'));
    // Queued rows show an indeterminate bar, which never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(downloader.started, [
      'us-rhode-island-osm',
      'us-rhode-island-contours-10m',
    ]);
    expect(find.text('Waiting…'), findsNWidgets(2));

    // Back to the list.
    await tester.tap(find.text('United States of America'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rhode Island  35 MB'), findsOneWidget);
  });

  testWidgets('wide: one column, the detail in place of the list', (
    tester,
  ) async {
    await open(tester, size: const Size(1200, 900));
    await tester.tap(find.textContaining('Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Watsonville'));
    await tester.pumpAndSettle();
    expect(find.text('Map'), findsOneWidget);
    expect(
      find.text('NOAA charts'),
      findsNothing,
      reason: 'charts are picked in the Charts tab, not per region',
    );
    expect(find.text('Regions in Test'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Test'));
    await tester.pumpAndSettle();
    expect(find.text('Regions in Test'), findsOneWidget);
  });

  testWidgets('a deep link opens the region detail', (tester) async {
    await open(
      tester,
      size: const Size(400, 900),
      region: 'north-america/us/rhode-island',
    );
    expect(find.text('Rhode Island'), findsOneWidget);
    expect(find.text('Download 35 MB'), findsOneWidget);
  });

  testWidgets('hill shading is offered and ticked where a region has it', (
    tester,
  ) async {
    final index = jsonDecode(_index) as Map<String, Object?>;
    final packs = (index['packs']! as List).cast<Map<String, Object?>>();
    final usgs = packs.firstWhere((p) => p['id'] == 'us-rhode-island');
    packs.add({
      ...usgs,
      'id': 'us-rhode-island-terrain',
      'kind': 'terrain',
      'bytes': 2000000,
      'sha256': '0' * 64,
    });
    await tester.runAsync(
      () async => maps = await catalogue(jsonEncode(index)),
    );
    await open(
      tester,
      size: const Size(400, 900),
      region: 'north-america/us/rhode-island',
    );
    expect(find.text('Hill shading'), findsOneWidget);
    expect(
      find.text('Hills and mountains, shaded under the map'),
      findsOneWidget,
    );
    // Map 34.1 MB + metric contours 1.0 MB + hill shading 2.0 MB.
    expect(find.text('Download 37 MB'), findsOneWidget);
  });

  testWidgets('Downloaded is empty until something is installed', (
    tester,
  ) async {
    await open(tester, size: const Size(400, 900));
    await tester.tap(find.widgetWithText(Tab, 'Downloaded'));
    await tester.pumpAndSettle();
    expect(find.text('No offline maps yet'), findsOneWidget);

    await tester.tap(find.text('Find maps'));
    await tester.pumpAndSettle();
    expect(find.text('World'), findsOneWidget);
  });

  testWidgets('a failed download can be retried or removed', (tester) async {
    final osm = maps.index!.packs.firstWhere(
      (e) => e.id == 'us-rhode-island-osm',
    );
    downloader.emit(
      PackDownload(osm, PackDownloadState.failed, error: 'Not enough storage'),
    );
    await open(tester, size: const Size(400, 900));
    await tester.tap(find.widgetWithText(Tab, 'Downloaded'));
    await tester.pumpAndSettle();
    expect(find.text('Download failed: Not enough storage'), findsOneWidget);
    expect(find.byTooltip('Retry'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    expect(downloader.cancelled, ['us-rhode-island-osm']);
    downloader.emit(PackDownload(osm, PackDownloadState.canceled));
    await tester.pumpAndSettle();
    expect(find.text('Download failed: Not enough storage'), findsNothing);
  });
}
