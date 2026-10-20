import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

import 'support/fake_pmtiles.dart';

void main() {
  late Directory tmp;
  late PackManager manager;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ovm');
    manager = PackManager(Directory('${tmp.path}/packs'));
  });
  tearDown(() => tmp.delete(recursive: true));

  File source(String name, {Map<String, Object?> metadata = const {}}) =>
      File('${tmp.path}/$name')
        ..writeAsBytesSync(fakePmTiles(metadata: metadata));

  test(
    'install with move renames the download, and deletes a bad one',
    () async {
      // A download lands in the pack directory itself, next to the packs.
      await manager.root.create(recursive: true);
      final good = File('${manager.root.path}/r.pmtiles.download')
        ..writeAsBytesSync(fakePmTiles(metadata: {'kind': 'osm'}));
      final sum = sha256.convert(good.readAsBytesSync()).toString();
      final pack = await manager.install(
        good,
        id: 'r',
        sha256: sum,
        move: true,
      );
      expect(pack.kind, PackKind.osm);
      expect(good.existsSync(), isFalse);
      expect((await manager.listInstalled()).map((p) => p.id), ['r']);

      final bad = File('${manager.root.path}/s.pmtiles.download')
        ..writeAsBytesSync(fakePmTiles());
      await expectLater(
        manager.install(bad, id: 's', sha256: '0' * 64, move: true),
        throwsA(isA<PackException>()),
      );
      expect(bad.existsSync(), isFalse);
      expect((await manager.listInstalled()).map((p) => p.id), ['r']);
    },
  );

  test('a pack installed with a checksum is named by its build', () async {
    final src = source(
      'ri.pmtiles',
      metadata: {
        'kind': 'osm',
        'region': 'north-america/us/rhode-island',
        'build_date': '2026-10-19',
      },
    );
    final sum = sha256.convert(src.readAsBytesSync()).toString();
    final pack = await manager.install(src, id: 'us-ri-osm', sha256: sum);
    expect(pack.id, 'us-ri-osm');
    expect(pack.sha256Prefix, sum.substring(0, 12));
    expect(
      pack.file.path,
      endsWith('us-ri-osm@${sum.substring(0, 12)}.pmtiles'),
    );
    expect(pack.isBuild(sum.toUpperCase()), isTrue);
    expect(pack.isBuild('f' * 64), isFalse);
    expect(pack.region, 'north-america/us/rhode-island');
    expect(pack.buildDate, DateTime(2026, 10, 19));

    final unversioned = await manager.install(source('plain.pmtiles'));
    expect(unversioned.sha256Prefix, isNull);
    expect(unversioned.isBuild(sum), isNull);
  });

  test('an update replaces the old build, and only that pack', () async {
    final v1 = source('v1.pmtiles', metadata: {'build_date': '2026-10-01'});
    final v2 = source('v2.pmtiles', metadata: {'build_date': '2026-10-19'});
    final other = source('o.pmtiles');
    await manager.install(other, id: 'r-osm');
    final old = await manager.install(
      v1,
      id: 'r',
      sha256: sha256.convert(v1.readAsBytesSync()).toString(),
    );
    final sum2 = sha256.convert(v2.readAsBytesSync()).toString();
    final fresh = await manager.install(v2, id: 'r', sha256: sum2);
    expect(old.file.existsSync(), isFalse);
    expect(fresh.file.path, isNot(old.file.path));
    final installed = await manager.listInstalled();
    expect(installed.map((p) => p.id), ['r', 'r-osm']);
    expect(installed.first.isBuild(sum2), isTrue);
  });

  test(
    'listInstalled keeps the newest build when an old one is left',
    () async {
      await manager.root.create(recursive: true);
      final older = File('${manager.root.path}/r@aaaaaaaaaaaa.pmtiles')
        ..writeAsBytesSync(fakePmTiles(metadata: {'build_date': '2026-10-01'}));
      older.setLastModifiedSync(DateTime(2026, 10, 1));
      File(
        '${manager.root.path}/r@bbbbbbbbbbbb.pmtiles',
      ).writeAsBytesSync(fakePmTiles(metadata: {'build_date': '2026-10-19'}));
      final packs = await manager.listInstalled();
      expect(packs, hasLength(1));
      expect(packs.single.sha256Prefix, 'bbbbbbbbbbbb');
      expect(older.existsSync(), isFalse);
    },
  );

  test('rejects ids with a path separator or the build separator', () async {
    for (final id in ['a/b', r'a\b', 'a@b', '']) {
      await expectLater(
        manager.install(source('x.pmtiles'), id: id),
        throwsA(isA<PackException>()),
      );
    }
  });

  test('install, list, delete', () async {
    final pack = await manager.install(
      source(
        'watsonville-test.pmtiles',
        metadata: {
          'name': 'Watsonville',
          'kind': 'base',
          'vector_layers': [
            {'id': 'water'},
            {'id': 'contours'},
          ],
        },
      ),
    );
    expect(pack.id, 'watsonville-test');
    expect(pack.name, 'Watsonville');
    expect(pack.kind, PackKind.base);
    expect(pack.vectorLayers, ['water', 'contours']);
    expect(await manager.listInstalled(), hasLength(1));

    await manager.delete(pack);
    expect(await manager.listInstalled(), isEmpty);
  });

  test('contours variant and units come from metadata', () async {
    final pack = await manager.install(
      source(
        'x-contours-10m.pmtiles',
        metadata: {'kind': 'contours', 'variant': '10m', 'units': 'metric'},
      ),
    );
    expect(pack.kind, PackKind.contours);
    expect(pack.variant, '10m');
    expect(pack.units, Units.metric);
  });

  test('checksum is verified before the pack becomes active', () async {
    final src = source('a.pmtiles');
    final good = sha256.convert(src.readAsBytesSync()).toString();

    await expectLater(
      manager.install(src, sha256: '0' * 64),
      throwsA(isA<PackException>()),
    );
    expect(await manager.listInstalled(), isEmpty);
    expect(manager.root.listSync(), isEmpty, reason: 'no .part left behind');

    final pack = await manager.install(src, sha256: good.toUpperCase());
    expect(await manager.verify(pack, good), isTrue);
  });

  test('rejects files that are not PMTiles', () async {
    final junk = File('${tmp.path}/junk.pmtiles')..writeAsStringSync('x' * 200);
    await expectLater(manager.install(junk), throwsA(isA<PackException>()));
    expect(manager.root.listSync(), isEmpty);
  });

  test('listInstalled skips unreadable files', () async {
    await manager.install(source('ok.pmtiles'));
    File('${manager.root.path}/bad.pmtiles').writeAsStringSync('nope');
    final errors = <File>[];
    final packs = await manager.listInstalled(onError: (f, _) => errors.add(f));
    expect(packs.map((p) => p.id), ['ok']);
    expect(errors, hasLength(1));
  });

  test('bestFor prefers coverage, then newest build', () async {
    final old = await manager.install(
      source(
        'old.pmtiles',
        metadata: {'kind': 'base', 'build_date': '2026-01-01'},
      ),
    );
    final fresh = await manager.install(
      source(
        'new.pmtiles',
        metadata: {'kind': 'base', 'build_date': '2026-09-01'},
      ),
    );
    const viewport = LatLngBounds(
      south: 36.8,
      west: -121.9,
      north: 36.9,
      east: -121.8,
    );
    expect(PackManager.bestFor(viewport, [old, fresh]), fresh);
    expect(
      PackManager.bestFor(viewport, [old, fresh], kind: PackKind.charts),
      isNull,
    );
    const away = LatLngBounds(south: 40, west: -110, north: 41, east: -109);
    expect(PackManager.bestFor(away, [old, fresh]), isNull);
  });
}
