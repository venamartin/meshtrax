import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/cayenne_lpp.dart';

// Sensor requests and replies as SensorMesh.cpp (firmware 1.18) lays them
// out. Reply data here is what follows the 4-byte tag in the companion's
// 0x8C frame, which is what RepeaterCommandService.sendBinaryRequest hands
// back.
Uint8List _b(List<int> bytes) => Uint8List.fromList(bytes);

void main() {
  final tag = _b([0xD4, 0xC3, 0xB2, 0xA1]);

  group('subscribe', () {
    test('payload layout (firmware example: battery and temperature, 1 h)',
        () {
      final deltas = _b([
        ...CayenneLpp.encodeDelta(1, CayenneLpp.lppVoltage, 0.05),
        ...CayenneLpp.encodeDelta(2, CayenneLpp.lppTemperature, 0.5),
      ]);

      expect(buildSubscribePayload(tag, 3600, deltas), [
        0x08, 0xD4, 0xC3, 0xB2, 0xA1, 0x10, 0x0E, 0x00, 0x08, //
        0x01, 0x74, 0x00, 0x05, 0x02, 0x67, 0x00, 0x05,
      ]);
    });

    test('refuses what the sensor would reject or never push for', () {
      final deltas = CayenneLpp.encodeDelta(1, CayenneLpp.lppVoltage, 0.05);
      expect(() => buildSubscribePayload(tag, 0, deltas), throwsRangeError);
      expect(() => buildSubscribePayload(tag, 70000, deltas), throwsRangeError);
      expect(() => buildSubscribePayload(tag, 60, _b([1, 2])), throwsRangeError);
      expect(() => buildSubscribePayload(tag, 60, _b(List.filled(15, 1))),
          throwsRangeError);
      expect(() => buildSubscribePayload(_b([1, 2, 3]), 60, deltas),
          throwsArgumentError);
    });

    test('a grant names its region; padding is not part of it', () {
      final grant = parseSubscribeReply(
        _b([0x10, 0x0E, 0, 0, ...utf8.encode('bench'), 0, 0, 0]),
      );

      expect(grant!.grantedSecs, 3600);
      expect(grant.region, 'bench');
    });

    test('a region name may run to the end of the frame', () {
      expect(parseSubscribeReply(_b([0x3C, 0, 0, 0, ...utf8.encode('#sf')]))!
          .region, '#sf');
    });

    test('no usable region on the sensor is a refusal', () {
      expect(parseSubscribeReply(_b([0, 0, 0, 0, 0, 0, 0, 0])), isNull);
      expect(parseSubscribeReply(_b([0, 0])), isNull);
    });

    test('unsubscribe is just its type', () {
      expect(buildUnsubscribePayload(), [0x09]);
    });
  });

  test('a push carries its tag, the sensor time and the reading', () {
    final push = parseSensorPush(_b([
      0x8C, 0x00, 0xD4, 0xC3, 0xB2, 0xA1, //
      0x00, 0xD2, 0x02, 0x69, // 1761792512 LE
      0x01, 0x74, 0x01, 0x8D, 0x00, 0x00,
    ]));

    expect(push!.pushTag, tag);
    expect(push.sensorTime.millisecondsSinceEpoch, 0x6902D200 * 1000);
    expect(CayenneLpp.parseByChannel(push.lpp).single['values'],
        {'voltage': 3.97});
    expect(parseSensorPush(_b([0x8B, 0, 1, 2, 3, 4, 5, 6, 7, 8])), isNull);
  });

  group('min/max/average', () {
    test('payload layout: the last 24 h', () {
      expect(buildMinMaxAvgPayload(startSecsAgo: 86400, endSecsAgo: 0), [
        0x04, 0x80, 0x51, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);
    });

    test('reply: battery, a signed temperature and LPPData humidity', () {
      final reply = CayenneLpp.parseMinMaxAvg(_b([
        0x00, 0xD2, 0x02, 0x69, // sensor time
        0x01, 0x74, 0x01, 0x2C, 0x01, 0x9A, 0x01, 0x63, // 3.00 4.10 3.55 V
        0x02, 0x67, 0xFF, 0x9C, 0x00, 0x32, 0x00, 0x0A, // -10.0 5.0 1.0 °C
        0x02, 0x68, 0x01, 0xC7, 0x01, 0xC7, 0x01, 0xC7, // 45.5 % (2 bytes ×10)
        0x00, 0x00, 0x00, // padding
      ]))!;

      expect(reply.sensorTime.millisecondsSinceEpoch, 0x6902D200 * 1000);
      expect(reply.series.map((s) => [s.channel, s.type, s.min, s.max, s.avg]),
          [
            [1, CayenneLpp.lppVoltage, 3.0, 4.1, 3.55],
            [2, CayenneLpp.lppTemperature, -10.0, 5.0, 1.0],
            [2, CayenneLpp.lppRelativeHumidity, 45.5, 45.5, 45.5],
          ]);
    });

    test('a sensor with nothing stored answers just its time', () {
      expect(CayenneLpp.parseMinMaxAvg(_b([1, 2, 3, 4]))!.series, isEmpty);
      expect(CayenneLpp.parseMinMaxAvg(_b([1, 2])), isNull);
    });
  });
}
