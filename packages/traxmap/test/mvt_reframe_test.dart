import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/mvt_reframe.dart';

import 'support/mvt.dart';

void main() {
  test('a point lands in the child tile at the same scale', () {
    final tile = encodeMvt({
      'place': [
        (id: 7, type: 1, points: [(3000, 1000)]),
      ],
    }, extent: 4096);
    final place = decodeMvt(reframeMvt(tile, 1, 1, 0))['place']!;
    expect(place.extent, 2048);
    expect(place.features.single.points, [(952, 1000)]);
  });

  test('only the first point moves; the rest follow', () {
    final tile = encodeMvt({
      'water': [
        (id: 1, type: 3, points: [(100, 1100), (150, 1100), (150, 1150)]),
      ],
      'transportation': [
        (id: 2, type: 2, points: [(-64, 1100), (4160, 1300)]),
      ],
    });
    final out = decodeMvt(reframeMvt(tile, 2, 0, 1));
    expect(out['water']!.extent, 1024, reason: 'from the default 4096');
    expect(out['water']!.features.single.points, [
      (100, 76),
      (150, 76),
      (150, 126),
    ]);
    expect(out['transportation']!.features.single.points, [
      (-64, 76),
      (4160, 276),
    ]);
  });

  test('features that miss the tile are left out', () {
    // The child is the parent's top-left quarter: 0-2048 in parent units,
    // plus an eighth of it (256) either side.
    final tile = encodeMvt({
      'place': [
        (id: 1, type: 1, points: [(2200, 100)]),
        (id: 2, type: 1, points: [(2400, 100)]),
      ],
      'water': [
        (id: 3, type: 3, points: [(-100, -100), (4200, -100), (4200, 4200)]),
        (id: 4, type: 3, points: [(3000, 3000), (3500, 3000), (3500, 3500)]),
      ],
    });
    final out = decodeMvt(reframeMvt(tile, 1, 0, 0));
    expect(out['place']!.features.map((f) => f.id), [1]);
    expect(out['water']!.features.map((f) => f.id), [
      3,
    ], reason: 'the sea across the whole tile stays');
  });

  test('ids, tags, keys and values are kept', () {
    final tile = encodeMvt({
      'place': [
        (id: 42, type: 1, points: [(10, 10)]),
      ],
    });
    final place = decodeMvt(reframeMvt(tile, 3, 0, 0))['place']!;
    expect(place.keys, ['class']);
    expect(place.features.single.id, 42);
    expect(place.features.single.tags, [0, 0]);
    expect(place.features.single.points, [(10, 10)]);
    expect(place.extent, 512);
  });
}
