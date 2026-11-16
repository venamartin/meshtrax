import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxlos/src/mvt.dart';
import 'package:traxlos/src/pmtiles.dart';

import 'support/fixtures.dart';
import 'support/mvt_writer.dart';
import 'support/pmtiles_writer.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('traxlos_pmtiles'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('PMTiles', () {
    test('tile ids follow the Hilbert curve, zoom by zoom', () {
      // The z13 values found real tiles in the production packs' directories
      // through an independent reader.
      for (final (z, x, y, id) in [
        (0, 0, 0, 0),
        (1, 0, 0, 1),
        (1, 0, 1, 2),
        (1, 1, 1, 3),
        (1, 1, 0, 4),
        (2, 0, 0, 5),
        (12, 715, 1606, 8926758),
        (13, 1438, 3210, 35706983),
        (13, 1439, 3210, 35706984),
        (13, 0, 8191, 44739242),
        (13, 8191, 0, 89478484),
      ]) {
        expect(tileId(z, x, y), id, reason: '$z/$x/$y');
      }
      expect(() => tileId(13, 8192, 0), throwsArgumentError);
    });

    test('reads the header, metadata and tiles, with and without leaf '
        'directories', () {
      final flat = PmtilesFile(fixturePack('norcal-contours-20ft', dir));
      final leafDir = Directory('${dir.path}/leaves')..createSync();
      final leafy = PmtilesFile(
        fixturePack('norcal-contours-20ft', leafDir, leafSize: 3),
      );
      addTearDown(flat.close);
      addTearDown(leafy.close);
      expect(leafy.header.leafLength, greaterThan(0));
      expect(flat.header.leafLength, 0);
      expect(flat.header.maxZoom, 13);
      expect(flat.metadata['interval'], 20);
      expect(flat.metadata['interval_unit'], 'ft');
      expect(flat.metadata['attribution'], 'USGS 3DEP');
      for (final t in fixtureTiles('norcal-contours-20ft')) {
        final [x, y] = t.split('/').map(int.parse).toList();
        final a = flat.tile(13, x, y), b = leafy.tile(13, x, y);
        expect(a, isNotNull, reason: t);
        expect(b, a, reason: t);
        // Decompressed MVT, not gzip.
        expect(a![0], isNot(0x1f));
      }
      for (final t in fixtureAbsent('norcal-contours-20ft')) {
        final [x, y] = t.split('/').map(int.parse).toList();
        expect(flat.tile(13, x, y), isNull, reason: t);
        expect(leafy.tile(13, x, y), isNull, reason: t);
      }
      expect(flat.tile(12, 719, 1605), isNull, reason: 'zoom not in pack');
    });

    test('notices a replaced file', () {
      final path = '${dir.path}/p.pmtiles';
      writePmtiles(
        path,
        {(13, 1, 1): contourTile([])},
        {'v': 1},
        gzipTiles: true,
      );
      final f = PmtilesFile(path);
      expect(f.metadata['v'], 1);
      final g = f.generation;
      f.close();
      writePmtiles(
        path,
        {(13, 1, 1): contourTile([]), (13, 1, 2): contourTile([])},
        {'v': 2},
        gzipTiles: true,
      );
      f.open();
      expect(f.generation, g + 1);
      expect(f.metadata['v'], 2);
      expect(f.tile(13, 1, 2), isNotNull);
      f.close();
    });

    test('refuses files that are not PMTiles v3', () {
      final path = '${dir.path}/bad.pmtiles';
      File(path).writeAsBytesSync(List.filled(200, 7));
      expect(() => PmtilesFile(path).open(), throwsFormatException);
    });
  });

  group('MVT', () {
    test('real 20 ft tiles: levels in whole 20 ft steps, tile coordinates '
        'with their buffer', () {
      final f = PmtilesFile(fixturePack('norcal-contours-20ft', dir));
      addTearDown(f.close);
      final lines = decodeContours(f.tile(13, 1439, 3210)!, feet: true);
      expect(lines.extent, 4096);
      expect(lines.lineCount, greaterThan(100));
      for (final level in lines.levels) {
        final ft = level / 0.3048;
        expect(ft, closeTo(ft.roundToDouble(), 1e-6));
        expect(ft.round() % 20, 0);
      }
      for (final v in lines.xy) {
        expect(v, inInclusiveRange(-80, 4176));
      }
      expect(lines.starts.last, lines.pointCount);
    });

    test('real 10 m tiles read ele_m', () {
      final f = PmtilesFile(fixturePack('norcal-contours-10m', dir));
      addTearDown(f.close);
      final lines = decodeContours(f.tile(13, 1438, 3210)!, feet: false);
      expect(lines.lineCount, greaterThan(10));
      for (final level in lines.levels) {
        expect(level % 10, 0);
      }
    });

    test('heights below sea level, as sint or as 64-bit int', () {
      for (final plain in [false, true]) {
        final t = contourTile([
          (-40, [(0, 0), (100, 100)]),
          (-260, [(0, 0), (5, 5), (9, 1)]),
          (20, [(0, 0), (1, 1)]),
        ], plainInts: plain);
        final lines = decodeContours(t, feet: true);
        expect(lines.levels, [-40 * 0.3048, -260 * 0.3048, 20 * 0.3048]);
        expect(lines.starts, [0, 2, 5, 7]);
        expect(lines.xy.sublist(4, 10), [0, 0, 5, 5, 9, 1]);
      }
    });

    test('a tile without the layer has no lines', () {
      final t = peakTile([('A', 100, 1, 1, 'peak')]);
      expect(decodeContours(t, feet: true).lineCount, 0);
      expect(decodeContours(Uint8List(0), feet: true).lineCount, 0);
    });

    test('named peaks with a height; saddles and nameless points skipped', () {
      final peaks = decodePeaks(
        peakTile([
          ('Summit', 3369, 100, 200, 'peak'),
          ('Pass', 1511, 300, 300, 'saddle'),
          ('', 2000, 5, 5, 'peak'),
          ('Cone', 1200.5, 4100, -20, 'volcano'),
        ]),
      );
      expect(
        [for (final p in peaks) (p.name, p.eleM, p.x, p.y)],
        [('Summit', 3369.0, 100, 200), ('Cone', 1200.5, 4100, -20)],
      );
    });
  });
}
