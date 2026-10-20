import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:traxmap/traxmap.dart';

import '../../packages/traxmap/test/support/fake_pmtiles.dart';

/// Real catalogue files from maps.meshtrax.io/dev (kept in traxmap's tests).
final _index = File('packages/traxmap/test/support/sample_index.json')
    .readAsStringSync();
final _picker = File('packages/traxmap/test/support/picker.geojson')
    .readAsStringSync();

const _ri = 'north-america/us/rhode-island';

class _FakeDownloader implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final started = <String>[];
  final cancelled = <String>[];

  void emit(PackDownload d) => _updates.add(d);

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async => started.add(entry.id);
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async => cancelled.add(packId);
}

void main() {
  late Directory tmp;
  late _FakeDownloader downloader;
  late List<http.Request> requests;
  late Map<String, http.Response Function(http.Request)> routes;

  MapPacksService service() => MapPacksService(
    manager: PackManager(Directory('${tmp.path}/maps/packs')),
    downloader: downloader,
    cacheDir: Directory('${tmp.path}/maps'),
    indexUrl: Uri.parse('https://maps.example/dev/index.json'),
    client: MockClient((request) async {
      requests.add(request);
      final route = routes[request.url.path];
      return route == null ? http.Response('', 404) : route(request);
    }),
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mappacks');
    downloader = _FakeDownloader();
    requests = [];
    routes = {
      '/dev/index.json': (_) =>
          http.Response(_index, 200, headers: {'etag': '"i1"'}),
      '/dev/picker.geojson': (_) =>
          http.Response(_picker, 200, headers: {'etag': '"p1"'}),
    };
  });
  tearDown(() => tmp.delete(recursive: true));

  /// Installs a fake pack built from index entry [id] (optionally an older
  /// build) through the real PackManager.
  Future<void> install(MapPacksService maps, String id, {bool old = false}) {
    final entry = maps.index!.packs.firstWhere((e) => e.id == id);
    final file = File('${tmp.path}/$id.src')
      ..writeAsBytesSync(
        fakePmTiles(
          metadata: {'kind': entry.kind.name, 'region': entry.region},
        ),
      );
    final sum = old
        ? sha256.convert(file.readAsBytesSync()).toString()
        : entry.sha256;
    return old
        ? maps.manager.install(file, id: id, sha256: sum)
        : maps.manager
              .install(file, id: id)
              .then(
                // Rename to the index's build so it counts as current.
                (pack) => pack.file.rename(
                  '${maps.manager.root.path}/$id@${entry.sha256.substring(0, 12)}.pmtiles',
                ),
              );
  }

  test(
    'fetches the catalogue, caches it, and revalidates with ETags',
    () async {
      final maps = service();
      await maps.start();
      expect(maps.status, CatalogueStatus.unknown);

      await maps.refresh();
      expect(maps.status, CatalogueStatus.ready);
      expect(maps.index!.packs, hasLength(9));
      expect(maps.regions!.attribution, contains('Geofabrik'));
      expect(requests.map((r) => r.url.path), [
        '/dev/index.json',
        '/dev/picker.geojson',
      ]);
      expect(requests.first.headers['If-None-Match'], isNull);

      // A second refresh sends the ETags and keeps the cache on 304.
      routes = {
        for (final path in ['/dev/index.json', '/dev/picker.geojson'])
          path: (_) => http.Response('', 304),
      };
      requests.clear();
      await maps.refresh();
      expect(requests.map((r) => r.headers['If-None-Match']), ['"i1"', '"p1"']);
      expect(maps.status, CatalogueStatus.ready);
      expect(maps.index!.packs, hasLength(9));

      // A new service starts from the cache, with no network.
      final again = service();
      await again.start();
      expect(again.status, CatalogueStatus.ready);
      expect(again.regions!['north-america/us/rhode-island'], isNotNull);
    },
  );

  test('a 404 index means no catalogue yet, not an error', () async {
    routes = {};
    final maps = service();
    await maps.start();
    await maps.refresh();
    expect(maps.status, CatalogueStatus.unavailable);
    expect(maps.error, isNull);
  });

  test('a network failure keeps the cached catalogue and reports it', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    routes = {'/dev/index.json': (_) => http.Response('', 500)};
    await maps.refresh();
    expect(maps.status, CatalogueStatus.error);
    expect(maps.error, contains('500'));
    expect(maps.index!.packs, hasLength(9));
  });

  test('default selection: the map and the contours for the units', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    expect(maps.defaultSelection(_ri, UnitSystem.imperial).map((e) => e.id), [
      'us-rhode-island-osm',
      'us-rhode-island-contours-20ft',
    ]);
    expect(
      maps.defaultSelection(_ri, UnitSystem.metric).last.id,
      'us-rhode-island-contours-10m',
    );
    expect(maps.packsForRegion(_ri), hasLength(4));
  });

  test('pack status follows downloads, installs and builds', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    final osm = maps.index!.packs.firstWhere(
      (e) => e.id == 'us-rhode-island-osm',
    );
    expect(maps.statusOf(osm), PackStatus.available);

    await maps.download([osm]);
    expect(downloader.started, ['us-rhode-island-osm']);
    downloader.emit(PackDownload(osm, PackDownloadState.running, progress: .4));
    await pumpEventQueue();
    expect(maps.statusOf(osm), PackStatus.running);
    expect(maps.downloadOf(osm.id)!.bytesDone, (.4 * osm.bytes).round());
    expect(maps.badgeCount, 1);

    await install(maps, osm.id);
    downloader.emit(PackDownload(osm, PackDownloadState.installed));
    await pumpEventQueue();
    await maps.reloadInstalled();
    expect(maps.statusOf(osm), PackStatus.installed);
    expect(maps.installedRegions, {_ri});
    expect(maps.badgeCount, 0);

    final usgs = maps.index!.packs.firstWhere((e) => e.id == 'us-rhode-island');
    await install(maps, usgs.id, old: true);
    await maps.reloadInstalled();
    expect(maps.statusOf(usgs), PackStatus.updateAvailable);
    expect(maps.updates.map((e) => e.id), ['us-rhode-island']);
    expect(maps.badgeCount, 1);
  });

  test('deleting a region cancels its downloads and frees its packs', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    final contours = maps.index!.packs.firstWhere(
      (e) => e.id == 'us-rhode-island-contours-20ft',
    );
    await install(maps, 'us-rhode-island-osm');
    await install(maps, 'watsonville-test-osm');
    downloader.emit(PackDownload(contours, PackDownloadState.running));
    await pumpEventQueue();
    await maps.reloadInstalled();

    final freed = await maps.deleteRegion(_ri);
    await maps.reloadInstalled();
    expect(freed, greaterThan(0));
    expect(downloader.cancelled, ['us-rhode-island-contours-20ft']);
    expect(maps.installed.map((p) => p.id), ['watsonville-test-osm']);
  });
}
