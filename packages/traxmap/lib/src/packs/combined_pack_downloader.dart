import 'dart:async';

import 'download_item.dart';
import 'drive_pack_downloader.dart';
import 'pack_download.dart';

/// The network's downloader and a drive's as one, so the app and its
/// installers follow every download, and install every file, in one place.
///
/// [start] downloads from the network; [startFromDrive] copies from the
/// drive. Pause, resume, cancel and finish go to whichever has the item.
class CombinedPackDownloader implements PackDownloader {
  final PackDownloader network;
  final DrivePackDownloader drive;

  /// Passes each update on as it arrives (the two downloaders already
  /// deliver them asynchronously), while anyone listens.
  late final StreamController<PackDownload> _updates =
      StreamController<PackDownload>.broadcast(
        sync: true,
        onListen: () => _sources = [
          network.updates.listen(_updates.add),
          drive.updates.listen(_updates.add),
        ],
        onCancel: () {
          for (final source in _sources) {
            unawaited(source.cancel());
          }
          _sources = const [];
        },
      );
  var _sources = const <StreamSubscription<PackDownload>>[];

  CombinedPackDownloader(this.network, this.drive);

  @override
  Stream<PackDownload> get updates => _updates.stream;

  @override
  List<PackDownload> get downloads => [
    ...network.downloads,
    ...drive.downloads,
  ];

  @override
  Future<void> start(DownloadItem item) async {
    drive.forget(item.id);
    await network.start(item);
  }

  /// Installs [item] from the drive, dropping a failed download of it from
  /// the network first, so it doesn't come back at the next launch.
  Future<void> startFromDrive(DownloadItem item) async {
    final failed = network.downloads.any(
      (d) => d.id == item.id && d.state == PackDownloadState.failed,
    );
    if (failed) await network.cancel(item.id);
    await drive.start(item);
  }

  @override
  Future<void> pause(String id) => _owner(id).pause(id);

  @override
  Future<void> resume(String id) => _owner(id).resume(id);

  @override
  Future<void> cancel(String id) => _owner(id).cancel(id);

  @override
  Future<void> finish(String id, {String? error}) =>
      _owner(id).finish(id, error: error);

  PackDownloader _owner(String id) => drive.owns(id) ? drive : network;
}
