import 'dart:math';
import 'dart:typed_data';

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

TraxReport _report({Trail? trail, String? name}) => TraxReport(
  seq: 1,
  senderPrefix: Uint8List.fromList([1, 2, 3, 4]),
  session: 9,
  sentAt: DateTime.utc(2026, 11, 22, 9),
  lat: _start.lat,
  lon: _start.lon,
  name: name,
  trail: trail,
);

void main() {
  test('exp-Golomb writes the plan example: k 3, u 100 is 0001101100', () {
    // A step of 50 grid units east zigzags to 100; 0 north is 1000.
    final anchor = wirePosition(_start.lat, _start.lon);
    final east = (
      lat: anchor.lat,
      lon: anchor.lon + 50 * 8 / (_mPerDegree * cos(anchor.lat * pi / 180)),
    );
    final bits = encodeTrail(anchor, (gridM: 8, points: [east]));
    // 0001101100 1000, padded: 00011011 00100000
    expect(bits, [0x1B, 0x20]);
  });

  test('a trail reads back to within half a grid step per axis', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final points = _walk(anchor, 40, stepM: 60, wiggleM: 20);
    final trail = (gridM: 8, points: points);
    final bits = encodeTrail(anchor, trail);
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

  test('a short trail fits at 15 m on an 8 m grid', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final fit = fitTrail(anchor, _walk(anchor, 20, wiggleM: 30), 126)!;
    expect(fit.gridM, 8);
    expect(fit.points.length, 20);
  });

  test('10 miles of twisting trail fit in the room, finest first', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final points = _walk(anchor, 640, wiggleM: 30);
    final room = TraxReport.trailRoom(name: 'Trail Radio');
    final fit = fitTrail(anchor, points, room)!;
    expect(encodeTrail(anchor, fit).length, lessThanOrEqualTo(room));
    expect(fit.points.last, points.last, reason: 'the oldest point is kept');
    final bytes = _report(trail: fit, name: 'Trail Radio').encode();
    expect(bytes.length, lessThanOrEqualTo(TraxReport.maxSize));
    final back = TraxReport.decode(bytes)!;
    expect(back.name, 'Trail Radio');
    expect(back.trail!.gridM, fit.gridM);
    expect(back.trail!.points.length, fit.points.length);
    expect(_metres(back.trail!.points.last, points.last), lessThan(300));
  });

  test('a report with a trail reads back, name after the points', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final fit = fitTrail(anchor, _walk(anchor, 12, wiggleM: 25), 126)!;
    final bytes = _report(trail: fit, name: 'Ana').encode();
    final back = TraxReport.decode(bytes)!;
    expect(back.lat, closeTo(_start.lat, 1e-9));
    expect(back.name, 'Ana');
    expect(back.trail!.points.length, fit.points.length);
    for (var i = 0; i < fit.points.length; i++) {
      expect(_metres(back.trail!.points[i], fit.points[i]), lessThan(6));
    }
  });

  test('a trail across 180 degrees does not go round the world', () {
    final anchor = wirePosition(-16.8, 179.9995);
    final west = (lat: -16.8, lon: -179.9995);
    final trail = (gridM: 8, points: [west]);
    final bits = encodeTrail(anchor, trail);
    expect(bits.length, lessThanOrEqualTo(4));
    final read = decodeTrail(anchor, 8, 1, bits, 0)!;
    expect(read.points.single.lon, closeTo(-179.9995, 1e-4));
  });

  test('a truncated or broken trail drops the report', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    final fit = fitTrail(anchor, _walk(anchor, 12, wiggleM: 25), 126)!;
    final bytes = _report(trail: fit).encode();
    expect(TraxReport.decode(bytes.sublist(0, bytes.length - 2)), isNull);
    final noGrid = Uint8List.fromList(bytes)..[29] = 0;
    expect(TraxReport.decode(noGrid), isNull);
    final tooMany = Uint8List.fromList(bytes)..[30] = 200;
    expect(TraxReport.decode(tooMany), isNull);
    final zeros = Uint8List.fromList([
      ...bytes.sublist(0, 31),
      ...Uint8List(40),
    ]);
    expect(TraxReport.decode(zeros), isNull);
  });

  test('no room, no trail', () {
    final anchor = wirePosition(_start.lat, _start.lon);
    expect(fitTrail(anchor, _walk(anchor, 5), 0), isNull);
    expect(fitTrail(anchor, const [], 126), isNull);
  });
}
