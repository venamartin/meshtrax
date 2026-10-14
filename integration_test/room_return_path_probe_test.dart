import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/path_graph/frame_adapter.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// PROBE ONLY — what does a room server actually send back?
///
/// Question under test (owner, 2026-10-13): the Pathfinder graph says the
/// room's flooded replies arrive with 1-byte path hashes and drops them.
/// This probe logs every packet the BLE companion hears, raw, around a
/// flooded login and one post, so the width of the room's replies is read
/// off the wire instead of inferred from a counter.
///
/// The room comes from a define (its full 64-hex public key) so no
/// third-party identity lives in the repo. Without it every test is skipped.
///
/// RF budget (live mesh, 910.525): ONE login flood and ONE post from us.
/// The send budget is pinned to one attempt for the run (the saved value
/// comes back afterwards). The path reset and contact fetches are
/// link-only. Nothing else transmits.
///
/// Run with:
///   flutter test integration_test/room_return_path_probe_test.dart -d windows \
///     --dart-define=PROBE_ROOM_KEY=<64 hex>
///     [--dart-define=ROOM_PASSWORD=xxxx]   (blank = known client)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const password = String.fromEnvironment('ROOM_PASSWORD');
  const roomKey = String.fromEnvironment('PROBE_ROOM_KEY');
  const missingRoom = roomKey == '';
  if (missingRoom) {
    debugPrint('room probe skipped: needs --dart-define=PROBE_ROOM_KEY '
        '(the room\'s full 64-hex public key)');
  }
  const probeText = 'Pathfinder return path test';

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  final settings = AppSettingsService();
  int? savedRetries;
  Contact? room;
  var ready = false;
  StreamSubscription<Uint8List>? tap;

  String hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  String describePathLen(int raw) {
    final b = raw & 0xFF;
    if (b == 0xFF) return '0xFF (no route / flood)';
    final count = b & 0x3F;
    final width = ((b >> 6) & 0x03) + 1;
    return '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()} '
        '(count=$count, width=$width byte(s))';
  }

  /// Every packet the radio hears, decoded the way the path graph sees it.
  void logRx(Uint8List frame) {
    final snr = frame[1].toSigned(8) / 4.0;
    final rssi = frame[2].toSigned(8);
    final packet = parseRawPacket(Uint8List.sublistView(frame, 3));
    if (packet == null) {
      blog('RX  unparsed ${frame.length - 3} B · ${snr.toStringAsFixed(1)} dB');
      return;
    }
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
        ? ' · payload starts ${hex(packet.payload.sublist(0, 2))}'
        : '';
    blog('RX  ${packetKind(packet.payloadType).padRight(10)} $route · '
        'hashes ${packet.stride} B · path $hops$head · '
        '${snr.toStringAsFixed(1)} dB / $rssi dBm');
  }

  Future<Uint8List?> fetchRawContactFrame(Uint8List pubKey) async {
    final completer = Completer<Uint8List?>();
    final sub = ble.connector.receivedFrames.listen((frame) {
      if (frame.length < 36 || frame[0] != respCodeContact) return;
      if (!listEquals(frame.sublist(1, 33), pubKey)) return;
      if (!completer.isCompleted) completer.complete(frame);
    });
    try {
      await ble.connector.sendFrame(buildGetContactByKeyFrame(pubKey));
      return await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  void logStoredRoute(String when, Uint8List frame) {
    final pathLenByte = frame[35];
    final byteLen = PathHelper.pathLenBytes(pathLenByte);
    final pathBytes = frame
        .sublist(36, 36 + maxPathSize)
        .sublist(0, byteLen.clamp(0, maxPathSize));
    blog('--- radio\'s stored route to the room, $when ---');
    blog('path_len byte: ${describePathLen(pathLenByte)}');
    blog('path bytes   : ${pathBytes.isEmpty ? '(none)' : hex(pathBytes)}');
  }

  tearDownAll(() async {
    await tap?.cancel();
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

  testWidgets('R0 bring-up: BLE companion on the mesh, room contact found',
      skip: missingRoom, (tester) async {
    await beginScenario(tester, 'R0 room probe bring-up');
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
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…)');
    blog('firmware path hash width: ${c.pathHashByteWidth} byte(s)');
    await waitUntil(() => c.currentFreqHz != null && c.currentSf != null,
        'radio params known');
    blog('freq=${(c.currentFreqHz! / 1000).toStringAsFixed(3)} MHz '
        'bw=${c.currentBwHz} sf=${c.currentSf} cr=${c.currentCr}');
    expect(c.currentFreqHz, BenchConfig.meshFreqKhz,
        reason: 'the radio is not on the mesh frequency — refusing to '
            'transmit anywhere else; park it on 910.525 and re-run');

    // Exactly one room with this full key: a near match would send a real
    // login to the wrong node.
    final want = roomKey.toLowerCase();
    expect(want, matches(RegExp(r'^[0-9a-f]{64}$')),
        reason: 'PROBE_ROOM_KEY must be 64 hex characters');
    final hits = c.allContacts
        .where((x) =>
            x.publicKeyHex.toLowerCase() == want && x.type == advTypeRoom)
        .toList();
    expect(hits, hasLength(1), reason: 'the room is not on the BLE companion');
    room = hits.single;
    final inRadioDb = c.contacts.any((x) => x.publicKeyHex == room!.publicKeyHex);
    if (!inRadioDb) {
      blog('room is discovered-only — importing to the radio DB (no RF)');
      expect(await c.importDiscoveredContact(room!), isTrue);
      await waitUntil(
          () => c.contacts.any((x) => x.publicKeyHex == room!.publicKeyHex),
          'room saved to contacts');
      room = c.contacts.firstWhere((x) => x.publicKeyHex == room!.publicKeyHex);
    }
    blog('target: ${room!.name} (${room!.shortPubKeyHex}) type=${room!.type}');
    blog('app-parsed route: pathLength=${room!.pathLength} '
        'pathHashSize=${room!.pathHashSize} path="${room!.pathIdList}"');

    tap = c.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      switch (frame[0]) {
        case pushCodeLogRxData:
          if (frame.length > 4) logRx(frame);
        case pushCodePathUpdated:
          blog('PUSH path updated · ${hex(frame.sublist(1, frame.length.clamp(1, 40)))}');
        case pushCodeLoginSuccess:
          blog('PUSH login success · admin=${frame[1] == 1}');
        case pushCodeLoginFail:
          blog('PUSH login FAIL');
        case respCodeSent:
          blog('RESP sent · ${hex(frame.sublist(1, frame.length.clamp(1, 12)))}');
        case 0x82: // PUSH_CODE_SEND_CONFIRMED (ack)
          blog('PUSH send confirmed (ack) · ${hex(frame.sublist(1, frame.length.clamp(1, 12)))}');
      }
    });
    ready = true;
  });

  testWidgets('R1 forget the route, log in by flood, read what comes back',
      skip: missingRoom, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'R1 flooded room login');
    final c = ble.connector;
    final key = room!.publicKey;

    final before = await fetchRawContactFrame(key);
    if (before != null) logStoredRoute('BEFORE', before);

    blog('forgetting the stored route (link-only command, no RF)');
    await c.sendFrame(buildResetPathFrame(key));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final afterReset = await fetchRawContactFrame(key);
    if (afterReset != null) logStoredRoute('after reset', afterReset);

    blog('>>> login by flood (password ${password.isEmpty ? "blank" : "set"})…');
    final (ok, admin) = await repeaterLogin(ble, room!, password,
        timeout: const Duration(seconds: 45));
    blog('login result: ${ok == null ? 'TIMEOUT' : ok ? 'SUCCESS' : 'FAIL'}'
        '${ok == true ? ' (admin=$admin)' : ''}');

    blog('listening 10 s more for late copies…');
    await Future<void>.delayed(const Duration(seconds: 10));

    final after = await fetchRawContactFrame(key);
    if (after != null) logStoredRoute('AFTER LOGIN', after);
    expect(ok, isTrue, reason: 'login did not succeed — nothing to read');
  });

  testWidgets('R2 post the test message, read the ack and any flood back',
      skip: missingRoom, (tester) async {
    if (!ready) fail('Bench not ready — see the first failure above.');
    await beginScenario(tester, 'R2 post to the room');
    final c = ble.connector;
    final live = c.contacts.firstWhere((x) => x.publicKeyHex == room!.publicKeyHex);
    blog('>>> posting "$probeText" (route: pathLength=${live.pathLength} '
        'width=${live.pathHashSize})…');
    await c.sendMessage(live, probeText);
    blog('listening 40 s for the ack and anything flooded back…');
    await Future<void>.delayed(const Duration(seconds: 40));
    final after = await fetchRawContactFrame(room!.publicKey);
    if (after != null) logStoredRoute('AFTER POST', after);
    blog('done — read the RX lines above: "hashes N B" is the width the '
        'sender flooded with.');
  });
}
