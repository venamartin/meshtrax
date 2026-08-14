import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// MeshCore One reaction send/receive over real radios, on 920.000 MHz.
///
/// Covers the three defects the format switch had to fix, plus the parked
/// -orphan flow:
///   X1  a reaction sent in the MC1 dialect lands as a CHIP on both radios
///       and never appears as a visible message on the sender's own screen
///   X2  the DM path, including the reactor's own chip reaching a terminal
///       send status (the bug: it was stuck "pending" forever because
///       _setReactionStatus re-derived the legacy hash)
///   X3  a reaction whose target the receiver doesn't hold parks as an
///       orphan, then RESOLVES when the target message finally arrives
///
///   flutter test integration_test/mc1_reaction_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  String tag(String s) => 'mc1[$runTag] $s';

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final radios = [usb, ble];
  final bridge = BleNusTcpBridge();

  final pskRx = Channel.derivePskFromHashtag('#mc1rx');
  final idKeyRx = Channel.formatPskHex(pskRx);

  var benchReady = false;
  void requireBench() {
    if (!benchReady) fail('Bench not ready — see X0 failure above.');
  }

  /// The stored copy of [text] on [radio]'s [idKeyRx] channel.
  Future<ChannelMessage?> channelRow(BenchRadio radio, String text) async {
    final ch = liveByIdKey(radio.connector, idKeyRx);
    if (ch == null) return null;
    for (final m in await radio.connector.loadChannelMessagesFor(ch)) {
      if (m.text == text) return m;
    }
    return null;
  }

  /// Polls until [text]'s row on [radio] carries [emoji], or the window
  /// closes. Returns the reactor names recorded for that emoji.
  Future<List<String>?> awaitChip(
    BenchRadio radio,
    String text,
    String emoji, {
    Duration timeout = const Duration(seconds: 75),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final row = await channelRow(radio, text);
      if (row != null && (row.reactions[emoji] ?? 0) > 0) {
        return row.reactionSenders[emoji] ?? const [];
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  /// Every stored text on [radio]'s harness channel — used to prove a
  /// reaction never became a visible message row.
  Future<List<String>> allTexts(BenchRadio radio) async {
    final ch = liveByIdKey(radio.connector, idKeyRx);
    if (ch == null) return [];
    return (await radio.connector.loadChannelMessagesFor(ch))
        .map((m) => m.text)
        .toList();
  }

  /// pollFor, for conditions that must hit the database.
  Future<bool> pollForAsync(
    Future<bool> Function() condition,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (!await condition()) {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return true;
  }

  tearDownAll(() async {
    for (final r in radios) {
      try {
        await r.connector.disconnect();
      } catch (_) {}
    }
    try {
      await bridge.stop();
    } catch (_) {}
  });

  testWidgets('X0 bench comes up on 920.000 MHz with a clean channel',
      (tester) async {
    await beginScenario(tester, 'X0 bring-up');
    blog('MC1 reaction bench, run tag: $runTag');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    usb.connector = await buildConnector();
    ble.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    ble.reconnect = () async {
      await ble.connector.connectTcp(
        host: '127.0.0.1',
        port: BenchConfig.bridgePort,
      );
      await waitConnectedVerified(ble);
    };

    blog('starting BLE bridge (watch for a Windows pairing prompt)…');
    await bridge.start();
    await usb.reconnect();
    await ble.reconnect();

    blog('USB radio: ${usb.connector.selfName}');
    blog('BLE radio: ${ble.connector.selfName}');
    expect(usb.connector.selfPublicKeyHex,
        isNot(equals(ble.connector.selfPublicKeyHex)),
        reason: 'Both transports reached the SAME radio — check the bench.');

    // Standing bench rule: RF traffic goes on 920.000 only, never the mesh.
    await alignFrequency(usb);
    await alignFrequency(ble);
    for (final r in radios) {
      expect(r.connector.currentFreqHz, BenchConfig.targetFreqKhz,
          reason: '${r.label} is NOT on the bench frequency — refusing to '
              'transmit test traffic');
    }

    if (BenchConfig.radiosAreDedicated) {
      for (final r in radios) {
        await wipeNonPublicChannels(r);
      }
    }
    for (final r in radios) {
      await awaitSyncIdle(r);
      snapshotProtectedSlots(r, {idKeyRx});
      await ensureChannel(r, '#mc1rx', pskRx);
    }

    benchReady = true;
    blog('bench ready');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('X1 channel reaction: MC1 on the wire, chip on both radios',
      (tester) async {
    await beginScenario(tester, 'X1 channel reaction round-trip');
    requireBench();

    final text = tag('X1 react to me');
    blog('${usb.label} -> ${ble.label}: "$text"');
    await usb.connector
        .sendChannelMessage(liveByIdKey(usb.connector, idKeyRx)!, text);
    await awaitText(ble, idKeyRx, text);
    await Future<void>.delayed(BenchConfig.interSendGap);

    // React from the BLE radio, exactly as the channel screen does.
    final target = (await channelRow(ble, text))!;
    final wire = MeshCoreConnector.channelReactionText(target, '😂');
    blog('reaction wire text: ${wire.replaceAll('\n', '\\n')}');

    // The format itself, on the air, is the point of the change.
    final parsed = ReactionHelper.parseIncomingReaction(wire);
    expect(parsed, isNotNull, reason: 'our own send does not parse');
    expect(parsed!.format, ReactionFormat.one,
        reason: 'still emitting the legacy r: dialect');
    expect(parsed.targetSender, target.senderName);
    expect(wire.startsWith('😂@['), isTrue, reason: 'got "$wire"');

    final before = (await allTexts(ble)).length;
    await ble.connector
        .sendChannelMessage(liveByIdKey(ble.connector, idKeyRx)!, wire);

    // Reactor's own screen: chip on the target, and NO new message row.
    // Before the gate fix this stored the raw two-line text as a message.
    final mine = await awaitChip(ble, text, '😂');
    expect(mine, isNotNull,
        reason: '${ble.label}: own reaction never applied to its target');
    blog('${ble.label}: own chip 😂 by ${mine!.join(", ")}');
    expect(await allTexts(ble), hasLength(before),
        reason: '${ble.label}: the reaction became a VISIBLE MESSAGE — '
            'the outgoing gate is not format-aware');
    expect((await allTexts(ble)).any((t) => t.contains('\n')), isFalse,
        reason: '${ble.label}: raw reaction text stored as a message');

    // Recipient's screen: same chip, attributed to the reactor.
    final theirs = await awaitChip(usb, text, '😂');
    expect(theirs, isNotNull,
        reason: '${usb.label}: reaction never landed on its target');
    blog('${usb.label}: chip 😂 by ${theirs!.join(", ")}');
    expect(theirs, contains(ble.connector.selfName));
    expect((await allTexts(usb)).any((t) => t.contains(wire)), isFalse,
        reason: '${usb.label}: reaction shown as a message, not a chip');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('X2 DM reaction: chip both ways, reactor status goes terminal',
      (tester) async {
    await beginScenario(tester, 'X2 DM reaction + send status');
    requireBench();

    blog('flooding self-adverts so the radios learn each other');
    await usb.connector.sendSelfAdvert(flood: true);
    await Future<void>.delayed(const Duration(seconds: 4));
    await ble.connector.sendSelfAdvert(flood: true);
    final usbOnBle = await ensureSavedContact(
        ble, usb.connector.selfPublicKeyHex, 'the USB radio');
    final bleOnUsb = await ensureSavedContact(
        usb, ble.connector.selfPublicKeyHex, 'the BLE radio');

    final dm = tag('X2 dm to react to');
    await usb.connector.sendMessage(bleOnUsb, dm);
    expect(await dmArrived(ble, usbOnBle, dm), isTrue,
        reason: 'the DM under test never arrived');
    await Future<void>.delayed(BenchConfig.interSendGap);

    Future<Message?> dmRow(BenchRadio r, Contact c, {required bool outgoing}) async {
      for (final m in await r.connector.loadMessagesFor(c)) {
        if (m.text == dm && m.isOutgoing == outgoing) return m;
      }
      return null;
    }

    final target = (await dmRow(ble, usbOnBle, outgoing: false))!;
    final wire = MeshCoreConnector.contactReactionText(target, '🔥');
    blog('DM reaction wire text: ${wire.replaceAll('\n', '\\n')}');
    // The DM dialect names no sender — the hash alone identifies the target.
    expect(wire.startsWith('🔥\n'), isTrue, reason: 'got "$wire"');
    expect(ReactionHelper.parseIncomingReaction(wire)!.targetSender, isNull);

    await ble.connector.sendMessage(usbOnBle, wire);

    // Reactor's own chip, and — the actual A.3 bug — its SEND STATUS. It
    // used to sit at "pending" forever: _setReactionStatus re-derived the
    // 4-hex legacy hash and could never match an 8-char Crockford one, so
    // a failed reaction was indistinguishable from one still in flight.
    MessageStatus? chipStatus;
    List<String>? mine;
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      final row = await dmRow(ble, usbOnBle, outgoing: false);
      if (row != null && (row.reactions['🔥'] ?? 0) > 0) {
        mine ??= row.reactionSenders['🔥'] ?? const [];
        chipStatus = row.reactionStatuses['🔥'];
        if (chipStatus == MessageStatus.delivered ||
            chipStatus == MessageStatus.failed) {
          break;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(mine, isNotNull,
        reason: '${ble.label}: own DM reaction never applied');
    blog('${ble.label}: own chip 🔥 by ${mine!.join(", ")}, '
        'send status = ${chipStatus?.name}');
    // One tap is one reactor. The retry service files every send it tracks,
    // so our own reaction comes back through the ingest path; if that path
    // re-applies it, _resolveReactorName attributes the second copy to the
    // CONTACT and the chip reads "2".
    expect(mine, hasLength(1),
        reason: '${ble.label}: own reaction counted more than once — '
            'attributed to ${mine.join(", ")}');
    expect(mine.single, ble.connector.selfName);
    final ownRow = await dmRow(ble, usbOnBle, outgoing: false);
    expect(ownRow!.reactions['🔥'], 1,
        reason: '${ble.label}: one tap produced a count of '
            '${ownRow.reactions['🔥']}');
    expect(chipStatus, isNotNull,
        reason: '${ble.label}: reaction chip has NO send status — '
            '_setReactionStatus never found the target row');
    expect(chipStatus, isNot(MessageStatus.pending),
        reason: '${ble.label}: reaction chip stuck at "pending" — this is '
            'the stuck-chip bug the shared matcher was meant to fix');
    expect(chipStatus, MessageStatus.delivered,
        reason: '${ble.label}: reaction send did not settle as delivered');

    // Recipient side: the chip lands on its own outgoing DM row.
    List<String>? theirs;
    final d2 = DateTime.now().add(const Duration(seconds: 75));
    while (DateTime.now().isBefore(d2)) {
      final row = await dmRow(usb, bleOnUsb, outgoing: true);
      if (row != null && (row.reactions['🔥'] ?? 0) > 0) {
        theirs = row.reactionSenders['🔥'] ?? const [];
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(theirs, isNotNull,
        reason: '${usb.label}: DM reaction never landed on its target — if '
            'the chip appeared on the reactor but not here, the wire-second '
            'candidate window did not cover the send skew');
    blog('${usb.label}: chip 🔥 by ${theirs!.join(", ")}');

    // Neither radio may show the reaction as a message.
    for (final r in radios) {
      final c = r == usb ? bleOnUsb : usbOnBle;
      final shown =
          (await r.connector.loadMessagesFor(c)).any((m) => m.text == wire);
      expect(shown, isFalse,
          reason: '${r.label}: DM reaction stored as a visible message');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('X3 orphan reaction parks, then resolves when its target lands',
      (tester) async {
    await beginScenario(tester, 'X3 parked orphan resolution');
    requireBench();

    // A reaction for a message the BLE radio has never seen. Sending it
    // FIRST is the real-world case: the reaction beat its target out of a
    // repeater's backlog queue.
    final futureText = tag('X3 the target, arriving late');
    final futureSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hash =
        ReactionHelper.computeMeshCoreOneHash(futureText, futureSecs);
    final wire = ReactionHelper.encodeMeshCoreOne('🎉', hash,
        targetSender: usb.connector.selfName ?? 'Me');
    blog('sending a reaction for a message nobody has yet: '
        '${wire.replaceAll('\n', '\\n')}');

    await usb.connector
        .sendChannelMessage(liveByIdKey(usb.connector, idKeyRx)!, wire);

    // It must be STORED (parked), not dropped — the UI draws it as a
    // compact stub, never the raw hash.
    final parked = await pollForAsync(
      () async => (await allTexts(ble)).contains(wire),
      const Duration(seconds: 75),
    );
    expect(parked, isTrue,
        reason: '${ble.label}: the unresolvable reaction was dropped — it '
            'must park so it can resolve when its target arrives');
    final stub = (await channelRow(ble, wire))!;
    expect(ReactionHelper.parseMeshCoreOneReaction(stub.text), isNotNull,
        reason: 'the parked row must re-parse — that is what drives the '
            'stub rendering');
    expect(stub.isOutgoing, isFalse);
    blog('${ble.label}: parked as an orphan stub 🎉');
    await Future<void>.delayed(BenchConfig.interSendGap);

    // Now the target finally arrives, carrying the very timestamp the
    // reaction was hashed over (what a backlog drain or repeat delivers).
    blog('${usb.label}: sending the target with wire stamp $futureSecs');
    await usb.connector.sendFrame(
      buildSendChannelTextMsgFrame(
        liveByIdKey(usb.connector, idKeyRx)!.index,
        usb.connector.prepareChannelOutboundText(
          liveByIdKey(usb.connector, idKeyRx)!.index,
          futureText,
        ),
        timestampSecs: futureSecs,
      ),
    );

    // The reaction should land on it, and the stub should disappear.
    final landed = await awaitChip(ble, futureText, '🎉');
    expect(landed, isNotNull,
        reason: '${ble.label}: the parked reaction did NOT resolve when its '
            'target arrived — orphan re-match on ingest is broken');
    blog('${ble.label}: orphan resolved onto its target, by '
        '${landed!.join(", ")}');
    expect(landed, contains(usb.connector.selfName));

    final gone = await pollForAsync(
      () async => !(await allTexts(ble)).contains(wire),
      const Duration(seconds: 20),
    );
    expect(gone, isTrue,
        reason: '${ble.label}: the stub row survived after resolving — the '
            'chat now shows both a chip and an orphan for one reaction');
    blog('${ble.label}: stub row deleted — chip only');
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('X4 cleanup: harness channel removed, radios stay on 920.000',
      (tester) async {
    await beginScenario(tester, 'X4 cleanup');
    requireBench();
    for (final r in radios) {
      await removeChannelIfPresent(r, idKeyRx);
      await verifyUserChannelsIntact(r);
      expect(r.connector.currentFreqHz, BenchConfig.targetFreqKhz,
          reason: '${r.label}: frequency drifted during the run');
    }
    blog('cleanup done — both radios remain on 920.000 MHz');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
