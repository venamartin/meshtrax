import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/path_graph/frame_adapter.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';
import 'package:path_graph/path_graph.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// PROBE — what does the Pathfinder graph LEARN from real traffic?
///
/// The room probe showed the wire; this one runs the real
/// [PathGraphService] (the app's own wiring: adapter, PATH-reply
/// attribution, attempt results) on an in-memory graph against the BLE
/// companion, and dumps what the graph holds after each step:
///   1. the radio's stored routes to every target are cleared;
///   2. one flooded login to the room, then one post;
///   3. one DM to contact A, then a listen window;
///   4. optionally, one DM to contact B, then a listen window.
/// After every step: who hears the contact, who hears me, the route to
/// them, the route back, and the packet-log rows that explain it.
///
/// Targets come from defines (full 64-hex public keys) so no third-party
/// identity lives in the repo. Without them every test is skipped.
///
/// RF budget (live mesh, 910.525): one login flood, one room post, one DM
/// (two with contact B). The send budget is pinned to one attempt per
/// message for the run, so nothing is retried; the saved value comes back
/// afterwards. Ask the contacts first — they receive a real DM.
///
/// Run with:
///   flutter test integration_test/pathfinder_learning_probe_test.dart -d windows \
///     --dart-define=PROBE_ROOM_KEY=<64 hex> --dart-define=PROBE_DM_KEY=<64 hex> \
///     [--dart-define=PROBE_SECOND_DM_KEY=<64 hex>]
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const roomKey = String.fromEnvironment('PROBE_ROOM_KEY');
  const contactAKey = String.fromEnvironment('PROBE_DM_KEY');
  const contactBKey = String.fromEnvironment('PROBE_SECOND_DM_KEY');
  const missingTargets = roomKey == '' || contactAKey == '';
  if (missingTargets) {
    debugPrint('learning probe skipped: needs --dart-define=PROBE_ROOM_KEY '
        'and --dart-define=PROBE_DM_KEY (full 64-hex public keys)');
  }
  // Unique per run: the status poll reads the message store, and a text
  // reused from an earlier run would answer with that run's outcome.
  final stamp = DateTime.now().toIso8601String().substring(11, 19);
  final roomText = 'Pathfinder bench $stamp: room post';
  final dmText = 'Pathfinder bench $stamp: DM test';

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  final service = PathGraphService();
  final settings = AppSettingsService();
  int? savedRetries;
  Contact? room;
  Contact? contactA;
  Contact? contactB;
  var ready = false;
  StreamSubscription<Uint8List>? tap;

  String hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  void logRx(Uint8List frame) {
    final snr = frame[1].toSigned(8) / 4.0;
    final packet = parseRawPacket(Uint8List.sublistView(frame, 3));
    if (packet == null) return;
    final route = switch (packet.routeType) {
      0x00 => 'transport-flood',
      0x01 => 'flood',
      0x02 => 'direct',
      0x03 => 'transport-direct',
      _ => 'route ${packet.routeType}',
    };
    final hops = packet.pathBytes.isEmpty
        ? '(no path)'
        : PathHelper.formatPathHex(packet.pathBytes, stride: packet.stride);
    final head = packet.payload.length >= 2
        ? ' · payload ${hex(packet.payload.sublist(0, packet.payload.length.clamp(0, 4)))}'
        : '';
    blog('RX  ${packetKind(packet.payloadType).padRight(10)} $route · '
        'hashes ${packet.stride} B · path $hops$head · '
        '${snr.toStringAsFixed(1)} dB');
  }

  String fmtRoute(PathGraph graph, PathResult r) => switch (r) {
        DirectResult() => 'direct',
        RouteResult(:final pathBytes, :final estDelivery) =>
          '${PathHelper.formatPathHex(pathBytes, stride: graph.hashWidthBytes)} '
              '(${(estDelivery * 100).toStringAsFixed(0)}%)',
        FloodResult(:final reason) => 'flood — ${reason.name}',
      };

  String fmtCandidate(PathGraph graph, Candidate c) =>
      '${c.repeaterHash} ${c.proven ? "proven" : "heard-only"} '
      'heard=${c.heard} final=${c.finalCount} proofs=${c.provenCount} '
      'up=${c.uplinkSnr?.toStringAsFixed(1) ?? "-"} '
      'down=${c.downlinkSnr?.toStringAsFixed(1) ?? "-"} '
      'conf=${(graph.doorstepConfidence(c) * 100).toStringAsFixed(0)}%';

  /// Everything the graph holds that bears on [contact], in plain lines.
  void dump(String when, Contact contact) {
    final graph = service.graph!;
    final pk = contact.publicKeyHex;
    blog('=== GRAPH $when ===');
    blog('repeaters that hear me: '
        '${graph.egressCandidates().take(6).map((c) => fmtCandidate(graph, c)).join(' | ')}');
    final theirs = graph.ingressCandidates(pk);
    blog('repeaters that hear ${contact.name}: '
        '${theirs.isEmpty ? "(none)" : theirs.map((c) => fmtCandidate(graph, c)).join(' | ')}');
    blog('route to ${contact.name}:   ${fmtRoute(graph, graph.findPath(pk))}');
    blog('route back:                ${fmtRoute(graph, graph.findReturnPath(pk))}');
    final log = service.adapter?.packetLog ?? const <PacketLogEntry>[];
    blog('packet log (newest first, ${log.length} rows):');
    for (final e in log.take(12)) {
      blog('   ${e.kind.padRight(10)} ${e.path.isEmpty ? "(no path)" : e.path} · ${e.verdict}');
    }
  }

  Future<void> clearRoute(Contact c) async {
    blog('clearing the radio\'s stored route to ${c.name} (link only, no RF)');
    await ble.connector.clearContactPath(c); // resets the radio AND the cached contact
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Contact live(Contact c) =>
      ble.connector.contacts.firstWhere((x) => x.publicKeyHex == c.publicKeyHex);

  tearDownAll(() async {
    await tap?.cancel();
    try {
      await service.stop();
    } catch (_) {}
    try {
      await ble.connector.disconnect();
    } catch (_) {}
    try {
      await bridge.stop();
    } catch (_) {}
    if (savedRetries != null) {
      await settings.updateSettings(
          settings.settings.copyWith(maxMessageRetries: savedRetries));
    }
  });

  testWidgets('L0 bring-up: BLE companion, routes cleared, fresh graph',
      skip: missingTargets, (tester) async {
    await beginScenario(tester, 'L0 learning probe bring-up');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    await settings.loadSettings();
    savedRetries = settings.settings.maxMessageRetries;
    await settings
        .updateSettings(settings.settings.copyWith(maxMessageRetries: 1));
    blog('send budget pinned to 1 attempt (saved value $savedRetries)');

    ble.connector = await buildConnector(appSettings: settings);
    blog('starting BLE bridge…');
    await bridge.start();
    await ble.connector
        .connectTcp(host: '127.0.0.1', port: BenchConfig.bridgePort);
    await waitConnectedVerified(ble);
    final c = ble.connector;
    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contacts synced', timeout: const Duration(seconds: 60));
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…) · '
        'path hash width ${c.pathHashByteWidth} B');
    await waitUntil(() => c.currentFreqHz != null, 'radio params known');
    expect(c.currentFreqHz, BenchConfig.meshFreqKhz,
        reason: 'radio is not on the mesh frequency — refusing to transmit');
    expect(c.pathHashByteWidth, 2, reason: 'owner runs 2-byte hashes');

    /// Exactly one contact with this full key and type, or the test fails:
    /// a near match would send a real packet to the wrong node.
    Contact find(String label, String key, int type) {
      final want = key.toLowerCase();
      expect(want, matches(RegExp(r'^[0-9a-f]{64}$')),
          reason: '$label key must be 64 hex characters');
      final hits = c.contacts
          .where((x) => x.publicKeyHex.toLowerCase() == want && x.type == type)
          .toList();
      expect(hits, hasLength(1), reason: '$label is not on the radio');
      return hits.single;
    }

    room = find('room', roomKey, advTypeRoom);
    contactA = find('contact A', contactAKey, advTypeChat);
    if (contactBKey.isNotEmpty) {
      contactB = find('contact B', contactBKey, advTypeChat);
    }
    blog('room: ${room!.name} · contact A: ${contactA!.name}'
        '${contactB == null ? '' : ' · contact B: ${contactB!.name}'}');

    for (final target in [room!, contactA!, ?contactB]) {
      await clearRoute(target);
    }

    tap = c.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      switch (frame[0]) {
        case pushCodeLogRxData:
          if (frame.length > 4) logRx(frame);
        case pushCodePathUpdated:
          blog('PUSH path updated for ${hex(frame.sublist(1, 4))}…');
        case pushCodeLoginSuccess:
          blog('PUSH login success');
        case pushCodeLoginFail:
          blog('PUSH login FAIL');
        case pushCodeSendConfirmed:
          blog('PUSH send confirmed (ack ${hex(frame.sublist(1, 5))})');
        case respCodeSent:
          blog('RESP sent · ${hex(frame.sublist(1, frame.length.clamp(1, 10)))}');
        case respCodeErr:
          blog('RESP ERR · ${hex(frame.sublist(1, frame.length.clamp(1, 6)))}');
        case respCodeOk:
          blog('RESP ok');
      }
    });

    blog('starting the real PathGraphService on an in-memory graph…');
    await service.start(c, database: NativeDatabase.memory());
    await waitUntil(() => service.graph?.selfPubkey != null,
        'graph knows the radio identity');
    dump('at start (fresh graph, nothing learned)', room!);
    ready = true;
  });

  testWidgets('L1 room: one flooded login, then one post',
      skip: missingTargets, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'L1 room login + post');
    blog('>>> login by flood (one try)…');
    final (ok, _) = await repeaterLogin(ble, room!, '',
        timeout: const Duration(seconds: 45));
    blog('login result: ${ok == null ? 'TIMEOUT' : ok ? 'SUCCESS' : 'FAIL'}');
    blog('listening 15 s for late copies and the radio\'s route…');
    await Future<void>.delayed(const Duration(seconds: 15));
    final r1 = live(room!);
    blog('radio route to the room now: pathLength=${r1.pathLength} '
        'width=${r1.pathHashSize} path="${r1.pathIdList}"');
    dump('after the flooded login', room!);
    expect(ok, isTrue, reason: 'login failed — nothing to learn from');

    blog('>>> posting "$roomText"…');
    await ble.connector.sendMessage(r1, roomText);
    final status = await awaitDmStatus(ble, r1, roomText,
        timeout: const Duration(seconds: 90));
    blog('post status: $status');
    await Future<void>.delayed(const Duration(seconds: 10));
    final r2 = live(room!);
    blog('radio route to the room now: pathLength=${r2.pathLength} '
        'width=${r2.pathHashSize} path="${r2.pathIdList}"');
    dump('after the post', room!);
  });

  /// One DM to [who] with the radio's route cleared first, then a listen
  /// window for whatever they send back.
  Future<MessageStatus?> dmStep(Contact who, String text) async {
    await clearRoute(who);
    dump('before the DM', who);
    final target = live(who);
    blog('>>> sending DM "$text" (radio route: pathLength=${target.pathLength})…');
    await ble.connector.sendMessage(target, text);
    final status = await awaitDmStatus(ble, target, text,
        timeout: const Duration(seconds: 120));
    blog('DM status: $status');
    await Future<void>.delayed(const Duration(seconds: 10));
    final t2 = live(who);
    blog('radio route to ${who.name} now: pathLength=${t2.pathLength} '
        'width=${t2.pathHashSize} path="${t2.pathIdList}"');
    dump('after the DM', who);
    blog('listening 60 s for anything ${who.name} sends back…');
    await Future<void>.delayed(const Duration(seconds: 60));
    final t3 = live(who);
    blog('radio route to ${who.name} now: pathLength=${t3.pathLength} '
        'width=${t3.pathHashSize} path="${t3.pathIdList}"');
    dump('after the listen window', who);
    return status;
  }

  testWidgets('L2 contact A: route cleared, one DM, then listen',
      skip: missingTargets, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'L2 DM to contact A');
    final status = await dmStep(contactA!, dmText);
    expect(status, isNot(MessageStatus.failed),
        reason: 'the DM failed — contact A may be off the air');
  });

  testWidgets('L3 contact B: route cleared, one DM, then listen',
      skip: missingTargets || contactBKey == '', (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'L3 DM to contact B');
    final status = await dmStep(contactB!, dmText);
    expect(status, isNot(MessageStatus.failed),
        reason: 'the DM failed — contact B may be off the air');
  });
}
