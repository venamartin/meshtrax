import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/app_settings_screen.dart';
import 'package:meshtrax/screens/offline_maps/offline_maps_ui.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
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

  /// When set, starting waits for it, like a permission prompt would.
  Completer<void>? gate;

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {
    await gate?.future;
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
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
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

  /// Installs the current build of [entry], written straight to its final
  /// name: PackManager.install would also set off a reload of its own.
  Future<void> install(MapPacksService maps, PackIndexEntry entry) async {
    await maps.manager.root.create(recursive: true);
    File(
      '${maps.manager.root.path}/${entry.id}@${entry.sha256.substring(0, 12)}.pmtiles',
    ).writeAsBytesSync(
      fakePmTiles(
        metadata: {
          'kind': entry.kind.name,
          'region': entry.region,
          'name': entry.name,
        },
      ),
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

  testWidgets('"Why?" gives the reasons, and can undo "don\'t show again"', (
    tester,
  ) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps);
    final settings = tester
        .element(find.byType(OfflineMapsScreen))
        .read<AppSettingsService>();
    Future<void> why() async {
      await tester.tap(find.text('Not for navigation · Why?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notices to Mariners'), findsOneWidget);
    }

    bool ticked() =>
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value!;

    await why();
    expect(ticked(), isFalse);
    await tester.tap(find.text("Don't show this again"));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(settings.settings.chartsNoticeDismissed, isTrue);

    await why();
    expect(ticked(), isTrue, reason: 'shows the saved choice');
    await tester.tap(find.text("Don't show this again"));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(settings.settings.chartsNoticeDismissed, isFalse);
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

    // Cancelled, Maine can be downloaded again, and comes back unticked.
    downloader._updates.add(
      PackDownload(
        maps.chartPackOf('charts/us/maine')!,
        PackDownloadState.canceled,
        progress: 0,
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final maine = tester.widget<Checkbox>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Maine'),
          matching: find.byType(PackRow),
        ),
        matching: find.byType(Checkbox),
      ),
    );
    expect(maine.value, isFalse);
    expect(find.textContaining('Download '), findsNothing);
  });

  testWidgets('ticks made while the downloads start are kept', (tester) async {
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps, chartArea: 'charts/us/maine');
    downloader.gate = Completer();
    await tester.tap(find.textContaining('Download '));
    await tester.pump();
    expect(downloader.started, isEmpty, reason: 'still starting');
    expect(find.textContaining('Download '), findsNothing, reason: 'cleared');

    await tester.tap(find.text('New Hampshire'));
    await tester.pump();
    downloader.gate!.complete();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(downloader.started, ['charts-us-me-charts']);
    expect(find.text('1 area'), findsOneWidget, reason: 'New Hampshire');
    final nh = tester.widget<Checkbox>(
      find.descendant(
        of: find.ancestor(
          of: find.text('New Hampshire'),
          matching: find.byType(PackRow),
        ),
        matching: find.byType(Checkbox),
      ),
    );
    expect(nh.value, isTrue);
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

    // Offline with the catalogue cached: the server can't be reached, not
    // "no charts".
    routes['/maps/index.json'] = () => http.Response('', 500);
    await tester.runAsync(maps.refresh);
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the map server"), findsOneWidget);
    expect(find.text('No NOAA charts are available yet'), findsNothing);

    routes['/maps/index.json'] = () =>
        http.Response.bytes(utf8.encode(_chartsIndex), 200);
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
    await tester.runAsync(() async {
      for (final area in ['texas', 'rhode-island', 'lake-champlain']) {
        await installCharts(maps, 'charts/us/$area');
      }
    });
    await open(tester, maps, tab: OfflineMapsTab.downloaded);
    expect(find.text('NOAA charts'), findsOneWidget);
    expect(find.text('Rhode Island'), findsOneWidget);
    expect(find.textContaining('rhode-island'), findsNothing);
    expect(find.text('Other map files'), findsNothing);
    final tops = [
      for (final name in ['Lake Champlain (Vermont)', 'Rhode Island', 'Texas'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: 'by name, not by id');

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Rhode Island'),
        matching: find.byTooltip('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete Rhode Island NOAA charts?'), findsOneWidget);
  });

  testWidgets('an installed area the file no longer lists keeps a name', (
    tester,
  ) async {
    final areas = jsonDecode(_chartAreas) as Map<String, Object?>;
    (areas['features'] as List).removeWhere(
      (f) => ((f as Map)['properties'] as Map)['id'] == 'charts-us-ri',
    );
    routes['/maps/chart_areas.geojson'] = () =>
        http.Response.bytes(utf8.encode(jsonEncode(areas)), 200);
    final maps = (await tester.runAsync(service))!;
    await tester.runAsync(() => installCharts(maps, 'charts/us/rhode-island'));
    await open(tester, maps, tab: OfflineMapsTab.downloaded);
    expect(find.text('Rhode Island (NOAA charts)'), findsOneWidget);
    expect(find.textContaining('rhode-island'), findsNothing);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Rhode Island (NOAA charts)?'), findsOneWidget);
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

  testWidgets('an inland region has no Charts link', (tester) async {
    // Iowa's box meets the box of Michigan's Lake Superior part, but no
    // chart water reaches Iowa.
    final picker = jsonDecode(_picker) as Map<String, Object?>;
    final (w, s, e, n) = (-96.6426, 40.37266, -90.13581, 43.50182);
    (picker['features'] as List).add({
      'type': 'Feature',
      'properties': {
        'id': 'us-iowa',
        'name': 'Iowa',
        'path': 'north-america/us/iowa',
        'parent': 'north-america/us',
        'level': 'state',
        'downloadable': true,
        'display_bbox': [w, s, e, n],
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [w, s],
            [e, s],
            [e, n],
            [w, n],
            [w, s],
          ],
        ],
      },
    });
    routes['/maps/picker.geojson'] = () =>
        http.Response.bytes(utf8.encode(jsonEncode(picker)), 200);
    final maps = (await tester.runAsync(service))!;
    await open(tester, maps, tab: null, region: 'north-america/us/iowa');
    expect(find.text('Iowa'), findsWidgets, reason: 'the region detail');
    expect(
      find.text('NOAA charts are picked by coast, in the Charts tab.'),
      findsNothing,
    );
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
