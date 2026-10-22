import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

/// `picker.geojson` is cut from the real `dev/picker.geojson` on
/// maps.meshtrax.io (2026-10-19): 11 of its 136 regions, unchanged.
void main() {
  final sample = File('test/support/picker.geojson').readAsStringSync();
  final index = RegionIndex.parse(sample);

  test('reads the collection members and every feature', () {
    expect(index.regions, hasLength(11));
    expect(index.skipped, isEmpty);
    expect(index.version, 1);
    expect(index.needsNewerApp, isFalse);
    expect(index.attribution, contains('Geofabrik'));
    expect(index.source, isNotEmpty);
  });

  test('builds the tree from parent paths', () {
    expect(index.roots.map((r) => r.path), ['north-america', 'test']);
    final us = index['north-america/us']!;
    expect(us.level, 'country');
    expect(us.downloadable, isFalse);
    expect(index.childrenOf(us).map((r) => r.name), [
      'Alaska',
      'California',
      'Nevada',
      'Rhode Island',
    ]);
    final socal = index['north-america/us/california/socal']!;
    expect(index.ancestorsOf(socal).map((r) => r.path), [
      'north-america',
      'north-america/us',
      'north-america/us/california',
    ]);
  });

  test('finds the most specific downloadable region at a point', () {
    expect(
      index.regionAt(const LatLng(41.82, -71.41))?.path, // Providence
      'north-america/us/rhode-island',
    );
    expect(
      index.regionAt(const LatLng(34.05, -118.24))?.path, // Los Angeles
      'north-america/us/california/socal',
    );
    expect(
      index.regionAt(const LatLng(36.91, -121.76))?.path, // Watsonville
      'test/watsonville-test',
    );
    expect(
      index.regionAt(const LatLng(61.22, -149.9))?.path,
      'north-america/us/alaska',
    );
    expect(
      index.regionAt(const LatLng(51.5, -0.13)),
      isNull,
    ); // London: not in the fixture
  });

  test('handles outlines split at the antimeridian', () {
    final alaska = index['north-america/us/alaska']!;
    expect(alaska.polygons.length, greaterThan(1));
    expect(
      alaska.contains(const LatLng(52.9, 173.2)),
      isTrue,
    ); // Attu, west of 180°
    expect(alaska.bounds.west, -180);
  });

  test('pairs regions with their packs through the index', () {
    final packs = PackIndex.parse(
      File('test/support/sample_index.json').readAsStringSync(),
    );
    final ri = index['north-america/us/rhode-island']!;
    expect(packs.forRegion(ri.path).map((e) => e.id), {
      'us-rhode-island',
      'us-rhode-island-contours-10m',
      'us-rhode-island-contours-20ft',
      'us-rhode-island-osm',
    });
    expect(packs.forRegion('north-america/us/california/socal'), isEmpty);
  });

  test('skips a malformed feature and treats an orphan as top level', () {
    final root = jsonDecode(sample) as Map<String, Object?>;
    final features = root['features'] as List<Object?>;
    final first = features.first as Map<String, Object?>;
    (first['properties'] as Map<String, Object?>).remove('name');
    features.add({
      'type': 'Feature',
      'properties': {
        'id': 'orphan',
        'name': 'Orphan',
        'path': 'nowhere/orphan',
        'parent': 'nowhere',
        'level': 'state',
        'downloadable': true,
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [0, 0],
            [1, 0],
            [1, 1],
            [0, 0],
          ],
        ],
      },
    });
    root['version'] = 2;
    final parsed = RegionIndex.parse(jsonEncode(root));
    expect(parsed.skipped, hasLength(1));
    expect(parsed.regions, hasLength(11));
    expect(parsed.roots.map((r) => r.path), contains('nowhere/orphan'));
    expect(parsed['nowhere/orphan']!.bounds.east, 1);
    expect(parsed.needsNewerApp, isTrue);
  });
}
