import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Utility: put the BLE companion (GWQ 🚀) on its home frequency.
///
/// Owner's standing rule (2026-09-21): the rocket LIVES on the US standard
/// mesh frequency (910.525). Only high-volume/"crazy activity" test sessions
/// move it off-mesh, and they must bring it back here when they end. Override
/// with --dart-define=PARK_KHZ=920000 for an off-mesh bench session.
///
///   flutter test integration_test/park_companion_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const parkKhz = int.fromEnvironment(
    'PARK_KHZ',
    defaultValue: BenchConfig.meshFreqKhz,
  );

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();

  tearDownAll(() async {
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('set BLE companion frequency', (tester) async {
    await beginScenario(tester, 'park companion');
    await PrefsManager.initialize();

    await bridge.start();
    ble.connector = await buildConnector();
    await ble.connector.connectTcp(
      host: '127.0.0.1',
      port: BenchConfig.bridgePort,
    );
    await waitConnectedVerified(ble);
    blog('companion: ${ble.connector.selfName}');

    await alignFrequency(ble, khz: parkKhz);
    expect(ble.connector.currentFreqHz, parkKhz);
    blog('companion now on $parkKhz kHz');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
