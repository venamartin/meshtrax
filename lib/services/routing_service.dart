import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxmap/traxmap.dart'
    show
        DownloadFile,
        LatLng,
        PackDownload,
        PackDownloadState,
        creditsIn,
        noticesIn;
import 'package:traxroute/traxroute.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';

/// Offline routing: the routing data per region (from the catalogue's
/// `routing` entry) and routes on it. One build on the device at a time.
///
/// The engine is Valhalla. On phones it's valhalla-mobile inside the app,
/// on the channel `meshtrax/routing`: `MeshTraxRouting.kt` on Android, the
/// `traxroute_ios` plugin on iOS. On Linux it's Valhalla's own service
/// program, found through `--dart-define=VALHALLA_SERVICE=<path>`. Without
/// an engine, routing is not offered.
///
/// Bundles download through the map downloader, as packs do: in the
/// background, on Wi‑Fi when the setting says so, with pause and resume.
/// The downloader checks each one and hands it over; whatever has arrived
/// is merged into the one tile file.
class RoutingService extends ChangeNotifier {
  /// The [DownloadFile.kind] of a routing bundle.
  static const downloadKind = 'routing';

  final MapPacksService maps;
  final RoutingStore store;
  final RoutingEngine? engine;

  RoutingCatalog? _catalog;
  bool _needsNewerApp = false;
  DateTime? _catalogRead;
  bool _catalogChecked = false;
  List<String> _credits = const [];
  List<String> _notices = const [];
  StreamSubscription<PackDownload>? _downloads;
  var _work = Future<void>.value();
  final _recovering = <String>{};

  /// Per build, the regions [download] asked for, so a new build waits for
  /// those the downloader hasn't started yet.
  final _expected = <String, Set<String>>{};

  RoutingService({
    required this.maps,
    required this.store,
    required this.engine,
  });

  static Future<RoutingService> create(MapPacksService maps) async {
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
    );
    maps.addListener(service._readCatalog);
    service._readCatalog();
    service._readCredits();
    await service._openEngine();
    service._followDownloads();
    return service;
  }

  /// Whether this device can route at all.
  bool get available => engine != null;

  RoutingCatalog? get catalog => _catalog;

  /// The catalogue has routing, but only for engines a newer app reads.
  bool get needsNewerApp => _needsNewerApp;

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

  /// The id of [region]'s bundle in the map downloader.
  static String downloadId(String region) =>
      'routing-${region.replaceAll('/', '_')}';

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

  /// Downloads what [regions] take from the current catalogue, through the
  /// map downloader. Each bundle installs as it arrives.
  Future<void> download(Set<String> regions) async {
    final c = _catalog;
    if (c == null) return;
    final todo = downloadsFor(regions);
    (_expected[c.build] ??= {}).addAll(todo);
    await maps.download([for (final region in todo) _item(region, c)]);
  }

  DownloadFile _item(String region, RoutingCatalog c) {
    final b = c.regions[region]!;
    return DownloadFile(
      id: downloadId(region),
      name: maps.regions?[region]?.name ?? region.split('/').last,
      region: region,
      url: b.url,
      bytes: b.bytes,
      sha256: b.sha256,
      kind: downloadKind,
      payload: {
        'build': c.build,
        'attribution': ?b.attribution,
        'notice': ?b.notice,
      },
    );
  }

  /// Removes [region]'s routing. It waits behind any install, since both
  /// rewrite the tile file and a new build deletes the old build's folder.
  Future<void> remove(String region) => _work = _work.then((_) async {
    if (!isInstalled(region)) return;
    try {
      await store.remove(region);
    } on Object catch (e) {
      appLogger.warn('Routing remove failed: $e', tag: 'Routing');
    }
    _readCredits();
    await _openEngine();
    notifyListeners();
  });

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

  /// Completes once every install and retry queued so far has run.
  @visibleForTesting
  Future<void> get idle async {
    Future<void>? seen;
    while (seen != _work) {
      seen = _work;
      await seen;
    }
  }

  /// Installs bundles as the downloader hands them over, including any
  /// handed over before this service existed (restored from the last run).
  void _followDownloads() {
    _downloads = maps.downloader.updates.listen(_onDownload);
    for (final d in maps.downloader.downloads) {
      _onDownload(d);
    }
  }

  void _onDownload(PackDownload d) {
    if (d.file?.kind != downloadKind) return;
    switch (d.state) {
      case PackDownloadState.downloaded:
        _work = _work.then((_) => _installDownloaded());
      // A canceled bundle may be the last one a new build was waiting for.
      case PackDownloadState.canceled:
        _expected[d.file!.payload['build']]?.remove(d.file!.region);
        _work = _work.then((_) => _installDownloaded());
      // A bundle gone from the server: it has moved on to a newer build,
      // keeping the old one only for a while (FINDINGS §1.5).
      case PackDownloadState.failed when d.error == 'HTTP 404':
        _work = _work.then((_) => _retryFromCatalog(d));
      default:
    }
  }

  /// Installs everything the downloader has handed over, in one rewrite of
  /// the tile file per build.
  Future<void> _installDownloaded() async {
    final byBuild = <String, Map<String, (File, RoutingBundle)>>{};
    for (final d in maps.downloader.downloads) {
      final file = d.file;
      if (file == null ||
          file.kind != downloadKind ||
          d.state != PackDownloadState.downloaded) {
        continue;
      }
      (byBuild[file.payload['build'] as String] ??= {})[file.region!] = (
        File(d.path!),
        RoutingBundle(
          file.url,
          file.bytes,
          0,
          file.sha256,
          attribution: file.payload['attribution'] as String?,
          notice: file.payload['notice'] as String?,
        ),
      );
    }
    if (byBuild.isEmpty) return;
    for (final MapEntry(key: build, value: bundles) in byBuild.entries) {
      // A new build replaces the installed one in one step, keeping only
      // the regions it's given, so it waits for every bundle of it still
      // on its way: installing early would drop their regions meanwhile,
      // and for good if one failed.
      if (store.build != null && build != store.build && _waiting(build)) {
        continue;
      }
      String? error;
      try {
        await store.install(build, bundles);
        _expected[build]?.removeAll(bundles.keys);
      } on Object catch (e) {
        appLogger.warn('Routing install failed: $e', tag: 'Routing');
        error = '$e';
      }
      for (final MapEntry(key: region, value: (file, _)) in bundles.entries) {
        if (file.existsSync()) file.deleteSync();
        await maps.downloader.finish(downloadId(region), error: error);
      }
    }
    _readCredits();
    await _openEngine();
  }

  /// Whether a bundle of [build] is still to come: asked for but not
  /// started yet, downloading, or failed.
  bool _waiting(String build) {
    final states = {
      for (final d in maps.downloader.downloads)
        if (d.file?.kind == downloadKind && d.file!.payload['build'] == build)
          d.file!.region: d.state,
    };
    return {...states.keys, ...?_expected[build]}.any(
      (region) => switch (states[region]) {
        PackDownloadState.downloaded ||
        PackDownloadState.installed ||
        PackDownloadState.canceled => false,
        _ => true,
      },
    );
  }

  /// Reads the catalogue again and takes the current build of [d]'s region:
  /// a new build has a new URL, so the same URL would only 404 again.
  Future<void> _retryFromCatalog(PackDownload d) async {
    final region = d.item.region!;
    if (!_recovering.add(region)) return;
    try {
      await maps.refresh();
      final current = bundleFor(region);
      if (current != null && current.url != d.item.url) {
        await download({region});
      }
    } finally {
      _recovering.remove(region);
    }
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
    final index = maps.catalogue;
    if (index == null) return;
    try {
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
    unawaited(_downloads?.cancel());
    engine?.close();
    super.dispose();
  }
}
