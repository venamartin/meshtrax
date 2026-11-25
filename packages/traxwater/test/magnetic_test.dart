import 'package:test/test.dart';
import 'package:traxwater/src/magnetic.dart';

void main() {
  test("NOAA's WMM2025 test values", () {
    // WMM2025_TEST_VALUES.txt: year, height (km), latitude, longitude, and
    // the declination to 0.01°.
    const values = [
      (2025.0, 0.0, 80.0, 0.0, 1.28),
      (2025.0, 0.0, 0.0, 120.0, -0.16),
      (2025.0, 0.0, -80.0, 240.0, 68.78),
      (2025.0, 100.0, 80.0, 0.0, 0.85),
      (2025.0, 100.0, 0.0, 120.0, -0.15),
      (2025.0, 100.0, -80.0, 240.0, 68.21),
      (2027.5, 0.0, 80.0, 0.0, 2.59),
      (2027.5, 0.0, 0.0, 120.0, -0.24),
      (2027.5, 0.0, -80.0, 240.0, 68.49),
      (2027.5, 100.0, 80.0, 0.0, 2.16),
      (2027.5, 100.0, 0.0, 120.0, -0.23),
      (2027.5, 100.0, -80.0, 240.0, 67.93),
    ];
    for (final (year, height, lat, lon, declination) in values) {
      expect(
        declinationAt(lat, lon, year, heightKm: height),
        closeTo(declination, 0.006),
        reason: '$year $height km $lat $lon',
      );
    }
  });

  test('decimal years', () {
    expect(decimalYear(DateTime.utc(2025)), 2025.0);
    expect(decimalYear(DateTime.utc(2027, 7, 2, 12)), closeTo(2027.5, 1e-9));
  });
}
