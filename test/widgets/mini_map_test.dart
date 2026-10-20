import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/mini_map.dart';

import '../helpers/map_fakes.dart';

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

void main() {
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('minimap');
  });
  tearDown(() => tmp.delete(recursive: true));

  testWidgets('a chat card map: compact AppMap with a pin on the spot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(
            create: (_) => MapPacksService(
              manager: PackManager(Directory('${tmp.path}/packs')),
              downloader: _NoDownloads(),
              cacheDir: tmp,
              styles: StyleRegistry(MemoryStyles()),
            ),
          ),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MiniMap(position: ll.LatLng(41.8, -71.4), label: 'Here'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final map = tester.widget<AppMap>(find.byType(AppMap));
    expect(map.compact, isTrue);
    expect(map.initialCamera?.zoom, 13);
    final pin = map.overlays.single as MapMarker;
    expect(pin.position, const LatLng(41.8, -71.4));
    expect(pin.anchor, Alignment.bottomCenter);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
  });
}
