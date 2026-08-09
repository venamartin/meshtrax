import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/repeater_command_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// Repeater command latency against F857 — diagnosis and fix verification.
///
/// WHY THIS EXISTS. Simple commands to a repeater in the same room timed out
/// constantly. The link was never the problem: 100+ round trips measured
/// 954-1009 ms at -46 dBm with the channel 3% occupied. Three app-side
/// defects were:
///
///   1. GIVE-UP POINT. RepeaterCommandService allowed max(8000, base*3) per
///      attempt — 12.4 s direct, 28.6 s flood — against a 1 s round trip.
///      About 5% of commands get no reply (a half-duplex repeater is deaf
///      while it forwards someone else's traffic), so one dropped packet
///      cost half a minute and three cost 86 s. Measured before the fix: a
///      two-command "Refresh radio settings" took 171,934 ms.
///   2. REPLY CROSS-TALK. handleResponse matched replies by their "NN|"
///      token but fell through, on a miss, to "complete whatever is pending".
///      Every reply arriving after the app gave up therefore landed on the
///      NEXT command. Confirmed on hardware: the app asked "get tx" and was
///      handed "910.5250244,62.5,7,5".
///   3. FLOOD RATCHET. preparePathForContactSend let route rotation pick
///      flood for a zero-hop contact, then wrote that choice back with
///      clearContactPath — erasing the direct path permanently.
///
/// FREQUENCY DISCIPLINE. Everything is measured on the off-mesh bench
/// frequency (920.000). F0 moves F857 there and F9 puts it back on the live
/// mesh. `set radio` only writes prefs ("OK - reboot to apply",
/// CommonCLI.cpp:585), so the saved value is read back and verified BEFORE
/// any reboot is sent. If a run is interrupted, restore_f857_test.dart puts
/// the repeater back on its own.
///
/// Run with:
///   flutter test integration_test/repeater_f857_latency_test.dart -d windows \
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

  /// Generous per-scenario: an aborted run skips F9, which strands F857.
  const rf = Timeout(Duration(minutes: 8));

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  Contact? f857;
  String? homeRadioLine;
  var repeaterMoved = false;
  var ready = false;

  final samples = <_Sample>[];

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  Contact live() => usb.connector.contacts.firstWhere(
        (c) => c.publicKeyHex == f857!.publicKeyHex,
        orElse: () => f857!,
      );

  Future<_Sample> cli(
    String command, {
    Duration timeout = const Duration(seconds: 12),
    String tag = '',
    bool quiet = false,
  }) async {
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
    final started = DateTime.now();
    try {
      await usb.connector
          .sendFrame(buildSendCliCommandFrame(f857!.publicKey, command));
      final reply =
          await completer.future.timeout(timeout, onTimeout: () => null);
      final ms = DateTime.now().difference(started).inMilliseconds;
      final sample = _Sample(tag: tag, ms: ms, reply: reply);
      samples.add(sample);
      if (!quiet) {
        blog('${tag.isEmpty ? '' : '[$tag] '}"$command" -> '
            '${reply == null ? 'NO REPLY' : '"${reply.trim()}"'}  [${ms}ms]');
      }
      return sample;
    } finally {
      await sub.cancel();
    }
  }

  /// For the frequency moves, which must land: ~5% of packets go missing and
  /// the consequence of a miss here is a repeater on the wrong band.
  Future<String?> cliInsist(String command, {int attempts = 6}) async {
    for (var i = 1; i <= attempts; i++) {
      final s = await cli(command, timeout: const Duration(seconds: 15));
      if (s.reply != null) return s.reply;
      blog('   attempt $i/$attempts got nothing, retrying');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  Future<(bool, bool)> login({int attempts = 4}) async {
    bool? ok;
    var admin = false;
    for (var i = 1; i <= attempts && ok != true; i++) {
      (ok, admin) = await repeaterLogin(usb, live(), password,
          timeout: const Duration(seconds: 15));
      if (ok == null) blog('   login attempt $i/$attempts: no reply');
      if (ok == false) break;
    }
    return (ok == true, admin);
  }

  String? value(String? r) => r?.replaceFirst(RegExp(r'^>\s*'), '').trim();

  /// Moves F857 to [targetKhz] and follows it with the companion. The prefs
  /// write is verified by read-back BEFORE the reboot that applies it, so a
  /// lost packet cannot strand the repeater.
  Future<bool> moveRepeater(int targetKhz, String bwSfCr) async {
    final mhz = (targetKhz / 1000).toStringAsFixed(3);
    blog('--- moving F857 to $mhz MHz ---');

    final setReply = await cliInsist('set radio $mhz,$bwSfCr');
    blog('set radio -> "${setReply?.trim() ?? '(no reply)'}"');
    if (setReply == null || setReply.toLowerCase().contains('error')) {
      blog('REFUSING to reboot: the write was never confirmed');
      return false;
    }

    final check = value(await cliInsist('get radio'));
    blog('saved prefs read back as: "$check"');
    final want = double.tryParse(mhz);
    final got = double.tryParse(check?.split(',').first ?? '');
    if (want == null || got == null || (got - want).abs() > 0.01) {
      blog('REFUSING to reboot: saved frequency is "$check", not $mhz');
      return false;
    }

    blog('write verified; rebooting F857 to apply');
    await cli('reboot', timeout: const Duration(seconds: 3), quiet: true);
    await Future<void>.delayed(const Duration(seconds: 9));
    await alignFrequency(usb, khz: targetKhz);

    for (var i = 1; i <= 8; i++) {
      final probe = await cli('get radio',
          timeout: const Duration(seconds: 12), quiet: true);
      if (probe.reply != null) {
        blog('F857 is up on $mhz MHz: "${value(probe.reply)}"');
        return true;
      }
      blog('   waiting for F857 on $mhz MHz ($i/8)');
      if (i == 3 || i == 6) await login(attempts: 2);
    }
    return false;
  }

  testWidgets('F0 take both radios off the mesh', (tester) async {
    await beginScenario(tester, 'F0 bring-up + move to 920');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    if (password.isEmpty) {
      fail('Pass the repeater password: '
          '--dart-define=BENCH_REPEATER_PASSWORD=xxxxxx');
    }

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();

    final c = usb.connector;
    blog('companion: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…)');
    await waitUntil(() => c.currentFreqHz != null && c.currentSf != null,
        'radio params known');
    await c.syncTime();

    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contact table synced', timeout: const Duration(seconds: 60));
    f857 = findContactByPrefix(c, BenchConfig.repeaterPubKeyPrefix,
        savedOnly: true);
    expect(f857, isNotNull, reason: 'F857 is not in the companion contacts');
    blog('target: ${f857!.name} (${f857!.shortPubKeyHex}) '
        'path="${f857!.pathLabel}" pathLen=${f857!.pathLength}');

    if (c.currentFreqHz != meshFreqKhz) {
      await alignFrequency(usb, khz: meshFreqKhz);
    }
    final (ok, admin) = await login();
    blog('login on the mesh frequency: ok=$ok admin=$admin');
    expect(ok && admin, isTrue,
        reason: 'no admin session on '
            '${(meshFreqKhz / 1000).toStringAsFixed(3)} MHz — F857 has not '
            'been moved anywhere');

    homeRadioLine = value(await cliInsist('get radio'));
    blog('F857 home radio line: "$homeRadioLine"');
    expect(homeRadioLine, isNotNull,
        reason: 'could not read F857\'s settings, so F9 would have nothing '
            'to restore — refusing to move it');
    final parts = homeRadioLine!.split(',');
    expect(parts.length, 4, reason: 'unexpected format "$homeRadioLine"');

    repeaterMoved = await moveRepeater(benchFreqKhz, parts.sublist(1).join(','));
    expect(repeaterMoved, isTrue,
        reason: 'F857 did not come up on the bench frequency');

    final (ok2, admin2) = await login();
    expect(ok2 && admin2, isTrue,
        reason: 'no admin session on the bench frequency');
    ready = true;
  }, timeout: rf);

  testWidgets('F1 the link itself', (tester) async {
    requireReady();
    await beginScenario(tester, 'F1 link');

    // 920.000 carries nothing but these two radios, so whatever is lost here
    // is the link and the repeater, not mesh congestion. Unhurried on
    // purpose: the no-gap burst in an earlier run coincided with the
    // companion locking up hard enough to need a power cycle, and that is
    // not what this run is trying to find out.
    for (var i = 1; i <= 6; i++) {
      await cli('get tx', timeout: const Duration(seconds: 20), tag: 'link');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    _report('F1 link', samples.where((s) => s.tag == 'link'));
  }, timeout: rf);

  testWidgets('F2 a zero-hop contact stays direct', (tester) async {
    requireReady();
    await beginScenario(tester, 'F2 flood ratchet');

    // Give the contact the direct path it should have — the ratchet may
    // already have demoted it in an earlier session, and the fix prevents
    // future demotion rather than healing a contact already at -1.
    await usb.connector.setContactPath(live(), Uint8List(0), 0);
    await Future<void>.delayed(const Duration(seconds: 1));
    blog('contact set to: pathLen=${live().pathLength} '
        '"${live().pathLabel}"');

    final service = RepeaterCommandService(usb.connector);
    try {
      final selection = await service.preparePath(live());
      blog('preparePath -> useFlood=${selection.useFlood} '
          'hops=${selection.hopCount}');
      blog('contact after preparePath: pathLen=${live().pathLength} '
          '"${live().pathLabel}"');

      expect(selection.useFlood, isFalse,
          reason: 'route rotation demoted a zero-hop neighbour to flood');
      expect(selection.hopCount, 0,
          reason: 'a direct contact resolved to a multi-hop path');
      expect(live().pathLength, 0,
          reason: 'the direct path was erased from the contact — this is the '
              'ratchet that makes the demotion permanent');
      blog('=== the direct path survived preparePath ===');
    } finally {
      service.dispose();
    }
  }, timeout: rf);

  testWidgets('F3 a stray reply no longer answers the wrong command',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'F3 reply cross-talk');

    final service = RepeaterCommandService(usb.connector);
    final sub = usb.connector.receivedFrames.listen((frame) {
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
      service.handleResponse(live(), parsed.text);
    });

    try {
      final selection = await service.preparePath(live());
      var crossed = 0;
      for (var round = 1; round <= 3; round++) {
        // A reply carrying a token that matches nothing pending. That is
        // exactly the state of a late reply: the firmware reflects the token
        // it was sent (simple_repeater/MyMesh.cpp:1211), and by the time it
        // arrives the app has cleaned that attempt up. "ZZ|" is never issued
        // by _nextPrefixToken, so it can never match.
        await usb.connector.sendFrame(
            buildSendCliCommandFrame(f857!.publicKey, 'ZZ|get radio'));
        await Future<void>.delayed(const Duration(milliseconds: 150));

        String? answer;
        try {
          answer = await service.sendCommand(live(), 'get tx',
              retries: 2, selection: selection);
        } catch (e) {
          answer = null;
        }
        final wrong = answer != null && answer.contains(',');
        if (wrong) crossed++;
        blog('  round $round: asked "get tx", got '
            '"${answer?.trim() ?? '(failed)'}"${wrong ? '  <- WRONG' : ''}');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      blog('=== stale-token replies delivered to the wrong command: '
          '$crossed/3 ===');
      expect(crossed, 0,
          reason: 'a reply whose token matches no pending command was still '
              'handed to whatever was waiting — this is how "get tx" came '
              'back as a frequency');
    } finally {
      await sub.cancel();
      service.dispose();
    }
  }, timeout: rf);

  testWidgets('F4 the settings-screen refresh, end to end', (tester) async {
    requireReady();
    await beginScenario(tester, 'F4 refresh radio settings');

    final service = RepeaterCommandService(usb.connector);
    final sub = usb.connector.receivedFrames.listen((frame) {
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
      service.handleResponse(live(), parsed.text);
    });

    try {
      // Exactly _refreshRadioSettings: one preparePath for the batch, the
      // screen's retry count, 200 ms between commands.
      final selection = await service.preparePath(live());
      blog('preparePath -> useFlood=${selection.useFlood} '
          'hops=${selection.hopCount}');

      final batchStarted = DateTime.now();
      final answers = <String, String?>{};
      for (final command in ['get radio', 'get tx']) {
        final started = DateTime.now();
        var attempts = 0;
        String? response;
        try {
          response = await service.sendCommand(live(), command,
              retries: 3, selection: selection, onAttempt: (n) => attempts = n);
        } catch (e) {
          response = null;
          blog('  "$command" FAILED: $e');
        }
        answers[command] = response;
        final ms = DateTime.now().difference(started).inMilliseconds;
        samples.add(_Sample(tag: 'service', ms: ms, reply: response));
        blog('  "$command" -> "${response?.trim() ?? 'FAILED'}"  '
            '[${ms}ms, $attempts attempt(s)]');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      final total = DateTime.now().difference(batchStarted).inMilliseconds;
      blog('=== "Refresh radio settings" end to end: ${total}ms '
          '(was 171934ms before the fix) ===');

      // The values must belong to the commands that asked for them — the
      // cross-talk bug swapped exactly this pair.
      final radio = answers['get radio'];
      final tx = answers['get tx'];
      if (radio != null) {
        expect(radio.contains(','), isTrue,
            reason: '"get radio" returned "$radio", which is not a radio line');
      }
      if (tx != null) {
        expect(tx.contains(','), isFalse,
            reason: '"get tx" returned "$tx" — that is a radio line, so a '
                'reply was delivered to the wrong command');
      }
    } finally {
      await sub.cancel();
      service.dispose();
    }
  }, timeout: rf);

  testWidgets('F5 verdict', (tester) async {
    requireReady();
    await beginScenario(tester, 'F5 verdict');

    _report('link', samples.where((s) => s.tag == 'link'));
    _report('service', samples.where((s) => s.tag == 'service'));

    final link = samples.where((s) => s.tag == 'link').toList();
    final lost = link.where((s) => s.reply == null).length;
    blog('=== VERDICT ===');
    blog('off-mesh, repeater in the room: $lost/${link.length} commands got '
        'no reply');
    final answered = link.where((s) => s.reply != null).toList();
    if (answered.isNotEmpty) {
      final t = answered.map((s) => s.ms).toList()..sort();
      blog('round trip: min ${t.first}ms median ${t[t.length ~/ 2]}ms '
          'max ${t.last}ms');
    }
  }, timeout: rf);

  testWidgets('F9 put F857 back on the mesh', (tester) async {
    await beginScenario(tester, 'F9 restore');

    if (f857 == null || homeRadioLine == null || !repeaterMoved) {
      blog('F857 was never moved; nothing to put back');
    } else {
      final parts = homeRadioLine!.split(',');
      final homeKhz = (double.parse(parts.first) * 1000).round();
      final back = await moveRepeater(homeKhz, parts.sublist(1).join(','));
      expect(back, isTrue,
          reason: 'F857 IS STILL OFF THE MESH. Its home settings are '
              '"$homeRadioLine" — run restore_f857_test.dart.');
      blog('F857 is back on ${parts.first} MHz');
    }

    await alignFrequency(usb, khz: benchFreqKhz);
    expect(usb.connector.currentFreqHz, benchFreqKhz);
    blog('companion parked on '
        '${(benchFreqKhz / 1000).toStringAsFixed(3)} MHz');
  }, timeout: rf);
}

class _Sample {
  _Sample({required this.tag, required this.ms, required this.reply});

  final String tag;
  final int ms;
  final String? reply;
}

void _report(String label, Iterable<_Sample> all) {
  final list = all.toList();
  if (list.isEmpty) return;
  final answered = list.where((s) => s.reply != null).toList();
  final lost = list.length - answered.length;
  if (answered.isEmpty) {
    blog('$label: 0/${list.length} answered');
    return;
  }
  final t = answered.map((s) => s.ms).toList()..sort();
  blog('$label: ${answered.length}/${list.length} answered, $lost lost — '
      'min ${t.first}ms median ${t[t.length ~/ 2]}ms max ${t.last}ms');
}
