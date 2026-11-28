import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxproto/traxproto.dart';
import 'package:traxshare/traxshare.dart';

TraxReport _report({
  int seq = 7,
  double lat = 36.4570,
  double lon = -116.8660,
  int? altitude = -86,
  int? battery = 81,
  bool mayBeOld = false,
  TraxMapIcon icon = TraxMapIcon.hike,
  String? name,
  int? build,
  double? heading,
  double? speed,
  Duration? stillFor,
  TrackBlock? track,
}) => TraxReport(
  seq: seq,
  senderPrefix: Uint8List.fromList([0xB4, 0xE1, 0x02, 0x9C]),
  sentAt: DateTime.utc(2026, 11, 21, 18, 30, 5),
  lat: lat,
  lon: lon,
  altitude: altitude,
  battery: battery,
  mayBeOld: mayBeOld,
  icon: icon,
  name: name,
  build: build,
  heading: heading,
  speed: speed,
  stillFor: stillFor,
  track: track,
);

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
]);

// Version 2's REPORT, byte by byte. These bytes must never change: a phone
// on an older MeshTrax reads them.
final _golden = _hex(
  '21' // version 2, kind 1
  'B4E1029C' // sender
  '2DE3016B' // sent at 1795285805
  '00' // flags
  '97D9B3' // latitude, 11786647 2^24ths from -90
  '32E52C' // longitude, 2942258 2^24ths from -180
  '07' // seq
  '00' // heading
  '00' // speed or minutes still
  'AAFF' // altitude -86
  '51' // battery 81
  '00', // icon
);

final _track = TrackBlock(
  gridM: 8,
  keepHours: 48,
  pieces: [
    TrackPiece(
      minute: TrackPiece.minuteOf(DateTime.utc(2026, 11, 21, 18)),
      endMinute: TrackPiece.minuteOf(DateTime.utc(2026, 11, 21, 18, 20)),
      points: const [
        (lat: 36.4500, lon: -116.8600),
        (lat: 36.4550, lon: -116.8640),
      ],
    ),
  ],
);

void main() {
  test('a report without a name is 23 bytes and reads back', () {
    final bytes = _report().encode();
    expect(bytes.length, TraxReport.size);
    final r = TraxReport.decode(bytes)!;
    expect(r.seq, 7);
    expect(r.senderPrefix, [0xB4, 0xE1, 0x02, 0x9C]);
    expect(r.sentAt, DateTime.utc(2026, 11, 21, 18, 30, 5));
    expect(r.lat, closeTo(36.4570, 6e-6));
    expect(r.lon, closeTo(-116.8660, 1.1e-5));
    expect(r.altitude, -86);
    expect(r.battery, 81);
    expect(r.mayBeOld, isFalse);
    expect((r.name, r.build, r.track), (null, null, null));
  });

  test('the bytes follow the plan', () {
    expect(_report().encode(), _golden);
    expect(TraxReport.decode(_golden)!.seq, 7);
  });

  test('the position is the wire position, which a trail starts from', () {
    final r = TraxReport.decode(_golden)!;
    expect((lat: r.lat, lon: r.lon), wirePosition(36.4570, -116.8660));
  });

  test('an altitude or battery not known goes as -32768 or 255', () {
    final bytes = _report(altitude: null, battery: null).encode();
    expect(bytes.sublist(19, 22), [0x00, 0x80, 0xFF]);
    final r = TraxReport.decode(bytes)!;
    expect((r.altitude, r.battery), (null, null));
    final low = _report(altitude: -40000).encode();
    expect(TraxReport.decode(low)!.altitude, -32767);
    final over = Uint8List.fromList(_golden)..[21] = 101;
    expect(TraxReport.decode(over)!.battery, isNull);
  });

  test('heading and speed while moving, in the plan\'s steps', () {
    final bytes = _report(heading: 45, speed: 1.4).encode();
    expect(bytes.length, TraxReport.size);
    expect(bytes[9], 0x01, reason: 'moving');
    expect(bytes[17], 32, reason: '45 degrees in 1/256 turns');
    expect(bytes[18], 3, reason: '1.4 m/s in 0.5 m/s steps');
    final r = TraxReport.decode(bytes)!;
    expect(r.heading, 45);
    expect(r.speed, 1.5);
    expect(r.stillFor, isNull);

    final round = TraxReport.decode(_report(heading: 359.9).encode())!;
    expect(round.heading, 0, reason: 'a whole turn is north again');
    expect(TraxReport.decode(_report(speed: 200).encode())!.speed, 127.5);
  });

  test('not moving: the minutes since the last move, in byte 18', () {
    final bytes = _report(stillFor: const Duration(minutes: 80)).encode();
    expect(bytes[9], 0x02, reason: 'still');
    expect(bytes[18], 80);
    final r = TraxReport.decode(bytes)!;
    expect(r.stillFor, const Duration(minutes: 80));
    expect((r.speed, r.heading), (null, null));
    final long = _report(stillFor: const Duration(hours: 9)).encode();
    expect(TraxReport.decode(long)!.stillFor, const Duration(minutes: 255));
    final none = TraxReport.decode(_golden)!;
    expect((none.heading, none.speed, none.stillFor), (null, null, null));
  });

  test('edges of the world read back', () {
    for (final (lat, lon) in [
      (90.0, 179.99999),
      (-90.0, -180.0),
      (0.0, 0.0),
      (-33.86882, 151.20929),
    ]) {
      final r = TraxReport.decode(_report(lat: lat, lon: lon).encode())!;
      expect(r.lat, closeTo(lat, 1.1e-5), reason: '$lat');
      expect((r.lon - lon + 180) % 360 - 180, closeTo(0, 1.1e-5));
    }
    final wrapped = TraxReport.decode(_report(lon: 180).encode())!;
    expect(wrapped.lon, -180);
  });

  test('may be old reads back', () {
    final bytes = _report(mayBeOld: true).encode();
    expect(bytes[9], 0x04);
    expect(TraxReport.decode(bytes)!.mayBeOld, isTrue);
  });

  test('the icon is byte 22; one this build doesn\'t know is the hiker', () {
    for (final icon in TraxMapIcon.values) {
      final bytes = _report(icon: icon).encode();
      expect(bytes[22], icon.index);
      expect(TraxReport.decode(bytes)!.icon, icon);
    }
    final bytes = Uint8List.fromList(_golden)..[22] = 0x17;
    expect(TraxReport.decode(bytes)!.icon, TraxMapIcon.hike);
  });

  test('spare flag bits set by a later MeshTrax change nothing', () {
    final bytes = _report(stillFor: const Duration(minutes: 3)).encode()
      ..[9] |= 0xF8;
    final r = TraxReport.decode(bytes)!;
    expect(r.stillFor, const Duration(minutes: 3));
    expect(r.mayBeOld, isFalse);
  });

  test('the name and build go after the fixed bytes, as meshtrax.proto '
      'says', () {
    final bytes = _report(name: 'Trail Radio', build: 252).encode();
    expect(bytes.sublist(0, TraxReport.size), _golden);
    expect(bytes.sublist(TraxReport.size), [
      0x0A, 11, ...utf8.encode('Trail Radio'), //
      0x10, 0xFC, 0x01,
    ]);
    final r = TraxReport.decode(bytes)!;
    expect((r.name, r.build), ('Trail Radio', 252));
  });

  test('a long name is cut at a character boundary to 20 bytes', () {
    final r = TraxReport.decode(_report(name: 'Ana 🏜️🏜️🏜️🏜️🏜️').encode())!;
    expect(utf8.encode(r.name!).length, lessThanOrEqualTo(20));
    expect(r.name, 'Ana 🏜️🏜️');
    final ascii = TraxReport.decode(_report(name: 'A' * 30).encode())!;
    expect(ascii.name, 'A' * 20);
  });

  test('an empty name sends nothing', () {
    expect(_report(name: '').encode(), _golden);
  });

  test('a track reads back from the report\'s position, beside the name', () {
    final bytes = _report(name: 'Cy', track: _track).encode();
    final block = _track.encode(wirePosition(36.4570, -116.8660));
    expect(bytes.sublist(TraxReport.size), [
      0x0A, 2, 0x43, 0x79, //
      0x1A, block.length, ...block,
    ]);
    final read = TraxReport.decode(bytes)!;
    expect(read.name, 'Cy');
    final points = read.track!.pieces.single.points;
    expect(points, hasLength(2));
    expect(
      metresBetween(points.last, _track.pieces.single.points.last),
      lessThan(6),
    );
  });

  test('the room a track has: 131 bytes alone, less beside a name and a '
      'build, and no more fits', () {
    expect(TraxReport.trackRoom(), 131);
    expect(TraxReport.trackRoom(name: 'Trail Radio', build: 252), 116);
    for (final (name, build) in [
      (null, null),
      ('Trail Radio', 252),
      ('A' * 20, 2242),
      ('Ana', null),
      ('Cy', null),
    ]) {
      int size(int track) =>
          TraxReport.size +
          TraxReportGrowth(
            name: name ?? '',
            build: build ?? 0,
            track: List.filled(track, 1),
          ).encode().length;
      final room = TraxReport.trackRoom(name: name, build: build);
      expect(size(room), lessThanOrEqualTo(TraxReport.maxSize), reason: name);
      expect(size(room + 1), greaterThan(TraxReport.maxSize), reason: name);
    }
  });

  test('fields from the future after the fixed bytes are skipped', () {
    final bytes = Uint8List.fromList([
      ..._report(name: 'Cy').encode(),
      0x78, 0x2A, // field 15, varint
      0xA2, 0x01, 0x02, 0xFF, 0xFF, // field 20, bytes
      0xAD, 0x01, 1, 2, 3, 4, // field 21, 32-bit
      0xB1, 0x01, 1, 2, 3, 4, 5, 6, 7, 8, // field 22, 64-bit
    ]);
    final r = TraxReport.decode(bytes)!;
    expect(r.name, 'Cy');
    expect(r.altitude, -86);
  });

  test('anything else is null, never an exception', () {
    final good = _report(name: 'Cy', track: _track).encode();
    expect(TraxReport.decode(good.sublist(0, 22)), isNull);
    expect(TraxReport.decode(good.sublist(0, good.length - 1)), isNull);
    expect(TraxReport.decode(Uint8List(0)), isNull);
    for (final first in [0x11, 0x12, 0x22, 0x31, 0x20]) {
      expect(
        TraxReport.decode(Uint8List.fromList([first, ...good.skip(1)])),
        isNull,
        reason: first.toRadixString(16),
      );
    }
    // A tail that doesn't parse.
    final tail = Uint8List.fromList([..._golden, 0xA2, 0x01]);
    expect(TraxReport.decode(tail), isNull);
    // A track with a byte after its points.
    final block = _track.encode(wirePosition(36.4570, -116.8660));
    final long = Uint8List.fromList([
      ..._golden,
      0x1A, block.length + 1, ...block, 0, //
    ]);
    expect(TraxReport.decode(long), isNull);
    final random = Random(3);
    for (var n = 0; n < 2000; n++) {
      final junk = Uint8List.fromList(
        List.generate(random.nextInt(60), (_) => random.nextInt(256)),
      );
      if (junk.isNotEmpty) junk[0] = 0x21;
      TraxReport.decode(junk);
    }
  });
}
