import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// INTEROP VERIFICATION — MeshCore One's NEW mention-first reaction order.
///
/// USER-DIRECTED SPECIAL CASE: runs on the LIVE US mesh frequency
/// (910.525 MHz), traffic confined to #mtdebug, sends capped at two frames
/// (the seed + one confirmation). The harness drives the BLE companion
/// (GWQ 🚀) and seeds one message; the user reacts to it from MeshCore One
/// on a phone. Verifies:
///
///   N1  the reaction arrives in the new order `@[{sender}]{emoji}\n{hash}`
///       (the old `{emoji}@[{sender}]\n{hash}` is logged and still accepted)
///   N2  parseMeshCoreOneReaction reads it — emoji, target sender, hash
///   N3  production ingest lands it as a CHIP on the seed row, and the raw
///       two-line text never persists as a visible message
///
///   flutter test integration_test/mc1_new_format_live_test.dart -d windows
///
/// Ends when the chip is verified, when any phone sends "abort" on
/// #mtdebug, or after 20 minutes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const meshKhz = 910525; // US/Canada preset, user-confirmed
  const logPath = String.fromEnvironment(
    'MC1_NEWFORMAT_LOG',
    defaultValue: 'mc1_newformat_capture.jsonl',
  );

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  final psk = Channel.derivePskFromHashtag('#mtdebug');
  final idKey = Channel.formatPskHex(psk);

  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);

  tearDownAll(() async {
    try {
      if (ble.connector.isConnected) {
        await alignFrequency(ble, khz: BenchConfig.targetFreqKhz);
        blog('companion parked back on 920.000 MHz');
      }
    } catch (_) {}
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('new-format MC1 reaction lands live', (tester) async {
    await beginScenario(tester, 'MC1 new-format live verification');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    final log = File(logPath).openWrite(mode: FileMode.append);
    void jsonl(Map<String, Object?> entry) {
      entry['t'] = DateTime.now().toIso8601String();
      entry['run'] = runTag;
      log.writeln(json.encode(entry));
    }

    blog('starting BLE bridge (watch for a Windows pairing prompt)…');
    await bridge.start();
    ble.connector = await buildConnector();
    await ble.connector.connectTcp(
      host: '127.0.0.1',
      port: BenchConfig.bridgePort,
    );
    await waitConnectedVerified(ble);
    blog('companion: ${ble.connector.selfName}');

    await alignFrequency(ble, khz: meshKhz);
    blog('LIVE MESH FREQUENCY — sends restricted to #mtdebug, 2 max');

    await awaitSyncIdle(ble);
    snapshotProtectedSlots(ble, {idKey});
    final channel = await ensureChannel(ble, '#mtdebug', psk);
    blog('#mtdebug live in slot ${channel.index} '
        '(idKey ${idKey.substring(0, 8)}…)');

    final reactions = StreamController<
        ({String reactor, String raw, ReactionInfo info, int wireSecs})>();
    final aborted = Completer<void>();

    final sub = ble.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return;
      }
      final parsed = ChannelMessage.fromFrame(frame);
      if (parsed == null || parsed.channelIndex != channel.index) return;
      final wireSecs = parsed.timestamp.millisecondsSinceEpoch ~/ 1000;

      jsonl({
        'kind': 'channel_msg',
        'sender': parsed.senderName,
        'text': parsed.text,
        'wire_secs': wireSecs,
        'raw_hex':
            frame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      });
      if (parsed.senderName == ble.connector.selfName) return; // our echo

      final info = ReactionHelper.parseMeshCoreOneReaction(parsed.text);
      if (info != null) {
        final firstLine = parsed.text.split('\n').first;
        final order = firstLine.startsWith('@[') ? 'NEW (mention-first)'
            : 'OLD (emoji-first)';
        blog('REACTION heard from "${parsed.senderName}": '
            '"${parsed.text.replaceAll('\n', '\\n')}"');
        blog('  order: $order | emoji ${info.emoji} | '
            'target @[${info.targetSender ?? '-'}] | hash ${info.targetHash}');
        reactions.add((
          reactor: parsed.senderName,
          raw: parsed.text,
          info: info,
          wireSecs: wireSecs,
        ));
        return;
      }
      blog('MSG [${parsed.senderName}] "${parsed.text}" ts=$wireSecs');
      if (RegExp(r'\babort\b', caseSensitive: false).hasMatch(parsed.text) &&
          !aborted.isCompleted) {
        aborted.complete();
      }
    });

    // Send 1/2: the seed the user reacts to.
    final seed = 'MeshTrax new-format reaction test [$runTag] — '
        'react to THIS from MeshCore One.';
    await ble.connector.sendChannelMessage(channel, seed);
    blog('seed sent (1/2): "$seed"');
    blog('>>> waiting for your MeshCore One reaction (up to 15 min)…');

    // Verify EVERY reaction heard (both orders must land as chips); the
    // session passes once a NEW-order one has been verified. An old-order
    // reaction (e.g. a released MeshTrax build) is verified and logged,
    // then we keep listening.
    Future<void> verifyChipped(
      ({String reactor, String raw, ReactionInfo info, int wireSecs}) heard,
    ) async {
      // Hash forensics: our seed row's candidate stamps must reproduce it.
      final rows = await ble.connector.loadChannelMessagesFor(channel);
      final seedRow = rows.firstWhere(
        (m) => m.isOutgoing && m.text == seed,
        orElse: () => fail('our own seed row is missing from the store'),
      );
      final baseSecs = seedRow.timestamp.millisecondsSinceEpoch ~/ 1000;
      final candidates = <int>{
        baseSecs, baseSecs + 1, baseSecs + 2, baseSecs + 3,
        ...seedRow.sentWireSecs,
      };
      final hashHit = candidates.any((s) =>
          ReactionHelper.computeMeshCoreOneHash(seed, s) ==
          heard.info.targetHash);
      if (!hashHit) {
        // Diagnose before failing: which dt would have matched?
        int? dtHit;
        for (var dt = -300; dt <= 300 && dtHit == null; dt++) {
          if (ReactionHelper.computeMeshCoreOneHash(seed, baseSecs + dt) ==
              heard.info.targetHash) {
            dtHit = dt;
          }
        }
        jsonl({'kind': 'hash_miss', 'dt_hit': dtHit, 'base_secs': baseSecs});
        blog('HASH MISS — dt sweep hit: ${dtHit ?? 'none within ±300 s'} '
            '(base $baseSecs, harvested ${seedRow.sentWireSecs})');
      }

      // Production ingest must make it a chip, not a message.
      var chipBy = <String>[];
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      var chipLanded = false;
      while (DateTime.now().isBefore(deadline)) {
        final fresh = await ble.connector.loadChannelMessagesFor(channel);
        final row = fresh.where((m) => m.isOutgoing && m.text == seed);
        if (row.isNotEmpty &&
            (row.first.reactions[heard.info.emoji] ?? 0) > 0) {
          chipBy = row.first.reactionSenders[heard.info.emoji] ?? const [];
          chipLanded = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      final visible = (await ble.connector.loadChannelMessagesFor(channel))
          .any((m) => m.text == heard.raw);
      jsonl({
        'kind': 'verdict',
        'raw': heard.raw,
        'reactor': heard.reactor,
        'chip_landed': chipLanded,
        'chip_by': chipBy,
        'stored_as_message': visible,
        'hash_reproduced': hashHit,
      });
      expect(chipLanded, isTrue,
          reason: 'the reaction "${heard.raw.replaceAll('\n', '\\n')}" '
              'parsed but never landed as a chip on the seed row — '
              'matcher/ingest problem (hash reproduced: $hashHit)');
      blog('CHIP ${heard.info.emoji} landed on the seed, by '
          '${chipBy.join(", ")}');
      expect(visible, isFalse,
          reason: 'the reaction ALSO persisted as a visible message row');
      expect(hashHit, isTrue,
          reason: 'chip landed but not via our candidate stamps — see the '
              'dt sweep in the log');
    }

    ({String reactor, String raw, ReactionInfo info, int wireSecs})?
        newOrderHeard;
    final sessionDeadline = DateTime.now().add(const Duration(minutes: 15));
    final queue = StreamIterator(reactions.stream);
    while (newOrderHeard == null &&
        DateTime.now().isBefore(sessionDeadline)) {
      final remaining = sessionDeadline.difference(DateTime.now());
      final moved = await Future.any<bool?>([
        queue.moveNext(),
        aborted.future.then((_) => null),
      ]).timeout(remaining, onTimeout: () => false);
      if (moved == null) fail('aborted by a phone on #mtdebug');
      if (moved != true) break;
      final heard = queue.current;
      jsonl({
        'kind': 'reaction',
        'reactor': heard.reactor,
        'raw': heard.raw,
        'emoji': heard.info.emoji,
        'target_sender': heard.info.targetSender,
        'hash': heard.info.targetHash,
        'wire_secs': heard.wireSecs,
      });
      if (heard.info.targetSender != null &&
          heard.info.targetSender != ble.connector.selfName) {
        blog('  targets @[${heard.info.targetSender}], not our seed — '
            'ignoring');
        continue;
      }
      await verifyChipped(heard);
      if (heard.raw.split('\n').first.startsWith('@[')) {
        newOrderHeard = heard;
      } else {
        blog('>>> OLD-order reaction verified as a chip. Still waiting for '
            'a NEW-order one from MeshCore One…');
      }
    }

    if (newOrderHeard == null) {
      await sub.cancel();
      await log.close();
      fail('no NEW mention-first reaction heard within 15 minutes '
          '(old-order ones, if any, were verified — see the log)');
    }

    // Send 2/2: close the loop so the user sees success on the phone.
    await ble.connector.sendChannelMessage(
      channel,
      'Got it — ${newOrderHeard.info.emoji} in the new mention-first order, '
      'chip applied. ✅',
    );
    blog('confirmation sent (2/2)');

    await sub.cancel();
    await log.close();
    blog('capture written to $logPath');
  }, timeout: const Timeout(Duration(minutes: 25)));
}
