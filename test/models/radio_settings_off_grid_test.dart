import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/radio_settings.dart';

// Firmware refuses repeat on any frequency outside its list, and refuses the
// whole radio settings frame with it; the app used to send 869.000 on the
// 868 MHz band, which stock firmware has not allowed since 1.16.
void main() {
  const stock = [
    (lowerKhz: 433000, upperKhz: 433000),
    (lowerKhz: 869495, upperKhz: 869495),
    (lowerKhz: 918000, upperKhz: 918000),
  ];

  test('takes the radio\'s own frequency nearest the current one', () {
    expect(RadioSettings.offGridFrequencyMHz(869.618, allowed: stock), 869.495);
    expect(RadioSettings.offGridFrequencyMHz(910.525, allowed: stock), 918.0);
    expect(RadioSettings.offGridFrequencyMHz(433.650, allowed: stock), 433.0);
  });

  test('without a list, follows the firmware version', () {
    expect(
      RadioSettings.offGridFrequencyMHz(869.618, firmwareVerCode: 14),
      869.495,
    );
    expect(
      RadioSettings.offGridFrequencyMHz(869.618, firmwareVerCode: 11),
      869.0,
    );
    expect(RadioSettings.offGridFrequencyMHz(869.618), 869.495);
    expect(
      RadioSettings.offGridFrequencyMHz(910.525, firmwareVerCode: 11),
      918.0,
    );
  });

  test('a list overrides the version', () {
    expect(
      RadioSettings.offGridFrequencyMHz(
        869.618,
        allowed: const [(lowerKhz: 869000, upperKhz: 869000)],
        firmwareVerCode: 14,
      ),
      869.0,
    );
  });

  test('a range gives its lowest frequency', () {
    expect(
      RadioSettings.offGridFrequencyMHz(
        910.525,
        allowed: const [(lowerKhz: 902000, upperKhz: 928000)],
      ),
      902.0,
    );
  });

  test('the hidden 869 preset is a frequency stock firmware allows', () {
    final preset = RadioSettings.presets
        .firstWhere((p) => p.$1 == 'Off-Grid 869')
        .$2;
    expect(preset.frequencyHz, 869495);
  });
}
