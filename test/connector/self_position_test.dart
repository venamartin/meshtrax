import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/cayenne_lpp.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The map keeps "You" current by asking a radio with GPS for its own
// telemetry. SELF_INFO would also carry the position, but it reloads the
// contacts and starts a sync each time.
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

  int sentOf(int command) => sent.where((f) => f[0] == command).length;
}

Uint8List _selfInfo(Uint8List pubKey, double lat, double lon) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(
    (ByteData(8)
          ..setInt32(0, (lat * 1e6).round(), Endian.little)
          ..setInt32(4, (lon * 1e6).round(), Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([0, 0, 0, 1]);
  w.add(Uint8List(8));
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

List<int> _int24(double degrees) {
  final v = (degrees * 10000).round() & 0xFFFFFF;
  return [v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF];
}

/// PUSH_CODE_TELEMETRY_RESPONSE: [0x8B][reserved][key prefix x6][LPP].
Uint8List _telemetry(Uint8List pubKey, double lat, double lon) =>
    Uint8List.fromList([
      pushCodeTelemetryResponse,
      0,
      ...pubKey.sublist(0, 6),
      1, CayenneLpp.lppVoltage, 0x01, 0x8D, // 3.97 V
      1, CayenneLpp.lppGps, ..._int24(lat), ..._int24(lon), 0, 0, 0,
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  late _Connector c;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  void radio({required int verCode, required String gps}) {
    c.handleFrameForTest([respCodeDeviceInfo, verCode, 50, 8]);
    c.handleFrameForTest([respCodeCustomVars, ...utf8.encode('gps:$gps'), 0]);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey, 41.812345, -71.412345));
    await settle();
  });

  test('asks only a radio with its GPS on and self telemetry', () async {
    radio(verCode: 9, gps: '0');
    await c.requestSelfPosition();
    radio(verCode: 5, gps: '1');
    await c.requestSelfPosition();
    expect(c.sentOf(cmdSendTelemetryReq), 0);

    radio(verCode: 9, gps: '1');
    await c.requestSelfPosition();
    expect(
      c.sent.where((f) => f[0] == cmdSendTelemetryReq).single,
      buildSendTelemetryReq(null),
      reason: 'no key: the radio answers for itself',
    );
  });

  test('the reply moves the radio, with no contact sync', () async {
    final syncs = c.sentOf(cmdGetContacts);
    c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012));
    expect(c.selfLatitude, closeTo(41.8301, 1e-9));
    expect(c.selfLongitude, closeTo(-71.4012, 1e-9));
    await settle();
    expect(c.sentOf(cmdGetContacts), syncs);
  });

  test("a contact's telemetry isn't the radio's", () {
    c.handleFrameForTest(_telemetry(peerKey, 40.0, -70.0));
    expect(c.selfLatitude, closeTo(41.812345, 1e-9));
  });

  test("standing still keeps SELF_INFO's finer figure", () {
    c.handleFrameForTest(_telemetry(selfKey, 41.8123, -71.4123));
    expect(c.selfLatitude, closeTo(41.812345, 1e-9));
    expect(c.selfLongitude, closeTo(-71.412345, 1e-9));
  });
}
