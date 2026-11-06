import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:traxmap/traxmap.dart'
    show DownloadFile, PackDownload, PackDownloadState;
import 'package:traxpoi/traxpoi.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';

/// Which of a region's two downloads.
enum PoiDownload { points, addresses }

/// The "Points of interest" and "Addresses" downloads per region (the
/// catalogue's `poi` entry), opened for search and the place sheets.
///
/// Files download through the map downloader, as packs do, and live at
/// `<maps>/poi/<region>/points-of-interest.sqlite` and `addresses.sqlite`,
/// with `poi/manifest.json` recording each file's checksum for update
/// checks.
class PoiService extends ChangeNotifier {
  /// The [DownloadFile.kind]s of the two downloads.
  static const pointsKind = 'poi-points';
  static const addressesKind = 'poi-addresses';

  final MapPacksService maps;
  final Directory root;

  PoiCatalog? _catalog;
  DateTime? _catalogRead;
  bool _catalogChecked = false;
  final Map<String, PoiRegion> _open = {};
  Map<String, Map<String, String>> _manifest = {};
  StreamSubscription<PackDownload>? _downloads;
  var _work = Future<void>.value();

  PoiService({required this.maps, required this.root});

  static Future<PoiService> create(MapPacksService maps) async {
    final service = PoiService(
      maps: maps,
      root: Directory('${maps.cacheDir.path}/poi'),
    );
    service._readManifest();
    service._openInstalled();
    maps.addListener(service._readCatalog);
    service._readCatalog();
    service._followDownloads();
    return service;
  }

  PoiCatalog? get catalog => _catalog;

  /// Every region with a downloaded file, for search.
  List<PoiRegion> get regions => _open.values.toList();

  PoiRegion? regionFor(String path) => _open[path];

  PoiFile? fileFor(String region, PoiDownload which) {
    final files = _catalog?.regions[region];
    return switch (which) {
      PoiDownload.points => files?.points,
      PoiDownload.addresses => files?.addresses,
    };
  }

  bool isInstalled(String region, PoiDownload which) =>
      _manifest[region]?[which.name] != null;

  /// Regions with either download on the device.
  Set<String> get installedRegions => _manifest.keys.toSet();

  int sizeOf(String region) => [
    for (final w in PoiDownload.values)
      File('${root.path}/${_slug(region)}/${_fileName(w)}'),
  ].where((f) => f.existsSync()).fold(0, (sum, f) => sum + f.lengthSync());

  int get totalBytes => installedRegions.fold(0, (sum, r) => sum + sizeOf(r));

  bool updateAvailable(String region, PoiDownload which) {
    final have = _manifest[region]?[which.name];
    final offered = fileFor(region, which)?.sha256;
    return have != null && offered != null && have != offered;
  }

  /// The id of [region]'s [which] file in the map downloader.
  static String downloadId(String region, PoiDownload which) =>
      'poi-${_slug(region)}-${which.name}';

  static String kindOf(PoiDownload which) => switch (which) {
    PoiDownload.points => pointsKind,
    PoiDownload.addresses => addressesKind,
  };

  /// Downloads [which] of [region]'s files through the map downloader. Each
  /// installs as it arrives.
  Future<void> download(String region, Set<PoiDownload> which) => maps.download(
    [
      for (final w in which)
        if (fileFor(region, w) case final file?)
          DownloadFile(
            id: downloadId(region, w),
            name: maps.regions?[region]?.name ?? region.split('/').last,
            region: region,
            url: file.url,
            bytes: file.bytes,
            sha256: file.sha256,
            kind: kindOf(w),
          ),
    ],
  );

  Future<void> remove(String region, {Set<PoiDownload>? which}) async {
    await _open.remove(region)?.close();
    for (final w in which ?? PoiDownload.values.toSet()) {
      final f = File('${root.path}/${_slug(region)}/${_fileName(w)}');
      if (f.existsSync()) f.deleteSync();
      _manifest[region]?.remove(w.name);
    }
    if (_manifest[region]?.isEmpty ?? false) _manifest.remove(region);
    _writeManifest();
    _openRegion(region);
    notifyListeners();
  }

  /// Completes once every install queued so far has run.
  @visibleForTesting
  Future<void> get idle async {
    Future<void>? seen;
    while (seen != _work) {
      seen = _work;
      await seen;
    }
  }

  /// Installs files as the downloader hands them over, including any
  /// handed over before this service existed (restored from the last run).
  void _followDownloads() {
    _downloads = maps.downloader.updates.listen(_onDownload);
    for (final d in maps.downloader.downloads) {
      _onDownload(d);
    }
  }

  void _onDownload(PackDownload d) {
    if (d.state != PackDownloadState.downloaded) return;
    final which = switch (d.file?.kind) {
      pointsKind => PoiDownload.points,
      addressesKind => PoiDownload.addresses,
      _ => null,
    };
    if (which != null) _work = _work.then((_) => _install(d, which));
  }

  /// Unpacks a file the downloader has checked into its region's folder.
  Future<void> _install(PackDownload d, PoiDownload which) async {
    final region = d.item.region!;
    final gz = File(d.path!);
    String? error;
    try {
      await _open.remove(region)?.close();
      final dir = Directory('${root.path}/${_slug(region)}')
        ..createSync(recursive: true);
      final target = File('${dir.path}/${_fileName(which)}');
      final tmp = File('${target.path}.tmp');
      await gz.openRead().transform(gzip.decoder).pipe(tmp.openWrite());
      tmp.renameSync(target.path);
      (_manifest[region] ??= {})[which.name] = d.item.sha256;
      _writeManifest();
    } on Object catch (e) {
      appLogger.warn('Points of interest install failed: $e', tag: 'Poi');
      error = '$e';
    }
    if (gz.existsSync()) gz.deleteSync();
    await maps.downloader.finish(d.id, error: error);
    _openRegion(region);
    notifyListeners();
  }

  void _openInstalled() {
    for (final region in _manifest.keys) {
      _openRegion(region);
    }
  }

  void _openRegion(String region) {
    final dir = '${root.path}/${_slug(region)}';
    final points = File('$dir/${_fileName(PoiDownload.points)}');
    final addresses = File('$dir/${_fileName(PoiDownload.addresses)}');
    if (!points.existsSync() && !addresses.existsSync()) return;
    _open[region] = PoiRegion.open(
      points: points.existsSync() ? points : null,
      addresses: addresses.existsSync() ? addresses : null,
    );
  }

  String _fileName(PoiDownload w) => switch (w) {
    PoiDownload.points => 'points-of-interest.sqlite',
    PoiDownload.addresses => 'addresses.sqlite',
  };

  static String _slug(String region) => region.replaceAll('/', '_');

  File get _manifestFile => File('${root.path}/manifest.json');

  void _readManifest() {
    if (!_manifestFile.existsSync()) return;
    try {
      _manifest = {
        for (final MapEntry(:key, :value)
            in (jsonDecode(_manifestFile.readAsStringSync()) as Map).entries)
          key as String: (value as Map).cast<String, String>(),
      };
    } on Object catch (e) {
      appLogger.warn('Points of interest manifest unreadable: $e', tag: 'Poi');
    }
  }

  void _writeManifest() {
    root.createSync(recursive: true);
    final tmp = File('${_manifestFile.path}.tmp')
      ..writeAsStringSync(jsonEncode(_manifest));
    tmp.renameSync(_manifestFile.path);
  }

  void _readCatalog() {
    if (_catalogChecked && maps.fetchedAt == _catalogRead) return;
    _catalogChecked = true;
    _catalogRead = maps.fetchedAt;
    final file = File('${maps.cacheDir.path}/index.json');
    if (!file.existsSync()) return;
    try {
      _catalog = PoiCatalog.fromIndex(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        maps.indexUrl,
      );
      notifyListeners();
    } on Object catch (e) {
      appLogger.warn('Points of interest catalogue unreadable: $e', tag: 'Poi');
    }
  }

  @override
  void dispose() {
    maps.removeListener(_readCatalog);
    unawaited(_downloads?.cancel());
    for (final r in _open.values) {
      r.close();
    }
    super.dispose();
  }
}
