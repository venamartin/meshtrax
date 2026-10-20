import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness/bench.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Utility: list the MeshCore radios advertising over Bluetooth near this
/// PC, with their addresses, to point a bench bridge at one of them.
/// A radio that already has an app connected does not advertise.
///
///   flutter test integration_test/ble_scan_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('scan for MeshCore radios', (tester) async {
    await beginScenario(tester, 'BLE scan');
    final found = await BleNusTcpBridge().scan();
    blog('${found.length} MeshCore radio(s) advertising:');
    for (final entry in found.entries) {
      blog('  ${entry.key}  "${entry.value}"');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
