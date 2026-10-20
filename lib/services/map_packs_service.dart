import 'dart:async';
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
  /// The pack index. Dev builds point at the frozen test catalogue with
  /// `--dart-define=MAP_INDEX_URL=https://maps.meshtrax.io/dev/index.json`.
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

  /// Holds the cached catalogue (`index.json`, `picker.geojson`).
  final Directory cacheDir;
  final http.Client _client;

  PackIndex? _index;
  RegionIndex? _regions;
  DateTime? _fetchedAt;
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

  List<Pack> get installed => _installed;

  /// Size on disk of an installed pack.
  int sizeOf(Pack pack) => _files[pack.file.path]?.size ?? 0;

  /// When an installed pack was downloaded (its file's time).
  DateTime? installedAt(Pack pack) => _files[pack.file.path]?.modified;

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
    notifyListeners();
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
        await file.writeAsString(response.body);
        final newTag = response.headers['etag'];
        if (newTag != null) {
          await etagFile.writeAsString(newTag);
        } else if (await etagFile.exists()) {
          await etagFile.delete();
        }
        return response.body;
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
    final indexFile = File('${cacheDir.path}/index.json');
    final pickerFile = File('${cacheDir.path}/picker.geojson');
    try {
      if (await indexFile.exists()) {
        _index = _parseIndex(await indexFile.readAsString());
        _fetchedAt = await indexFile.lastModified();
        _status = CatalogueStatus.ready;
      }
      if (await pickerFile.exists()) {
        _regions = RegionIndex.parse(await pickerFile.readAsString());
      }
    } on Object catch (e) {
      appLogger.warn('Cached map catalogue unreadable: $e', tag: 'Maps');
    }
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

  void _onDownload(PackDownload download) {
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
        if (id != null) _styleIds[(type, dark)] = id;
      }
    }
    notifyListeners();
  }

  /// The installed packs a map draws from; the style uses those it needs.
  List<Pack> mapPacks({required bool contours}) => [
    for (final pack in _installed)
      if (pack.kind != PackKind.unknown &&
          (contours || pack.kind != PackKind.contours))
        pack,
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
