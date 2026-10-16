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
