import 'grids.dart';
import 'utm.dart';

enum CoordFormat {
  decimalDegrees,
  degreesMinutes,
  degreesMinutesSeconds,
  utm,
  mgrs,
  maidenhead,
  geohash,
}

/// One reading of typed text as a position. Text can read two ways
/// ("cm97bv" is a Maidenhead locator and a geohash), so parsing returns a
/// list.
class CoordReading {
  final CoordFormat format;
  final LatLon position;

  const CoordReading(this.format, this.position);

  @override
  String toString() => '$format ${position.lat}, ${position.lon}';
}

/// Every way [text] reads as a position, most likely first; empty when it
/// isn't one.
List<CoordReading> parseCoordinates(String text) {
  final s = text.trim();
  if (s.isEmpty) return const [];
  final out = <CoordReading>[];
  void add(CoordFormat f, LatLon? p) {
    if (p != null && p.lat.abs() <= 90 && p.lon.abs() <= 180) {
      out.add(CoordReading(f, p));
    }
  }

  final mgrs = RegExp(
    r'^(\d{1,2})\s*([C-HJ-NP-X])\s*([A-HJ-NP-Z][A-HJ-NP-V])\s*(\d*)\s*(\d*)$',
    caseSensitive: false,
  ).firstMatch(s);
  if (mgrs != null) {
    final zone = int.parse(mgrs[1]!);
    final digits = '${mgrs[4]}${mgrs[5]}';
    final split = mgrs[5]!.isEmpty
        ? digits
        : (mgrs[4]!.length == mgrs[5]!.length ? digits : null);
    if (zone >= 1 && zone <= 60 && split != null) {
      add(
        CoordFormat.mgrs,
        fromMgrs(zone, mgrs[2]!.toUpperCase(), mgrs[3]!.toUpperCase(), split),
      );
    }
  }

  final utm = RegExp(
    r'^(\d{1,2})\s*([C-HJ-NP-X])\s+(\d{6}(?:\.\d+)?)\s*m?\s*E?\s+(\d{1,7}(?:\.\d+)?)\s*m?\s*N?$',
    caseSensitive: false,
  ).firstMatch(s);
  if (utm != null) {
    final zone = int.parse(utm[1]!);
    if (zone >= 1 && zone <= 60) {
      add(
        CoordFormat.utm,
        fromUtm(
          zone,
          utm[2]!.toUpperCase(),
          double.parse(utm[3]!),
          double.parse(utm[4]!),
        ),
      );
    }
  }

  if (!s.contains(RegExp(r'\s'))) {
    add(CoordFormat.maidenhead, fromMaidenhead(s));
    // Letters-only geohashes look like words ("custer" is one), so they
    // need 8 characters; with a digit, 4 are enough.
    final hashLike = RegExp(
      r'^[0-9b-hjkmnp-z]{4,12}$',
      caseSensitive: false,
    ).hasMatch(s);
    if (hashLike && (s.contains(RegExp(r'\d')) || s.length >= 8)) {
      add(CoordFormat.geohash, fromGeohash(s));
    }
  }

  final degrees = _parseDegrees(s);
  if (degrees != null) add(degrees.$1, degrees.$2);
  return out;
}

/// Latitude and longitude in degrees, degrees and minutes, or degrees,
/// minutes and seconds, with signs or N/S/E/W before or after each.
(CoordFormat, LatLon)? _parseDegrees(String s) {
  if (RegExp(r'[^\d\s.+\-NSEWnsew°º˚′″"\x27,;:]').hasMatch(s)) return null;
  final tokens = RegExp(r'[NSEWnsew]|[-+]?\d+(?:\.\d+)?')
      .allMatches(s.replaceAll(RegExp(r'[°º˚′″"\x27,;:]'), ' '))
      .map((m) => m[0]!)
      .toList();
  return _fromGroups(tokens);
}

(CoordFormat, LatLon)? _fromGroups(List<String> tokens) {
  // Split the tokens into two coordinates: at hemisphere letters when there
  // are any, else in half.
  final letters = tokens.where((t) => RegExp(r'^[NSEWnsew]$').hasMatch(t));
  final parts = <(List<double>, String?)>[];
  if (letters.isEmpty) {
    final numbers = tokens.map(double.parse).toList();
    if (numbers.isEmpty || numbers.length.isOdd || numbers.length > 6) {
      return null;
    }
    final half = numbers.length ~/ 2;
    parts.add((numbers.sublist(0, half), null));
    parts.add((numbers.sublist(half), null));
  } else {
    if (letters.length != 2) return null;
    final lettersFirst = RegExp(r'^[NSEWnsew]$').hasMatch(tokens.first);
    var current = <double>[];
    String? hemisphere;
    for (final t in tokens) {
      final isLetter = RegExp(r'^[NSEWnsew]$').hasMatch(t);
      if (isLetter) {
        if (lettersFirst) {
          if (hemisphere != null) parts.add((current, hemisphere));
          current = [];
          hemisphere = t.toUpperCase();
        } else {
          parts.add((current, t.toUpperCase()));
          current = [];
        }
      } else {
        current.add(double.parse(t));
      }
    }
    if (lettersFirst) {
      parts.add((current, hemisphere));
    } else if (current.isNotEmpty) {
      return null;
    }
  }
  if (parts.length != 2) return null;
  final (a, b) = (parts[0], parts[1]);
  if (a.$1.length != b.$1.length || a.$1.isEmpty || a.$1.length > 3) {
    return null;
  }

  double? value((List<double>, String?) part) {
    final n = part.$1;
    if (n.length > 1 && (n[0] != n[0].truncateToDouble())) return null;
    for (final x in n.skip(1)) {
      if (x < 0 || x >= 60) return null;
    }
    if (n.length == 3 && n[1] != n[1].truncateToDouble()) return null;
    final sign = n[0] < 0 ? -1 : 1;
    var v = n[0].abs();
    if (n.length > 1) v += n[1] / 60;
    if (n.length > 2) v += n[2] / 3600;
    if (part.$2 == 'S' || part.$2 == 'W') return -v;
    return sign * v;
  }

  final first = value(a), second = value(b);
  if (first == null || second == null) return null;
  final swap = a.$2 == 'E' || a.$2 == 'W' || b.$2 == 'N' || b.$2 == 'S';
  if ((a.$2 != null && b.$2 != null) &&
      ((a.$2 == 'N' || a.$2 == 'S') == (b.$2 == 'N' || b.$2 == 'S'))) {
    return null;
  }
  final lat = swap ? second : first;
  final lon = swap ? first : second;
  if (lat.abs() > 90 || lon.abs() > 180) return null;
  final format = switch (a.$1.length) {
    1 => CoordFormat.decimalDegrees,
    2 => CoordFormat.degreesMinutes,
    _ => CoordFormat.degreesMinutesSeconds,
  };
  return (format, (lat: lat, lon: lon));
}

/// [position] written in [format], as the app shows it.
String? formatCoordinates(LatLon position, CoordFormat format) {
  final (:lat, :lon) = position;
  String hemi(double v, String pos, String neg) => v < 0 ? neg : pos;
  switch (format) {
    case CoordFormat.decimalDegrees:
      return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    case CoordFormat.degreesMinutes:
      String dm(double v, String pos, String neg) {
        var d = v.abs().floor();
        var m = (v.abs() - d) * 60;
        if (double.parse(m.toStringAsFixed(3)) >= 60) {
          d += 1;
          m = 0;
        }
        return '$d°${m.toStringAsFixed(3).padLeft(6, '0')}′${hemi(v, pos, neg)}';
      }
      return '${dm(lat, 'N', 'S')} ${dm(lon, 'E', 'W')}';
    case CoordFormat.degreesMinutesSeconds:
      String dms(double v, String pos, String neg) {
        final total = (v.abs() * 36000).round();
        final d = total ~/ 36000;
        final m = total % 36000 ~/ 600;
        final s = (total % 600) / 10;
        return '$d°${m.toString().padLeft(2, '0')}′'
            '${s.toStringAsFixed(1).padLeft(4, '0')}″${hemi(v, pos, neg)}';
      }
      return '${dms(lat, 'N', 'S')} ${dms(lon, 'E', 'W')}';
    case CoordFormat.utm:
      final u = toUtm(lat, lon);
      if (u == null) return null;
      return '${u.zone}${u.band} ${u.easting.floor()} ${u.northing.floor()}';
    case CoordFormat.mgrs:
      return toMgrs(lat, lon);
    case CoordFormat.maidenhead:
      return toMaidenhead(lat, lon);
    case CoordFormat.geohash:
      return toGeohash(lat, lon);
  }
}
