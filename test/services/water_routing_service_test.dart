import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/water_routing_service.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxwater/traxwater.dart'
    show WaterRoutingException, WaterRoutingProblem;

final _index = jsonDecode(
  File('packages/traxmap/test/support/sample_index.json').readAsStringSync(),
) as Map<String, dynamic>;
const _area = 'test/watsonville-test';
const _build = '2026112401';
final _chart = (_index['packs'] as List).firstWhere(
  (p) => p['id'] == 'watsonville-test-charts',
);

/// Serves [files] by URL path at once, as checked downloads, and remembers
/// what it was asked.
class _FakeDownloader implements PackDownloader {
  _FakeDownloader(this.files, this.dir);

  final Map<String, Uint8List> files;
  final Directory dir;
  final started = <DownloadItem>[];
  final _updates = StreamController<PackDownload>.broadcast(sync: true);
  final _latest = <String, PackDownload>{};

  void _emit(PackDownload d) {
    _latest[d.id] = d;
    _updates.add(d);
  }

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => _latest.values.toList();

  @override
  Future<void> start(DownloadItem item) async {
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

/// A gzipped bundle of the Monterey fixture's two tiles.
Uint8List _bundle() {
  final tar = BytesBuilder();
  for (final name in ['506_232.wrm', '507_232.wrm']) {
    final data = gzip.decode(
      File('packages/traxwater/test/fixture/monterey/$name.gz')
          .readAsBytesSync(),
    );
    final size = data.length.toRadixString(8).padLeft(11, '0');
    tar
      ..add(
        Uint8List(512)
          ..setAll(0, ascii.encode(name))
          ..setAll(124, ascii.encode('$size\u0000'))
          ..[156] = 0x30,
      )
      ..add(data)
      ..add(Uint8List((512 - data.length % 512) % 512));
  }
  tar.add(Uint8List(1024));
  return Uint8List.fromList(gzip.encode(tar.takeBytes()));
}

void main() {
  late Directory tmp;
  late Map<String, Uint8List> files;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('water_routing');
    files = {};
  });
  tearDown(() => tmp.delete(recursive: true));

  /// The catalogue's water routing, its area built from [chartsSha256].
  Map<String, Object> waterRouting(String chartsSha256) {
    const path = 'water-routing/wrm-2/$_build/test/watsonville-test.tar.gz';
    final bytes = files[path] = _bundle();
    return {
      'wrm-2': {
        'build': _build,
        'regions': {
          _area: {
            'url': path,
            'bytes': bytes.length,
            'unpacked_bytes': 2048,
            'sha256': sha256.convert(bytes).toString(),
            'charts_sha256': chartsSha256,
            'attribution': 'NOAA Office of Coast Survey',
            'notice': 'Not for navigation.',
          },
        },
      },
    };
  }

  Future<(WaterRoutingService, _FakeDownloader)> services(
    Map<String, Object> water,
  ) async {
    final client = MockClient((request) async {
      final path = request.url.path.substring(1);
      if (path == 'index.json') {
        return http.Response.bytes(
          utf8.encode(jsonEncode({..._index, 'water_routing': water})),
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
    return (WaterRoutingService.create(maps), downloader);
  }

  test('routing downloads with its chart, installs, and routes', () async {
    final (service, downloader) = await services(
      waterRouting(_chart['sha256'] as String),
    );
    expect(service.rebuilding(_area), isFalse);
    expect(service.chartFor(_area)!.id, _chart['id']);

    await service.download({_area});
    await service.idle;
    expect(downloader.started.map((d) => d.id), [
      _chart['id'],
      WaterRoutingService.downloadId(_area),
    ]);
    expect(service.installedRegions, {_area});
    expect(service.notices, ['Not for navigation.']);
    expect(
      downloader.downloads
          .firstWhere((d) => d.id == WaterRoutingService.downloadId(_area))
          .state,
      PackDownloadState.installed,
    );

    // Monterey to Moss Landing, as the fixture's first trip.
    final trip = await service.route(
      (lat: 36.605, lon: -121.8915),
      (lat: 36.8045, lon: -121.7915),
    );
    expect(trip.endsShort, isNull);
    expect(trip.distanceM, greaterThan(20000));

    // San Francisco Bay, off the tiles on the device.
    await expectLater(
      service.route(
        (lat: 37.8590, lon: -122.4783),
        (lat: 37.7935, lon: -122.2775),
      ),
      throwsA(
        isA<WaterRoutingException>().having(
          (e) => e.problem,
          'problem',
          WaterRoutingProblem.noTiles,
        ),
      ),
    );
  });

  test('routing built from another chart is being rebuilt', () async {
    final (service, downloader) = await services(waterRouting('f' * 64));
    expect(service.rebuilding(_area), isTrue);
    expect(service.chartFor(_area), isNull);
    expect(service.downloadsFor({_area}), isEmpty);
    await service.download({_area});
    expect(downloader.started, isEmpty);
  });
}
