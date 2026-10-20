import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';

import '../helpers/map_fakes.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector({required this.nodes, this.self});

  final List<Contact> nodes;
  final ll.LatLng? self;

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
  Future<List<Message>> loadMessagesFor(Contact contact) async => const [];
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
