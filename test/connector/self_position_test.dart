import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/cayenne_lpp.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The app keeps the radio's position current by asking a radio with its GPS
// on for its own telemetry every 30 s. SELF_INFO would also carry the
// position, but it reloads the contacts and starts a sync each time.
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

List<int> _int24(double value, int scale) {
  final v = (value * scale).round() & 0xFFFFFF;
  return [v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF];
}

/// PUSH_CODE_TELEMETRY_RESPONSE: [0x8B][reserved][key prefix x6][LPP].
Uint8List _telemetry(
  Uint8List pubKey,
  double lat,
  double lon, {
  double alt = 0,
}) => Uint8List.fromList([
  pushCodeTelemetryResponse,
  0,
  ...pubKey.sublist(0, 6),
  1, CayenneLpp.lppVoltage, 0x01, 0x8D, // 3.97 V
  1, CayenneLpp.lppGps,
  ..._int24(lat, 10000), ..._int24(lon, 10000), ..._int24(alt, 100),
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
  // GPS off stops the refresh timer.
  tearDown(() => radio(verCode: 9, gps: '0'));

  test('GPS on: asks every 60 s, every 10 s while shown, never APP_START', () {
    fakeAsync((async) {
      final appStarts = c.sentOf(cmdAppStart);
      radio(verCode: 9, gps: '1');
      async.elapse(const Duration(seconds: 61));
      expect(c.sentOf(cmdSendTelemetryReq), 1);

      c.addSelfPositionViewer();
      expect(c.sentOf(cmdSendTelemetryReq), 2, reason: 'asks on opening');
      async.elapse(const Duration(seconds: 21));
      expect(c.sentOf(cmdSendTelemetryReq), 4);

      c.removeSelfPositionViewer();
      async.elapse(const Duration(seconds: 59));
      expect(c.sentOf(cmdSendTelemetryReq), 4, reason: 'back to 60 s');
      async.elapse(const Duration(seconds: 2));
      expect(c.sentOf(cmdSendTelemetryReq), 5);

      radio(verCode: 9, gps: '0');
      async.elapse(const Duration(seconds: 61));
      expect(c.sentOf(cmdSendTelemetryReq), 5, reason: 'GPS off: no asking');
      expect(c.sentOf(cmdAppStart), appStarts);
    });
  });

  test("GPS on from the app sets the radio's default refresh", () {
    fakeAsync((async) {
      expect(c.hasGps, isFalse, reason: 'no gps setting: no module');
      radio(verCode: 9, gps: '0');
      expect((c.hasGps, c.gpsOn), (true, false));

      unawaited(c.setGps(true));
      async.flushMicrotasks();
      expect(
        c.sent
            .where((f) => f[0] == cmdSetCustomVar)
            .map((f) => utf8.decode(f.sublist(1)).replaceAll('\x00', '')),
        ['gps:1', 'gps_interval:0'],
      );
      expect(c.gpsOn, isTrue);
      async.elapse(const Duration(seconds: 61));
      expect(c.sentOf(cmdSendTelemetryReq), 1, reason: 'the refresh started');
    });
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
    c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012, alt: 34.3));
    expect(c.selfLatitude, closeTo(41.8301, 1e-9));
    expect(c.selfLongitude, closeTo(-71.4012, 1e-9));
    expect(c.selfGps.value?.altitude, closeTo(34.3, 1e-9));
    await settle();
    expect(c.sentOf(cmdGetContacts), syncs);
  });

  test("a contact's telemetry isn't the radio's", () {
    c.handleFrameForTest(_telemetry(peerKey, 40.0, -70.0));
    expect(c.selfLatitude, closeTo(41.812345, 1e-9));
  });

  test("standing still keeps SELF_INFO's finer figure", () {
    c.handleFrameForTest(_telemetry(selfKey, 41.8123, -71.4123, alt: 30.7));
    expect(c.selfLatitude, closeTo(41.812345, 1e-9));
    expect(c.selfLongitude, closeTo(-71.412345, 1e-9));
    expect(
      c.selfGps.value?.altitude,
      closeTo(30.7, 1e-9),
      reason: 'the GPS dialog still sees the new reading',
    );
  });

  // After a restart with no fix, a radio reports the position it stored at
  // its last settings save, with altitude 0 (firmware MyMesh.cpp), and the
  // same SELF_INFO gave at connect. Pathfinder must not take it for a fix.
  test("a restarted radio's stored position is never live or fresh", () {
    for (var i = 0; i < 3; i++) {
      c.handleFrameForTest(_telemetry(selfKey, 41.8123, -71.4123));
    }
    expect(c.selfPositionIsLive, isFalse);
    expect(c.selfGpsIsFresh, isFalse);
  });

  test('a reading that moved off the position at connect is live', () {
    c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012, alt: 34.3));
    expect(c.selfPositionIsLive, isTrue);
  });

  group('every way off a radio forgets its fix', () {
    void liveFix() {
      radio(verCode: 9, gps: '1');
      c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012, alt: 34.3));
      c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012, alt: 34.5));
      expect(c.selfPositionIsLive, isTrue);
      expect(c.selfGps.value, isNotNull);
      expect(c.selfGpsIsFresh, isTrue);
    }

    void forgotten() {
      expect(c.selfPositionIsLive, isFalse);
      expect(c.selfGps.value, isNull);
      expect(c.selfGpsIsFresh, isFalse);
      expect(c.selfGpsChangedAt, isNull);
    }

    test('a disconnect, and its poll stops', () {
      fakeAsync((async) {
        liveFix();
        unawaited(c.disconnect());
        async.flushMicrotasks();
        forgotten();

        // The next radio answers DEVICE_INFO before its GPS setting comes:
        // the old poll must not ask it.
        final asked = c.sentOf(cmdSendTelemetryReq);
        c.handleFrameForTest([respCodeDeviceInfo, 9, 50, 8]);
        async.elapse(const Duration(minutes: 2));
        expect(c.sentOf(cmdSendTelemetryReq), asked);
      });
    });

    test('a Bluetooth drop', () {
      fakeAsync((async) {
        liveFix();
        c.handleBleDropForTest();
        forgotten();
      });
    });

    test('back on the radio, its first reading is not fresh', () {
      fakeAsync((async) {
        liveFix();
        c.handleBleDropForTest();
        c.handleFrameForTest(_selfInfo(selfKey, 41.812345, -71.412345));
        radio(verCode: 9, gps: '1');
        c.handleFrameForTest(_telemetry(selfKey, 41.8301, -71.4012, alt: 34.9));
        expect(c.selfGpsIsFresh, isFalse, reason: 'grey for one poll');
        expect(c.selfPositionMayBeOld, isTrue);
      });
    });
  });

  // The map's blue dot (safety review CH-07): a radio that lost its fix
  // keeps reporting the last one, exactly. For the screen only: Pathfinder
  // keeps selfPositionIsLive, which never expires (#206).
  group('a fresh GPS position', () {
    // A radio with a fix standing still: its altitude moves in centimetres.
    void reading(double alt, {double lat = 41.8301, double lon = -71.4012}) =>
        c.handleFrameForTest(_telemetry(selfKey, lat, lon, alt: alt));

    test('takes two readings that differ', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '1');
        reading(34.3);
        expect(c.selfGpsIsFresh, isFalse, reason: 'nothing to compare it with');
        expect(c.selfPositionMayBeOld, isTrue);
        reading(34.5);
        expect(c.selfGpsIsFresh, isTrue);
        expect(c.selfPositionMayBeOld, isFalse);
        expect(c.selfGpsChangedAt, isNotNull);
      });
    });

    test('ends 3 min after the last change, and says so', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '1');
        reading(34.3);
        reading(34.5);
        final changedAt = c.selfGpsChangedAt;
        async.elapse(const Duration(milliseconds: 100));
        var notified = 0;
        c.addListener(() => notified++);

        // The fix is lost: every poll gets the last reading again.
        for (var i = 0; i < 2; i++) {
          async.elapse(const Duration(seconds: 60));
          reading(34.5);
          expect(c.selfGpsIsFresh, isTrue);
        }
        async.elapse(const Duration(seconds: 59));
        expect(c.selfGpsIsFresh, isTrue);
        async.elapse(const Duration(seconds: 1));
        expect(c.selfGpsIsFresh, isFalse);
        expect(c.selfPositionMayBeOld, isTrue);
        async.elapse(const Duration(milliseconds: 100));
        expect(notified, 1, reason: 'the dot turns grey with no new reading');
        expect(c.selfGpsChangedAt, changedAt, reason: '"Last known" time');
        expect(
          c.selfPositionIsLive,
          isTrue,
          reason: "Pathfinder's flag never expires",
        );

        reading(34.6);
        expect(c.selfGpsIsFresh, isTrue, reason: 'a fix again');
        async.elapse(const Duration(milliseconds: 100));
        expect(notified, 2);
      });
    });

    test('a phone that slept past the 3 min: the next repeat ends it', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '1');
        reading(34.3);
        reading(34.5);
        c.backdateSelfGpsChangeForTest(const Duration(hours: 1));
        expect(c.selfGpsIsFresh, isTrue, reason: 'its timer has not run');
        reading(34.5);
        expect(c.selfGpsIsFresh, isFalse);
      });
    });

    test('a reading of no position is no fix', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '1');
        reading(34.3);
        reading(0, lat: 0, lon: 0);
        expect(c.selfGpsIsFresh, isFalse);
      });
    });

    test('a typed position ends it, and the radio reporting it is no fix', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '1');
        reading(34.3);
        reading(34.5);
        unawaited(c.setNodeLocation(lat: 40, lon: 2));
        async.flushMicrotasks();
        expect(c.selfGpsIsFresh, isFalse);
        expect(c.selfGpsChangedAt, isNull);

        // A radio with no fix reports the typed spot from then on.
        reading(34.5, lat: 40, lon: 2);
        reading(34.5, lat: 40, lon: 2);
        expect(c.selfGpsIsFresh, isFalse);
      });
    });

    test('GPS off: a typed position is never "may be old"', () {
      fakeAsync((async) {
        radio(verCode: 9, gps: '0');
        expect(c.selfGpsIsFresh, isFalse);
        expect(c.selfPositionMayBeOld, isFalse);
      });
    });
  });
}
