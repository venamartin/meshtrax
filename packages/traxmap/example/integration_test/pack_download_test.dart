// Real downloads through background_downloader, against traxmapmaker's dev
// server. Run on the desktop (or a phone that can reach the server):
//
//   cd ../traxmapmaker && ./tmm publish --config <local config> && ./viewer/serve.py --rate 8
//   flutter test integration_test/pack_download_test.dart -d linux
//
// OVM_INDEX overrides the index URL. Skipped when the server isn't running.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxmap_example/downloads_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final indexUrl = Uri.parse(
    Platform.environment['OVM_INDEX'] ??
        'http://127.0.0.1:8000/out/published/index.json',
  );

  test('download a pack, pause, resume, verify and install', () async {
    final PackIndex index;
    try {
      index = await fetchIndex(indexUrl);
    } on SocketException {
      markTestSkipped('No pack server at $indexUrl');
      return;
    }
    // The biggest pack under 100 MB: long enough to pause, quick to finish.
    final entry =
        (index.packs.where((e) => e.bytes < 100e6).toList()
              ..sort((a, b) => b.bytes.compareTo(a.bytes)))
            .first;

    final tmp = await Directory.systemTemp.createTemp('traxmap-dl');
    final manager = PackManager(Directory('${tmp.path}/packs'));
    final downloader = BackgroundPackDownloader(manager, scope: 'traxmap-test');
    final states = <PackDownloadState>[];
    final sub = downloader.updates.listen((d) {
      if (states.isEmpty || states.last != d.state) {
        states.add(d.state);
        // ignore: avoid_print
        print('download: $d');
      }
    });
    // ignore: avoid_print
    print('index ok: ${index.packs.length} packs, testing ${entry.id}');
    await downloader.restore();

    Future<PackDownload> until(bool Function(PackDownload) test) => downloader
        .updates
        .firstWhere((d) => d.id == entry.id && test(d))
        .timeout(const Duration(minutes: 3));

    await downloader.start(entry);
    await until((d) => (d.progress ?? 0) >= 0.3);
    await downloader.pause(entry.id);
    final paused = await until((d) => d.state == PackDownloadState.paused);
    await Future<void>.delayed(const Duration(seconds: 2));

    final afterResume = <double>[];
    final watch = downloader.updates.listen((d) {
      if (d.state == PackDownloadState.running && d.progress != null) {
        afterResume.add(d.progress!);
      }
    });
    await downloader.resume(entry.id);
    final done = await until((d) => d.state.isFinal);
    await watch.cancel();
    expect(done.state, PackDownloadState.installed, reason: '${done.error}');
    // Resumed, not restarted: progress never fell back below the pause point.
    expect(afterResume, isNotEmpty);
    expect(
      afterResume.reduce((a, b) => a < b ? a : b),
      greaterThanOrEqualTo(paused.progress! - 0.01),
    );

    final installed = await manager.listInstalled();
    expect(installed.map((p) => p.id), [entry.id]);
    expect(await manager.verify(installed.single, entry.sha256), isTrue);
    expect(
      states,
      containsAllInOrder([
        PackDownloadState.queued,
        PackDownloadState.running,
        PackDownloadState.paused,
        PackDownloadState.running,
        PackDownloadState.verifying,
        PackDownloadState.installed,
      ]),
    );
    // No leftover download file next to the packs.
    expect(
      manager.root
          .listSync()
          .map((f) => f.path)
          .where((p) => !p.endsWith('.pmtiles')),
      isEmpty,
    );

    await sub.cancel();
    await downloader.dispose();
    await tmp.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
