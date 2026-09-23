import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// DM attempt ladder on the two-radio bench: the firmware owns the route.
///
///   L1  no route → the first DM floods; the PATH reply teaches the sender's
///       radio a route, which the app picks up (contact.pathLength >= 0)
///   L2  known route → the next DM goes direct, and the app pushes nothing
///   L3  a dead custom path (a hop nobody has) → attempt 0 times out,
///       attempt 1 resets the path and floods, the message is delivered on
///       attempt 1
///
/// Everything runs on the off-mesh bench frequency (920.000 MHz). L3 puts
/// exactly three frames on the air: one dead direct send, one flood, one
/// reply.
///
/// Run with:
///   flutter test integration_test/dm_ladder_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  String tag(String s) => 'lad[$runTag] $s';

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final radios = [usb, ble];
  final bridge = BleNusTcpBridge();
  var benchReady = false;

  void requireBench() {
    if (!benchReady) fail('Bench not ready — see L0 failure above.');
  }

  Contact bleOnUsb() => findContactByHex(
        usb.connector,
        ble.connector.selfPublicKeyHex,
        savedOnly: true,
      )!;
  Contact usbOnBle() => findContactByHex(
        ble.connector,
        usb.connector.selfPublicKeyHex,
        savedOnly: true,
      )!;

  Future<Message> sentCopy(String text) async {
    final copy = (await usb.connector.loadMessagesFor(bleOnUsb()))
        .where((m) => m.isOutgoing && m.text == text)
        .toList();
    expect(copy, hasLength(1), reason: 'sender copy of "$text"');
    return copy.single;
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

  testWidgets('L0 bench comes up: both radios connected on 920.000 MHz',
      (tester) async {
    await beginScenario(tester, 'L0 bench bring-up');
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
    expect(
      usb.connector.selfPublicKeyHex,
      isNot(equals(ble.connector.selfPublicKeyHex)),
      reason: 'Both transports reached the SAME radio — check the bench.',
    );

    await alignFrequency(usb);
    await alignFrequency(ble);

    blog('flooding self-adverts so the radios learn each other');
    await usb.connector.sendSelfAdvert(flood: true);
    await Future<void>.delayed(const Duration(seconds: 4));
    await ble.connector.sendSelfAdvert(flood: true);
    await ensureSavedContact(
        ble, usb.connector.selfPublicKeyHex, 'the USB radio');
    await ensureSavedContact(
        usb, ble.connector.selfPublicKeyHex, 'the BLE radio');

    // Start from no route and no override on the sender's side.
    await usb.connector.setPathOverride(bleOnUsb(), pathLen: null);
    await usb.connector.clearContactPath(bleOnUsb());
    await waitUntil(
      () => bleOnUsb().pathLength < 0,
      '${usb.label}: route to the BLE radio cleared',
    );

    benchReady = true;
    blog('bench ready');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('L1 no route: the first DM floods and the radio learns a route',
      (tester) async {
    await beginScenario(tester, 'L1 flood learns the route');
    requireBench();

    final t = tag('L1 flood');
    await usb.connector.sendMessage(bleOnUsb(), t);
    expect(await dmArrived(ble, usbOnBle(), t), isTrue,
        reason: 'flooded DM never arrived');
    expect(await awaitDmStatus(usb, bleOnUsb(), t), MessageStatus.delivered);

    final sent = await sentCopy(t);
    expect(sent.pathLength, -1, reason: 'attempt 0 should have flooded');
    expect(sent.retryCount, 0);

    await waitUntil(
      () => bleOnUsb().pathLength >= 0,
      '${usb.label}: firmware route learned from the PATH reply',
      timeout: const Duration(seconds: 30),
    );
    blog('learned route: ${bleOnUsb().pathLabel}');
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('L2 known route: the next DM goes direct, nothing pushed',
      (tester) async {
    await beginScenario(tester, 'L2 direct on the learned route');
    requireBench();
    final route = bleOnUsb();
    expect(route.pathLength, greaterThanOrEqualTo(0), reason: 'L1 first');

    final t = tag('L2 direct');
    await usb.connector.sendMessage(route, t);
    expect(await dmArrived(ble, usbOnBle(), t), isTrue,
        reason: 'direct DM never arrived');
    expect(await awaitDmStatus(usb, bleOnUsb(), t), MessageStatus.delivered);

    final sent = await sentCopy(t);
    expect(sent.pathLength, route.pathLength,
        reason: 'attempt 0 should have used the firmware route as-is');
    expect(sent.retryCount, 0);
    expect(bleOnUsb().pathLength, route.pathLength,
        reason: 'the route must survive a direct send untouched');
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('L3 dead custom path: retry floods and delivers on attempt 1',
      (tester) async {
    await beginScenario(tester, 'L3 dead path → flood fallback');
    requireBench();

    // One hop through a hash no node on the bench carries.
    final deadHop = Uint8List.fromList([0xEE]);
    await usb.connector.setPathOverride(bleOnUsb(),
        pathLen: 1, pathBytes: deadHop);
    expect(bleOnUsb().pathOverride, 1);

    final t = tag('L3 dead path');
    await usb.connector.sendMessage(bleOnUsb(), t);
    expect(await dmArrived(ble, usbOnBle(), t), isTrue,
        reason: 'the flood retry never arrived');
    expect(await awaitDmStatus(usb, bleOnUsb(), t), MessageStatus.delivered);

    final sent = await sentCopy(t);
    expect(sent.retryCount, 1, reason: 'delivered by the first flood retry');
    expect(sent.pathLength, -1, reason: 'the retry should have flooded');
    blog('attempt 1 flood delivered in ${sent.tripTimeMs} ms');

    await usb.connector.setPathOverride(bleOnUsb(), pathLen: null);
    expect(bleOnUsb().pathOverride, isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('L9 cleanup: no override left, radios stay on bench',
      (tester) async {
    await beginScenario(tester, 'L9 cleanup');
    requireBench();
    await usb.connector.setPathOverride(bleOnUsb(), pathLen: null);
    for (final r in radios) {
      expect(r.connector.currentFreqHz, equals(BenchConfig.targetFreqKhz),
          reason: '${r.label}: frequency drifted during the run');
    }
    blog('cleanup done — radios remain on 920.000 MHz for the bench');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
