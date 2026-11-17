import 'dart:convert';
import 'dart:io';

import 'package:traxlos/src/geo.dart' as geo;
import 'package:traxlos/traxlos.dart';

import 'mvt_writer.dart';
import 'pmtiles_writer.dart';

/// Real tiles: see test/fixtures/fixtures.json for where they came from.
final _manifest = jsonDecode(
  File('test/fixtures/fixtures.json').readAsStringSync(),
) as Map<String, Object?>;

Map<String, Object?> _pack(String name) =>
    (_manifest['packs'] as Map<String, Object?>)[name] as Map<String, Object?>;

/// The z13 tiles the fixture has for [name], as "x/y".
List<String> fixtureTiles(String name) =>
    (_pack(name)['tiles'] as List).cast<String>();

/// Tiles the tests touch that the real pack [name] doesn't have.
List<String> fixtureAbsent(String name) =>
    (_pack(name)['absent'] as List).cast<String>();

/// Writes the fixture's tiles of [name] as a PMTiles pack in [dir] and
/// returns its path.
String fixturePack(String name, Directory dir, {int? leafSize}) {
  final tiles = <(int, int, int), List<int>>{};
  for (final t in fixtureTiles(name)) {
    final [x, y] = t.split('/').map(int.parse).toList();
    tiles[(13, x, y)] = File('test/fixtures/$name/13-$x-$y.mvt.gz')
        .readAsBytesSync();
  }
  final path = '${dir.path}/$name.pmtiles';
  writePmtiles(
    path,
    tiles,
    Map<String, Object?>.from(_pack(name)['metadata'] as Map),
    leafSize: leafSize,
  );
  return path;
}

/// A box as a coverage outline.
List<List<List<Geo>>> box(double s, double w, double n, double e) => [
  [
    [Geo(s, w), Geo(s, e), Geo(n, e), Geo(n, w), Geo(s, w)],
  ],
];

/// The part of Death Valley the fixture covers (inside the real NorCal
/// outline).
final deathValley = box(36.10, -117.00, 36.60, -116.60);

// Places, with USGS 3DEP 1 m lidar heights from the USGS Elevation Point
// Query Service where given.
const dantesView = Geo(36.2209, -116.7266); // 1670.1 m
const badwater = Geo(36.2302, -116.7672); // -82.7 m (1" DEM: -82.6 m)
const furnaceCreek = Geo(36.4618, -116.8664); // 1" DEM: -57.5 m
const blackMountainsSlope = Geo(36.210618, -116.707517); // 1476.1 m
const saltPan = Geo(36.227697, -116.780625); // -84.8 m

/// The ground the 1" DEM gives at Badwater, below sea level where the
/// packs have no lines.
const badwaterGroundM = -82.6;

/// A synthetic contours pack in [dir]: [tiles] maps z13 x, y to an MVT
/// tile (see mvt_writer.dart). [belowSeaLevel] marks it as having lines
/// at and below sea level, as the rebuilt packs do.
String syntheticPack(
  Directory dir,
  String name,
  Map<(int, int), List<int>> tiles, {
  String interval = '20ft',
  bool belowSeaLevel = false,
}) {
  final path = '${dir.path}/$name.pmtiles';
  final m = RegExp(r'(\d+)(ft|m)').firstMatch(interval)!;
  writePmtiles(
    path,
    {for (final e in tiles.entries) (13, e.key.$1, e.key.$2): e.value},
    {
      'name': 'Test contours',
      'kind': 'contours',
      'interval': int.parse(m.group(1)!),
      'interval_unit': m.group(2),
      'attribution': 'Test heights',
      if (belowSeaLevel) 'below_sea_level': true,
    },
    gzipTiles: true,
  );
  return path;
}

/// A synthetic map pack in [dir] with named peaks in z13 tile x, y.
String peakPack(Directory dir, int x, int y, List<PeakFeature> peaks) {
  final path = '${dir.path}/peaks.pmtiles';
  writePmtiles(
    path,
    {(13, x, y): peakTile(peaks)},
    {'name': 'Test map', 'attribution': 'Test map credit'},
    gzipTiles: true,
  );
  return path;
}

/// The synthetic tests' z13 tile, somewhere with no real packs.
const tx = 1300, ty = 3000;

/// A position in the synthetic tile, in tile coordinates (0..4096).
Geo at(double x, double y) => geo.fromWorld(tx * 4096.0 + x, ty * 4096.0 + y);

/// The synthetic tile's own square as a coverage outline.
List<List<List<Geo>>> tileSquare([int x0 = 0, int x1 = 4096]) => [
  [
    [
      at(x0.toDouble(), 0),
      at(x1.toDouble(), 0),
      at(x1.toDouble(), 4096),
      at(x0.toDouble(), 4096),
      at(x0.toDouble(), 0),
    ],
  ],
];

/// A vertical contour line across the synthetic tile at [x].
Line vertical(num ele, int x) => (ele, [(x, -40), (x, 4136)]);
