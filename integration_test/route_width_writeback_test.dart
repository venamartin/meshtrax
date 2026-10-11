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
/// with its width (path_len 0x42, never 0x04), and that the route keeps
/// that width — on the radio and in the app — after the radio is switched
/// to 1-byte hashes. Repeaters forward by the width bits in each packet, so
/// such a route still delivers; nothing may "repair" it.
///
/// USB only, zero RF: add/get contact and set-hash-mode never transmit. A
/// synthetic repeater contact is added and removed again; the radio's hash
/// width is put back to what it was.
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

  void expectStoredRoute(Uint8List? frame, String when) {
    expect(frame, isNotNull, reason: 'contact fetch timed out ($when)');
    blog('$when: stored path_len 0x${frame![35].toRadixString(16)} '
        'path ${PathHelper.formatPathHex(frame.sublist(36, 40), stride: 2)}');
    expect(frame[35], 0x42, reason: '$when: radio must hold 2 hops × 2 bytes');
    expect(frame.sublist(36, 40), route);
    final inMemory = probe();
    expect(inMemory, isNotNull);
    expect(inMemory!.pathLabel, '2 hops');
    expect(inMemory.displayPathString, 'A277,BEEF');
  }

  testWidgets('a 2-byte route is written as 0x42 and survives a mode switch',
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
      expectStoredRoute(await fetchRawContactFrame(probeKey), 'at width 2');

      // The radio now runs at 1 byte. The route is still 2 hops of 2 bytes
      // everywhere; nothing re-reads it as four 1-byte hops.
      await setWidth(1);
      blog('re-reading WIDTH-PROBE with the radio at width 1');
      await c.getContactByKey(probeKey);
      await Future<void>.delayed(const Duration(seconds: 2));
      expectStoredRoute(await fetchRawContactFrame(probeKey), 'at width 1');
      blog('PASS: 0x42 written and kept across the mode switch');
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
