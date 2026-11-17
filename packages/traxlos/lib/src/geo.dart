import 'dart:math' as math;

/// A WGS84 position in degrees.
class Geo {
  final double lat;
  final double lon;

  const Geo(this.lat, this.lon);

  @override
  bool operator ==(Object other) =>
      other is Geo && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() =>
      'Geo(${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})';
}

/// Mean earth radius (IUGG), metres.
const earthRadiusM = 6371008.8;

/// The zoom whose tiles hold every contour line.
const tileZoom = 13;

/// Units across one z13 tile: positions are kept in "world units", the z13
/// tile grid at 4096 units per tile, so tile coordinates add up exactly.
const tileUnits = 4096;

/// World units across the whole Web Mercator square.
const worldUnits = (1 << tileZoom) * tileUnits * 1.0;

const _deg = math.pi / 180;

double worldX(double lon) => (lon + 180) / 360 * worldUnits;

double worldY(double lat) {
  final s = math.sin(lat.clamp(-85.05, 85.05) * _deg);
  return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * worldUnits;
}

Geo fromWorld(double x, double y) {
  final n = math.pi - 2 * math.pi * y / worldUnits;
  final e = math.exp(n);
  return Geo(math.atan((e - 1 / e) / 2) / _deg, x / worldUnits * 360 - 180);
}

/// Ground metres per world unit at world row [y] (the Mercator scale).
double metresPerUnit(double y) {
  final psi = math.pi * (1 - 2 * y / worldUnits);
  final e = math.exp(psi);
  return 2 * math.pi * earthRadiusM / worldUnits / ((e + 1 / e) / 2);
}

double distanceM(Geo a, Geo b) {
  final p1 = a.lat * _deg, p2 = b.lat * _deg;
  final dp = p2 - p1, dl = (b.lon - a.lon) * _deg;
  final s1 = math.sin(dp / 2), s2 = math.sin(dl / 2);
  final h = s1 * s1 + math.cos(p1) * math.cos(p2) * s2 * s2;
  return 2 * earthRadiusM * math.asin(math.min(1.0, math.sqrt(h)));
}

/// The point [f] of the way from [a] to [b] on the great circle.
Geo interpolate(Geo a, Geo b, double f) {
  final d = distanceM(a, b) / earthRadiusM;
  if (d < 1e-12) return a;
  final p1 = a.lat * _deg, l1 = a.lon * _deg;
  final p2 = b.lat * _deg, l2 = b.lon * _deg;
  final s = math.sin(d);
  final ka = math.sin((1 - f) * d) / s, kb = math.sin(f * d) / s;
  final x = ka * math.cos(p1) * math.cos(l1) + kb * math.cos(p2) * math.cos(l2);
  final y = ka * math.cos(p1) * math.sin(l1) + kb * math.cos(p2) * math.sin(l2);
  final z = ka * math.sin(p1) + kb * math.sin(p2);
  return Geo(
    math.atan2(z, math.sqrt(x * x + y * y)) / _deg,
    math.atan2(y, x) / _deg,
  );
}

/// The point [distance] metres from [a] at [bearingDeg] (from north,
/// clockwise) on the great circle.
Geo destination(Geo a, double bearingDeg, double distance) {
  final p1 = a.lat * _deg, l1 = a.lon * _deg, br = bearingDeg * _deg;
  final d = distance / earthRadiusM;
  final p2 = math.asin(
    math.sin(p1) * math.cos(d) + math.cos(p1) * math.sin(d) * math.cos(br),
  );
  final l2 =
      l1 +
      math.atan2(
        math.sin(br) * math.sin(d) * math.cos(p1),
        math.cos(d) - math.sin(p1) * math.sin(p2),
      );
  return Geo(p2 / _deg, l2 / _deg);
}
