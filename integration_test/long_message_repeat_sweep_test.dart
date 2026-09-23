import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Length sweep for the "long messages never get repeated" report.
///
/// USER-DIRECTED live-mesh debugging (910.525, #mtdebug only): the BLE
/// companion (GWQ 🚀) sends ONE frame per length step — no retries — and
/// listens for its own echo coming back from a repeater (a channel-msg
/// frame carrying path bytes). A companion pushes the FIRST repeated copy
/// of its own sends to the app, so the echo is the ground truth for
/// "did any repeater forward this". Budget: at most 10 transmissions,
/// ~30 s apart.
///
///   flutter test integration_test/long_message_repeat_sweep_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  final psk = Channel.derivePskFromHashtag('#mtdebug');
  final idKey = Channel.formatPskHex(psk);
  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);

  tearDownAll(() async {
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('length sweep: which sizes come back repeated', (tester) async {
    await beginScenario(tester, 'long-message repeat sweep');
    await PrefsManager.initialize();

    await bridge.start();
    ble.connector = await buildConnector();
    await ble.connector.connectTcp(
      host: '127.0.0.1',
      port: BenchConfig.bridgePort,
    );
    await waitConnectedVerified(ble);
    final selfName = ble.connector.selfName ?? '';
    blog('companion: $selfName');

    expect(ble.connector.currentFreqHz, BenchConfig.meshFreqKhz,
        reason: 'companion is not on 910.525 — refusing to run');

    await awaitSyncIdle(ble);
    snapshotProtectedSlots(ble, {idKey});
    final channel = await ensureChannel(ble, '#mtdebug', psk);
    blog('#mtdebug in slot ${channel.index}');

    // Echo watcher: any channel-msg frame from OUR name with path bytes.
    final echoes = <String, int>{}; // text -> path byte count of first echo
    final sub = ble.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return;
      }
      final parsed = ChannelMessage.fromFrame(frame);
      if (parsed == null || parsed.channelIndex != channel.index) return;
      final pathLen = parsed.pathLength ?? -1;
      if (parsed.senderName != selfName || pathLen <= 0) return;
      echoes.putIfAbsent(parsed.text, () => pathLen);
      blog('ECHO heard: len=${parsed.text.length} path=$pathLen bytes '
          '"${parsed.text.substring(0, parsed.text.length.clamp(0, 24))}…"');
    });

    // One message per length step; text is padded to EXACTLY the target
    // length so payload sizes are known. 148 is the app cap for a 10-byte
    // sender name.
    const lengths = [15, 60, 100, 120, 130, 136, 140, 144, 148];
    String makeText(int len) {
      final head = 'S$runTag L$len ';
      final filler = List.generate(len - head.length,
          (i) => String.fromCharCode(97 + (i % 26))).join();
      return '$head$filler';
    }

    final results = <int, bool>{};
    for (final len in lengths) {
      final text = makeText(len);
      final wire = ble.connector.prepareChannelOutboundText(
        channel.index,
        text,
      );
      blog('TX len=$len (wire ${wire.length} chars) — single frame, '
          'no retry');
      await ble.connector.sendFrame(
        buildSendChannelTextMsgFrame(
          channel.index,
          wire,
          timestampSecs: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      // Wait for the echo (A277-class repeater answers within seconds).
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      var repeated = false;
      while (DateTime.now().isBefore(deadline)) {
        if (echoes.containsKey(text)) {
          repeated = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      results[len] = repeated;
      blog('RESULT len=$len -> ${repeated ? "REPEATED "
          "(${echoes[text]} path bytes)" : "no echo"}');
      // Quiet gap between steps so we never stack transmissions.
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    await sub.cancel();
    blog('=== SWEEP SUMMARY (sender "$selfName", tag $runTag) ===');
    results.forEach((len, repeated) {
      blog('  len=$len  ${repeated ? "REPEATED" : "NO ECHO"}');
    });
    blog('=== sweep ended — ${lengths.length} frames transmitted ===');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
