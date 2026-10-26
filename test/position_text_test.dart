import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/position_text.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:traxcoords/traxcoords.dart';

void main() {
  test('positions read in the chosen format, then decimal degrees', () {
    expect(positionLines(37.8816, -121.9142, CoordFormat.decimalDegrees), [
      '37.88160, -121.91420',
    ]);
    expect(positionLines(37.8816, -121.9142, CoordFormat.mgrs), [
      '10S EG 95484 93234',
      '37.88160, -121.91420',
    ]);
  });

  test('the setting keeps the chosen format and reads old settings', () {
    final s = AppSettings().copyWith(coordinateFormat: 'utm');
    final back = AppSettings.fromJson(s.toJson());
    expect(coordFormatOf(back), CoordFormat.utm);
    expect(coordFormatOf(AppSettings.fromJson({})), CoordFormat.decimalDegrees);
    expect(
      coordFormatOf(AppSettings().copyWith(coordinateFormat: 'nonsense')),
      CoordFormat.decimalDegrees,
    );
  });
}
