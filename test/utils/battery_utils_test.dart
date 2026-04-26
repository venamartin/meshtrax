import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/battery_utils.dart';

void main() {
  group('battery utils', () {
    test('nmc range maps 3.0V to 0% and 4.2V to 100%', () {
      expect(estimateBatteryPercentFromVolts(3.0, 'nmc'), 0);
      expect(estimateBatteryPercentFromVolts(4.2, 'nmc'), 100);
    });

    test('lifepo4 range maps 2.6V to 0% and 3.65V to 100%', () {
      expect(estimateBatteryPercentFromVolts(2.6, 'lifepo4'), 0);
      expect(estimateBatteryPercentFromVolts(3.65, 'lifepo4'), 100);
    });

    test('unknown chemistry falls back to nmc mapping', () {
      expect(
        estimateBatteryPercentFromMillivolts(3600, 'unknown'),
        estimateBatteryPercentFromMillivolts(3600, 'nmc'),
      );
    });
  });
}
