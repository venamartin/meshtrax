import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// RECOVERY — puts F857 back on the live mesh frequency.
///
/// A diagnostic run was cut short before its own restore step, leaving the
/// repeater on the off-mesh bench frequency. This does one job: find it on
/// 920.000, write its home radio settings back, reboot it onto the mesh, and
/// confirm it answers there. The companion is parked on 920.000 afterwards.
///
///   flutter test integration_test/restore_f857_test.dart -d windows \
///     --dart-define=BENCH_REPEATER_PASSWORD=xxxxxx \
///     --dart-define=F857_HOME_RADIO=910.5250244,62.5,7,5
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = BenchConfig.repeaterPassword;

  /// Exactly what `get radio` reported before the move.
  const homeRadio = String.fromEnvironment(
    'F857_HOME_RADIO',
    defaultValue: '910.5250244,62.5,7,5',
  );

  testWidgets('F857 back on the mesh', (tester) async {
    await beginScenario(tester, 'restore F857');
    await PrefsManager.initialize();

    final homeParts = homeRadio.split(',');
    expect(homeParts.length, 4, reason: 'bad F857_HOME_RADIO: "$homeRadio"');
    final homeKhz = (double.parse(homeParts.first) * 1000).round();
    final bwSfCr = homeParts.sublist(1).join(',');
    blog('restoring F857 to $homeRadio '
        '(${(homeKhz / 1000).toStringAsFixed(3)} MHz)');

    final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
    usb.connector = await buildConnector();
    await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
    await waitConnectedVerified(usb);
    await waitUntil(
        () => !usb.connector.isLoadingContacts &&
            usb.connector.contacts.isNotEmpty,
        'contacts synced',
        timeout: const Duration(seconds: 60));

    final f857 = findContactByPrefix(
        usb.connector, BenchConfig.repeaterPubKeyPrefix,
        savedOnly: true);
    expect(f857, isNotNull, reason: 'F857 is not in the companion contacts');
    Contact live() => usb.connector.contacts.firstWhere(
        (c) => c.publicKeyHex == f857!.publicKeyHex, orElse: () => f857!);

    Future<String?> cli(String command,
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
        await usb.connector.sendFrame(
            buildSendCliCommandFrame(f857.publicKey, command));
        return await completer.future.timeout(timeout, onTimeout: () => null);
      } finally {
        await sub.cancel();
      }
    }

    String? value(String? r) => r?.replaceFirst(RegExp(r'^>\s*'), '').trim();

    // Whatever silenced the link during the burst test may still be in
    // effect, so probe patiently rather than giving up after one miss.
    // Deliberately unhurried: 6 s between attempts, no bursts.
    Future<String?> waitForRepeater(String what, int rounds) async {
      for (var i = 1; i <= rounds; i++) {
        final reply = await cli('get radio');
        if (reply != null) {
          blog('$what: answering — "${value(reply)}"');
          return reply;
        }
        blog('$what: silent ($i/$rounds)');
        if (i % 4 == 0) {
          final (ok, admin) = await repeaterLogin(usb, live(), password,
              timeout: const Duration(seconds: 15));
          blog('   re-login: ok=$ok admin=$admin');
        }
        await Future<void>.delayed(const Duration(seconds: 6));
      }
      return null;
    }

    await alignFrequency(usb, khz: BenchConfig.targetFreqKhz);
    final (ok, admin) = await repeaterLogin(usb, live(), password,
        timeout: const Duration(seconds: 15));
    blog('login on 920.000: ok=$ok admin=$admin');

    final found = await waitForRepeater('F857 on 920.000', 14);
    if (found == null) {
      fail('F857 did not answer on 920.000 MHz after ~90s of patient '
          'probing. It is still configured for $homeRadio ONLY after a '
          'successful restore — right now it is on 920.000. Power-cycle it '
          'and re-run this test.');
    }

    // If it is already home, nothing to do.
    if (value(found)!.startsWith(homeParts.first.substring(0, 5))) {
      blog('F857 already reports $homeRadio — nothing to restore');
    } else {
      String? setReply;
      for (var i = 1; i <= 6 && setReply == null; i++) {
        setReply = await cli('set radio ${homeParts.first},$bwSfCr');
        if (setReply == null) {
          blog('set radio attempt $i/6: no reply');
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
      blog('set radio -> "${setReply?.trim() ?? '(no reply)'}"');
      expect(setReply, isNotNull, reason: 'could not write the home settings');

      String? check;
      for (var i = 1; i <= 6 && check == null; i++) {
        check = value(await cli('get radio'));
        if (check == null) await Future<void>.delayed(const Duration(seconds: 3));
      }
      blog('saved prefs read back as: "$check"');
      final got = double.tryParse(check?.split(',').first ?? '');
      expect(got, isNotNull, reason: 'could not verify the saved frequency');
      expect((got! - double.parse(homeParts.first)).abs() < 0.01, isTrue,
          reason: 'saved frequency is "$check", not ${homeParts.first} — '
              'NOT rebooting');

      blog('verified; rebooting F857 onto the mesh');
      await cli('reboot', timeout: const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(seconds: 10));
    }

    await alignFrequency(usb, khz: homeKhz);
    await repeaterLogin(usb, live(), password,
        timeout: const Duration(seconds: 15));
    final home = await waitForRepeater(
        'F857 on ${(homeKhz / 1000).toStringAsFixed(3)}', 10);

    // Park the companion off-mesh regardless of the outcome.
    await alignFrequency(usb, khz: BenchConfig.targetFreqKhz);
    blog('companion parked on 920.000 MHz');

    expect(home, isNotNull,
        reason: 'F857 did not answer on '
            '${(homeKhz / 1000).toStringAsFixed(3)} MHz. The write and '
            'reboot were sent; it may still be booting, or it needs a '
            'power cycle. Re-run to confirm.');
    blog('=== F857 IS BACK ON THE MESH: "${value(home)}" ===');
  }, timeout: const Timeout(Duration(minutes: 9)));
}
