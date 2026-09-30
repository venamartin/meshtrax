import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// OVERNIGHT REACTION MONITOR — Public channel, live mesh, PASSIVE.
///
/// Listens on the USB companion (Whale 🐋) tuned to the live US mesh
/// (910.525 MHz) and NEVER transmits. For every reaction heard on Public
/// (MeshCore One dialect in either order, or legacy r:) it:
///
///   1. replays our matcher on the wire data — exact candidates first
///      (raw/stripped text × wire seconds) over everything heard tonight
///      AND over the rows already in the store, then a ±300 s clock sweep;
///   2. waits for production ingest to land the reaction as a chip;
///   3. writes a verdict. A reaction whose target WAS heard (wire or store)
///      but never chipped is an app-side failure: the run dumps the full
///      diagnosis and STOPS so the finding is waiting in the morning. A
///      reaction whose target Whale never heard is logged as RF/history
///      loss and the run keeps going.
///
///   flutter test integration_test/public_reaction_monitor_test.dart \
///     -d windows --dart-define=PUBLIC_MON_LOG=C:/path/to/capture.jsonl
///
/// Ends on the first diagnosed failure, when the console window is closed,
/// or after 14 hours. Whale stays on the mesh frequency afterwards.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const logPath = String.fromEnvironment(
    'PUBLIC_MON_LOG',
    defaultValue: 'public_reaction_monitor.jsonl',
  );
  const sessionLength = Duration(hours: 14);
  const chipGrace = Duration(seconds: 90);

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');

  testWidgets('public reaction monitor', (tester) async {
    await beginScenario(tester, 'Public reaction monitor (passive)');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    final log = File(logPath).openWrite(mode: FileMode.append);
    void jsonl(Map<String, Object?> entry) {
      entry['t'] = DateTime.now().toIso8601String();
      log.writeln(json.encode(entry));
    }

    usb.connector = await buildConnector();
    await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
    await waitConnectedVerified(usb);
    blog('USB companion: ${usb.connector.selfName}');
    await alignFrequency(usb, khz: BenchConfig.meshFreqKhz);
    blog('LIVE MESH FREQUENCY — passive, zero transmissions');
    await awaitSyncIdle(usb);

    final public = usb.connector.channels.firstWhere(
      (c) => c.isPublicChannel,
      orElse: () => fail('no Public channel on the radio'),
    );
    blog('monitoring Public (slot ${public.index}) for reactions…');
    jsonl({'kind': 'session_start', 'self': usb.connector.selfName});

    // ── capture state ────────────────────────────────────────────────────
    final captured = <({String sender, String text, int wireSecs})>[];
    final stop = Completer<String>();
    var reactionsHeard = 0;
    var chipsLanded = 0;
    var targetsUnheard = 0;

    List<String> variantsOf(String text) => {
          text,
          ChannelMessage.stripLeadingMentions(text),
          ChannelMessage.mc1DisplayText(text),
          text.trim(),
        }.toList();

    String show(String s) => s.replaceAll('\n', '\\n');

    // Candidate (text, secs) pairs for a stored row — every stamp the app
    // itself would try.
    Iterable<(String, int)> storedCandidates(ChannelMessage m) sync* {
      final secs = <int>{
        m.timestamp.millisecondsSinceEpoch ~/ 1000,
        ...m.sentWireSecs,
      };
      final texts = <String>{
        ...variantsOf(m.text),
        if (m.wireText != null) m.wireText!,
      };
      for (final t in texts) {
        for (final s in secs) {
          yield (t, s);
        }
      }
    }

    Future<void> analyzeReaction({
      required String reactor,
      required String raw,
      required ReactionInfo info,
      required int reactionWireSecs,
    }) async {
      reactionsHeard++;
      final order = info.format == ReactionFormat.one
          ? (raw.startsWith('@[') ? 'mention-first' : 'emoji-first')
          : 'legacy r:';
      blog('REACTION #$reactionsHeard ${info.emoji} by "$reactor" '
          '[$order] targeting @[${info.targetSender ?? '-'}] '
          'hash=${info.targetHash}');
      jsonl({
        'kind': 'reaction',
        'reactor': reactor,
        'raw': raw,
        'order': order,
        'emoji': info.emoji,
        'target_sender': info.targetSender,
        'hash': info.targetHash,
        'wire_secs': reactionWireSecs,
      });
      if (info.format != ReactionFormat.one) {
        blog('  legacy format — logged only');
        return;
      }

      // ── wire forensics ───────────────────────────────────────────────
      String? wireMatch;
      for (final m in captured.reversed) {
        for (final v in variantsOf(m.text)) {
          if (ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs) ==
              info.targetHash) {
            wireMatch = '"${m.sender}: ${show(m.text)}" ts=${m.wireSecs} '
                '(${v == m.text ? 'raw' : 'variant'})';
            break;
          }
        }
        if (wireMatch != null) break;
      }

      // ── store forensics (history from before tonight counts too) ─────
      final rows = await usb.connector.loadChannelMessagesFor(public);
      ChannelMessage? storeMatch;
      for (final m in rows.reversed) {
        if (ReactionHelper.parseMeshCoreOneReaction(m.text) != null) continue;
        for (final (t, s) in storedCandidates(m)) {
          if (ReactionHelper.computeMeshCoreOneHash(t, s) == info.targetHash) {
            storeMatch = m;
            break;
          }
        }
        if (storeMatch != null) break;
      }

      // ── clock sweep: right text, wrong second ────────────────────────
      int? dtHit;
      String? dtTarget;
      final senderRows = captured.reversed
          .where((m) =>
              info.targetSender == null || m.sender == info.targetSender)
          .take(5);
      outer:
      for (final m in senderRows) {
        for (final v in variantsOf(m.text)) {
          for (var dt = -300; dt <= 300; dt++) {
            if (ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs + dt) ==
                info.targetHash) {
              dtHit = dt;
              dtTarget = '"${m.sender}: ${show(m.text)}" ts=${m.wireSecs}';
              break outer;
            }
          }
        }
      }

      blog('  wire match : ${wireMatch ?? 'none'}');
      blog('  store match: ${storeMatch == null ? 'none' : '"${storeMatch.senderName}: ${show(storeMatch.text)}" id=${storeMatch.messageId}'}');
      if (wireMatch == null && storeMatch == null) {
        blog('  clock sweep: ${dtHit == null ? 'no hit within ±300 s' : 'dt=$dtHit s on $dtTarget'}');
      }

      // ── did production ingest chip it? ───────────────────────────────
      final deadline = DateTime.now().add(chipGrace);
      ChannelMessage? chipped;
      var stubVisible = false;
      while (DateTime.now().isBefore(deadline)) {
        final fresh = await usb.connector.loadChannelMessagesFor(public);
        for (final m in fresh) {
          final by = m.reactionSenders[info.emoji] ?? const [];
          final hashFits = storeMatch != null && m.messageId == storeMatch.messageId;
          if ((m.reactions[info.emoji] ?? 0) > 0 &&
              (by.contains(reactor) || hashFits)) {
            chipped = m;
            break;
          }
        }
        if (chipped != null) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      stubVisible = (await usb.connector.loadChannelMessagesFor(public))
          .any((m) => m.text == raw && !m.isOutgoing);

      final targetHeard = wireMatch != null || storeMatch != null;
      final String verdict;
      if (chipped != null) {
        chipsLanded++;
        verdict = 'chip_landed';
        blog('  ✅ CHIP landed on "${chipped.senderName}: ${show(chipped.text)}" '
            'by ${chipped.reactionSenders[info.emoji]}');
      } else if (targetHeard) {
        verdict = 'FAILURE_target_known_no_chip';
      } else if (dtHit != null) {
        verdict = 'FAILURE_clock_mismatch';
      } else {
        targetsUnheard++;
        verdict = 'target_unheard';
        blog('  ⚠ target never heard by Whale (wire or store) — RF/history '
            'loss, not diagnosable here; stub visible: $stubVisible');
      }
      jsonl({
        'kind': 'verdict',
        'verdict': verdict,
        'reactor': reactor,
        'emoji': info.emoji,
        'hash': info.targetHash,
        'target_sender': info.targetSender,
        'wire_match': wireMatch,
        'store_match_id': storeMatch?.messageId,
        'store_match_text': storeMatch?.text,
        'dt_hit': dtHit,
        'dt_target': dtTarget,
        'chipped_id': chipped?.messageId,
        'chipped_by': chipped?.reactionSenders[info.emoji],
        'stub_visible': stubVisible,
      });

      if (verdict.startsWith('FAILURE')) {
        blog('❌ $verdict — dumping diagnosis');
        // Everything an offline reader needs: what we heard from the
        // target sender recently and what each candidate hashes to.
        for (final m in captured.reversed
            .where((m) =>
                info.targetSender == null || m.sender == info.targetSender)
            .take(5)) {
          for (final v in variantsOf(m.text)) {
            blog('    wire "${m.sender}" ts=${m.wireSecs} '
                '${v == m.text ? 'raw' : 'alt'} -> '
                '${ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs)} '
                '("${show(v.length > 50 ? '${v.substring(0, 50)}…' : v)}")');
          }
        }
        if (storeMatch != null) {
          blog('    store row: id=${storeMatch.messageId} '
              'outgoing=${storeMatch.isOutgoing} '
              'ts=${storeMatch.timestamp.millisecondsSinceEpoch ~/ 1000} '
              'sentWireSecs=${storeMatch.sentWireSecs} '
              'wireText=${storeMatch.wireText == null ? 'null' : '"${show(storeMatch.wireText!)}"'} '
              'reactions=${storeMatch.reactions} '
              'by=${storeMatch.reactionSenders}');
        }
        blog('    stub row visible in store: $stubVisible');
        if (!stop.isCompleted) stop.complete(verdict);
      }
    }

    // ── the wire tap ─────────────────────────────────────────────────────
    final sub = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return;
      }
      final parsed = ChannelMessage.fromFrame(frame);
      if (parsed == null || parsed.channelIndex != public.index) return;
      if (parsed.senderName == usb.connector.selfName) return;
      final wireSecs = parsed.timestamp.millisecondsSinceEpoch ~/ 1000;

      jsonl({
        'kind': 'channel_msg',
        'sender': parsed.senderName,
        'text': parsed.text,
        'wire_secs': wireSecs,
        'path_len': parsed.pathLength,
        'raw_hex':
            frame.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      });

      final info = ReactionHelper.parseIncomingReaction(parsed.text);
      if (info != null) {
        unawaited(analyzeReaction(
          reactor: parsed.senderName,
          raw: parsed.text,
          info: info,
          reactionWireSecs: wireSecs,
        ));
        return;
      }
      blog('MSG [${parsed.senderName}] "${show(parsed.text)}" ts=$wireSecs '
          'hops=${parsed.pathLength}');
      captured.add((
        sender: parsed.senderName,
        text: parsed.text,
        wireSecs: wireSecs,
      ));
    });

    // Hourly heartbeat so a quiet night is distinguishable from a hung one.
    final heartbeat = Timer.periodic(const Duration(hours: 1), (_) {
      blog('heartbeat: ${captured.length} msgs, $reactionsHeard reactions, '
          '$chipsLanded chipped, $targetsUnheard target-unheard, '
          'connected=${usb.connector.isConnected}');
      jsonl({
        'kind': 'heartbeat',
        'msgs': captured.length,
        'reactions': reactionsHeard,
        'chipped': chipsLanded,
        'target_unheard': targetsUnheard,
        'connected': usb.connector.isConnected,
      });
    });

    final endedBy = await stop.future
        .timeout(sessionLength, onTimeout: () => 'session length reached');
    heartbeat.cancel();
    await sub.cancel();
    blog('=== monitor ended: $endedBy ===');
    blog('totals: ${captured.length} msgs, $reactionsHeard reactions, '
        '$chipsLanded chipped, $targetsUnheard target-unheard');
    jsonl({
      'kind': 'session_end',
      'reason': endedBy,
      'msgs': captured.length,
      'reactions': reactionsHeard,
      'chipped': chipsLanded,
      'target_unheard': targetsUnheard,
    });
    await log.close();

    await usb.connector.disconnect();

    expect(endedBy.startsWith('FAILURE'), isFalse,
        reason: 'a reaction failed to land — see the diagnosis above and '
            'the capture at $logPath');
  }, timeout: const Timeout(Duration(hours: 15)));
}
