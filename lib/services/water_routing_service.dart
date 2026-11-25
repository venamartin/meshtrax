import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:traxmap/traxmap.dart'
    show
        ChartArea,
        DownloadFile,
        LatLng,
        PackDownload,
        PackDownloadState,
        PackIndexEntry,
        creditsIn,
        noticesIn;
import 'package:traxwater/traxwater.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';
import 'routing_service.dart' show RoutingDriveBlock;

/// Routes on the water: the water-routing tiles per chart area (from the
/// catalogue's `water_routing` entry, FINDINGS 1.11) and trips on them,
/// worked out by `packages/traxwater` in an isolate. One build on the
/// device at a time.
///
/// Each area's routing is built from one charts pack. A chart of another
/// build is out of date, and downloading the routing brings the chart up to
/// date too. Bundles download through the map downloader, as land routing
/// does.
class WaterRoutingService extends ChangeNotifier {
  WaterRoutingService({required this.maps, required this.store});

  /// The [DownloadFile.kind] of a water-routing bundle.
  static const downloadKind = 'water-routing';

  final MapPacksService maps;
  final WaterStore store;

  WaterCatalog? _catalog;
  bool _needsNewerApp = false;
  int? _catalogVersion;
  List<String> _notices = const [];
  StreamSubscription<PackDownload>? _downloads;
  var _work = Future<void>.value();
  final _recovering = <String>{};

  /// Per build, the areas [download] asked for, so a new build waits for
  /// those the downloader hasn't started yet.
  final _expected = <String, Set<String>>{};

  static WaterRoutingService create(MapPacksService maps) {
    final service = WaterRoutingService(
      maps: maps,
      store: WaterStore(Directory('${maps.cacheDir.path}/water-routing')),
    );
    maps.addListener(service._readCatalog);
    service._readCatalog();
    service._readNotices();
    service._followDownloads();
    return service;
  }

  WaterCatalog? get catalog => _catalog;

  /// The catalogue has water routing, but only in a format a newer app
  /// reads.
  bool get needsNewerApp => _needsNewerApp;

  WaterBundle? bundleFor(String area) => _catalog?.regions[area];

  bool isInstalled(String area) => store.regions.containsKey(area);

  bool get hasRoutingData => store.tileDir != null;

  Set<String> get installedRegions => store.regions.keys.toSet();

  /// What the installed areas' data says must be shown with a route ("Not
  /// for navigation. …").
  List<String> get notices => _notices;

  int sizeOf(String area) => store.sizeOf(area);

  int get totalBytes => store.totalBytes;

  static String downloadId(String area) =>
      'water-routing-${area.replaceAll('/', '_')}';

  /// Whether water routing is on offer at [point]: data is on the device (a
  /// trip may still end short of it), or the catalogue has it for a chart
  /// area there, to download.
  bool offeredAt(LatLng point) =>
      hasRoutingData ||
      (maps.chartAreas?.areasAt(point) ?? const []).any(
        (a) => bundleFor(a.packRegion) != null,
      );

  /// The chart area at [point] with water routing, on the device or to
  /// download: one on the device first.
  ChartArea? areaAt(LatLng point) {
    final areas = [
      for (final a in maps.chartAreas?.areasAt(point) ?? const <ChartArea>[])
        if (isInstalled(a.packRegion) || bundleFor(a.packRegion) != null) a,
    ];
    return areas.where((a) => isInstalled(a.packRegion)).firstOrNull ??
        areas.firstOrNull;
  }

  /// The catalogue's chart for [area] isn't the one its routing was built
  /// from: routing there is being rebuilt, and isn't offered meanwhile.
  bool rebuilding(String area) {
    final b = bundleFor(area);
    return b != null && maps.chartPackOf(area)?.sha256 != b.chartsSha256;
  }

  /// The chart to download with [area]'s routing: its chart when it isn't
  /// installed, or isn't the build the routing was made from.
  PackIndexEntry? chartFor(String area) {
    final entry = maps.chartPackOf(area);
    if (entry == null || rebuilding(area)) return null;
    return maps.installedPack(entry.id)?.isBuild(entry.sha256) == true
        ? null
        : entry;
  }

  /// What downloading [areas] takes: those areas, plus every installed one
  /// when the catalogue has a newer build. Nothing when a drive in use
  /// can't give it ([driveBlock]), and never an area being rebuilt.
  Set<String> downloadsFor(Set<String> areas) {
    final c = _catalog;
    if (c == null || driveBlock != null) return {};
    // A new build replaces every installed area at once, so none goes
    // while one of them is being rebuilt.
    if (store.build != null &&
        c.build != store.build &&
        installedRegions.any(rebuilding)) {
      return {};
    }
    return store.downloadsFor(c, areas).where((a) => !rebuilding(a)).toSet();
  }

  /// Why water routing can't come from the drive in use, as for land
  /// routing ([RoutingService.driveBlock]).
  RoutingDriveBlock? get driveBlock {
    final c = _catalog;
    final installed = store.build;
    if (maps.drive == null || c == null || installed == null) return null;
    final order = c.build.compareTo(installed);
    if (order < 0) return RoutingDriveBlock.older;
    if (order > 0 && installedRegions.any((r) => !c.regions.containsKey(r))) {
      return RoutingDriveBlock.incomplete;
    }
    return null;
  }

  /// The bytes downloading [areas] takes, their charts included.
  int bytesFor(Set<String> areas) {
    final todo = downloadsFor(areas);
    return todo.fold(
      0,
      (sum, a) =>
          sum + (_catalog!.regions[a]?.bytes ?? 0) + (chartFor(a)?.bytes ?? 0),
    );
  }

  bool updateAvailable(String area) =>
      isInstalled(area) && downloadsFor(const {}).contains(area);

  /// Downloads what [areas] take, and the charts they need, through the
  /// map downloader. Each bundle installs as it arrives.
  Future<void> download(Set<String> areas) async {
    final c = _catalog;
    if (c == null) return;
    final todo = downloadsFor(areas);
    (_expected[c.build] ??= {}).addAll(todo);
    await maps.download([
      for (final area in todo) ...[?chartFor(area), _item(area, c)],
    ]);
  }

  DownloadFile _item(String area, WaterCatalog c) {
    final b = c.regions[area]!;
    return DownloadFile(
      id: downloadId(area),
      name:
          maps.chartAreas?.areas
              .where((a) => a.packRegion == area)
              .firstOrNull
              ?.name ??
          area.split('/').last,
      region: area,
      url: b.url,
      bytes: b.bytes,
      sha256: b.sha256,
      kind: downloadKind,
      payload: {
        'build': c.build,
        'charts_sha256': ?b.chartsSha256,
        'attribution': ?b.attribution,
        'notice': ?b.notice,
      },
    );
  }

  /// Removes [area]'s water routing. It waits behind any install, since a
  /// new build deletes the old build's tiles.
  Future<void> remove(String area) => _work = _work.then((_) async {
    if (!isInstalled(area)) return;
    try {
      await store.remove(area);
    } on Object catch (e) {
      appLogger.warn('Water routing remove failed: $e', tag: 'Routing');
    }
    _readNotices();
    notifyListeners();
  });

  /// A trip from [from] to [to], worked out in an isolate. Throws a
  /// [WaterRoutingException] where there's no trip to make.
  Future<WaterTrip> route(
    LatLon from,
    LatLon to, {
    WaterRouteOptions options = const WaterRouteOptions(),
  }) {
    final root = store.root.path;
    return Isolate.run(
      () => WaterStore(Directory(root)).route(from, to, options: options),
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
      // A bundle gone from the server: it has moved on to a newer build.
      case PackDownloadState.failed when d.error == 'HTTP 404':
        _work = _work.then((_) => _retryFromCatalog(d));
      default:
    }
  }

  /// Installs everything the downloader has handed over, per build.
  Future<void> _installDownloaded() async {
    final byBuild = <String, Map<String, (File, WaterBundle)>>{};
    for (final d in maps.downloader.downloads) {
      final file = d.file;
      if (file == null ||
          file.kind != downloadKind ||
          d.state != PackDownloadState.downloaded) {
        continue;
      }
      (byBuild[file.payload['build'] as String] ??= {})[file.region!] = (
        File(d.path!),
        WaterBundle(
          file.url,
          file.bytes,
          0,
          file.sha256,
          chartsSha256: file.payload['charts_sha256'] as String?,
          attribution: file.payload['attribution'] as String?,
          notice: file.payload['notice'] as String?,
        ),
      );
    }
    for (final MapEntry(key: build, value: bundles) in byBuild.entries) {
      // A new build replaces the installed one in one step, keeping only
      // the areas it's given, so it waits for every bundle of it on its way.
      if (store.build != null && build != store.build && _waiting(build)) {
        continue;
      }
      String? error;
      try {
        await store.install(build, bundles);
        _expected[build]?.removeAll(bundles.keys);
      } on Object catch (e) {
        appLogger.warn('Water routing install failed: $e', tag: 'Routing');
        error = '$e';
      }
      for (final MapEntry(key: area, value: (file, _)) in bundles.entries) {
        if (file.existsSync()) file.deleteSync();
        await maps.downloader.finish(downloadId(area), error: error);
      }
    }
    _readNotices();
    notifyListeners();
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
      (area) => switch (states[area]) {
        PackDownloadState.downloaded ||
        PackDownloadState.installed ||
        PackDownloadState.canceled => false,
        _ => true,
      },
    );
  }

  /// Reads the catalogue again and takes the current build of [d]'s area.
  Future<void> _retryFromCatalog(PackDownload d) async {
    final area = d.item.region!;
    if (!_recovering.add(area)) return;
    try {
      await maps.refresh();
      final current = bundleFor(area);
      if (current != null && current.url != d.item.url) {
        await download({area});
      }
    } finally {
      _recovering.remove(area);
    }
  }

  void _readNotices() =>
      _notices = noticesIn([for (final r in store.regions.values) r.notice]);

  /// Credits for the installed water routing, one per source.
  List<String> get credits =>
      creditsIn([for (final r in store.regions.values) r.attribution]);

  void _readCatalog() {
    if (maps.catalogueVersion == _catalogVersion) return;
    _catalogVersion = maps.catalogueVersion;
    final index = maps.catalogue;
    try {
      _catalog = index == null
          ? null
          : WaterCatalog.fromIndex(index, maps.indexUrl);
      _needsNewerApp = index != null && WaterCatalog.needsNewerApp(index);
    } on Object catch (e) {
      appLogger.warn('Water routing catalogue unreadable: $e', tag: 'Routing');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    maps.removeListener(_readCatalog);
    unawaited(_downloads?.cancel());
    super.dispose();
  }
}
