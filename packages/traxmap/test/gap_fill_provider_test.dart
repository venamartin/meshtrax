import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/composite_pmtiles_provider.dart';
import 'package:traxmap/src/renderer/gap_fill_provider.dart';

import 'support/fake_pmtiles.dart';
import 'support/mvt.dart';

/// A base map with data to z2 and a downloaded region from z2 to z3 that
/// has tile 2/2/1 and, deeper, only 3/2/2.
void main() {
  late Directory tmp;
  late CompositePmTilesProvider world;
  late CompositePmTilesProvider region;
  final town = encodeMvt({
    'place': [
      (id: 1, type: 1, points: [(3000, 3000)]),
    ],
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gap_fill');
    final worldFile = File('${tmp.path}/world.pmtiles')
      ..writeAsBytesSync(
        fakePmTiles(
          minZoom: 0,
          maxZoom: 2,
          tiles: {
            (1, 0, 0): [1],
            (2, 1, 1): town,
            (2, 2, 1): [21],
          },
        ),
      );
    final regionFile = File('${tmp.path}/region.pmtiles')
      ..writeAsBytesSync(
        fakePmTiles(
          minZoom: 2,
          maxZoom: 3,
          tiles: {
            (2, 2, 1): [9],
            (3, 2, 2): [9],
          },
        ),
      );
    world = await CompositePmTilesProvider.open([worldFile]);
    region = await CompositePmTilesProvider.open([regionFile]);
  });
  tearDown(() async {
    region.dispose();
    await tmp.delete(recursive: true);
  });

  Future<vt.TileResponse> load(GapFillProvider p, int z, int x, int y) =>
      p.load(vt.TileKey(z, x, y));

  test('below the region, the base map passes through', () async {
    final p = GapFillProvider(world, masks: [region]);
    addTearDown(p.dispose);
    expect(((await load(p, 1, 0, 0)) as vt.TileResponseData).bytes, [1]);
  });

  test('where the region has a tile, the base map has none', () async {
    final p = GapFillProvider(world, masks: [region]);
    addTearDown(p.dispose);
    expect(await load(p, 2, 2, 1), isA<vt.TileResponseNotFound>());
    expect(
      ((await load(p, 2, 1, 1)) as vt.TileResponseData).bytes,
      town,
      reason: 'beside it, the base map tile as it is',
    );
  });

  test('deeper than its data, tiles are reframed and masked', () async {
    final p = GapFillProvider(world, masks: [region]);
    addTearDown(p.dispose);
    expect(p.maximumZoom, 3);

    final child = (await load(p, 3, 3, 3)) as vt.TileResponseData;
    final place = decodeMvt(child.bytes)['place']!;
    expect(place.extent, 2048);
    expect(place.features.single.points, [(3000 - 2048, 3000 - 2048)]);

    expect(
      await load(p, 3, 2, 2),
      isA<vt.TileResponseNotFound>(),
      reason: "the region's own deeper tile",
    );
    expect(
      await load(p, 4, 4, 4),
      isA<vt.TileResponseNotFound>(),
      reason: "past the region's top zoom, its tile above decides",
    );
    final far = (await load(p, 4, 6, 6)) as vt.TileResponseData;
    expect(decodeMvt(far.bytes)['place']!.features.single.points, [
      (3000 - 2 * 1024, 3000 - 2 * 1024),
    ]);
  });

  test('without masks it is the base map alone', () async {
    final p = GapFillProvider(world, masks: const []);
    addTearDown(p.dispose);
    expect(p.maximumZoom, 2);
    expect(((await load(p, 2, 2, 1)) as vt.TileResponseData).bytes, [21]);
    final masked = GapFillProvider(world, masks: [region]);
    expect(masked.cacheKey, isNot(p.cacheKey));
  });

  test('disposing it leaves the masks open', () async {
    GapFillProvider(world, masks: [region]).dispose();
    expect(await region.contains(const vt.TileKey(2, 2, 1)), isTrue);
  });
}
