import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// PASSIVE long-message repeat forensics — transmits NOTHING.
///
/// The BLE companion (GWQ 🚀, living on 910.525) listens on #mtdebug and
/// logs EVERY copy of every channel message it hears: sender, text length,
/// text prefix, and crucially the PATH LENGTH — 0 = direct from the
/// sender, >0 = a repeated copy. The user sends short and long messages
/// from a phone; if long messages show direct copies but never a
/// repeated one, repeaters really aren't forwarding them. If repeated
/// copies DO appear here while the sending phone shows "Retrying", the
/// bug is the app's repeat-echo matching instead.
///
///   flutter test integration_test/long_message_repeat_monitor_test.dart -d windows
///
/// Ends when a message containing "done" is heard on #mtdebug, or after
/// 30 minutes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  final psk = Channel.derivePskFromHashtag('#mtdebug');
  final idKey = Channel.formatPskHex(psk);

  tearDownAll(() async {
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('passive repeat monitor', (tester) async {
    await beginScenario(tester, 'long-message repeat monitor');
    await PrefsManager.initialize();

    await bridge.start();
    ble.connector = await buildConnector();
    await ble.connector.connectTcp(
      host: '127.0.0.1',
      port: BenchConfig.bridgePort,
    );
    await waitConnectedVerified(ble);
    blog('companion: ${ble.connector.selfName}');

    expect(ble.connector.currentFreqHz, BenchConfig.meshFreqKhz,
        reason: 'companion is not on 910.525 — refusing to run (this '
            'monitor assumes the live-mesh home frequency)');

    await awaitSyncIdle(ble);
    snapshotProtectedSlots(ble, {idKey});
    final channel = await ensureChannel(ble, '#mtdebug', psk);
    blog('#mtdebug in slot ${channel.index} — monitoring, zero TX');
    blog('>>> send test messages now; say "done" on #mtdebug to finish');

    final doneSignal = Completer<void>();
    // (text, per-copy path lengths seen) keyed by "sender|text"
    final copies = <String, List<int>>{};

    final sub = ble.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return;
      }
      final parsed = ChannelMessage.fromFrame(frame);
      if (parsed == null || parsed.channelIndex != channel.index) return;

      final pathLen = parsed.pathLength ?? -1;
      final key = '${parsed.senderName}|${parsed.text}';
      final seen = copies.putIfAbsent(key, () => []);
      seen.add(pathLen);
      final kind = pathLen <= 0
          ? 'DIRECT'
          : 'REPEATED($pathLen path bytes)';
      final preview = parsed.text.length > 40
          ? '${parsed.text.substring(0, 40)}…'
          : parsed.text;
      blog('COPY $kind  [${parsed.senderName}] len=${parsed.text.length} '
          '"${preview.replaceAll('\n', '\\n')}"  copies so far: $seen');

      if (RegExp(r'\bdone\b', caseSensitive: false).hasMatch(parsed.text)) {
        if (!doneSignal.isCompleted) doneSignal.complete();
      }
    });

    await doneSignal.future
        .timeout(const Duration(minutes: 30), onTimeout: () {});
    await sub.cancel();

    blog('=== SUMMARY (per message: path lengths of every copy heard) ===');
    copies.forEach((key, paths) {
      final sep = key.indexOf('|');
      final sender = key.substring(0, sep);
      final text = key.substring(sep + 1);
      final repeated = paths.any((p) => p > 0);
      blog('${repeated ? "REPEATED" : "DIRECT-ONLY"}  [$sender] '
          'len=${text.length} copies=$paths '
          '"${(text.length > 30 ? '${text.substring(0, 30)}…' : text).replaceAll('\n', '\\n')}"');
    });
    blog('=== monitor ended ===');
  }, timeout: const Timeout(Duration(minutes: 35)));
}
