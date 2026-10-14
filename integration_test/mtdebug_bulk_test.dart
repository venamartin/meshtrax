
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// BULK DELIVERY CHECK — 20 out, 20 back, on the 920.000 bench frequency.
///
/// Phase 1: send N numbered messages on #mtdebug spaced by airtime, then
/// report the status each one's own copy reached. On a bench with no
/// repeater nothing ever reaches `delivered` (that status needs a heard
/// echo) — the RECEIVING end is the verdict, which is the point of
/// running this against a human on the other radio.
/// Phase 2: listen for the operator's N replies and report arrivals live.
///
/// Result 2026-08-15 (COM15 "graphnode" <-> GWQ∆🍓, 920.000 SF7 BW62.5k,
/// direct, no repeater): 20/20 out and 20/20 back, zero loss both ways.
/// Establishes that the client is not dropping channel messages; field
/// reports of missing messages point at RF conditions, not the app.
///
///   flutter test integration_test/mtdebug_bulk_test.dart -d windows \
///     --dart-define=MT_PORT=COM15
///
/// Optional: --dart-define=MT_COUNT=20  --dart-define=MT_RX_MINUTES=20
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const port = String.fromEnvironment('MT_PORT',
      defaultValue: BenchConfig.usbPortName);
  const count = int.fromEnvironment('MT_COUNT', defaultValue: 20);
  const rxMinutes = int.fromEnvironment('MT_RX_MINUTES', defaultValue: 20);
  // Distinct per run so a re-run never matches the previous run's rows.
  final tag = DateTime.now().millisecondsSinceEpoch
      .toRadixString(36)
      .substring(4)
      .toUpperCase();

  final usb = BenchRadio('USB($port)');
  final psk = Channel.derivePskFromHashtag('#mtdebug');
  final idKey = Channel.formatPskHex(psk);

  testWidgets('20 out, 20 back on #mtdebug', (tester) async {
    await beginScenario(tester, 'mtdebug bulk delivery');
    await PrefsManager.initialize();

    usb.connector = await buildConnector();
    await usb.connector.connectUsb(portName: port);
    await waitConnectedVerified(usb);
    blog('companion: ${usb.connector.selfName} on $port');

    await alignFrequency(usb, khz: BenchConfig.targetFreqKhz);
    final freq = usb.connector.currentFreqHz;
    expect(freq, BenchConfig.targetFreqKhz,
        reason: 'BENCH FREQUENCY ONLY — refusing to transmit off 920.000');
    blog('confirmed ${(freq! / 1000).toStringAsFixed(3)} MHz, '
        'sf=${usb.connector.currentSf} bw=${usb.connector.currentBwHz}');

    await awaitSyncIdle(usb);
    snapshotProtectedSlots(usb, {idKey});
    final channel = await ensureChannel(usb, '#mtdebug', psk);
    blog('#mtdebug slot ${channel.index} (idKey ${idKey.substring(0, 8)}…)');
    blog('run tag $tag — my messages read "$tag NN/$count"');

    // ── Phase 1: send ────────────────────────────────────────────────
    // Deliberately NOT awaiting each send to settle: with no repeater on
    // the bench frequency there is no echo to hear, so settling means
    // waiting out the 30 s timeout twenty times over. Fire them spaced
    // by airtime instead and read the statuses at the end.
    final sent = <String>[];
    for (var i = 1; i <= count; i++) {
      final text = '$tag ${i.toString().padLeft(2, '0')}/$count';
      blog('--> sending "$text"');
      await usb.connector.sendChannelMessage(channel, text);
      sent.add(text);
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    blog('all $count queued — letting the last one clear the air');
    await Future<void>.delayed(const Duration(seconds: 5));

    final statuses = <String, String>{};
    for (final t in sent) {
      statuses[t] = (await findOutgoing(usb, idKey, t))?.status.name ??
          'missing';
    }
    final delivered =
        statuses.values.where((s) => s == 'delivered').length;
    blog('');
    blog('=== SEND SUMMARY ===');
    for (final t in sent) {
      blog('  $t  ->  ${statuses[t]}');
    }
    blog('$delivered/$count reached "delivered" (echo heard); the rest '
        'may still have arrived — the receiving end is the real judge.');
    blog('NOTE: with no repeater echo, un-ACKed sends are retried '
        'automatically, so you may see duplicates. Count UNIQUE numbers '
        '01..$count, not total messages.');
    blog('');
    blog('>>> Your turn: send $count messages on #mtdebug. Listening for '
        '$rxMinutes minutes. <<<');

    // ── Phase 2: receive ─────────────────────────────────────────────
    // Only messages that ARRIVE from here on count. #mtdebug rows persist
    // across runs, so without this gate the tally replays every capture
    // session ever recorded (first run reported "And" via A277 — a live
    // mesh repeater that cannot exist on the bench frequency).
    final since = DateTime.now();
    final seen = <String>{};
    final deadline = DateTime.now().add(Duration(minutes: rxMinutes));
    var lastReport = 0;
    while (DateTime.now().isBefore(deadline)) {
      final live = liveByIdKey(usb.connector, idKey);
      if (live != null) {
        for (final m in await usb.connector.loadChannelMessagesFor(live)) {
          if (m.isOutgoing) continue;
          if (m.timestamp.isBefore(since)) continue; // stored history
          if (sent.contains(m.text)) continue; // our own, echoed back
          if (!seen.add('${m.senderName}|${m.text}')) continue;
          blog('<-- #${seen.length} from ${m.senderName}: "${m.text}"'
              '${m.pathBytes.isEmpty ? '' : ' via ${m.displayPathString}'}');
        }
      }
      if (seen.length >= count && lastReport != seen.length) {
        blog('all $count received — still listening until the window ends '
            'or you stop the run');
        lastReport = seen.length;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    blog('');
    blog('=== RECEIVE SUMMARY ===');
    blog('${seen.length} inbound message(s) heard in $rxMinutes min:');
    for (final s in seen) {
      final parts = s.split('|');
      blog('  ${parts.first}: ${parts.sublist(1).join('|')}');
    }
    blog('');
    blog('sent $count ($delivered echo-confirmed) · received ${seen.length}');
  }, timeout: const Timeout(Duration(minutes: 90)));
}
