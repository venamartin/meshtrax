import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// Proves on the bench radio that a 2-byte route is written to the radio
/// with its width (path_len 0x42, never 0x04), and that a route stored at a
/// width the radio no longer runs at is forgotten (0xFF) on the next sync.
///
/// USB only, zero RF: add/get/reset contact and set-hash-mode never
/// transmit. A synthetic repeater contact is added and removed again; the
/// radio's hash width is put back to what it was.
///
/// Run with:
///   flutter test integration_test/route_width_writeback_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final probeKey = Uint8List.fromList(List.filled(32, 0x5A));
  const route = [0xA2, 0x77, 0xBE, 0xEF];

  Future<Uint8List?> fetchRawContactFrame(Uint8List pubKey) async {
    final completer = Completer<Uint8List?>();
    final sub = usb.connector.receivedFrames.listen((frame) {
      if (frame.length < 36 || frame[0] != respCodeContact) return;
      if (!listEquals(frame.sublist(1, 33), pubKey)) return;
      if (!completer.isCompleted) completer.complete(frame);
    });
    try {
      await usb.connector.sendFrame(buildGetContactByKeyFrame(pubKey));
      return await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  Future<void> setWidth(int width) async {
    final c = usb.connector;
    if (c.pathHashByteWidth == width) return;
    blog('setting path hash width to $width byte(s)');
    await c.setPathHashMode(PathHelper.hashModeFromWidth(width));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await c.refreshDeviceInfo();
    await waitUntil(() => c.pathHashByteWidth == width,
        'device info confirms $width-byte path hash width',
        timeout: const Duration(seconds: 15));
  }

  Contact? probe() => usb.connector.allContacts
      .cast<Contact?>()
      .firstWhere((c) => listEquals(c!.publicKey, probeKey), orElse: () => null);

  testWidgets('a 2-byte route is written as 0x42 and a stale one is forgotten',
      (tester) async {
    await beginScenario(tester, 'route width write-back');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();
    final c = usb.connector;
    await waitUntil(() => !c.isLoadingContacts, 'contact table synced',
        timeout: const Duration(seconds: 60));

    final originalWidth = c.pathHashByteWidth;
    blog('radio ${c.selfName}: ${c.contacts.length} contacts, '
        'width $originalWidth byte(s)');

    try {
      await setWidth(2);

      // What the app does when a discovered repeater with a learned 2-byte
      // route is imported (Manage Repeaters → any routing change).
      blog('importing WIDTH-PROBE with route A277,BEEF at width 2');
      final imported = await c.importDiscoveredContact(Contact(
        publicKey: probeKey,
        name: 'WIDTH-PROBE',
        type: advTypeRepeater,
        pathLength: 2,
        path: Uint8List.fromList(route),
        pathHashSize: 2,
        lastSeen: DateTime.now(),
      ));
      expect(imported, isTrue, reason: 'CMD_ADD_UPDATE_CONTACT not acked');

      final stored = await fetchRawContactFrame(probeKey);
      expect(stored, isNotNull, reason: 'contact fetch timed out');
      blog('stored path_len 0x${stored![35].toRadixString(16)} '
          'path ${PathHelper.formatPathHex(stored.sublist(36, 40), stride: 2)}');
      expect(stored[35], 0x42, reason: 'radio must hold 2 hops × 2 bytes');
      expect(stored.sublist(36, 40), route);

      final inMemory = probe();
      expect(inMemory, isNotNull);
      expect(inMemory!.pathLabel, '2 hops');
      expect(inMemory.displayPathString, 'A277,BEEF');

      // Now the radio runs at 1 byte: the 2-byte route can no longer
      // deliver, so the next contact frame must get it forgotten.
      await setWidth(1);
      blog('re-reading WIDTH-PROBE at width 1; expecting the route reset');
      await c.getContactByKey(probeKey);
      await waitUntil(() => probe()?.pathLength == -1,
          'stale route forgotten in memory',
          timeout: const Duration(seconds: 15));

      final after = await fetchRawContactFrame(probeKey);
      expect(after, isNotNull, reason: 'contact fetch timed out');
      blog('stored path_len after repair 0x${after![35].toRadixString(16)}');
      expect(after[35], 0xFF, reason: 'radio must hold no route');
      expect(
        debugLog.entries.any((e) => e.message.contains('Forgetting WIDTH-PROBE')),
        isTrue,
        reason: 'the repair must be logged',
      );
      blog('PASS: 0x42 written, stale route reset to 0xFF');
    } finally {
      final leftover = probe();
      if (leftover != null) {
        blog('removing WIDTH-PROBE');
        await c.removeContact(leftover);
      }
      await setWidth(originalWidth);
    }
  });
}
