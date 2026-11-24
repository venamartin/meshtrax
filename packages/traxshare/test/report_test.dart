import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxshare/traxshare.dart';

TraxReport _report({
  int seq = 7,
  double lat = 36.4570,
  double lon = -116.8660,
  int? altitude = -86,
  Duration? fixAge = const Duration(seconds: 42),
  int? battery = 81,
  bool mayBeOld = false,
  bool requester = true,
  String? name,
  double? heading,
  double? speed,
  Duration? stillFor,
}) => TraxReport(
  seq: seq,
  senderPrefix: Uint8List.fromList([0xB4, 0xE1, 0x02, 0x9C]),
  session: 0xA1B2,
  sentAt: DateTime.utc(2026, 11, 21, 18, 30, 5),
  lat: lat,
  lon: lon,
  altitude: altitude,
  fixAge: fixAge,
  battery: battery,
  mayBeOld: mayBeOld,
  requester: requester,
  name: name,
  heading: heading,
  speed: speed,
  stillFor: stillFor,
);

void main() {
  test('a report without a name is 29 bytes and reads back', () {
    final bytes = _report().encode();
    expect(bytes.length, TraxReport.size);
    final r = TraxReport.decode(bytes)!;
    expect(r.seq, 7);
    expect(r.senderPrefix, [0xB4, 0xE1, 0x02, 0x9C]);
    expect(r.session, 0xA1B2);
    expect(r.sentAt, DateTime.utc(2026, 11, 21, 18, 30, 5));
    expect(r.lat, closeTo(36.4570, 1e-9));
    expect(r.lon, closeTo(-116.8660, 1e-9));
    expect(r.altitude, -86);
    expect(r.fixAge, const Duration(seconds: 42));
    expect(r.battery, 81);
    expect(r.mayBeOld, isFalse);
    expect(r.requester, isTrue);
    expect(r.name, isNull);
  });

  test('the bytes follow the plan', () {
    final bytes = _report().encode();
    expect(bytes.sublist(0, 14), [
      0x12, // version 1, REPORT
      7, // seq
      0xB4, 0xE1, 0x02, 0x9C, // sender prefix
      0xB2, 0xA1, // session
      0x2D, 0xE3, 0x01, 0x6B, // sent at, 1795285805
      0x6C, 0x00, // altitude, fix age, requester, battery
    ]);
    // lat_u << 31 | lon_u << 5, little-endian.
    final latU = 12645700, lonU = 6313400;
    var position = BigInt.from(latU) << 31 | BigInt.from(lonU) << 5;
    for (var i = 14; i < 21; i++) {
      expect(bytes[i], (position & BigInt.from(0xFF)).toInt(), reason: '$i');
      position >>= 8;
    }
    expect(bytes.sublist(21), [42, 0, 0, 0, 0xAA, 0xFF, 81, 0]);
  });

  test('fields left out are clear in the mask and sent as 0', () {
    final bytes = _report(
      altitude: null,
      fixAge: null,
      battery: null,
      requester: false,
    ).encode();
    expect(bytes[12] | bytes[13] << 8, 0);
    expect(bytes.sublist(21), List.filled(8, 0));
    final r = TraxReport.decode(bytes)!;
    expect(r.altitude, isNull);
    expect(r.fixAge, isNull);
    expect(r.battery, isNull);
  });

  test('heading and speed while moving, in the plan\'s steps', () {
    final bytes = _report(heading: 45, speed: 1.4).encode();
    expect(bytes.length, TraxReport.size);
    // Heading, speed and moving, beside altitude, fix age, requester and
    // battery.
    expect(bytes[12], 0x7F);
    expect(bytes[23], 32, reason: '45 degrees in 1/256 turns');
    expect(bytes[24], 3, reason: '1.4 m/s in 0.5 m/s steps');
    final r = TraxReport.decode(bytes)!;
    expect(r.heading, 45);
    expect(r.speed, 1.5);
    expect(r.stillFor, isNull);

    final round = TraxReport.decode(_report(heading: 359.9).encode())!;
    expect(round.heading, 0, reason: 'a whole turn is north again');
    expect(TraxReport.decode(_report(speed: 200).encode())!.speed, 127.5);
  });

  test('not moving: the minutes since the last move, in the speed byte', () {
    final bytes = _report(stillFor: const Duration(minutes: 80)).encode();
    expect(bytes[13] & 0x10, 0x10, reason: 'mask bit 12');
    expect(bytes[12] & 0x13, 0, reason: 'no heading, speed or moving');
    expect(bytes[24], 80);
    final r = TraxReport.decode(bytes)!;
    expect(r.stillFor, const Duration(minutes: 80));
    expect(r.speed, isNull);
    expect(r.heading, isNull);
    final long = _report(stillFor: const Duration(hours: 9)).encode();
    expect(TraxReport.decode(long)!.stillFor, const Duration(minutes: 255));
  });

  test('edges of the world read back', () {
    for (final (lat, lon) in [
      (90.0, 179.99999),
      (-90.0, -180.0),
      (0.0, 0.0),
      (-33.86882, 151.20929),
    ]) {
      final r = TraxReport.decode(_report(lat: lat, lon: lon).encode())!;
      expect(r.lat, closeTo(lat, 6e-6), reason: '$lat');
      expect(r.lon, closeTo(lon, 6e-6), reason: '$lon');
    }
    final wrapped = TraxReport.decode(_report(lon: 180).encode())!;
    expect(wrapped.lon, closeTo(-180, 1e-9));
  });

  test('a fix age of 18 hours or more is random bytes and may be old', () {
    final bytes = _report(
      fixAge: const Duration(hours: 20),
    ).encode(random: Random(1));
    final mask = bytes[12] | bytes[13] << 8;
    expect(mask & 1 << 3, 0);
    expect(mask & 1 << 11, isNot(0));
    final r = TraxReport.decode(bytes)!;
    expect(r.fixAge, isNull);
    expect(r.mayBeOld, isTrue);
    final again = _report(
      fixAge: const Duration(hours: 20),
    ).encode(random: Random(2));
    expect(again.sublist(21, 23), isNot(bytes.sublist(21, 23)));
  });

  test('may be old reads back', () {
    expect(
      TraxReport.decode(_report(mayBeOld: true).encode())!.mayBeOld,
      isTrue,
    );
  });

  test('the name goes in an extension block', () {
    final bytes = _report(name: 'Trail Radio').encode();
    expect(bytes.length, TraxReport.size + 3 + 11);
    expect(bytes[13] & 0x80, 0x80);
    expect(bytes.sublist(29, 32), [13, 1, 11]);
    expect(TraxReport.decode(bytes)!.name, 'Trail Radio');
  });

  test('a long name is cut at a character boundary to 20 bytes', () {
    final r = TraxReport.decode(_report(name: 'Ana 🏜️🏜️🏜️🏜️🏜️').encode())!;
    expect(utf8.encode(r.name!).length, lessThanOrEqualTo(20));
    expect(r.name, 'Ana 🏜️🏜️');
    final ascii = TraxReport.decode(_report(name: 'A' * 30).encode())!;
    expect(ascii.name, 'A' * 20);
  });

  test('an empty name sends no extension block', () {
    expect(_report(name: '').encode().length, TraxReport.size);
  });

  test('unknown extension tags are skipped', () {
    final bytes = Uint8List.fromList([
      ..._report().encode(),
      9, 7, 2, 0xAB, 0xCD, 1, 3, 0x42, 0x65, 0x6E, // tag 7, then the name
    ]);
    bytes[13] |= 0x80;
    expect(TraxReport.decode(bytes)!.name, 'Ben');
  });

  test('anything else is null, never an exception', () {
    final good = _report(name: 'Cy').encode();
    expect(TraxReport.decode(good.sublist(0, 28)), isNull);
    expect(TraxReport.decode(Uint8List(0)), isNull);
    expect(
      TraxReport.decode(Uint8List.fromList([0x11, ...good.skip(1)])),
      isNull,
    );
    expect(
      TraxReport.decode(Uint8List.fromList([0x22, ...good.skip(1)])),
      isNull,
    );
    final pastEnd = Uint8List.fromList(good)..[29] = 200;
    expect(TraxReport.decode(pastEnd)!.name, isNull);
    final itemPastEnd = Uint8List.fromList(good)..[31] = 9;
    expect(TraxReport.decode(itemPastEnd)!.name, isNull);
    final badLat = Uint8List.fromList(good)..[20] = 0xFF;
    expect(TraxReport.decode(badLat), isNull);
    final random = Random(3);
    for (var n = 0; n < 2000; n++) {
      final junk = Uint8List.fromList(
        List.generate(random.nextInt(60), (_) => random.nextInt(256)),
      );
      if (junk.isNotEmpty) junk[0] = 0x12;
      TraxReport.decode(junk);
    }
  });
}
