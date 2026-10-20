import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A 1.18 companion forwards a sensor's telemetry push as an unsolicited
// 0x8C, laid out like the reply to one of our own binary requests. Push
// tags carry the top bit; request tags are the radio's RTC seconds.
Uint8List _binaryResponse(Uint8List tag, List<int> rest) => Uint8List.fromList(
      [pushCodeBinaryResponse, 0, ...tag, ...rest],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector c;
  late List<SensorPush> pushes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = MeshCoreConnector();
    pushes = [];
    c.sensorPushes.listen(pushes.add);
  });

  test('push tags always carry the top bit, request tags never do', () {
    final random = Random(7);
    for (var i = 0; i < 200; i++) {
      expect(isSensorPushTag(newSensorPushTag(random)), isTrue);
    }
    // RTC seconds for 2026-10-20, as the companion stamps a request.
    final requestTag = Uint8List(4)
      ..buffer.asByteData().setUint32(0, 1792512000, Endian.little);
    expect(isSensorPushTag(requestTag), isFalse);
  });

  test('a push goes out on sensorPushes', () async {
    final tag = newSensorPushTag(Random(1));
    c.handleFrameForTest(_binaryResponse(
      tag,
      [0x00, 0xD2, 0x02, 0x69, 0x01, 0x74, 0x01, 0x8D],
    ));
    await Future<void>.delayed(Duration.zero);

    expect(pushes.single.pushTag, tag);
    expect(pushes.single.lpp, [0x01, 0x74, 0x01, 0x8D]);
  });

  test('a reply to our own request does not', () async {
    final requestTag = Uint8List(4)
      ..buffer.asByteData().setUint32(0, 1792512000, Endian.little);
    c.handleFrameForTest(_binaryResponse(requestTag, [0x10, 0x0E, 0, 0]));
    await Future<void>.delayed(Duration.zero);

    expect(pushes, isEmpty);
  });
}
