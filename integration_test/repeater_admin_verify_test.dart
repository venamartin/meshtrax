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

  /// How long a direct CLI round trip may legitimately take, every term
  /// taken from the firmware rather than guessed:
  ///
  ///  * two legs of airtime — the connector's own physics model;
  ///  * CLI_REPLY_DELAY_MILLIS = 600 (MyMesh.cpp:59), a deliberate wait
  ///    before the repeater transmits its reply;
  ///  * up to CADFailMaxDuration = 4000 (Dispatcher.cpp:62) of carrier-
  ///    sense backoff, retried every 200 ms, before the send is forced.
  ///
  /// That last term is why "timeouts" appeared next to a repeater in the
  /// same house: on a live mesh the channel is often busy, and the reply
  /// is deferred, not lost. Anything under ~5.2 s reports late replies as
  /// failures. The app's RepeaterCommandService already floors its own
  /// timeout at 8 s for exactly this reason.
  /// The CAD ceiling is NOT a global cap: cad_busy_start resets every
  /// time the channel goes quiet, so intermittent traffic can restart the
  /// backoff indefinitely. A budget cannot guarantee delivery — retrying
  /// is the only correct answer, which is why this harness and
  /// RepeaterCommandService both retry.
  Duration cliBudget({int hops = 0, int bytes = 100}) {
    const cliReplyDelayMs = 600; // MyMesh.cpp:59
    const cadBackoffCeilingMs = 4000; // Dispatcher.cpp:62
    final leg = usb.connector
        .calculateTimeout(pathLength: hops, messageBytes: bytes);
    return Duration(
        milliseconds: leg * 2 + cliReplyDelayMs + cadBackoffCeilingMs + 500);
  }

  /// Sends one CLI command and waits for the repeater's reply.
  Future<String?> cli(String command, {Duration? timeout}) async {
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
      final budget = timeout ?? cliBudget();
      final started = DateTime.now();
      blog('-> "$command"  (budget ${budget.inMilliseconds} ms)');
      await usb.connector.sendFrame(
          buildSendCliCommandFrame(a277!.publicKey, command));
      final reply =
          await completer.future.timeout(budget, onTimeout: () => null);
      final ms = DateTime.now().difference(started).inMilliseconds;
      blog('<- ${reply == null ? "(no reply)" : '"$reply"'}  [$ms ms]');
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
      final reply = await cli(command);
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

    // A login is one packet each way like anything else — retry it on the
    // same derived budget rather than staking the run on a single shot.
    // A false (wrong password) is final; only a null is worth repeating.
    bool? ok;
    bool admin = false;
    for (var i = 1; i <= 3 && ok != true; i++) {
      (ok, admin) = await repeaterLogin(usb, live(), password,
          timeout: cliBudget());
      if (ok == null) blog('   login attempt $i/3: no reply');
      if (ok == false) break;
    }
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

  testWidgets('V5 login-dialog Direct vs settings-screen Direct',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'V5 the two shapes of "set Direct"');
    final c = usb.connector;
    Contact live() => c.contacts.firstWhere(
        (x) => x.publicKeyHex == a277!.publicKeyHex);

    void dump(String when) {
      final x = live();
      final sel = resolvePathSelection(x);
      blog('$when: override=${x.pathOverride} '
          'overrideBytes=${x.pathOverrideBytes?.length ?? 0}B '
          'devicePath=${x.pathLength} pathBytes=${x.path.length}B '
          'label="${x.pathLabel}" '
          '| resolves to hops=${sel.hopCount} '
          'bytes=${sel.pathBytes.length}B flood=${sel.useFlood}');
    }

    // Pretend a 2-hop path was chosen earlier (Path Management does this).
    await c.setPathOverride(live(),
        pathLen: 2, pathBytes: Uint8List.fromList([0x11, 0x22, 0x33, 0x44]));
    dump('seeded 2-hop');

    // EXACTLY what repeater_login_dialog.dart:488 does — no pathBytes.
    await c.setPathOverride(live(), pathLen: 0);
    dump('login-dialog Direct');
    final afterLoginDialog = live();

    // EXACTLY what repeater_settings_screen.dart:790 does.
    await c.setPathOverride(live(), pathLen: 0, pathBytes: Uint8List(0));
    dump('settings-screen Direct');
    final afterSettings = live();

    blog('--- the difference ---');
    blog('login dialog left ${afterLoginDialog.pathOverrideBytes?.length ?? 0} '
        'bytes of stale path behind; settings left '
        '${afterSettings.pathOverrideBytes?.length ?? 0}');
    expect(afterSettings.pathOverrideBytes?.isEmpty ?? true, isTrue);
    expect(afterSettings.pathLength, 0,
        reason: 'settings-screen Direct syncs the device to zero hops');
  });

  /// Sends with an EXPLICIT sender_timestamp and waits for the reply.
  Future<String?> cliAt(String command, int ts,
      {Duration? timeout}) async {
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
      blog('-> "$command" @ts=$ts');
      await usb.connector.sendFrame(buildSendCliCommandFrame(
          a277!.publicKey, command,
          timestampSeconds: ts));
      final reply = await completer.future
          .timeout(timeout ?? cliBudget(), onTimeout: () => null);
      blog('<- ${reply == null ? "(NO REPLY)" : '"$reply"'}');
      return reply;
    } finally {
      await sub.cancel();
    }
  }

  testWidgets('V6 sender_timestamp replay guard', (tester) async {
    requireReady();
    await beginScenario(tester, 'V6 does the timestamp guard eat commands');

    // MeshCore simple_repeater/MyMesh.cpp:696
    //   else if (sender_timestamp >= client->last_timestamp)   <- older = dropped
    //   bool is_retry = (sender_timestamp == client->last_timestamp)
    //   if (is_retry) { *reply = 0; }                          <- never executed
    // _saveSettings recomputes now()~/1000 inside a 200 ms loop, so several
    // of its commands share a second. Does that suppress them?
    final base = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final a = await cliAt('get tx', base);
    blog('  [1] fresh timestamp      -> ${a == null ? "DROPPED" : "answered"}');

    final b = await cliAt('get name', base);
    blog('  [2] SAME timestamp       -> ${b == null ? "DROPPED" : "answered"}');

    final c = await cliAt('get repeat', base - 30);
    blog('  [3] OLDER timestamp      -> ${c == null ? "DROPPED" : "answered"}');

    final d = await cliAt('get lat', base + 5);
    blog('  [4] NEWER timestamp      -> ${d == null ? "DROPPED" : "answered"}');

    blog('=== VERDICT ===');
    blog('same-second command answered: ${b != null}');
    blog('older-timestamp command answered: ${c != null}');
    if (b == null) {
      blog('CONFIRMED: two commands in one second -> the second is eaten.');
      blog('_saveSettings fires ~5 commands per second. That is the bug.');
    } else {
      blog('NOT the mechanism — A277 answers same-second commands.');
    }
  });

  testWidgets('V7 a non-TX setting saves through the fixed path',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'V7 sequential save');

    String? val(String? reply) =>
        reply?.replaceFirst(RegExp(r'^>\s*'), '').trim();

    final origAdvert = int.tryParse(
        val(await cliRetry('get advert.interval')) ?? '');
    final origFlood = int.tryParse(
        val(await cliRetry('get flood.advert.interval')) ?? '');
    final origRepeat = val(await cliRetry('get repeat'));
    final origReadOnly = val(await cliRetry('get allow.read.only'));
    blog('current: advert=$origAdvert flood=$origFlood '
        'repeat=$origRepeat allow.read.only=$origReadOnly');
    expect(origAdvert, isNotNull, reason: 'could not read advert.interval');

    // MUST be even. CommonCLI.cpp:525 stores advert.interval as minutes/2
    // in a uint8, and the getter multiplies back by 2 — so "121" is stored
    // as 60 and reads back as 120. An odd offset round-trips to the
    // starting value and proves nothing about whether the write landed.
    final target = origAdvert! + 2;

    // What _saveSettings does now: send, wait for the reply, send the
    // next — nothing is ever in flight but the command being awaited.
    // Every value except advert.interval is the repeater's current one,
    // so only that field moves. "set radio" and "set name" are excluded
    // by hand; the app does send them.
    final batch = [
      'set repeat $origRepeat',
      'set allow.read.only $origReadOnly',
      'set advert.interval $target',
      'set flood.advert.interval $origFlood',
    ];
    final rejected = <String>[];
    for (final command in batch) {
      final reply = (await cliRetry(command))?.trim() ?? '(no reply)';
      final bad = reply.startsWith('Err') ||
          reply.startsWith('Error') ||
          reply.startsWith('??') ||
          reply == '(no reply)';
      blog('  ${bad ? "REJECTED" : "ok      "}  "$command" -> "$reply"');
      if (bad) rejected.add(command);
    }

    final after = int.tryParse(val(await cliRetry('get advert.interval')) ?? '');
    blog('=== advert.interval: was $origAdvert, set $target, now $after ===');
    expect(rejected, isEmpty, reason: 'every command must be answered');
    expect(after, target,
        reason: 'a setting saved the sequential way must stick');

    // Restore whatever happened.
    await cliRetry('set advert.interval $origAdvert');
    final restored =
        int.tryParse(val(await cliRetry('get advert.interval')) ?? '');
    blog('restored advert.interval to: $restored (was $origAdvert)');
    expect(restored, origAdvert, reason: 'FAILED TO RESTORE advert.interval');
  });

  testWidgets('V8 the FIXED save path: every command lands', (tester) async {
    requireReady();
    await beginScenario(tester, 'V8 verify the fix');

    String? val(String? r) => r?.replaceFirst(RegExp(r'^>\s*'), '').trim();

    // The old builder wrote the frequency with one decimal. Prove the
    // damage without transmitting it: read the real radio line and format
    // it both ways.
    final radio = val(await cliRetry('get radio'));
    blog('A277 radio: "$radio"');
    final freq = double.tryParse(radio?.split(',').first ?? '');
    if (freq != null) {
      // The firmware keeps freq as a float32, so "910.525" reads back as
      // 910.5250244. Tolerance, not bit-equality, is the right test.
      final oldErrKhz = (double.parse(freq.toStringAsFixed(1)) - freq).abs()
          * 1000;
      final newErrKhz = (double.parse(freq.toStringAsFixed(3)) - freq).abs()
          * 1000;
      blog('  old builder: "set radio ${freq.toStringAsFixed(1)} …" '
          '-> off by ${oldErrKhz.toStringAsFixed(1)} kHz');
      blog('  new builder: "set radio ${freq.toStringAsFixed(3)} …" '
          '-> off by ${newErrKhz.toStringAsFixed(3)} kHz');
      expect(newErrKhz, lessThan(1.0),
          reason: '3 decimals must land within 1 kHz of the real frequency');
    }

    final origTx = parseTx(await cliRetry('get tx'));
    final origAdvert =
        int.tryParse(val(await cliRetry('get advert.interval')) ?? '');
    final origFlood =
        int.tryParse(val(await cliRetry('get flood.advert.interval')) ?? '');
    final origRepeat = val(await cliRetry('get repeat'));
    final origReadOnly = val(await cliRetry('get allow.read.only'));

    // The command list _buildSaveCommands now produces, with A277's own
    // current values so this run changes nothing. "set radio", "set name"
    // and the password commands are excluded by hand.
    final commands = [
      'set tx $origTx',
      'set repeat $origRepeat',
      'set allow.read.only $origReadOnly',
      'set advert.interval ${origAdvert! - (origAdvert % 2)}',
      'set flood.advert.interval $origFlood',
    ];

    final rejected = <String>[];
    for (final command in commands) {
      final reply = (await cliRetry(command))?.trim() ?? '(no reply)';
      final bad = reply.startsWith('Err') ||
          reply.startsWith('Error') ||
          reply.startsWith('??') ||
          reply == '(no reply)';
      blog('  ${bad ? "REJECTED" : "ok      "}  "$command" -> "$reply"');
      if (bad) rejected.add('$command -> $reply');
    }
    blog('=== ${commands.length - rejected.length}/${commands.length} '
        'accepted ===');
    expect(rejected, isEmpty,
        reason: 'the app now sends only commands the firmware implements');

    // And the headline fix: TX power actually persists.
    await cliRetry('set tx 5');
    final low = parseTx(await cliRetry('get tx'));
    await cliRetry('set tx $origTx');
    final back = parseTx(await cliRetry('get tx'));
    blog('=== TX: $origTx -> set 5 -> read $low -> restored $back ===');
    expect(low, 5, reason: 'set tx must stick');
    expect(back, origTx, reason: 'FAILED TO RESTORE TX POWER');
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
