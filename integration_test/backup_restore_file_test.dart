import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';
import 'package:meshtrax/utils/backup_service.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Bench utility: restore a saved MeshTrax backup file onto ONE bench radio.
/// Used to put a radio back into a known state (e.g. after an aborted swap
/// left a duplicated identity).
///
///   flutter test integration_test/backup_restore_file_test.dart -d windows \
///     --dart-define=RESTORE_FILE=backup_swap_xxxx_ble.json \
///     --dart-define=RESTORE_TARGET=ble   (or usb)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const restoreFile = String.fromEnvironment('RESTORE_FILE');
  const target = String.fromEnvironment('RESTORE_TARGET', defaultValue: 'ble');

  final radio = BenchRadio(
    target == 'usb'
        ? 'USB(${BenchConfig.usbPortName})'
        : 'BLE(${BenchConfig.bleName})',
  );
  final bridge = BleNusTcpBridge();

  tearDownAll(() async {
    try {
      await radio.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('restore backup file onto the $target bench radio',
      (tester) async {
    await beginScenario(tester, 'Restore file → $target radio');
    expect(restoreFile, isNotEmpty,
        reason: 'Pass --dart-define=RESTORE_FILE=<backup.json>');

    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    final parsed = await BackupService.parseBackupFromPath(restoreFile);
    expect(parsed, isA<FullBackup>(),
        reason: '$restoreFile is not a full MeshTrax backup');
    final backup = (parsed as FullBackup).device;
    blog('backup: "${backup.name}" '
        '(${backup.publicKeyHex.substring(0, 12)}…), '
        '${backup.channels.length} channel(s), '
        '${backup.contacts.length} contact(s)');

    radio.connector = await buildConnector();
    if (target == 'usb') {
      await radio.connector.connectUsb(portName: BenchConfig.usbPortName);
    } else {
      blog('starting BLE bridge (watch for a Windows pairing prompt)…');
      await bridge.start();
      await radio.connector.connectTcp(
        host: '127.0.0.1',
        port: BenchConfig.bridgePort,
      );
    }
    await waitConnectedVerified(radio);
    blog('${radio.label}: currently "${radio.connector.selfName}" '
        '(${radio.connector.selfPublicKeyHex.substring(0, 12)}…)');

    // Off the live mesh while the restore runs.
    await alignFrequency(radio);

    final report = await radio.connector.restoreDeviceBackup(
      backup,
      onProgress: (step, done, total) {
        if (done == 0 || done == total) {
          blog('${radio.label}: ${step.name} $done/$total');
        }
      },
    );
    for (final f in report.failures) {
      blog('${radio.label}: ⚠ restore problem: $f');
    }
    expect(report.identityRestored, isTrue,
        reason: '${radio.label}: identity import failed');

    expect(radio.connector.selfPublicKeyHex, backup.publicKeyHex);
    expect(radio.connector.selfName, backup.name);
    blog('${radio.label}: IS now "${backup.name}" ✔');

    await alignFrequency(radio, khz: BenchConfig.meshFreqKhz);
    blog('${radio.label}: parked on the mesh frequency');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
