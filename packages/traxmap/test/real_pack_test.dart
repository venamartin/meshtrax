import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

/// Reads the test packs built by traxmapmaker, if they're in test/packs.
void main() {
  final file = File('test/packs/watsonville-test.pmtiles');

  test(
    'reads the pipeline-built test pack',
    () async {
      final pack = await PackManager.open(file);
      expect(pack.kind, PackKind.base);
      expect(pack.header.tileType, PmTileType.mvt);
      expect(pack.minZoom, 6);
      expect(pack.maxZoom, 14);
      expect(pack.metadata['schema_version'], 1);
      expect(
        pack.vectorLayers,
        containsAll(['road', 'trail', 'water', 'waterway', 'hillshade']),
      );
      expect(pack.vectorLayers, isNot(contains('contour')));
      expect(pack.bounds.contains(const LatLng(36.91, -121.76)), isTrue);
    },
    skip: file.existsSync() ? false : 'build test packs into test/packs (see README)',
  );

  final contours = File(
    'test/packs/watsonville-test-contours-20ft.pmtiles',
  );
  test(
    'reads the pipeline-built contours pack',
    () async {
      final pack = await PackManager.open(contours);
      expect(pack.kind, PackKind.contours);
      expect(pack.maxZoom, 13, reason: 'overzoomed above z13');
      expect(pack.vectorLayers, ['contour']);
      expect(pack.variant, '20ft');
      expect(pack.units, Units.imperial);
    },
    skip: contours.existsSync()
        ? false
        : 'build test packs into test/packs (see README)',
  );
}
