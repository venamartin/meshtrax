import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/cayenne_lpp.dart';
import 'package:meshtrax/services/repeater_command_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Companion-to-companion telemetry (pull) between two 1.18 companions:
/// GWQ🚀 asks GWQ (GPS attached) for its reading, both ways the app can.
///
/// - GWQ🚀 over WiFi (MT_ROCKET_HOST), GWQ over Bluetooth on its own bridge
///   (MT_GWQ_ADDR, from integration_test/ble_scan_test.dart).
/// - Both move to the bench frequency for the test and go back after.
/// - The two advertise once, zero-hop, to learn each other.
/// - GWQ lets GWQ🚀 read its telemetry (base, location, environment); that
///   permission and both contacts are left in place.
///
///   flutter test integration_test/companion_telemetry_pull_test.dart -d windows
///     --dart-define=MT_ROCKET_HOST=192.168.4.116
///     --dart-define=MT_GWQ_ADDR=8c:fd:49:b5:88:0d
///     [--dart-define=MT_GWQ_GPS=true]  (switch GWQ's GPS on first)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const rocketHost = String.fromEnvironment('MT_ROCKET_HOST');
  const gwqAddress = String.fromEnvironment('MT_GWQ_ADDR');
  // Switch GWQ's GPS on if it is off (left on afterwards).
  const switchGpsOn = bool.fromEnvironment('MT_GWQ_GPS');
  const gwqBridgePort = BenchConfig.bridgePort + 1;

  final rocket = BenchRadio('GWQ🚀(WiFi)');
  final gwq = BenchRadio('GWQ(BLE)');
  final bridge = BleNusTcpBridge(address: gwqAddress, port: gwqBridgePort);
  int? rocketHomeKhz;
  int? gwqHomeKhz;

  tearDownAll(() async {
    // Put both back on their own frequency, whatever happened.
    for (final (radio, khz) in [(rocket, rocketHomeKhz), (gwq, gwqHomeKhz)]) {
      try {
        if (khz != null && radio.connector.isConnected) {
          await alignFrequency(radio, khz: khz);
        }
      } catch (e) {
        blog('could not restore ${radio.label} to $khz kHz: $e');
      }
      try {
        await radio.connector.disconnect();
      } catch (_) {}
    }
    try {
      await bridge.stop();
    } catch (_) {}
  });

  void showReading(String how, Uint8List lpp) {
    final channels = CayenneLpp.parseByChannel(lpp);
    blog('$how: ${lpp.length} bytes, ${channels.length} channel(s)');
    for (final ch in channels) {
      blog('  ch${ch['channel']}: ${ch['values']}');
    }
  }

  testWidgets('pull telemetry GWQ🚀 ← GWQ', (tester) async {
    await beginScenario(tester, 'companion telemetry pull');
    await PrefsManager.initialize();
    expect(rocketHost, isNotEmpty, reason: 'pass MT_ROCKET_HOST');
    expect(gwqAddress, isNotEmpty, reason: 'pass MT_GWQ_ADDR');

    // --- connect both ------------------------------------------------------
    rocket.connector = await buildConnector();
    await rocket.connector.connectTcp(host: rocketHost, port: 5000);
    await waitConnectedVerified(rocket);

    await bridge.start();
    gwq.connector = await buildConnector();
    await gwq.connector.connectTcp(host: '127.0.0.1', port: gwqBridgePort);
    await waitConnectedVerified(gwq);

    final r = rocket.connector;
    final g = gwq.connector;
    for (final (radio, c) in [(rocket, r), (gwq, g)]) {
      blog('${radio.label}: "${c.selfName}" ${c.firmwareVersion}, '
          'key ${c.selfPublicKeyHex.substring(0, 8)}…');
    }
    expect(g.firmwareVerCode, 14);

    // --- off-mesh for the test ---------------------------------------------
    await beginScenario(tester, 'move both to the bench frequency');
    rocketHomeKhz = r.currentFreqHz;
    gwqHomeKhz = g.currentFreqHz;
    await alignFrequency(rocket);
    await alignFrequency(gwq);

    // --- learn each other ---------------------------------------------------
    await beginScenario(tester, 'zero-hop adverts');
    await r.sendSelfAdvert(flood: false);
    await Future<void>.delayed(const Duration(seconds: 3));
    await g.sendSelfAdvert(flood: false);
    final gwqOnRocket =
        await ensureSavedContact(rocket, g.selfPublicKeyHex, 'GWQ');
    final rocketOnGwq =
        await ensureSavedContact(gwq, r.selfPublicKeyHex, 'GWQ🚀');
    blog('GWQ🚀 knows "${gwqOnRocket.name}" '
        '(route ${gwqOnRocket.pathLength}); GWQ knows "${rocketOnGwq.name}" '
        '(route ${rocketOnGwq.pathLength})');

    // --- GWQ lets GWQ🚀 read its telemetry ---------------------------------
    await beginScenario(tester, 'GWQ grants GWQ🚀 telemetry');
    blog('GWQ telemetry modes before: base=${g.telemetryModeBase} '
        'loc=${g.telemetryModeLoc} env=${g.telemetryModeEnv} '
        '(0 deny, 1 per contact, 2 everyone)');
    int atLeastPerContact(int mode) =>
        mode == teleModeDeny ? teleModeAllowFlags : mode;
    await g.setTelemetryModeBase(
      atLeastPerContact(g.telemetryModeBase),
      atLeastPerContact(g.telemetryModeLoc),
      atLeastPerContact(g.telemetryModeEnv),
      g.advertLocationPolicy,
      g.multiAcks,
    );
    await g.setContactFlags(
      rocketOnGwq,
      teleBase: true,
      teleLoc: true,
      teleEnv: true,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    final granted = findContactByHex(g, r.selfPublicKeyHex, savedOnly: true)!;
    blog('GWQ modes now: base=${g.telemetryModeBase} '
        'loc=${g.telemetryModeLoc} env=${g.telemetryModeEnv}; GWQ🚀 flags '
        '0x${granted.flags.toRadixString(16)}');
    expect(granted.teleBaseEnabled && granted.teleLocEnabled, isTrue);

    // A companion puts its position in telemetry only while its GPS is on
    // (EnvironmentSensorManager: `gps_active`), fix or not. The firmware
    // shows the "gps" setting only when it detected a GPS module.
    final vars = g.currentCustomVars ?? const {};
    blog('GWQ custom settings: $vars');
    if (!vars.containsKey('gps')) {
      blog('GWQ reports no GPS module (no "gps" setting)');
    } else if (switchGpsOn && vars['gps'] != '1') {
      blog("switching GWQ's GPS on");
      await g.setCustomVar('gps:1');
      await g.refreshDeviceInfo();
      await waitUntil(
        () => g.currentCustomVars?['gps'] == '1',
        'GWQ reports its GPS on',
      );
    }

    // --- pull, both ways ----------------------------------------------------
    await beginScenario(tester, 'pull telemetry');
    final service = RepeaterCommandService(r);
    try {
      final viaTelemetryReq = await service.sendTelemetryRequest(gwqOnRocket);
      showReading('telemetry request (CMD 39 → 0x8B)', viaTelemetryReq);
      expect(CayenneLpp.parseByChannel(viaTelemetryReq), isNotEmpty);

      final viaBinaryReq = await service.sendBinaryRequest(
        gwqOnRocket,
        Uint8List.fromList([reqTypeGetTelemetry, 0x00]),
      );
      showReading('binary request (REQ 0x03 → 0x8C)', viaBinaryReq);
      expect(CayenneLpp.parseByChannel(viaBinaryReq), isNotEmpty);

      final gps = CayenneLpp.parse(viaTelemetryReq)
          .where((e) => e['type'] == CayenneLpp.lppGps);
      blog(gps.isEmpty
          ? 'no GPS position in the reading (no fix yet, or GPS off)'
          : 'GPS: ${gps.first['value']}');
    } finally {
      service.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
