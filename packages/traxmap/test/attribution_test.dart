import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

import 'support/fake_pmtiles.dart';

Pack _pack(String id, String kind, String? attribution) => Pack(
  id: id,
  file: File('/packs/$id.pmtiles'),
  header: PmTilesHeader.parse(fakePmTiles()),
  metadata: {'kind': kind, 'attribution': ?attribution},
);

void main() {
  final base = _pack('r', 'base', 'USGS The National Map');
  final osm = _pack(
    'r-osm',
    'osm',
    '<a href="https://openmaptiles.org/">&copy; OpenMapTiles</a> '
        '<a href="https://www.openstreetmap.org/copyright">&copy; OpenStreetMap contributors</a>',
  );
  final contours = _pack('r-contours-20ft', 'contours', 'USGS 3DEP');
  final dup = _pack('other', 'base', 'USGS The National Map');

  test('strips HTML, decodes entities, removes duplicates', () {
    expect(attributionOf([base, osm, dup, contours]), [
      'USGS The National Map',
      '© OpenMapTiles © OpenStreetMap contributors',
      'USGS 3DEP',
    ]);
  });

  test('licence notices: every distinct line, from packs that have one', () {
    Pack withNotice(String id, String notice) => Pack(
      id: id,
      file: File('/packs/$id.pmtiles'),
      header: PmTilesHeader.parse(fakePmTiles()),
      metadata: {'kind': 'contours', 'notice': notice},
    );
    const copernicus = 'The organisations in charge of Copernicus …';
    expect(
      noticesOf([
        base,
        withNotice('a', copernicus),
        withNotice('b', '$copernicus\nAnother source notice'),
      ]),
      [copernicus, 'Another source notice'],
    );
    expect(noticesOf([base, osm]), isEmpty);
  });

  test('packs combined into one source are all credited', () {
    const context = StyleContext();
    final otherContours = _pack('n-contours-20ft', 'contours', 'Copernicus');
    final style = <String, Object?>{
      'sources': {
        'contours': {
          'type': 'vector',
          'url': context.pmtilesUrl(contours),
          'ovm:urls': [
            context.pmtilesUrl(contours),
            context.pmtilesUrl(otherContours),
          ],
        },
      },
    };
    expect(packsUsedBy(style, [base, contours, otherContours], context), [
      contours,
      otherContours,
    ]);
  });

  test('only packs the style draws from are credited', () {
    const context = StyleContext();
    final style = <String, Object?>{
      'sources': {
        'base': {'type': 'vector', 'url': context.pmtilesUrl(base)},
        'contours': {'type': 'vector', 'url': context.pmtilesUrl(contours)},
      },
    };
    expect(packsUsedBy(style, [base, osm, contours], context), [
      base,
      contours,
    ]);
  });
}
