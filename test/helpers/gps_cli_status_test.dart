import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/gps_cli_status.dart';

// The replies are the firmware's own (CommonCLI.cpp, "gps", 1.18.0).
void main() {
  test('a fix with its satellite count', () {
    final status = GpsCliStatus.parse('on, active, fix, 7 sats')!;
    expect(status.powered, isTrue);
    expect(status.hasFix, isTrue);
    expect(status.satellites, 7);
  });

  test('"no fix" is not read as a fix', () {
    final status = GpsCliStatus.parse('on, active, no fix, 0 sats')!;
    expect(status.hasFix, isFalse);
    expect(status.satellites, 0);
  });

  test('off', () {
    final status = GpsCliStatus.parse('off')!;
    expect(status.powered, isFalse);
    expect(status.hasFix, isFalse);
    expect(status.satellites, isNull);
  });

  test('anything else is not a status', () {
    expect(GpsCliStatus.parse("Can't find GPS"), isNull);
    expect(GpsCliStatus.parse('Unknown command'), isNull);
    expect(GpsCliStatus.parse(''), isNull);
  });
}
