import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

/// `chart_areas.geojson` is the live file from maps.meshtrax.io
/// (2026-10-20, 17:10 PDT, with `coast_areas`); `charts_index.json` is the
/// live index.json's 42 charts entries plus Rhode Island's map.
void main() {
  final json = File('test/support/chart_areas.geojson').readAsStringSync();
  final index = ChartAreaIndex.parse(json);

  test('reads the file members and every area', () {
    expect(index.version, 1);
    expect(index.needsNewerApp, isFalse);
    expect(index.source, startsWith('NOAA ENC'));
    expect(index.attribution, 'NOAA Office of Coast Survey');
    expect(index.skipped, isEmpty);
    expect(index.areas, hasLength(42));
    expect(index.coasts, [
      'West Coast',
      'Alaska',
      'Hawaii & Pacific',
      'Atlantic Coast',
      'Gulf Coast',
      'Great Lakes',
      'Caribbean',
      'Inland lakes',
      'Other',
    ]);
  });

  test('coasts list their areas along the coast; some areas are in two', () {
    final counts = {for (final c in index.coasts) c: index.inCoast(c).length};
    expect(counts, {
      'West Coast': 3,
      'Alaska': 1,
      'Hawaii & Pacific': 4,
      'Atlantic Coast': 15,
      'Gulf Coast': 5,
      'Great Lakes': 8,
      'Caribbean': 5,
      'Inland lakes': 3,
      'Other': 1,
    });
    List<String> ids(String coast) => [
      for (final a in index.inCoast(coast)) a.id,
    ];
    expect(ids('West Coast'), ['charts-us-wa', 'charts-us-or', 'charts-us-ca']);
    expect(ids('Atlantic Coast').first, 'charts-us-me');
    expect(ids('Atlantic Coast').last, 'charts-us-fl');
    expect(ids('Gulf Coast').first, 'charts-us-fl');
    expect(ids('Gulf Coast').last, 'charts-us-tx');
    final florida = index.byPackRegion('charts/us/florida')!;
    expect(florida.coasts, containsAll(['Atlantic Coast', 'Gulf Coast']));
    expect(index.inCoast('Gulf Coast'), contains(florida));
    expect(index.inCoast('Atlantic Coast'), contains(florida));
    expect(index.areas.where((a) => a == florida), hasLength(1));
  });

  test('looks areas up by their pack region only', () {
    expect(
      index.byPackRegion('charts/us/lake-champlain')!.name,
      'Lake Champlain (Vermont)',
    );
    expect(
      index.byPackRegion('charts/us/puerto-rico')!.name,
      'Puerto Rico & Virgin Islands',
    );
    expect(index.byPackRegion('north-america/us/rhode-island'), isNull);
    expect(index.byPackRegion('charts/us/rhode-island')!.id, 'charts-us-ri');
  });

  test('finds the areas at a point, the most specific first', () {
    expect(
      index.areasAt(const LatLng(41.5, -71.35)).first.name,
      'Rhode Island',
    );
    expect(
      index.areasAt(const LatLng(39.74, -104.99)),
      isEmpty,
      reason: 'Denver',
    );
    expect(
      index.areasAt(const LatLng(52.9, 173.2)).map((a) => a.name),
      contains('Alaska'),
      reason: 'Attu, across the antimeridian',
    );
  });

  test('finds the areas overlapping a box', () {
    final rhodeIsland = const LatLngBounds(
      south: 41.1,
      west: -71.9,
      north: 42.0,
      east: -71.1,
    );
    expect(
      index.areasIn(rhodeIsland).map((a) => a.name),
      contains('Rhode Island'),
    );
    final colorado = const LatLngBounds(
      south: 37,
      west: -109,
      north: 41,
      east: -102,
    );
    expect(index.areasIn(colorado), isEmpty);
    for (final part in index.byPackRegion('charts/us/alaska')!.parts) {
      expect(part.east - part.west, lessThan(360));
    }
  });

  test('every area pairs with exactly one charts pack, and back', () {
    final packs = PackIndex.parse(
      File('test/support/charts_index.json').readAsStringSync(),
    );
    final charts = packs.usable.where((e) => e.kind == PackKind.charts);
    for (final area in index.areas) {
      final entries = packs
          .forRegion(area.packRegion)
          .where((e) => e.kind == PackKind.charts);
      expect(entries, hasLength(1), reason: area.name);
      expect(entries.single.id, isNot(area.id));
    }
    for (final entry in charts) {
      expect(index.byPackRegion(entry.region!), isNotNull, reason: entry.id);
    }
  });

  group('tolerates a changed file', () {
    Map<String, Object?> feature(
      String id, {
      Object? coasts = const ['Atlantic Coast'],
      String? packRegion,
      Object? geometry = const {
        'type': 'Polygon',
        'coordinates': [
          [
            [-71, 41],
            [-70, 41],
            [-70, 42],
            [-71, 41],
          ],
        ],
      },
    }) => {
      'type': 'Feature',
      'properties': {
        'id': id,
        'name': id.toUpperCase(),
        'coasts': ?coasts,
        'pack_region': packRegion ?? 'charts/us/$id',
      },
      'geometry': geometry,
    };

    ChartAreaIndex parse(
      List<Map<String, Object?>> features, {
      Map<String, Object?> extra = const {},
    }) => ChartAreaIndex.parse(
      jsonEncode({
        'type': 'FeatureCollection',
        'coasts': ['Atlantic Coast'],
        'features': features,
        ...extra,
      }),
    );

    test('bad features are skipped and named', () {
      final index = parse([
        feature('a'),
        feature('b', coasts: const <String>[]),
        feature(
          'c',
          geometry: const {
            'type': 'Point',
            'coordinates': [0, 0],
          },
        ),
        feature('a'),
        feature('d', packRegion: 'charts/us/a'),
        {
          'type': 'Feature',
          'properties': {'id': 'e', 'name': 'E'},
        },
      ]);
      expect(index.areas.map((a) => a.id), ['a']);
      expect(index.skipped, hasLength(5));
      expect(index.skipped.first, startsWith('b:'));
    });

    test('an area without geometry is listed but never found at a point', () {
      final index = parse([feature('a', geometry: null)]);
      expect(index.areas.single.polygons, isEmpty);
      expect(index.areas.single.parts, isEmpty);
      expect(index.areasAt(const LatLng(41.2, -70.8)), isEmpty);
    });

    test('a coast missing from the list is added after it', () {
      final index = parse([
        feature('a', coasts: const ['Atlantic Coast', 'New coast']),
      ]);
      expect(index.coasts, ['Atlantic Coast', 'New coast']);
      expect(index.inCoast('New coast').single.id, 'a');
    });

    test('coast_areas orders a coast; unlisted areas follow by name', () {
      final index = parse(
        [feature('a'), feature('b'), feature('c'), feature('d')],
        extra: {
          'coast_areas': {
            'Atlantic Coast': ['c', 'a'],
          },
        },
      );
      expect(index.inCoast('Atlantic Coast').map((a) => a.id), [
        'c',
        'a',
        'b',
        'd',
      ]);
    });

    test('a newer version asks for a newer app', () {
      expect(parse([], extra: {'version': 2}).needsNewerApp, isTrue);
    });

    test('the root must be an object', () {
      expect(() => ChartAreaIndex.parse('[]'), throwsFormatException);
    });
  });
}
