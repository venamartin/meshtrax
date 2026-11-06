import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;

import 'download_item.dart';
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
/// The app's own files ([DownloadFile]) land in [files] as `<id>.download`
/// and are checked the same way, then reported
/// [PackDownloadState.downloaded] for the app to install; it calls [finish].
///
/// Call [start] once at app launch; it restores downloads from the previous
/// run and installs any that finished while the app was closed.
class BackgroundPackDownloader implements PackDownloader {
  static const _group = 'packs';
  static const _suffix = '.download';

  final PackManager manager;

  /// Where the app's own files wait until it installs them: beside the
  /// packs folder unless given.
  final Directory files;

  final FileDownloader _downloader;
  final _updates = StreamController<PackDownload>.broadcast();
  final _latest = <String, PackDownload>{};
  final _installing = <String>{};
  StreamSubscription<TaskUpdate>? _subscription;

  /// [scope] isolates traxmap's tasks from the app's own background_downloader
  /// use. Notifications start with English titles; see
  /// [configureNotifications].
  BackgroundPackDownloader(
    this.manager, {
    String scope = 'traxmap',
    Directory? files,
  }) : files =
           files ?? Directory(p.join(manager.root.parent.path, 'downloads')),
       _downloader = FileDownloader.scoped(scope) {
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
      final item = _itemOf(record.task);
      if (item == null) continue;
      if (record.status == TaskStatus.complete) {
        // Finished while the app was closed, but not installed yet.
        unawaited(_install(record.task, item));
      } else {
        final progress = record.progress;
        _emit(
          PackDownload(
            item,
            _stateOf(record.status),
            progress: progress >= 0 && progress <= 1 ? progress : null,
            // An HTTP failure's description is the server's whole error page.
            error: switch (record.exception) {
              TaskHttpException(:final httpResponseCode) =>
                'HTTP $httpResponseCode',
              final e => e?.description,
            },
          ),
        );
      }
    }
    // Downloads the app was killed in the middle of: queue them again. They
    // continue from the partial file where the platform kept one.
    final (rescheduled, failed) = await _downloader.rescheduleKilledTasks();
    for (final task in failed) {
      final item = _itemOf(task);
      if (item != null) {
        _emit(
          PackDownload(
            item,
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
  Future<void> start(DownloadItem item) async {
    final current = _latest[item.id];
    if (current != null && !current.state.isFinal) return;
    final (base, directory, filename) = await Task.split(
      filePath: await _targetOf(item),
    );
    final task = DownloadTask(
      taskId: item.id,
      url: item.url.toString(),
      baseDirectory: base,
      directory: directory,
      filename: filename,
      group: _group,
      displayName: item.name,
      metaData: jsonEncode(item.toJson()),
      updates: Updates.statusAndProgress,
      retries: 5,
      // UIDT on Android 14+, and pausable (resumes across WorkManager's
      // 9-minute cycles) everywhere.
      transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
      stallTimeout: const Duration(seconds: 60),
    );
    _emit(PackDownload(item, PackDownloadState.queued, progress: 0));
    if (!await _downloader.enqueue(task)) {
      _emit(
        PackDownload(
          item,
          PackDownloadState.failed,
          error: 'Could not start the download',
        ),
      );
    }
  }

  /// Where [item] lands: a pack next to the installed ones, another file in
  /// [files]. Normalised: on Windows the plugin only recognises the app's
  /// folders written with `\`. Given a mixed path it stores a relative one,
  /// which resolves against the working folder, where a Store install can't
  /// write.
  Future<String> _targetOf(DownloadItem item) async {
    final dir = item is PackIndexEntry ? manager.root : files;
    await dir.create(recursive: true);
    final name = item is PackIndexEntry
        ? '${item.id}${PackManager.extension}$_suffix'
        : '${item.id}$_suffix';
    return p.normalize(p.join(dir.path, name));
  }

  @override
  Future<void> pause(String id) async {
    final task = await _downloader.taskForId(id);
    if (task is DownloadTask) await _downloader.pause(task);
  }

  @override
  Future<void> resume(String id) async {
    final task = await _downloader.taskForId(id);
    if (task is DownloadTask) {
      await _downloader.resume(task);
    } else {
      // Not known to the plugin any more (e.g. failed): start over.
      final item = _latest[id]?.item;
      if (item != null) {
        _latest.remove(id);
        await start(item);
      }
    }
  }

  @override
  Future<void> cancel(String id) async {
    final latest = _latest[id];
    if (latest?.state == PackDownloadState.failed) {
      // Nothing is running: drop the plugin's record, or the failure comes
      // back at every launch.
      await _downloader.database.deleteRecordWithId(id);
      _emit(PackDownload(latest!.item, PackDownloadState.canceled));
      return;
    }
    await _downloader.cancelTaskWithId(id);
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
    await _downloader.database.deleteRecordWithId(id);
  }

  /// Stops listening. Downloads keep running in the background.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }

  void _onUpdate(TaskUpdate update) {
    final item = _itemOf(update.task);
    if (item == null) return;
    switch (update) {
      case TaskProgressUpdate(:final progress):
        // Negative values signal states; status updates cover those.
        if (progress < 0 || progress > 1) return;
        final state = _latest[item.id]?.state;
        _emit(
          PackDownload(
            item,
            state == null || state == PackDownloadState.queued
                ? PackDownloadState.running
                : state,
            progress: progress,
          ),
        );
      case TaskStatusUpdate(:final status, :final exception):
        if (status == TaskStatus.complete) {
          unawaited(_install(update.task, item));
        } else {
          _emit(
            PackDownload(
              item,
              _stateOf(status),
              progress: _latest[item.id]?.progress,
              error: switch (exception) {
                TaskHttpException(:final httpResponseCode) =>
                  'HTTP $httpResponseCode',
                final e => e?.description,
              },
            ),
          );
        }
    }
  }

  Future<void> _install(Task task, DownloadItem item) async {
    if (!_installing.add(item.id)) return;
    _emit(PackDownload(item, PackDownloadState.verifying, progress: 1));
    final file = File(await task.filePath());
    try {
      if (!await file.exists()) {
        // The plugin can report or record a completion twice (live, then
        // again from its database at the next launch). If the first one
        // installed this build, there's nothing left to do; the app's own
        // file was handed over then.
        final installed = item is PackIndexEntry
            ? (await manager.listInstalled()).any(
                (p) => p.id == item.id && p.isBuild(item.sha256) == true,
              )
            : true;
        if (installed) {
          _emit(PackDownload(item, PackDownloadState.installed, progress: 1));
          await _downloader.database.deleteRecordWithId(task.taskId);
          return;
        }
        throw const PackException('Downloaded file is missing');
      }
      if (item is PackIndexEntry) {
        await manager.install(
          file,
          id: item.id,
          sha256: item.sha256,
          move: true,
        );
        _emit(PackDownload(item, PackDownloadState.installed, progress: 1));
        await _downloader.database.deleteRecordWithId(task.taskId);
      } else {
        // The app installs it, and says so through [finish].
        if (!await PackManager.matchesSha256(file, item.sha256)) {
          throw PackException('Checksum mismatch for "${item.id}"');
        }
        _emit(
          PackDownload(
            item,
            PackDownloadState.downloaded,
            progress: 1,
            path: file.path,
          ),
        );
      }
    } catch (e) {
      if (await file.exists()) await file.delete();
      _emit(
        PackDownload(
          item,
          PackDownloadState.failed,
          error: e is PackException ? e.message : '$e',
        ),
      );
    } finally {
      _installing.remove(item.id);
    }
  }

  void _emit(PackDownload download) {
    _latest[download.id] = download;
    if (!_updates.isClosed) _updates.add(download);
  }

  static DownloadItem? _itemOf(Task task) {
    try {
      final json = jsonDecode(task.metaData) as Map<String, Object?>;
      return DownloadFile.isFile(json)
          ? DownloadFile.fromJson(json)
          : PackIndexEntry.fromJson(json);
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
