import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
final _chartAreas = File('packages/traxmap/test/support/chart_areas.geojson')
    .readAsStringSync();
final _chartsIndex = File('packages/traxmap/test/support/charts_index.json')
    .readAsStringSync();

const _ri = 'north-america/us/rhode-island';

class _FakeDownloader implements PackDownloader {
  final _updates = StreamController<PackDownload>.broadcast();
  final started = <String>[];
  final startedWith = <PackIndexEntry>[];
  final cancelled = <String>[];

  void emit(PackDownload d) => _updates.add(d);

  @override
  Stream<PackDownload> get updates => _updates.stream;
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {
    started.add(entry.id);
    startedWith.add(entry);
  }

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

  MapPacksService service({StyleRegistry? styles}) => MapPacksService(
    manager: PackManager(Directory('${tmp.path}/maps/packs')),
    downloader: downloader,
    cacheDir: Directory('${tmp.path}/maps'),
    indexUrl: Uri.parse('https://maps.example/dev/index.json'),
    client: MockClient((request) async {
      requests.add(request);
      final route = routes[request.url.path];
      return route == null ? http.Response('', 404) : route(request);
    }),
    styles: styles,
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
      '/dev/chart_areas.geojson': (_) => http.Response.bytes(
        utf8.encode(_chartAreas),
        200,
        headers: {'etag': '"c1"'},
      ),
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
      expect(maps.chartAreas!.areas, hasLength(42));
      expect(requests.map((r) => r.url.path), [
        '/dev/index.json',
        '/dev/picker.geojson',
        '/dev/chart_areas.geojson',
      ]);
      expect(requests.first.headers['If-None-Match'], isNull);

      // A second refresh sends the ETags and keeps the cache on 304.
      routes = {
        for (final path in [
          '/dev/index.json',
          '/dev/picker.geojson',
          '/dev/chart_areas.geojson',
        ])
          path: (_) => http.Response('', 304),
      };
      requests.clear();
      await maps.refresh();
      expect(requests.map((r) => r.headers['If-None-Match']), [
        '"i1"',
        '"p1"',
        '"c1"',
      ]);
      expect(maps.status, CatalogueStatus.ready);
      expect(maps.index!.packs, hasLength(9));
      expect(maps.chartAreas!.areas, hasLength(42));

      // A new service starts from the cache, with no network.
      final again = service();
      await again.start();
      expect(again.status, CatalogueStatus.ready);
      expect(again.regions!['north-america/us/rhode-island'], isNotNull);
    },
  );

  test(
    'reads the catalogue as UTF-8 when the server names no charset',
    () async {
      // The server writes ASCII with \u escapes and names charset=utf-8
      // (FINDINGS §1.1), but it once sent raw UTF-8 with no charset (e.g.
      // the en dash in "Watsonville – Monterey"), and that must still work.
      final picker = _picker.replaceAll(r'\u2013', '–');
      expect(picker, contains('Watsonville – Monterey'));
      routes['/dev/picker.geojson'] = (_) => http.Response.bytes(
        utf8.encode(picker),
        200,
        headers: {'content-type': 'application/geo+json', 'etag': '"p1"'},
      );
      final maps = service();
      await maps.start();
      await maps.refresh();
      expect(
        maps.regions!['test/watsonville-test']!.name,
        'Watsonville – Monterey (test)',
      );

      // And the cache keeps the bytes, so a 304 later reads them back intact.
      final again = service();
      await again.start();
      expect(
        again.regions!['test/watsonville-test']!.name,
        'Watsonville – Monterey (test)',
      );
    },
  );

  group('chart areas', () {
    test('the catalogue reads as ready only once they are in', () async {
      late MapPacksService maps;
      CatalogueStatus? during;
      routes['/dev/chart_areas.geojson'] = (_) {
        during = maps.status;
        return http.Response.bytes(utf8.encode(_chartAreas), 200);
      };
      maps = service();
      await maps.start();
      await maps.refresh();
      expect(during, CatalogueStatus.loading);
      expect(maps.status, CatalogueStatus.ready);
      expect(maps.chartAreas, isNotNull);
    });

    test('none published (404): the catalogue is still ready', () async {
      routes.remove('/dev/chart_areas.geojson');
      final maps = service();
      await maps.start();
      await maps.refresh();
      expect(maps.status, CatalogueStatus.ready);
      expect(maps.chartAreas, isNull);
      expect(maps.chartAreasError, isNull);
      expect(maps.regions, isNotNull);
    });

    test(
      'a failure keeps the last chart areas and leaves Maps alone',
      () async {
        final maps = service();
        await maps.start();
        await maps.refresh();
        final fetchedAt = maps.fetchedAt;
        routes['/dev/chart_areas.geojson'] = (_) => http.Response('', 500);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await maps.refresh();
        expect(maps.status, CatalogueStatus.ready);
        expect(maps.error, isNull);
        expect(maps.fetchedAt, isNot(fetchedAt));
        expect(maps.chartAreasError, contains('500'));
        expect(maps.chartAreas!.areas, hasLength(42));

        routes['/dev/chart_areas.geojson'] = (_) => http.Response('', 304);
        await maps.refresh();
        expect(maps.chartAreasError, isNull);
      },
    );

    test(
      'the cache brings them back even if the picker cache is bad',
      () async {
        final maps = service();
        await maps.start();
        await maps.refresh();
        File('${tmp.path}/maps/picker.geojson').writeAsStringSync('{broken');
        routes = {'/dev/index.json': (_) => http.Response('', 500)};
        final again = service();
        await again.start();
        expect(again.regions, isNull);
        expect(again.chartAreas!.areas, hasLength(42));
        expect(again.chartAreasFetchedAt, isNotNull);
      },
    );

    test('read as UTF-8 when the server names no charset', () async {
      routes['/dev/chart_areas.geojson'] = (_) => http.Response.bytes(
        utf8.encode(_chartAreas.replaceFirst('"Haiti"', '"Haïti"')),
        200,
        headers: {'content-type': 'application/geo+json'},
      );
      final maps = service();
      await maps.start();
      await maps.refresh();
      expect(maps.chartAreas!.areas.map((a) => a.name), contains('Haïti'));
    });

    test('each area pairs with its charts pack by region', () async {
      routes['/dev/index.json'] = (_) =>
          http.Response.bytes(utf8.encode(_chartsIndex), 200);
      final maps = service();
      await maps.start();
      await maps.refresh();
      expect(maps.chartPackOf('charts/us/florida')!.id, 'charts-us-fl-charts');
      expect(maps.chartPackOf(_ri), isNull, reason: 'a street map region');
      for (final area in maps.chartAreas!.areas) {
        expect(maps.chartPackOf(area.packRegion), isNotNull, reason: area.id);
      }
    });
  });

  test(
    'downloaded areas: what each map draws, by region or chart area',
    () async {
      final maps = service(
        styles: StyleRegistry(
          DirectoryStyleSource(Directory('packages/traxmap/assets/styles')),
        ),
      );
      await maps.start();
      await maps.refresh();
      // Which pack kinds each map needs comes from the bundled styles.
      final styled = Completer<void>();
      maps.addListener(() {
        if (!styled.isCompleted &&
            maps.styleId(MapType.charts, dark: false) != null) {
          styled.complete();
        }
      });
      maps.styleId(MapType.osm, dark: false);
      await styled.future;

      Future<void> add(String id, String kind, String region) async {
        await maps.manager.root.create(recursive: true);
        File('${maps.manager.root.path}/$id.pmtiles').writeAsBytesSync(
          fakePmTiles(metadata: {'kind': kind, 'region': region}),
        );
        await maps.reloadInstalled();
      }

      await add('us-rhode-island-osm', 'osm', _ri);
      await add('us-ri-contours-20ft', 'contours', _ri);
      await add('charts-us-ri-charts', 'charts', 'charts/us/rhode-island');
      final chartArea = maps.chartAreas!.areas.firstWhere(
        (a) => a.packRegion == 'charts/us/rhode-island',
      );
      expect(maps.downloadedAreas(MapType.osm), {
        _ri: maps.regions![_ri]!.polygons,
      });
      expect(maps.downloadedAreas(MapType.charts), {
        'charts/us/rhode-island': chartArea.polygons,
      });
      expect(maps.downloadedAreas(MapType.usgs), isEmpty, reason: 'no topo');

      await add('us-rhode-island', 'base', _ri);
      expect(maps.downloadedAreas(MapType.usgs).keys, [_ri]);
    },
  );

  test('the maps folder stays out of iOS and macOS backups', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('meshtrax/storage');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add('${call.method} ${call.arguments}');
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final dir = Directory('${tmp.path}/maps');
    try {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        await MapPacksService.keepOutOfBackups(dir);
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    expect(calls, [
      'excludeFromBackup ${dir.path}',
      'excludeFromBackup ${dir.path}',
    ], reason: 'iOS and macOS only');
    expect(dir.existsSync(), isTrue);
  });

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

  test('default selection adds hill shading where a region has it', () async {
    final index = jsonDecode(_index) as Map<String, Object?>;
    final packs = (index['packs']! as List).cast<Map<String, Object?>>();
    final usgs = packs.firstWhere((p) => p['id'] == 'us-rhode-island');
    packs.add({
      ...usgs,
      'id': 'us-rhode-island-terrain',
      'name': 'Rhode Island (terrain)',
      'kind': 'terrain',
      'sha256': '0' * 64,
      'url': 'https://maps.example/dev/v1/north-america/us/rhode-island/terrain.pmtiles',
    });
    routes['/dev/index.json'] = (_) =>
        http.Response.bytes(utf8.encode(jsonEncode(index)), 200);
    final maps = service();
    await maps.start();
    await maps.refresh();
    expect(maps.defaultSelection(_ri, UnitSystem.imperial).map((e) => e.id), [
      'us-rhode-island-osm',
      'us-rhode-island-contours-20ft',
      'us-rhode-island-terrain',
    ]);
  });

  test('the map leaves hill shading out when it is switched off', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    await install(maps, 'us-rhode-island-osm');
    final terrain = File('${tmp.path}/terrain.src')
      ..writeAsBytesSync(
        fakePmTiles(metadata: {'kind': 'terrain', 'region': _ri}),
      );
    await maps.manager.install(terrain, id: 'us-rhode-island-terrain');
    await maps.reloadInstalled();
    List<String> kinds({required bool hillShading}) => [
      for (final p in maps.mapPacks(
        contours: true,
        hillShading: hillShading,
        world: true,
      ))
        p.kind.name,
    ];
    expect(kinds(hillShading: true), containsAll(['osm', 'terrain']));
    expect(kinds(hillShading: false), ['osm']);
  });

  test('offline maps draw the bundled world map', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final maps = service();
    await maps.start();
    await maps.openWorld();
    expect(maps.world?.kind, PackKind.world);
    List<PackKind> kinds({required bool world}) => [
      for (final p in maps.mapPacks(
        contours: true,
        hillShading: true,
        world: world,
      ))
        p.kind,
    ];
    expect(kinds(world: true), [PackKind.world]);
    expect(kinds(world: false), isEmpty, reason: 'online tiles show it');
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

  test(
    'a finished download goes straight from checking to installed',
    () async {
      final maps = service();
      await maps.start();
      await maps.refresh();
      final osm = maps.index!.packs.firstWhere(
        (e) => e.id == 'us-rhode-island-osm',
      );
      await maps.download([osm]);
      downloader.emit(PackDownload(osm, PackDownloadState.verifying));
      await pumpEventQueue();
      final seen = <PackStatus>[];
      maps.addListener(() => seen.add(maps.statusOf(osm)));

      await install(maps, osm.id);
      downloader.emit(PackDownload(osm, PackDownloadState.installed));
      for (var i = 0; i < 50 && !seen.contains(PackStatus.installed); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(maps.statusOf(osm), PackStatus.installed);
      expect(seen.toSet(), {PackStatus.verifying, PackStatus.installed});
    },
  );

  group('a pack republished during its download', () {
    late MapPacksService maps;
    late PackIndexEntry current, old;

    setUp(() async {
      maps = service();
      await maps.start();
      await maps.refresh();
      current = maps.index!.packs.firstWhere(
        (e) => e.id == 'us-rhode-island-osm',
      );
      // The entry the download began with, before the publish.
      old = PackIndexEntry.fromJson({...current.toJson(), 'sha256': 'ab' * 32});
    });

    Future<void> rejected(PackIndexEntry entry) async {
      downloader.emit(PackDownload(entry, PackDownloadState.verifying));
      await pumpEventQueue();
      downloader.emit(
        PackDownload(entry, PackDownloadState.failed, error: 'Checksum'),
      );
      await pumpEventQueue();
      // The catalogue fetch reads and writes its cache on disk.
      while (maps.status == CatalogueStatus.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await pumpEventQueue();
    }

    test('Retry downloads the current build', () async {
      downloader.emit(PackDownload(old, PackDownloadState.failed));
      await pumpEventQueue();
      await maps.resume(old.id);
      expect(downloader.cancelled, [old.id], reason: 'the failed record');
      expect(downloader.startedWith.single.sha256, current.sha256);
    });

    test(
      'a rejected download fetches the catalogue and starts the new build',
      () async {
        requests.clear();
        await rejected(old);
        expect(requests.map((r) => r.url.path), contains('/dev/index.json'));
        expect(downloader.startedWith.single.sha256, current.sha256);
      },
    );

    test('a rejected download of the current build waits for Retry', () async {
      requests.clear();
      await rejected(current);
      expect(requests.map((r) => r.url.path), contains('/dev/index.json'));
      expect(downloader.started, isEmpty);
      expect(maps.statusOf(current), PackStatus.failed);
    });
  });

  test('with nothing else to show, maps open on the latest map pack', () async {
    final maps = service();
    await maps.start();
    await maps.refresh();
    expect(maps.latestMapFit, isNull);

    await install(maps, 'us-rhode-island-contours-10m');
    await maps.reloadInstalled();
    expect(maps.latestMapFit, isNull, reason: 'contours alone are no map');

    await install(maps, 'us-rhode-island-osm');
    await maps.reloadInstalled();
    final fit = maps.latestMapFit!;
    final pack = maps.installedPack('us-rhode-island-osm')!;
    expect(fit.bounds, pack.bounds);
    expect(fit.minZoom, pack.minZoom);
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
