import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxwater/src/mesh.dart';
import 'package:traxwater/traxwater.dart';

import 'support/fixture.dart';

void main() {
  final set = FixtureSet('antimeridian');

  test('joins tiles across the 180° meridian', () {
    // From 179.75° E to 179.75° W: tile 1439, then tile 0 east of it.
    final mesh = WaterMesh.load(179.75, 51.3, 180.25, 51.5, set.tile);
    expect(mesh.tileCount, 2);
    final east = set.tile(1439, 565)!.triangleCount;
    var across = 0;
    for (var t = 0; t < east; t++) {
      for (var j = mesh.linkStart[t]; j < mesh.linkStart[t + 1]; j++) {
        if (mesh.linkTo[j] >= east) across++;
      }
    }
    expect(across, greaterThan(0));
    expect(mesh.toLatLon(0, 0).lon.abs(), closeTo(180, 1e-9));
  });

  test('refuses tiles of two builds', () {
    final other = WaterTile.parse(
      Uint8List.fromList(
        tileBytes('antimeridian', 0, 565)
          ..setRange(26, 36, '2026112402'.codeUnits),
      ),
    );
    expect(
      () => WaterMesh.load(
        179.75,
        51.3,
        180.25,
        51.5,
        (ix, iy) => ix == 0 ? other : set.tile(ix, iy),
      ),
      throwsA(
        isA<WaterRoutingException>().having(
          (e) => e.problem,
          'problem',
          WaterRoutingProblem.mixedBuilds,
        ),
      ),
    );
  });
}
