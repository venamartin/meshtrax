import 'download_item.dart';
import 'pack_index.dart';

/// Where a download is in its life.
enum PackDownloadState {
  /// Waiting to start, e.g. behind other downloads or for a network.
  queued,
  running,
  paused,

  /// Retrying after a network error.
  waitingToRetry,

  /// Downloaded; checking the SHA-256 and installing.
  verifying,

  /// A [DownloadFile], checked and waiting at [PackDownload.path] for the
  /// app to install it and call [PackDownloader.finish].
  downloaded,

  /// Installed; the download is finished.
  installed,
  failed,
  canceled;

  /// No further updates will follow.
  bool get isFinal => this == installed || this == failed || this == canceled;
}

/// A snapshot of one download, keyed by [item]`.id`.
class PackDownload {
  final DownloadItem item;
  final PackDownloadState state;

  /// 0.0–1.0 while running or paused; null when unknown.
  final double? progress;

  /// Why it failed, for [PackDownloadState.failed].
  final String? error;

  /// Where the checked file waits, for [PackDownloadState.downloaded].
  final String? path;

  const PackDownload(
    this.item,
    this.state, {
    this.progress,
    this.error,
    this.path,
  });

  String get id => item.id;

  /// The map pack, when this download is one.
  PackIndexEntry? get entry => switch (item) {
    final PackIndexEntry e => e,
    _ => null,
  };

  /// The app's own file, when this download is one.
  DownloadFile? get file => switch (item) {
    final DownloadFile f => f,
    _ => null,
  };

  /// Bytes received so far, estimated from [progress] and the index size.
  int get bytesDone => ((progress ?? 0) * item.bytes).round();

  PackDownload copyWith({
    PackDownloadState? state,
    double? progress,
    String? error,
  }) => PackDownload(
    item,
    state ?? this.state,
    progress: progress ?? this.progress,
    error: error ?? this.error,
    path: path,
  );

  @override
  String toString() =>
      'PackDownload($id, ${state.name}'
      '${progress == null ? '' : ', ${(progress! * 100).toStringAsFixed(0)}%'}'
      '${error == null ? '' : ', $error'})';
}

/// Downloads packs from the pack index and installs them, and downloads the
/// app's own files ([DownloadFile]) for it to install.
///
/// Implementations download in the background where the platform allows
/// (the Flutter layer's `BackgroundPackDownloader`), resume interrupted
/// downloads, and verify each file's SHA-256 before installing it or
/// handing it over, so a partial or mixed file is never used. The app
/// builds its own UI from [updates] and [downloads].
abstract interface class PackDownloader {
  /// Every state or progress change, for any download.
  Stream<PackDownload> get updates;

  /// The latest snapshot of each download this session knows about,
  /// including ones restored from a previous run.
  List<PackDownload> get downloads;

  /// Starts downloading [item], or returns quietly if it is already queued
  /// or running.
  Future<void> start(DownloadItem item);

  Future<void> pause(String id);
  Future<void> resume(String id);

  /// Stops a download, or forgets a failed one so it's no longer listed.
  Future<void> cancel(String id);

  /// The app has installed a [PackDownloadState.downloaded] file, or could
  /// not ([error]); either way the download is finished.
  Future<void> finish(String id, {String? error});
}
