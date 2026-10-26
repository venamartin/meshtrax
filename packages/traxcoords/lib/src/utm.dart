import 'dart:math' as math;

typedef LatLon = ({double lat, double lon});

/// A UTM position on WGS84.
typedef Utm = ({int zone, String band, double easting, double northing});

const _a = 6378137.0;
const _f = 1 / 298.257223563;
const _k0 = 0.9996;
const _falseEasting = 500000.0;
const _falseNorthing = 10000000.0;

const bandLetters = 'CDEFGHJKLMNPQRSTUVWX';

final _e = math.sqrt(_f * (2 - _f));
final _n = _f / (2 - _f);
final _bigA = () {
  final n2 = _n * _n;
  return _a / (1 + _n) * (1 + n2 / 4 + n2 * n2 / 64 + n2 * n2 * n2 / 256);
}();

// Krüger series to n⁶ (Karney 2011): accurate to well under a millimetre
// across a zone.
final _alpha = () {
  final n = _n, n2 = n * n, n3 = n2 * n, n4 = n3 * n, n5 = n4 * n, n6 = n5 * n;
  return [
    n / 2 -
        2 / 3 * n2 +
        5 / 16 * n3 +
        41 / 180 * n4 -
        127 / 288 * n5 +
        7891 / 37800 * n6,
    13 / 48 * n2 -
        3 / 5 * n3 +
        557 / 1440 * n4 +
        281 / 630 * n5 -
        1983433 / 1935360 * n6,
    61 / 240 * n3 - 103 / 140 * n4 + 15061 / 26880 * n5 + 167603 / 181440 * n6,
    49561 / 161280 * n4 - 179 / 168 * n5 + 6601661 / 7257600 * n6,
    34729 / 80640 * n5 - 3418889 / 1995840 * n6,
    212378941 / 319334400 * n6,
  ];
}();
final _beta = () {
  final n = _n, n2 = n * n, n3 = n2 * n, n4 = n3 * n, n5 = n4 * n, n6 = n5 * n;
  return [
    n / 2 -
        2 / 3 * n2 +
        37 / 96 * n3 -
        1 / 360 * n4 -
        81 / 512 * n5 +
        96199 / 604800 * n6,
    1 / 48 * n2 +
        1 / 15 * n3 -
        437 / 1440 * n4 +
        46 / 105 * n5 -
        1118711 / 3870720 * n6,
    17 / 480 * n3 - 37 / 840 * n4 - 209 / 4480 * n5 + 5569 / 90720 * n6,
    4397 / 161280 * n4 - 11 / 504 * n5 - 830251 / 7257600 * n6,
    4583 / 161280 * n5 - 108847 / 3991680 * n6,
    20648693 / 638668800 * n6,
  ];
}();

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
double _atanh(double x) => 0.5 * math.log((1 + x) / (1 - x));
double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));
double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// The UTM zone of a position, with Norway's and Svalbard's exceptions.
int utmZone(double lat, double lon) {
  var zone = ((lon + 180) / 6).floor() + 1;
  if (zone > 60) zone = 1;
  if (lat >= 56 && lat < 64 && lon >= 3 && lon < 12) zone = 32;
  if (lat >= 72 && lat < 84) {
    if (lon >= 0 && lon < 9) {
      zone = 31;
    } else if (lon >= 9 && lon < 21) {
      zone = 33;
    } else if (lon >= 21 && lon < 33) {
      zone = 35;
    } else if (lon >= 33 && lon < 42) {
      zone = 37;
    }
  }
  return zone;
}

/// The latitude band letter, or null outside UTM's 80°S–84°N.
String? utmBand(double lat) {
  if (lat < -80 || lat > 84) return null;
  return bandLetters[math.min(((lat + 80) / 8).floor(), 19)];
}

/// [lat]/[lon] in UTM, in its own zone or in [zone]. Null outside
/// 80°S–84°N (the polar regions use UPS, which this doesn't do).
Utm? toUtm(double lat, double lon, {int? zone}) {
  final band = utmBand(lat);
  if (band == null) return null;
  final z = zone ?? utmZone(lat, lon);
  final lon0 = _rad((z - 1) * 6 - 180 + 3);
  final phi = _rad(lat);
  final lambda = _rad(lon) - lon0;

  final tau = math.tan(phi);
  final sigma = _sinh(_e * _atanh(_e * tau / math.sqrt(1 + tau * tau)));
  final tauP =
      tau * math.sqrt(1 + sigma * sigma) - sigma * math.sqrt(1 + tau * tau);
  final xiP = math.atan2(tauP, math.cos(lambda));
  final etaP = _asinh(
    math.sin(lambda) / math.sqrt(tauP * tauP + math.pow(math.cos(lambda), 2)),
  );
  var xi = xiP, eta = etaP;
  for (var j = 1; j <= 6; j++) {
    xi += _alpha[j - 1] * math.sin(2 * j * xiP) * _cosh(2 * j * etaP);
    eta += _alpha[j - 1] * math.cos(2 * j * xiP) * _sinh(2 * j * etaP);
  }
  final easting = _k0 * _bigA * eta + _falseEasting;
  var northing = _k0 * _bigA * xi;
  if (lat < 0) northing += _falseNorthing;
  return (zone: z, band: band, easting: easting, northing: northing);
}

/// A UTM position back to latitude and longitude. Bands N–X are the
/// northern hemisphere.
LatLon fromUtm(int zone, String band, double easting, double northing) {
  final south = bandLetters.indexOf(band.toUpperCase()) < 10;
  final x = easting - _falseEasting;
  final y = south ? northing - _falseNorthing : northing;
  final eta = x / (_k0 * _bigA);
  final xi = y / (_k0 * _bigA);
  var xiP = xi, etaP = eta;
  for (var j = 1; j <= 6; j++) {
    xiP -= _beta[j - 1] * math.sin(2 * j * xi) * _cosh(2 * j * eta);
    etaP -= _beta[j - 1] * math.cos(2 * j * xi) * _sinh(2 * j * eta);
  }
  final sinhEtaP = _sinh(etaP);
  final sinXiP = math.sin(xiP);
  final cosXiP = math.cos(xiP);
  final tauP = sinXiP / math.sqrt(sinhEtaP * sinhEtaP + cosXiP * cosXiP);

  final e2 = _e * _e;
  var tau = tauP;
  for (var i = 0; i < 20; i++) {
    final sigma = _sinh(_e * _atanh(_e * tau / math.sqrt(1 + tau * tau)));
    final tauI =
        tau * math.sqrt(1 + sigma * sigma) - sigma * math.sqrt(1 + tau * tau);
    final delta =
        (tauP - tauI) /
        math.sqrt(1 + tauI * tauI) *
        (1 + (1 - e2) * tau * tau) /
        ((1 - e2) * math.sqrt(1 + tau * tau));
    tau += delta;
    if (delta.abs() < 1e-12) break;
  }
  final lon0 = (zone - 1) * 6 - 180 + 3;
  return (
    lat: _deg(math.atan(tau)),
    lon: _deg(math.atan2(sinhEtaP, cosXiP)) + lon0,
  );
}
