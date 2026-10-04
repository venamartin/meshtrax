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

/// PROBE ONLY — diagnoses the "4 hops · A2,77,BE,EF" mislabeled route to
/// repeater MADONNA (prefix A377) reported from the phone.
///
/// Question under test: after a FLOOD login on a 2-byte-hash companion, what
/// does the far repeater's path return actually stamp into out_path_len?
///  * 0x42 (count 2, width 2) -> everything healthy, phone radio's DB entry
///    was stale/poisoned some other way.
///  * 0x04 (count 4, width 1)  -> the repeater echoes byte-count semantics:
///    old/transitional firmware at MADONNA mints broken routes for every
///    2-byte client. Confirms the standing diagnosis.
///
/// RF budget (live mesh, 910.525): at most TWO login floods from us; the
/// path reset and contact fetches are USB-only. Nothing else transmits.
///
/// Run with:
///   flutter test integration_test/madonna_login_probe_test.dart -d windows \
///     --dart-define=MADONNA_PASSWORD=xxxxxx
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = String.fromEnvironment('MADONNA_PASSWORD');
  const madonnaPrefix = 'a377';

  const usaFreqKhz = 910525;
  const usaBwHz = 62500;
  const usaSf = 7;
  const usaCr = 5;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  Contact? madonna;
  var ready = false;

  String hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  /// Decodes a wire path_len byte for the log: raw, count, width.
  String describePathLen(int raw) {
    final b = raw & 0xFF;
    if (b == 0xFF) return '0xFF (no route / flood)';
    final count = b & 0x3F;
    final width = ((b >> 6) & 0x03) + 1;
    return '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()} '
        '(count=$count, width=$width byte(s))';
  }

  /// Fetches ONE contact frame raw off the wire (USB only, no RF) so the
  /// un-parsed path_len byte at offset 35 is visible.
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

  void logStoredRoute(String when, Uint8List frame) {
    final pathLenByte = frame[35];
    final byteLen = extractPathByteLen(pathLenByte);
    final pathBytes = frame.sublist(36, 36 + maxPathSize).sublist(
        0, byteLen.clamp(0, maxPathSize));
    blog('--- stored route $when ---');
    blog('path_len byte: ${describePathLen(pathLenByte)}');
    blog('path bytes   : ${pathBytes.isEmpty ? '(none)' : hex(pathBytes)}');
    if (pathBytes.isNotEmpty) {
      blog('  as width 1 : ${PathHelper.formatPathHex(pathBytes, stride: 1)}');
      blog('  as width 2 : ${PathHelper.formatPathHex(pathBytes, stride: 2)}');
    }
  }

  testWidgets('P0 bring-up: USB companion on the mesh preset', (tester) async {
    await beginScenario(tester, 'P0 MADONNA probe bring-up');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    if (password.isEmpty) {
      fail('Pass the repeater password: '
          '--dart-define=MADONNA_PASSWORD=xxxxxx');
    }

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();

    final c = usb.connector;
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…)');
    blog('firmware path hash width: ${c.pathHashByteWidth} byte(s)');
    if (c.pathHashByteWidth != 2) {
      blog('setting path hash mode to 2-byte (owner instruction)');
      await c.setPathHashMode(1); // mode 1 = 2-byte hashes
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await c.refreshDeviceInfo();
      await waitUntil(() => c.pathHashByteWidth == 2,
          'device info confirms 2-byte path hash width',
          timeout: const Duration(seconds: 15));
      blog('path hash width now ${c.pathHashByteWidth} byte(s)');
    }
    await waitUntil(() => c.currentFreqHz != null && c.currentSf != null,
        'radio params known');
    blog('freq=${(c.currentFreqHz! / 1000).toStringAsFixed(3)} MHz '
        'bw=${c.currentBwHz} sf=${c.currentSf} cr=${c.currentCr}');

    final onPreset = c.currentFreqHz == usaFreqKhz &&
        c.currentBwHz == usaBwHz &&
        c.currentSf == usaSf &&
        (c.currentCr == usaCr || c.currentCr == usaCr - 4);
    if (!onPreset) {
      blog('retuning to USA/Canada preset (910.525 / 62.5 / SF7 / CR5)');
      await c.sendFrame(
          buildSetRadioParamsFrame(usaFreqKhz, usaBwHz, usaSf, usaCr));
      await Future<void>.delayed(const Duration(seconds: 1));
      await c.refreshDeviceInfo();
      await waitUntil(() => c.currentFreqHz == usaFreqKhz,
          'frequency confirms 910.525 MHz',
          timeout: const Duration(seconds: 20));
    }

    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contact table synced', timeout: const Duration(seconds: 60));
    blog('${c.contacts.length} contacts');

    madonna = c.allContacts.cast<Contact?>().firstWhere(
          (x) =>
              x!.publicKeyHex.toLowerCase().startsWith(madonnaPrefix) ||
              x.name.toUpperCase().contains('MADONNA'),
          orElse: () => null,
        );
    if (madonna == null) {
      final nearMisses = c.allContacts
          .where((x) =>
              x.name.toUpperCase().contains('MAD') ||
              x.name.toUpperCase().contains('DONNA') ||
              x.publicKeyHex.toLowerCase().startsWith('a3'))
          .map((x) => '"${x.name}" <${x.publicKeyHex.substring(0, 8)}…> '
              'type=${x.type}')
          .toList();
      blog('near misses: ${nearMisses.isEmpty ? '(none)' : nearMisses.join('; ')}');
      final repeaters = c.allContacts
          .where((x) => x.type == advTypeRepeater)
          .map((x) => '"${x.name}" <${x.publicKeyHex.substring(0, 4)}>')
          .toList();
      blog('repeaters on radio (${repeaters.length}): '
          '${repeaters.take(40).join('; ')}');
    }
    expect(madonna, isNotNull,
        reason: 'No contact with prefix $madonnaPrefix / name MADONNA on '
            'the USB companion');

    // Discovered-only contacts are not in the radio's DB, so the raw
    // contact fetch (and a non-anon login) needs an import first. USB only.
    final inRadioDb = c.contacts
        .any((x) => x.publicKeyHex == madonna!.publicKeyHex);
    if (!inRadioDb) {
      blog('MADONNA is discovered-only — importing to the radio DB (no RF)');
      final okImport = await c.importDiscoveredContact(madonna!);
      expect(okImport, isTrue, reason: 'import of MADONNA failed');
      await waitUntil(
          () => c.contacts
              .any((x) => x.publicKeyHex == madonna!.publicKeyHex),
          'MADONNA saved to contacts');
      madonna = c.contacts
          .firstWhere((x) => x.publicKeyHex == madonna!.publicKeyHex);
    }
    blog('target: ${madonna!.name} (${madonna!.shortPubKeyHex})');
    blog('app-parsed: pathLength=${madonna!.pathLength} '
        'pathHashSize=${madonna!.pathHashSize} '
        'pathIdList="${madonna!.pathIdList}"');

    // Context: do the two suspected 2-byte repeaters actually exist?
    for (final p in const ['a277', 'beef', 'a2', '77', 'be', 'ef']) {
      final hits = c.allContacts
          .where((x) =>
              (x.type == advTypeRepeater || x.type == advTypeRoom) &&
              x.publicKeyHex.toLowerCase().startsWith(p))
          .map((x) => '${x.name} <${x.publicKeyHex.substring(0, 8)}…>')
          .toList();
      if (hits.isNotEmpty) blog('repeaters matching "$p": ${hits.join(', ')}');
    }
    ready = true;
  });

  testWidgets('P1 snapshot stored route, flood login, inspect learned route',
      (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'P1 MADONNA flood-login probe');
    final c = usb.connector;
    final key = madonna!.publicKey;

    final before = await fetchRawContactFrame(key);
    expect(before, isNotNull, reason: 'contact fetch (USB) timed out');
    logStoredRoute('BEFORE', before!);

    // Force the login to FLOOD so the route is re-learned from scratch —
    // this is the exact scenario that stamps out_path_len. USB-only command.
    blog('resetting stored path (CMD_RESET_PATH, no RF)');
    await c.sendFrame(buildResetPathFrame(key));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final afterReset = await fetchRawContactFrame(key);
    if (afterReset != null) logStoredRoute('after reset', afterReset);

    // Generous single-shot budget: multi-hop flood both ways on a live mesh.
    bool? ok;
    bool admin = false;
    for (var attempt = 1; attempt <= 2 && ok == null; attempt++) {
      blog('login attempt $attempt/2 (flood)…');
      (ok, admin) = await repeaterLogin(usb, madonna!, password,
          timeout: const Duration(seconds: 40));
      if (ok == null) blog('   no reply in 40 s');
    }
    blog('login result: ${ok == null ? 'TIMEOUT' : ok ? 'SUCCESS' : 'FAIL'}'
        '${ok == true ? ' (admin=$admin)' : ''}');

    // Whatever happened, the radio may have learned a route from the reply.
    await Future<void>.delayed(const Duration(seconds: 3));
    final after = await fetchRawContactFrame(key);
    expect(after, isNotNull, reason: 'contact fetch (USB) timed out');
    logStoredRoute('AFTER LOGIN', after!);

    final rawAfter = after[35];
    if ((rawAfter & 0xFF) == 0xFF) {
      blog('VERDICT: no route learned (no path return heard).');
    } else {
      final width = ((rawAfter >> 6) & 0x03) + 1;
      if (width == c.pathHashByteWidth) {
        blog('VERDICT: route width matches the radio ($width B) — healthy '
            'path return. The phone DB entry was poisoned some other way.');
      } else {
        blog('VERDICT: route came back width=$width while the radio floods '
            'at ${c.pathHashByteWidth} — the far node re-stamped the '
            'path_len. Confirms old/transitional firmware at MADONNA.');
      }
    }
  });
}
