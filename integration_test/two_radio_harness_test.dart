import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Two-radio hardware-in-the-loop suite for the channel core.
///
/// Drives two REAL MeshCore companions — one over USB serial (COM14), one
/// over BLE via a localhost NUS bridge — with two stock MeshCoreConnector
/// instances, on the 920.000 MHz bench frequency. Every scenario ends with a
/// contamination sweep: a harness message may exist ONLY under the channel
/// identity (PSK) it was sent to, on both radios.
///
/// Run with:
///   flutter test integration_test/two_radio_harness_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Render every scheduled frame so the on-screen bench console stays live
  // during real-async waits (default policy only renders explicit pumps).
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final runTag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  String tag(String s) => 'hx[$runTag] $s';

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final radios = [usb, ble];
  final bridge = BleNusTcpBridge();
  final ledger = MessageLedger();
  var benchReady = false;

  void requireBench() {
    if (!benchReady) {
      fail('Bench not ready — see S0 failure above.');
    }
  }

  // Harness channel identities. Hashtag channels derive their PSK from the
  // name; the private channel uses a fixed key ("MTRX C-priv-0001" in hex).
  final psk1 = Channel.derivePskFromHashtag('#hx1');
  final psk2 = Channel.derivePskFromHashtag('#hx2');
  final psk3 = Channel.derivePskFromHashtag('#hx3');
  final psk4 = Channel.derivePskFromHashtag('#hx4');
  final pskPriv = Channel.parsePskHex('4d54525820432d707269762d30303031');
  // Engineered on-air hash collision: this hashtag's PSK shares its 1-byte
  // channel hash with #hx1's by construction.
  final collisionName = mineCollidingHashtag('#hx1');
  final pskCol = Channel.derivePskFromHashtag(collisionName);
  final idKey1 = Channel.formatPskHex(psk1);
  final idKey2 = Channel.formatPskHex(psk2);
  final idKey3 = Channel.formatPskHex(psk3);
  final idKey4 = Channel.formatPskHex(psk4);
  // Same-name trap: two channels both NAMED '#twin' with different keys
  // ("twin-custom-bnch" in hex for the second), plus a channel only the USB
  // radio subscribes to, for node-scope isolation proofs.
  final pskTwin = Channel.derivePskFromHashtag('#twin');
  final pskTwinCustom =
      Channel.parsePskHex('7477696e2d637573746f6d2d626e6368');
  final pskSolo = Channel.derivePskFromHashtag('#hxsolo');
  final idKeyPriv = Channel.formatPskHex(pskPriv);
  final idKeyCol = Channel.formatPskHex(pskCol);
  final idKeyTwin = Channel.formatPskHex(pskTwin);
  final idKeyTwinCustom = Channel.formatPskHex(pskTwinCustom);
  final idKeySolo = Channel.formatPskHex(pskSolo);
  final harnessIdKeys = [
    idKey1,
    idKey2,
    idKey3,
    idKey4,
    idKeyPriv,
    idKeyCol,
    idKeyTwin,
    idKeyTwinCustom,
    idKeySolo,
  ];
  final harnessIdKeySet = harnessIdKeys.toSet();

  Future<void> exchange(
    BenchRadio from,
    BenchRadio to,
    String idKey,
    String text,
  ) async {
    ledger.expectText(idKey, text);
    final ch = liveByIdKey(from.connector, idKey);
    expect(ch, isNotNull,
        reason: '${from.label}: channel $idKey not live before send');
    expect(from.connector.channelsVerified, isTrue,
        reason: '${from.label}: channel map not verified before send');
    blog('${from.label} -> ${to.label}: "$text"');
    await from.connector.sendChannelMessage(ch!, text);
    await awaitText(to, idKey, text);
    await awaitSendSettled(from, idKey, text);
    await contaminationSweep(radios, ledger);
    await Future<void>.delayed(BenchConfig.interSendGap);
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

  testWidgets('S0 bench comes up: both radios connected on 920.000 MHz',
      (tester) async {
    await beginScenario(tester, 'S0 bench bring-up');
    blog('two-radio bench, run tag: $runTag');
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

    blog('USB radio:  ${usb.connector.selfName} '
        '(${usb.connector.selfPublicKeyHex.substring(0, 12)}…)');
    blog('BLE radio:  ${ble.connector.selfName} '
        '(${ble.connector.selfPublicKeyHex.substring(0, 12)}…)');
    expect(
      usb.connector.selfPublicKeyHex,
      isNot(equals(ble.connector.selfPublicKeyHex)),
      reason: 'Both transports reached the SAME radio — check the bench.',
    );

    await alignFrequency(usb);
    await alignFrequency(ble);

    expect(usb.connector.currentSf, equals(ble.connector.currentSf),
        reason: 'Spreading factors differ — radios cannot hear each other.');
    expect(usb.connector.currentBwHz, equals(ble.connector.currentBwHz),
        reason: 'Bandwidths differ — radios cannot hear each other.');

    // Dedicated radios: start from a clean slot table every run.
    if (BenchConfig.radiosAreDedicated) {
      for (final r in radios) {
        await wipeNonPublicChannels(r);
      }
    }

    // Everything still on the radios is off-limits from here on.
    for (final r in radios) {
      await awaitSyncIdle(r);
      snapshotProtectedSlots(r, harnessIdKeySet);
    }

    benchReady = true;
    blog('bench ready');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('S1 harness channels provision identically on both radios',
      (tester) async {
    await beginScenario(tester, 'S1 provision channels');
    requireBench();
    blog('collision pair: #hx1 + $collisionName share on-air hash '
        '0x${channelHashByte(psk1).toRadixString(16).padLeft(2, '0')}');
    for (final r in radios) {
      await ensureChannel(r, '#hx1', psk1);
      await ensureChannel(r, '#hx2', psk2);
      await ensureChannel(r, 'HXPRIV', pskPriv);
      await ensureChannel(r, collisionName, pskCol);
      expect(fatalHealthWarnings(r.connector), isEmpty,
          reason: '${r.label}: twin-slot warning after provisioning');
    }
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('R1 repeater echo probe (F857)', (tester) async {
    await beginScenario(tester, 'R1 repeater echo probe');
    requireBench();
    final text = tag('R1 repeater probe');
    ledger.expectText(idKey1, text);
    final ch = liveByIdKey(usb.connector, idKey1);
    expect(ch, isNotNull);
    blog('probing: does F857 echo a #hx1 message?');
    await usb.connector.sendChannelMessage(ch!, text);
    await awaitText(ble, idKey1, text);
    await reportRepeaterEcho(usb, idKey1, text);
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('S2 bidirectional messages land only in their own channel',
      (tester) async {
    await beginScenario(tester, 'S2 bidirectional exchange');
    requireBench();
    await exchange(usb, ble, idKey1, tag('S2 usb->ble #hx1'));
    await exchange(ble, usb, idKey1, tag('S2 ble->usb #hx1'));
    await exchange(usb, ble, idKey2, tag('S2 usb->ble #hx2'));
    await exchange(ble, usb, idKeyPriv, tag('S2 ble->usb priv'));
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('S2b engineered hash-collision pair never cross-files',
      (tester) async {
    await beginScenario(tester, 'S2b engineered hash collision');
    requireBench();
    // Both channels answer to the same 1-byte on-air hash; the 2-byte MAC
    // must pick the right one every time — the #test deafness bug class.
    await exchange(usb, ble, idKeyCol, tag('S2b usb->ble $collisionName'));
    await exchange(ble, usb, idKey1, tag('S2b ble->usb #hx1'));
    await exchange(ble, usb, idKeyCol, tag('S2b ble->usb $collisionName'));
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('S2c interleaved burst: arrivals file correctly, losses honest',
      (tester) async {
    await beginScenario(tester, 'S2c interleaved burst');
    requireBench();
    final pending =
        <({BenchRadio from, BenchRadio to, String idKey, String text})>[];
    for (var i = 0; i < 4; i++) {
      final t1 = tag('S2c#$i usb->ble #hx1');
      ledger.expectText(idKey1, t1);
      await usb.connector
          .sendChannelMessage(liveByIdKey(usb.connector, idKey1)!, t1);
      pending.add((from: usb, to: ble, idKey: idKey1, text: t1));

      final t2 = tag('S2c#$i ble->usb #hx2');
      ledger.expectText(idKey2, t2);
      await ble.connector
          .sendChannelMessage(liveByIdKey(ble.connector, idKey2)!, t2);
      pending.add((from: ble, to: usb, idKey: idKey2, text: t2));

      await Future<void>.delayed(const Duration(milliseconds: 2500));
    }
    // Contending senders plus a repeater echoing at desk range WILL collide
    // sometimes. Losses must be HONEST (never misfiled, never duplicated);
    // systemic failure is a delivery rate below 75%.
    var arrived = 0;
    for (final p in pending) {
      if (await textArrived(p.to, p.idKey, p.text,
          timeout: const Duration(seconds: 75))) {
        arrived++;
      } else {
        final m = findOutgoing(p.from, p.idKey, p.text);
        blog('AIR LOSS: "${p.text}" never reached ${p.to.label} '
            '(sender status: ${m?.status.name ?? 'unknown'})');
      }
    }
    blog('burst delivery: $arrived/${pending.length}');
    expect(arrived, greaterThanOrEqualTo((pending.length * 3) ~/ 4),
        reason: 'burst delivery below 75% — systemic delivery problem');
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 14)));

  testWidgets('D1 payload torture: unicode and max-length arrive intact',
      (tester) async {
    await beginScenario(tester, 'D1 payload torture');
    requireBench();
    final unicode = tag('D1 🚀🐋💥 ¡Ünïcödé! 日本語 한국어 עברית ✓');
    await exchange(usb, ble, idKey1, unicode);

    final limit = maxChannelMessageBytes(ble.connector.selfName);
    final stem = tag('D1 max ');
    final room = limit - utf8.encode(stem).length;
    expect(room, greaterThan(0), reason: 'run tag left no room to pad');
    final maxText = stem + 'x' * room;
    expect(utf8.encode(maxText).length, equals(limit));
    blog('sending max-length channel message: $limit bytes');
    await exchange(ble, usb, idKey2, maxText);
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('D6 Public channel files by identity like any other',
      (tester) async {
    await beginScenario(tester, 'D6 Public channel');
    requireBench();
    const idKeyPub = Channel.publicChannelPsk;
    expect(liveByIdKey(usb.connector, idKeyPub), isNotNull,
        reason: 'Public channel missing on ${usb.label}');
    expect(liveByIdKey(ble.connector, idKeyPub), isNotNull,
        reason: 'Public channel missing on ${ble.label}');
    await exchange(usb, ble, idKeyPub, tag('D6 usb->ble public'));
    await exchange(ble, usb, idKeyPub, tag('D6 ble->usb public'));
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('S3 deleted slot reused by a new channel files correctly',
      (tester) async {
    await beginScenario(tester, 'S3 slot reuse by new identity');
    requireBench();
    await awaitSyncIdle(ble);
    // The original field bug: slot index reused by a different identity.
    final oldSlot = liveByIdKey(ble.connector, idKey1)!.index;
    await removeChannelIfPresent(ble, idKey1);
    await ensureChannel(ble, '#hx3', psk3, atSlot: oldSlot);
    await ensureChannel(usb, '#hx3', psk3);

    await exchange(usb, ble, idKey3, tag('S3 slot-reuse #hx3'));

    expect(liveByIdKey(ble.connector, idKey1), isNull,
        reason: '${ble.label}: deleted #hx1 resurrected');
    expect(fatalHealthWarnings(ble.connector), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('S4 queued messages drain into the right identity after remap',
      (tester) async {
    await beginScenario(tester, 'S4 offline queue drain after slot remap');
    requireBench();
    // While the app is away: #hx2 moves to a new slot and a decoy channel
    // takes its old slot. Queued traffic must follow the identity, not the
    // slot number — this is the exact cross-contamination scenario from the
    // field reports.
    await awaitSyncIdle(ble);
    final hx2OldSlot = liveByIdKey(ble.connector, idKey2)!.index;
    await removeChannelIfPresent(ble, idKey2);
    final newSlot = freeSlot(ble, avoid: {hx2OldSlot});
    await ensureChannel(ble, '#hx2', psk2, atSlot: newSlot);
    await ensureChannel(ble, '#hx4', psk4, atSlot: hx2OldSlot);

    blog('${ble.label}: app going offline (radio keeps listening)');
    await ble.connector.disconnect();
    await Future<void>.delayed(const Duration(seconds: 2));

    final queued1 = tag('S4 queued #hx2');
    final queued2 = tag('S4 queued priv');
    ledger.expectText(idKey2, queued1);
    ledger.expectText(idKeyPriv, queued2);

    final chHx2 = liveByIdKey(usb.connector, idKey2)!;
    await usb.connector.sendChannelMessage(chHx2, queued1);
    await Future<void>.delayed(BenchConfig.interSendGap);
    final chPriv = liveByIdKey(usb.connector, idKeyPriv)!;
    await usb.connector.sendChannelMessage(chPriv, queued2);
    blog('letting the air settle while ${ble.label} is offline…');
    await Future<void>.delayed(const Duration(seconds: 10));

    blog('${ble.label}: reconnecting — channels must sync before the '
        'queue drains');
    await ble.reconnect();

    await awaitText(ble, idKey2, queued1);
    await awaitText(ble, idKeyPriv, queued2);
    await contaminationSweep(radios, ledger);

    final decoy = liveByIdKey(ble.connector, idKey4)!;
    final decoyTexts = ble.connector
        .getChannelMessages(decoy)
        .map((m) => m.text)
        .where(ledger.allTexts.contains);
    expect(decoyTexts, isEmpty,
        reason: '${ble.label}: queued traffic leaked into the decoy channel '
            'occupying #hx2\'s old slot');
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('D5 slot shuffle: filing follows identity, deletes purge',
      (tester) async {
    await beginScenario(tester, 'D5 three-channel slot shuffle');
    requireBench();
    // Earlier scenarios may have deleted these on either radio (S3 removes
    // #hx1 from the BLE radio) — every scenario provisions its own needs.
    for (final r in radios) {
      await ensureChannel(r, '#hx1', psk1);
      await ensureChannel(r, '#hx2', psk2);
      await ensureChannel(r, 'HXPRIV', pskPriv);
    }
    // Phase 1: give each identity fresh history on the BLE radio.
    final phase1 = <String, String>{
      idKey1: tag('D5p1 #hx1'),
      idKey2: tag('D5p1 #hx2'),
      idKeyPriv: tag('D5p1 priv'),
    };
    for (final e in phase1.entries) {
      ledger.expectText(e.key, e.value);
      await usb.connector
          .sendChannelMessage(liveByIdKey(usb.connector, e.key)!, e.value);
      await Future<void>.delayed(BenchConfig.interSendGap);
    }
    for (final e in phase1.entries) {
      await awaitText(ble, e.key, e.value);
    }

    // Permute the three identities across their slots on the BLE radio.
    final names = {idKey1: '#hx1', idKey2: '#hx2', idKeyPriv: 'HXPRIV'};
    final psks = {idKey1: psk1, idKey2: psk2, idKeyPriv: pskPriv};
    final order = phase1.keys.toList();
    final slotOf = {
      for (final k in order) k: liveByIdKey(ble.connector, k)!.index,
    };
    blog('shuffling: ${order.map((k) => '${names[k]}@${slotOf[k]}').join(' ')}');
    for (final k in order) {
      await removeChannelIfPresent(ble, k);
    }
    for (var i = 0; i < order.length; i++) {
      final k = order[i];
      final newSlot = slotOf[order[(i + 1) % order.length]]!;
      await ensureChannel(ble, names[k]!, psks[k]!, atSlot: newSlot);
    }

    // Deleting a channel purges its history BY DESIGN — re-added identities
    // must come back empty, not resurrect phase-1 texts (the field bug where
    // old snapshots reappeared).
    for (final e in phase1.entries) {
      final ch = liveByIdKey(ble.connector, e.key)!;
      final resurrected = ble.connector
          .getChannelMessages(ch)
          .any((m) => m.text == e.value);
      expect(resurrected, isFalse,
          reason: '${ble.label}: deleted history resurrected in '
              '${ch.displayName}');
      await assertDbTextsGone(ble, e.key, [e.value]);
    }

    // Phase 2: traffic must file correctly at the permuted slots.
    for (final k in order) {
      final t = tag('D5p2 ${names[k]}');
      ledger.expectText(k, t);
      await usb.connector
          .sendChannelMessage(liveByIdKey(usb.connector, k)!, t);
      await Future<void>.delayed(BenchConfig.interSendGap);
      await awaitText(ble, k, t);
    }
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('D3 reconnect storm: every gap message drains exactly once',
      (tester) async {
    await beginScenario(tester, 'D3 reconnect storm');
    requireBench();
    for (final r in radios) {
      await ensureChannel(r, '#hx1', psk1);
      await ensureChannel(r, '#hx2', psk2);
    }
    for (var cycle = 0; cycle < 3; cycle++) {
      final t = tag('D3 ble-gap#$cycle');
      ledger.expectText(idKey1, t);
      await ble.connector.disconnect();
      await Future<void>.delayed(const Duration(seconds: 2));
      await usb.connector
          .sendChannelMessage(liveByIdKey(usb.connector, idKey1)!, t);
      await Future<void>.delayed(const Duration(seconds: 6));
      await ble.reconnect();
      await awaitText(ble, idKey1, t);
      await contaminationSweep(radios, ledger);
    }
    for (var cycle = 0; cycle < 3; cycle++) {
      final t = tag('D3 usb-gap#$cycle');
      ledger.expectText(idKey2, t);
      await usb.connector.disconnect();
      await Future<void>.delayed(const Duration(seconds: 2));
      await ble.connector
          .sendChannelMessage(liveByIdKey(ble.connector, idKey2)!, t);
      await Future<void>.delayed(const Duration(seconds: 6));
      await usb.reconnect();
      await awaitText(usb, idKey2, t);
      await contaminationSweep(radios, ledger);
    }
  }, timeout: const Timeout(Duration(minutes: 14)));

  testWidgets('D4 dual-offline crossfire: parallel reconnect drains cleanly',
      (tester) async {
    await beginScenario(tester, 'D4 dual-offline crossfire');
    requireBench();
    for (final r in radios) {
      await ensureChannel(r, '#hx1', psk1);
      await ensureChannel(r, 'HXPRIV', pskPriv);
    }
    final m1 = tag('D4 queued #hx1');
    final m2 = tag('D4 queued priv');
    ledger.expectText(idKey1, m1);
    ledger.expectText(idKeyPriv, m2);
    await ble.connector.disconnect();
    await Future<void>.delayed(const Duration(seconds: 2));
    await usb.connector
        .sendChannelMessage(liveByIdKey(usb.connector, idKey1)!, m1);
    await Future<void>.delayed(BenchConfig.interSendGap);
    await usb.connector
        .sendChannelMessage(liveByIdKey(usb.connector, idKeyPriv)!, m2);
    await Future<void>.delayed(const Duration(seconds: 8));
    await usb.connector.disconnect();
    await Future<void>.delayed(const Duration(seconds: 3));
    blog('both apps offline — reconnecting in parallel');
    await Future.wait([usb.reconnect(), ble.reconnect()]);
    await awaitText(ble, idKey1, m1);
    await awaitText(ble, idKeyPriv, m2);
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('D7 same-name channels: the key decides, never the name',
      (tester) async {
    await beginScenario(tester, 'D7 same-name trap');
    requireBench();
    // BLE radio carries TWO channels both named '#twin', different keys;
    // the USB radio has only the derived-key one.
    await ensureChannel(ble, '#twin', pskTwin);
    await ensureChannel(ble, '#twin', pskTwinCustom);
    await ensureChannel(usb, '#twin', pskTwin);

    await exchange(usb, ble, idKeyTwin, tag('D7 into derived twin'));

    // Traffic on the custom '#twin' must never surface on the USB radio —
    // it does not hold that key. Same name means nothing.
    final t2 = tag('D7 custom twin (usb must never see this)');
    ledger.expectText(idKeyTwinCustom, t2);
    await ble.connector
        .sendChannelMessage(liveByIdKey(ble.connector, idKeyTwinCustom)!, t2);
    await Future<void>.delayed(const Duration(seconds: 15));
    assertTextAbsentEverywhere(usb, t2);
    await assertDbEmptyFor(
        usb, idKeyTwinCustom, 'radio is not subscribed to this key');
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('D8a volume soak: 16 alternating messages, ordered, deduped',
      (tester) async {
    await beginScenario(tester, 'D8a volume soak');
    requireBench();
    for (final r in radios) {
      await ensureChannel(r, 'HXPRIV', pskPriv);
    }
    // Node-scope isolation seed: a channel only the USB radio subscribes to.
    await ensureChannel(usb, '#hxsolo', pskSolo);
    final soloText = tag('D8 solo (only usb has this channel)');
    ledger.expectText(idKeySolo, soloText);
    await usb.connector
        .sendChannelMessage(liveByIdKey(usb.connector, idKeySolo)!, soloText);

    final sent = <({BenchRadio from, BenchRadio to, int seq, String text})>[];
    for (var i = 0; i < 16; i++) {
      final from = i.isEven ? usb : ble;
      final to = i.isEven ? ble : usb;
      final t = tag('D8#${i.toString().padLeft(2, '0')} priv');
      ledger.expectText(idKeyPriv, t);
      await from.connector
          .sendChannelMessage(liveByIdKey(from.connector, idKeyPriv)!, t);
      sent.add((from: from, to: to, seq: i, text: t));
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    var arrived = 0;
    for (final s in sent) {
      if (await textArrived(s.to, idKeyPriv, s.text,
          timeout: const Duration(seconds: 75))) {
        arrived++;
      } else {
        final m = findOutgoing(s.from, idKeyPriv, s.text);
        blog('AIR LOSS: D8#${s.seq} never reached ${s.to.label} '
            '(sender status: ${m?.status.name ?? 'unknown'})');
      }
    }
    blog('volume soak delivery: $arrived/${sent.length}');
    expect(arrived, greaterThanOrEqualTo(13),
        reason: 'volume delivery below floor — systemic problem');

    // Arrival order preserved: the seq numbers visible on each radio must
    // be monotonically increasing in list order (3s spacing dwarfs the two
    // radios' clock skew after time sync).
    final seqPattern = RegExp(r'D8#(\d\d) priv$');
    for (final r in radios) {
      final ch = liveByIdKey(r.connector, idKeyPriv)!;
      final seqs = <int>[];
      for (final m in r.connector.getChannelMessages(ch)) {
        final match = seqPattern.firstMatch(m.text);
        if (match != null && m.text.startsWith('hx[$runTag]')) {
          seqs.add(int.parse(match.group(1)!));
        }
      }
      final sorted = [...seqs]..sort();
      expect(seqs, equals(sorted),
          reason: '${r.label}: D8 messages out of order: $seqs');
    }
    assertTextAbsentEverywhere(ble, soloText);
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 15)));

  testWidgets('C1 contacts: adverts flow, DMs deliver and stay out of channels',
      (tester) async {
    await beginScenario(tester, 'C1 contact DMs');
    requireBench();
    blog('flooding self-adverts so the radios learn each other');
    await usb.connector.sendSelfAdvert(flood: true);
    await Future<void>.delayed(const Duration(seconds: 4));
    await ble.connector.sendSelfAdvert(flood: true);

    final usbOnBle = await ensureSavedContact(
        ble, usb.connector.selfPublicKeyHex, 'the USB radio');
    final bleOnUsb = await ensureSavedContact(
        usb, ble.connector.selfPublicKeyHex, 'the BLE radio');

    final d1 = tag('C1 dm usb->ble');
    await usb.connector.sendMessage(bleOnUsb, d1);
    expect(await dmArrived(ble, usbOnBle, d1), isTrue,
        reason: 'DM usb->ble never arrived');
    final st1 = await awaitDmStatus(usb, bleOnUsb, d1);
    blog('usb->ble DM status: ${st1?.name} (DMs carry real ACKs)');
    expect(st1, isNot(MessageStatus.failed));

    final d2 = tag('C1 dm ble->usb');
    await ble.connector.sendMessage(usbOnBle, d2);
    expect(await dmArrived(usb, bleOnUsb, d2), isTrue,
        reason: 'DM ble->usb never arrived');
    final st2 = await awaitDmStatus(ble, usbOnBle, d2);
    blog('ble->usb DM status: ${st2?.name}');
    expect(st2, isNot(MessageStatus.failed));

    // DMs must never bleed into channel buckets on either radio.
    for (final r in radios) {
      assertTextAbsentEverywhere(r, d1);
      assertTextAbsentEverywhere(r, d2);
    }
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('C2 offline DM queues and drains exactly once', (tester) async {
    await beginScenario(tester, 'C2 offline DM');
    requireBench();
    final usbOnBle = findContactByHex(
        ble.connector, usb.connector.selfPublicKeyHex,
        savedOnly: true);
    final bleOnUsb = findContactByHex(
        usb.connector, ble.connector.selfPublicKeyHex,
        savedOnly: true);
    expect(usbOnBle, isNotNull, reason: 'C1 must run first');
    expect(bleOnUsb, isNotNull, reason: 'C1 must run first');

    await ble.connector.disconnect();
    await Future<void>.delayed(const Duration(seconds: 2));
    final t = tag('C2 dm queued');
    await usb.connector.sendMessage(bleOnUsb!, t);
    await Future<void>.delayed(const Duration(seconds: 10));
    await ble.reconnect();

    expect(await dmArrived(ble, usbOnBle!, t, timeout: const Duration(seconds: 60)),
        isTrue,
        reason: 'queued DM never drained after reconnect');
    final copies =
        ble.connector.getMessages(usbOnBle).where((m) => m.text == t).length;
    expect(copies, 1, reason: 'queued DM duplicated: $copies copies');
    assertTextAbsentEverywhere(ble, t);
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('R2 repeater: discovery, admin login, CLI round-trip',
      (tester) async {
    await beginScenario(tester, 'R2 repeater admin + CLI');
    requireBench();
    if (BenchConfig.repeaterPassword.isEmpty) {
      blog('R2 SKIPPED — run with '
          '--dart-define=BENCH_REPEATER_PASSWORD=… to enable');
      return;
    }

    // Find F857 on either radio: discovery from both, then a passive wait
    // for its periodic advert.
    (BenchRadio, Contact)? hit;
    (BenchRadio, Contact)? locate() {
      for (final r in radios) {
        final c = findContactByPrefix(
            r.connector, BenchConfig.repeaterPubKeyPrefix);
        if (c != null) return (r, c);
      }
      return null;
    }

    hit = locate();
    if (hit == null) {
      blog('repeater not known — discovery from ${usb.label}');
      await usb.connector.sendRepeaterDiscovery();
      if (!await pollFor(
          () => (hit = locate()) != null, const Duration(seconds: 45))) {
        blog('no reply — discovery from ${ble.label}');
        await ble.connector.sendRepeaterDiscovery();
        if (!await pollFor(
            () => (hit = locate()) != null, const Duration(seconds: 45))) {
          blog('still nothing — waiting for a periodic advert (90s)…');
          await pollFor(() => (hit = locate()) != null,
              const Duration(seconds: 90),
              poll: const Duration(seconds: 2));
        }
      }
    }
    if (hit == null) {
      final known = [
        for (final r in radios)
          '${r.label}: ${[
            ...r.connector.contacts,
            ...r.connector.discoveredContacts,
          ].map((c) => '${c.name}(${c.publicKeyHex.substring(0, 4)})').join(', ')}',
      ];
      fail('F857 never appeared via discovery or advert. Known contacts — '
          '${known.join(' | ')}. Does this repeater firmware answer '
          'discovery? Send "advert" from its CLI, or supply its full '
          'public key.');
    }
    final host = hit!.$1;
    blog('repeater contact: ${hit!.$2.name} '
        '(${hit!.$2.publicKeyHex.substring(0, 8)}…) via ${host.label}');
    if (findContactByPrefix(host.connector, BenchConfig.repeaterPubKeyPrefix,
            savedOnly: true) ==
        null) {
      await host.connector.importDiscoveredContact(hit!.$2);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    final rep = findContactByPrefix(
        host.connector, BenchConfig.repeaterPubKeyPrefix,
        savedOnly: true)!;

    var login = await repeaterLogin(host, rep, BenchConfig.repeaterPassword);
    if (login.$1 == null) {
      blog('login attempt timed out — retrying once');
      login = await repeaterLogin(host, rep, BenchConfig.repeaterPassword);
    }
    expect(login.$1, isTrue, reason: 'repeater login failed or timed out');
    blog('login ok, admin=${login.$2}');
    expect(login.$2, isTrue,
        reason: 'admin password did not yield an admin session');

    final ver = await repeaterCli(host, rep, 'ver');
    expect(ver, isNotNull, reason: 'no reply to CLI "ver"');
    blog('F857 ver: $ver');
    final clock = await repeaterCli(host, rep, 'clock');
    expect(clock, isNotNull, reason: 'no reply to CLI "clock"');
    blog('F857 clock: $clock');
    // Read-only CLI only: this repeater must stay configured on 920.000 MHz
    // for every future bench run.
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('S5 duplicate-PSK channel creation is refused', (tester) async {
    await beginScenario(tester, 'S5 duplicate-PSK guard');
    requireBench();
    await awaitSyncIdle(ble);
    final before = ble.connector.channels
        .map((c) => '${c.index}:${c.idKey}')
        .toSet();
    await ble.connector.setChannel(
      freeSlot(ble),
      '#hx2twin',
      psk2,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    final after = ble.connector.channels
        .map((c) => '${c.index}:${c.idKey}')
        .toSet();
    expect(after, equals(before),
        reason: '${ble.label}: duplicate-PSK setChannel changed the slot '
            'table — twin channel guard failed');
    expect(fatalHealthWarnings(ble.connector), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('S6 histories survive an app restart, keyed by identity',
      (tester) async {
    await beginScenario(tester, 'S6 restart persistence');
    requireBench();
    final snapUsb = snapshotHarnessTexts(usb, ledger);
    final snapBle = snapshotHarnessTexts(ble, ledger);
    expect(snapUsb.values.expand((t) => t), isNotEmpty,
        reason: 'restart test needs prior traffic');

    blog('simulating app restart: fresh connectors, same radios');
    for (final r in radios) {
      try {
        await r.connector.disconnect();
      } catch (_) {}
      r.connector.dispose();
    }
    usb.connector = await buildConnector();
    ble.connector = await buildConnector();
    await usb.reconnect();
    await ble.reconnect();

    expect(snapshotHarnessTexts(usb, ledger), equals(snapUsb),
        reason: '${usb.label}: channel histories changed across restart');
    expect(snapshotHarnessTexts(ble, ledger), equals(snapBle),
        reason: '${ble.label}: channel histories changed across restart');
    await contaminationSweep(radios, ledger);
  }, timeout: const Timeout(Duration(minutes: 8)));

  testWidgets('D8b database integrity audit: Drift rows are clean',
      (tester) async {
    await beginScenario(tester, 'D8b DB integrity audit');
    requireBench();
    // Row-level, post-restart (S6 rebuilt the connectors from the DB):
    // unique messageIds, correct identity per stored text, node scopes
    // distinct and isolated.
    expect(nodeScopeOf(usb), isNot(equals(nodeScopeOf(ble))),
        reason: 'both radios map to one node scope — isolation impossible');
    await assertDbIntegrity(
      radios,
      ledger,
      [...harnessIdKeys, Channel.publicChannelPsk],
    );
    await assertDbEmptyFor(
        ble, idKeySolo, 'never subscribed to #hxsolo');
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('S7 cleanup: harness channels removed, radios stay on bench',
      (tester) async {
    await beginScenario(tester, 'S7 cleanup');
    requireBench();
    for (final r in radios) {
      for (final idKey in harnessIdKeys) {
        await removeChannelIfPresent(r, idKey);
      }
      await waitUntil(
        () =>
            r.connector.channelsVerified &&
            harnessIdKeys.every((k) => liveByIdKey(r.connector, k) == null),
        '${r.label}: slot table settles after cleanup',
        timeout: const Duration(seconds: 60),
      );
      expect(fatalHealthWarnings(r.connector), isEmpty,
          reason: '${r.label}: twin-slot warning after cleanup');
      await verifyUserChannelsIntact(r);
      expect(r.connector.currentFreqHz, equals(BenchConfig.targetFreqKhz),
          reason: '${r.label}: frequency drifted during the run');
    }
    blog('cleanup done — radios remain on 920.000 MHz for the bench');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
