# traxmap history notes

traxmap was built in its own repository from 2026-10-16 and moved into MeshTrax
on 2026-10-17 ([#164](https://github.com/venamartin/meshtrax/pull/164),
squash-merged, so its commits aren't in MeshTrax's history). This file keeps
what mattered from that history. Details:

- **Changes:** [CHANGELOG.md](CHANGELOG.md).
- **Decisions, measurements and pitfalls:** traxmapmaker's
  [FINDINGS.md](https://github.com/venamartin/traxmapmaker/blob/main/FINDINGS.md),
  especially "Pack downloads with background_downloader" and section 8,
  "MeshTrax integration".

## Commits before the move

| Date | Commit |
| --- | --- |
| 2026-10-16 | Initial traxmap package, split out of the `vectormaps` prototype |
| 2026-10-16 | Simplify map choice to OSM, USGS and NOAA Charts, each light and dark |
| 2026-10-16 | Draw land contours on the NOAA chart styles |
| 2026-10-16 | Add Offline maps screen notes to the MeshTrax integration section |
| 2026-10-16 | Download packs in the background with background_downloader |
| 2026-10-17 | License traxmap under MIT, matching MeshTrax |

On the move, the example app was dropped (MeshTrax is the host) and the
bundled test packs left git (see the README, "Test packs").

## The removed example app

`example/` was a test bench that ran on Linux desktop and phones:
- **Main screen:** map picker (OSM / USGS / NOAA Charts), light/dark,
  contours on/off, ft/m, a pack drawer and a stress test.
- **MeshTrax-style demo:** markers, labels, lines, fits.
- **"Get maps" page:** the pack index, with download, pause, resume and
  cancel.

Desktop variables: `OVM_MAP`, `OVM_THEME`, `OVM_CAMERA`, `OVM_UNITS`,
`OVM_CONTOURS`, `OVM_SCREEN=meshtrax`, `OVM_INDEX`, `OVM_DOWNLOAD`,
`OVM_STYLES`.

### "Get maps" page: what MeshTrax's Offline maps screen should copy

- **Fetch the index** with dart:io's `HttpClient` and `PackIndex.parse`, so
  no extra dependency. Show the URL and the error when it fails.
- **Installed packs:** know them from `PackManager.listInstalled()`, and
  reload on every `installed` update from `PackDownloader.updates`.
- **Each row:** name, kind, size in MB, and status:
  - `installed`;
  - `running` or `paused`, with "N of M MB";
  - `failed: <error>`;
  - otherwise the state name.

  Show a progress bar while not final.
- **Buttons by state:**
  - **Pause:** while running.
  - **Resume:** when paused or failed.
  - **Cancel:** while active and not verifying.
  - **Download / Download again:** otherwise.
- **Before the first download,** call
  `BackgroundPackDownloader.requestNotificationPermission()` (Android 14+
  long-download notification).

### Pack download integration test

Real downloads through background_downloader, against traxmapmaker's local
pack server (`./tmm publish` with a local config, then
`./viewer/serve.py --rate 8`). It skips when the server isn't running.

It picks the biggest pack under 100 MB, then checks each step:
- downloads to 30%, pauses, waits 2 s, and resumes;
- progress after resuming never falls below the pause point, so it really
  resumed with a range request instead of restarting;
- the states run queued → running → paused → running → verifying →
  installed;
- the pack's SHA-256 verifies;
- no download leftovers sit next to the packs.

Measured on the Pi: a 90.6 MB charts pack in 21 s, with one 206 range
request.

Move it into MeshTrax's `integration_test/` when pack downloads are wired
up. It imported `fetchIndex` from the example's downloads page. The source,
as it was:

```dart
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
```
