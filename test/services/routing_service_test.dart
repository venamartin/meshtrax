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

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
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

  Future<(MapPacksService, RoutingService)> services() async {
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
    final maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/maps/packs')),
      downloader: _NoDownloads(),
      cacheDir: Directory('${tmp.path}/maps'),
      indexUrl: Uri.parse('https://maps.example/index.json'),
      client: client,
    );
    await maps.refresh();
    return (maps, await RoutingService.create(maps, client: client));
  }

  test('a bundle gone from the server: the catalogue is read again and '
      'the current build installed', () async {
    catalogue = routing('b1', ['test/a']);
    final (_, service) = await services();
    expect(service.catalog!.build, 'b1');

    // The server moves on to b2 and b1's files go, before the download.
    files.clear();
    catalogue = routing('b2', ['test/a']);
    await service.download({'test/a'});

    expect(service.error, isNull);
    expect(service.store.build, 'b2');
    expect(service.installedRegions, {'test/a'});
  });

  test('a catalogue that lists nothing keeps what is installed', () async {
    catalogue = routing('b1', ['test/a', 'test/b']);
    final (_, service) = await services();
    await service.download({'test/a'});
    expect(service.installedRegions, {'test/a'});

    // Mid-publish: b1's files are gone and b2 lists no regions yet.
    files.clear();
    catalogue = routing('b2', []);
    await service.download({'test/b'});

    expect(service.store.build, 'b1');
    expect(service.installedRegions, {'test/a'});
    expect(service.hasRoutingData, isTrue);
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
    final (maps, service) = await services();
    expect(service.credits, isEmpty);

    await service.download({'test/a', 'test/b'});
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

  test('routing only for a newer engine needs a newer app', () async {
    catalogue = {
      'valhalla-4.0': {'build': 'x', 'regions': {}},
    };
    final (_, service) = await services();
    expect(service.catalog, isNull);
    expect(service.needsNewerApp, isTrue);
  });
}
