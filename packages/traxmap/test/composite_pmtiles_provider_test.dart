import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/composite_pmtiles_provider.dart';
import 'package:traxmap/src/renderer/flutter_map_renderer.dart';

import 'support/fake_pmtiles.dart';

/// Two neighbouring "regions": A has tiles 10/1/1 and 10/1/2; B has 10/2/2
/// and its own copy of the shared border tile 10/1/2.
void main() {
  late Directory tmp;
  late File a;
  late File b;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('composite');
    a = File('${tmp.path}/a.pmtiles')
      ..writeAsBytesSync(
        fakePmTiles(
          minZoom: 6,
          maxZoom: 13,
          tiles: {
            (10, 1, 1): [1],
            (10, 1, 2): [12],
          },
        ),
      );
    b = File('${tmp.path}/b.pmtiles')
      ..writeAsBytesSync(
        fakePmTiles(
          minZoom: 6,
          maxZoom: 14,
          tiles: {
            (10, 2, 2): [2],
            (10, 1, 2): [99],
          },
        ),
      );
  });
  tearDown(() => tmp.delete(recursive: true));

  List<int>? bytesOf(vt.TileResponse r) =>
      r is vt.TileResponseData ? r.bytes.toList() : null;

  test('each tile comes from the first pack that has it', () async {
    final provider = await CompositePmTilesProvider.open([a, b]);
    addTearDown(provider.dispose);
    expect(bytesOf(await provider.load(const vt.TileKey(10, 1, 1))), [1]);
    expect(bytesOf(await provider.load(const vt.TileKey(10, 2, 2))), [2]);
    expect(bytesOf(await provider.load(const vt.TileKey(10, 1, 2))), [
      12,
    ], reason: 'the shared tile from the preferred pack');
    expect(
      await provider.load(const vt.TileKey(10, 3, 3)),
      isA<vt.TileResponseNotFound>(),
    );
    expect(provider.minimumZoom, 6);
    expect(provider.maximumZoom, 14);
    expect(provider.cacheBytesToDisk, isFalse);
  });

  test('contains asks every pack', () async {
    final provider = await CompositePmTilesProvider.open([a, b]);
    addTearDown(provider.dispose);
    expect(await provider.contains(const vt.TileKey(10, 1, 1)), isTrue);
    expect(await provider.contains(const vt.TileKey(10, 2, 2)), isTrue);
    expect(await provider.contains(const vt.TileKey(10, 3, 3)), isFalse);
  });

  test('the cache key changes when a pack file is replaced', () async {
    final before = await CompositePmTilesProvider.open([a, b]);
    final key = before.cacheKey;
    before.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    b.writeAsBytesSync(
      fakePmTiles(
        tiles: {
          (10, 2, 2): [2, 2],
        },
      ),
    );
    final after = await CompositePmTilesProvider.open([a, b]);
    addTearDown(after.dispose);
    expect(after.cacheKey, isNot(key));
    expect(bytesOf(await after.load(const vt.TileKey(10, 2, 2))), [2, 2]);
  });

  test('tile coverage maps web tiles onto the packs\' zooms', () async {
    final pack = File('${tmp.path}/c.pmtiles')
      ..writeAsBytesSync(
        fakePmTiles(
          minZoom: 6,
          maxZoom: 14,
          tiles: {
            (6, 10, 24): [1],
            (14, 2650, 6300): [1],
          },
        ),
      );
    final provider = await CompositePmTilesProvider.open([pack]);
    addTearDown(provider.dispose);
    final coverage = TileCoverage([provider]);

    // Web tiles are one level above the packs' MapLibre zooms.
    expect(await coverage.covers(7, 20, 48), isTrue);
    expect(await coverage.covers(7, 21, 49), isTrue);
    expect(await coverage.covers(7, 22, 48), isFalse);
    expect(await coverage.covers(7, 20 + 128, 48), isTrue, reason: 'wrapped');
    expect(
      await coverage.covers(6, 10, 24),
      isFalse,
      reason: 'below the lowest zoom the pack draws nothing',
    );
    expect(
      await coverage.covers(17, 2650 * 8 + 3, 6300 * 8 + 5),
      isTrue,
      reason: 'above the highest zoom its top tiles are stretched',
    );
    expect(await const TileCoverage([]).covers(7, 20, 48), isFalse);
  });
}
