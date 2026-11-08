import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'download_item.dart';
import 'map_drive.dart';
import 'pack_download.dart';
import 'pack_index.dart';
import 'pack_manager.dart';

/// [PackDownloader] that installs from a [MapDrive] instead of the network.
///
/// Each file is copied next to where a download would land, with [suffix],
/// then checked and installed as a download is: a pack through
/// [PackManager.install], which checks its SHA-256, and the app's own files
/// ([DownloadFile]) checked and handed over as
/// [PackDownloadState.downloaded] for the app to install and [finish].
///
/// One file copies at a time, while the app runs. Pause stops a copy and
/// keeps what's copied, so resume carries on from there. Nothing carries
/// over to the next run: [clean] deletes what copies left behind.
class DrivePackDownloader implements PackDownloader {
  static const suffix = '.drive';

  /// Why a copy failed when its drive went away mid-copy.
  static const removedError = 'The drive was removed';

  final PackManager manager;

  /// Where the app's own files wait until it installs them, as downloads do.
  final Directory files;

  DrivePackDownloader(this.manager, {Directory? files})
    : files = files ?? Directory(p.join(manager.root.parent.path, 'downloads'));

  MapDrive? _drive;
  String? Function(Uri url)? _pathOf;
  final _updates = StreamController<PackDownload>.broadcast();
  final _latest = <String, PackDownload>{};
  final _queue = <String>[];
  String? _running;
  Future<void>? _copying;
  Completer<void>? _stop;
  PackDownloadState? _stopAs;
  String? _stopError;

  /// The drive files are copied from; null when none is in use.
  MapDrive? get drive => _drive;

  /// Copies from [drive] from now on. [pathOf] gives a file's path on the
  /// drive from its URL; null means the drive has no place for it.
  void attach(MapDrive drive, String? Function(Uri url) pathOf) {
    _drive = drive;
    _pathOf = pathOf;
  }

  /// Stops using the drive. Copies not finished end: canceled, or failed
  /// with [error], such as the drive having been removed.
  Future<void> detach({String? error}) async {
    final state = error == null
        ? PackDownloadState.canceled
        : PackDownloadState.failed;
    for (final id in [..._queue, ..._paused]) {
      _queue.remove(id);
      final item = _latest[id]!.item;
      final target = _target(item);
      if (await target.exists()) await target.delete();
      _emit(PackDownload(item, state, error: error));
    }
    await _stopRunning(state, error: error);
    _drive = null;
    _pathOf = null;
  }

  /// Whether [id] is this downloader's to pause, resume, cancel or finish.
  bool owns(String id) => switch (_latest[id]?.state) {
    null || PackDownloadState.installed || PackDownloadState.canceled => false,
    _ => true,
  };

  /// Forgets [id] once it's over here, so a download of the same item from
  /// the network isn't shadowed by it.
  void forget(String id) {
    if (!owns(id)) _latest.remove(id);
  }

  /// Deletes what copies from an earlier run left behind.
  Future<void> clean() async {
    for (final dir in [manager.root, files]) {
      if (!await dir.exists()) continue;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith(suffix)) {
          await entity.delete();
        }
      }
    }
  }

  @override
  Stream<PackDownload> get updates => _updates.stream;

  @override
  List<PackDownload> get downloads => List.unmodifiable(_latest.values);

  @override
  Future<void> start(DownloadItem item) async {
    final current = _latest[item.id];
    if (current != null && !current.state.isFinal) return;
    _emit(PackDownload(item, PackDownloadState.queued, progress: 0));
    _queue.add(item.id);
    _next();
  }

  @override
  Future<void> pause(String id) async {
    final d = _latest[id];
    if (d == null) return;
    if (_queue.remove(id)) {
      _emit(d.copyWith(state: PackDownloadState.paused));
    } else if (_running == id) {
      await _stopRunning(PackDownloadState.paused);
    }
  }

  @override
  Future<void> resume(String id) async {
    final d = _latest[id];
    if (d?.state != PackDownloadState.paused) return;
    _emit(d!.copyWith(state: PackDownloadState.queued));
    _queue.add(id);
    _next();
  }

  @override
  Future<void> cancel(String id) async {
    if (!owns(id)) return;
    if (_running == id) return _stopRunning(PackDownloadState.canceled);
    _queue.remove(id);
    final item = _latest[id]!.item;
    final target = _target(item);
    if (await target.exists()) await target.delete();
    _emit(PackDownload(item, PackDownloadState.canceled));
  }

  @override
  Future<void> finish(String id, {String? error}) async {
    final item = _latest[id]?.item;
    if (item == null) return;
    _emit(
      error == null
          ? PackDownload(item, PackDownloadState.installed, progress: 1)
          : PackDownload(item, PackDownloadState.failed, error: error),
    );
  }

  Iterable<String> get _paused => [
    for (final d in _latest.values)
      if (d.state == PackDownloadState.paused) d.id,
  ];

  void _next() {
    if (_running != null || _queue.isEmpty) return;
    final id = _running = _queue.removeAt(0);
    final copying = _copying = _copy(_latest[id]!.item);
    unawaited(
      copying.whenComplete(() {
        _running = null;
        _copying = null;
        _next();
      }),
    );
  }

  /// Stops the running copy, if any, which then ends as [state]. A copy
  /// already being checked and installed finishes instead.
  Future<void> _stopRunning(PackDownloadState state, {String? error}) async {
    final copying = _copying;
    if (copying == null) return;
    _stopAs = state;
    _stopError = error;
    final stop = _stop;
    if (stop != null && !stop.isCompleted) stop.complete();
    await copying;
  }

  Future<void> _copy(DownloadItem item) async {
    final target = _target(item);
    final stop = _stop = Completer<void>();
    _stopAs = null;
    var copying = true;
    Timer? progress;
    try {
      final drive = _drive;
      final path = _pathOf?.call(item.url);
      if (drive == null || path == null) {
        throw const PackException('Not on the drive');
      }
      await target.parent.create(recursive: true);
      final paused = _latest[item.id]?.progress ?? 0;
      final from = paused > 0 && await target.exists()
          ? await target.length()
          : 0;
      _emit(
        PackDownload(
          item,
          PackDownloadState.running,
          progress: from / item.bytes,
        ),
      );
      progress = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        final length = await target.length().catchError((_) => 0);
        if (!copying) return;
        _emit(
          PackDownload(
            item,
            PackDownloadState.running,
            progress: (length / item.bytes).clamp(0.0, 1.0),
          ),
        );
      });
      await drive.copy(path, target, from: from, stop: stop.future);
      copying = false;
      _emit(PackDownload(item, PackDownloadState.verifying, progress: 1));
      if (item is PackIndexEntry) {
        await manager.install(
          target,
          id: item.id,
          sha256: item.sha256,
          move: true,
        );
        _emit(PackDownload(item, PackDownloadState.installed, progress: 1));
      } else {
        if (!await PackManager.matchesSha256(target, item.sha256)) {
          throw PackException('Checksum mismatch for "${item.id}"');
        }
        _emit(
          PackDownload(
            item,
            PackDownloadState.downloaded,
            progress: 1,
            path: target.path,
          ),
        );
      }
    } on DriveCopyStopped {
      copying = false;
      final state = _stopAs ?? PackDownloadState.canceled;
      if (state != PackDownloadState.paused && await target.exists()) {
        await target.delete();
      }
      final length = state == PackDownloadState.paused
          ? await target.length().catchError((_) => 0)
          : 0;
      _emit(
        PackDownload(
          item,
          state,
          progress: state == PackDownloadState.paused
              ? length / item.bytes
              : null,
          error: _stopError,
        ),
      );
    } catch (e) {
      copying = false;
      if (await target.exists()) await target.delete();
      final gone = !(await _drive?.isReadable() ?? true);
      _emit(
        PackDownload(
          item,
          PackDownloadState.failed,
          error: gone
              ? removedError
              : e is PackException
              ? e.message
              : '$e',
        ),
      );
    } finally {
      copying = false;
      progress?.cancel();
      _stop = null;
    }
  }

  File _target(DownloadItem item) => item is PackIndexEntry
      ? File(
          p.join(
            manager.root.path,
            '${item.id}${PackManager.extension}$suffix',
          ),
        )
      : File(p.join(files.path, '${item.id}$suffix'));

  void _emit(PackDownload download) {
    _latest[download.id] = download;
    if (!_updates.isClosed) _updates.add(download);
  }
}
