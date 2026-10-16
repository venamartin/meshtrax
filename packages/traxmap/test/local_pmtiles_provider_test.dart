import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/local_pmtiles_provider.dart';

void main() {
  final file = File('example/assets/packs/watsonville-test.pmtiles');
  final skip = file.existsSync()
      ? false
      : 'run pipeline/build.py --install-example';

  test('serves tiles from the local test pack', () async {
    final provider = await LocalPmTilesVectorTileProvider.open(file);
    addTearDown(provider.dispose);
    expect(provider.minimumZoom, 6);
    expect(provider.maximumZoom, 14);
    expect(provider.cacheBytesToDisk, isFalse);

    // z14 tile over Watsonville (36.91, -121.76).
    final hit = await provider.load(const vt.TileKey(14, 2650, 6382));
    expect(hit, isA<vt.TileResponseData>());
    final bytes = (hit as vt.TileResponseData).bytes;
    expect(bytes.sublist(0, 2), [0x1f, 0x8b], reason: 'gzip passes through');

    // Concurrent reads share one file handle without tripping over each other.
    final many = await Future.wait([
      for (var x = 2646; x < 2654; x++) provider.load(vt.TileKey(14, x, 6382)),
    ]);
    expect(many.whereType<vt.TileResponseData>(), hasLength(8));

    // Outside the pack, and above its max zoom.
    expect(
      await provider.load(const vt.TileKey(14, 0, 0)),
      isA<vt.TileResponseNotFound>(),
    );
    expect(
      await provider.load(const vt.TileKey(15, 5300, 12764)),
      isA<vt.TileResponseNotFound>(),
    );
  }, skip: skip);
}
