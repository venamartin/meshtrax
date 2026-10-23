import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/map_screen.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';

import '../helpers/map_fakes.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector({required this.nodes, this.self, this.gps});

  final List<Contact> nodes;
  final ll.LatLng? self;

  /// The radio's `gps` setting: null when it has no GPS module.
  String? gps;
  final gpsSets = <bool>[];

  @override
  bool get hasGps => gps != null;
  @override
  bool get gpsOn => gps == '1';
  @override
  Future<void> setGps(bool on) async {
    gpsSets.add(on);
    gps = on ? '1' : '0';
    notifyListeners();
  }

  @override
  List<Contact> get allContacts => nodes;
  @override
  List<Contact> get contacts => nodes;
  @override
  List<Channel> get channels => const [];
  @override
  double? get selfLatitude => self?.latitude;
  @override
  double? get selfLongitude => self?.longitude;
  @override
  Future<void> getChannels({int? maxChannels, bool force = false}) async {}
  @override
  Future<Map<String, List<Message>>> loadPossiblePinMessages(
    Iterable<Contact> contacts,
  ) async => const {};
  @override
  Future<Map<String, List<ChannelMessage>>> loadPossiblePinChannelMessages(
    Iterable<Channel> channels,
  ) async => const {};
  @override
  Stream<Map<String, ({ChannelMessage message, int arrivalUs})>>
  watchChannelLatest() => const Stream.empty();
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

Contact _node(String name, int type, int seed, double lat, double lon) =>
    Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: name,
      type: type,
      pathLength: 0,
      path: Uint8List(0),
      pathHashSize: 1,
      latitude: lat,
      longitude: lon,
      lastSeen: DateTime.now(),
    );

void main() {
  late Directory tmp;
  late MapPacksService maps;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('mapscreen');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpMap(
    WidgetTester tester,
    MeshCoreConnector connector, {
    Widget screen = const MapScreen(),
  }) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => screen)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<MapOverlay> overlays(WidgetTester tester) =>
      tester.widget<AppMap>(find.byType(AppMap)).overlays;

  T overlay<T extends MapOverlay>(WidgetTester tester, String id) =>
      overlays(tester).whereType<T>().firstWhere((o) => o.id == id);

  testWidgets('nodes and the radio are map markers, labelled from zoom 13', (
    tester,
  ) async {
    final repeater = _node('Hilltop', advTypeRepeater, 1, 41.8, -71.4);
    final chat = _node('Alice', advTypeChat, 2, 41.82, -71.41);
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [repeater, chat],
        self: const ll.LatLng(41.81, -71.42),
      ),
    );

    final hilltop = overlay<MapMarker>(tester, 'node:${repeater.publicKeyHex}');
    expect(hilltop.label, 'Hilltop');
    expect(hilltop.labelMinZoom, 13);
    expect(hilltop.position, const LatLng(41.8, -71.4));
    expect(hilltop.onTap, isNotNull);
    expect(
      overlay<MapMarker>(tester, 'node:${chat.publicKeyHex}').label,
      'Alice',
    );
    final self = overlay<MapMarker>(tester, 'self');
    expect(self.label, 'You');
    expect(self.interactive, isFalse);
    expect(find.byType(QuickSwitchBar), findsOneWidget);
  });

  testWidgets('a POI link: back button, labelled pin, no quick-switch bar', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const []),
      screen: const MapScreen(
        highlightPosition: ll.LatLng(41.83, -71.4),
        highlightLabel: 'Trailhead',
      ),
    );
    final pin = overlay<MapMarker>(tester, 'highlight');
    expect(pin.label, 'Trailhead');
    expect(pin.anchor, Alignment.bottomCenter);
    expect(find.byType(QuickSwitchBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MapScreen), findsNothing);
  });

  testWidgets('the menu opens Offline maps', (tester) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    await tester.tap(find.byIcon(Icons.more_vert));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Offline maps'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(OfflineMapsScreen), findsOneWidget);
  });

  testWidgets('the layers button: map types, details and node types', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    final settings = tester
        .element(find.byType(MapScreen))
        .read<AppSettingsService>();
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Map type'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(
      find.text('Not downloaded'),
      findsNWidgets(2),
      reason: 'USGS and charts: no packs',
    );
    expect(
      find.text('Offline only'),
      findsNWidgets(3),
      reason: 'nothing downloaded, so Online: contours, hill shading, dark',
    );
    expect(find.text('Nodes'), findsOneWidget);

    // An Offline-only choice made Online switches to Offline.
    await tester.tap(find.text('Dark map'));
    await tester.pump();
    expect(settings.settings.mapSource, 'offline');
    expect(settings.settings.mapTheme, 'dark');
    expect(find.text('Offline only'), findsNothing);

    await tester.tap(find.text('Contours'));
    await tester.pump();
    expect(settings.settings.mapContours, isFalse);
    await tester.tap(find.text('Hill shading'));
    await tester.pump();
    expect(settings.settings.mapHillShading, isFalse);
    await tester.tap(find.text('Downloaded areas'));
    await tester.pump();
    expect(settings.settings.mapDownloadedAreas, isFalse);
    await tester.tap(find.text('Repeaters'));
    await tester.pump();
    expect(settings.settings.mapShowRepeaters, isFalse);
  });

  testWidgets('the layers Charts tile, not downloaded, opens the Charts tab', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Charts'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Map type', skipOffstage: false),
      findsNothing,
      reason: 'the sheet closed, not left under Offline maps',
    );
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      OfflineMapsTab.charts.index,
    );
  });

  MapCamera camera(WidgetTester tester) =>
      tester.widget<AppMap>(find.byType(AppMap)).controller!.camera!;

  testWidgets("GPS on: My location goes to the GPS's blue dot", (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: const [],
        self: const ll.LatLng(41.81, -71.42),
        gps: '1',
      ),
    );
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
    expect(camera(tester).zoom, greaterThanOrEqualTo(14));
    expect(
      overlay<MapMarker>(tester, 'self').label,
      isNull,
      reason: 'the blue dot, not the "You" pin',
    );
  });

  testWidgets('GPS off: My location offers to turn it on', (tester) async {
    final connector = _FakeConnector(
      nodes: const [],
      self: const ll.LatLng(41.81, -71.42),
      gps: '0',
    );
    await pumpMap(tester, connector);
    expect(overlay<MapMarker>(tester, 'self').label, 'You');
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(find.text('Turn on GPS?'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(connector.gpsSets, [true]);
    expect(overlay<MapMarker>(tester, 'self').label, isNull);
  });

  testWidgets('GPS on, no position yet: says so', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(0, 0), gps: '1'),
    );
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(find.textContaining('No position yet'), findsOneWidget);
  });

  testWidgets('no GPS module: no My location; "You" is the typed position', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(41.81, -71.42)),
    );
    expect(find.byTooltip('My location'), findsNothing);
    expect(overlay<MapMarker>(tester, 'self').label, 'You');
  });

  testWidgets('a radio without a position: no "You"', (tester) async {
    // A radio with no position reports 0, 0: never centre on it.
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(0, 0)),
    );
    expect(overlays(tester).where((o) => o.id == 'self'), isEmpty);
  });

  testWidgets('no zoom buttons on phones: they pinch', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: const [],
        self: const ll.LatLng(41.81, -71.42),
        gps: '1',
      ),
    );
    expect(find.byTooltip('Zoom in'), findsNothing);
    expect(find.byTooltip('My location'), findsOneWidget);
  });

  testWidgets(
    'zoom buttons on desktop',
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    (tester) async {
      await pumpMap(tester, _FakeConnector(nodes: const []));
      final before = camera(tester).zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(camera(tester).zoom, before + 1);
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(camera(tester).zoom, before - 1);
    },
  );

  testWidgets('the legend hides behind an info button', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [_node('Hilltop', advTypeRepeater, 1, 41.8, -71.4)],
      ),
    );
    expect(find.textContaining('Nodes:'), findsNothing);

    await tester.tap(find.byTooltip('Legend'));
    await tester.pump();
    expect(find.textContaining('Nodes:'), findsOneWidget);
    expect(find.text('Repeater'), findsOneWidget, reason: 'the key shows too');

    await tester.tap(find.textContaining('Nodes:'));
    await tester.pump();
    expect(find.textContaining('Nodes:'), findsNothing);
    expect(find.byTooltip('Legend'), findsOneWidget);
  });

  testWidgets('a path trace starts without a radio position', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [_node('Hilltop', advTypeRepeater, 1, 41.8, -71.4)],
      ),
    );
    await tester.tap(find.byIcon(Icons.radar));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Path Trace'), findsOneWidget);
    expect(find.text('Tap on nodes to add them to the path.'), findsOneWidget);
  });
}
