import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/screens/channel_message_path_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';

import '../helpers/map_fakes.dart';

/// A radio that knows two repeaters but not its own position.
class _NoPositionConnector extends MeshCoreConnector {
  _NoPositionConnector(this.nodes);
  final List<Contact> nodes;
  @override
  List<Contact> get allContacts => nodes;
  @override
  double? get selfLatitude => null;
  @override
  double? get selfLongitude => null;
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

Contact _repeater(String name, int key, double lat, double lon) => Contact(
  publicKey: Uint8List.fromList(List.filled(32, key)),
  name: name,
  type: advTypeRepeater,
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
    tmp = await Directory.systemTemp.createTemp('pathmap');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  testWidgets('a path without the radio position: no crash; hops, line, '
      'and the hop list below the map', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final message = ChannelMessage(
      senderName: 'Alice',
      text: 'hi',
      timestamp: DateTime(2026, 10, 20),
      isOutgoing: false,
      pathBytes: Uint8List.fromList([0x11, 0x22]),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _NoPositionConnector([
              _repeater('Hilltop', 0x11, 41.80, -71.40),
              _repeater('College Hill', 0x22, 41.83, -71.40),
            ]),
          ),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChannelMessagePathMapScreen(message: message),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    final map = tester.widget<AppMap>(find.byType(AppMap));
    final ids = map.overlays.map((o) => o.id).toSet();
    expect(ids, containsAll(['path', 'hop:1', 'hop:2']));
    expect(ids, isNot(contains('self')));
    final hop = map.overlays.whereType<MapMarker>().first;
    expect(hop.labelMinZoom, 7.5);
    expect(map.initialFit?.maxZoom, 15);

    // The hop list is docked below the map, not over it.
    final mapRect = tester.getRect(find.byType(AppMap));
    final listRect = tester.getRect(find.textContaining('Hilltop').last);
    expect(listRect.top, greaterThanOrEqualTo(mapRect.bottom));
  });
}
