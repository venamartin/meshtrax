import 'pack_index.dart';

/// Where a pack download is in its life.
enum PackDownloadState {
  /// Waiting to start, e.g. behind other downloads or for a network.
  queued,
  running,
  paused,

  /// Retrying after a network error.
  waitingToRetry,

  /// Downloaded; checking the SHA-256 and installing.
  verifying,

  /// Installed through the `PackManager`; the download is finished.
  installed,
  failed,
  canceled;

  /// No further updates will follow.
  bool get isFinal => this == installed || this == failed || this == canceled;
}

/// A snapshot of one pack download, keyed by the pack id ([entry]`.id`).
class PackDownload {
  final PackIndexEntry entry;
  final PackDownloadState state;

  /// 0.0–1.0 while running or paused; null when unknown.
  final double? progress;

  /// Why it failed, for [PackDownloadState.failed].
  final String? error;

  const PackDownload(this.entry, this.state, {this.progress, this.error});

  String get id => entry.id;

  /// Bytes received so far, estimated from [progress] and the index size.
  int get bytesDone => ((progress ?? 0) * entry.bytes).round();

  PackDownload copyWith({
    PackDownloadState? state,
    double? progress,
    String? error,
  }) => PackDownload(
    entry,
    state ?? this.state,
    progress: progress ?? this.progress,
    error: error ?? this.error,
  );

  @override
  String toString() =>
      'PackDownload($id, ${state.name}'
      '${progress == null ? '' : ', ${(progress! * 100).toStringAsFixed(0)}%'}'
      '${error == null ? '' : ', $error'})';
}

/// Downloads packs from the pack index and installs them.
///
/// Implementations download in the background where the platform allows
/// (the Flutter layer's `BackgroundPackDownloader`), resume interrupted
/// downloads, and verify each pack's SHA-256 before installing it, so a
/// partial or mixed file is never installed. The app builds its own UI from
/// [updates] and [downloads].
abstract interface class PackDownloader {
  /// Every state or progress change, for any pack.
  Stream<PackDownload> get updates;

  /// The latest snapshot of each download this session knows about,
  /// including ones restored from a previous run.
  List<PackDownload> get downloads;

  /// Starts downloading [entry], or returns quietly if it is already queued
  /// or running.
  Future<void> start(PackIndexEntry entry);

  Future<void> pause(String packId);
  Future<void> resume(String packId);

  /// Stops a download, or forgets a failed one so it's no longer listed.
  Future<void> cancel(String packId);
}
