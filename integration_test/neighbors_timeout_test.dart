import 'dart:async';
import 'dart:math' as math;

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
import 'harness/ble_nus_tcp_bridge.dart';

/// Binary-request (neighbors) timeout diagnosis against F857, from the BLE
/// companion — the same transport the phone uses.
///
/// Field report: the Neighbors screen shows "request timed out" and then,
/// moments later, "Received Neighbors Data". The screen sends ONE request
/// and arms ONE timer with calculateTimeout() — no retries, no escalation —
/// but its frame listener stays subscribed, so a reply arriving after the
/// timer still lands and turns the screen green. This suite measures what
/// the timer SHOULD have been:
///
///   N2  12 neighbors round trips, each recorded against three predictions:
///       what the screen uses today (messageBytes<=60, no contactKey), the
///       same with the repeater's contactKey, and one sized for the real
///       response — plus the companion's own est_timeout from the SENT frame
///   N3  CLI round trips for comparison (the path PR #81 already fixed)
///
/// FREQUENCY DISCIPLINE: measurements happen on 920.000 MHz. N0 moves F857
/// there (write, read-back verify, reboot) and N9 restores it; if a run is
/// cut short, restore_f857_test.dart recovers.
///
///   flutter test integration_test/neighbors_timeout_test.dart -d windows \
///     --dart-define=BENCH_REPEATER_PASSWORD=xxxxxx
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = BenchConfig.repeaterPassword;
  const benchFreqKhz = BenchConfig.targetFreqKhz;
  const meshFreqKhz = BenchConfig.meshFreqKhz;
  const rf = Timeout(Duration(minutes: 8));

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  Contact? f857;
  String? homeRadioLine;
  var repeaterMoved = false;
  var ready = false;

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  Contact live() => ble.connector.contacts.firstWhere(
        (c) => c.publicKeyHex == f857!.publicKeyHex,
        orElse: () => f857!,
      );

  Future<String?> cli(
    String command, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final completer = Completer<String?>();
    final target = f857!.publicKey.sublist(0, 6);
    final sub = ble.connector.receivedFrames.listen((frame) {
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
      await ble.connector
          .sendFrame(buildSendCliCommandFrame(f857!.publicKey, command));
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  Future<String?> cliInsist(String command, {int attempts = 6}) async {
    for (var i = 1; i <= attempts; i++) {
      final reply = await cli(command, timeout: const Duration(seconds: 15));
      if (reply != null) return reply;
      blog('   attempt $i/$attempts got nothing, retrying');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  Future<(bool, bool)> login({int attempts = 4}) async {
    bool? ok;
    var admin = false;
    for (var i = 1; i <= attempts && ok != true; i++) {
      (ok, admin) = await repeaterLogin(ble, live(), password,
          timeout: const Duration(seconds: 15));
      if (ok == null) blog('   login attempt $i/$attempts: no reply');
      if (ok == false) break;
    }
    return (ok == true, admin);
  }

  String? value(String? r) => r?.replaceFirst(RegExp(r'^>\s*'), '').trim();

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
    await cli('reboot', timeout: const Duration(seconds: 3));
    await Future<void>.delayed(const Duration(seconds: 9));
    await alignFrequency(ble, khz: targetKhz);

    for (var i = 1; i <= 8; i++) {
      final probe = await cli('get radio', timeout: const Duration(seconds: 12));
      if (probe != null) {
        blog('F857 is up on $mhz MHz: "${value(probe)}"');
        return true;
      }
      blog('   not answering yet ($i/8)');
      if (i % 3 == 0) await login();
      await Future<void>.delayed(const Duration(seconds: 4));
    }
    return false;
  }

  /// One neighbors binary request: send, wait for SENT (tag + the
  /// companion's own est_timeout), then the matching binary response.
  Future<({int? rttMs, int? companionEstMs, bool sent})> neighborsOnce({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final sentSeen = Completer<(Uint8List, int)>();
    final gotResponse = Completer<int>();
    Uint8List? tag;
    final started = DateTime.now();
    final sub = ble.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] == respCodeSent && frame.length >= 10) {
        final t = frame.sublist(2, 6);
        final est = frame[6] |
            (frame[7] << 8) |
            (frame[8] << 16) |
            (frame[9] << 24);
        tag = t;
        if (!sentSeen.isCompleted) sentSeen.complete((t, est));
      }
      if (frame[0] == pushCodeBinaryResponse &&
          frame.length >= 6 &&
          tag != null &&
          listEquals(frame.sublist(2, 6), tag)) {
        if (!gotResponse.isCompleted) {
          gotResponse
              .complete(DateTime.now().difference(started).inMilliseconds);
        }
      }
    });
    try {
      final frame = buildSendBinaryReq(
        f857!.publicKey,
        payload: Uint8List.fromList(
          [reqTypeGetNeighbors, 0x00, 0x0F, 0x00, 0x00, 0x00, 4],
        ),
      );
      await ble.connector.sendFrame(frame);
      final (_, est) = await sentSeen.future
          .timeout(const Duration(seconds: 5), onTimeout: () => (Uint8List(0), -1));
      if (est < 0) return (rttMs: null, companionEstMs: null, sent: false);
      final rtt =
          await gotResponse.future.timeout(timeout, onTimeout: () => -1);
      return (
        rttMs: rtt < 0 ? null : rtt,
        companionEstMs: est,
        sent: true,
      );
    } finally {
      await sub.cancel();
    }
  }

  tearDownAll(() async {
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('N0 bring-up: BLE companion, F857 moved to the bench frequency',
      (tester) async {
    await beginScenario(tester, 'N0 bring-up');
    if (password.isEmpty) {
      fail('run with --dart-define=BENCH_REPEATER_PASSWORD=…');
    }
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    ble.connector = await buildConnector();
    blog('starting BLE bridge…');
    await bridge.start();
    await ble.connector
        .connectTcp(host: '127.0.0.1', port: BenchConfig.bridgePort);
    await waitConnectedVerified(ble);
    await waitUntil(
        () => !ble.connector.isLoadingContacts &&
            ble.connector.contacts.isNotEmpty,
        'contacts synced',
        timeout: const Duration(seconds: 60));
    blog('BLE radio: ${ble.connector.selfName}');

    f857 = findContactByPrefix(ble.connector, BenchConfig.repeaterPubKeyPrefix,
        savedOnly: true);
    expect(f857, isNotNull,
        reason: 'F857 is not in the BLE radio\'s contacts — import it first');
    blog('repeater contact: ${f857!.name}');

    // F857 lives on the mesh; the move exchange is the one permitted,
    // minimal transmission there.
    await alignFrequency(ble, khz: meshFreqKhz);
    final (ok, admin) = await login();
    expect(ok, isTrue, reason: 'login on the mesh frequency failed');
    expect(admin, isTrue, reason: 'password did not grant admin');

    homeRadioLine = value(await cliInsist('get radio'));
    expect(homeRadioLine, isNotNull, reason: 'could not read the home radio');
    blog('F857 home radio: "$homeRadioLine"');
    final parts = homeRadioLine!.split(',');
    expect(parts.length, 4, reason: 'unexpected radio line: $homeRadioLine');

    repeaterMoved =
        await moveRepeater(benchFreqKhz, parts.sublist(1).join(','));
    expect(repeaterMoved, isTrue, reason: 'F857 never came up on 920.000');
    final (ok2, admin2) = await login();
    expect(ok2 && admin2, isTrue, reason: 'login on 920.000 failed');
    ready = true;
    blog('bench ready — measurements on 920.000 MHz only');
  }, timeout: rf);

  testWidgets('N2 neighbors round trips vs every timeout the app could use',
      (tester) async {
    await beginScenario(tester, 'N2 neighbors RTT measurement');
    requireReady();

    final rep = live();
    final key = rep.publicKeyHex;
    final rtts = <int>[];
    var losses = 0;
    var screenWouldTimeout = 0;

    for (var i = 1; i <= 12; i++) {
      final selection = await ble.connector.preparePathForContactSend(rep);
      final pathLen = selection.useFlood ? -1 : selection.hopCount;
      final reqFrame = buildSendBinaryReq(
        rep.publicKey,
        payload: Uint8List.fromList(
          [reqTypeGetNeighbors, 0x00, 0x0F, 0x00, 0x00, 0x00, 4],
        ),
      );
      // Exactly what neighbors_screen arms today.
      final predScreen = ble.connector.calculateTimeout(
        pathLength: pathLen,
        messageBytes: math.max(reqFrame.length, 60),
      );
      // The two obvious improvements, measured alongside.
      final predWithKey = ble.connector.calculateTimeout(
        pathLength: pathLen,
        messageBytes: math.max(reqFrame.length, 60),
        contactKey: key,
      );
      final predRespSized = ble.connector.calculateTimeout(
        pathLength: pathLen,
        messageBytes: 150,
        contactKey: key,
      );

      final r = await neighborsOnce();
      if (!r.sent) {
        blog('#$i: SENT never came back from the companion — skipping');
        continue;
      }
      if (r.rttMs == null) {
        losses++;
        blog('#$i: NO RESPONSE (path=$pathLen, screen would arm '
            '${predScreen}ms, companion est ${r.companionEstMs}ms)');
      } else {
        rtts.add(r.rttMs!);
        final timedOut = r.rttMs! > predScreen;
        if (timedOut) screenWouldTimeout++;
        blog('#$i: ${r.rttMs}ms  path=$pathLen  screen=${predScreen}ms'
            '${timedOut ? '  << SCREEN TIMES OUT' : ''}  '
            'withKey=${predWithKey}ms  respSized=${predRespSized}ms  '
            'companion=${r.companionEstMs}ms');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    expect(rtts, isNotEmpty, reason: 'no neighbors responses at all — is '
        'MAX_NEIGHBOURS enabled on this firmware?');
    rtts.sort();
    final median = rtts[rtts.length ~/ 2];
    blog('=== N2: ${rtts.length} ok, $losses lost | '
        'min=${rtts.first} med=$median max=${rtts.last} ms | '
        'screen timer would have fired on $screenWouldTimeout of '
        '${rtts.length} successful round trips ===');
  }, timeout: rf);

  testWidgets('N3 CLI round trips for comparison', (tester) async {
    await beginScenario(tester, 'N3 CLI comparison');
    requireReady();
    final rtts = <int>[];
    var losses = 0;
    for (var i = 1; i <= 6; i++) {
      final started = DateTime.now();
      final reply = await cli('clock', timeout: const Duration(seconds: 15));
      final ms = DateTime.now().difference(started).inMilliseconds;
      if (reply == null) {
        losses++;
        blog('#$i: NO REPLY');
      } else {
        rtts.add(ms);
        blog('#$i: ${ms}ms  "${value(reply)}"');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (rtts.isNotEmpty) {
      rtts.sort();
      blog('=== N3: ${rtts.length} ok, $losses lost | '
          'min=${rtts.first} med=${rtts[rtts.length ~/ 2]} '
          'max=${rtts.last} ms ===');
    }
  }, timeout: rf);

  testWidgets('N4 the retrying service path answers every request type',
      (tester) async {
    await beginScenario(tester, 'N4 service-path verification');
    requireReady();
    final service = RepeaterCommandService(ble.connector);
    try {
      final rep = live();

      // Neighbors through the new retry loop, 6 rounds.
      for (var i = 1; i <= 6; i++) {
        var attempts = 0;
        final started = DateTime.now();
        final payload = await service.sendBinaryRequest(
          rep,
          Uint8List.fromList(
            [reqTypeGetNeighbors, 0x00, 0x0F, 0x00, 0x00, 0x00, 4],
          ),
          onAttempt: (a) => attempts = a,
        );
        final ms = DateTime.now().difference(started).inMilliseconds;
        expect(payload.length, greaterThanOrEqualTo(4),
            reason: 'neighbors payload too short');
        blog('neighbors #$i: ${ms}ms in $attempts attempt(s), '
            '${payload.length}B payload');
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      // Status through the same loop.
      var attempts = 0;
      var started = DateTime.now();
      final statusFrame = await service.sendStatusRequest(
        rep,
        onAttempt: (a) => attempts = a,
      );
      blog('status: ${DateTime.now().difference(started).inMilliseconds}ms '
          'in $attempts attempt(s), ${statusFrame.length}B frame');
      expect(statusFrame[0], pushCodeStatusResponse);

      // Telemetry (repeater branch → binary request).
      attempts = 0;
      started = DateTime.now();
      final telemetry = await service.sendTelemetryRequest(
        rep,
        onAttempt: (a) => attempts = a,
      );
      blog('telemetry: '
          '${DateTime.now().difference(started).inMilliseconds}ms '
          'in $attempts attempt(s), ${telemetry.length}B payload');
      expect(telemetry, isNotEmpty);
      blog('=== N4: service path verified for all three request types ===');
    } finally {
      service.dispose();
    }
  }, timeout: rf);

  testWidgets('N9 restore F857 to the mesh', (tester) async {
    await beginScenario(tester, 'N9 restore');
    if (!repeaterMoved) {
      blog('F857 was never moved — nothing to restore');
      return;
    }
    final parts = homeRadioLine!.split(',');
    final homeKhz = (double.parse(parts.first) * 1000).round();
    final restored = await moveRepeater(homeKhz, parts.sublist(1).join(','));
    // Park the companion off-mesh regardless.
    await alignFrequency(ble, khz: benchFreqKhz);
    blog('companion parked on 920.000 MHz');
    expect(restored, isTrue,
        reason: 'F857 did not answer back on its home frequency — run '
            'restore_f857_test.dart');
    blog('=== F857 BACK ON THE MESH ===');
  }, timeout: rf);
}
