import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

/// `sample_index.json` is the real `dev/index.json` from maps.meshtrax.io
/// (2026-10-19), so this checks the two repos agree on the format.
void main() {
  final sample = File('test/support/sample_index.json').readAsStringSync();

  test('parses an index published by traxmapmaker', () {
    final index = PackIndex.parse(sample);
    expect(index.packs, hasLength(9));
    expect(index.skipped, isEmpty);
    expect(index.schemaVersion, 1);
    expect(index.generated, DateTime.utc(2026, 10, 19, 23, 29, 8));
    expect(index.needsNewerApp, isFalse);
    final kinds = {for (final p in index.packs) p.kind};
    expect(kinds, {
      PackKind.base,
      PackKind.osm,
      PackKind.charts,
      PackKind.contours,
    });
    final base = index.packs.firstWhere((p) => p.id == 'watsonville-test');
    expect(base.url.path, endsWith('/v1/test/watsonville-test/usgs.pmtiles'));
    expect(base.sha256, hasLength(64));
    expect(base.bbox.contains(const LatLng(36.91, -121.76)), isTrue);
    expect(base.schemaVersion, 1);
    expect(base.region, 'test/watsonville-test');
    expect(base.variant, isNull);
  });

  test('reads region and contour variant fields', () {
    final index = PackIndex.parse(sample);
    final contours = index.packs.firstWhere(
      (p) => p.id == 'us-rhode-island-contours-10m',
    );
    expect(contours.region, 'north-america/us/rhode-island');
    expect(contours.variant, '10m');
    expect(contours.units, Units.metric);
    expect(contours.interval, 10);
    expect(contours.intervalUnit, 'm');
  });

  test('round-trips entries, so restored downloads keep every field', () {
    for (final entry in PackIndex.parse(sample).packs) {
      final copy = PackIndexEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, Object?>,
      );
      expect(copy.toJson(), entry.toJson());
    }
  });

  test('skips a malformed entry instead of rejecting the index', () {
    final root = jsonDecode(sample) as Map<String, Object?>;
    final packs = root['packs'] as List<Object?>;
    (packs[0] as Map<String, Object?>).remove('sha256');
    packs.add('not an entry');
    final index = PackIndex.parse(jsonEncode(root));
    expect(index.packs, hasLength(8));
    expect(index.skipped, hasLength(2));
    expect(index.skipped.first, startsWith('${(packs[0] as Map)['id']}:'));
  });

  test('ignores other modules and tolerates a missing packs key', () {
    final index = PackIndex.parse(
      jsonEncode({
        'schema_version': 1,
        'routing': {'lookup_version': 11, 'tiles': {}},
      }),
    );
    expect(index.packs, isEmpty);
    expect(index.skipped, isEmpty);
  });

  test('usable leaves out unknown kinds and other schema versions', () {
    final root = jsonDecode(sample) as Map<String, Object?>;
    final packs = root['packs'] as List<Object?>;
    (packs[0] as Map<String, Object?>)['kind'] = 'overlay';
    (packs[1] as Map<String, Object?>)['schema_version'] = 2;
    root['schema_version'] = 2;
    final index = PackIndex.parse(jsonEncode(root));
    expect(index.packs, hasLength(9));
    expect(index.usable, hasLength(7));
    expect(index.needsNewerApp, isTrue);
  });
}
