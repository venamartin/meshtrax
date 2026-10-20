import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

/// `sample_index.json` is a real index written by traxmapmaker's publish
/// stage, so this checks the two repos agree on the format.
void main() {
  test('parses an index published by traxmapmaker', () {
    final index = PackIndex.parse(
      File('test/support/sample_index.json').readAsStringSync(),
    );
    expect(index.packs, hasLength(5));
    final kinds = {for (final p in index.packs) p.kind};
    expect(kinds, {
      PackKind.base,
      PackKind.osm,
      PackKind.charts,
      PackKind.contours,
    });
    final base = index.packs.firstWhere((p) => p.kind == PackKind.base);
    expect(base.url.path, endsWith('/v1/test/watsonville-test/usgs.pmtiles'));
    expect(base.sha256, hasLength(64));
    expect(base.bbox.contains(const LatLng(36.91, -121.76)), isTrue);
    expect(base.schemaVersion, 1);
  });
}
