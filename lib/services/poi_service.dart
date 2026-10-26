import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:traxpoi/traxpoi.dart';

import '../utils/app_logger.dart';
import 'map_packs_service.dart';
import 'verified_download.dart';

/// Which of a region's two downloads.
enum PoiDownload { points, addresses }

/// The "Points of interest" and "Addresses" downloads per region (the
/// catalogue's `poi` entry), opened for search and the place sheets.
///
/// Files live at `<maps>/poi/<region>/points-of-interest.sqlite` and
/// `addresses.sqlite`, with `poi/manifest.json` recording each file's
/// checksum for update checks.
class PoiService extends ChangeNotifier {
  final MapPacksService maps;
  final Directory root;
  final http.Client _client;

  PoiCatalog? _catalog;
  DateTime? _catalogRead;
  bool _catalogChecked = false;
  final Map<String, PoiRegion> _open = {};
  Map<String, Map<String, String>> _manifest = {};
  final Map<(String, PoiDownload), double> _progress = {};
  String? _error;

  PoiService({required this.maps, required this.root, http.Client? client})
    : _client = client ?? http.Client();

  static Future<PoiService> create(MapPacksService maps) async {
    final service = PoiService(
      maps: maps,
      root: Directory('${maps.cacheDir.path}/poi'),
    );
    service._readManifest();
    service._openInstalled();
    maps.addListener(service._readCatalog);
    service._readCatalog();
    return service;
  }

  PoiCatalog? get catalog => _catalog;
  String? get error => _error;

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

  bool updateAvailable(String region, PoiDownload which) {
    final have = _manifest[region]?[which.name];
    final offered = fileFor(region, which)?.sha256;
    return have != null && offered != null && have != offered;
  }

  double? progressOf(String region, PoiDownload which) =>
      _progress[(region, which)];

  Future<void> download(String region, Set<PoiDownload> which) async {
    _error = null;
    for (final w in which) {
      final file = fileFor(region, w);
      if (file == null) continue;
      final dir = Directory('${root.path}/${_slug(region)}')
        ..createSync(recursive: true);
      final gz = File('${dir.path}/${w.name}.sqlite.gz.part');
      _progress[(region, w)] = 0;
      notifyListeners();
      try {
        await downloadVerified(
          _client,
          file.url,
          gz,
          file.sha256,
          onProgress: (got, total) {
            _progress[(region, w)] = got / (total ?? file.bytes);
            notifyListeners();
          },
        );
        await _open.remove(region)?.close();
        final target = File('${dir.path}/${_fileName(w)}');
        final tmp = File('${target.path}.tmp');
        await gz.openRead().transform(gzip.decoder).pipe(tmp.openWrite());
        tmp.renameSync(target.path);
        gz.deleteSync();
        (_manifest[region] ??= {})[w.name] = file.sha256;
        _writeManifest();
      } on Object catch (e) {
        appLogger.warn('Points of interest download failed: $e', tag: 'Poi');
        _error = '$e';
        if (gz.existsSync()) gz.deleteSync();
      } finally {
        _progress.remove((region, w));
      }
    }
    _openRegion(region);
    notifyListeners();
  }

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

  String _slug(String region) => region.replaceAll('/', '_');

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
    for (final r in _open.values) {
      r.close();
    }
    _client.close();
    super.dispose();
  }
}
