import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/repeater_command_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// Does SAVING a repeater setting actually work, through the app's own
/// command service?
///
/// Reading was already covered; this exercises writes — the thing that was
/// reported as "settings saved but nothing persists". Every command goes
/// through RepeaterCommandService exactly as repeater_settings_screen does,
/// so the fixed give-up point and reply matching are under test too.
///
/// WHAT IS WRITTEN. TX power, advert.interval and flood.advert.interval.
/// Nothing that can cut the link — no frequency, no radio params, no name,
/// no passwords. Every original is read first and restored in W5, which runs
/// even when the scenarios before it fail.
///
/// Firmware validation these values must respect (CommonCLI.cpp):
///   * advert.interval        minutes, 0 or 60..240, stored as N/2 in a
///                            uint8 and read back doubled — so only EVEN
///                            values round-trip exactly (line 525)
///   * flood.advert.interval  hours, 0 or 3..168 (line 515)
///   * tx                     unvalidated, applied live via setTxPower;
///                            kept to 5..21 dBm by the owner's instruction
///
/// FREQUENCY DISCIPLINE. All of this happens on the off-mesh bench frequency
/// (920.000). W0 moves F857 there and W6 puts it back on the live mesh. The
/// prefs write is verified by read-back BEFORE the reboot that applies it, so
/// a lost packet cannot strand the repeater. If a run is interrupted,
/// restore_f857_test.dart recovers it.
///
/// Run with:
///   flutter test integration_test/repeater_settings_write_test.dart -d windows \
///     --dart-define=BENCH_REPEATER_PASSWORD=xxxxxx
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = BenchConfig.repeaterPassword;
  const benchFreqKhz = BenchConfig.targetFreqKhz;
  const meshFreqKhz = int.fromEnvironment(
    'BENCH_MESH_FREQ_KHZ',
    defaultValue: BenchConfig.meshFreqKhz,
  );
  const rf = Timeout(Duration(minutes: 8));

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  Contact? f857;
  String? homeRadioLine;
  var repeaterMoved = false;
  var ready = false;

  RepeaterCommandService? service;
  StreamSubscription<Uint8List>? replySub;
  PathSelection? selection;

  /// Read at W1, put back at W5. Null means "never successfully read", and
  /// W5 refuses to write a value it never confirmed.
  final originals = <String, String>{};

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  Contact live() => usb.connector.contacts.firstWhere(
        (c) => c.publicKeyHex == f857!.publicKeyHex,
        orElse: () => f857!,
      );

  String? strip(String? r) => r?.replaceFirst(RegExp(r'^>\s*'), '').trim();

  /// Raw CLI, used only for the frequency moves in W0/W6.
  Future<String?> rawCli(String command,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final completer = Completer<String?>();
    final target = f857!.publicKey.sublist(0, 6);
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
      await usb.connector
          .sendFrame(buildSendCliCommandFrame(f857!.publicKey, command));
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  Future<String?> rawInsist(String command, {int attempts = 6}) async {
    for (var i = 1; i <= attempts; i++) {
      final reply = await rawCli(command);
      if (reply != null) return reply;
      blog('   attempt $i/$attempts got nothing, retrying');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  /// One command through the app's own service, timed.
  Future<String?> appCli(String command, {int retries = 3}) async {
    final started = DateTime.now();
    String? response;
    var attempts = 0;
    try {
      response = await service!.sendCommand(live(), command,
          retries: retries,
          selection: selection,
          onAttempt: (n) => attempts = n);
    } catch (e) {
      response = null;
    }
    final ms = DateTime.now().difference(started).inMilliseconds;
    blog('  "$command" -> "${strip(response) ?? 'FAILED'}"  '
        '[${ms}ms, $attempts attempt(s)]');
    return response;
  }

  /// A write is only believed once a read-back agrees with it.
  Future<bool> writeAndVerify(String key, String wanted) async {
    final setReply = await appCli('set $key $wanted');
    if (setReply == null) {
      blog('  $key: no reply to the write');
      return false;
    }
    if (strip(setReply)!.toLowerCase().startsWith('err')) {
      blog('  $key: firmware REJECTED "$wanted" -> "${strip(setReply)}"');
      return false;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final readBack = strip(await appCli('get $key'));
    final ok = readBack == wanted;
    blog('  $key: wrote "$wanted", reads back "$readBack" '
        '${ok ? 'OK' : '<- MISMATCH'}');
    return ok;
  }

  Future<bool> moveRepeater(int targetKhz, String bwSfCr) async {
    final mhz = (targetKhz / 1000).toStringAsFixed(3);
    blog('--- moving F857 to $mhz MHz ---');
    final setReply = await rawInsist('set radio $mhz,$bwSfCr');
    blog('set radio -> "${setReply?.trim() ?? '(no reply)'}"');
    if (setReply == null || setReply.toLowerCase().contains('error')) {
      blog('REFUSING to reboot: the write was never confirmed');
      return false;
    }
    final check = strip(await rawInsist('get radio'));
    blog('saved prefs read back as: "$check"');
    final want = double.tryParse(mhz);
    final got = double.tryParse(check?.split(',').first ?? '');
    if (want == null || got == null || (got - want).abs() > 0.01) {
      blog('REFUSING to reboot: saved frequency is "$check", not $mhz');
      return false;
    }
    blog('write verified; rebooting F857 to apply');
    await rawCli('reboot', timeout: const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(seconds: 9));
    await alignFrequency(usb, khz: targetKhz);
    for (var i = 1; i <= 8; i++) {
      final probe = await rawCli('get radio');
      if (probe != null) {
        blog('F857 is up on $mhz MHz: "${strip(probe)}"');
        return true;
      }
      blog('   waiting for F857 on $mhz MHz ($i/8)');
      if (i == 3 || i == 6) {
        await repeaterLogin(usb, live(), password,
            timeout: const Duration(seconds: 15));
      }
    }
    return false;
  }

  testWidgets('W0 bring-up, take both radios off the mesh', (tester) async {
    await beginScenario(tester, 'W0 bring-up + move to 920');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    if (password.isEmpty) {
      fail('Pass the repeater password: '
          '--dart-define=BENCH_REPEATER_PASSWORD=xxxxxx');
    }

    usb.connector = await buildConnector();
    await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
    await waitConnectedVerified(usb);
    final c = usb.connector;
    blog('companion: ${c.selfName}');
    await waitUntil(() => c.currentFreqHz != null, 'radio params known');
    await c.syncTime();
    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contact table synced', timeout: const Duration(seconds: 60));

    f857 = findContactByPrefix(c, BenchConfig.repeaterPubKeyPrefix,
        savedOnly: true);
    expect(f857, isNotNull, reason: 'F857 is not in the companion contacts');
    blog('target: ${f857!.name} (${f857!.shortPubKeyHex})');

    if (c.currentFreqHz != meshFreqKhz) {
      await alignFrequency(usb, khz: meshFreqKhz);
    }
    var loggedIn = false;
    for (var i = 1; i <= 4 && !loggedIn; i++) {
      final (ok, admin) = await repeaterLogin(usb, live(), password,
          timeout: const Duration(seconds: 15));
      loggedIn = ok == true && admin;
      if (ok == false) break;
    }
    expect(loggedIn, isTrue, reason: 'no admin session on the mesh frequency');

    homeRadioLine = strip(await rawInsist('get radio'));
    expect(homeRadioLine, isNotNull,
        reason: 'could not read F857\'s radio line — refusing to move it');
    blog('F857 home radio line: "$homeRadioLine"');
    final parts = homeRadioLine!.split(',');
    expect(parts.length, 4);

    repeaterMoved = await moveRepeater(benchFreqKhz, parts.sublist(1).join(','));
    expect(repeaterMoved, isTrue,
        reason: 'F857 did not come up on the bench frequency');

    for (var i = 1; i <= 4; i++) {
      final (ok, admin) = await repeaterLogin(usb, live(), password,
          timeout: const Duration(seconds: 15));
      if (ok == true && admin) break;
    }

    // Everything from here goes through the app's own command service.
    service = RepeaterCommandService(usb.connector);
    replySub = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] != respCodeContactMsgRecv &&
          frame[0] != respCodeContactMsgRecvV3) {
        return;
      }
      final parsed = parseContactMessageText(frame);
      if (parsed == null || parsed.senderPrefix.length < 6) return;
      if (!listEquals(
          parsed.senderPrefix.sublist(0, 6), f857!.publicKey.sublist(0, 6))) {
        return;
      }
      service!.handleResponse(live(), parsed.text);
    });
    selection = await service!.preparePath(live());
    blog('preparePath -> useFlood=${selection!.useFlood} '
        'hops=${selection!.hopCount}');
    ready = true;
  }, timeout: rf);

  testWidgets('W1 record every original', (tester) async {
    requireReady();
    await beginScenario(tester, 'W1 originals');

    for (final key in ['tx', 'advert.interval', 'flood.advert.interval']) {
      String? v;
      for (var i = 1; i <= 3 && v == null; i++) {
        v = strip(await appCli('get $key'));
      }
      expect(v, isNotNull,
          reason: 'could not read "$key" — refusing to write anything, '
              'because W5 would have nothing to restore');
      originals[key] = v!;
    }
    blog('=== ORIGINALS: $originals ===');

    // advert.interval is stored as minutes/2 in a uint8 and read back
    // doubled, so a healthy repeater always reports an even number.
    final advert = int.tryParse(originals['advert.interval']!);
    expect(advert, isNotNull);
    expect(advert! % 2, 0,
        reason: 'advert.interval read back odd ($advert), which the firmware '
            'cannot represent — restoring it exactly would be impossible');
  }, timeout: rf);

  testWidgets('W2 TX power saves and reads back', (tester) async {
    requireReady();
    await beginScenario(tester, 'W2 set tx');

    final original = int.parse(originals['tx']!);
    // Both ends inside the 5..21 dBm the owner allowed, and far enough from
    // the original that a stale read cannot be mistaken for a success.
    final target = original >= 13 ? 8 : 18;
    blog('tx: $original dBm -> $target dBm');
    expect(await writeAndVerify('tx', '$target'), isTrue,
        reason: 'TX power did not persist — this is the reported '
            '"settings saved but nothing changed"');
  }, timeout: rf);

  testWidgets('W3 advert.interval saves and reads back', (tester) async {
    requireReady();
    await beginScenario(tester, 'W3 set advert.interval');

    final original = int.parse(originals['advert.interval']!);
    // Valid range is 0 or 60..240 minutes, and only even values round-trip.
    final target = original == 120 ? 180 : 120;
    blog('advert.interval: $original min -> $target min');
    expect(await writeAndVerify('advert.interval', '$target'), isTrue,
        reason: 'advert.interval did not persist');
  }, timeout: rf);

  testWidgets('W4 flood.advert.interval saves and reads back', (tester) async {
    requireReady();
    await beginScenario(tester, 'W4 set flood.advert.interval');

    final original = int.parse(originals['flood.advert.interval']!);
    // Valid range is 0 or 3..168 hours.
    final target = original == 6 ? 12 : 6;
    blog('flood.advert.interval: $original h -> $target h');
    expect(await writeAndVerify('flood.advert.interval', '$target'), isTrue,
        reason: 'flood.advert.interval did not persist');
  }, timeout: rf);

  testWidgets('W5 put every setting back', (tester) async {
    await beginScenario(tester, 'W5 restore settings');
    if (service == null || f857 == null || originals.isEmpty) {
      blog('nothing was written; nothing to restore');
      return;
    }

    // Runs whatever happened above. Restore order does not matter here:
    // every original advert.interval is either 0 or >= 60, so the firmware's
    // savePrefs() rule (advert_interval*2 < 60 is forced to 0) cannot
    // silently rewrite one while another setting is being saved.
    final failed = <String>[];
    for (final entry in originals.entries) {
      if (!await writeAndVerify(entry.key, entry.value)) {
        failed.add('${entry.key} -> ${entry.value}');
      }
    }
    blog(failed.isEmpty
        ? '=== ALL SETTINGS RESTORED: $originals ==='
        : '=== FAILED TO RESTORE: ${failed.join('; ')} ===');
    expect(failed, isEmpty,
        reason: 'F857 is NOT back to its original settings. Wanted '
            '$originals — set these by hand.');
  }, timeout: rf);

  testWidgets('W6 put F857 back on the mesh', (tester) async {
    await beginScenario(tester, 'W6 restore frequency');
    await replySub?.cancel();
    service?.dispose();

    if (f857 == null || homeRadioLine == null || !repeaterMoved) {
      blog('F857 was never moved; nothing to put back');
    } else {
      final parts = homeRadioLine!.split(',');
      final homeKhz = (double.parse(parts.first) * 1000).round();
      final back = await moveRepeater(homeKhz, parts.sublist(1).join(','));
      expect(back, isTrue,
          reason: 'F857 IS STILL OFF THE MESH. Home settings are '
              '"$homeRadioLine" — run restore_f857_test.dart.');
      blog('F857 is back on ${parts.first} MHz');
    }

    await alignFrequency(usb, khz: benchFreqKhz);
    expect(usb.connector.currentFreqHz, benchFreqKhz);
    blog('companion parked on '
        '${(benchFreqKhz / 1000).toStringAsFixed(3)} MHz');
  }, timeout: rf);
}
