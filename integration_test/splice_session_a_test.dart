import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

/// SESSION A (2026-10-24): the splice, the orphan fix and the keeper rule
/// on the air, from GWQ over its WiFi link, against two rooms.
///
///   A0  bring-up over TCP, graph seeded from a saved session (optional)
///   A1  room A: one flooded login, two posts — the baseline the audit
///       asked for (which rung delivered, how the radio sent it, ACK trip)
///   A2  room A: a CONTROLLED empty case — the forward links the search
///       would use are removed from the seeded graph until Pathfinder's
///       best route is a splice (guessed hops) or nothing; then two posts
///   A3  room B: login, then a window for the owner to post there from
///       the phone so the room pushes to GWQ and the keeper's ACK route
///       can be watched
///   A4  the graph and the app log are saved for the read-out
///
/// RF budget (live mesh, 910.525): two logins, four posts to room A, each
/// on the normal DM ladder (the setting's attempt budget). Message texts
/// are short labels so they stay small on the air.
///
///   flutter test integration_test/splice_session_a_test.dart -d windows \
///     --dart-define=MT_HOST=192.168.4.116 \
///     --dart-define=SESSION_FILE=C:/Users/venam/Downloads/path-graph-2026-10-23.json \
///     --dart-define=OUT_DIR=C:/…/scratchpad \
///     [--dart-define=ROOM_A='Monterey Bay'] [--dart-define=ROOM_B='Meshtrax Room']
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const host = String.fromEnvironment('MT_HOST', defaultValue: '192.168.4.116');
  const port = int.fromEnvironment('MT_TCP_PORT', defaultValue: 5000);
  const roomAName = String.fromEnvironment('ROOM_A', defaultValue: 'Monterey Bay');
  const roomBName = String.fromEnvironment('ROOM_B', defaultValue: 'Meshtrax Room');
  const sessionFile = String.fromEnvironment('SESSION_FILE');
  const outDir = String.fromEnvironment('OUT_DIR', defaultValue: '.');
  // ONLY=A3 runs the bring-up and the keeper window alone (no room A RF);
  // ONLY=A12 runs the room A steps and skips the keeper window.
  const only = String.fromEnvironment('ONLY');
  const skipRoomA = only == 'A3' || only == 'DM' || only == 'PAIR';
  const skipRoomB = only == 'A12' || only == 'DM' || only == 'PAIR';
  // ONLY=DM: two DMs to the chat contact named DM_CONTACT (name prefix,
  // case-blind), on the normal ladder, with a dump before and after.
  const dmContactName = String.fromEnvironment('DM_CONTACT', defaultValue: 'RedTail1');
  // NO_USB_POSTER=1: A3 never opens the COM14 radio; it logs in and waits a
  // short window for pushes that something else (the owner, or a simulated
  // member) makes the room send. The mesh simulator runs A3 this way.
  const noUsbPoster = bool.fromEnvironment('NO_USB_POSTER');
  // A3_NO_LOGIN=1: A3 does not log in to room B (the radio is already a
  // member with a route back, as the simulator seeds it), so the login's
  // PATH reply does not install a live route ahead of Pathfinder's own.
  const a3NoLogin = bool.fromEnvironment('A3_NO_LOGIN');
  // A1_POSTS: how many baseline posts A1 sends (default 2). The simulator
  // uses 4 to show a doorstep being given up after two failed deliveries.
  const a1Posts = int.fromEnvironment('A1_POSTS', defaultValue: 2);

  // Hour-minute-second with dashes: a Windows file name cannot hold colons.
  final stamp =
      DateTime.now().toIso8601String().substring(11, 19).replaceAll(':', '-');
  // Texts carry the run's hour and minute: the status poll reads the
  // message store, and a text reused from an earlier run would answer with
  // that run's outcome. Still under 20 characters.
  final hm = stamp.substring(0, 5).replaceAll('-', '');
  final radio = BenchRadio('TCP($host)');
  final service = PathGraphService();
  final settings = AppSettingsService();
  final debugLog = AppDebugLogService();
  Contact? roomA;
  Contact? roomB;
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
    blog('RX  ${packetKind(packet.payloadType).padRight(10)} $route · '
        'hashes ${packet.stride} B · path $hops · ${snr.toStringAsFixed(1)} dB');
  }

  String fmtRoute(PathGraph graph, PathResult r) => switch (r) {
        DirectResult() => 'direct',
        RouteResult(:final pathBytes, :final estDelivery, :final guessedHops) =>
          '${PathHelper.formatPathHex(pathBytes, stride: graph.hashWidthBytes)} '
              '(${(estDelivery * 100).toStringAsFixed(0)}%'
              '${guessedHops > 0 ? ", $guessedHops guessed" : ""})',
        FloodResult(:final reason) => 'flood — ${reason.name}',
      };

  String fmtCandidate(PathGraph graph, Candidate c) =>
      '${c.repeaterHash} ${c.proven ? "proven" : "heard-only"} '
      'final=${c.finalCount} proofs=${c.provenCount} '
      'conf=${(graph.doorstepConfidence(c) * 100).toStringAsFixed(0)}%';

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
    for (final (i, alt) in graph.findAlternatives(pk).indexed) {
      blog('   alternative ${i + 1}:           ${fmtRoute(graph, alt)}');
    }
    blog('route back:                ${fmtRoute(graph, graph.findReturnPath(pk))}');
    final hints = graph.hintsFor(pk);
    blog('inbound paths kept as hints (${hints.length}): '
        '${hints.isEmpty ? "(none)" : hints.map((h) => '${h.hops.join(",")} @${DateTime.fromMillisecondsSinceEpoch(h.at).toIso8601String().substring(11, 19)}').join(' | ')}');
    final guesses = graph.hintGuessesFor(pk);
    blog('reverse guesses the guard allows (${guesses.length}): '
        '${guesses.isEmpty ? "(none)" : guesses.map((g) => '${g.$1}→${g.$2}').join(' ')}');
  }

  Contact live(Contact c) => radio.connector.contacts
      .firstWhere((x) => x.publicKeyHex == c.publicKeyHex);

  Future<void> clearRoute(Contact c) async {
    blog('clearing the radio\'s stored route to ${c.name} (link only, no RF)');
    await radio.connector.clearContactPath(c);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// One post to [room] on the normal ladder; reports what delivered it.
  Future<MessageStatus?> post(Contact room, String text) async {
    final target = live(room);
    blog('>>> posting "$text" to ${room.name} '
        '(radio route before: pathLength=${target.pathLength})…');
    await radio.connector.sendMessage(target, text);
    final status = await awaitDmStatus(radio, target, text,
        timeout: const Duration(seconds: 150));
    final row = (await radio.connector.loadMessagesFor(target))
        .where((m) => m.isOutgoing && m.text == text)
        .firstOrNull;
    blog('post "$text": status $status · attempts ${(row?.retryCount ?? 0) + 1} · '
        'went ${row == null || (row.pathLength ?? -1) < 0 ? "as a flood" : "on ${PathHelper.formatPathHex(row.pathBytes, stride: row.pathHashSize ?? 2)}"}'
        '${(row?.guessedHops ?? 0) > 0 ? " (${row!.guessedHops} guessed)" : ""} · '
        'source ${row?.routeSource.name} · trip ${row?.tripTimeMs ?? "-"} ms');
    await Future<void>.delayed(const Duration(seconds: 8));
    return status;
  }

  Future<void> save(String name, String body) async {
    final f = File('$outDir/$name');
    await f.writeAsString(body);
    blog('saved ${f.path}');
  }

  tearDownAll(() async {
    await tap?.cancel();
    try {
      if (service.graph != null) {
        await save('session-a-$stamp-graph.json',
            const JsonEncoder.withIndent(' ').convert(service.graph!.saveSession()));
      }
      await save(
          'session-a-$stamp-app.log',
          debugLog.entries
              .map((e) => '${e.timestamp.toIso8601String()} [${e.tag}] ${e.level.name}: ${e.message}')
              .join('\n'));
    } catch (e) {
      blog('save failed: $e');
    }
    try {
      await service.stop();
    } catch (_) {}
    try {
      await radio.connector.disconnect();
    } catch (_) {}
  });

  testWidgets('A0 bring-up: GWQ over WiFi, seeded graph, routes cleared',
      (tester) async {
    await beginScenario(tester, 'A0 Session A bring-up');
    await PrefsManager.initialize();
    appLogger.initialize(debugLog, enabled: true);
    // Every Pathfinder, keeper and ACK line into the console.
    var seen = debugLog.entries.length;
    debugLog.addListener(() {
      final entries = debugLog.entries;
      for (var i = seen; i < entries.length; i++) {
        final e = entries[i];
        if (e.level != AppDebugLogLevel.info ||
            e.tag == 'PathGraph' ||
            e.tag == 'AckHash') {
          blog('[${e.tag}] ${e.message}');
        }
      }
      seen = entries.length;
    });

    await settings.loadSettings();
    blog('attempt budget from settings: ${settings.settings.maxMessageRetries}');

    radio.connector = await buildConnector(appSettings: settings);
    blog('connecting to $host:$port…');
    await radio.connector.connectTcp(host: host, port: port);
    await waitConnectedVerified(radio);
    final c = radio.connector;
    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contacts synced', timeout: const Duration(seconds: 90));
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…) · '
        'path hash width ${c.pathHashByteWidth} B');
    await waitUntil(() => c.currentFreqHz != null, 'radio params known');
    expect(c.currentFreqHz, BenchConfig.meshFreqKhz,
        reason: 'radio is not on the mesh frequency — refusing to transmit');
    expect(c.pathHashByteWidth, 2, reason: 'owner runs 2-byte hashes');

    blog('rooms on this radio: '
        '${c.contacts.where((x) => x.type == advTypeRoom).map((x) => '"${x.name}" ${x.publicKeyHex.substring(0, 8)}').join(', ')}');
    Contact findRoom(String name) {
      final hits = c.contacts
          .where((x) =>
              x.type == advTypeRoom &&
              x.name.trim().toLowerCase() == name.trim().toLowerCase())
          .toList();
      if (hits.length != 1) blog('room "$name": ${hits.length} matches');
      expect(hits, hasLength(1), reason: 'room "$name" is not on the radio');
      return hits.single;
    }

    roomA = findRoom(roomAName);
    roomB = findRoom(roomBName);
    blog('room A: ${roomA!.name} (${roomA!.publicKeyHex.substring(0, 12)}…) · '
        'room B: ${roomB!.name} (${roomB!.publicKeyHex.substring(0, 12)}…)');

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
          blog('RESP sent · ${frame.length > 1 && frame[1] != 0 ? "flood" : "direct"} · '
              '${hex(frame.sublist(1, frame.length.clamp(1, 10)))}');
      }
    });

    blog('starting the real PathGraphService on an in-memory graph…');
    await service.start(c, database: NativeDatabase.memory());
    await waitUntil(() => service.graph?.selfPubkey != null,
        'graph knows the radio identity');
    if (sessionFile.isNotEmpty) {
      final doc = jsonDecode(await File(sessionFile).readAsString())
          as Map<String, dynamic>;
      await service.graph!.loadSession(doc);
      blog('graph seeded from $sessionFile: '
          '${(doc['nodes'] as List?)?.length ?? 0} repeaters, '
          '${(doc['edges'] as List?)?.length ?? 0} links, saved ${doc['saved_at']}');
    } else {
      blog('fresh graph (no SESSION_FILE)');
    }
    for (final r in [roomA!, roomB!]) {
      await clearRoute(r);
    }
    dump('at start', roomA!);
    ready = true;
  });

  testWidgets('A1 baseline: flooded login to room A, two posts',
      skip: skipRoomA, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'A1 baseline');
    blog('>>> login to ${roomA!.name} (no stored route: the radio floods)…');
    final (ok, _) = await repeaterLogin(radio, roomA!, '',
        timeout: const Duration(seconds: 45));
    blog('login result: ${ok == null ? 'TIMEOUT' : ok ? 'SUCCESS' : 'FAIL'}');
    await Future<void>.delayed(const Duration(seconds: 15));
    final r1 = live(roomA!);
    blog('radio route to ${roomA!.name} now: pathLength=${r1.pathLength} '
        'path="${r1.pathIdList}"');
    dump('after the flooded login', roomA!);
    expect(ok, isTrue, reason: 'login failed — nothing to measure against');

    for (var i = 1; i <= a1Posts; i++) {
      await post(roomA!, 'Test $hm: before $i');
      if (i >= 2 && i < a1Posts) dump('after baseline post $i', roomA!);
    }
    dump('after the baseline posts', roomA!);
  });

  testWidgets('A2 splice: what the search offers after the baseline, then two '
      'posts', skip: skipRoomA, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'A2 splice');
    final graph = service.graph!;
    final pk = roomA!.publicKeyHex;
    // Removing links to force a splice was wrong: it deleted the very
    // corridors a splice joins onto. The splice fires or not on its own.
    final result = graph.findPath(pk);
    dump('before the splice posts', roomA!);
    if (result is RouteResult && result.guessedHops > 0) {
      blog('Pathfinder offers a SPLICE with ${result.guessedHops} guessed hop(s): '
          '${fmtRoute(graph, result)}');
    } else {
      blog('no splice offered: best is ${fmtRoute(graph, result)} '
          '(a fully observed route, a live PATH route, or no usable hint) '
          '— no posts, nothing new to learn on the air');
      return;
    }
    await post(roomA!, 'Test $hm: guess 1');
    await post(roomA!, 'Test $hm: guess 2');
    dump('after the splice posts', roomA!);
    final snap = graph.snapshot();
    if (result.guessedHops > 0) {
      final hops = [
        for (var i = 0; i < result.pathBytes.length; i += 2)
          hex(result.pathBytes.sublist(i, i + 2)).replaceAll(' ', '')
      ];
      for (var i = 0; i < hops.length - 1; i++) {
        if (!result.guessedLinks[i]) continue;
        final e = snap.edges[(hops[i], hops[i + 1])];
        blog('guessed link ${hops[i]}→${hops[i + 1]} after the posts: '
            '${e == null ? "not in the graph (no delivery proved it)" : "s=${e.s} n=${e.n} (proven forward)"}');
      }
    }
  });

  testWidgets('D1 DM: two messages to a chat contact on the normal ladder',
      skip: only != 'DM', (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'D1 DM to $dmContactName');
    final c = radio.connector;
    final hits = c.contacts
        .where((x) =>
            x.type == advTypeChat &&
            x.name.trim().toLowerCase().startsWith(dmContactName.toLowerCase()))
        .toList();
    blog('chat contacts matching "$dmContactName": '
        '${hits.map((x) => '"${x.name}" ${x.publicKeyHex.substring(0, 8)} route=${x.pathLength}').join(', ')}');
    expect(hits, hasLength(1), reason: 'need exactly one contact named like that');
    final who = hits.single;
    await clearRoute(who);
    dump('before the DMs', who);
    await post(who, 'Test $hm: dm 1');
    dump('after DM 1', who);
    await post(who, 'Test $hm: dm 2');
    blog('listening 45 s for anything ${who.name} sends back…');
    await Future<void>.delayed(const Duration(seconds: 45));
    final w = live(who);
    blog('radio route to ${who.name} now: pathLength=${w.pathLength} path="${w.pathIdList}"');
    dump('after the DMs', who);
  });

  // ONLY=PAIR: a sanity check that DMs work at all tonight. The COM14 bench
  // radio adverts, GWQ adverts, then one DM each way on the normal ladder.
  testWidgets('P1 pair: adverts both ways, then a DM each way',
      skip: only != 'PAIR', (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'P1 Whale <-> GWQ');
    final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
    usb.connector = await buildConnector(appSettings: settings);
    blog('connecting the bench radio on ${BenchConfig.usbPortName}…');
    await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
    await waitConnectedVerified(usb);
    await waitUntil(() => !usb.connector.isLoadingContacts,
        'bench radio contacts synced', timeout: const Duration(seconds: 60));
    await alignFrequency(usb, khz: BenchConfig.meshFreqKhz);
    // Whale's own view of the air, so a lost first attempt can be placed:
    // never transmitted, not heard, or heard and not answered.
    final usbTap = usb.connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      switch (frame[0]) {
        case pushCodeLogRxData:
          if (frame.length > 4) {
            final snr = frame[1].toSigned(8) / 4.0;
            final packet = parseRawPacket(Uint8List.sublistView(frame, 3));
            if (packet == null) return;
            final hops = packet.pathBytes.isEmpty
                ? '(no path)'
                : PathHelper.formatPathHex(packet.pathBytes, stride: packet.stride);
            blog('W-RX ${packetKind(packet.payloadType).padRight(10)} '
                '${packet.routeType == 0x02 ? "direct" : "flood"} · path $hops · '
                '${snr.toStringAsFixed(1)} dB');
          }
        case pushCodeSendConfirmed:
          blog('W-PUSH send confirmed (ack ${hex(frame.sublist(1, 5))})');
        case pushCodePathUpdated:
          blog('W-PUSH path updated for ${hex(frame.sublist(1, 4))}…');
        case respCodeSent:
          blog('W-RESP sent · ${frame.length > 1 && frame[1] != 0 ? "flood" : "direct"} · '
              '${hex(frame.sublist(1, frame.length.clamp(1, 10)))}');
      }
    });
    final whaleKey = usb.connector.selfPublicKeyHex;
    final gwqKey = radio.connector.selfPublicKeyHex;
    blog('bench radio: ${usb.connector.selfName} (${whaleKey.substring(0, 12)}…) '
        'tx ${usb.connector.currentTxPower ?? "?"} dBm · '
        'GWQ: ${radio.connector.selfName} (${gwqKey.substring(0, 12)}…) '
        'tx ${radio.connector.currentTxPower ?? "?"} dBm');
    final whaleTx = usb.connector.currentTxPower;
    if (whaleTx != null && whaleTx < 10) {
      blog('bench radio transmits at $whaleTx dBm — raising to 18 for the test');
      await usb.connector.sendFrame(buildSetRadioTxPowerFrame(18));
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final whaleKnownBefore = findContactByHex(radio.connector, whaleKey) != null;
    final gwqKnownBefore = findContactByHex(usb.connector, gwqKey) != null;
    blog('before adverts: GWQ knows bench radio: $whaleKnownBefore · '
        'bench radio knows GWQ: $gwqKnownBefore');

    blog('>>> bench radio adverts (flood)…');
    await usb.connector.sendSelfAdvert(flood: true);
    final heardWhale = await pollFor(
        () => findContactByHex(radio.connector, whaleKey) != null,
        const Duration(seconds: 25));
    blog('GWQ heard the advert from the bench radio: $heardWhale');

    blog('>>> GWQ adverts (flood)…');
    await radio.connector.sendSelfAdvert(flood: true);
    final heardGwq = await pollFor(
        () => findContactByHex(usb.connector, gwqKey) != null,
        const Duration(seconds: 25));
    blog('bench radio heard the advert from GWQ: $heardGwq');

    Contact? whaleOnGwq;
    Contact? gwqOnWhale;
    if (heardWhale) {
      whaleOnGwq = await ensureSavedContact(radio, whaleKey, 'bench radio');
    }
    if (heardGwq) {
      gwqOnWhale = await ensureSavedContact(usb, gwqKey, 'GWQ');
    }

    blog('letting the air settle 45 s after the adverts…');
    await Future<void>.delayed(const Duration(seconds: 45));
    if (whaleOnGwq != null) {
      dump('before GWQ -> bench radio', whaleOnGwq);
      await post(whaleOnGwq, 'Test $hm: pair 1');
      if (gwqOnWhale != null) {
        final arrived1 = await dmArrived(usb, gwqOnWhale, 'Test $hm: pair 1',
            timeout: const Duration(seconds: 20));
        blog('bench radio received "pair 1": $arrived1');
      }
    } else {
      blog('GWQ -> bench radio DM skipped: GWQ has no contact for it');
    }
    if (gwqOnWhale != null) {
      final target = usb.connector.contacts
          .firstWhere((c) => c.publicKeyHex == gwqOnWhale!.publicKeyHex);
      blog('>>> bench radio posts "Test $hm: pair 2" to GWQ '
          '(its route: pathLength=${target.pathLength})…');
      await usb.connector.sendMessage(target, 'Test $hm: pair 2');
      final st2 = await awaitDmStatus(usb, target, 'Test $hm: pair 2',
          timeout: const Duration(seconds: 150));
      final arrived2 = whaleOnGwq == null
          ? null
          : await dmArrived(radio, whaleOnGwq, 'Test $hm: pair 2',
              timeout: const Duration(seconds: 20));
      blog('bench radio -> GWQ "pair 2": status $st2 · GWQ received: $arrived2');
    } else {
      blog('bench radio -> GWQ DM skipped: bench radio has no contact for GWQ');
    }
    if (whaleOnGwq != null) dump('after the pair DMs', whaleOnGwq);
    await usbTap.cancel();
    try {
      await usb.connector.disconnect();
    } catch (_) {}
  });

  testWidgets('A3 keeper: login to room B, then a window for pushes from it',
      skip: skipRoomB, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'A3 keeper window');
    if (a3NoLogin) {
      blog('A3_NO_LOGIN: not logging in to ${roomB!.name}; already a member');
    } else {
      blog('>>> login to ${roomB!.name}…');
      final (ok, _) = await repeaterLogin(radio, roomB!, '',
          timeout: const Duration(seconds: 45));
      blog('login result: ${ok == null ? 'TIMEOUT' : ok ? 'SUCCESS' : 'FAIL'}');
    }
    await Future<void>.delayed(const Duration(seconds: 5));
    dump('after the room B login', roomB!);
    final startCount = (await radio.connector.loadMessagesFor(live(roomB!)))
        .where((m) => !m.isOutgoing)
        .length;

    // The second bench radio posts in room B so the room pushes to GWQ.
    // Without it (or without the room on it) the owner posts by hand.
    var posterReady = false;
    final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
    if (noUsbPoster) {
      blog('NO_USB_POSTER: not opening ${BenchConfig.usbPortName}; waiting '
          'for pushes made by other members of the room');
    }
    try {
      if (noUsbPoster) throw StateError('no USB poster by request');
      usb.connector = await buildConnector(appSettings: settings);
      blog('connecting the bench radio on ${BenchConfig.usbPortName}…');
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
      await waitUntil(
          () => !usb.connector.isLoadingContacts &&
              usb.connector.contacts.isNotEmpty,
          'bench radio contacts synced',
          timeout: const Duration(seconds: 60));
      await alignFrequency(usb, khz: BenchConfig.meshFreqKhz);
      // The same room by its KEY: the two radios may know it by different
      // names (an advert renamed it after one of them saved it).
      blog('rooms on the bench radio: '
          '${usb.connector.contacts.where((x) => x.type == advTypeRoom).map((x) => '"${x.name}" ${x.publicKeyHex.substring(0, 8)}').join(', ')}');
      final its = usb.connector.contacts
          .where((x) =>
              x.publicKeyHex.toLowerCase() == roomB!.publicKeyHex.toLowerCase())
          .toList();
      if (its.length == 1) {
        blog('>>> bench radio logs in to ${roomB!.name}…');
        final (ok2, _) = await repeaterLogin(usb, its.single, '',
            timeout: const Duration(seconds: 45));
        blog('bench radio login: ${ok2 == null ? 'TIMEOUT' : ok2 ? 'SUCCESS' : 'FAIL'}');
        posterReady = ok2 == true;
        if (posterReady) {
          for (final text in const ['Test: ack route 1', 'Test: ack route 2']) {
            final target = usb.connector.contacts
                .firstWhere((x) => x.publicKeyHex == its.single.publicKeyHex);
            blog('>>> bench radio posts "$text"…');
            await usb.connector.sendMessage(target, text);
            final st = await awaitDmStatus(usb, target, text,
                timeout: const Duration(seconds: 120));
            blog('bench radio post "$text": $st');
            await Future<void>.delayed(const Duration(seconds: 20));
          }
        }
      } else {
        blog('bench radio does not have "${roomB!.name}" as a contact '
            '(${its.length} matches)');
      }
    } catch (e) {
      blog('bench radio unavailable: $e');
    }
    if (!posterReady && !noUsbPoster) {
      blog('OWNER: please post TWICE in "${roomB!.name}" from your phone now '
          '("Test: ack route 1", "Test: ack route 2"). Waiting up to 8 minutes…');
    }
    final deadline = DateTime.now().add(posterReady
        ? const Duration(minutes: 1)
        : noUsbPoster
            ? const Duration(minutes: 2)
            : const Duration(minutes: 8));
    var got = 0;
    while (DateTime.now().isBefore(deadline) && got < 2) {
      await Future<void>.delayed(const Duration(seconds: 5));
      got = (await radio.connector.loadMessagesFor(live(roomB!)))
              .where((m) => !m.isOutgoing)
              .length -
          startCount;
    }
    blog('pushes from ${roomB!.name} received in the window: $got');
    final rb = live(roomB!);
    blog('radio route to ${roomB!.name} now: pathLength=${rb.pathLength} '
        'path="${rb.pathIdList}" (what my ACKs go on)');
    dump('after the keeper window', roomB!);
    if (!noUsbPoster) {
      try {
        await usb.connector.disconnect();
      } catch (_) {}
    }
  });
}
