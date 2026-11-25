import 'dart:math' as math;

// Magnetic declination from the World Magnetic Model WMM2025 (NOAA NCEI
// and the British Geological Survey; public domain), as NOAA's
// GeomagnetismLibrary works it out.

/// The model's epoch, as a decimal year.
const _epoch = 2025.0;

/// The model is valid to this decimal year.
const magneticModelValidUntil = 2030.0;

/// The model's degree.
const _degree = 12;

/// The year as a decimal, as the model takes it.
double decimalYear(DateTime when) {
  final t = when.toUtc();
  final start = DateTime.utc(t.year), end = DateTime.utc(t.year + 1);
  return t.year +
      t.difference(start).inMicroseconds / end.difference(start).inMicroseconds;
}

/// The magnetic declination (degrees, east positive) at [lat], [lon]
/// (degrees), at sea level, on [when].
double magneticDeclination(double lat, double lon, DateTime when) =>
    declinationAt(lat, lon, decimalYear(when));

/// The declination at [year] (decimal) and [heightKm] above the WGS84
/// ellipsoid.
double declinationAt(
  double lat,
  double lon,
  double year, {
  double heightKm = 0,
}) {
  const a = 6378.137, f = 1 / 298.257223563, re = 6371.2;
  const e2 = f * (2 - f);
  final phi = lat * math.pi / 180, lambda = lon * math.pi / 180;
  final sinPhi = math.sin(phi);
  // Geodetic to geocentric.
  final rc = a / math.sqrt(1 - e2 * sinPhi * sinPhi);
  final xp = (rc + heightKm) * math.cos(phi);
  final zp = (rc * (1 - e2) + heightKm) * sinPhi;
  final r = math.sqrt(xp * xp + zp * zp);
  final phig = math.asin(zp / r);

  // Schmidt semi-normalised associated Legendre functions of sin(phig), and
  // their derivatives by latitude.
  const size = (_degree + 1) * (_degree + 2) ~/ 2;
  final p = List<double>.filled(size, 0), dp = List<double>.filled(size, 0);
  final x = math.sin(phig), z = math.cos(phig);
  p[0] = 1;
  for (var n = 1; n <= _degree; n++) {
    for (var m = 0; m <= n; m++) {
      final i = n * (n + 1) ~/ 2 + m;
      if (n == m) {
        final j = (n - 1) * n ~/ 2 + m - 1;
        p[i] = z * p[j];
        dp[i] = z * dp[j] + x * p[j];
      } else if (n == 1 || m > n - 2) {
        final j = (n - 1) * n ~/ 2 + m;
        p[i] = x * p[j];
        dp[i] = x * dp[j] - z * p[j];
      } else {
        final j1 = (n - 2) * (n - 1) ~/ 2 + m, j2 = (n - 1) * n ~/ 2 + m;
        final k = ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
        p[i] = x * p[j2] - k * p[j1];
        dp[i] = x * dp[j2] - z * p[j2] - k * dp[j1];
      }
    }
  }
  final norm = List<double>.filled(size, 0)..[0] = 1;
  for (var n = 1; n <= _degree; n++) {
    final i0 = n * (n + 1) ~/ 2;
    norm[i0] = norm[(n - 1) * n ~/ 2] * (2 * n - 1) / n;
    for (var m = 1; m <= n; m++) {
      norm[i0 + m] =
          norm[i0 + m - 1] *
          math.sqrt((n - m + 1) * (m == 1 ? 2 : 1) / (n + m));
    }
  }
  for (var i = 1; i < size; i++) {
    p[i] *= norm[i];
    dp[i] *= -norm[i];
  }

  // The field in geocentric coordinates.
  final dt = year - _epoch;
  var bx = 0.0, by = 0.0, bz = 0.0;
  for (var n = 1; n <= _degree; n++) {
    final rr = math.pow(re / r, n + 2).toDouble();
    for (var m = 0; m <= n; m++) {
      final i = n * (n + 1) ~/ 2 + m, c = 4 * (i - 1);
      final g = _coefficients[c] + dt * _coefficients[c + 2];
      final h = _coefficients[c + 1] + dt * _coefficients[c + 3];
      final cos = math.cos(m * lambda), sin = math.sin(m * lambda);
      bz -= rr * (g * cos + h * sin) * (n + 1) * p[i];
      by += rr * (g * sin - h * cos) * m * p[i];
      bx -= rr * (g * cos + h * sin) * dp[i];
    }
  }
  by /= math.cos(phig);
  // Back to geodetic: north and east.
  final psi = phig - phi;
  final north = bx * math.cos(psi) - bz * math.sin(psi);
  return math.atan2(by, north) * 180 / math.pi;
}

/// WMM2025 (WMM.COF of 2024-11-13): g, h in nT and their change a year,
/// for n 1 to 12 and m 0 to n.
const _coefficients = <double>[
  -29351.8, 0.0, 12.0, 0.0, // 1 0
  -1410.8, 4545.4, 9.7, -21.5, // 1 1
  -2556.6, 0.0, -11.6, 0.0, // 2 0
  2951.1, -3133.6, -5.2, -27.7, // 2 1
  1649.3, -815.1, -8.0, -12.1, // 2 2
  1361.0, 0.0, -1.3, 0.0, // 3 0
  -2404.1, -56.6, -4.2, 4.0, // 3 1
  1243.8, 237.5, 0.4, -0.3, // 3 2
  453.6, -549.5, -15.6, -4.1, // 3 3
  895.0, 0.0, -1.6, 0.0, // 4 0
  799.5, 278.6, -2.4, -1.1, // 4 1
  55.7, -133.9, -6.0, 4.1, // 4 2
  -281.1, 212.0, 5.6, 1.6, // 4 3
  12.1, -375.6, -7.0, -4.4, // 4 4
  -233.2, 0.0, 0.6, 0.0, // 5 0
  368.9, 45.4, 1.4, -0.5, // 5 1
  187.2, 220.2, 0.0, 2.2, // 5 2
  -138.7, -122.9, 0.6, 0.4, // 5 3
  -142.0, 43.0, 2.2, 1.7, // 5 4
  20.9, 106.1, 0.9, 1.9, // 5 5
  64.4, 0.0, -0.2, 0.0, // 6 0
  63.8, -18.4, -0.4, 0.3, // 6 1
  76.9, 16.8, 0.9, -1.6, // 6 2
  -115.7, 48.8, 1.2, -0.4, // 6 3
  -40.9, -59.8, -0.9, 0.9, // 6 4
  14.9, 10.9, 0.3, 0.7, // 6 5
  -60.7, 72.7, 0.9, 0.9, // 6 6
  79.5, 0.0, -0.0, 0.0, // 7 0
  -77.0, -48.9, -0.1, 0.6, // 7 1
  -8.8, -14.4, -0.1, 0.5, // 7 2
  59.3, -1.0, 0.5, -0.8, // 7 3
  15.8, 23.4, -0.1, 0.0, // 7 4
  2.5, -7.4, -0.8, -1.0, // 7 5
  -11.1, -25.1, -0.8, 0.6, // 7 6
  14.2, -2.3, 0.8, -0.2, // 7 7
  23.2, 0.0, -0.1, 0.0, // 8 0
  10.8, 7.1, 0.2, -0.2, // 8 1
  -17.5, -12.6, 0.0, 0.5, // 8 2
  2.0, 11.4, 0.5, -0.4, // 8 3
  -21.7, -9.7, -0.1, 0.4, // 8 4
  16.9, 12.7, 0.3, -0.5, // 8 5
  15.0, 0.7, 0.2, -0.6, // 8 6
  -16.8, -5.2, -0.0, 0.3, // 8 7
  0.9, 3.9, 0.2, 0.2, // 8 8
  4.6, 0.0, -0.0, 0.0, // 9 0
  7.8, -24.8, -0.1, -0.3, // 9 1
  3.0, 12.2, 0.1, 0.3, // 9 2
  -0.2, 8.3, 0.3, -0.3, // 9 3
  -2.5, -3.3, -0.3, 0.3, // 9 4
  -13.1, -5.2, 0.0, 0.2, // 9 5
  2.4, 7.2, 0.3, -0.1, // 9 6
  8.6, -0.6, -0.1, -0.2, // 9 7
  -8.7, 0.8, 0.1, 0.4, // 9 8
  -12.9, 10.0, -0.1, 0.1, // 9 9
  -1.3, 0.0, 0.1, 0.0, // 10 0
  -6.4, 3.3, 0.0, 0.0, // 10 1
  0.2, 0.0, 0.1, -0.0, // 10 2
  2.0, 2.4, 0.1, -0.2, // 10 3
  -1.0, 5.3, -0.0, 0.1, // 10 4
  -0.6, -9.1, -0.3, -0.1, // 10 5
  -0.9, 0.4, 0.0, 0.1, // 10 6
  1.5, -4.2, -0.1, 0.0, // 10 7
  0.9, -3.8, -0.1, -0.1, // 10 8
  -2.7, 0.9, -0.0, 0.2, // 10 9
  -3.9, -9.1, -0.0, -0.0, // 10 10
  2.9, 0.0, 0.0, 0.0, // 11 0
  -1.5, 0.0, -0.0, -0.0, // 11 1
  -2.5, 2.9, 0.0, 0.1, // 11 2
  2.4, -0.6, 0.0, -0.0, // 11 3
  -0.6, 0.2, 0.0, 0.1, // 11 4
  -0.1, 0.5, -0.1, -0.0, // 11 5
  -0.6, -0.3, 0.0, -0.0, // 11 6
  -0.1, -1.2, -0.0, 0.1, // 11 7
  1.1, -1.7, -0.1, -0.0, // 11 8
  -1.0, -2.9, -0.1, 0.0, // 11 9
  -0.2, -1.8, -0.1, 0.0, // 11 10
  2.6, -2.3, -0.1, 0.0, // 11 11
  -2.0, 0.0, 0.0, 0.0, // 12 0
  -0.2, -1.3, 0.0, -0.0, // 12 1
  0.3, 0.7, -0.0, 0.0, // 12 2
  1.2, 1.0, -0.0, -0.1, // 12 3
  -1.3, -1.4, -0.0, 0.1, // 12 4
  0.6, -0.0, -0.0, -0.0, // 12 5
  0.6, 0.6, 0.1, -0.0, // 12 6
  0.5, -0.1, -0.0, -0.0, // 12 7
  -0.1, 0.8, 0.0, 0.0, // 12 8
  -0.4, 0.1, 0.0, -0.0, // 12 9
  -0.2, -1.0, -0.1, -0.0, // 12 10
  -1.3, 0.1, -0.0, 0.0, // 12 11
  -0.7, 0.2, -0.1, -0.1, // 12 12
];
