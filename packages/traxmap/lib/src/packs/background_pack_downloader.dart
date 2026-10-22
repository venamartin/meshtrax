import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;

import 'pack_download.dart';
import 'pack_index.dart';
import 'pack_manager.dart';

/// [PackDownloader] built on the background_downloader plugin.
///
/// - **Android:** WorkManager, and on Android 14+ a user-initiated data
///   transfer job (with its required notification), so multi-GB packs run
///   past WorkManager's 9-minute limit and survive the app going to the
///   background. Not Android's DownloadManager.
/// - **iOS and macOS:** background `URLSession`.
/// - **Linux and Windows:** in-process, while the app runs.
///
/// Downloads resume with HTTP range requests (R2 serves them). Each pack
/// lands next to the installed packs as `<id>.pmtiles.download`, then
/// [PackManager.install] checks its SHA-256 and renames it into place, so a
/// truncated or mixed file (e.g. the pack was rebuilt mid-download) is
/// rejected rather than installed.
///
/// Call [start] once at app launch; it restores downloads from the previous
/// run and installs any that finished while the app was closed.
class BackgroundPackDownloader implements PackDownloader {
  static const _group = 'packs';
  static const _suffix = '.download';

  final PackManager manager;

  final FileDownloader _downloader;
  final _updates = StreamController<PackDownload>.broadcast();
  final _latest = <String, PackDownload>{};
  final _installing = <String>{};
  StreamSubscription<TaskUpdate>? _subscription;

  /// [scope] isolates traxmap's tasks from the app's own background_downloader
  /// use. Notifications start with English titles; see
  /// [configureNotifications].
  BackgroundPackDownloader(this.manager, {String scope = 'traxmap'})
    : _downloader = FileDownloader.scoped(scope) {
    configureNotifications();
  }

  /// Titles the system notifications (Android 14+ requires one for long
  /// downloads). Pass translated text once the app knows its locale; the
  /// body shows the pack name.
  void configureNotifications({
    String running = 'Downloading map',
    String paused = 'Map download paused',
    String failed = 'Map download failed',
  }) {
    _downloader.configureNotificationForGroup(
      _group,
      running: TaskNotification(running, '{displayName}  {progress}'),
      paused: TaskNotification(paused, '{displayName}'),
      error: TaskNotification(failed, '{displayName}'),
      progressBar: true,
    );
  }

  /// Holds downloads until the device is on Wi-Fi, or lets them use any
  /// network. Applies to running downloads too. Phones only; desktops
  /// ignore it.
  Future<void> setRequiresWiFi(bool required) => _downloader.requireWiFi(
    required ? RequireWiFi.forAllTasks : RequireWiFi.asSetByTask,
  );

  @override
  Stream<PackDownload> get updates => _updates.stream;

  @override
  List<PackDownload> get downloads => List.unmodifiable(_latest.values);

  /// Restores downloads from the previous run. Call once, before [start]ing
  /// downloads; listen to [updates] first to see the restored ones.
  Future<void> restore() async {
    _subscription ??= _downloader.updates.listen(_onUpdate);
    // A scoped downloader's start() only tracks its default group, so track
    // ours explicitly, or nothing is recorded and killed downloads are lost.
    await _downloader.trackTasksInGroup(_group);
    await _downloader.start(
      autoCleanDatabase: true,
      doRescheduleKilledTasks: false, // done below, not on a timer
    );
    for (final record in await _downloader.database.allRecords()) {
      final entry = _entryOf(record.task);
      if (entry == null) continue;
      if (record.status == TaskStatus.complete) {
        // Finished while the app was closed, but not installed yet.
        unawaited(_install(record.task, entry));
      } else {
        final progress = record.progress;
        _emit(
          PackDownload(
            entry,
            _stateOf(record.status),
            progress: progress >= 0 && progress <= 1 ? progress : null,
            error: record.exception?.description,
          ),
        );
      }
    }
    // Downloads the app was killed in the middle of: queue them again. They
    // continue from the partial file where the platform kept one.
    final (rescheduled, failed) = await _downloader.rescheduleKilledTasks();
    for (final task in failed) {
      final entry = _entryOf(task);
      if (entry != null) {
        _emit(
          PackDownload(
            entry,
            PackDownloadState.failed,
            error: 'Could not restart the download',
          ),
        );
      }
    }
    restoredCount = rescheduled.length;
  }

  /// How many interrupted downloads the last [restore] queued again.
  int restoredCount = 0;

  /// Asks for permission to show download notifications, if not granted yet.
  /// Android 14+ needs a visible notification for long downloads (UIDT); call
  /// this when the user starts a download, so the request makes sense to
  /// them. True if notifications may be shown. Desktop always says yes.
  Future<bool> requestNotificationPermission() async {
    const type = PermissionType.notifications;
    final permissions = _downloader.permissions;
    if (await permissions.status(type) == PermissionStatus.granted) return true;
    return await permissions.request(type) == PermissionStatus.granted;
  }

  @override
  Future<void> start(PackIndexEntry entry) async {
    final current = _latest[entry.id];
    if (current != null && !current.state.isFinal) return;
    await manager.root.create(recursive: true);
    final target = p.join(
      manager.root.path,
      '${entry.id}${PackManager.extension}$_suffix',
    );
    final (base, directory, filename) = await Task.split(filePath: target);
    final task = DownloadTask(
      taskId: entry.id,
      url: entry.url.toString(),
      baseDirectory: base,
      directory: directory,
      filename: filename,
      group: _group,
      displayName: entry.name,
      metaData: jsonEncode(entry.toJson()),
      updates: Updates.statusAndProgress,
      retries: 5,
      // UIDT on Android 14+, and pausable (resumes across WorkManager's
      // 9-minute cycles) everywhere.
      transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
      stallTimeout: const Duration(seconds: 60),
    );
    _emit(PackDownload(entry, PackDownloadState.queued, progress: 0));
    if (!await _downloader.enqueue(task)) {
      _emit(
        PackDownload(
          entry,
          PackDownloadState.failed,
          error: 'Could not start the download',
        ),
      );
    }
  }

  @override
  Future<void> pause(String packId) async {
    final task = await _downloader.taskForId(packId);
    if (task is DownloadTask) await _downloader.pause(task);
  }

  @override
  Future<void> resume(String packId) async {
    final task = await _downloader.taskForId(packId);
    if (task is DownloadTask) {
      await _downloader.resume(task);
    } else {
      // Not known to the plugin any more (e.g. failed): start over.
      final entry = _latest[packId]?.entry;
      if (entry != null) {
        _latest.remove(packId);
        await start(entry);
      }
    }
  }

  @override
  Future<void> cancel(String packId) async {
    final latest = _latest[packId];
    if (latest?.state == PackDownloadState.failed) {
      // Nothing is running: drop the plugin's record, or the failure comes
      // back at every launch.
      await _downloader.database.deleteRecordWithId(packId);
      _emit(PackDownload(latest!.entry, PackDownloadState.canceled));
      return;
    }
    await _downloader.cancelTaskWithId(packId);
  }

  /// Stops listening. Downloads keep running in the background.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }

  void _onUpdate(TaskUpdate update) {
    final entry = _entryOf(update.task);
    if (entry == null) return;
    switch (update) {
      case TaskProgressUpdate(:final progress):
        // Negative values signal states; status updates cover those.
        if (progress < 0 || progress > 1) return;
        final state = _latest[entry.id]?.state;
        _emit(
          PackDownload(
            entry,
            state == null || state == PackDownloadState.queued
                ? PackDownloadState.running
                : state,
            progress: progress,
          ),
        );
      case TaskStatusUpdate(:final status, :final exception):
        if (status == TaskStatus.complete) {
          unawaited(_install(update.task, entry));
        } else {
          _emit(
            PackDownload(
              entry,
              _stateOf(status),
              progress: _latest[entry.id]?.progress,
              error: exception?.description,
            ),
          );
        }
    }
  }

  Future<void> _install(Task task, PackIndexEntry entry) async {
    if (!_installing.add(entry.id)) return;
    _emit(PackDownload(entry, PackDownloadState.verifying, progress: 1));
    final file = File(await task.filePath());
    try {
      if (!await file.exists()) {
        // The plugin can report or record a completion twice (live, then
        // again from its database at the next launch). If the first one
        // installed this build, there's nothing left to do.
        final installed = await manager.listInstalled();
        if (installed.any(
          (p) => p.id == entry.id && p.isBuild(entry.sha256) == true,
        )) {
          _emit(PackDownload(entry, PackDownloadState.installed, progress: 1));
          await _downloader.database.deleteRecordWithId(task.taskId);
          return;
        }
        throw const PackException('Downloaded file is missing');
      }
      await manager.install(
        file,
        id: entry.id,
        sha256: entry.sha256,
        move: true,
      );
      _emit(PackDownload(entry, PackDownloadState.installed, progress: 1));
      await _downloader.database.deleteRecordWithId(task.taskId);
    } catch (e) {
      if (await file.exists()) await file.delete();
      _emit(
        PackDownload(
          entry,
          PackDownloadState.failed,
          error: e is PackException ? e.message : '$e',
        ),
      );
    } finally {
      _installing.remove(entry.id);
    }
  }

  void _emit(PackDownload download) {
    _latest[download.id] = download;
    if (!_updates.isClosed) _updates.add(download);
  }

  static PackIndexEntry? _entryOf(Task task) {
    try {
      return PackIndexEntry.fromJson(
        jsonDecode(task.metaData) as Map<String, Object?>,
      );
    } catch (_) {
      return null; // not one of ours
    }
  }

  static PackDownloadState _stateOf(TaskStatus status) => switch (status) {
    TaskStatus.enqueued => PackDownloadState.queued,
    TaskStatus.running => PackDownloadState.running,
    TaskStatus.paused => PackDownloadState.paused,
    TaskStatus.waitingToRetry => PackDownloadState.waitingToRetry,
    TaskStatus.complete => PackDownloadState.verifying,
    TaskStatus.canceled => PackDownloadState.canceled,
    TaskStatus.failed || TaskStatus.notFound => PackDownloadState.failed,
  };
}
