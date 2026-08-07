import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// VERIFICATION ONLY — reproduces two reported repeater-admin failures
/// against real hardware. Fixes nothing; changes no app code.
///
///   1. A path set to Direct does not stick when moving between the
///      repeater management screens.
///   2. "Settings saved" is reported but nothing persists — TX power for
///      certain, possibly every other field too.
///
/// Drives the USB companion (COM14) on the USA/Canada preset and talks to
/// live repeater A277.
///
/// Run with:
///   flutter test integration_test/repeater_admin_verify_test.dart -d windows \
///     --dart-define=A277_PASSWORD=xxxxxx
///
/// Writes to the repeater are limited to TX power, which is restored to its
/// original value at the end. `set radio` is NEVER sent — see V4.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = String.fromEnvironment('A277_PASSWORD');
  const repeaterPrefix = 'a277';

  // USA/Canada preset (lib/models/radio_settings.dart).
  const usaFreqKhz = 910525;
  const usaBwHz = 62500;
  const usaSf = 7;
  const usaCr = 5;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  Contact? a277;
  int? originalTx;
  var ready = false;

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  /// Sends one CLI command and waits for the repeater's reply.
  Future<String?> cli(String command,
      {Duration timeout = const Duration(seconds: 45)}) async {
    final completer = Completer<String?>();
    final target = a277!.publicKey.sublist(0, 6);
    final sub = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] != respCodeContactMsgRecv &&
          frame[0] != respCodeContactMsgRecvV3) {
        return;
      }
      final parsed = parseContactMessageText(frame);
      if (parsed == null || parsed.senderPrefix.length < 6) return;
      if (!listEquals(parsed.senderPrefix.sublist(0, 6), target)) return;
      if (!completer.isCompleted) completer.complete(parsed.text);
    });
    try {
      blog('-> "$command"');
      await usb.connector.sendFrame(
          buildSendCliCommandFrame(a277!.publicKey, command));
      final reply = await completer.future
          .timeout(timeout, onTimeout: () => null);
      blog('<- ${reply == null ? "(no reply)" : '"$reply"'}');
      return reply;
    } finally {
      await sub.cancel();
    }
  }

  /// The link to A277 drops packets. Anything that must not be a false
  /// negative gets retried — exactly what RepeaterCommandService does for
  /// reads, and exactly what _saveSettings does NOT do for writes.
  Future<String?> cliRetry(String command, {int attempts = 3}) async {
    for (var i = 1; i <= attempts; i++) {
      final reply = await cli(command, timeout: const Duration(seconds: 30));
      if (reply != null) {
        if (i > 1) blog('   (took $i attempts)');
        return reply;
      }
      blog('   attempt $i/$attempts timed out');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  int? parseTx(String? reply) {
    if (reply == null) return null;
    final digits = reply.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(digits);
  }

  testWidgets('V0 USB companion up on the USA/Canada preset', (tester) async {
    await beginScenario(tester, 'V0 bring-up');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    if (password.isEmpty) {
      fail('Pass the repeater password: '
          '--dart-define=A277_PASSWORD=xxxxxx');
    }

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();

    final c = usb.connector;
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…)');
    await waitUntil(() => c.currentFreqHz != null && c.currentSf != null,
        'radio params known');
    blog('before: freq=${(c.currentFreqHz! / 1000).toStringAsFixed(3)} MHz '
        'bw=${c.currentBwHz} sf=${c.currentSf} cr=${c.currentCr}');

    final onPreset = c.currentFreqHz == usaFreqKhz &&
        c.currentBwHz == usaBwHz &&
        c.currentSf == usaSf &&
        (c.currentCr == usaCr || c.currentCr == usaCr - 4);
    if (!onPreset) {
      blog('retuning to the USA/Canada preset (910.525 / 62.5 / SF7 / CR5)');
      await c.sendFrame(
          buildSetRadioParamsFrame(usaFreqKhz, usaBwHz, usaSf, usaCr));
      await Future<void>.delayed(const Duration(seconds: 1));
      await c.refreshDeviceInfo();
      await waitUntil(() => c.currentFreqHz == usaFreqKhz,
          'frequency confirms 910.525 MHz',
          timeout: const Duration(seconds: 20));
    }
    blog('after:  freq=${(c.currentFreqHz! / 1000).toStringAsFixed(3)} MHz '
        'bw=${c.currentBwHz} sf=${c.currentSf} cr=${c.currentCr}');
    expect(c.currentFreqHz, usaFreqKhz);

    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contact table synced', timeout: const Duration(seconds: 60));
    blog('${c.contacts.length} contacts');

    a277 = c.contacts.cast<Contact?>().firstWhere(
          (x) => x!.publicKeyHex.toLowerCase().startsWith(repeaterPrefix),
          orElse: () => null,
        );
    expect(a277, isNotNull,
        reason: 'No contact starting $repeaterPrefix — is A277 in the '
            'companion contact list?');
    blog('target: ${a277!.name} (${a277!.shortPubKeyHex}) '
        'path=${a277!.pathLabel}');
    ready = true;
  });

  testWidgets('V1 Direct override survives a login + CLI round trip',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'V1 path override persistence');
    final c = usb.connector;

    Contact live() => c.contacts.firstWhere(
        (x) => x.publicKeyHex == a277!.publicKeyHex);

    await c.setPathOverride(a277!, pathLen: 0, pathBytes: Uint8List(0));
    blog('set Direct: override=${live().pathOverride} '
        'label="${live().pathLabel}"');
    expect(live().pathOverride, 0, reason: 'override did not take at all');

    // What every management screen calls before it sends anything.
    final selection = await c.preparePathForContactSend(live());
    blog('preparePathForContactSend -> useFlood=${selection.useFlood} '
        'hops=${selection.hopCount} bytes=${selection.pathBytes.length}');
    expect(selection.useFlood, isFalse,
        reason: 'Direct override resolved to FLOOD');
    expect(selection.hopCount, 0,
        reason: 'Direct override resolved to a multi-hop path');
    expect(live().pathOverride, 0,
        reason: 'preparing the send cleared the override');

    final (ok, admin) = await repeaterLogin(usb, live(), password);
    blog('login: ok=$ok admin=$admin');
    expect(ok, isTrue, reason: 'login to A277 failed');
    blog('after login: override=${live().pathOverride} '
        'devicePath=${live().pathLength} label="${live().pathLabel}"');
    expect(live().pathOverride, 0,
        reason: 'login cleared the Direct override');

    final reply = await cli('get tx');
    expect(reply, isNotNull, reason: 'no CLI reply — is A277 reachable?');
    blog('after CLI: override=${live().pathOverride} '
        'devicePath=${live().pathLength} label="${live().pathLabel}"');
    expect(live().pathOverride, 0,
        reason: 'a CLI round trip cleared the Direct override');

    // The same resolution a second screen would perform.
    final again = resolvePathSelection(live());
    blog('re-resolved: useFlood=${again.useFlood} hops=${again.hopCount}');
    expect(again.useFlood, isFalse);
    expect(again.hopCount, 0);
  });

  testWidgets('V2 a single set tx, waited on, sticks', (tester) async {
    requireReady();
    await beginScenario(tester, 'V2 does set tx work at all');

    originalTx = parseTx(await cliRetry('get tx'));
    blog('current TX power: $originalTx dBm');
    expect(originalTx, isNotNull, reason: 'could not read TX power');

    final target = originalTx == 5 ? 10 : 5;
    final setReply = await cliRetry('set tx $target');
    blog('SET REPLY for "set tx $target": "$setReply"');

    final readBack = parseTx(await cliRetry('get tx'));
    blog('READ BACK after set: $readBack dBm (wanted $target)');

    // Restore before asserting, so a failed assertion never leaves the
    // repeater on the test value.
    final restoreReply = await cliRetry('set tx $originalTx');
    blog('restore "set tx $originalTx" -> "$restoreReply"');
    final restored = parseTx(await cliRetry('get tx'));
    blog('RESTORED TO: $restored dBm (was $originalTx)');

    expect(readBack, target,
        reason: 'the repeater did not accept "set tx $target" — the app is '
            'not the only problem');
    expect(restored, originalTx, reason: 'FAILED TO RESTORE TX POWER');
  });

  testWidgets('V3 the save screens burst cadence: how much survives?',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'V3 blind 200 ms burst');

    // repeater_settings_screen._saveSettings fires every command back to
    // back, 200 ms apart, and never waits for or reads a reply. Replay
    // that cadence with READ-ONLY commands and count what comes back.
    const commands = [
      'get tx',
      'get name',
      'get repeat',
      'get allow.read.only',
      'get privacy',
      'get advert.interval',
      'get flood.advert.interval',
      'get lat',
    ];

    final replies = <String>[];
    final target = a277!.publicKey.sublist(0, 6);
    final sub = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] != respCodeContactMsgRecv &&
          frame[0] != respCodeContactMsgRecvV3) {
        return;
      }
      final parsed = parseContactMessageText(frame);
      if (parsed == null || parsed.senderPrefix.length < 6) return;
      if (!listEquals(parsed.senderPrefix.sublist(0, 6), target)) return;
      replies.add(parsed.text);
      blog('<- reply ${replies.length}: "${parsed.text}"');
    });

    try {
      for (final command in commands) {
        blog('-> "$command"');
        await usb.connector.sendFrame(
            buildSendCliCommandFrame(a277!.publicKey, command));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      blog('all ${commands.length} sent; collecting replies for 90 s…');
      await Future<void>.delayed(const Duration(seconds: 90));
    } finally {
      await sub.cancel();
    }

    blog('BURST RESULT: ${replies.length}/${commands.length} replied');
    for (final r in replies) {
      blog('  "$r"');
    }
    // Recorded, not asserted — this measurement IS the finding.
    expect(replies.length, lessThanOrEqualTo(commands.length));
  });

  testWidgets('V4 report', (tester) async {
    await beginScenario(tester, 'V4 summary');
    blog('--- verification summary ---');
    blog('A277 TX power left at: $originalTx dBm');
    blog('NOTE (code inspection, deliberately NOT exercised here):');
    blog('  repeater_settings_screen._saveSettings builds "set radio '
        '\${freqMHz.toStringAsFixed(1)} ..." — one decimal. On the USA '
        'preset that sends "set radio 910.5", retuning the repeater off '
        '910.525 MHz and out of reach. Never fired at live hardware.');
  });
}
