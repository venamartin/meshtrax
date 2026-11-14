import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:traxmap/traxmap.dart';

import '../models/app_settings.dart';
import '../utils/app_logger.dart';
import 'app_settings_service.dart';
import 'drive_folder.dart';

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

  /// Downloads from the server and installs from a drive, as one: what the
  /// screens, and the routing and places installers, follow.
  final CombinedPackDownloader downloader;
  final Uri indexUrl;

  /// Holds the cached catalogue (`index.json`, `picker.geojson`,
  /// `chart_areas.geojson`).
  final Directory cacheDir;
  final http.Client _client;

  PackIndex? _index;
  Map<String, dynamic>? _catalogue;
  RegionIndex? _regions;
  DateTime? _fetchedAt;
  ChartAreaIndex? _chartAreas;
  MapHints? _hints;
  String? _chartAreasError;
  DateTime? _chartAreasFetchedAt;
  CatalogueStatus _status = CatalogueStatus.unknown;
  String? _error;
  List<Pack> _installed = const [];

  /// The world base map bundled with traxmap, once [openWorld] has copied
  /// it into [cacheDir].
  Pack? get world => _world;
  Pack? _world;
  final _files = <String, FileStat>{};
  final _downloads = <String, PackDownload>{};
  Future<void>? _refreshing;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// [downloader] downloads from the server; installs from a drive have a
  /// downloader of their own beside it.
  MapPacksService({
    required this.manager,
    required PackDownloader downloader,
    required this.cacheDir,
    http.Client? client,
    Uri? indexUrl,
    StyleRegistry? styles,
  }) : downloader = CombinedPackDownloader(
         downloader,
         DrivePackDownloader(manager),
       ),
       _client = client ?? http.Client(),
       indexUrl = indexUrl ?? defaultIndexUrl,
       styles = styles ?? bundledStyles();

  /// Builds the service on the app's storage, restores downloads from the
  /// previous run, and starts an update check if the catalogue is stale.
  static Future<MapPacksService> create(AppSettingsService settings) async {
    final support = await getApplicationSupportDirectory();
    unawaited(
      removeOnlineTileCache(
        temp: await getTemporaryDirectory(),
        support: support,
      ),
    );
    final root = Directory('${support.path}/maps');
    await keepOutOfBackups(root);
    final manager = PackManager(Directory('${root.path}/packs'));
    final service = MapPacksService(
      manager: manager,
      downloader: BackgroundPackDownloader(manager),
      cacheDir: root,
    )..keepAwake = keepScreenOn;
    await service.start();
    await service.openWorld();
    await service._followWifiSetting(settings);
    return service;
  }

  /// Opens the base map bundled with the app, which maps draw where no
  /// region pack reaches. A failure leaves those parts empty.
  Future<void> openWorld({AssetBundle? bundle}) async {
    try {
      _world = await openBundledWorld(cacheDir, bundle: bundle);
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Opening the world map failed: $e', tag: 'Maps');
    }
  }

  /// Deletes what the online map tiles left on the device before the app
  /// dropped them (1.9.0): up to 200,000 cached tiles in [temp] and their
  /// index in [support] (flutter_cache_manager's `map_tile_cache`).
  static Future<void> removeOnlineTileCache({
    required Directory temp,
    required Directory support,
  }) async {
    try {
      final tiles = Directory('${temp.path}/map_tile_cache');
      if (await tiles.exists()) await tiles.delete(recursive: true);
      // The index: SQLite on Android, iOS and macOS, else JSON.
      for (final suffix in const [
        'db',
        'db-journal',
        'db-wal',
        'db-shm',
        'json',
      ]) {
        final file = File('${support.path}/map_tile_cache.$suffix');
        if (await file.exists()) await file.delete();
      }
    } on Object catch (e) {
      appLogger.warn('Removing the online tile cache failed: $e', tag: 'Maps');
    }
  }

  /// Keeps [dir] out of iCloud and Time Machine backups (iOS, macOS). Maps
  /// can be downloaded again, and Apple's storage rules say such files
  /// must not be backed up. Android's backup rules exclude it in XML.
  @visibleForTesting
  static Future<void> keepOutOfBackups(Directory dir) async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    try {
      await dir.create(recursive: true);
      await const MethodChannel('meshtrax/storage')
          .invokeMethod<void>('excludeFromBackup', dir.path);
    } on Object catch (e) {
      appLogger.warn('Could not keep maps out of backups: $e', tag: 'Maps');
    }
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
    try {
      await downloader.drive.clean();
    } on Object catch (e) {
      appLogger.warn('Clearing drive copies failed: $e', tag: 'Maps');
    }
    final d = downloader.network;
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

  CatalogueStatus get status =>
      _onDrive != null ? CatalogueStatus.ready : _status;
  String? get error => _onDrive != null ? null : _error;

  /// The cached or fetched pack index, or the drive's in use; null before
  /// the first fetch.
  PackIndex? get index => _onDrive?.index ?? _index;

  /// The whole `index.json` behind [index], decoded, for the modules that
  /// download beside the packs (routing, places) to read their entries
  /// from. Null before the first fetch.
  Map<String, dynamic>? get catalogue =>
      _onDrive != null ? _onDrive!.catalogue : _catalogue;

  /// The picker's region tree; null before the first fetch.
  RegionIndex? get regions => _onDrive?.regions ?? _regions;

  /// When the catalogue shown was fetched (the cache file's time).
  DateTime? get fetchedAt => _fetchedAt;

  /// The NOAA chart areas for the Charts tab; null before the first fetch
  /// and while the server has none. On a drive, only those whose charts it
  /// holds.
  ChartAreaIndex? get chartAreas =>
      _onDrive != null ? _onDrive!.chartAreas : _chartAreas;

  /// Small map facts the styles need (desert parks, …), fetched with the
  /// catalogue and kept for offline use.
  MapHints? get hints => _hints;

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

  /// When the pack with [id] was downloaded, if it is installed.
  DateTime? installedAtOf(String id) {
    final pack = installedPack(id);
    return pack == null ? null : installedAt(pack);
  }

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
      _refreshing ??= (_onDrive != null ? _rereadDrive() : _refresh())
          .whenComplete(() => _refreshing = null);

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
      _useIndex(indexBody);
      await _refreshHints(_catalogue!['hints']);
      final pickerBody = await _fetch(
        indexUrl.resolve('picker.geojson'),
        'picker.geojson',
      );
      if (pickerBody != null) _regions = RegionIndex.parse(pickerBody);
      // Before "ready": until then the Charts tab would say there are none.
      await _refreshChartAreas();
      _fetchedAt = DateTime.now();
      _status = CatalogueStatus.ready;
    } on Object catch (e) {
      appLogger.warn('Map catalogue refresh failed: $e', tag: 'Maps');
      _error = '$e';
      _status = CatalogueStatus.error;
    }
    notifyListeners();
  }

  /// Fetches the hints the catalogue lists (`hints`: url, sha256), unless the
  /// cached copy already has that sha256. A failure keeps what was cached.
  Future<void> _refreshHints(Object? entry) async {
    if (entry is! Map) return;
    try {
      final file = File('${cacheDir.path}/hints.json');
      final sha = entry['sha256'] as String;
      if (!await file.exists() ||
          sha256.convert(await file.readAsBytes()).toString() != sha) {
        final url = indexUrl.resolve(entry['url'] as String);
        final response = await _client
            .get(url)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: url);
        }
        if (sha256.convert(response.bodyBytes).toString() != sha) {
          throw HttpException('sha256 mismatch', uri: url);
        }
        await cacheDir.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
      _hints = MapHints.parse(await file.readAsString());
    } on Object catch (e) {
      appLogger.warn('Map hints refresh failed: $e', tag: 'Maps');
    }
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
        // JSON is UTF-8 (RFC 8259, FINDINGS §1.1). Decoded here, not by
        // response.body, which falls back to Latin-1 without a charset.
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
      _useIndex(await file.readAsString());
      _fetchedAt = await file.lastModified();
      _status = CatalogueStatus.ready;
    });
    await read('picker.geojson', (file) async {
      _regions = RegionIndex.parse(await file.readAsString());
    });
    await read('hints.json', (file) async {
      _hints = MapHints.parse(await file.readAsString());
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

  /// Takes [body], an `index.json`, as the catalogue: its packs, and the
  /// whole index for the modules beside them.
  void _useIndex(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('pack index is not a JSON object');
    }
    final index = PackIndex.fromJson(json);
    for (final skipped in index.skipped) {
      appLogger.warn('Pack index entry skipped: $skipped', tag: 'Maps');
    }
    _index = index;
    _catalogue = json;
    _catalogueVersion++;
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
    final pack = download.entry != null;
    // Until the installed list has the new build, the row would flash
    // "Download" or "Update" between "Checking" and "Downloaded".
    if (pack && download.state == PackDownloadState.installed) {
      await reloadInstalled();
    }
    final verifying =
        _downloads[download.id]?.state == PackDownloadState.verifying;
    _downloads[download.id] = download;
    final busy = downloader.drive.downloads.any(
      (d) => switch (d.state) {
        PackDownloadState.queued ||
        PackDownloadState.running ||
        PackDownloadState.verifying => true,
        _ => false,
      },
    );
    if (busy != _driveBusy) {
      _driveBusy = busy;
      unawaited(
        keepAwake?.call(busy).catchError((Object e) {
          appLogger.warn('Keeping the screen on failed: $e', tag: 'Maps');
        }),
      );
    }
    notifyListeners();
    // Rejected once downloaded (its SHA-256): the pack may have been
    // republished during the download, so the entry it began with is old.
    // Routing and places look after their own. A drive's copy is simply
    // damaged.
    if (pack &&
        verifying &&
        download.state == PackDownloadState.failed &&
        !downloader.drive.owns(download.id)) {
      unawaited(_retryIfRepublished(download));
    }
  }

  final _recovering = <String>{};

  /// Fetches the catalogue again and, if [failed]'s pack has a new build,
  /// downloads that one.
  Future<void> _retryIfRepublished(PackDownload failed) async {
    if (!_recovering.add(failed.id)) return;
    try {
      await refresh();
      final entry = _entryOf(failed.id);
      if (entry != null && entry.sha256 != failed.item.sha256) {
        await resume(failed.id);
      }
    } finally {
      _recovering.remove(failed.id);
    }
  }

  PackIndexEntry? _entryOf(String id) =>
      index?.usable.where((e) => e.id == id).firstOrNull;

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
  /// style needs. OSM always does, from the bundled base map.
  bool hasMap(MapType type) =>
      type == MapType.osm ||
      _installed.any((p) => _requiredKinds[type]?.contains(p.kind) ?? false);

  /// Whether a pack of [kind] is installed anywhere.
  bool hasKind(PackKind kind) => _installed.any((p) => p.kind == kind);

  /// The installed packs a map draws from; the style uses those it needs.
  /// Contours come last so the map's own credit leads the credits, and the
  /// bundled base map after them.
  List<Pack> mapPacks({required bool contours, required bool hillShading}) => [
    for (final pack in _installed)
      if (pack.kind != PackKind.unknown &&
          pack.kind != PackKind.contours &&
          (hillShading || pack.kind != PackKind.terrain))
        pack,
    if (contours)
      for (final pack in _installed)
        if (pack.kind == PackKind.contours) pack,
    ?_world,
  ];

  // --- Catalogue queries ---------------------------------------------------

  /// Packs offered for the region at [path].
  List<PackIndexEntry> packsForRegion(String path) =>
      index?.forRegion(path) ?? const [];

  /// The packs a region's Download button starts with: the map alone.
  /// Contours, hill shading and USGS are opt-in (Martin, 2026-11-02).
  List<PackIndexEntry> defaultSelection(String path) => [
    ...packsForRegion(path).where((e) => e.kind == PackKind.osm),
  ];

  /// The region's contours in [units], else its first contours; null where
  /// it has none.
  PackIndexEntry? preferredContours(String path, UnitSystem units) {
    final contours = packsForRegion(path)
        .where((e) => e.kind == PackKind.contours);
    final wanted = Units.parse(units.value);
    return contours.where((e) => e.units == wanted).firstOrNull ??
        contours.firstOrNull;
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

  /// The outlines of what [type] draws from downloaded packs, by region
  /// path: the region's shape for street and topo maps, the NOAA chart area
  /// for charts. Each polygon is its outer ring followed by any holes.
  Map<String, List<List<List<LatLng>>>> downloadedAreas(MapType type) {
    final kinds = _requiredKinds[type] ?? const <PackKind>{};
    final charts = {
      for (final area in _allChartAreas?.areas ?? const <ChartArea>[])
        area.packRegion: area.polygons,
    };
    return {
      for (final pack in _installed)
        if (pack.region case final region? when kinds.contains(pack.kind))
          region: ?(_allRegions?[region]?.polygons ?? charts[region]),
    };
  }

  /// Whether a region of [type]'s map is downloaded at [point].
  bool downloadedAt(MapType type, LatLng point) {
    final areas = downloadedAreas(type);
    final here = type == MapType.charts
        ? [
            for (final a
                in _allChartAreas?.areasAt(point) ?? const <ChartArea>[])
              a.packRegion,
          ]
        : [?_allRegions?.regionAt(point)?.path];
    return here.any(areas.containsKey);
  }

  /// Every region's outline, for packs installed from anywhere: the
  /// server's, else a drive's.
  RegionIndex? get _allRegions => _regions ?? _onDrive?.regions;

  /// Every chart area, for charts installed from anywhere.
  ChartAreaIndex? get _allChartAreas => _chartAreas ?? _onDrive?.allChartAreas;

  /// The download in progress (or last finished) for [id], if any.
  PackDownload? downloadOf(String id) => _downloads[id];

  /// How the download with [id] is going (a pack's, or routing or places),
  /// or null when none is, or it is over.
  PackStatus? downloadStatus(String id) => switch (_downloads[id]?.state) {
    PackDownloadState.queued => PackStatus.queued,
    PackDownloadState.running => PackStatus.running,
    PackDownloadState.paused => PackStatus.paused,
    PackDownloadState.waitingToRetry => PackStatus.waitingToRetry,
    PackDownloadState.verifying ||
    PackDownloadState.downloaded => PackStatus.verifying,
    PackDownloadState.failed => PackStatus.failed,
    PackDownloadState.installed || PackDownloadState.canceled || null => null,
  };

  PackStatus statusOf(PackIndexEntry entry) {
    final downloading = downloadStatus(entry.id);
    if (downloading != null) return downloading;
    final pack = installedPack(entry.id);
    if (pack == null) return PackStatus.available;
    return pack.isBuild(entry.sha256) == false && _mayReplace(entry, pack)
        ? PackStatus.updateAvailable
        : PackStatus.installed;
  }

  /// Whether [entry] may replace the installed [pack]: always from the
  /// server, so a build it takes back still reaches phones, but from a
  /// drive only when it's a later build, so an old drive never takes a
  /// phone back.
  bool _mayReplace(PackIndexEntry entry, Pack pack) {
    if (_onDrive == null) return true;
    final built = pack.buildDate;
    return built == null || entry.buildDate.isAfter(built);
  }

  /// Index entries whose installed pack is an older build.
  List<PackIndexEntry> get updates => [
    for (final entry in index?.usable ?? const <PackIndexEntry>[])
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

  // --- Drive ---------------------------------------------------------------

  /// The folder a stick's maps sit in (traxmapmaker's thumb drive).
  static const driveFolder = 'MeshTrax-maps';

  _OnDrive? _onDrive;
  Timer? _driveCheck;
  var _driveRemoved = false;
  var _catalogueVersion = 0;

  /// Changes whenever the catalogue shown changes: fetched, read from the
  /// cache, or switched to or from a drive.
  int get catalogueVersion => _catalogueVersion;

  /// The drive whose maps the screens show and install, or null for the
  /// server's ("Use a drive").
  MapDrive? get drive => _onDrive?.drive;

  /// When the drive's maps were made: its `index.json`'s `generated`.
  DateTime? get driveMapsDate => _onDrive?.index.generated;

  /// Whether the drive in use went away; until another is chosen, or the
  /// notice is dismissed.
  bool get driveRemoved => _driveRemoved;

  void dismissDriveRemoved() {
    _driveRemoved = false;
    notifyListeners();
  }

  /// Whether files are copying from the drive: the app must stay open.
  bool get driveBusy => _driveBusy;
  var _driveBusy = false;

  /// Keeps the screen on while files copy from a drive; set by [create].
  Future<void> Function(bool on)? keepAwake;

  /// Whether a drive chosen is being read, before its maps show.
  bool get readingDrive => _readingDrive;
  var _readingDrive = false;

  /// Whether the region at [path], or one inside it, has anything to
  /// install from the drive in use. Always true for the server's.
  bool hasContent(String path) =>
      _onDrive?.regionPaths.any((r) => r == path || r.startsWith('$path/')) ??
      true;

  /// Shows and installs what [drive] holds instead of the server's
  /// catalogue: the files its `index.json` lists that are on it, at their
  /// URL paths, with the sizes it lists. Takes the folder chosen, or the
  /// one inside it that holds the maps ([driveFolder] first). Throws a
  /// [FormatException] when neither has an `index.json`.
  Future<void> useDrive(MapDrive drive) async {
    _readingDrive = true;
    notifyListeners();
    final _OnDrive read;
    try {
      read = await _readDrive(drive);
    } finally {
      _readingDrive = false;
      notifyListeners();
    }
    await _leaveDrive();
    downloader.drive.attach(read.drive, _drivePath);
    _onDrive = read;
    _driveRemoved = false;
    _catalogueVersion++;
    _driveCheck = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(checkDrive()),
    );
    notifyListeners();
    await _seedCache(read);
    await _takeNewerHints(read);
  }

  /// Back to the server's catalogue. Unfinished installs from the drive
  /// stop: canceled, or failed when the drive was [removed].
  Future<void> useInternet({bool removed = false}) async {
    if (_onDrive == null) return;
    await _leaveDrive(error: removed ? DrivePackDownloader.removedError : null);
    _driveRemoved = removed;
    _catalogueVersion++;
    notifyListeners();
  }

  /// Goes back to the server's catalogue when the drive in use can't be
  /// read any more. True while the drive is there.
  Future<bool> checkDrive() async {
    final drive = this.drive;
    if (drive == null) return false;
    if (await drive.isReadable()) return true;
    if (this.drive == drive) await useInternet(removed: true);
    return false;
  }

  Future<void> _leaveDrive({String? error}) async {
    final onDrive = _onDrive;
    if (onDrive == null) return;
    _driveCheck?.cancel();
    _onDrive = null;
    await downloader.drive.detach(error: error);
    try {
      await onDrive.drive.close();
    } on Object catch (e) {
      appLogger.warn('Letting go of the drive failed: $e', tag: 'Maps');
    }
  }

  /// The drive in use, read again: files added or gone since.
  Future<void> _rereadDrive() async {
    final onDrive = _onDrive;
    if (onDrive == null || !await checkDrive()) return;
    try {
      final read = await _readDrive(onDrive.drive);
      if (_onDrive != onDrive) return;
      _onDrive = read;
      _catalogueVersion++;
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Reading the drive again failed: $e', tag: 'Maps');
    }
  }

  /// Where the file at [url] sits on a drive: its path below the server's
  /// root, the folder of [indexUrl]; null when it's elsewhere.
  String? _drivePath(Uri url) {
    final root = Uri.decodeFull(indexUrl.resolve('.').path);
    final path = Uri.decodeFull(url.path);
    return path.startsWith(root) && path.length > root.length
        ? path.substring(root.length)
        : null;
  }

  /// Reads [drive]'s catalogue, keeping only the files that are on it.
  Future<_OnDrive> _readDrive(MapDrive drive) async {
    var files = await drive.list();
    if (!files.containsKey('index.json')) {
      final folders = [
        for (final path in files.keys)
          if (path.split('/') case [final folder, 'index.json']) folder,
      ];
      final folder = folders.contains(driveFolder)
          ? driveFolder
          : folders.firstOrNull;
      if (folder == null) {
        throw const FormatException('No index.json on the drive');
      }
      drive = drive.inFolder(folder);
      files = {
        for (final MapEntry(:key, :value) in files.entries)
          if (key.startsWith('$folder/'))
            key.substring(folder.length + 1): value,
      };
    }
    final body = await drive.readText('index.json');
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('pack index is not a JSON object');
    }
    bool onDrive(Object? entry) {
      if (entry is! Map || entry['url'] is! String) return false;
      final path = _drivePath(indexUrl.resolve(entry['url'] as String));
      return path != null && files[path] == entry['bytes'];
    }

    final catalogue = _onlyOnDrive(json, onDrive);
    final index = PackIndex.fromJson(catalogue);
    Future<String?> text(String name) async =>
        files.containsKey(name) ? drive.readText(name) : null;
    final picker = await text('picker.geojson');
    final chartsBody = await text('chart_areas.geojson');
    final charts = chartsBody == null ? null : _parseChartAreas(chartsBody);
    final chartRegions = {
      for (final e in index.usable)
        if (e.kind == PackKind.charts) e.region,
    };
    final routing = catalogue['routing'];
    final poi = catalogue['poi'];
    return _OnDrive(
      drive: drive,
      files: files,
      body: body,
      index: index,
      catalogue: catalogue,
      pickerBody: picker,
      regions: picker == null ? null : RegionIndex.parse(picker),
      chartAreasBody: chartsBody,
      allChartAreas: charts,
      chartAreas: charts?.where((a) => chartRegions.contains(a.packRegion)),
      regionPaths: {
        for (final e in index.usable) ?e.region,
        if (routing is Map)
          for (final engine in routing.values)
            if (engine is Map && engine['regions'] is Map)
              ...(engine['regions'] as Map).keys.cast<String>(),
        if (poi is Map && poi['regions'] is Map)
          ...(poi['regions'] as Map).keys.cast<String>(),
      },
    );
  }

  /// [json], an `index.json`, with only the files [onDrive] keeps: packs,
  /// routing bundles and places files. Everything else stays as it is.
  static Map<String, dynamic> _onlyOnDrive(
    Map<String, dynamic> json,
    bool Function(Object? entry) onDrive,
  ) {
    final routing = json['routing'];
    final poi = json['poi'];
    return <String, dynamic>{
      ...json,
      'packs': [
        for (final e in json['packs'] as List<Object?>? ?? const [])
          if (onDrive(e)) e,
      ],
      if (routing is Map)
        'routing': {
          for (final MapEntry(:key, :value) in routing.entries)
            key: value is Map && value['regions'] is Map
                ? {
                    ...value,
                    'regions': {
                      for (final MapEntry(key: region, value: bundle)
                          in (value['regions'] as Map).entries)
                        if (onDrive(bundle)) region: bundle,
                    },
                  }
                : value,
        },
      if (poi is Map && poi['regions'] is Map)
        'poi': {
          ...poi,
          'regions': {
            for (final MapEntry(key: region, value: files)
                in (poi['regions'] as Map).entries)
              if (files is Map)
                if ({
                      for (final MapEntry(:key, :value) in files.entries)
                        if (onDrive(value)) key: value,
                    }
                    case final kept when kept.isNotEmpty)
                  region: kept,
          },
        },
    };
  }

  /// A phone that has never had the server's catalogue keeps the drive's
  /// as its cache, dated by its `generated` and with no ETag, so the first
  /// refresh online replaces it.
  Future<void> _seedCache(_OnDrive read) async {
    try {
      if (await File('${cacheDir.path}/index.json').exists()) return;
      await cacheDir.create(recursive: true);
      final generated = read.index.generated;
      for (final (name, body) in [
        ('picker.geojson', read.pickerBody),
        ('chart_areas.geojson', read.chartAreasBody),
        ('index.json', read.body),
      ]) {
        if (body == null) continue;
        final file = File('${cacheDir.path}/$name');
        await file.writeAsString(body);
        if (generated != null) await file.setLastModified(generated);
      }
      await _loadCache();
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Keeping the drive catalogue failed: $e', tag: 'Maps');
    }
  }

  /// Takes the drive's map hints when they're newer than the phone's.
  Future<void> _takeNewerHints(_OnDrive read) async {
    final entry = read.catalogue['hints'];
    if (entry is! Map || entry['url'] is! String) return;
    final have = (_catalogue?['hints'] as Map?)?['build'];
    final build = entry['build'];
    if (_hints != null &&
        have is String &&
        (build is! String || build.compareTo(have) <= 0)) {
      return;
    }
    final path = _drivePath(indexUrl.resolve(entry['url'] as String));
    if (path == null || read.files[path] != entry['bytes']) return;
    try {
      final body = await read.drive.readText(path);
      if (sha256.convert(utf8.encode(body)).toString() != entry['sha256']) {
        return;
      }
      await cacheDir.create(recursive: true);
      await File('${cacheDir.path}/hints.json').writeAsString(body);
      _hints = MapHints.parse(body);
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Map hints on the drive unreadable: $e', tag: 'Maps');
    }
  }

  // --- Actions -------------------------------------------------------------

  /// Starts downloading [items] (packs, or routing and places files), or
  /// installing them from the drive in use; already-active ones are left
  /// alone. From a drive, items still downloading from the server are
  /// left to finish.
  Future<void> download(Iterable<DownloadItem> items) async {
    if (drive != null) {
      if (!await checkDrive()) return;
      for (final item in items) {
        if (downloader.network.downloads.any(
          (d) => d.id == item.id && !d.state.isFinal,
        )) {
          continue;
        }
        await downloader.startFromDrive(item);
      }
      return;
    }
    final d = downloader.network;
    if (d is BackgroundPackDownloader) {
      await d.requestNotificationPermission();
    }
    for (final item in items) {
      await downloader.start(item);
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
    final d = downloader.network;
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

  /// Resumes a paused download. A failed one starts again from the
  /// catalogue's current entry, as the pack may have been republished;
  /// from the drive, if one is in use.
  Future<void> resume(String id) async {
    final failed = _downloads[id];
    if (failed?.state != PackDownloadState.failed) {
      return downloader.resume(id);
    }
    await downloader.cancel(id);
    await download([_entryOf(id) ?? failed!.item]);
  }

  Future<void> cancel(String id) => downloader.cancel(id);

  /// Downloads every available update.
  Future<void> updateAll() => download(updates);

  /// Deletes the installed packs of the region at [path], cancelling any of
  /// its downloads first (packs, routing and places). Returns the bytes
  /// freed.
  Future<int> deleteRegion(String path) async {
    for (final download in _downloads.values.toList()) {
      if (download.item.region == path && !download.state.isFinal) {
        await downloader.cancel(download.id);
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
    final d = downloader.network;
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
    _driveCheck?.cancel();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _client.close();
    super.dispose();
  }
}

/// A drive in use, and what's on it.
class _OnDrive {
  /// Read from the folder that holds the maps.
  final MapDrive drive;

  /// Its files and their sizes.
  final Map<String, int> files;

  /// Its `index.json` as read, which lists the server's whole catalogue.
  final String body;

  /// The packs of [catalogue].
  final PackIndex index;

  /// Its `index.json` with only the files that are on it.
  final Map<String, dynamic> catalogue;

  final String? pickerBody;
  final RegionIndex? regions;
  final String? chartAreasBody;
  final ChartAreaIndex? allChartAreas;

  /// The chart areas whose charts are on it.
  final ChartAreaIndex? chartAreas;

  /// The regions with a file on it.
  final Set<String> regionPaths;

  const _OnDrive({
    required this.drive,
    required this.files,
    required this.body,
    required this.index,
    required this.catalogue,
    required this.pickerBody,
    required this.regions,
    required this.chartAreasBody,
    required this.allChartAreas,
    required this.chartAreas,
    required this.regionPaths,
  });
}
