import 'dart:async';
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

/// Real catalogue files from maps.meshtrax.io/dev (kept in traxmap's tests).
final _index = File('packages/traxmap/test/support/sample_index.json')
    .readAsStringSync();
final _picker = File('packages/traxmap/test/support/picker.geojson')
    .readAsStringSync();

class _FakeDownloader implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final started = <String>[];

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
  Future<void> cancel(String packId) async {}
}

void main() {
  late Directory tmp;
  late _FakeDownloader downloader;
  late MapPacksService maps;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('offlinemaps');
    downloader = _FakeDownloader();
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: downloader,
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.example/dev/index.json'),
      client: MockClient(
        (request) async => switch (request.url.path) {
          '/dev/index.json' => http.Response(_index, 200),
          '/dev/picker.geojson' => http.Response(_picker, 200),
          _ => http.Response('', 404),
        },
      ),
    );
    await maps.start();
    await maps.refresh();
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

  testWidgets('wide: the detail sits beside the list', (tester) async {
    await open(tester, size: const Size(1200, 900));
    expect(find.text('Choose a region'), findsOneWidget);

    await tester.tap(find.textContaining('Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Watsonville'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a region'), findsNothing);
    expect(find.text('NOAA charts'), findsOneWidget);
    // The list stays visible next to the detail.
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

  testWidgets('Downloaded is empty until something is installed', (
    tester,
  ) async {
    await open(tester, size: const Size(400, 900));
    await tester.tap(find.text('Downloaded'));
    await tester.pumpAndSettle();
    expect(find.text('No offline maps yet'), findsOneWidget);

    await tester.tap(find.text('Find maps'));
    await tester.pumpAndSettle();
    expect(find.text('World'), findsOneWidget);
  });
}
