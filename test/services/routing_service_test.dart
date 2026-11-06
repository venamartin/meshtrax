import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/routing_service.dart';
import 'package:traxmap/traxmap.dart';

final _index = jsonDecode(
  File('packages/traxmap/test/support/sample_index.json').readAsStringSync(),
) as Map<String, dynamic>;

/// Stands in for the background downloader: serves [files] by URL path at
/// once, as checked downloads, and remembers what it was asked. Ids in
/// [held] stay running until [release]d.
class _FakeDownloader implements PackDownloader {
  final Map<String, Uint8List> files;
  final Directory dir;
  final started = <DownloadItem>[];
  final _updates = StreamController<PackDownload>.broadcast(sync: true);
  final _latest = <String, PackDownload>{};

  _FakeDownloader(this.files, this.dir);

  PackDownload? latest(String id) => _latest[id];

  void _emit(PackDownload d) {
    _latest[d.id] = d;
    _updates.add(d);
  }

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => _latest.values.toList();

  final held = <String>{};

  /// Lets a held download finish.
  Future<void> release(String id) async {
    held.remove(id);
    await start(_latest[id]!.item);
  }

  /// A held download that failed for good.
  void fail(String id) => _emit(
    PackDownload(_latest[id]!.item, PackDownloadState.failed, error: 'HTTP 500'),
  );

  @override
  Future<void> start(DownloadItem item) async {
    if (held.contains(item.id)) {
      _emit(PackDownload(item, PackDownloadState.running, progress: 0.5));
      return;
    }
    started.add(item);
    final bytes = files[item.url.path.substring(1)];
    if (bytes == null) {
      _emit(PackDownload(item, PackDownloadState.failed, error: 'HTTP 404'));
      return;
    }
    final file = File('${dir.path}/${item.id}')..writeAsBytesSync(bytes);
    _emit(
      PackDownload(
        item,
        PackDownloadState.downloaded,
        progress: 1,
        path: file.path,
      ),
    );
  }

  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> resume(String id) async {}
  @override
  Future<void> cancel(String id) async =>
      _emit(PackDownload(_latest[id]!.item, PackDownloadState.canceled));
  @override
  Future<void> finish(String id, {String? error}) async => _emit(
    PackDownload(
      _latest[id]!.item,
      error == null ? PackDownloadState.installed : PackDownloadState.failed,
      progress: 1,
      error: error,
    ),
  );
}

/// A gzipped routing bundle holding one tile, as traxmapmaker writes them.
Uint8List _bundle(String tile) {
  final data = utf8.encode('tile $tile');
  final header = Uint8List(512)
    ..setAll(0, ascii.encode(tile))
    ..setAll(
      124,
      ascii.encode('${data.length.toRadixString(8).padLeft(11, '0')}\u0000'),
    )
    ..[156] = 0x30;
  final padding = Uint8List((512 - data.length % 512) % 512);
  return Uint8List.fromList(
    gzip.encode([...header, ...data, ...padding, ...Uint8List(1024)]),
  );
}

void main() {
  late Directory tmp;
  late Map<String, Object> catalogue;
  late Map<String, Uint8List> files;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('routing');
    files = {};
  });
  tearDown(() => tmp.delete(recursive: true));

  /// The catalogue's routing entry for [build], with [regions]' bundles,
  /// which the server then holds, and their [credits].
  Map<String, Object> routing(
    String build,
    List<String> regions, {
    Map<String, Map<String, String>> credits = const {},
  }) {
    final entries = <String, Object>{};
    for (final (i, region) in regions.indexed) {
      final path = 'routing/valhalla-3.9/$build/$region.tar.gz';
      final bytes = files[path] = _bundle('2/000/00$i/001.gph');
      entries[region] = {
        'url': path,
        'bytes': bytes.length,
        'unpacked_bytes': 2048,
        'sha256': sha256.convert(bytes).toString(),
        ...?credits[region],
      };
    }
    return {
      'valhalla-3.9': {
        'engine': 'valhalla',
        'engine_version': '3.9.1',
        'build': build,
        'regions': entries,
      },
    };
  }

  Future<(MapPacksService, _FakeDownloader)> mapsService() async {
    final client = MockClient((request) async {
      final path = request.url.path.substring(1);
      if (path == 'index.json') {
        return http.Response.bytes(
          utf8.encode(jsonEncode({..._index, 'routing': catalogue})),
          200,
        );
      }
      final file = files[path];
      return file == null
          ? http.Response('', 404)
          : http.Response.bytes(file, 200);
    });
    final downloader = _FakeDownloader(
      files,
      Directory('${tmp.path}/downloads')..createSync(),
    );
    final maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: downloader,
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.example/index.json'),
      client: client,
    );
    await maps.refresh();
    return (maps, downloader);
  }

  Future<(MapPacksService, RoutingService, _FakeDownloader)> services() async {
    final (maps, downloader) = await mapsService();
    return (maps, await RoutingService.create(maps), downloader);
  }

  /// Files the downloader handed over that nobody cleaned up.
  List<FileSystemEntity> leftovers() =>
      Directory('${tmp.path}/downloads').listSync();

  test('bundles download through the map downloader and install as they '
      'arrive', () async {
    catalogue = routing('b1', ['test/a']);
    final (_, service, downloader) = await services();

    await service.download({'test/a'});
    final item = downloader.started.single as DownloadFile;
    expect(item.id, RoutingService.downloadId('test/a'));
    expect(item.region, 'test/a');
    expect(item.kind, RoutingService.downloadKind);
    expect(item.payload['build'], 'b1');
    await service.idle;

    expect(service.installedRegions, {'test/a'});
    expect(service.hasRoutingData, isTrue);
    expect(downloader.latest(item.id)!.state, PackDownloadState.installed);
    expect(leftovers(), isEmpty);
  });

  test('a bundle gone from the server: the catalogue is read again and '
      'the current build installed', () async {
    catalogue = routing('b1', ['test/a']);
    final (_, service, downloader) = await services();
    expect(service.catalog!.build, 'b1');

    // The server moves on to b2 and b1's files go, before the download.
    files.clear();
    catalogue = routing('b2', ['test/a']);
    await service.download({'test/a'});
    await service.idle;

    expect(service.store.build, 'b2');
    expect(service.installedRegions, {'test/a'});
    expect(
      downloader.latest(RoutingService.downloadId('test/a'))!.state,
      PackDownloadState.installed,
    );
  });

  test('a catalogue that lists nothing keeps what is installed', () async {
    catalogue = routing('b1', ['test/a', 'test/b']);
    final (_, service, _) = await services();
    await service.download({'test/a'});
    await service.idle;
    expect(service.installedRegions, {'test/a'});

    // Mid-publish: b1's files are gone and b2 lists no regions yet.
    files.clear();
    catalogue = routing('b2', []);
    await service.download({'test/b'});
    await service.idle;

    expect(service.store.build, 'b1');
    expect(service.installedRegions, {'test/a'});
    expect(service.hasRoutingData, isTrue);
  });

  test('routing is offered where the catalogue has it, and anywhere once '
      'some is on the device', () async {
    files['picker.geojson'] = File(
      'packages/traxmap/test/support/picker.geojson',
    ).readAsBytesSync();
    catalogue = routing('b1', ['north-america/us/rhode-island']);
    final (_, service, _) = await services();
    const providence = (lat: 41.82, lon: -71.41);
    const watsonville = (lat: 36.91, lon: -121.76);
    expect(service.offeredAt(providence), isTrue);
    expect(service.offeredAt(watsonville), isFalse);

    await service.download({'north-america/us/rhode-island'});
    await service.idle;
    expect(service.offeredAt(watsonville), isTrue);
  });

  test("the installed regions' credits, offline too", () async {
    const osm = '© OpenStreetMap contributors; USGS 3DEP';
    const glo30 =
        'produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © '
        'Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by '
        'the European Union and ESA; all rights reserved';
    const notice =
        'The organisations in charge of the Copernicus programme by law or by '
        'delegation do not incur any liability for any use of the Copernicus '
        'WorldDEM-30.';
    catalogue = routing(
      'b1',
      ['test/a', 'test/b'],
      credits: {
        'test/a': {'attribution': osm},
        'test/b': {'attribution': '$osm; $glo30', 'notice': notice},
      },
    );
    final (maps, service, _) = await services();
    expect(service.credits, isEmpty);

    await service.download({'test/a', 'test/b'});
    await service.idle;
    expect(service.credits, [
      '© OpenStreetMap contributors',
      'USGS 3DEP',
      glo30,
    ]);
    expect(service.notices, [notice]);

    // The next start without a catalogue: they come from the device.
    File('${tmp.path}/maps/index.json').deleteSync();
    final offline = await RoutingService.create(maps);
    expect(offline.catalog, isNull);
    expect(offline.credits, service.credits);
    expect(offline.notices, service.notices);

    await service.remove('test/b');
    expect(service.credits, ['© OpenStreetMap contributors', 'USGS 3DEP']);
    expect(service.notices, isEmpty);
  });

  test('a new build replaces the old one once every bundle of it is in', () async {
    catalogue = routing('b1', ['test/a', 'test/b']);
    final (maps, service, downloader) = await services();
    await service.download({'test/a', 'test/b'});
    await service.idle;

    // The server moves on to b2. test/a's bundle arrives first; test/b's
    // is still on its way, as over a slow link or waiting for Wi-Fi.
    catalogue = routing('b2', ['test/a', 'test/b']);
    await maps.refresh();
    final b = RoutingService.downloadId('test/b');
    downloader.held.add(b);
    await service.download({'test/a'});
    await service.idle;
    expect(service.store.build, 'b1');
    expect(service.installedRegions, {'test/a', 'test/b'});

    await downloader.release(b);
    await service.idle;
    expect(service.store.build, 'b2');
    expect(service.installedRegions, {'test/a', 'test/b'});
    expect(leftovers(), isEmpty);
  });

  test('a failed bundle keeps the old build until it is canceled', () async {
    catalogue = routing('b1', ['test/a', 'test/b']);
    final (maps, service, downloader) = await services();
    await service.download({'test/a', 'test/b'});
    await service.idle;

    catalogue = routing('b2', ['test/a', 'test/b']);
    await maps.refresh();
    final b = RoutingService.downloadId('test/b');
    downloader.held.add(b);
    await service.download({'test/a'});
    downloader.fail(b);
    await service.idle;
    expect(service.store.build, 'b1');
    expect(service.installedRegions, {'test/a', 'test/b'});

    // Canceling it is choosing the new build without test/b.
    await downloader.cancel(b);
    await service.idle;
    expect(service.store.build, 'b2');
    expect(service.installedRegions, {'test/a'});
  });

  test('a region removed while a new build installs waits for the install', () async {
    catalogue = routing('b1', ['test/a', 'test/b']);
    final (maps, service, _) = await services();
    await service.download({'test/a', 'test/b'});
    await service.idle;

    // b2 drops test/b. Its install and test/b's removal start together, as
    // when a region is deleted while an update installs.
    catalogue = routing('b2', ['test/a']);
    await maps.refresh();
    final update = service.download({'test/a'});
    final removal = service.remove('test/b');
    await Future.wait([update, removal]);
    await service.idle;

    expect(service.store.build, 'b2');
    expect(service.installedRegions, {'test/a'});
    expect(service.hasRoutingData, isTrue);
  });

  test('a bundle that will not install is reported, and its file removed', () async {
    catalogue = routing('b1', ['test/a']);
    // Not a routing tile: the store refuses it.
    files['routing/valhalla-3.9/b1/test/a.tar.gz'] = _bundle('../../evil.gph');
    final (_, service, downloader) = await services();

    await service.download({'test/a'});
    await service.idle;

    final failed = downloader.latest(RoutingService.downloadId('test/a'))!;
    expect(failed.state, PackDownloadState.failed);
    expect(failed.error, contains('Not a routing tile'));
    expect(service.installedRegions, isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('a bundle handed over before the service started installs at start', () async {
    catalogue = routing('b1', ['test/a']);
    final (maps, downloader) = await mapsService();
    // Downloaded while the app was closed: the downloader restores it
    // before the routing service exists.
    final item = DownloadFile(
      id: RoutingService.downloadId('test/a'),
      name: 'A',
      region: 'test/a',
      url: Uri.parse(
        'https://maps.example/routing/valhalla-3.9/b1/test/a.tar.gz',
      ),
      bytes: 1,
      sha256: 'x',
      kind: RoutingService.downloadKind,
      payload: {'build': 'b1'},
    );
    await downloader.start(item);
    expect(downloader.latest(item.id)!.state, PackDownloadState.downloaded);

    final service = await RoutingService.create(maps);
    await service.idle;
    expect(service.installedRegions, {'test/a'});
    expect(downloader.latest(item.id)!.state, PackDownloadState.installed);
  });

  test('routing only for a newer engine needs a newer app', () async {
    catalogue = {
      'valhalla-4.0': {'build': 'x', 'regions': {}},
    };
    final (_, service, _) = await services();
    expect(service.catalog, isNull);
    expect(service.needsNewerApp, isTrue);
  });
}
