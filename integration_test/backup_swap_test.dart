import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/models/device_backup.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';
import 'package:meshtrax/utils/backup_service.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Full backup/restore proof by IDENTITY SWAP: back up both bench radios,
/// restore each backup onto the OTHER radio, verify each radio now IS the
/// other (key, name, settings, channels, contacts, shareable advert blobs),
/// prove the swap survives a reboot — then swap BACK and verify again, so
/// the bench ends exactly as it started and the round-trip is proven in all
/// four directions.
///
/// Entirely over USB/the BLE bridge: the test never transmits on-air. Both
/// radios are moved to the 920.000 bench frequency BEFORE the backups are
/// taken so the windows where both hold the same identity never touch the
/// live mesh, and both are parked back on the mesh frequency at the end.
///
/// Run with:
///   flutter test integration_test/backup_swap_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final radios = [usb, ble];
  final bridge = BleNusTcpBridge();
  var benchReady = false;

  DeviceBackup? usbBackup;
  DeviceBackup? bleBackup;
  var usbPub0 = '';
  var blePub0 = '';
  String? usbName0;
  String? bleName0;

  void requireBench() {
    if (!benchReady) fail('Bench not ready — see S0 failure above.');
  }

  /// Restores [backup] onto both radios' counterparts in [assignments] and
  /// only asserts AFTER every direction ran — a mid-loop failure must never
  /// strand the bench half-swapped with a duplicated identity.
  Future<void> crossRestore(
    List<(BenchRadio, DeviceBackup)> assignments,
  ) async {
    final problems = <String>[];
    for (final (radio, backup) in assignments) {
      blog('${radio.label}: restoring "${backup.name}" '
          '(${backup.publicKeyHex.substring(0, 12)}…) onto this radio…');
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
      if (!report.identityRestored) {
        problems.add('${radio.label}: identity import failed');
      }
      problems.addAll(report.failures
          .where((f) => f.startsWith('Channel') || f.startsWith('Contact'))
          .map((f) => '${radio.label}: $f'));
      blog('${radio.label}: restored ${report.contactsWritten} contact(s) '
          '(${report.advertsReplayed} advert blob(s) replayed), '
          '${report.channelsWritten} channel(s)');
    }
    expect(problems, isEmpty,
        reason: 'restore problems: ${problems.join('; ')}');
  }

  /// Full "this radio IS that backup" assertion set. Starts with a fresh
  /// authoritative contact sync so it never reads a list that an identity
  /// re-point or cache reload left stale.
  Future<void> verifyMatchesBackup(
    BenchRadio radio,
    DeviceBackup backup,
    String oldSelf,
  ) async {
    final c = radio.connector;
    await awaitSyncIdle(radio);
    await waitUntil(
      () => !c.isLoadingContacts,
      '${radio.label}: contact sync idle',
      timeout: const Duration(minutes: 4),
      poll: const Duration(seconds: 1),
    );
    await c.getContacts();
    await waitUntil(
      () => !c.isLoadingContacts,
      '${radio.label}: fresh contact sync settles',
      timeout: const Duration(minutes: 4),
      poll: const Duration(seconds: 1),
    );

    // Identity and name.
    expect(c.selfPublicKeyHex, backup.publicKeyHex,
        reason: '${radio.label}: public key does not match the backup');
    expect(c.selfName, backup.name,
        reason: '${radio.label}: node name does not match the backup');

    // Radio params and node settings.
    expect(c.currentFreqHz, backup.freqHz);
    expect(c.currentBwHz, backup.bwHz);
    expect(c.currentSf, backup.sf);
    expect(c.currentCr, backup.cr);
    expect(c.currentTxPower, backup.txPower);
    expect(c.pathHashByteWidth - 1, backup.pathHashMode,
        reason: '${radio.label}: path hash mode mismatch');
    expect(c.multiAcks, backup.multiAcks);
    expect(c.advertLocationPolicy, backup.advertLocPolicy);
    expect(c.telemetryModeBase, backup.telemetryBase);
    expect(c.telemetryModeLoc, backup.telemetryLoc,
        reason: '${radio.label}: telemetry loc mismatch — bit-order bug?');
    expect(c.telemetryModeEnv, backup.telemetryEnv,
        reason: '${radio.label}: telemetry env mismatch — bit-order bug?');

    // Channels: every backed-up channel sits in its slot; no extras.
    final liveBySlot = {for (final ch in c.channels) ch.index: ch};
    for (final bch in backup.channels) {
      final live = liveBySlot[bch.index];
      expect(live, isNotNull,
          reason: '${radio.label}: channel slot ${bch.index} '
              '("${bch.name}") empty after restore');
      expect(live!.idKey, bch.pskHex,
          reason: '${radio.label}: wrong key in slot ${bch.index}');
      expect(live.name, bch.name,
          reason: '${radio.label}: wrong name in slot ${bch.index}');
    }
    final extraSlots = liveBySlot.keys
        .where((s) => !backup.channels.any((bch) => bch.index == s))
        .toList();
    expect(extraSlots, isEmpty,
        reason: '${radio.label}: slots not in the backup survived the '
            'full replace: $extraSlots');

    // Contacts: everything from the backup is on the radio.
    final livePubs =
        c.contacts.map((ct) => ct.publicKeyHex.toLowerCase()).toSet();
    for (final bc in backup.contacts) {
      final hex = bc.contact.publicKeyHex.toLowerCase();
      if (hex == backup.publicKeyHex.toLowerCase()) continue;
      expect(livePubs.contains(hex), isTrue,
          reason: '${radio.label}: contact "${bc.contact.name}" missing '
              'after restore');
    }
    if (livePubs.contains(oldSelf.toLowerCase())) {
      blog('${radio.label}: holds its pre-restore identity as a contact — '
          'the identity filter handled the swap correctly');
    }

    // Advert blobs: a contact restored WITH a blob must be shareable
    // again (CMD_EXPORT_CONTACT serves from the rebuilt /adv_blobs).
    BackupContact? withBlob;
    for (final bc in backup.contacts) {
      if (bc.rawAdvert != null &&
          bc.contact.publicKeyHex.toLowerCase() !=
              backup.publicKeyHex.toLowerCase()) {
        withBlob = bc;
        break;
      }
    }
    if (withBlob != null) {
      final name = withBlob.contact.name;
      final blob = await c.exportContactAdvert(withBlob.contact.publicKey);
      expect(blob, isNotNull,
          reason: '${radio.label}: "$name" not shareable after restore — '
              'advert blob replay failed');
      blog('${radio.label}: "$name" exportable again '
          '(${blob!.length} byte blob)');
    } else {
      blog('${radio.label}: no contact carried an advert blob — '
          'share/export check skipped');
    }

    blog('${radio.label}: IS "${backup.name}" '
        '(${backup.publicKeyHex.substring(0, 12)}…) ✔');
  }

  tearDownAll(() async {
    for (final r in radios) {
      try {
        await r.connector.disconnect();
      } catch (_) {}
    }
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('S0 bench comes up and moves off the mesh frequency',
      (tester) async {
    await beginScenario(tester, 'S0 swap bench bring-up');
    blog('backup swap bench, run tag: $runTag');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    usb.connector = await buildConnector();
    ble.connector = await buildConnector();

    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    ble.reconnect = () async {
      await ble.connector.connectTcp(
        host: '127.0.0.1',
        port: BenchConfig.bridgePort,
      );
      await waitConnectedVerified(ble);
    };

    blog('starting BLE bridge (watch for a Windows pairing prompt)…');
    await bridge.start();

    await usb.reconnect();
    await ble.reconnect();

    usbPub0 = usb.connector.selfPublicKeyHex;
    blePub0 = ble.connector.selfPublicKeyHex;
    usbName0 = usb.connector.selfName;
    bleName0 = ble.connector.selfName;
    blog('USB radio:  $usbName0 (${usbPub0.substring(0, 12)}…)');
    blog('BLE radio:  $bleName0 (${blePub0.substring(0, 12)}…)');
    expect(usbPub0, isNot(equals(blePub0)),
        reason: 'Both radios report the SAME identity. Either both '
            'transports reached one radio, or a previous aborted swap left '
            'a duplicate — run the backup rescue before this test.');

    // Off the live mesh BEFORE identities get duplicated mid-swap.
    await alignFrequency(usb);
    await alignFrequency(ble);

    // Distinguishing telemetry state on the USB radio: loc != env is the
    // live regression probe for the SELF_INFO bit-order fix.
    blog('seeding telemetry loc=2 env=1 on the USB radio');
    await usb.connector.setTelemetryModeBase(
      usb.connector.telemetryModeBase,
      2,
      1,
      usb.connector.advertLocationPolicy,
      usb.connector.multiAcks,
    );
    await usb.connector.refreshDeviceInfo();
    await waitUntil(
      () =>
          usb.connector.telemetryModeLoc == 2 &&
          usb.connector.telemetryModeEnv == 1,
      'USB radio: seeded telemetry reads back loc=2 env=1',
    );

    benchReady = true;
    blog('bench ready');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('S1 both radios back up, identity keys included',
      (tester) async {
    await beginScenario(tester, 'S1 backup both radios');
    requireBench();

    for (final (radio, label) in [(usb, 'usb'), (ble, 'ble')]) {
      blog('${radio.label}: gathering full backup…');
      final backup = await radio.connector.gatherDeviceBackup(
        onContactProgress: (done, total) {
          if (done == total) blog('${radio.label}: $total contact(s) read');
        },
      );
      expect(backup.privateKeyHex, isNotNull,
          reason: '${radio.label}: firmware refused private key export — '
              'cannot swap identities, aborting before any restore');
      final blobs =
          backup.contacts.where((c) => c.rawAdvert != null).length;
      blog('${radio.label}: "${backup.name}" — '
          '${backup.channels.length} channel(s), '
          '${backup.contacts.length} contact(s) ($blobs with advert blobs), '
          'freq=${backup.freqHz} sf=${backup.sf} tx=${backup.txPower}');

      final json = await BackupService.createBackupJson(backup);
      final path = 'backup_swap_${runTag}_$label.json';
      expect(await BackupService.saveToPath(json, path), isTrue);
      blog('${radio.label}: backup saved to $path');
      if (radio == usb) {
        usbBackup = backup;
      } else {
        bleBackup = backup;
      }
    }

    expect(usbBackup!.publicKeyHex, usbPub0);
    expect(bleBackup!.publicKeyHex, blePub0);
  }, timeout: const Timeout(Duration(minutes: 12)));

  testWidgets('S2 cross-restore: each radio becomes the other',
      (tester) async {
    await beginScenario(tester, 'S2 cross-restore (the swap)');
    requireBench();
    await crossRestore([(usb, bleBackup!), (ble, usbBackup!)]);
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('S3 swap verified: identity, settings, channels, contacts',
      (tester) async {
    await beginScenario(tester, 'S3 verify the swap');
    requireBench();
    await verifyMatchesBackup(usb, bleBackup!, usbPub0);
    await verifyMatchesBackup(ble, usbBackup!, blePub0);
    blog('swap verified: $usbName0 and $bleName0 traded places');
  }, timeout: const Timeout(Duration(minutes: 15)));

  testWidgets('S4 swap survives a reboot (USB radio)', (tester) async {
    await beginScenario(tester, 'S4 reboot persistence');
    requireBench();

    blog('rebooting the USB radio (flushes dirty contacts to flash)…');
    await usb.connector.rebootDevice();
    await Future<void>.delayed(const Duration(seconds: 3));
    try {
      await usb.connector.disconnect();
    } catch (_) {}

    var reconnected = false;
    for (var attempt = 1; attempt <= 12 && !reconnected; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      try {
        await usb.reconnect();
        reconnected = true;
      } catch (e) {
        blog('reconnect attempt $attempt failed: $e');
      }
    }
    expect(reconnected, isTrue,
        reason: 'USB radio never came back after reboot');

    expect(usb.connector.selfPublicKeyHex, bleBackup!.publicKeyHex,
        reason: 'USB radio lost the swapped identity across a reboot');
    expect(usb.connector.selfName, bleBackup!.name);
    await awaitSyncIdle(usb);
    await waitUntil(
      () => !usb.connector.isLoadingContacts,
      'USB radio: contact sync settles after reboot',
      timeout: const Duration(minutes: 4),
      poll: const Duration(seconds: 1),
    );
    final livePubs = usb.connector.contacts
        .map((ct) => ct.publicKeyHex.toLowerCase())
        .toSet();
    for (final bc in bleBackup!.contacts) {
      final hex = bc.contact.publicKeyHex.toLowerCase();
      if (hex == bleBackup!.publicKeyHex.toLowerCase()) continue;
      expect(livePubs.contains(hex), isTrue,
          reason: 'contact "${bc.contact.name}" lost across the reboot');
    }
    blog('USB radio still "${bleBackup!.name}" after reboot, '
        '${livePubs.length} contact(s) intact');
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('S5 swap back: each radio becomes itself again',
      (tester) async {
    await beginScenario(tester, 'S5 cross-restore (swap back)');
    requireBench();
    await crossRestore([(usb, usbBackup!), (ble, bleBackup!)]);
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('S6 original identities verified back in place',
      (tester) async {
    await beginScenario(tester, 'S6 verify the swap back');
    requireBench();
    await verifyMatchesBackup(usb, usbBackup!, bleBackup!.publicKeyHex);
    await verifyMatchesBackup(ble, bleBackup!, usbBackup!.publicKeyHex);
    blog('bench back to original: $usbName0 on USB, $bleName0 on BLE');
  }, timeout: const Timeout(Duration(minutes: 15)));

  testWidgets('S7 park both radios back on the mesh frequency',
      (tester) async {
    await beginScenario(tester, 'S7 park on mesh frequency');
    requireBench();
    for (final r in radios) {
      await alignFrequency(r, khz: BenchConfig.meshFreqKhz);
    }
    blog('both radios idling on '
        '${(BenchConfig.meshFreqKhz / 1000).toStringAsFixed(3)} MHz');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
