import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

import 'support/fake_pmtiles.dart';

/// A drive whose copies write the first half of the file, then wait for
/// [release] (or a stop) before writing the rest.
class _SlowDrive implements MapDrive {
  final IoMapDrive inner;
  var release = Completer<void>();
  final halfway = StreamController<String>.broadcast();
  var readable = true;

  _SlowDrive(this.inner);

  @override
  String get name => inner.name;

  @override
  Future<Map<String, int>> list() => inner.list();

  @override
  Future<String> readText(String path) => inner.readText(path);

  @override
  Future<void> copy(
    String path,
    File to, {
    int from = 0,
    Future<void>? stop,
  }) async {
    final bytes = File('${inner.root.path}/$path').readAsBytesSync();
    final half = bytes.length ~/ 2;
    final sink = to.openWrite(
      mode: from == 0 ? FileMode.writeOnly : FileMode.writeOnlyAppend,
    );
    try {
      if (from < half) {
        sink.add(bytes.sublist(from, half));
        await sink.flush();
        halfway.add(path);
        final stopped = await Future.any([
          release.future.then((_) => false),
          if (stop != null) stop.then((_) => true),
        ]);
        if (stopped) throw const DriveCopyStopped();
        from = half;
      }
      sink.add(bytes.sublist(from));
    } finally {
      await sink.close();
    }
  }

  @override
  Future<bool> isReadable() async => readable;

  @override
  MapDrive inFolder(String name) => throw UnimplementedError();

  @override
  Future<void> close() async {}
}

void main() {
  late Directory tmp;
  late Directory stick;
  late PackManager manager;
  late DrivePackDownloader drive;
  late List<PackDownload> seen;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('drive');
    stick = Directory('${tmp.path}/MeshTrax-maps')..createSync();
    File('${stick.path}/index.json').writeAsStringSync('{}');
    manager = PackManager(Directory('${tmp.path}/maps/packs'));
    drive = DrivePackDownloader(manager);
    seen = [];
    drive.updates.listen(seen.add);
  });
  tearDown(() => tmp.delete(recursive: true));

  /// Puts [bytes] on the stick at [path] and returns its sha256.
  String put(String path, List<int> bytes) {
    File('${stick.path}/$path')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return sha256.convert(bytes).toString();
  }

  /// A pack entry for [bytes], put on the stick unless [onDrive] is false;
  /// [sum] overrides the checksum the entry lists.
  PackIndexEntry pack(
    String id,
    List<int> bytes, {
    bool onDrive = true,
    String? sum,
  }) {
    final actual = onDrive
        ? put('v1/test/$id.pmtiles', bytes)
        : sha256.convert(bytes).toString();
    return PackIndexEntry(
      id: id,
      name: id,
      kind: PackKind.osm,
      bbox: LatLngBounds.fromList([-72, 41, -71, 42]),
      bytes: bytes.length,
      sha256: sum ?? actual,
      buildDate: DateTime.utc(2026, 11, 7),
      schemaVersion: 1,
      url: Uri.parse('https://maps.example/v1/test/$id.pmtiles'),
    );
  }

  void attach([MapDrive? to]) =>
      drive.attach(to ?? IoMapDrive(stick), (url) => url.path.substring(1));

  Future<PackDownload> settled(String id) async {
    while (true) {
      final d = drive.downloads.where((d) => d.id == id).firstOrNull;
      if (d != null &&
          (d.state.isFinal ||
              d.state == PackDownloadState.downloaded ||
              d.state == PackDownloadState.paused)) {
        return d;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('a pack copies from the drive, is checked and installed', () async {
    attach();
    final bytes = fakePmTiles(metadata: {'kind': 'osm'});
    final entry = pack('ri', bytes);

    await drive.start(entry);
    final done = await settled('ri');
    expect(done.state, PackDownloadState.installed);
    await pumpEventQueue();
    expect(
      seen.map((d) => d.state),
      containsAllInOrder([
        PackDownloadState.queued,
        PackDownloadState.running,
        PackDownloadState.verifying,
        PackDownloadState.installed,
      ]),
    );
    final installed = (await manager.listInstalled()).single;
    expect(installed.id, 'ri');
    expect(installed.isBuild(entry.sha256), isTrue);
    expect(
      manager.root.listSync().where(
        (f) => f.path.endsWith(DrivePackDownloader.suffix),
      ),
      isEmpty,
    );
  });

  test(
    "the app's own file is checked and handed over, then finished",
    () async {
      attach();
      final bytes = List.generate(1000, (i) => i % 256);
      final file = DownloadFile(
        id: 'routing-test_a',
        name: 'A',
        region: 'test/a',
        url: Uri.parse('https://maps.example/routing/b1/test/a.tar.gz'),
        bytes: bytes.length,
        sha256: put('routing/b1/test/a.tar.gz', bytes),
        kind: 'routing',
      );

      await drive.start(file);
      final handed = await settled(file.id);
      expect(handed.state, PackDownloadState.downloaded);
      expect(File(handed.path!).readAsBytesSync(), bytes);
      expect(drive.owns(file.id), isTrue);

      await drive.finish(file.id);
      expect((await settled(file.id)).state, PackDownloadState.installed);
      expect(drive.owns(file.id), isFalse);
    },
  );

  test(
    'a file not on the drive, or damaged, fails and leaves nothing',
    () async {
      attach();
      final missing = pack('gone', [1, 2, 3], onDrive: false);
      final bytes = fakePmTiles(metadata: {'kind': 'osm'});
      final damaged = pack('bad', bytes, sum: 'cd' * 32);

      await drive.start(missing);
      await drive.start(damaged);
      final gone = await settled('gone');
      expect(gone.state, PackDownloadState.failed);
      expect(gone.error, isNot(DrivePackDownloader.removedError));
      final bad = await settled('bad');
      expect(bad.state, PackDownloadState.failed);
      expect(bad.error, contains('Checksum'));
      expect(await manager.listInstalled(), isEmpty);
      expect(manager.root.listSync(), isEmpty);
    },
  );

  test('pause keeps the copy so far, and resume carries on from it', () async {
    final slow = _SlowDrive(IoMapDrive(stick));
    attach(slow);
    final bytes = fakePmTiles(metadata: {'kind': 'osm', 'pad': 'x' * 4000});
    final entry = pack('ri', bytes);

    final halfway = slow.halfway.stream.first;
    await drive.start(entry);
    await halfway;
    await drive.pause('ri');
    final paused = await settled('ri');
    expect(paused.state, PackDownloadState.paused);
    expect(paused.progress, closeTo(0.5, 0.01));
    final partial = File(
      '${manager.root.path}/ri.pmtiles${DrivePackDownloader.suffix}',
    );
    expect(partial.lengthSync(), bytes.length ~/ 2);

    slow.release.complete();
    await drive.resume('ri');
    expect((await settled('ri')).state, PackDownloadState.installed);
    expect(
      (await manager.listInstalled()).single.isBuild(entry.sha256),
      isTrue,
    );
  });

  test('cancel stops the copy and deletes it', () async {
    final slow = _SlowDrive(IoMapDrive(stick));
    attach(slow);
    final entry = pack('ri', fakePmTiles(metadata: {'pad': 'x' * 4000}));

    final halfway = slow.halfway.stream.first;
    await drive.start(entry);
    await halfway;
    await drive.cancel('ri');
    expect((await settled('ri')).state, PackDownloadState.canceled);
    expect(manager.root.listSync(), isEmpty);
  });

  test('a drive taken away fails what was copying and waiting', () async {
    final slow = _SlowDrive(IoMapDrive(stick));
    attach(slow);
    final first = pack('a', fakePmTiles(metadata: {'pad': 'x' * 4000}));
    final second = pack('b', fakePmTiles(metadata: {'pad': 'y' * 4000}));

    final halfway = slow.halfway.stream.first;
    await drive.start(first);
    await drive.start(second);
    await halfway;
    slow.readable = false;
    await drive.detach(error: DrivePackDownloader.removedError);

    for (final id in ['a', 'b']) {
      final d = await settled(id);
      expect(d.state, PackDownloadState.failed);
      expect(d.error, DrivePackDownloader.removedError);
    }
    expect(drive.drive, isNull);
    expect(manager.root.listSync(), isEmpty);
  });

  test('copies an earlier run left are cleaned away', () async {
    final partial = File(
      '${manager.root.path}/ri.pmtiles${DrivePackDownloader.suffix}',
    )..createSync(recursive: true);
    final handed = File(
      '${drive.files.path}/poi-a${DrivePackDownloader.suffix}',
    )..createSync(recursive: true);
    final download = File('${manager.root.path}/ri.pmtiles.download')
      ..createSync();

    await drive.clean();
    expect(partial.existsSync(), isFalse);
    expect(handed.existsSync(), isFalse);
    expect(download.existsSync(), isTrue);
  });

  group('combined with the network downloader', () {
    late _Network network;
    late CombinedPackDownloader both;

    setUp(() {
      network = _Network();
      both = CombinedPackDownloader(network, drive);
    });

    test('downloads go to the network, drive installs to the drive, and '
        'finish to whichever has the item', () async {
      attach();
      final bytes = List.generate(100, (i) => i);
      final file = DownloadFile(
        id: 'poi-a',
        name: 'A',
        url: Uri.parse('https://maps.example/poi/a.sqlite.gz'),
        bytes: bytes.length,
        sha256: put('poi/a.sqlite.gz', bytes),
        kind: 'poi-points',
      );
      final updates = <PackDownload>[];
      both.updates.listen(updates.add);

      await both.startFromDrive(file);
      expect((await settled('poi-a')).state, PackDownloadState.downloaded);
      expect(network.started, isEmpty);
      expect(both.downloads.map((d) => d.id), ['poi-a']);

      await both.finish('poi-a');
      await pumpEventQueue();
      expect(network.finished, isEmpty);
      expect(updates.last.state, PackDownloadState.installed);

      // Later from the network: the drive's finished record steps aside.
      await both.start(file);
      expect(network.started.single.id, 'poi-a');
      expect(drive.downloads, isEmpty);
      await both.finish('poi-a');
      expect(network.finished, ['poi-a']);
    });

    test(
      "a failed network download is dropped when the drive takes over",
      () async {
        attach();
        final entry = pack('ri', fakePmTiles(metadata: {'kind': 'osm'}));
        network.failed(entry);

        await both.startFromDrive(entry);
        expect(network.canceled, ['ri']);
        expect((await settled('ri')).state, PackDownloadState.installed);
      },
    );
  });
}

class _Network implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final _latest = <String, PackDownload>{};
  final started = <DownloadItem>[];
  final finished = <String>[];
  final canceled = <String>[];

  void failed(DownloadItem item) =>
      _latest[item.id] = PackDownload(item, PackDownloadState.failed);

  @override
  Stream<PackDownload> get updates => _updates.stream;

  @override
  List<PackDownload> get downloads => _latest.values.toList();

  @override
  Future<void> start(DownloadItem item) async {
    started.add(item);
    _latest[item.id] = PackDownload(item, PackDownloadState.queued);
  }

  @override
  Future<void> pause(String id) async {}

  @override
  Future<void> resume(String id) async {}

  @override
  Future<void> cancel(String id) async {
    canceled.add(id);
    _latest.remove(id);
  }

  @override
  Future<void> finish(String id, {String? error}) async => finished.add(id);
}
