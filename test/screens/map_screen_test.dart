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
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/map_legend_sheet.dart';
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

  void replaceNode(int index, Contact node) {
    nodes[index] = node;
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

// The values a real radio reports: frequency in kHz despite the getter's name.
class _RadioConnector extends _FakeConnector {
  _RadioConnector({required super.nodes});

  final written = <String>{};
  @override
  bool wroteContactPath(Contact contact) =>
      written.contains(contact.publicKeyHex);

  @override
  int? get currentFreqHz => 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentTxPower => 22;
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
  @override
  set pendingTraceTag(int? tag) {} // the real one starts a 60 s timer
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

  var guessedLocationsOn = false;

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
          ChangeNotifierProvider(
            create: (_) =>
                AppSettingsService()
                  ..setMapShowGuessedLocations(guessedLocationsOn),
          ),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
          ChangeNotifierProvider.value(value: PathGraphService()),
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

  testWidgets('guesses use the radio\'s range: 912 km apart is a guess, 1,750 km is not', (
    tester,
  ) async {
    Contact target(int seed, int routeHop) => Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: 'T$seed',
      type: advTypeChat,
      pathLength: 1,
      path: Uint8List.fromList([routeHop]),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
      inboundPath: Uint8List.fromList(const [0x01]),
      inboundHopCount: 1,
      inboundPathHashSize: 1,
    );
    final near = target(0x10, 0x02);
    final across = target(0x11, 0x03);
    final tooFar = target(0x12, 0x04);
    await pumpMap(
      tester,
      _RadioConnector(
        nodes: [
          _node('A', advTypeRepeater, 0x01, 37.3, -122.0),
          _node('B', advTypeRepeater, 0x02, 37.5, -122.2),
          _node('Portland', advTypeRepeater, 0x03, 45.5, -122.7),
          _node('Rapid City', advTypeRepeater, 0x04, 44.1, -103.2),
          near,
          across,
          tooFar,
        ],
      ),
    );
    await tester
        .element(find.byType(AppMap))
        .read<AppSettingsService>()
        .setMapShowGuessedLocations(true);
    await tester.pump();

    final guess = overlay<MapMarker>(tester, 'guess:${near.publicKeyHex}');
    expect(guess.position.latitude, closeTo(37.4, 0.01));
    expect(guess.position.longitude, closeTo(-122.1, 0.01));
    expect(
      overlays(tester).map((o) => o.id),
      contains('guess:${across.publicKeyHex}'),
    );
    expect(
      overlays(tester).map((o) => o.id),
      isNot(contains('guess:${tooFar.publicKeyHex}')),
    );
  });

  group('guessed pins', () {
    setUp(() => guessedLocationsOn = true);
    tearDown(() => guessedLocationsOn = false);

    final anchor = _node('Anchor', advTypeRepeater, 0x01, 37.3, -122.0);
    Contact heardVia(int seed, int type) => Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: 'T$seed',
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
      inboundPath: Uint8List.fromList(const [0x01]),
      inboundHopCount: 1,
      inboundPathHashSize: 1,
    );
    final chat = heardVia(0x10, advTypeChat);
    final repeater = heardVia(0x11, advTypeRepeater);
    final room = heardVia(0x12, advTypeRoom);

    String guessId(Contact c) => 'guess:${c.publicKeyHex}';
    Iterable<String?> ids(WidgetTester tester) =>
        overlays(tester).map((o) => o.id);
    AppSettingsService settingsOf(WidgetTester tester) =>
        tester.element(find.byType(AppMap)).read<AppSettingsService>();
    int legendGuesses(WidgetTester tester) => tester
        .widget<MapLegendButton>(find.byType(MapLegendButton))
        .counts!()
        .guessed;

    testWidgets('follow the node layers, and the legend counts what is drawn', (
      tester,
    ) async {
      await pumpMap(
        tester,
        _RadioConnector(nodes: [anchor, chat, repeater, room]),
      );
      final settings = settingsOf(tester);
      expect(
        ids(tester),
        containsAll([guessId(chat), guessId(repeater), guessId(room)]),
      );
      expect(legendGuesses(tester), 3);

      await settings.setMapShowChatNodes(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(chat))));
      expect(ids(tester), contains(guessId(repeater)));
      expect(legendGuesses(tester), 2);

      await settings.setMapShowRepeaters(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(repeater))));
      expect(legendGuesses(tester), 1);

      await settings.setMapShowOtherNodes(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(room))));
      expect(legendGuesses(tester), 0);
    });

    testWidgets('are off in the overlaps view, and off the legend', (
      tester,
    ) async {
      // Sharing a first byte, so the filter alone would keep them in this view.
      Contact sharing(int fill) => Contact(
        publicKey: Uint8List.fromList([0x20, ...List.filled(31, fill)]),
        name: 'S$fill',
        type: advTypeRepeater,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
        inboundPath: Uint8List.fromList(const [0x01]),
        inboundHopCount: 1,
        inboundPathHashSize: 1,
      );
      final first = sharing(0x21);
      final second = sharing(0x22);
      await pumpMap(tester, _RadioConnector(nodes: [anchor, first, second]));
      expect(ids(tester), containsAll([guessId(first), guessId(second)]));

      await settingsOf(tester).setMapShowOverlaps(true);
      await tester.pump();

      expect(ids(tester), isNot(contains(guessId(first))));
      expect(ids(tester), isNot(contains(guessId(second))));
      expect(legendGuesses(tester), 0);
    });

    testWidgets('in a trace: no chat nodes, repeaters whatever the layer', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat, repeater]));
      await settingsOf(tester).setMapShowRepeaters(false);
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();

      expect(ids(tester), isNot(contains(guessId(chat))));
      expect(ids(tester), contains(guessId(repeater)));
    });

    testWidgets('show the contact as it is now, not as it was first guessed', (
      tester,
    ) async {
      final connector = _RadioConnector(nodes: [anchor, chat]);
      await pumpMap(tester, connector);
      final before = overlay<MapMarker>(tester, guessId(chat));

      connector.replaceNode(1, chat.copyWith(name: 'Renamed'));
      await tester.pump(const Duration(milliseconds: 200));

      final after = overlay<MapMarker>(tester, guessId(chat));
      expect(after.label, 'Renamed');
      expect(after.position, before.position);

      after.onTap!();
      await tester.pump();
      expect(find.text('Renamed'), findsWidgets);
    });

    testWidgets('long-press in a trace keeps the estimated location', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();

      overlay<MapMarker>(tester, guessId(repeater)).onLongPress!();
      await tester.pump();

      expect(find.textContaining('Est. Location'), findsOneWidget);
    });

    testWidgets('a guess in a trace stays an estimate, off the contact', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();
      final marker = overlay<MapMarker>(tester, guessId(repeater));

      marker.onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.pathContacts!.single.hasLocation, isFalse);
      final position = trace.guessedPositions[repeater.publicKeyHex]!;
      expect(position.latitude, marker.position.latitude);
      expect(position.longitude, marker.position.longitude);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a route the app wrote is no anchor, as soon as it is written', (
      tester,
    ) async {
      final routed = Contact(
        publicKey: Uint8List.fromList(List.filled(32, 0x13)),
        name: 'Routed',
        type: advTypeChat,
        pathLength: 1,
        path: Uint8List.fromList(const [0x01]),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
      );
      final connector = _RadioConnector(nodes: [anchor, routed]);
      await pumpMap(tester, connector);
      expect(ids(tester), contains(guessId(routed)));

      connector.written.add(routed.publicKeyHex);
      connector.replaceNode(1, routed);
      await tester.pump(const Duration(milliseconds: 200));

      expect(ids(tester), isNot(contains(guessId(routed))));
    });

    testWidgets('a return trace carries the estimate too', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();
      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, contains(repeater.publicKeyHex));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new trace starts with no old estimates', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();
      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(tester.element(find.byType(PathTraceMapScreen))).pop();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();
      overlay<MapMarker>(tester, 'node:${anchor.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undoing a guessed hop drops its estimate', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await tester.tap(find.byIcon(Icons.radar));
      await tester.pump();

      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      overlay<MapMarker>(tester, 'node:${anchor.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('frame the map only when nothing else can', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat]));
      // A map with content opens on it, not on where it was last left.
      tester
          .element(find.byType(AppMap))
          .read<UiViewStateService>()
          .setMapCamera(const MapCamera(center: LatLng(10, 10), zoom: 5));
      // Anchors count whatever the filter; a key prefix leaves only the guess.
      final settings = settingsOf(tester);
      await settings.setMapKeyPrefixEnabled(true);
      await settings.setMapKeyPrefix('10');
      await tester.pump();
      expect(ids(tester), contains(guessId(chat)));
      expect(ids(tester), isNot(contains('node:${anchor.publicKeyHex}')));

      final camera = tester.widget<AppMap>(find.byType(AppMap)).initialCamera!;
      expect(camera.center.latitude, closeTo(37.3, 0.01));
      expect(camera.center.longitude, closeTo(-122.0, 0.01));
    });

    testWidgets('leave the framing to real positions when there are any', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat]));

      final camera = tester.widget<AppMap>(find.byType(AppMap)).initialCamera!;
      expect(camera.center.latitude, 37.3);
      expect(camera.center.longitude, -122.0);
    });
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

  testWidgets('the legend opens as a sheet from the info button', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [_node('Hilltop', advTypeRepeater, 1, 41.8, -71.4)],
      ),
    );
    expect(find.textContaining('Nodes:'), findsNothing);

    await tester.tap(find.byTooltip('Legend'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Mesh'), findsOneWidget);
    expect(find.textContaining('Nodes:'), findsOneWidget);
    expect(find.text('Repeater'), findsOneWidget, reason: 'the key shows too');
    expect(find.text('Chart symbols'), findsNothing, reason: 'not charts');
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
