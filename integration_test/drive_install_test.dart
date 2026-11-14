// "Use a drive" against a real drive, such as traxmapmaker's stick: read its
// catalogue, show it in the Offline maps screen, install a region's map from
// it there, then routing and places, and go back to internet. The drive is
// only read; everything installs into a temporary folder, and no radio is
// used.
//
//   flutter test integration_test/drive_install_test.dart -d linux \
//     --dart-define=DRIVE=/media/$USER/MeshTraxMap
//
// --dart-define=SHOTS=<folder> saves screenshots there, in the dark theme
// with --dart-define=DARK=true. Skipped without DRIVE.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/poi_service.dart';
import 'package:meshtrax/services/routing_service.dart';

const _drive = String.fromEnvironment('DRIVE');
const _shots = String.fromEnvironment('SHOTS');
const _dark = bool.fromEnvironment('DARK');
const _region = 'north-america/us/rhode-island';
const _places = 'north-america/us/california/norcal';

/// The server's downloader, never used: the test has no network.
class _Offline implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async {}
  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> resume(String id) async {}
  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

/// The app's theme (main.dart), for screenshots that look like it.
ThemeData _theme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  ),
  useMaterial3: true,
  fontFamily: 'Liberation Sans',
  fontFamilyFallback: const ['Noto Color Emoji', 'DejaVu Sans'],
);

void _log(String line) {
  // ignore: avoid_print
  print('drive: $line');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('install a region from a drive', (tester) async {
    if (_drive.isEmpty) {
      markTestSkipped('No DRIVE');
      return;
    }
    SharedPreferences.setMockInitialValues({});
    final tmp = await Directory.systemTemp.createTemp('drive-install');
    addTearDown(() => tmp.delete(recursive: true));
    final maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: _Offline(),
      cacheDir: Directory('${tmp.path}/maps'),
      client: MockClient((_) async => http.Response('', 404)),
    );
    await maps.start();
    final routing = await RoutingService.create(maps);
    final poi = await PoiService.create(maps);

    var watch = Stopwatch()..start();
    await maps.useDrive(IoMapDrive(Directory(_drive)));
    _log(
      'read ${maps.drive!.name} in ${watch.elapsedMilliseconds} ms: '
      '${maps.index!.packs.length} packs, '
      '${routing.catalog?.regions.length} routing regions '
      '(build ${routing.catalog?.build}), '
      '${poi.catalog?.regions.length} places regions',
    );

    final shot = GlobalKey();
    Future<void> save(String name) async {
      if (_shots.isEmpty) return;
      final boundary =
          shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_shots/$name${_dark ? '-dark' : ''}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    }

    Future<void> until(bool Function() done, String what) async {
      for (var i = 0; i < 2400 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await tester.pump();
      }
      expect(done(), isTrue, reason: what);
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: shot,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MeshCoreConnector>(
              create: (_) => MeshCoreConnector(),
            ),
            ChangeNotifierProvider<AppSettingsService>(
              create: (_) => AppSettingsService(),
            ),
            ChangeNotifierProvider<MapPacksService>.value(value: maps),
            ChangeNotifierProvider<RoutingService?>.value(value: routing),
            ChangeNotifierProvider<PoiService?>.value(value: poi),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OfflineMapsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Maps on the drive'), findsOneWidget);
    await save('1-maps-tab');

    await tester.tap(find.textContaining('North America'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('United States'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Rhode Island'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Rhode Island'));
    await tester.pumpAndSettle();
    final install = find.textContaining(RegExp(r'^Install \d'));
    expect(install, findsOneWidget);
    await save('2-region');

    final osm = maps
        .packsForRegion(_region)
        .firstWhere((e) => e.kind == PackKind.osm);
    watch = Stopwatch()..start();
    await tester.ensureVisible(install);
    await tester.pumpAndSettle();
    await tester.tap(install);
    await until(() => maps.installedPack(osm.id) != null, 'map installed');
    _log(
      'map ${osm.id}: ${(osm.bytes / 1e6).toStringAsFixed(1)} MB in '
      '${watch.elapsedMilliseconds} ms (copy and sha256)',
    );
    await tester.pumpAndSettle();
    await save('3-installed');

    final bundle = routing.catalog!.regions[_region]!;
    watch = Stopwatch()..start();
    await routing.download({_region});
    await until(() => routing.isInstalled(_region), 'routing installed');
    _log(
      'routing: ${(bundle.bytes / 1e6).toStringAsFixed(1)} MB in '
      '${watch.elapsedMilliseconds} ms (copy, sha256, unpack); '
      'build ${routing.store.build}',
    );

    final points = poi.fileFor(_places, PoiDownload.points)!;
    watch = Stopwatch()..start();
    await poi.download(_places, {PoiDownload.points});
    await until(
      () => poi.isInstalled(_places, PoiDownload.points),
      'places installed',
    );
    _log(
      'places: ${(points.bytes / 1e6).toStringAsFixed(1)} MB in '
      '${watch.elapsedMilliseconds} ms (copy, sha256, gunzip)',
    );
    expect(
      maps.downloader.drive.downloads.where((d) => !d.state.isFinal),
      isEmpty,
    );

    await tester.tap(find.text('Back to internet'));
    await tester.pumpAndSettle();
    expect(maps.drive, isNull);
    expect(maps.installedPack(osm.id), isNotNull);
    expect(routing.isInstalled(_region), isTrue);
    _log('back to internet; installs kept');
  });
}
