import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:traxcoords/traxcoords.dart';

/// reference_points.json comes from independent libraries (pyproj for UTM,
/// the GeoTrans-based mgrs package for MGRS), so these tests check the math
/// rather than repeat it.
void main() {
  final refs =
      (jsonDecode(File('test/reference_points.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  Matcher near(double v, [double tol = 1e-6]) => closeTo(v, tol);

  group('reference points', () {
    for (final r in refs) {
      final lat = (r['lat'] as num).toDouble();
      final lon = (r['lon'] as num).toDouble();
      final utm = r['utm'] as Map<String, dynamic>;
      test(r['name'], () {
        final u = toUtm(lat, lon)!;
        expect((u.zone, u.band), (utm['zone'], utm['band']));
        expect(u.easting, closeTo((utm['easting'] as num).toDouble(), 0.01));
        expect(u.northing, closeTo((utm['northing'] as num).toDouble(), 0.01));

        final back = fromUtm(u.zone, u.band, u.easting, u.northing);
        expect(back.lat, near(lat));
        expect(back.lon, near(lon));

        final mgrs = (r['mgrs'] as String).replaceFirst(RegExp(r'^0'), '');
        expect(toMgrs(lat, lon)!.replaceAll(' ', ''), mgrs);
        expect(toGeohash(lat, lon), r['geohash']);
        expect(toMaidenhead(lat, lon), r['maidenhead']);
      });
    }
  });

  group('reading what people type', () {
    const diablo = (lat: 37.8816, lon: -121.9142);
    void reads(String text, CoordFormat format, {double tol = 1e-4}) {
      final r = parseCoordinates(text);
      final match = r.where((x) => x.format == format);
      expect(match, isNotEmpty, reason: '$text read as $r');
      expect(match.first.position.lat, closeTo(diablo.lat, tol), reason: text);
      expect(match.first.position.lon, closeTo(diablo.lon, tol), reason: text);
    }

    test('decimal degrees', () {
      reads('37.8816, -121.9142', CoordFormat.decimalDegrees);
      reads('37.8816 -121.9142', CoordFormat.decimalDegrees);
      reads('37.8816N 121.9142W', CoordFormat.decimalDegrees);
      reads('N37.8816 W121.9142', CoordFormat.decimalDegrees);
      reads('121.9142 W, 37.8816 N', CoordFormat.decimalDegrees);
    });

    test('degrees and minutes', () {
      reads('37°52.896′N 121°54.852′W', CoordFormat.degreesMinutes);
      reads("37 52.896N 121 54.852W", CoordFormat.degreesMinutes);
      reads('N 37 52.896 W 121 54.852', CoordFormat.degreesMinutes);
      reads('37 52.896, -121 54.852', CoordFormat.degreesMinutes);
    });

    test('degrees, minutes and seconds', () {
      reads('37°52′53.8″N 121°54′51.1″W', CoordFormat.degreesMinutesSeconds);
      reads('37 52 53.8 N 121 54 51.1 W', CoordFormat.degreesMinutesSeconds);
      reads("37°52'53.8\"N 121°54'51.1\"W", CoordFormat.degreesMinutesSeconds);
    });

    test('UTM', () {
      reads('10S 595485 4193234', CoordFormat.utm);
      reads('10 S 595485 4193234', CoordFormat.utm);
      reads('10S 595485mE 4193234mN', CoordFormat.utm);
    });

    test('MGRS and USNG, at any precision', () {
      reads('10S EG 95484 93234', CoordFormat.mgrs);
      reads('10SEG9548493234', CoordFormat.mgrs);
      reads('10seg9548493234', CoordFormat.mgrs);
      reads('10S EG 955 932', CoordFormat.mgrs, tol: 1e-3);
      reads('10SEG9593', CoordFormat.mgrs, tol: 1e-2);
    });

    test('Maidenhead and geohash', () {
      reads('CM97bv', CoordFormat.maidenhead, tol: 0.042);
      reads('9q9r9b0u3', CoordFormat.geohash);
    });

    test('text that reads two ways gives both', () {
      final formats = parseCoordinates('cm97bv').map((r) => r.format);
      expect(
        formats,
        containsAll([CoordFormat.maidenhead, CoordFormat.geohash]),
      );
    });

    test('names and nonsense are not positions', () {
      for (final text in [
        '',
        'Mount Diablo',
        'Camp Bird Mine',
        '91, 10',
        '10, 181',
        '37 61.0 N 121 54 W',
        '37.88 N 121.91 N',
        '612 Main St',
        '10Z 595485 4193234',
        'custer',
      ]) {
        expect(parseCoordinates(text), isEmpty, reason: text);
      }
    });
  });

  group('writing positions', () {
    const p = (lat: 37.8816, lon: -121.9142);
    test('each format', () {
      expect(
        formatCoordinates(p, CoordFormat.decimalDegrees),
        '37.88160, -121.91420',
      );
      expect(
        formatCoordinates(p, CoordFormat.degreesMinutes),
        '37°52.896′N 121°54.852′W',
      );
      expect(
        formatCoordinates(p, CoordFormat.degreesMinutesSeconds),
        '37°52′53.8″N 121°54′51.1″W',
      );
      expect(formatCoordinates(p, CoordFormat.utm), '10S 595484 4193234');
      expect(formatCoordinates(p, CoordFormat.mgrs), '10S EG 95484 93234');
      expect(formatCoordinates(p, CoordFormat.maidenhead), 'CM97bv');
      expect(formatCoordinates(p, CoordFormat.geohash), '9q9r9b0u3');
    });

    test('what the app writes, it reads back', () {
      for (final r in refs) {
        final pos = (
          lat: (r['lat'] as num).toDouble(),
          lon: (r['lon'] as num).toDouble(),
        );
        for (final f in CoordFormat.values) {
          final text = formatCoordinates(pos, f)!;
          final read = parseCoordinates(text).where((x) => x.format == f);
          expect(read, isNotEmpty, reason: '$f $text');
          final tol = switch (f) {
            CoordFormat.maidenhead => 0.042,
            CoordFormat.decimalDegrees || CoordFormat.geohash => 1e-4,
            _ => 1e-4,
          };
          expect(
            read.first.position.lat,
            closeTo(pos.lat, tol),
            reason: '$f $text',
          );
          expect(
            read.first.position.lon,
            closeTo(pos.lon, tol),
            reason: '$f $text',
          );
        }
      }
    });

    test('southern and western positions', () {
      const sydney = (lat: -33.8688, lon: 151.2093);
      expect(
        formatCoordinates(sydney, CoordFormat.degreesMinutes),
        '33°52.128′S 151°12.558′E',
      );
    });
  });
}
