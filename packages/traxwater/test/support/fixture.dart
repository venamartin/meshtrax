import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:traxwater/traxwater.dart';

/// A set of the engine fixture (test/fixture/README.md): tiles cut from a
/// water-routing build, and the builder's test router's trips over them.
class FixtureSet {
  FixtureSet(this.name)
    : trips =
          (jsonDecode(File('test/fixture/$name/trips.json').readAsStringSync())
                  as Map<String, Object?>)['trips']
              as List;

  final String name;
  final List trips;
  final _tiles = <String, WaterTile?>{};

  bool has(int ix, int iy) =>
      File('test/fixture/$name/${tileName(ix, iy)}.gz').existsSync();

  WaterTile? tile(int ix, int iy) => _tiles.putIfAbsent(
    '${iy}_$ix',
    () => has(ix, iy) ? WaterTile.parse(tileBytes(name, ix, iy)) : null,
  );
}

/// A fixture tile's bytes.
Uint8List tileBytes(String set, int ix, int iy) => Uint8List.fromList(
  gzip.decode(
    File('test/fixture/$set/${tileName(ix, iy)}.gz').readAsBytesSync(),
  ),
);

const ft = 0.3048;

/// The test router's settings (`args`, as route.py takes them) as options:
/// its defaults are 6 ft draft, 2 ft margin and no distance off land.
WaterRouteOptions optionsOf(List<String> args) {
  double? arg(String name) {
    final i = args.indexOf(name);
    return i < 0 ? null : double.parse(args[i + 1]);
  }

  return WaterRouteOptions(
    draftM: (arg('--draft-ft') ?? 6) * ft,
    underKeelM: (arg('--margin-ft') ?? 2) * ft,
    offLandNm: arg('--off-land-nm'),
    mastHeightM: arg('--air-draft-m'),
    avoidOpeningBridges: args.contains('--avoid-opening-bridges'),
  );
}

LatLon pointOf(List<String> args, String name) {
  final v = args
      .firstWhere((a) => a.startsWith('--$name='))
      .split('=')[1]
      .split(',')
      .map(double.parse)
      .toList();
  return (lat: v[1], lon: v[0]);
}

/// A fixture trip as the engine finds it, over the set's tiles alone. A
/// trip with `--security-first never` runs without the second search.
WaterTrip tripOf(
  FixtureSet set,
  List<String> args, {
  WaterRouteOptions? options,
}) {
  return routeOnWater(
    pointOf(args, 'from'),
    pointOf(args, 'to'),
    hasTile: set.has,
    tileAt: set.tile,
    options: options ?? optionsOf(args),
    when: DateTime.utc(2026, 11, 24),
    secondSearch: !args.contains('never'),
  );
}
