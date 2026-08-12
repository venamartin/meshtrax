import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// INTEROP CAPTURE — MeshCore One <-> MeshTrax reaction forensics.
///
/// USER-DIRECTED SPECIAL CASE: runs on the LIVE US mesh frequency
/// (910.525 MHz), not the 920.000 bench. Sends are capped at three frames,
/// all inside the #mtdebug hashtag channel. The user drives two phones
/// (MeshTrax on GWQ🍓, MeshCore One on GWQ🚀); this harness listens on the
/// USB companion (Whale 🐋) and records everything.
///
/// For every MeshCore One-shaped reaction heard, it immediately replays our
/// full matching logic against every message captured so far — exact
/// candidates first (raw/stripped text x wire seconds), then a +/-300 s
/// timestamp sweep and trimmed-text variants — and logs WHICH candidate
/// matched or exactly how it missed. The point: field evidence shows MC1
/// reactions orphaning even when their target is on screen, so some
/// ingredient of hash(text, wire_ts) disagrees between the clients.
///
///   flutter test integration_test/mtdebug_monitor_test.dart -d windows \
///     --dart-define=MTDEBUG_LOG=C:/path/to/capture.jsonl
///
/// Ends when any phone sends a message containing the word "done" on
/// #mtdebug, or after 100 minutes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const meshKhz = 910525; // US/Canada preset, user-confirmed
  const logPath = String.fromEnvironment(
    'MTDEBUG_LOG',
    defaultValue: 'mtdebug_capture.jsonl',
  );

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final psk = Channel.derivePskFromHashtag('#mtdebug');
  final idKey = Channel.formatPskHex(psk);

  testWidgets('mtdebug interop capture', (tester) async {
    await beginScenario(tester, 'mtdebug capture');
    await PrefsManager.initialize();

    final log = File(logPath).openWrite(mode: FileMode.append);
    void jsonl(Map<String, Object?> entry) {
      entry['t'] = DateTime.now().toIso8601String();
      log.writeln(json.encode(entry));
    }

    usb.connector = await buildConnector();
    await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
    await waitConnectedVerified(usb);
    blog('USB companion: ${usb.connector.selfName}');
    await alignFrequency(usb, khz: meshKhz);
    blog('LIVE MESH FREQUENCY — sends restricted to #mtdebug, 3 max');

    await awaitSyncIdle(usb);
    snapshotProtectedSlots(usb, {idKey});
    final channel = await ensureChannel(usb, '#mtdebug', psk);
    blog('#mtdebug live in slot ${channel.index} '
        '(idKey ${idKey.substring(0, 8)}…)');

    // ── capture state ────────────────────────────────────────────────────
    // Every non-reaction channel message heard, oldest first.
    final captured =
        <({String sender, String text, int wireSecs, int channelIdx})>[];
    var sendsUsed = 0;
    const sendBudget = 3;
    final reactedTo = <String>{}; // senders Whale already reacted to
    final doneSignal = Completer<String>();

    List<String> variantsOf(String text) => {
          text,
          ChannelMessage.stripLeadingMentions(text),
          text.trim(),
          ChannelMessage.stripLeadingMentions(text).trim(),
        }.toList();

    // Replays our matching logic against everything captured so far and
    // reports the verdict. This runs on the WIRE data, independent of what
    // the connector's production ingest concludes.
    void analyzeReaction({
      required String reactorName,
      required ReactionInfo info,
      required int reactionWireSecs,
    }) {
      blog('REACTION ${info.emoji} by "$reactorName" '
          'targeting @[${info.targetSender ?? '-'}] hash=${info.targetHash}');

      // Pass 1: exactly what the app tries today.
      for (final m in captured.reversed) {
        for (final v in variantsOf(m.text)) {
          if (ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs) ==
              info.targetHash) {
            blog('  MATCH (app logic): "${m.sender}: ${m.text}" '
                'ts=${m.wireSecs} variant="${v == m.text ? 'raw' : 'stripped/trimmed'}"');
            jsonl({
              'kind': 'reaction_match',
              'reactor': reactorName,
              'emoji': info.emoji,
              'hash': info.targetHash,
              'target_sender': m.sender,
              'target_text': m.text,
              'target_wire_secs': m.wireSecs,
              'variant': v,
            });
            return;
          }
        }
      }

      // Pass 2: timestamp sweep — a hit here means the TEXT form is right
      // and the two clients disagree about the wire clock by exactly dt.
      for (final m in captured.reversed) {
        if (info.targetSender != null && m.sender != info.targetSender) {
          continue;
        }
        for (final v in variantsOf(m.text)) {
          for (var dt = -300; dt <= 300; dt++) {
            if (ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs + dt) ==
                info.targetHash) {
              blog('  OFFSET MATCH: "${m.sender}: ${m.text}" needs '
                  'dt=${dt}s off our wire ts ${m.wireSecs} '
                  '(variant "${v == m.text ? 'raw' : 'stripped/trimmed'}")');
              jsonl({
                'kind': 'reaction_offset_match',
                'reactor': reactorName,
                'hash': info.targetHash,
                'target_text': m.text,
                'target_wire_secs': m.wireSecs,
                'dt': dt,
                'variant': v,
              });
              return;
            }
          }
        }
      }

      // Pass 3: nothing — dump what we WOULD have produced for the named
      // sender's recent messages so the discrepancy is inspectable offline.
      blog('  NO MATCH within ±300 s. Candidates we computed:');
      final near = captured.reversed
          .where((m) =>
              info.targetSender == null || m.sender == info.targetSender)
          .take(3);
      for (final m in near) {
        for (final v in variantsOf(m.text)) {
          blog('    "${m.sender}" ts=${m.wireSecs} '
              '${v == m.text ? "raw" : "alt"} -> '
              '${ReactionHelper.computeMeshCoreOneHash(v, m.wireSecs)} '
              '("${v.length > 40 ? '${v.substring(0, 40)}…' : v}")');
        }
      }
      jsonl({
        'kind': 'reaction_no_match',
        'reactor': reactorName,
        'emoji': info.emoji,
        'hash': info.targetHash,
        'target_sender': info.targetSender,
        'reaction_wire_secs': reactionWireSecs,
      });
    }

    // One MC1 reaction from Whale to the first message from each phone, so
    // both apps also get to RECEIVE our dialect during the session.
    Future<void> maybeReactTo(ChannelMessage msg) async {
      if (sendsUsed >= sendBudget) return;
      if (!msg.senderName.startsWith('GWQ')) return;
      if (!reactedTo.add(msg.senderName)) return;
      await Future<void>.delayed(const Duration(seconds: 3));
      final wire = MeshCoreConnector.channelReactionText(msg, '🐋');
      sendsUsed++;
      blog('Whale reacts 🐋 to "${msg.senderName}: ${msg.text}" '
          '(send $sendsUsed/$sendBudget): ${wire.replaceAll('\n', '\\n')}');
      jsonl({'kind': 'whale_reaction_sent', 'wire': wire, 'to': msg.text});
      await usb.connector.sendChannelMessage(channel, wire);
    }

    // ── the wire tap ─────────────────────────────────────────────────────
    final sub = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final code = frame[0];
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return;
      }
      final parsed = ChannelMessage.fromFrame(frame);
      if (parsed == null) return;
      final wireSecs = parsed.timestamp.millisecondsSinceEpoch ~/ 1000;
      final isOurs = parsed.channelIndex == channel.index;

      jsonl({
        'kind': 'channel_msg',
        'ours': isOurs,
        'channel_idx': parsed.channelIndex,
        'sender': parsed.senderName,
        'text': parsed.text,
        'wire_secs': wireSecs,
        'path_len': parsed.pathLength,
        'raw_hex': frame
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(),
      });
      if (!isOurs) return; // background mesh traffic: logged, not analyzed

      final info = ReactionHelper.parseMeshCoreOneReaction(parsed.text);
      if (info != null) {
        analyzeReaction(
          reactorName: parsed.senderName,
          info: info,
          reactionWireSecs: wireSecs,
        );
        return;
      }
      final legacy = ReactionHelper.parseReaction(parsed.text);
      if (legacy != null) {
        blog('LEGACY r: reaction from ${parsed.senderName}: ${parsed.text}');
        return;
      }

      blog('MSG [${parsed.senderName}] "${parsed.text}" ts=$wireSecs '
          'hops=${parsed.pathLength}');
      captured.add((
        sender: parsed.senderName,
        text: parsed.text,
        wireSecs: wireSecs,
        channelIdx: parsed.channelIndex ?? -1,
      ));
      if (RegExp(r'\bdone\b', caseSensitive: false).hasMatch(parsed.text) &&
          parsed.senderName != usb.connector.selfName) {
        if (!doneSignal.isCompleted) {
          doneSignal.complete(parsed.senderName);
        }
        return;
      }
      unawaited(maybeReactTo(parsed));
    });

    // Seed: one visible target both phones can react to immediately.
    sendsUsed++;
    const seed = 'Whale 🐋 monitor is live — react to THIS message '
        'from both apps first, then run your combinations.';
    await usb.connector.sendChannelMessage(channel, seed);
    blog('seed sent ($sendsUsed/$sendBudget) — capturing…');

    final endedBy = await doneSignal.future
        .timeout(const Duration(minutes: 100), onTimeout: () => '(timeout)');
    blog('=== capture ended by: $endedBy ===');
    await sub.cancel();

    // What production code concluded, for cross-checking against the wire.
    final rows = await usb.connector.loadChannelMessagesFor(channel);
    blog('--- stored #mtdebug rows (${rows.length}) ---');
    for (final r in rows) {
      final orphan =
          ReactionHelper.parseMeshCoreOneReaction(r.text) != null;
      blog('  [${r.senderName}] "${r.text.replaceAll('\n', '\\n')}"'
          '${orphan ? '  <ORPHAN>' : ''}'
          '${r.reactions.isNotEmpty ? '  reactions=${r.reactions} by ${r.reactionSenders}' : ''}');
      jsonl({
        'kind': 'stored_row',
        'sender': r.senderName,
        'text': r.text,
        'orphan': orphan,
        'reactions': r.reactions,
        'reaction_senders': r.reactionSenders,
      });
    }

    await log.close();
    blog('capture written to $logPath');

    // Park the companion back on the bench frequency — the special case
    // ends with the session.
    await alignFrequency(usb, khz: BenchConfig.targetFreqKhz);
    blog('companion parked on 920.000 MHz');
    await usb.connector.disconnect();
  }, timeout: const Timeout(Duration(minutes: 115)));
}
