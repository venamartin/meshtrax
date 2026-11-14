import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/poi_service.dart';
import 'package:traxmap/traxmap.dart';

final _index = jsonDecode(
  File('packages/traxmap/test/support/sample_index.json').readAsStringSync(),
) as Map<String, dynamic>;

/// Stands in for the background downloader: serves [files] by URL path at
/// once, as checked downloads, and remembers what it was asked.
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
  Future<void> cancel(String id) async {}
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

void main() {
  late Directory tmp;
  late Map<String, Object> catalogue;
  late Map<String, Uint8List> files;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('poi');
    files = {};
  });
  tearDown(() => tmp.delete(recursive: true));

  const path = 'poi/2026110601/test/a/points.sqlite.gz';

  /// The catalogue's poi entry with one region's points file, [body]
  /// gzipped, which the server then holds.
  void points(List<int> body) {
    final gz = files[path] = Uint8List.fromList(gzip.encode(body));
    catalogue = {
      'schema_version': 1,
      'build': '2026110601',
      'regions': {
        'test/a': {
          'points': {
            'url': path,
            'bytes': gz.length,
            'unpacked_bytes': body.length,
            'sha256': sha256.convert(gz).toString(),
          },
        },
      },
    };
  }

  Future<(PoiService, _FakeDownloader)> services() async {
    final client = MockClient((request) async {
      final path = request.url.path.substring(1);
      if (path == 'index.json') {
        return http.Response.bytes(
          utf8.encode(jsonEncode({..._index, 'poi': catalogue})),
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
    return (await PoiService.create(maps), downloader);
  }

  List<FileSystemEntity> leftovers() =>
      Directory('${tmp.path}/downloads').listSync();

  Object? manifest() =>
      jsonDecode(File('${tmp.path}/maps/poi/manifest.json').readAsStringSync());

  test(
    'a places file downloads through the map downloader and installs',
    () async {
      final body = utf8.encode('SQLite format 3 stand-in');
      points(body);
      final (service, downloader) = await services();
      expect(service.fileFor('test/a', PoiDownload.points), isNotNull);

      await service.download('test/a', {PoiDownload.points});
      final item = downloader.started.single as DownloadFile;
      expect(item.id, PoiService.downloadId('test/a', PoiDownload.points));
      expect(item.kind, PoiService.pointsKind);
      expect(item.region, 'test/a');
      expect(item.payload['build'], '2026110601');
      await service.idle;

      expect(service.isInstalled('test/a', PoiDownload.points), isTrue);
      expect(service.installedRegions, {'test/a'});
      expect(service.regionFor('test/a'), isNotNull);
      expect(
        File('${tmp.path}/maps/poi/test_a/points-of-interest.sqlite')
            .readAsBytesSync(),
        body,
      );
      expect(service.updateAvailable('test/a', PoiDownload.points), isFalse);
      expect(downloader.latest(item.id)!.state, PackDownloadState.installed);
      expect(leftovers(), isEmpty);
      expect(manifest(), {
        'test/a': {
          'points': sha256.convert(files[path]!).toString(),
          'pointsBuild': '2026110601',
        },
      });
    },
  );

  test('removing a file forgets its checksum and build', () async {
    points(utf8.encode('fine'));
    final (service, _) = await services();
    await service.download('test/a', {PoiDownload.points});
    await service.idle;

    await service.remove('test/a');
    expect(service.installedRegions, isEmpty);
    expect(manifest(), isEmpty);
  });

  test('a manifest written before builds were recorded still reads', () async {
    points(utf8.encode('fine'));
    final sum = sha256.convert(files[path]!).toString();
    File('${tmp.path}/maps/poi/manifest.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'test/a': {'points': sum},
        }),
      );
    File('${tmp.path}/maps/poi/test_a/points-of-interest.sqlite')
      ..createSync(recursive: true)
      ..writeAsStringSync('fine');
    final (service, _) = await services();

    expect(service.isInstalled('test/a', PoiDownload.points), isTrue);
    expect(service.updateAvailable('test/a', PoiDownload.points), isFalse);
  });

  test(
    'a file that will not unpack is reported, and its file removed',
    () async {
      points(utf8.encode('fine'));
      files[path] = Uint8List.fromList(utf8.encode('not gzip'));
      final (service, downloader) = await services();

      await service.download('test/a', {PoiDownload.points});
      await service.idle;

      final id = PoiService.downloadId('test/a', PoiDownload.points);
      expect(downloader.latest(id)!.state, PackDownloadState.failed);
      expect(service.isInstalled('test/a', PoiDownload.points), isFalse);
      expect(leftovers(), isEmpty);
    },
  );
}
