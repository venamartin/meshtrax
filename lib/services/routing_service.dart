import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:traxcoords/traxcoords.dart';
import 'package:traxroute/traxroute.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';
import 'verified_download.dart';

/// Offline routing: the routing data per region (from the catalogue's
/// `routing` entry) and routes on it. One build on the device at a time.
///
/// The engine is Valhalla. On Android it's valhalla-mobile inside the app
/// (`MeshTraxRouting.kt`, channel `meshtrax/routing`). On Linux it's
/// Valhalla's own service program, found through
/// `--dart-define=VALHALLA_SERVICE=<path>`. Without an engine, routing is
/// not offered.
class RoutingService extends ChangeNotifier {
  final MapPacksService maps;
  final RoutingStore store;
  final RoutingEngine? engine;
  final http.Client _client;

  RoutingCatalog? _catalog;
  DateTime? _catalogRead;
  bool _catalogChecked = false;
  final Map<String, double> _progress = {};
  String? _error;
  bool _busy = false;

  RoutingService({
    required this.maps,
    required this.store,
    required this.engine,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static Future<RoutingService> create(MapPacksService maps) async {
    final root = Directory('${maps.cacheDir.path}/routing');
    final workDir = Directory('${maps.cacheDir.path}/routing-engine');
    const executable = String.fromEnvironment('VALHALLA_SERVICE');
    final service = RoutingService(
      maps: maps,
      store: RoutingStore(root),
      engine: Platform.isAndroid
          ? ValhallaMobileEngine(
              invoke: const MethodChannel('meshtrax/routing').invokeMethod,
              workDir: workDir,
            )
          : executable.isEmpty
          ? null
          : ValhallaServiceEngine(executable: executable, workDir: workDir),
    );
    maps.addListener(service._readCatalog);
    service._readCatalog();
    await service._openEngine();
    return service;
  }

  /// Whether this device can route at all.
  bool get available => engine != null;

  RoutingCatalog? get catalog => _catalog;

  /// The last download or install error, for the region page.
  String? get error => _error;

  RoutingBundle? bundleFor(String region) => _catalog?.regions[region];

  bool isInstalled(String region) => store.regions.containsKey(region);

  bool get hasRoutingData => store.tileFile != null;

  /// Regions with routing data on the device.
  Set<String> get installedRegions => store.regions.keys.toSet();

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
    final c = _catalog;
    if (c == null || _busy) return;
    final todo = downloadsFor(regions);
    if (todo.isEmpty) return;
    _busy = true;
    _error = null;
    notifyListeners();
    final temp = Directory('${store.root.path}-downloads')
      ..createSync(recursive: true);
    try {
      final bundles = <String, (File, String)>{};
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
        bundles[region] = (file, b.sha256);
      }
      await store.install(c.build, bundles);
      await _openEngine();
    } on Object catch (e) {
      appLogger.warn('Routing download failed: $e', tag: 'Routing');
      _error = '$e';
    } finally {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
      _progress.clear();
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> remove(String region) async {
    if (!isInstalled(region)) return;
    await store.remove(region);
    await _openEngine();
    notifyListeners();
  }

  /// A route from [from] to [to] with [type], or to the nearest point
  /// [type] reaches. Throws [RouteError].
  Future<RouteResult> route(
    LatLon from,
    LatLon to,
    PathType type, {
    String language = 'en-US',
  }) async {
    final e = engine;
    if (e == null || !hasRoutingData) {
      throw const RouteError('No routing data');
    }
    return routeOrNearest(
      e,
      RouteRequest([from, to], type, language: language),
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

  void _readCatalog() {
    if (_catalogChecked && maps.fetchedAt == _catalogRead) return;
    _catalogChecked = true;
    _catalogRead = maps.fetchedAt;
    final file = File('${maps.cacheDir.path}/index.json');
    if (!file.existsSync()) return;
    try {
      _catalog = RoutingCatalog.fromIndex(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        maps.indexUrl,
      );
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
