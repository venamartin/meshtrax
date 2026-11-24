import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/photo_model_downloads.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

import '../helpers/map_fakes.dart';

/// The map downloader's side: records starts and finishes, emits on demand.
class _FakeDownloads implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final latest = <String, PackDownload>{};
  final started = <DownloadFile>[];
  final finished = <String, String?>{};

  void emit(PackDownload d) {
    latest[d.id] = d;
    _updates.add(d);
  }

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => latest.values.toList();
  @override
  Future<void> start(DownloadItem item) async {
    started.add(item as DownloadFile);
    emit(PackDownload(item, PackDownloadState.queued, progress: 0));
  }

  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> resume(String id) async {}
  @override
  Future<void> cancel(String id) async =>
      emit(PackDownload(latest[id]!.item, PackDownloadState.canceled));
  @override
  Future<void> finish(String id, {String? error}) async {
    finished[id] = error;
    emit(
      error == null
          ? PackDownload(latest[id]!.item, PackDownloadState.installed)
          : PackDownload(
              latest[id]!.item,
              PackDownloadState.failed,
              error: error,
            ),
    );
  }
}

final en = lookupAppLocalizations(const Locale('en'));

void main() {
  late Directory tmp;
  late _FakeDownloads fake;
  late MapPacksService maps;

  Future<PhotoModelDownloads> follow() async {
    await PhotoModelDownloads.start(maps, dir: Directory('${tmp.path}/ft8'));
    return PhotoModelDownloads.instance!;
  }

  /// A checked file the downloader hands over for [item].
  PackDownload handover(DownloadFile item, List<int> bytes) {
    final file = File('${tmp.path}/downloads/${item.id}.download')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return PackDownload(
      item,
      PackDownloadState.downloaded,
      progress: 1,
      path: file.path,
    );
  }

  DownloadFile itemFor(String name) =>
      fake.started.singleWhere((i) => i.payload['name'] == name);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('photomodel');
    fake = _FakeDownloads();
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: fake,
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles(maps: ['osm'])),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  test('asks the map downloader for each file, as its own kind', () async {
    final models = await follow();
    await models.download(en);
    expect(fake.started.map((i) => i.payload['name']), [
      for (final f in PhotoModelDownloads.files) f.name,
      for (final f in PhotoModelDownloads.licences) f.name,
    ]);
    expect(fake.started.map((i) => i.kind).toSet(), {PhotoModelDownloads.kind});
    expect(fake.started.first.name, 'Photo model (1 of 12)');
    expect(fake.started.last.name, 'Photo model licence (7 of 7)');
    expect(models.active, hasLength(19));
  });

  test('a licence text goes in the licences folder', () async {
    final models = await follow();
    await models.download(en);
    final notice = fake.started.singleWhere(
      (i) => i.payload['name'] == 'NOTICE.txt',
    );
    expect(notice.payload['folder'], 'licences');
    fake.emit(handover(notice, [9]));
    await pumpEventQueue();
    await models.idle;
    expect(File('${tmp.path}/ft8/licences/NOTICE.txt').readAsBytesSync(), [9]);
    expect(fake.finished, {notice.id: null});
  });

  test('moves a checked file into place, then finishes it', () async {
    final models = await follow();
    await models.download(en);
    final item = itemFor('aeic_cdf_ft8.bin');
    final d = handover(item, [1, 2, 3]);
    fake.emit(d);
    await pumpEventQueue();
    await models.idle;
    expect(File('${tmp.path}/ft8/aeic_cdf_ft8.bin').readAsBytesSync(), [
      1,
      2,
      3,
    ]);
    expect(File(d.path!).existsSync(), isFalse);
    expect(fake.finished, {item.id: null});
  });

  test('installs what was handed over before it started', () async {
    final early = await follow();
    await early.download(en);
    final item = itemFor('aeic_cdf_ft8.bin');
    fake.latest[item.id] = handover(item, [7]);
    final models = await follow();
    await models.idle;
    expect(File('${tmp.path}/ft8/aeic_cdf_ft8.bin').readAsBytesSync(), [7]);
    expect(fake.finished, {item.id: null});
  });

  test('a handover seen again after the move finishes quietly', () async {
    final models = await follow();
    await models.download(en);
    final tables = kImageCodecFiles.singleWhere(
      (f) => f.name == 'aeic_cdf_ft8.bin',
    );
    final item = itemFor(tables.name);
    final d = handover(item, List.filled(tables.bytes, 0));
    fake.emit(d);
    await pumpEventQueue();
    await models.idle;
    fake.finished.clear();
    fake.emit(d);
    await pumpEventQueue();
    await models.idle;
    expect(fake.finished, {item.id: null});
  });

  test('downloads only what is missing, and deletes only the model', () async {
    final models = await follow();
    final dir = Directory('${tmp.path}/ft8')..createSync();
    final tables = kImageCodecFiles.singleWhere(
      (f) => f.name == 'aeic_cdf_ft8.bin',
    );
    File('${dir.path}/${tables.name}')
        .writeAsBytesSync(List.filled(tables.bytes, 0));
    await models.download(en);
    expect(
      fake.started.map((i) => i.payload['name']),
      isNot(contains(tables.name)),
    );
    expect(
      fake.started,
      hasLength(
        PhotoModelDownloads.files.length - 1 +
            PhotoModelDownloads.licences.length,
      ),
    );

    File('${dir.path}/something-else.txt').writeAsStringSync('x');
    File('${dir.path}/xnnpack/x.xnnpack_cache')
      ..createSync(recursive: true)
      ..writeAsStringSync('x');
    await models.delete();
    expect(dir.listSync().map((e) => e.uri.pathSegments.last).toSet(), {
      'something-else.txt',
    });
    expect(models.active, isEmpty);
  });

  test('holds the download when the device lacks the room', () {
    const gb = 1000 * 1000 * 1000;
    expect(PhotoModelDownloads.spaceProblem(needed: gb, free: 2 * gb), isNull);
    expect(PhotoModelDownloads.spaceProblem(needed: gb, free: null), isNull);
    expect(
      PhotoModelDownloads.spaceProblem(needed: gb, free: gb),
      (needed: gb + PhotoModelDownloads.spareBytes, free: gb),
    );
  });
}
