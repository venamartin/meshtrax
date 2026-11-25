import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxwater/traxwater.dart';

Uint8List _bytes(String path) =>
    Uint8List.fromList(gzip.decode(File(path).readAsBytesSync()));

void main() {
  final bytes = _bytes('test/fixture/monterey/506_232.wrm.gz');

  test('reads the fixture tiles, as the builder counted them', () {
    for (final set in ['monterey', 'carquinez', 'antimeridian']) {
      final json =
          jsonDecode(File('test/fixture/$set/trips.json').readAsStringSync())
              as Map<String, Object?>;
      for (final t in (json['tiles'] as List).cast<Map>()) {
        final b = _bytes('test/fixture/$set/${t['file']}.gz');
        expect(b.length, t['bytes']);
        final tile = WaterTile.parse(b);
        expect(tileName(tile.ix, tile.iy), t['file']);
        expect(tile.triangleCount, t['triangles']);
        expect(tile.build, t['build']);
      }
    }
  });

  test('reads a tile', () {
    final tile = WaterTile.parse(bytes);
    expect((tile.ix, tile.iy), (232, 506));
    expect(tile.build, '2026112401');
    expect(tile.buildInfo['cells_sha1'], startsWith('d5c2fc08'));
    final zone = tile.areas.singleWhere((a) => a.id == 'f905d550a718');
    expect(zone.name, 'Monterey Bay Security Zone');
    expect(zone.isOverhead, isFalse);
  });

  test('reads opening bridges and their clearances', () {
    final tile = WaterTile.parse(
      _bytes('test/fixture/carquinez/512_231.wrm.gz'),
    );
    final lift = tile.areas.singleWhere((a) => a.id == 'f9d7e118881e');
    expect(lift.name, 'Union Pacific Railroad Lift Bridge');
    expect(lift.opens, isTrue);
    expect((lift.clearanceClosedM, lift.clearanceOpenM), (21.3, 41.1));
    expect(lift.charted, 21.3);
  });

  group('refuses', () {
    test('another format', () {
      final other = Uint8List.fromList(bytes)..[3] = 0x31; // WRM1
      expect(() => WaterTile.parse(other), throwsFormatException);
    });

    test('a tile cut short', () {
      expect(
        () =>
            WaterTile.parse(Uint8List.sublistView(bytes, 0, bytes.length - 1)),
        throwsFormatException,
      );
    });

    test('bytes after the areas', () {
      expect(
        () => WaterTile.parse(Uint8List.fromList([...bytes, 0])),
        throwsFormatException,
      );
    });

    test('a vertex that isn\'t there', () {
      final b = ByteData.sublistView(bytes);
      final vertices = b.getUint32(14, Endian.little);
      final broken = Uint8List.fromList(bytes);
      ByteData.sublistView(
        broken,
      ).setUint32(42 + vertices * 8, vertices, Endian.little);
      expect(() => WaterTile.parse(broken), throwsFormatException);
    });
  });
}
