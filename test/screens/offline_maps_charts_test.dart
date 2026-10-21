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
import 'package:meshtrax/screens/app_settings_screen.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/utils/format_bytes.dart';

import '../../packages/traxmap/test/support/fake_pmtiles.dart';
import '../helpers/map_fakes.dart';

/// The live files from maps.meshtrax.io (2026-10-20), kept in traxmap's
/// tests: 42 chart areas, and the index's charts entries plus Rhode Island.
final _chartsIndex = File('packages/traxmap/test/support/charts_index.json')
    .readAsStringSync();
final _chartAreas = File('packages/traxmap/test/support/chart_areas.geojson')
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

/// A radio at [lat], [lon].
class _Radio extends MeshCoreConnector {
  _Radio(this.lat, this.lon);
  final double? lat;
  final double? lon;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
}

void main() {
  late Directory tmp;
  late _FakeDownloader downloader;
  late Map<String, http.Response Function()> routes;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('charts');
    downloader = _FakeDownloader();
    routes = {
      '/maps/index.json': () =>
          http.Response.bytes(utf8.encode(_chartsIndex), 200),
      '/maps/picker.geojson': () => http.Response(_picker, 200),
      '/maps/chart_areas.geojson': () =>
          http.Response.bytes(utf8.encode(_chartAreas), 200),
    };
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<MapPacksService> service() async {
    final maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: downloader,
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.example/maps/index.json'),
      styles: StyleRegistry(MemoryStyles()),
      client: MockClient(
        (request) async =>
            routes[request.url.path]?.call() ?? http.Response('', 404),
      ),
    );
    await maps.start();
    await maps.refresh();
    return maps;
  }

  /// Installs the current build of [entry].
  Future<void> install(MapPacksService maps, PackIndexEntry entry) async {
    final file = File('${tmp.path}/${entry.id}.src')
      ..writeAsBytesSync(
        fakePmTiles(
          metadata: {'kind': entry.kind.name, 'region': entry.region},
        ),
      );
    final pack = await maps.manager.install(file, id: entry.id);
    await pack.file.rename(
      '${maps.manager.root.path}/${entry.id}@${entry.sha256.substring(0, 12)}.pmtiles',
    );
    await maps.reloadInstalled();
  }

  /// Installs the current build of the charts pack for [packRegion].
  Future<void> installCharts(MapPacksService maps, String packRegion) =>
      install(maps, maps.chartPackOf(packRegion)!);

  /// Waits for the refresh the screen started as it opened. Its file I/O
  /// completes in real time, but it resumes only when the fake clock is
  /// pumped, so awaiting it in runAsync alone would never return.
  Future<void> finishRefresh(WidgetTester tester, MapPacksService maps) async {
    var done = false;
    unawaited(maps.refresh().whenComplete(() => done = true));
    while (!done) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
  }

  Future<void> open(
    WidgetTester tester,
    MapPacksService maps, {
    Size size = const Size(600, 5000),
    OfflineMapsTab? tab = OfflineMapsTab.charts,
    String? chartArea,
    String? region,
    MeshCoreConnector? radio,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: radio ?? _Radio(null, null),
          ),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OfflineMapsScreen(
            initialTab: tab,
            initialChartArea: chartArea,
            initialRegionPath: region,
          ),
        ),
      ),
    );
    await tester.pump();
    await finishRefresh(tester, maps);
    await tester.pumpAndSettle();
  }

  String size(MapPacksService maps, Iterable<String> regions) => formatBytes(
    regions.fold(0, (sum, r) => sum + maps.chartPackOf(r)!.bytes),
  );

  testWidgets('three tabs; the Charts tab lists coasts in the server order', (
    tester,
  ) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    expect(
      tester.widgetList<Tab>(find.byType(Tab)).map((t) => t.text ?? 'badge'),
      ['Maps', 'Charts', 'badge'],
    );
    expect(find.textContaining('Not for navigation'), findsOneWidget);
    final coasts = maps.chartAreas!.coasts;
    final tops = [for (final c in coasts) tester.getTopLeft(find.text(c)).dy];
    expect(tops, [...tops]..sort(), reason: 'in the server order');
    expect(
      find.text(
        '15 areas · ${size(maps, [for (final a in maps.chartAreas!.inCoast('Atlantic Coast')) a.packRegion])}',
      ),
      findsOneWidget,
    );
    expect(find.text('NOAA Office of Coast Survey'), findsOneWidget);

    await tester.tap(find.text('Atlantic Coast'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Maine')).dy,
      lessThan(tester.getTopLeft(find.text('Florida')).dy),
      reason: 'along the coast (coast_areas), not by name',
    );
  });

  testWidgets('an area in two coasts is one tick, counted once', (
    tester,
  ) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    await tester.tap(find.text('Atlantic Coast'));
    await tester.pumpAndSettle();
    expect(find.text('Also in Gulf Coast'), findsOneWidget);
    await tester.tap(find.text('Florida'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('1 selected'),
      findsNWidgets(2),
      reason: 'Atlantic and Gulf both show it',
    );
    expect(find.text('1 area'), findsOneWidget);
    final florida = size(maps, ['charts/us/florida']);
    expect(find.text('Download $florida'), findsOneWidget);

    // Select all on Atlantic, then on Gulf: Florida counts once.
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gulf Coast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    final both = {
      for (final c in ['Atlantic Coast', 'Gulf Coast'])
        for (final a in maps.chartAreas!.inCoast(c)) a.packRegion,
    };
    expect(find.text('${both.length} areas'), findsOneWidget);
    expect(find.text('Download ${size(maps, both)}'), findsOneWidget);

    // Clear on Atlantic unticks Florida under Gulf too.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ExpansionTile, 'Atlantic Coast'),
        matching: find.text('Clear'),
      ),
    );
    await tester.pumpAndSettle();
    final gulfOnly = {
      for (final a in maps.chartAreas!.inCoast('Gulf Coast'))
        if (!a.coasts.contains('Atlantic Coast')) a.packRegion,
    };
    expect(find.text('Download ${size(maps, gulfOnly)}'), findsOneWidget);
  });

  testWidgets('Download starts the ticked areas and clears the ticks', (
    tester,
  ) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps, chartArea: 'charts/us/maine');
    expect(find.text('Maine'), findsOneWidget, reason: 'Atlantic opened');
    expect(find.text('1 area'), findsOneWidget);
    await tester.tap(find.text('Connecticut'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Download '));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      downloader.started,
      containsAll(['charts-us-me-charts', 'charts-us-ct-charts']),
    );
    expect(find.textContaining('Download '), findsNothing);
    expect(find.text('Waiting…'), findsNWidgets(2));
  });

  testWidgets(
    'a downloaded area shows its date and is left out of Select all',
    (tester) async {
      final maps = (await tester.runAsync(service))!;
      await tester.runAsync(
        () => installCharts(maps, 'charts/us/rhode-island'),
      );
      await open(tester, maps);
      expect(find.textContaining('1 downloaded'), findsOneWidget);
      await tester.tap(find.text('Atlantic Coast'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Downloaded '), findsWidgets);
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('14 areas'), findsOneWidget);
    },
  );

  testWidgets('an area whose pack is not out yet is greyed out', (
    tester,
  ) async {
    final index = jsonDecode(_chartsIndex) as Map<String, Object?>;
    (index['packs'] as List).removeWhere(
      (p) => (p as Map)['region'] == 'charts/us/lake-champlain',
    );
    routes['/maps/index.json'] = () =>
        http.Response.bytes(utf8.encode(jsonEncode(index)), 200);
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    await tester.tap(find.text('Inland lakes'));
    await tester.pumpAndSettle();
    expect(find.text('Not available yet'), findsOneWidget);
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 areas'), findsOneWidget);
  });

  testWidgets('states: no chart areas yet, and the server unreachable', (
    tester,
  ) async {
    routes.remove('/maps/chart_areas.geojson');
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    expect(find.text('No NOAA charts are available yet'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    routes['/maps/chart_areas.geojson'] = () => http.Response('', 500);
    await tester.runAsync(maps.refresh);
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the map server"), findsOneWidget);
  });

  testWidgets('Suggested: the chart area at the radio', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps, radio: _Radio(41.5, -71.35));
    expect(find.text('Suggested · Atlantic Coast'), findsOneWidget);
    await tester.tap(find.text('Rhode Island'));
    await tester.pumpAndSettle();
    expect(find.text('1 area'), findsOneWidget);
    expect(find.textContaining('1 selected'), findsOneWidget);
  });

  testWidgets('long names fit at phone width, everything open', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps, size: const Size(360, 8000));
    for (final coast in maps.chartAreas!.coasts) {
      await tester.tap(find.text(coast));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Pacific islands (Guam, Northern Marianas, Palau, American Samoa)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Downloaded lists chart areas apart, by name', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await tester.runAsync(() => installCharts(maps, 'charts/us/rhode-island'));
    await open(tester, maps, tab: OfflineMapsTab.downloaded);
    expect(find.text('NOAA charts'), findsOneWidget);
    expect(find.text('Rhode Island'), findsOneWidget);
    expect(find.textContaining('rhode-island'), findsNothing);
    expect(find.text('Other map files'), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Rhode Island NOAA charts?'), findsOneWidget);
  });

  testWidgets('ticks and open coasts survive switching tabs', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    await tester.tap(find.text('Atlantic Coast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Florida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    expect(find.text('Florida'), findsOneWidget, reason: 'still open');
    expect(find.text('1 area'), findsOneWidget);
  });

  testWidgets('a coastal region links to the Charts tab', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await open(
      tester,
      maps,
      tab: null,
      region: 'north-america/us/rhode-island',
    );
    expect(find.text('Map'), findsOneWidget, reason: 'the region detail');
    expect(find.text('NOAA charts'), findsNothing, reason: 'no charts row');
    await tester.tap(
      find.text('NOAA charts are picked by coast, in the Charts tab.'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      OfflineMapsTab.charts.index,
    );
    expect(find.text('Atlantic Coast'), findsOneWidget);
  });

  testWidgets('App Settings counts chart areas apart from regions', (
    tester,
  ) async {
    final maps = (await tester.runAsync(service))!;
    final osm = maps.index!.packs.firstWhere((e) => e.kind == PackKind.osm);
    await tester.runAsync(() async {
      await install(maps, osm);
      await installCharts(maps, 'charts/us/rhode-island');
      await installCharts(maps, 'charts/us/maine');
    });
    tester.view.physicalSize = const Size(600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Radio(null, null),
          ),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(create: (_) => ChatTextScaleService()),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        '1 region · 2 chart areas · ${formatBytes(maps.installedBytes)}',
      ),
      findsOneWidget,
    );
  });
}
