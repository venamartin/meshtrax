import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio settings dialog used to send its frame and report success without
// waiting; a refused frame (wrong off-grid frequency) changed nothing on the
// radio while the app said "Radio settings updated".
class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }
}

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

// RESP_ALLOWED_REPEAT_FREQ as stock companion firmware 1.18 writes it
// (MeshCore/examples/companion_radio/MyMesh.cpp CMD_GET_ALLOWED_REPEAT_FREQ).
Uint8List _stockAllowed() => Uint8List.fromList([
  respCodeAllowedRepeatFreq,
  ..._u32(433000),
  ..._u32(433000),
  ..._u32(869495),
  ..._u32(869495),
  ..._u32(918000),
  ..._u32(918000),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
  });

  test('parses the allowed repeat frequencies', () {
    expect(buildGetAllowedRepeatFreqFrame(), [cmdGetAllowedRepeatFreq]);
    expect(parseAllowedRepeatFreqFrame(_stockAllowed()), [
      (lowerKhz: 433000, upperKhz: 433000),
      (lowerKhz: 869495, upperKhz: 869495),
      (lowerKhz: 918000, upperKhz: 918000),
    ]);
    expect(
      parseAllowedRepeatFreqFrame(
        Uint8List.fromList([respCodeAllowedRepeatFreq]),
      ),
      isEmpty,
    );
  });

  test('asks the radio for its allowed repeat frequencies', () async {
    final answer = c.getAllowedRepeatFrequencies();
    await pumpEventQueue();
    expect(c.sent.single, [cmdGetAllowedRepeatFreq]);

    c.handleFrameForTest(_stockAllowed());
    expect((await answer)?.map((r) => r.lowerKhz), [433000, 869495, 918000]);
  });

  test('no list when the radio answers with an error', () async {
    final answer = c.getAllowedRepeatFrequencies();
    await pumpEventQueue();
    c.handleFrameForTest([respCodeErr, 6]);
    expect(await answer, isNull);
  });

  test('radio settings report a refusal', () async {
    final answer = c.setRadioParams(869000, 62500, 8, 5, clientRepeat: true);
    await pumpEventQueue();
    expect(c.sent.single.first, cmdSetRadioParams);
    expect(c.sent.single.last, 1, reason: 'repeat byte sent');

    c.handleFrameForTest([respCodeErr, 6]);
    expect(await answer, isFalse);
  });

  test('radio settings report success', () async {
    final answer = c.setRadioParams(869495, 62500, 8, 5, clientRepeat: true);
    await pumpEventQueue();
    c.handleFrameForTest([respCodeOk]);
    expect(await answer, isTrue);
  });
}
