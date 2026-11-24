import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:traxmap/traxmap.dart'
    show DownloadFile, PackDownload, PackDownloadState;
import 'package:traxpix_litert/traxpix_litert.dart';

import '../l10n/app_localizations.dart';
import '../services/map_packs_service.dart';
import '../utils/app_logger.dart';

/// The photo model, downloaded through the map downloader as routing and
/// places are: in the background where the platform allows, queued again at
/// launch, on Wi-Fi only if the user chose that, and each file checked
/// against its SHA-256 before it's handed over. This moves each file into
/// place and tells the downloader with `finish()`.
class PhotoModelDownloads extends ChangeNotifier {
  /// The [DownloadFile.kind] of a photo model file.
  static const kind = 'photo-model';

  /// The model's LiteRT files.
  static const files = kImageCodecFiles;

  static final int totalBytes = files.fold(0, (sum, f) => sum + f.bytes);

  /// The NOTICE and licences served beside the model, which its licences
  /// require to go with it; kept in the model's `licences` folder.
  static const licences = kImageCodecLicences;

  /// Null until [start], and on the web.
  static PhotoModelDownloads? instance;

  /// Follows the map downloader from now on, installing anything it handed
  /// over while the app was closed. Call once at launch, after the maps.
  /// The model goes in Documents/ft8 unless [dir] is given.
  static Future<void> start(MapPacksService maps, {Directory? dir}) async {
    dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/ft8');
    instance = PhotoModelDownloads._(maps, dir);
  }

  /// Waits for the installs queued so far.
  @visibleForTesting
  Future<void> get idle => _work;

  final MapPacksService maps;
  final Directory dir;
  var _work = Future<void>.value();

  PhotoModelDownloads._(this.maps, this.dir) {
    maps.downloader.updates.listen(_onDownload);
    for (final d in maps.downloader.downloads) {
      _onDownload(d);
    }
  }

  static String _idOf(ImageCodecFile f) =>
      'photo-model-${f.sha256.substring(0, 16)}';

  File _fileOf(String name) => File('${dir.path}/$name');

  /// Where the licence texts are kept.
  Directory get licencesDir => Directory('${dir.path}/licences');

  File _licenceOf(String name) => File('${licencesDir.path}/$name');

  bool _has(ImageCodecFile f) {
    final file = _fileOf(f.name);
    return file.existsSync() && file.lengthSync() == f.bytes;
  }

  bool _hasLicence(ImageCodecFile f) {
    final file = _licenceOf(f.name);
    return file.existsSync() && file.lengthSync() == f.bytes;
  }

  /// Whether the model itself is here, as photos need it.
  bool get installed => files.every(_has);

  /// Whether the NOTICE and licence texts are here too.
  bool get licencesInstalled => licences.every(_hasLicence);

  /// This model's downloads still under way.
  List<PackDownload> get active => [
    for (final d in maps.downloader.downloads)
      if (d.file?.kind == kind && !d.state.isFinal) d,
  ];

  /// The last download of this model that failed, if it hasn't been retried.
  PackDownload? get failed {
    for (final d in maps.downloader.downloads) {
      if (d.file?.kind == kind && d.state == PackDownloadState.failed) {
        return d;
      }
    }
    return null;
  }

  /// Bytes on the device, and received so far.
  int get bytesDone {
    final downloading = {for (final d in active) d.file!.payload['name']: d};
    var done = 0;
    for (final f in files) {
      final d = downloading[f.name];
      if (d != null) {
        done += d.bytesDone;
      } else if (_has(f)) {
        done += f.bytes;
      }
    }
    return done;
  }

  /// What stays free beside the model, so the phone isn't left full.
  static const spareBytes = 200 * 1000 * 1000;

  /// The room a download of [needed] bytes needs, with [spareBytes], when
  /// the device has less free ([free]); null when it fits, or when the free
  /// space is unknown.
  static ({int needed, int free})? spaceProblem({
    required int needed,
    required int? free,
  }) {
    if (free == null || free >= needed + spareBytes) return null;
    return (needed: needed + spareBytes, free: free);
  }

  /// Bytes free where the model goes, or null where the app can't tell.
  Future<int?> _freeBytes() async {
    try {
      return await const MethodChannel('meshtrax/storage')
          .invokeMethod<int>('freeBytes', dir.parent.path);
    } on Object catch (_) {
      return null;
    }
  }

  /// Downloads the files not yet on the device, if there's room for them,
  /// named in [l10n]'s language. Failed ones start over. Returns the room
  /// missing when it didn't start, or null.
  Future<({int needed, int free})?> download(AppLocalizations l10n) async {
    final needed = [
      ...files.where((f) => !_has(f)),
      ...licences.where((f) => !_hasLicence(f)),
    ].fold(0, (sum, f) => sum + f.bytes);
    final free = await _freeBytes();
    appLogger.info(
      'Photo model: ${free ?? 'unknown'} bytes free, $needed needed',
      tag: 'Photos',
    );
    final problem = spaceProblem(needed: needed, free: free);
    if (problem != null) return problem;
    for (final d in maps.downloader.downloads) {
      if (d.file?.kind == kind && d.state == PackDownloadState.failed) {
        await maps.cancel(d.id);
      }
    }
    await maps.download([
      for (final (i, f) in files.indexed)
        if (!_has(f))
          DownloadFile(
            id: _idOf(f),
            name: l10n.photo_downloadName(i + 1, files.length),
            url: Uri.parse(f.url),
            bytes: f.bytes,
            sha256: f.sha256,
            kind: kind,
            payload: {'name': f.name},
          ),
      for (final (i, f) in licences.indexed)
        if (!_hasLicence(f))
          DownloadFile(
            id: 'photo-model-licence-${f.sha256.substring(0, 16)}',
            name: l10n.photo_downloadLicenceName(i + 1, licences.length),
            url: Uri.parse(f.url),
            bytes: f.bytes,
            sha256: f.sha256,
            kind: kind,
            payload: {'name': f.name, 'folder': 'licences'},
          ),
    ]);
    notifyListeners();
    return null;
  }

  Future<void> cancel() async {
    for (final d in active) {
      await maps.cancel(d.id);
    }
    notifyListeners();
  }

  /// Stops any download and deletes the model and its licence texts.
  Future<void> delete() async {
    await cancel();
    for (final f in files) {
      final file = _fileOf(f.name);
      if (file.existsSync()) file.deleteSync();
    }
    if (licencesDir.existsSync()) licencesDir.deleteSync(recursive: true);
    final weights = Directory('${dir.path}/xnnpack');
    if (weights.existsSync()) weights.deleteSync(recursive: true);
    notifyListeners();
  }

  void _onDownload(PackDownload d) {
    if (d.file?.kind != kind) return;
    _log(d);
    if (d.state == PackDownloadState.downloaded) {
      _work = _work.then((_) => _install(d));
    }
    notifyListeners();
  }

  final _logged = <String, PackDownloadState>{};

  /// Each file's state changes, in the app's log.
  void _log(PackDownload d) {
    if (_logged[d.id] == d.state) return;
    _logged[d.id] = d.state;
    appLogger.info(
      'Photo model ${d.file!.payload['name']}: ${d.state.name}'
      '${d.error == null ? '' : ' (${d.error})'}',
      tag: 'Photos',
    );
  }

  /// Moves a checked file into [dir], kept out of iCloud and Time Machine
  /// backups as the maps are.
  Future<void> _install(PackDownload d) async {
    final name = d.file!.payload['name'] as String;
    final from = File(d.path!);
    final to = d.file!.payload['folder'] == 'licences'
        ? _licenceOf(name)
        : _fileOf(name);
    String? error;
    try {
      if (!from.existsSync()) {
        // Seen twice (at launch and live): the first one moved it.
        if (to.existsSync() && to.lengthSync() == d.item.bytes) {
          await maps.downloader.finish(d.id);
          return;
        }
        throw const FileSystemException('The downloaded file is missing');
      }
      to.parent.createSync(recursive: true);
      await _keepOutOfBackups();
      from.renameSync(to.path);
    } on Object catch (e) {
      error = '$e';
      if (from.existsSync()) from.deleteSync();
    }
    await maps.downloader.finish(d.id, error: error);
    notifyListeners();
  }

  /// Apple's storage rules: files that can be downloaded again aren't backed
  /// up. A failure only means they are.
  Future<void> _keepOutOfBackups() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    try {
      await const MethodChannel('meshtrax/storage')
          .invokeMethod<void>('excludeFromBackup', dir.path);
    } on Object catch (e) {
      appLogger.warn(
        'Keeping the photo model out of backups: $e',
        tag: 'Photos',
      );
    }
  }
}
