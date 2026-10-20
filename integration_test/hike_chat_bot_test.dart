import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/frame_adapter.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';
import 'package:path_graph/path_graph.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// FIELD TEST — a chat partner for the owner's hike.
///
/// The BLE companion (GWQ 🚀) runs this build with Pathfinder on and
/// answers every DM from the owner's hiking radio (name contains 🍓) with
/// one line from a joke pool, after the owner's copies have gone quiet for
/// [quiet]. It never sends anything else. A DM that is exactly "done"
/// gets a sign-off and ends the run.
///
/// Both ends exercise the route keeper: the phone holds Pathfinder's route
/// to 🚀 (the route its ACKs of these replies go on), 🚀 holds its own to
/// the phone. Everything is logged for the read-out:
///   HIKE_LOG       JSONL events: rx copies, tx outcomes, graph snapshots
///   HIKE_LOG_app   every app log line (PathGraph, AckHash, Connector …)
///   HIKE_DB        the Pathfinder database (kept, so a restart resumes it)
///
/// RF: live mesh (910.525). One reply per message from the owner, on the
/// normal DM ladder with the retry budget pinned to 5 for the run.
///
///   flutter test integration_test/hike_chat_bot_test.dart -d windows \
///     --dart-define=HIKE_LOG=C:/…/hike.jsonl --dart-define=HIKE_DB=C:/…/hike.sqlite
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const logPath =
      String.fromEnvironment('HIKE_LOG', defaultValue: 'hike_chat.jsonl');
  const dbPath =
      String.fromEnvironment('HIKE_DB', defaultValue: 'hike_path_graph.sqlite');
  const peerMark = '🍓';
  const sessionLength = Duration(hours: 12);
  const quiet = Duration(seconds: 40);

  testWidgets('hike chat bot', (tester) async {
    await beginScenario(tester, 'hike chat bot');
    final out = File(logPath).openWrite(mode: FileMode.append);
    final appOut = File(logPath.replaceAll('.jsonl', '_app.log'))
        .openWrite(mode: FileMode.append);
    void jsonl(Map<String, Object?> e) => out.writeln(
        jsonEncode({'t': DateTime.now().toIso8601String(), ...e}));

    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    AppDebugLogEntry? lastEntry;
    debugLog.addListener(() {
      final entries = debugLog.entries;
      var start = 0;
      if (lastEntry != null) {
        final i = entries.lastIndexWhere((e) => identical(e, lastEntry));
        start = i >= 0
            ? i + 1
            : entries.indexWhere((e) => e.timestamp.isAfter(lastEntry!.timestamp));
        if (start < 0) start = entries.length;
      }
      for (final e in entries.skip(start)) {
        appOut.writeln(e.formattedLine);
        if (e.tag == 'PathGraph' ||
            e.tag == 'AckHash' ||
            e.level != AppDebugLogLevel.info) {
          blog('[${e.tag}] ${e.message}');
        }
      }
      if (entries.isNotEmpty) lastEntry = entries.last;
    });

    final settings = AppSettingsService();
    await settings.loadSettings();
    final savedRetries = settings.settings.maxMessageRetries;
    await settings
        .updateSettings(settings.settings.copyWith(maxMessageRetries: 5));

    final connector = MeshCoreConnector();
    connector.initialize(
      retryService: MessageRetryService(),
      appSettingsService: settings,
      appDebugLogService: debugLog,
    );
    await connector.loadContactCache();
    await connector.loadCachedChannels();
    await connector.loadChannelSettings();
    final ble = BenchRadio('BLE(${BenchConfig.bleName})')..connector = connector;
    final bridge = BleNusTcpBridge();
    final service = PathGraphService();
    final timers = <Timer>[];
    StreamSubscription<Uint8List>? tap;

    try {
      blog('starting BLE bridge…');
      await bridge.start();
      await connector.connectTcp(
          host: '127.0.0.1', port: BenchConfig.bridgePort);
      await waitConnectedVerified(ble);
      await waitUntil(
          () => !connector.isLoadingContacts && connector.contacts.isNotEmpty,
          'contacts synced',
          timeout: const Duration(seconds: 90));
      await alignFrequency(ble, khz: BenchConfig.meshFreqKhz);
      expect(connector.currentFreqHz, BenchConfig.meshFreqKhz);

      final peers = connector.contacts
          .where((c) => c.type == advTypeChat && c.name.contains(peerMark))
          .toList();
      expect(peers, hasLength(1),
          reason: 'need exactly one chat contact named with $peerMark, found '
              '${peers.map((c) => c.name).toList()}');
      final peerKey = peers.single.publicKeyHex.toLowerCase();
      Contact peer() => connector.contacts
          .firstWhere((c) => c.publicKeyHex.toLowerCase() == peerKey);
      if (peer().pathOverride != null) {
        blog('⚠ ${peer().name} is NOT on Automatic — the route keeper skips it');
      }

      await service.start(connector, database: NativeDatabase(File(dbPath)));
      await waitUntil(() => service.graph?.selfPubkey != null,
          'graph knows the radio identity');
      final graph = service.graph!;

      String stored(Contact c) => c.pathLength < 0
          ? 'none (flood)'
          : c.pathLength == 0
              ? 'direct'
              : PathHelper.formatPathHex(c.path, stride: c.pathHashSize);
      String sel(PathSelection s) => s.useFlood
          ? 'flood'
          : s.hopCount == 0
              ? 'direct'
              : PathHelper.formatPathHex(s.pathBytes, stride: s.hashSize);
      String fmtRoute(PathResult r) => switch (r) {
            DirectResult() => 'direct',
            RouteResult(:final pathBytes, :final estDelivery) =>
              '${PathHelper.formatPathHex(pathBytes, stride: graph.hashWidthBytes)} '
                  '(${(estDelivery * 100).toStringAsFixed(0)}%)',
            FloodResult(:final reason) => 'flood — ${reason.name}',
          };
      String fmtCandidate(Candidate c) =>
          '${c.repeaterHash} ${c.proven ? "proven" : "heard-only"} '
          'conf=${(graph.doorstepConfidence(c) * 100).toStringAsFixed(0)}%';

      void snapshot(String when) {
        final c = peer();
        final routes = service.candidatesFor(c);
        final entry = {
          'kind': 'graph',
          'when': when,
          'stored': stored(c),
          'candidates': routes == null
              ? null
              : [
                  for (final r in routes)
                    '${sel(r)} ${r.estDelivery == null ? "" : "(${(r.estDelivery! * 100).toStringAsFixed(0)}%)"}'
                ],
          'routeTo': fmtRoute(graph.findPath(peerKey)),
          'routeBack': fmtRoute(graph.findReturnPath(peerKey)),
          'hearMe': [
            for (final x in graph.egressCandidates().take(6)) fmtCandidate(x)
          ],
          'hearThem': [
            for (final x in graph.ingressCandidates(peerKey).take(6))
              fmtCandidate(x)
          ],
        };
        jsonl(entry);
        blog('GRAPH $when · stored ${entry['stored']} · Pathfinder '
            '${entry['candidates']} · back ${entry['routeBack']}');
      }

      final self = connector.selfPublicKeyHex.toLowerCase();
      final selfByte = int.parse(self.substring(0, 2), radix: 16);
      final peerByte = int.parse(peerKey.substring(0, 2), radix: 16);
      blog('me: ${connector.selfName} ($self…) · peer: ${peer().name} '
          '($peerKey…) · stored route ${stored(peer())}');
      jsonl({
        'kind': 'session_start',
        'self': connector.selfName,
        'selfKey': self,
        'peer': peer().name,
        'peerKey': peerKey,
        'width': connector.pathHashByteWidth,
      });
      snapshot('start');

      final rng = Random();
      final jokes = List.of(_jokes)..shuffle(rng);
      final answers = List.of(_answers)..shuffle(rng);
      final startSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final copies = <String, int>{};
      final waiting = <String, Timer>{};
      final answered = <String>{};
      final done = Completer<String>();
      var rxCount = 0;
      var replyNo = 0;

      String pick(String theirs) {
        final pool = theirs.contains('?') && answers.isNotEmpty ? answers : jokes;
        if (pool.isEmpty) return 'Reply #${replyNo + 1}: still here, still a radio 📻';
        return pool.removeLast();
      }

      Future<void> reply(String theirs) async {
        final isDone = theirs.trim().toLowerCase() == 'done';
        final line = isDone ? 'Welcome back! Crunching the logs now 🔬📈' : pick(theirs);
        final n = ++replyNo;
        final c = peer();
        jsonl({'kind': 'tx_start', 'n': n, 'text': line, 'inReplyTo': theirs,
            'stored': stored(c)});
        blog('TX #$n "$line" (stored route ${stored(c)})');
        await connector.sendMessage(c, line);
        final status = await awaitDmStatus(ble, c, line,
            timeout: const Duration(minutes: 8));
        final sent = (await connector.loadMessagesFor(c))
            .where((m) => m.isOutgoing && m.text == line)
            .lastOrNull;
        jsonl({
          'kind': 'tx_end',
          'n': n,
          'status': status?.name,
          'attempt': sent?.retryCount,
          'route': sent == null
              ? null
              : (sent.pathLength ?? -1) < 0
                  ? 'flood'
                  : PathHelper.formatPathHex(sent.pathBytes,
                      stride: sent.pathHashSize ?? connector.pathHashByteWidth),
          'source': sent?.routeSource.name,
          'tripMs': sent?.tripTimeMs,
          'late': sent?.deliveredLate,
        });
        blog('TX #$n → ${status?.name} on attempt ${sent?.retryCount} '
            '(${sent?.routeSource.name}, ${sent?.tripTimeMs} ms)');
        snapshot('after reply #$n');
        if (isDone && !done.isCompleted) done.complete('"done" received');
      }

      void onPeerMessage(Uint8List frame) {
        final l = MeshCoreConnector.parseContactMsgLayout(frame);
        if (l == null) return;
        final prefix = l.senderPrefix
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        if (!peerKey.startsWith(prefix)) return;
        final id = '${l.txtType}:${l.timestampRaw}:${l.text}';
        final n = copies[id] = (copies[id] ?? 0) + 1;
        final direct = l.pathLen == 0xFF;
        final snr = frame[0] == respCodeContactMsgRecvV3
            ? frame[1].toSigned(8) / 4.0
            : null;
        rxCount++;
        jsonl({
          'kind': 'rx',
          'text': l.text,
          'senderTs': l.timestampRaw,
          'txtType': l.txtType,
          'copy': n,
          'direct': direct,
          'pathLenRaw': l.pathLen,
          'snr': snr,
          'storedSeen': stored(peer()),
        });
        blog('RX copy $n "${l.text}" ${direct ? "direct" : "flood (path_len 0x${l.pathLen.toRadixString(16)})"} '
            'snr ${snr ?? "-"} · stored route ${stored(peer())}');
        if (l.txtType != txtTypePlain ||
            l.timestampRaw < startSecs - 300 ||
            answered.contains(id)) {
          return;
        }
        waiting[id]?.cancel();
        waiting[id] = Timer(quiet, () {
          waiting.remove(id);
          if (!answered.add(id)) return;
          unawaited(reply(l.text).catchError((Object e) {
            blog('⚠ reply failed: $e');
          }));
        });
      }

      String hex(List<int> b) =>
          b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join();

      tap = connector.receivedFrames.listen((frame) {
        if (frame.isEmpty) return;
        switch (frame[0]) {
          case respCodeContactMsgRecv || respCodeContactMsgRecvV3:
            onPeerMessage(frame);
          case pushCodePathUpdated when frame.length >= 33:
            if (hex(frame.sublist(1, 33)).toLowerCase() == peerKey) {
              jsonl({'kind': 'path_updated'});
              blog('PUSH path updated for ${peer().name}');
            }
          case pushCodeSendConfirmed when frame.length >= 9:
            final trip = ByteData.sublistView(frame, 5, 9)
                .getUint32(0, Endian.little);
            jsonl({'kind': 'send_confirmed', 'ack': hex(frame.sublist(1, 5)),
                'tripMs': trip});
          case respCodeSent when frame.length >= 10:
            jsonl({'kind': 'sent', 'flood': frame[1] == 1,
                'ack': hex(frame.sublist(2, 6))});
          case pushCodeLogRxData when frame.length > 4:
            final p = parseRawPacket(Uint8List.sublistView(frame, 3));
            if (p == null) return;
            final kind = packetKind(p.payloadType);
            final ours = p.payload.length >= 2 &&
                {selfByte, peerByte}.contains(p.payload[0]) &&
                {selfByte, peerByte}.contains(p.payload[1]);
            if (kind == 'ack' || ((kind == 'dm' || kind == 'path reply') && ours)) {
              jsonl({
                'kind': 'air',
                'type': kind,
                'route': p.routeType == 0x02 || p.routeType == 0x03
                    ? 'direct'
                    : 'flood',
                'path': p.pathBytes.isEmpty
                    ? ''
                    : PathHelper.formatPathHex(p.pathBytes, stride: p.stride),
                'head': hex(p.payload.sublist(0, p.payload.length.clamp(0, 4))),
                'snr': frame[1].toSigned(8) / 4.0,
              });
            }
        }
      });

      DateTime? downSince;
      timers.add(Timer.periodic(const Duration(seconds: 30), (_) {
        if (connector.isConnected) {
          if (downSince != null) {
            blog('link back after ${DateTime.now().difference(downSince!).inSeconds} s');
            jsonl({'kind': 'link_up'});
          }
          downSince = null;
          return;
        }
        downSince ??= DateTime.now();
        jsonl({'kind': 'link_down', 'ble': bridge.bleConnected});
        if (DateTime.now().difference(downSince!) > const Duration(seconds: 90)) {
          blog('⚠ link down ${DateTime.now().difference(downSince!).inSeconds} s — reconnecting');
          unawaited(connector
              .connectTcp(host: '127.0.0.1', port: BenchConfig.bridgePort)
              .catchError((Object e) => blog('⚠ reconnect failed: $e')));
        }
      }));
      timers.add(Timer.periodic(const Duration(minutes: 10), (_) {
        jsonl({'kind': 'heartbeat', 'connected': connector.isConnected,
            'ble': bridge.bleConnected, 'rx': rxCount, 'tx': replyNo});
        snapshot('periodic');
      }));

      blog('🥾 LISTENING for DMs from ${peer().name} — replies after $quiet of quiet; '
          '"done" ends the run');
      jsonl({'kind': 'listening'});

      final reason = await Future.any([
        done.future,
        Future<String>.delayed(sessionLength, () => 'session length reached'),
      ]);
      snapshot('end');
      jsonl({'kind': 'session_end', 'reason': reason, 'rx': rxCount,
          'tx': replyNo});
      blog('session over: $reason · $rxCount copies in, $replyNo replies out');
      for (final t in waiting.values) {
        t.cancel();
      }
    } finally {
      for (final t in timers) {
        t.cancel();
      }
      await tap?.cancel();
      try {
        await service.stop();
      } catch (_) {}
      try {
        await connector.disconnect();
      } catch (_) {}
      try {
        await bridge.stop();
      } catch (_) {}
      await settings.updateSettings(
          settings.settings.copyWith(maxMessageRetries: savedRetries));
      await out.flush();
      await out.close();
      await appOut.flush();
      await appOut.close();
    }
  }, timeout: const Timeout(Duration(hours: 13)));
}

const _jokes = [
  'Copy that. Your signal smells faintly of pine needles 🌲',
  'Message received. The packets say hi and ask if there are snacks.',
  'Roger. I have alerted the squirrels to your position 🐿️',
  'Got it! Remember: hike like nobody is tracing your route.',
  'Loud and clear. Well, quiet and clear. It is LoRa after all.',
  'Received. If you see a repeater on a hilltop, wave. It might wave back.',
  'Ack! (The real kind, not the firmware kind. Okay, both.)',
  'Your DM took the scenic route. Fitting, really.',
  'Message in. My CPU is jealous of your fresh air.',
  'Noted. Hydrate. That is an order from your radio 💧',
  'Received 5 by 5. Or 5 by 62.5 kHz. Close enough.',
  'Got it. Step 1: hike. Step 2: ??? Step 3: routes.',
  'Copy. The mountain called; it wants its echo back ⛰️',
  'Received! Please do not feed the repeaters.',
  'Your packet arrived slightly out of breath 😮‍💨',
  'Roger roger. Bears do not have BLE, you are probably fine 🐻',
  'Message received and filed under: outdoorsy.',
  'Copy. If lost, follow the strongest SNR home.',
  'Got it. I am just a radio on a desk, living vicariously.',
  'Received. Pathfinder is taking notes. Pathfinder always takes notes.',
  'Ack. Nice hop count. Do you even lift, bro?',
  'Copy that, trail boss 🥾',
  'Heard you! Even the noise floor is impressed.',
  'Received. Somewhere a 2-byte hash just smiled.',
  'Got it. Fun fact: this reply cost about 300 ms of airtime.',
  'Message received. Please rate your hike: ⭐⭐⭐⭐⭐',
  'Copy. Your route back is under review by the committee of repeaters.',
  'Received. Watch out for roots. Tree ones AND path ones.',
  'Ack! I would send a GIF but the airtime budget said no.',
  'Got your message. The desk is quiet without you. Mostly fans whirring.',
  'Roger. Packet integrity: excellent. Packet vibes: immaculate.',
  'Received. Logging this for science 🧪',
  'Copy. Reminder: snacks are a valid waypoint.',
  'Message in. If a tree falls and no repeater hears it, did it ACK?',
  'Got it. Keep going, the next hilltop has better SNR.',
  'Received! Your radio and my radio are basically pen pals now.',
  'Copy that. Altitude is just a hop count for mountains.',
  'Ack. Please stay on the trail; the packets stay on the path.',
  'Message received. Sending encouragement at 7 spreading factor.',
  'Roger. Mesh status: meshing. Hike status: hiking. All nominal.',
];

const _answers = [
  'Great question. The answer is 42, routed via 3 hops.',
  'Hmm. Let me ask the repeaters. They said "maybe".',
  'Yes. Or no. Retry on the next attempt for a different answer.',
  'Signs point to: keep hiking.',
  'I asked Pathfinder. Pathfinder said "flood it".',
  'Short answer: yes. Long answer: does not fit in 150 bytes.',
  'Ask again after the next ACK 🎱',
  'Probably! I am a radio, not a fortune teller. Mostly.',
  'Absolutely. Confidence level: 95%, like a well-proven doorstep.',
  'Unclear. The answer got lost on a 1-byte hop.',
];
