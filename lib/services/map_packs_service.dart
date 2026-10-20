import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:traxmap/traxmap.dart';

import '../models/app_settings.dart';
import '../utils/app_logger.dart';
import 'app_settings_service.dart';

/// Where the catalogue stands, for the Offline maps screen.
enum CatalogueStatus {
  /// Nothing fetched or cached yet.
  unknown,
  loading,
  ready,

  /// The server has no index yet (404): "no maps available", not an error.
  unavailable,

  /// The last fetch failed; [MapPacksService.index] may still hold a cached copy.
  error,
}

/// One pack's state as the Offline maps screen shows it.
enum PackStatus {
  available,
  queued,
  running,
  paused,
  waitingToRetry,
  verifying,
  failed,
  installed,
  updateAvailable,
}

/// Offline map packs for the app: the pack server's catalogue
/// (`index.json` and `picker.geojson`, traxmapmaker FINDINGS §1.1–1.2),
/// installed packs, and downloads.
///
/// The catalogue is cached on disk, so the Offline maps screen works
/// offline, and refreshed with `If-None-Match`, so an unchanged file costs
/// a 304. Packs live under `<app support>/maps/packs`.
class MapPacksService extends ChangeNotifier {
  /// The pack index: production, for every build (Martin, 2026-10-20: the
  /// server publishes only finished products, there's no test catalogue).
  /// `--dart-define=MAP_INDEX_URL=…` points at another one, e.g. a local
  /// throttled server for testing pause and resume.
  static final defaultIndexUrl = Uri.parse(
    const String.fromEnvironment(
      'MAP_INDEX_URL',
      defaultValue: 'https://maps.meshtrax.io/index.json',
    ),
  );

  /// How old a cached catalogue may get before launch refreshes it, when
  /// packs are installed (to find updates).
  static const updateCheckInterval = Duration(days: 1);

  final PackManager manager;
  final PackDownloader downloader;
  final Uri indexUrl;

  /// Holds the cached catalogue (`index.json`, `picker.geojson`,
  /// `chart_areas.geojson`).
  final Directory cacheDir;
  final http.Client _client;

  PackIndex? _index;
  RegionIndex? _regions;
  DateTime? _fetchedAt;
  ChartAreaIndex? _chartAreas;
  String? _chartAreasError;
  DateTime? _chartAreasFetchedAt;
  CatalogueStatus _status = CatalogueStatus.unknown;
  String? _error;
  List<Pack> _installed = const [];
  final _files = <String, FileStat>{};
  final _downloads = <String, PackDownload>{};
  Future<void>? _refreshing;
  final _subscriptions = <StreamSubscription<Object?>>[];

  MapPacksService({
    required this.manager,
    required this.downloader,
    required this.cacheDir,
    http.Client? client,
    Uri? indexUrl,
    StyleRegistry? styles,
  }) : _client = client ?? http.Client(),
       indexUrl = indexUrl ?? defaultIndexUrl,
       styles = styles ?? bundledStyles();

  /// Builds the service on the app's storage, restores downloads from the
  /// previous run, and starts an update check if the catalogue is stale.
  static Future<MapPacksService> create(AppSettingsService settings) async {
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/maps',
    );
    final manager = PackManager(Directory('${root.path}/packs'));
    final service = MapPacksService(
      manager: manager,
      downloader: BackgroundPackDownloader(manager),
      cacheDir: root,
    );
    await service.start();
    await service._followWifiSetting(settings);
    return service;
  }

  /// Loads the cached catalogue and installed packs, restores downloads,
  /// and refreshes in the background when packs are installed and the
  /// catalogue is older than [updateCheckInterval].
  Future<void> start() async {
    _subscriptions
      ..add(downloader.updates.listen(_onDownload))
      ..add(manager.changes.listen((_) => unawaited(reloadInstalled())));
    await _loadCache();
    await reloadInstalled();
    final d = downloader;
    if (d is BackgroundPackDownloader) {
      try {
        await d.restore();
      } on Object catch (e) {
        // Never block app start-up over map downloads.
        appLogger.warn('Restoring map downloads failed: $e', tag: 'Maps');
      }
    }
    for (final download in downloader.downloads) {
      _downloads[download.id] = download;
    }
    final fetched = _fetchedAt;
    if (_installed.isNotEmpty &&
        (fetched == null ||
            DateTime.now().difference(fetched) > updateCheckInterval)) {
      unawaited(refresh());
    }
  }

  CatalogueStatus get status => _status;
  String? get error => _error;

  /// The cached or fetched pack index; null before the first fetch.
  PackIndex? get index => _index;

  /// The picker's region tree; null before the first fetch.
  RegionIndex? get regions => _regions;

  /// When the catalogue shown was fetched (the cache file's time).
  DateTime? get fetchedAt => _fetchedAt;

  /// The NOAA chart areas for the Charts tab; null before the first fetch
  /// and while the server has none.
  ChartAreaIndex? get chartAreas => _chartAreas;

  /// Why the last fetch of the chart areas failed. Kept apart from [error]
  /// so a charts problem never puts the Maps tab in an error state.
  String? get chartAreasError => _chartAreasError;

  /// When the chart areas shown were fetched (the cache file's time).
  DateTime? get chartAreasFetchedAt => _chartAreasFetchedAt;

  /// The charts pack for a chart area's [packRegion].
  PackIndexEntry? chartPackOf(String packRegion) =>
      packsForRegion(packRegion)
          .where((e) => e.kind == PackKind.charts)
          .firstOrNull;

  List<Pack> get installed => _installed;

  /// Size on disk of an installed pack.
  int sizeOf(Pack pack) => _files[pack.file.path]?.size ?? 0;

  /// When an installed pack was downloaded (its file's time).
  DateTime? installedAt(Pack pack) => _files[pack.file.path]?.modified;

  /// Where to open a map with nothing else to show: the most recently
  /// installed street or topo map, framed, but no further out than its packs
  /// draw (a big region shows its middle).
  MapFit? get latestMapFit {
    final maps =
        _installed
            .where((p) => p.kind == PackKind.osm || p.kind == PackKind.base)
            .toList()
          ..sort(
            (a, b) => (installedAt(a) ?? DateTime(0)).compareTo(
              installedAt(b) ?? DateTime(0),
            ),
          );
    if (maps.isEmpty) return null;
    final pack = maps.last;
    return MapFit.bounds(pack.bounds, minZoom: pack.minZoom.toDouble());
  }

  /// Bytes used by all installed packs.
  int get installedBytes => _installed.fold(0, (sum, p) => sum + sizeOf(p));

  /// Fetches `index.json` and `picker.geojson`. Concurrent calls share one
  /// fetch.
  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    _status = CatalogueStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final indexBody = await _fetch(indexUrl, 'index.json');
      if (indexBody == null) {
        _status = CatalogueStatus.unavailable;
        notifyListeners();
        return;
      }
      _index = _parseIndex(indexBody);
      final pickerBody = await _fetch(
        indexUrl.resolve('picker.geojson'),
        'picker.geojson',
      );
      if (pickerBody != null) _regions = RegionIndex.parse(pickerBody);
      _fetchedAt = DateTime.now();
      _status = CatalogueStatus.ready;
    } on Object catch (e) {
      appLogger.warn('Map catalogue refresh failed: $e', tag: 'Maps');
      _error = '$e';
      _status = CatalogueStatus.error;
    }
    if (_status == CatalogueStatus.ready) await _refreshChartAreas();
    notifyListeners();
  }

  /// Fetches `chart_areas.geojson`. Its own failure is recorded in
  /// [chartAreasError]; a 404 (none published) keeps what was cached.
  Future<void> _refreshChartAreas() async {
    try {
      final body = await _fetch(
        indexUrl.resolve('chart_areas.geojson'),
        'chart_areas.geojson',
      );
      if (body != null) {
        _chartAreas = _parseChartAreas(body);
        _chartAreasFetchedAt = DateTime.now();
      }
      _chartAreasError = null;
    } on Object catch (e) {
      appLogger.warn('Chart areas refresh failed: $e', tag: 'Maps');
      _chartAreasError = '$e';
    }
  }

  /// GETs [url], cached as [name] with its ETag. Returns the body (fresh or
  /// cached on a 304), or null on a 404.
  Future<String?> _fetch(Uri url, String name) async {
    final file = File('${cacheDir.path}/$name');
    final etagFile = File('${file.path}.etag');
    final etag = await etagFile.exists() ? await etagFile.readAsString() : null;
    final cached = await file.exists();
    final response = await _client
        .get(url, headers: {if (cached && etag != null) 'If-None-Match': etag})
        .timeout(const Duration(seconds: 30));
    switch (response.statusCode) {
      case 200:
        await cacheDir.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        final newTag = response.headers['etag'];
        if (newTag != null) {
          await etagFile.writeAsString(newTag);
        } else if (await etagFile.exists()) {
          await etagFile.delete();
        }
        // JSON is UTF-8 (RFC 8259). The server names no charset, and
        // response.body would then decode as Latin-1.
        return utf8.decode(response.bodyBytes);
      case 304 when cached:
        await file.setLastModified(DateTime.now());
        return file.readAsString();
      case 404:
        return null;
      default:
        throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
  }

  Future<void> _loadCache() async {
    // Each file on its own, so one unreadable file can't hide the others.
    Future<void> read(String name, Future<void> Function(File file) use) async {
      final file = File('${cacheDir.path}/$name');
      try {
        if (await file.exists()) await use(file);
      } on Object catch (e) {
        appLogger.warn('Cached $name unreadable: $e', tag: 'Maps');
      }
    }

    await read('index.json', (file) async {
      _index = _parseIndex(await file.readAsString());
      _fetchedAt = await file.lastModified();
      _status = CatalogueStatus.ready;
    });
    await read('picker.geojson', (file) async {
      _regions = RegionIndex.parse(await file.readAsString());
    });
    await read('chart_areas.geojson', (file) async {
      _chartAreas = _parseChartAreas(await file.readAsString());
      _chartAreasFetchedAt = await file.lastModified();
    });
  }

  ChartAreaIndex _parseChartAreas(String body) {
    final areas = ChartAreaIndex.parse(body);
    for (final skipped in areas.skipped) {
      appLogger.warn('Chart area skipped: $skipped', tag: 'Maps');
    }
    return areas;
  }

  PackIndex _parseIndex(String body) {
    final index = PackIndex.parse(body);
    for (final skipped in index.skipped) {
      appLogger.warn('Pack index entry skipped: $skipped', tag: 'Maps');
    }
    return index;
  }

  /// Re-reads the installed packs from disk.
  Future<void> reloadInstalled() async {
    final packs = await manager.listInstalled(
      onError: (file, e) =>
          appLogger.warn('Unreadable map pack ${file.path}: $e', tag: 'Maps'),
    );
    _files.clear();
    for (final pack in packs) {
      _files[pack.file.path] = await pack.file.stat();
    }
    _installed = packs;
    notifyListeners();
  }

  Future<void> _onDownload(PackDownload download) async {
    // Until the installed list has the new build, the row would flash
    // "Download" or "Update" between "Checking" and "Downloaded".
    if (download.state == PackDownloadState.installed) await reloadInstalled();
    _downloads[download.id] = download;
    notifyListeners();
  }

  // --- Drawing -------------------------------------------------------------

  /// The map styles (the bundled ones unless given), shared by every map so
  /// each loads once.
  final StyleRegistry styles;

  final _styleIds = <(MapType, bool), String>{};
  Future<void>? _loadingStyleIds;

  /// The style for [type] in light or dark, or null until the style list
  /// has loaded (listeners are notified then).
  String? styleId(MapType type, {required bool dark}) {
    final id = _styleIds[(type, dark)];
    if (id == null) _loadingStyleIds ??= _loadStyleIds();
    return id;
  }

  Future<void> _loadStyleIds() async {
    for (final type in MapType.values) {
      for (final dark in [false, true]) {
        final id = await styles.styleFor(type, dark: dark);
        if (id == null) continue;
        _styleIds[(type, dark)] = id;
        _requiredKinds[type] = (await styles.info(id)).requiredKinds;
      }
    }
    notifyListeners();
  }

  final _requiredKinds = <MapType, Set<PackKind>>{};

  /// Whether [type] has anything to draw: an installed pack of a kind its
  /// style needs. OSM always does, from online tiles where there's none.
  bool hasMap(MapType type) =>
      type == MapType.osm ||
      _installed.any((p) => _requiredKinds[type]?.contains(p.kind) ?? false);

  /// The installed packs a map draws from; the style uses those it needs.
  /// Contours come last so the map's own credit leads the credits.
  List<Pack> mapPacks({required bool contours}) => [
    for (final pack in _installed)
      if (pack.kind != PackKind.unknown && pack.kind != PackKind.contours) pack,
    if (contours)
      for (final pack in _installed)
        if (pack.kind == PackKind.contours) pack,
  ];

  // --- Catalogue queries ---------------------------------------------------

  /// Packs offered for the region at [path].
  List<PackIndexEntry> packsForRegion(String path) =>
      _index?.forRegion(path) ?? const [];

  /// The packs a region's Download button starts with: the map, plus the
  /// contours variant for [units] (or the first one). USGS is opt-in.
  List<PackIndexEntry> defaultSelection(String path, UnitSystem units) {
    final packs = packsForRegion(path);
    final contours = packs.where((e) => e.kind == PackKind.contours).toList();
    final wanted = Units.parse(units.value);
    return [
      ...packs.where((e) => e.kind == PackKind.osm),
      if (contours.isNotEmpty)
        contours.firstWhere(
          (e) => e.units == wanted,
          orElse: () => contours.first,
        ),
    ];
  }

  /// The installed pack with [id], if any.
  Pack? installedPack(String id) {
    for (final pack in _installed) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// Region paths with at least one installed pack.
  Set<String> get installedRegions => {
    for (final pack in _installed)
      if (pack.region != null) pack.region!,
  };

  /// The download in progress (or last finished) for [id], if any.
  PackDownload? downloadOf(String id) => _downloads[id];

  PackStatus statusOf(PackIndexEntry entry) {
    final download = _downloads[entry.id];
    if (download != null) {
      switch (download.state) {
        case PackDownloadState.queued:
          return PackStatus.queued;
        case PackDownloadState.running:
          return PackStatus.running;
        case PackDownloadState.paused:
          return PackStatus.paused;
        case PackDownloadState.waitingToRetry:
          return PackStatus.waitingToRetry;
        case PackDownloadState.verifying:
          return PackStatus.verifying;
        case PackDownloadState.failed:
          return PackStatus.failed;
        case PackDownloadState.installed || PackDownloadState.canceled:
          break;
      }
    }
    final pack = installedPack(entry.id);
    if (pack == null) return PackStatus.available;
    return pack.isBuild(entry.sha256) == false
        ? PackStatus.updateAvailable
        : PackStatus.installed;
  }

  /// Index entries whose installed pack is an older build.
  List<PackIndexEntry> get updates => [
    for (final entry in _index?.usable ?? const <PackIndexEntry>[])
      if (statusOf(entry) == PackStatus.updateAvailable) entry,
  ];

  /// Downloads still going, for the Downloaded tab's badge.
  /// Downloads still going (or failed, so they can be retried).
  List<PackDownload> get activeDownloads => [
    for (final d in _downloads.values)
      if (!d.state.isFinal || d.state == PackDownloadState.failed) d,
  ];

  int get activeDownloadCount =>
      _downloads.values.where((d) => !d.state.isFinal).length;

  /// Badge for "Offline maps": active downloads plus available updates.
  int get badgeCount => activeDownloadCount + updates.length;

  // --- Actions -------------------------------------------------------------

  /// Starts downloading [entries]; already-active ones are left alone.
  Future<void> download(Iterable<PackIndexEntry> entries) async {
    final d = downloader;
    if (d is BackgroundPackDownloader) {
      await d.requestNotificationPermission();
    }
    for (final entry in entries) {
      await downloader.start(entry);
    }
  }

  /// Translated titles for the download notifications (Android).
  void setNotificationTitles({
    required String running,
    required String paused,
    required String failed,
  }) {
    final titles = (running, paused, failed);
    if (titles == _notificationTitles) return;
    _notificationTitles = titles;
    final d = downloader;
    if (d is BackgroundPackDownloader) {
      d.configureNotifications(
        running: running,
        paused: paused,
        failed: failed,
      );
    }
  }

  (String, String, String)? _notificationTitles;

  Future<void> pause(String id) => downloader.pause(id);
  Future<void> resume(String id) => downloader.resume(id);
  Future<void> cancel(String id) => downloader.cancel(id);

  /// Downloads every available update.
  Future<void> updateAll() => download(updates);

  /// Deletes the installed packs of the region at [path], cancelling any of
  /// its downloads first. Returns the bytes freed.
  Future<int> deleteRegion(String path) async {
    for (final entry in packsForRegion(path)) {
      final download = _downloads[entry.id];
      if (download != null && !download.state.isFinal) {
        await downloader.cancel(entry.id);
      }
    }
    var freed = 0;
    for (final pack in _installed.where((pk) => pk.region == path).toList()) {
      freed += sizeOf(pack);
      await manager.delete(pack);
    }
    return freed;
  }

  Future<void> deletePack(Pack pack) => manager.delete(pack);

  Future<void> _followWifiSetting(AppSettingsService settings) async {
    final d = downloader;
    if (d is! BackgroundPackDownloader) return;
    var wifiOnly = settings.settings.mapDownloadsWifiOnly;
    await d.setRequiresWiFi(wifiOnly);
    settings.addListener(() {
      final now = settings.settings.mapDownloadsWifiOnly;
      if (now == wifiOnly) return;
      wifiOnly = now;
      unawaited(d.setRequiresWiFi(now));
    });
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _client.close();
    super.dispose();
  }
}
