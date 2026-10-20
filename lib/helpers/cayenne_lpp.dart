import 'dart:typed_data';
import 'package:meshtrax/utils/app_logger.dart';

import '../connector/meshcore_protocol.dart';

class CayenneLpp {
  static const int lppDigitalInput = 0; // 1 byte
  static const int lppDigitalOutput = 1; // 1 byte
  static const int lppAnalogInput = 2; // 2 bytes, 0.01 signed
  static const int lppAnalogOutput = 3; // 2 bytes, 0.01 signed
  static const int lppGenericSensor = 100; // 4 bytes, unsigned
  static const int lppLuminosity = 101; // 2 bytes, 1 lux unsigned
  static const int lppPresence = 102; // 1 byte, bool
  static const int lppTemperature = 103; // 2 bytes, 0.1°C signed
  static const int lppRelativeHumidity = 104; // 1 byte, 0.5% unsigned
  static const int lppAccelerometer = 113; // 2 bytes per axis, 0.001G
  static const int lppBarometricPressure = 115; // 2 bytes 0.1hPa unsigned
  static const int lppVoltage = 116; // 2 bytes 0.01V unsigned
  static const int lppCurrent = 117; // 2 bytes 0.001A unsigned
  static const int lppFrequency = 118; // 4 bytes 1Hz unsigned
  static const int lppPercentage = 120; // 1 byte 1-100% unsigned
  static const int lppAltitude = 121; // 2 byte 1m signed
  static const int lppConcentration = 125; // 2 bytes, 1 ppm unsigned
  static const int lppPower = 128; // 2 byte, 1W, unsigned
  static const int lppDistance = 130; // 4 byte, 0.001m, unsigned
  static const int lppEnergy = 131; // 4 byte, 0.001kWh, unsigned
  static const int lppDirection = 132; // 2 bytes, 1deg, unsigned
  static const int lppUnixTime = 133; // 4 bytes, unsigned
  static const int lppGyrometer = 134; // 2 bytes per axis, 0.01 °/s
  static const int lppColour = 135; // 1 byte per RGB Color
  static const int lppGps =
      136; // 3 byte lon/lat 0.0001 °, 3 bytes alt 0.01 meter
  static const int lppSwitch = 142; // 1 byte, 0/1
  static const int lppPolyline =
      240; // 1 byte size, 1 byte delta factor, 3 byte lon/lat 0.0001° * factor, n (size-8) bytes deltas

  /// The key each decoded type is shown under in [parseByChannel].
  static const Map<int, String> _valueKeys = {
    lppDigitalInput: 'digitalInput',
    lppDigitalOutput: 'digitalOutput',
    lppAnalogInput: 'analogInput',
    lppAnalogOutput: 'analogOutput',
    lppGenericSensor: 'generic',
    lppLuminosity: 'luminosity',
    lppPresence: 'presence',
    lppTemperature: 'temperature',
    lppRelativeHumidity: 'humidity',
    lppBarometricPressure: 'pressure',
    lppVoltage: 'voltage',
    lppCurrent: 'current',
    lppFrequency: 'frequency',
    lppPercentage: 'percentage',
    lppAltitude: 'altitude',
    lppConcentration: 'concentration',
    lppPower: 'power',
    lppDistance: 'distance',
    lppEnergy: 'energy',
    lppDirection: 'direction',
    lppUnixTime: 'unixTime',
    lppSwitch: 'switch',
    lppGps: 'gps',
  };

  /// Types whose size is known but whose value isn't shown; skipped so the
  /// readings after them still parse.
  static const Map<int, int> _skippedSizes = {
    lppAccelerometer: 6,
    lppGyrometer: 6,
    lppColour: 3,
  };

  /// One value, or null after skipping a known-size type. Throws
  /// [FormatException] for a type whose size is unknown: nothing after it
  /// can be read.
  static Object? _readValue(BufferReader b, int type) {
    switch (type) {
      case lppDigitalInput:
      case lppDigitalOutput:
      case lppPercentage:
      case lppSwitch:
        return b.readUInt8();
      case lppPresence:
        return b.readUInt8() != 0;
      case lppAnalogInput:
      case lppAnalogOutput:
        return b.readInt16BE() / 100.0;
      case lppGenericSensor:
      case lppFrequency:
      case lppUnixTime:
        return b.readUInt32BE();
      case lppLuminosity:
      case lppConcentration:
      case lppPower:
      case lppDirection:
        return b.readUInt16BE();
      case lppTemperature:
        return b.readInt16BE() / 10.0;
      case lppRelativeHumidity:
        return b.readUInt8() / 2.0;
      case lppBarometricPressure:
        return b.readUInt16BE() / 10.0;
      // Signed on purpose: a negative current arrives in two's complement.
      case lppVoltage:
        return b.readInt16BE() / 100.0;
      case lppCurrent:
        return b.readInt16BE() / 1000.0;
      case lppAltitude:
        return b.readInt16BE().toDouble();
      case lppDistance:
      case lppEnergy:
        return b.readUInt32BE() / 1000.0;
      case lppGps:
        return {
          'latitude': b.readInt24BE() / 10000.0,
          'longitude': b.readInt24BE() / 10000.0,
          'altitude': b.readInt24BE() / 100.0,
        };
    }
    final size = _skippedSizes[type];
    if (size == null) throw FormatException('unknown LPP type $type');
    b.skipBytes(size);
    return null;
  }

  /// Every reading in order as `{channel, type, value}`. Stops at `00 00`
  /// padding, at a type of unknown size, or at a truncated reading, and
  /// keeps what it read before that.
  static List<Map<String, dynamic>> parse(Uint8List bytes) {
    final buffer = BufferReader(bytes);
    final telemetry = <Map<String, dynamic>>[];
    try {
      while (buffer.remaining >= 2) {
        final channel = buffer.readUInt8();
        final type = buffer.readUInt8();
        if (channel == 0 && type == 0) break;
        final value = _readValue(buffer, type);
        if (value == null) continue;
        telemetry.add({'channel': channel, 'type': type, 'value': value});
      }
    } on FormatException {
      // Unknown type: the rest can't be aligned.
    } catch (e) {
      appLogger.error('Error parsing Cayenne LPP data: $e');
    }
    return telemetry;
  }

  /// Readings grouped by channel, sorted by channel:
  /// `[{channel, values: {temperature: 21.5, voltage: 3.97, ...}}]`.
  static List<Map<String, dynamic>> parseByChannel(Uint8List bytes) {
    final channels = <int, Map<String, dynamic>>{};
    for (final reading in parse(bytes)) {
      final channel = reading['channel'] as int;
      final channelData = channels.putIfAbsent(
        channel,
        () => {'channel': channel, 'values': <String, dynamic>{}},
      );
      channelData['values'][_valueKeys[reading['type']]] = reading['value'];
    }
    return channels.values.toList()
      ..sort((a, b) => (a['channel'] as int).compareTo(b['channel'] as int));
  }

  /// One `min_deltas` entry of a telemetry push subscription (firmware
  /// 1.18, REQ_TYPE_SUBSCRIBE): `[channel][type][delta]`, big-endian, sized
  /// and scaled the way the sensor reads it back (LPPData in
  /// LPPDataHelpers.h). There humidity is 2 bytes ×10, not the 1 byte ×2
  /// of the telemetry itself. Multi-value types (GPS, accelerometer,
  /// gyrometer, colour, polyline) can't carry a delta.
  static Uint8List encodeDelta(int channel, int type, double delta) {
    final (size, multiplier) = switch (type) {
      lppCurrent || lppDistance || lppEnergy => (
        type == lppCurrent ? 2 : 4,
        1000,
      ),
      lppVoltage || lppAnalogInput || lppAnalogOutput => (2, 100),
      lppTemperature || lppBarometricPressure || lppRelativeHumidity => (2, 10),
      lppGenericSensor || lppFrequency || lppUnixTime => (4, 1),
      lppLuminosity ||
      lppConcentration ||
      lppAltitude ||
      lppDirection ||
      lppPower => (2, 1),
      lppDigitalInput ||
      lppDigitalOutput ||
      lppPresence ||
      lppPercentage ||
      lppSwitch => (1, 1),
      _ => throw ArgumentError.value(type, 'type', 'cannot carry a delta'),
    };
    if (delta <= 0) throw ArgumentError.value(delta, 'delta', 'must be > 0');
    final maxRaw = (1 << (8 * size)) - 1;
    final raw = (delta * multiplier).round().clamp(1, maxRaw);
    final out = Uint8List(2 + size)
      ..[0] = channel
      ..[1] = type;
    for (var i = 0; i < size; i++) {
      out[2 + i] = (raw >> (8 * (size - 1 - i))) & 0xFF;
    }
    return out;
  }
}
