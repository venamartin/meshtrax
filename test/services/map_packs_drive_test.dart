import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:traxmap/traxmap.dart';

import '../../packages/traxmap/test/support/fake_pmtiles.dart';

final _picker = File('packages/traxmap/test/support/picker.geojson')
    .readAsStringSync();

const _ri = 'north-america/us/rhode-island';
const _wv = 'test/watsonville-test';

/// The server's downloader, offline: it only records what it was asked.
class _Network implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final active = <PackDownload>[];
  final started = <DownloadItem>[];

  @override
  Stream<PackDownload> get updates => _updates.stream;

  @override
  List<PackDownload> get downloads => active;

  @override
  Future<void> start(DownloadItem item) async => started.add(item);

  @override
  Future<void> pause(String id) async {}

  @override
  Future<void> resume(String id) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<void> finish(String id, {String? error}) async {}
}

void main() {
  late Directory tmp;
  late Directory stick;
  late _Network network;
  late MapPacksService maps;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mapdrive');
    stick = Directory('${tmp.path}/MeshTraxMap/MeshTrax-maps')
      ..createSync(recursive: true);
    network = _Network();
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: network,
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.meshtrax.io/index.json'),
      client: MockClient((_) async => http.Response('', 404)),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  /// A pack's index entry; its file goes on the stick unless [onDrive] is
  /// false, or with a size other than listed when [wrongSize].
  Map<String, Object?> pack(
    String id,
    String kind,
    String region, {
    String date = '2026-11-07',
    bool onDrive = true,
    bool wrongSize = false,
  }) {
    final bytes = fakePmTiles(
      metadata: {
        'kind': kind,
        'region': region,
        'build_date': date,
        'name': id,
      },
    );
    final path = 'v1/$region/$id.pmtiles';
    if (onDrive) {
      File('${stick.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(wrongSize ? bytes.sublist(1) : bytes);
    }
    return {
      'id': id,
      'name': id,
      'kind': kind,
      'bbox': [-72, 41, -71, 42],
      'bytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
      'build_date': date,
      'schema_version': 1,
      'url': 'https://maps.meshtrax.io/$path',
      'region': region,
    };
  }

  /// Writes the stick's `index.json` and picker.
  void index(List<Map<String, Object?>> packs) {
    File('${stick.path}/index.json').writeAsStringSync(
      jsonEncode({
        'generated': '2026-11-07T19:32:55Z',
        'schema_version': 1,
        'packs': packs,
      }),
    );
    File('${stick.path}/picker.geojson').writeAsStringSync(_picker);
  }

  Future<void> installed(String id) async {
    for (var i = 0; i < 500 && maps.installedPack(id) == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(maps.installedPack(id), isNotNull);
  }

  test("only what's on the drive shows, and the server's catalogue comes "
      'back', () async {
    final cached = {
      'generated': '2026-11-01T00:00:00Z',
      'schema_version': 1,
      'packs': [pack('wv-osm', 'osm', _wv, onDrive: false)],
    };
    File('${tmp.path}/maps/index.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(cached));
    await maps.start();
    expect(maps.index!.packs.single.id, 'wv-osm');

    index([
      pack('ri-osm', 'osm', _ri),
      pack('ri-terrain', 'terrain', _ri, wrongSize: true),
      pack('wv-osm', 'osm', _wv, onDrive: false),
    ]);
    await maps.useDrive(IoMapDrive(stick));
    expect(maps.drive, isNotNull);
    expect(maps.index!.packs.map((e) => e.id), ['ri-osm']);
    expect(maps.catalogue!['packs'], hasLength(1));
    expect(maps.status, CatalogueStatus.ready);
    expect(maps.driveMapsDate, DateTime.utc(2026, 11, 7, 19, 32, 55));
    expect(maps.hasContent(_ri), isTrue);
    expect(maps.hasContent('north-america/us'), isTrue);
    expect(maps.hasContent(_wv), isFalse);

    await maps.useInternet();
    expect(maps.drive, isNull);
    expect(maps.index!.packs.single.id, 'wv-osm');
    expect(maps.hasContent(_wv), isTrue);
  });

  test(
    "the drive's own top folder works: the maps folder in it is used",
    () async {
      await maps.start();
      index([pack('ri-osm', 'osm', _ri)]);
      await maps.useDrive(IoMapDrive(stick.parent));
      expect(maps.drive!.name, 'MeshTraxMap');
      expect(maps.index!.packs.single.id, 'ri-osm');
    },
  );

  test('a folder with no maps is refused', () async {
    await maps.start();
    await expectLater(
      maps.useDrive(IoMapDrive(Directory('${tmp.path}/maps')..createSync())),
      throwsFormatException,
    );
    expect(maps.drive, isNull);
  });

  test("packs install from the drive, and the server's downloader isn't "
      'used', () async {
    await maps.start();
    index([pack('ri-osm', 'osm', _ri)]);
    await maps.useDrive(IoMapDrive(stick));

    await maps.download(maps.index!.packs);
    await installed('ri-osm');
    expect(network.started, isEmpty);
    expect(maps.statusOf(maps.index!.packs.single), PackStatus.installed);
  });

  test('something downloading from the server is left to finish', () async {
    await maps.start();
    index([pack('ri-osm', 'osm', _ri)]);
    await maps.useDrive(IoMapDrive(stick));
    final entry = maps.index!.packs.single;
    network.active.add(PackDownload(entry, PackDownloadState.running));

    await maps.download([entry]);
    expect(maps.downloader.drive.downloads, isEmpty);
  });

  test('a drive never offers an older build than the one installed', () async {
    await maps.start();
    index([pack('ri-osm', 'osm', _ri, date: '2026-11-07')]);
    await maps.useDrive(IoMapDrive(stick));
    await maps.download(maps.index!.packs);
    await installed('ri-osm');

    // Another stick, written earlier: the same pack, an older build.
    stick.deleteSync(recursive: true);
    index([pack('ri-osm', 'osm', _ri, date: '2026-11-01')]);
    await maps.useDrive(IoMapDrive(stick));
    final older = maps.index!.packs.single;
    expect(maps.statusOf(older), PackStatus.installed);
    expect(maps.updates, isEmpty);

    // And one written later.
    stick.deleteSync(recursive: true);
    index([pack('ri-osm', 'osm', _ri, date: '2026-11-08')]);
    await maps.useDrive(IoMapDrive(stick));
    final newer = maps.index!.packs.single;
    expect(maps.statusOf(newer), PackStatus.updateAvailable);
    expect(maps.updates.single.id, 'ri-osm');
  });

  test(
    "a phone that has never been online keeps the drive's catalogue",
    () async {
      await maps.start();
      expect(maps.index, isNull);
      index([
        pack('ri-osm', 'osm', _ri),
        pack('wv-osm', 'osm', _wv, onDrive: false),
      ]);
      await maps.useDrive(IoMapDrive(stick));
      await maps.useInternet();

      expect(maps.index!.packs.map((e) => e.id), ['ri-osm', 'wv-osm']);
      expect(maps.regions![_ri], isNotNull);
      expect(maps.fetchedAt!.toUtc(), DateTime.utc(2026, 11, 7, 19, 32, 55));
      expect(File('${tmp.path}/maps/index.json.etag').existsSync(), isFalse);
    },
  );

  test('a drive that goes away sends the app back to the server', () async {
    await maps.start();
    index([pack('ri-osm', 'osm', _ri)]);
    await maps.useDrive(IoMapDrive(stick));
    expect(await maps.checkDrive(), isTrue);

    stick.deleteSync(recursive: true);
    expect(await maps.checkDrive(), isFalse);
    expect(maps.drive, isNull);
    expect(maps.driveRemoved, isTrue);
  });
}
