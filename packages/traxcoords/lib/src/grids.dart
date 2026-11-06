import 'dart:math' as math;

import 'utm.dart';

const _columnSets = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];
const _rowSets = ['ABCDEFGHJKLMNPQRSTUV', 'FGHJKLMNPQRSTUVABCDE'];

/// MGRS (the US National Grid in the US), e.g. `10S EG 95484 93234`, to
/// [digits] per axis: 5 is 1 m, 4 is 10 m, 3 is 100 m.
String? toMgrs(double lat, double lon, {int digits = 5}) {
  final utm = toUtm(lat, lon);
  if (utm == null) return null;
  final column = (utm.easting / 100000).floor();
  final row = (utm.northing / 100000).floor() % 20;
  final square =
      _columnSets[(utm.zone - 1) % 3][column - 1] +
      _rowSets[(utm.zone - 1) % 2][row];
  String part(double metres) =>
      (metres % 100000).floor().toString().padLeft(5, '0').substring(0, digits);
  return '${utm.zone}${utm.band} $square '
      '${part(utm.easting)} ${part(utm.northing)}';
}

/// An MGRS reference back to a position: the middle of the square its
/// digits describe ("10SEG9593" is the 1 km square's middle).
LatLon? fromMgrs(int zone, String band, String square, String digits) {
  if (digits.length.isOdd || digits.length > 10) return null;
  final columnIndex = _columnSets[(zone - 1) % 3].indexOf(square[0]);
  final rowIndex = _rowSets[(zone - 1) % 2].indexOf(square[1]);
  if (columnIndex < 0 || rowIndex < 0) return null;
  final half = digits.length ~/ 2;
  final scale = math.pow(10, 5 - half).toDouble();
  final e = half == 0 ? 0.0 : int.parse(digits.substring(0, half)) * scale;
  final n = half == 0 ? 0.0 : int.parse(digits.substring(half)) * scale;
  final middle = (half == 0 ? 100000.0 : scale) / 2;
  final easting = (columnIndex + 1) * 100000 + e + middle;

  // The row letters repeat every 2,000 km: pick the repeat inside the band.
  final bandIndex = bandLetters.indexOf(band);
  final bandSouth = bandIndex * 8 - 80.0;
  final lon0 = (zone - 1) * 6 - 180 + 3.0;
  final bandFloor = toUtm(bandSouth, lon0, zone: zone)!.northing;
  var northing = rowIndex * 100000 + n + middle;
  while (northing < bandFloor - 100000) {
    northing += 2000000;
  }
  return fromUtm(zone, band, easting, northing);
}

/// The Maidenhead grid locator, 6 characters (about 4.6 × 3.5 km).
String toMaidenhead(double lat, double lon) {
  final x = lon + 180;
  final y = lat + 90;
  return String.fromCharCodes([
    65 + (x / 20).floor().clamp(0, 17),
    65 + (y / 10).floor().clamp(0, 17),
    48 + (x % 20 / 2).floor(),
    48 + (y % 10).floor(),
    97 + (x % 2 * 12).floor(),
    97 + (y % 1 * 24).floor(),
  ]);
}

/// A 2, 4, 6 or 8 character locator back to the middle of its square.
LatLon? fromMaidenhead(String locator) {
  final s = locator.trim();
  if (!RegExp(
    r'^[A-Ra-r]{2}([0-9]{2}([A-Xa-x]{2}([0-9]{2})?)?)?$',
  ).hasMatch(s)) {
    return null;
  }
  final u = s.toUpperCase();
  var lon = -180.0 + (u.codeUnitAt(0) - 65) * 20;
  var lat = -90.0 + (u.codeUnitAt(1) - 65) * 10;
  var w = 20.0, h = 10.0;
  if (u.length >= 4) {
    w = 2;
    h = 1;
    lon += (u.codeUnitAt(2) - 48) * w;
    lat += (u.codeUnitAt(3) - 48) * h;
  }
  if (u.length >= 6) {
    w /= 24;
    h /= 24;
    lon += (u.codeUnitAt(4) - 65) * w;
    lat += (u.codeUnitAt(5) - 65) * h;
  }
  if (u.length == 8) {
    w /= 10;
    h /= 10;
    lon += (u.codeUnitAt(6) - 48) * w;
    lat += (u.codeUnitAt(7) - 48) * h;
  }
  return (lat: lat + h / 2, lon: lon + w / 2);
}

const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// The geohash, 9 characters (about 5 m).
String toGeohash(double lat, double lon, {int length = 9}) {
  final latRange = [-90.0, 90.0];
  final lonRange = [-180.0, 180.0];
  final out = StringBuffer();
  var bits = 0, value = 0, even = true;
  while (out.length < length) {
    final range = even ? lonRange : latRange;
    final v = even ? lon : lat;
    final mid = (range[0] + range[1]) / 2;
    value <<= 1;
    if (v >= mid) {
      value |= 1;
      range[0] = mid;
    } else {
      range[1] = mid;
    }
    even = !even;
    if (++bits == 5) {
      out.write(_base32[value]);
      bits = 0;
      value = 0;
    }
  }
  return out.toString();
}

/// A geohash back to the middle of its cell.
LatLon? fromGeohash(String hash) {
  final s = hash.trim().toLowerCase();
  if (s.isEmpty || s.length > 12) return null;
  final latRange = [-90.0, 90.0];
  final lonRange = [-180.0, 180.0];
  var even = true;
  for (final c in s.split('')) {
    final value = _base32.indexOf(c);
    if (value < 0) return null;
    for (var bit = 4; bit >= 0; bit--) {
      final range = even ? lonRange : latRange;
      final mid = (range[0] + range[1]) / 2;
      if ((value >> bit) & 1 == 1) {
        range[0] = mid;
      } else {
        range[1] = mid;
      }
      even = !even;
    }
  }
  return (
    lat: (latRange[0] + latRange[1]) / 2,
    lon: (lonRange[0] + lonRange[1]) / 2,
  );
}
