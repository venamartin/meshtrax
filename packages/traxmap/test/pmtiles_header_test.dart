import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

import 'support/fake_pmtiles.dart';

void main() {
  test('parses header fields', () {
    final h = PmTilesHeader.parse(fakePmTiles(minZoom: 6, maxZoom: 14));
    expect(h.specVersion, 3);
    expect(h.tileType, PmTileType.mvt);
    expect(h.internalCompression, PmCompression.gzip);
    expect(h.minZoom, 6);
    expect(h.maxZoom, 14);
    expect(h.bounds.west, closeTo(-122.0, 1e-7));
    expect(h.bounds.north, closeTo(37.0, 1e-7));
    expect(h.center.latitude, closeTo(36.75, 1e-7));
  });

  test('rejects bad magic and short input', () {
    final bytes = fakePmTiles()..[0] = 0x58;
    expect(() => PmTilesHeader.parse(bytes), throwsFormatException);
    expect(() => PmTilesHeader.parse(Uint8List(10)), throwsFormatException);
  });

  test('reads gzipped metadata', () async {
    final dir = await Directory.systemTemp.createTemp('ovm');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/a.pmtiles')
      ..writeAsBytesSync(fakePmTiles(metadata: {'name': 'Test'}));
    final h = await PmTilesHeader.read(file);
    expect(await h.readMetadata(file), {'name': 'Test'});
  });
}
