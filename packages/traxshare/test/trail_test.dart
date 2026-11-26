import 'dart:math';

import 'package:test/test.dart';
import 'package:traxshare/traxshare.dart';

const _start = (lat: 36.4570, lon: -116.8660);
const _mPerDegree = 111320.0;

/// [n] points, newest first, walking back from [from] every [stepM] metres
/// on [heading] degrees, wiggling [wiggleM] either side.
List<TrailPoint> _walk(
  TrailPoint from,
  int n, {
  double stepM = 25,
  double heading = 200,
  double wiggleM = 0,
}) {
  final cosLat = cos(from.lat * pi / 180);
  final h = heading * pi / 180;
  return [
    for (var i = 1; i <= n; i++)
      (
        lat:
            from.lat +
            (i * stepM * cos(h) + (i.isEven ? wiggleM : -wiggleM) * sin(h)) /
                _mPerDegree,
        lon:
            from.lon +
            (i * stepM * sin(h) - (i.isEven ? wiggleM : -wiggleM) * cos(h)) /
                (_mPerDegree * cosLat),
      ),
  ];
}

double _metres(TrailPoint a, TrailPoint b) {
  final dy = (a.lat - b.lat) * _mPerDegree;
  final dx = (a.lon - b.lon) * _mPerDegree * cos(a.lat * pi / 180);
  return sqrt(dx * dx + dy * dy);
}

void main() {
  test('exp-Golomb writes the plan example: k 3, u 100 is 0001101100', () {
    // A step of 50 grid units east zigzags to 100; 0 north is 1000.
    final anchor = wirePosition(_start.lat, _start.lon);
    final east = (
      lat: anchor.lat,
      lon: anchor.lon + 50 * 8 / (_mPerDegree * cos(anchor.lat * pi / 180)),
    );
    final bits = encodeTrail(anchor, 8, [east]);
    // 0001101100 1000, padded: 00011011 00100000
    expect(bits, [0x1B, 0x20]);
  });

  test('a trail reads back to within half a grid step per axis', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final points = _walk(anchor, 40, stepM: 60, wiggleM: 20);
    final bits = encodeTrail(anchor, 8, points);
    final read = decodeTrail(anchor, 8, points.length, bits, 0)!;
    expect(read.bytes, bits.length);
    for (var i = 0; i < points.length; i++) {
      expect(_metres(read.points[i], points[i]), lessThan(6), reason: '$i');
    }
  });

  test('simplify keeps the ends and drops what stays within epsilon', () {
    final straight = [_start, ..._walk(_start, 30)];
    expect(simplify(straight, 15), [straight.first, straight.last]);
    final zigzag = [_start, ..._walk(_start, 30, wiggleM: 40)];
    expect(simplify(zigzag, 15).length, zigzag.length);
  });

  test('a trail across 180 degrees does not go round the world', () {
    final anchor = wirePosition(-16.8, 179.9995);
    final west = (lat: -16.8, lon: -179.9995);
    final bits = encodeTrail(anchor, 8, [west]);
    expect(bits.length, lessThanOrEqualTo(4));
    final read = decodeTrail(anchor, 8, 1, bits, 0)!;
    expect(read.points.single.lon, closeTo(-179.9995, 1e-4));
  });
}
