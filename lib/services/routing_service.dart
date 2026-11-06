import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:traxcoords/traxcoords.dart';
import 'package:traxmap/traxmap.dart' show LatLng, creditsIn, noticesIn;
import 'package:traxroute/traxroute.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';
import 'verified_download.dart';

/// Offline routing: the routing data per region (from the catalogue's
/// `routing` entry) and routes on it. One build on the device at a time.
///
/// The engine is Valhalla. On phones it's valhalla-mobile inside the app,
/// on the channel `meshtrax/routing`: `MeshTraxRouting.kt` on Android, the
/// `traxroute_ios` plugin on iOS. On Linux it's Valhalla's own service
/// program, found through `--dart-define=VALHALLA_SERVICE=<path>`. Without
/// an engine, routing is not offered.
class RoutingService extends ChangeNotifier {
  final MapPacksService maps;
  final RoutingStore store;
  final RoutingEngine? engine;
  final http.Client _client;

  RoutingCatalog? _catalog;
  bool _needsNewerApp = false;
  DateTime? _catalogRead;
  bool _catalogChecked = false;
  final Map<String, double> _progress = {};
  String? _error;
  bool _busy = false;
  List<String> _credits = const [];
  List<String> _notices = const [];

  RoutingService({
    required this.maps,
    required this.store,
    required this.engine,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static Future<RoutingService> create(
    MapPacksService maps, {
    http.Client? client,
  }) async {
    final root = Directory('${maps.cacheDir.path}/routing');
    final workDir = Directory('${maps.cacheDir.path}/routing-engine');
    const executable = String.fromEnvironment('VALHALLA_SERVICE');
    final service = RoutingService(
      maps: maps,
      store: RoutingStore(root),
      engine: Platform.isAndroid || Platform.isIOS
          ? ValhallaMobileEngine(
              invoke: const MethodChannel('meshtrax/routing').invokeMethod,
              workDir: workDir,
            )
          : executable.isEmpty
          ? null
          : ValhallaServiceEngine(executable: executable, workDir: workDir),
      client: client,
    );
    maps.addListener(service._readCatalog);
    service._readCatalog();
    service._readCredits();
    await service._openEngine();
    return service;
  }

  /// Whether this device can route at all.
  bool get available => engine != null;

  RoutingCatalog? get catalog => _catalog;

  /// The catalogue has routing, but only for engines a newer app reads.
  bool get needsNewerApp => _needsNewerApp;

  /// The last download or install error, for the region page.
  String? get error => _error;

  RoutingBundle? bundleFor(String region) => _catalog?.regions[region];

  bool isInstalled(String region) => store.regions.containsKey(region);

  bool get hasRoutingData => store.tileFile != null;

  /// Whether routing is on offer at [point]: data is on the device (a
  /// route may still stop short of it), or the catalogue has it for the
  /// region there, to download.
  bool offeredAt(LatLon point) {
    if (hasRoutingData) return true;
    final region = maps.regions?.regionAt(LatLng(point.lat, point.lon));
    return region != null && bundleFor(region.path) != null;
  }

  /// Regions with routing data on the device.
  Set<String> get installedRegions => store.regions.keys.toSet();

  /// Credits for the routing data on the device, one per source: routes
  /// draw on every map, so the maps show them with their own (FINDINGS
  /// §1.5).
  List<String> get credits => _credits;

  /// The notices the routing data's licences require with the credits.
  List<String> get notices => _notices;

  /// What [region]'s routing data takes (tiles it shares count for each
  /// region that uses them).
  int sizeOf(String region) => store.sizeOf(region);

  /// What all routing data takes: the one tile file.
  int get totalBytes => store.tileFile?.lengthSync() ?? 0;

  /// 0–1 while [region]'s data is downloading, else null.
  double? progressOf(String region) => _progress[region];

  bool get busy => _busy;

  /// What downloading [regions] takes: those regions, plus every installed
  /// one when the catalogue has a newer build.
  Set<String> downloadsFor(Set<String> regions) {
    final c = _catalog;
    return c == null ? {} : store.downloadsFor(c, regions);
  }

  int bytesFor(Set<String> regions) =>
      downloadsFor(regions)
          .fold(0, (sum, r) => sum + (_catalog!.regions[r]?.bytes ?? 0));

  bool updateAvailable(String region) =>
      isInstalled(region) && downloadsFor(const {}).contains(region);

  Future<void> download(Set<String> regions) async {
    if (_catalog == null || _busy || downloadsFor(regions).isEmpty) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      try {
        await _install(regions);
      } on MissingDownload {
        // A bundle the catalogue lists is gone: the server has moved on to
        // a newer build, keeping the old one only for a while (FINDINGS
        // §1.5). Read the catalogue again and take the current build.
        await maps.refresh();
        await _install(regions);
      }
      _readCredits();
      await _openEngine();
    } on Object catch (e) {
      appLogger.warn('Routing download failed: $e', tag: 'Routing');
      _error = '$e';
    } finally {
      _progress.clear();
      _busy = false;
      notifyListeners();
    }
  }

  /// Downloads what [regions] take from the current catalogue and
  /// installs it.
  Future<void> _install(Set<String> regions) async {
    // Nothing listed (a catalogue mid-publish, or routing only a newer app
    // reads): installing nothing of a new build would remove the old one.
    final c = _catalog;
    final todo = downloadsFor(regions);
    if (c == null || todo.isEmpty) return;
    final temp = Directory('${store.root.path}-downloads')
      ..createSync(recursive: true);
    try {
      final bundles = <String, (File, RoutingBundle)>{};
      for (final region in todo) {
        final b = c.regions[region]!;
        final file = File('${temp.path}/${region.replaceAll('/', '_')}.tar.gz');
        _progress[region] = 0;
        notifyListeners();
        await downloadVerified(
          _client,
          b.url,
          file,
          b.sha256,
          onProgress: (got, total) {
            _progress[region] = got / (total ?? b.bytes);
            notifyListeners();
          },
        );
        bundles[region] = (file, b);
      }
      await store.install(c.build, bundles);
    } finally {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    }
  }

  Future<void> remove(String region) async {
    if (!isInstalled(region)) return;
    await store.remove(region);
    _readCredits();
    await _openEngine();
    notifyListeners();
  }

  /// A route from [from] to [to] with [type] and [options], or to the
  /// nearest point [type] reaches. Throws [RouteError].
  Future<RouteResult> route(
    LatLon from,
    LatLon to,
    PathType type, {
    RouteOptions options = const RouteOptions(),
    String language = 'en-US',
  }) async {
    final e = engine;
    if (e == null || !hasRoutingData) {
      throw const RouteError('No routing data');
    }
    return routeOrNearest(
      e,
      RouteRequest([from, to], type, options: options, language: language),
    );
  }

  Future<void> _openEngine() async {
    final e = engine;
    final tiles = store.tileFile;
    if (e == null) return;
    try {
      if (tiles == null) {
        await e.close();
      } else {
        await e.open(tiles);
      }
    } on Object catch (err) {
      appLogger.warn('Routing engine failed to start: $err', tag: 'Routing');
      _error = '$err';
    }
    notifyListeners();
  }

  /// The installed regions' credits, which the store keeps from the
  /// catalogue, so they show offline too.
  void _readCredits() {
    final regions = store.regions.values;
    _credits = creditsIn([for (final r in regions) r.attribution]);
    _notices = noticesIn([for (final r in regions) r.notice]);
  }

  void _readCatalog() {
    if (_catalogChecked && maps.fetchedAt == _catalogRead) return;
    _catalogChecked = true;
    _catalogRead = maps.fetchedAt;
    final file = File('${maps.cacheDir.path}/index.json');
    if (!file.existsSync()) return;
    try {
      final index = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      _catalog = RoutingCatalog.fromIndex(index, maps.indexUrl);
      _needsNewerApp = RoutingCatalog.needsNewerApp(index);
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Routing catalogue unreadable: $e', tag: 'Routing');
    }
  }

  @override
  void dispose() {
    maps.removeListener(_readCatalog);
    engine?.close();
    _client.close();
    super.dispose();
  }
}
