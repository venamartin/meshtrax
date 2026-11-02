import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/drawing_map.dart';

void main() {
  group('the map line', () {
    test('reads and writes back unchanged', () {
      for (final line in [
        'map=16/36.9695/-121.9525/c',
        'map=18/36.9643/-122.0177',
        'map=16/37.005/-121.905/u',
        'map=3/0/0',
      ]) {
        expect(DrawingMap.tryParse(line)!.toLine(), line, reason: line);
      }
    });

    test('carries the map type as one letter, Standard as none', () {
      expect(
        DrawingMap.tryParse('map=16/36.9695/-121.9525/c')!.type,
        DrawingMapType.charts,
      );
      expect(DrawingMap.tryParse('map=16/1/2/u')!.type, DrawingMapType.usgs);
      expect(DrawingMap.tryParse('map=16/1/2')!.type, DrawingMapType.standard);
    });

    test('any case reads, and a letter this app does not know is Standard', () {
      expect(DrawingMap.tryParse('MAP=16/1/2/C')!.type, DrawingMapType.charts);
      expect(DrawingMap.tryParse('map=16/1/2/x')!.type, DrawingMapType.standard);
    });

    test('anything else is not a map line', () {
      for (final line in [
        'map=19/1/2',
        'map=16/86/2',
        'map=16/1/181',
        'map=16/abc/2',
        'map=16/1',
        'map=16/1/2/cc',
        'map=16/1/2/c/x',
        'map 16/1/2',
        'Map of the bay',
      ]) {
        expect(DrawingMap.tryParse(line), isNull, reason: line);
      }
    });
  });

  group('snapping', () {
    test('rounds the zoom to a whole step within 3 to 18', () {
      DrawingMap snap(double zoom) => DrawingMap.snap(zoom: zoom, lat: 0, lon: 0);
      expect(snap(16.4).zoom, 16);
      expect(snap(16.6).zoom, 17);
      expect(snap(1.2).zoom, 3);
      expect(snap(21).zoom, 18);
    });

    test('rounds the centre to 4 decimals and writes no trailing zeros', () {
      final map = DrawingMap.snap(
        zoom: 16,
        lat: 37.00501234,
        lon: -121.90498765,
        type: DrawingMapType.usgs,
      );
      expect(map.lat, 37.005);
      expect(map.lon, -121.905);
      expect(map.toLine(), 'map=16/37.005/-121.905/u');
    });

    test('wraps longitude past the date line', () {
      expect(DrawingMap.snap(zoom: 5, lat: 0, lon: 181).lon, -179);
      expect(DrawingMap.snap(zoom: 5, lat: 0, lon: -0.00001).toLine(), 'map=5/0/0');
    });
  });

  test('a frame is 400 map pixels across at its zoom', () {
    const map = DrawingMap(zoom: 16, lat: 36.9695, lon: -121.9525);
    expect(map.metersAcross, closeTo(763, 1));
    const closer = DrawingMap(zoom: 18, lat: 36.9643, lon: -122.0177);
    expect(closer.metersAcross, closeTo(191, 1));
  });

  group('frames and the ground', () {
    const a = DrawingMap(zoom: 16, lat: 36.9695, lon: -121.9525);

    test('a point goes to the world and back to the same place', () {
      for (final p in [(x: 0.0, y: 0.0), (x: 200.0, y: 150.0), (x: 37.0, y: 281.0)]) {
        final back = a.fromWorld(a.toWorld(p));
        expect(back.x, closeTo(p.x, 1e-6));
        expect(back.y, closeTo(p.y, 1e-6));
      }
    });

    test('the centre is the middle of the frame', () {
      final c = DrawingMap.project(a.lat, a.lon);
      final p = a.fromWorld(c);
      expect(p.x, closeTo(200, 1e-6));
      expect(p.y, closeTo(150, 1e-6));
    });

    test('one zoom step closer, the same ground is twice as far from the centre', () {
      const b = DrawingMap(zoom: 17, lat: 36.9695, lon: -121.9525);
      final p = b.fromWorld(a.toWorld((x: 300, y: 150)));
      expect(p.x, closeTo(400, 1e-6));
      expect(p.y, closeTo(150, 1e-6));
    });

    test('a frame further east finds the same ground further west', () {
      // 100 map pixels at zoom 16, in degrees of longitude.
      const step = 100 * 360 / (256 * 65536);
      const east = DrawingMap(zoom: 16, lat: 36.9695, lon: -121.9525 + step);
      final p = east.fromWorld(a.toWorld((x: 200, y: 150)));
      expect(p.x, closeTo(100, 1e-6));
      expect(p.y, closeTo(150, 1e-6));
    });
  });
}
