import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/cayenne_lpp.dart';

// What a MeshCore sensor sends: battery voltage on channel 1, environment
// sensors on channel 2+, the MCU temperature on channel 1 last, then zero
// padding from the AES block.
Uint8List _bytes(List<int> b) => Uint8List.fromList(b);

void main() {
  group('decode', () {
    test('a sensor reading, grouped by channel', () {
      final channels = CayenneLpp.parseByChannel(_bytes([
        0x01, 0x74, 0x01, 0x8D, // ch1 voltage 3.97 V
        0x02, 0x67, 0x00, 0xD7, // ch2 temperature 21.5 °C
        0x02, 0x68, 0x5B, //       ch2 humidity 45.5 %
        0x02, 0x73, 0x27, 0x94, // ch2 pressure 1013.2 hPa
        0x01, 0x67, 0x01, 0x36, // ch1 MCU temperature 31.0 °C
        0x00, 0x00, 0x00, //       padding
      ]));

      expect(channels, [
        {
          'channel': 1,
          'values': {'voltage': 3.97, 'temperature': 31.0},
        },
        {
          'channel': 2,
          'values': {'temperature': 21.5, 'humidity': 45.5, 'pressure': 1013.2},
        },
      ]);
    });

    test('GPS', () {
      final gps = CayenneLpp.parseByChannel(_bytes([
        0x01, 0x88, //
        0x05, 0x6D, 0xA1, // 355745 → 35.5745
        0xED, 0x61, 0x11, // −1220335 (24-bit two's complement) → -122.0335
        0x00, 0x27, 0x10, // 100.00 m
      ])).single['values']['gps'];

      expect(gps['latitude'], closeTo(35.5745, 1e-9));
      expect(gps['longitude'], closeTo(-122.0335, 1e-9));
      expect(gps['altitude'], 100.0);
    });

    test('a known-size type it does not show is stepped over', () {
      final channels = CayenneLpp.parseByChannel(_bytes([
        0x03, 0x71, 0, 1, 0, 2, 0, 3, // ch3 accelerometer (6 bytes)
        0x03, 0x74, 0x01, 0x2C, //       ch3 voltage 3.00 V
      ]));

      expect(channels.single['values'], {'voltage': 3.0});
    });

    test('an unknown type stops parsing but keeps what came before', () {
      final readings = CayenneLpp.parse(_bytes([
        0x01, 0x74, 0x01, 0x8D, //
        0x02, 0xEE, 0x12, 0x34, // unknown type 0xEE
        0x03, 0x67, 0x00, 0x10,
      ]));

      expect(readings.single['value'], 3.97);
    });

    test('a truncated reading keeps the earlier ones', () {
      final channels = CayenneLpp.parseByChannel(_bytes([
        0x01, 0x74, 0x01, 0x8D, //
        0x02, 0x67, 0x00, // temperature cut short
      ]));

      expect(channels.single['values'], {'voltage': 3.97});
    });
  });

  group('encodeDelta (subscription min_deltas)', () {
    test('matches the firmware example: battery 0.05 V, temperature 0.5 °C',
        () {
      expect(
        [
          ...CayenneLpp.encodeDelta(1, CayenneLpp.lppVoltage, 0.05),
          ...CayenneLpp.encodeDelta(2, CayenneLpp.lppTemperature, 0.5),
        ],
        [0x01, 0x74, 0x00, 0x05, 0x02, 0x67, 0x00, 0x05],
      );
    });

    test('humidity is 2 bytes ×10, as the sensor reads deltas', () {
      expect(CayenneLpp.encodeDelta(2, CayenneLpp.lppRelativeHumidity, 5),
          [0x02, 0x68, 0x00, 0x32]);
    });

    test('rounds instead of truncating', () {
      // 0.29 × 100 is 28.999… in floating point.
      expect(CayenneLpp.encodeDelta(1, CayenneLpp.lppVoltage, 0.29),
          [0x01, 0x74, 0x00, 29]);
    });

    test('4-byte and 1-byte types', () {
      expect(CayenneLpp.encodeDelta(4, CayenneLpp.lppDistance, 1.5),
          [0x04, 0x82, 0x00, 0x00, 0x05, 0xDC]);
      expect(CayenneLpp.encodeDelta(4, CayenneLpp.lppPercentage, 5),
          [0x04, 0x78, 0x05]);
    });

    test('refuses what the sensor cannot compare', () {
      expect(() => CayenneLpp.encodeDelta(1, CayenneLpp.lppGps, 1),
          throwsArgumentError);
      expect(() => CayenneLpp.encodeDelta(1, CayenneLpp.lppVoltage, 0),
          throwsArgumentError);
    });
  });
}
