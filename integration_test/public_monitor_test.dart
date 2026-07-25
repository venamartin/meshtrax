import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Passive long-duration Public-channel monitor.
///
/// Tunes both bench radios to the REAL mesh frequency (910.525 MHz) and
/// NEVER TRANSMITS — it only listens to live mesh traffic and watches the
/// connector's Public channel the way an open UI would, through phone-like
/// disconnect/reconnect cycles, hunting the field-reported
/// disappear/reappear. No channels are created, deleted, or wiped.
///
/// Run (default 4 hours; MONITOR_HOURS overrides):
///   flutter test integration_test/public_monitor_test.dart -d windows \
///     --dart-define=MONITOR_HOURS=4
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const hoursDefine = String.fromEnvironment('MONITOR_HOURS');
  final hours = int.tryParse(hoursDefine) ?? 4;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final radios = [usb, ble];
  final bridge = BleNusTcpBridge();

  testWidgets('Public channel passive monitor', (tester) async {
    await beginScenario(tester, 'Public monitor: ${hours}h @ 910.525 MHz');
    blog('PASSIVE MODE — this test never transmits on the mesh');

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
    await bridge.start();
    await usb.reconnect();
    await ble.reconnect();

    // The monitor's ONLY radio write: join the mesh frequency to listen.
    await alignFrequency(usb, khz: BenchConfig.meshFreqKhz);
    await alignFrequency(ble, khz: BenchConfig.meshFreqKhz);

    const idKeyPub = Channel.publicChannelPsk;
    final handles = {
      for (final r in radios) r: liveByIdKey(r.connector, idKeyPub),
    };
    for (final r in radios) {
      expect(handles[r], isNotNull,
          reason: '${r.label}: no Public channel — cannot monitor');
    }

    final incidents = <String>[];
    final recoveries = <String>[];
    // Per radio: newest message key seen, last non-empty count, empty-streak
    // start, and whether Public was missing from the channels list.
    final newestKey = <BenchRadio, String?>{for (final r in radios) r: null};
    final lastCount = <BenchRadio, int>{for (final r in radios) r: 0};
    final emptySince = <BenchRadio, DateTime?>{for (final r in radios) r: null};
    final listMissingSince = <BenchRadio, DateTime?>{
      for (final r in radios) r: null,
    };
    var samples = 0;

    String now() => DateTime.now().toIso8601String().substring(11, 19);

    void incident(String what) {
      incidents.add('[${now()}] $what');
      blog('INCIDENT: $what');
    }

    Future<void> sampleRadio(BenchRadio r) async {
      final connected = r.connector.isConnected;
      final phase = connected
          ? (r.connector.isLoadingChannels ? 'syncing' : 'connected')
          : 'offline';

      // Channels-list presence (what the chats screen shows).
      final inList = r.connector.channels.any((c) => c.idKey == idKeyPub);
      if (!inList) {
        listMissingSince[r] ??= DateTime.now();
      } else if (listMissingSince[r] != null) {
        final gap = DateTime.now().difference(listMissingSince[r]!);
        incident('${r.label}: Public MISSING from channel list for '
            '${gap.inMilliseconds}ms (phase at recovery: $phase)');
        recoveries.add('${r.label}: list recovered after '
            '${gap.inMilliseconds}ms');
        listMissingSince[r] = null;
      }

      // Message view through a captured handle (what an open screen shows).
      final msgs = await r.connector.loadChannelMessagesFor(handles[r]!);
      if (msgs.isEmpty && lastCount[r]! > 0) {
        emptySince[r] ??= DateTime.now();
      } else if (msgs.isNotEmpty && emptySince[r] != null) {
        final gap = DateTime.now().difference(emptySince[r]!);
        incident('${r.label}: Public messages EMPTY for '
            '${gap.inMilliseconds}ms then reappeared '
            '(count now ${msgs.length}, phase: $phase)');
        emptySince[r] = null;
      }
      if (msgs.isNotEmpty) {
        // The newest known message may only vanish if something newer exists.
        final keys = {for (final m in msgs) m.messageId};
        final prevNewest = newestKey[r];
        if (prevNewest != null &&
            !keys.contains(prevNewest) &&
            msgs.last.timestamp.isBefore(DateTime.now()
                .subtract(const Duration(seconds: 2)))) {
          incident('${r.label}: newest message ($prevNewest) vanished '
              'without replacement (count ${lastCount[r]} -> '
              '${msgs.length}, phase: $phase)');
        }
        newestKey[r] = msgs.last.messageId;
        // Mass shrink without new arrivals = window trim would keep count
        // stable; a real drop is an incident.
        if (msgs.length < lastCount[r]! - 5) {
          incident('${r.label}: message count fell ${lastCount[r]} -> '
              '${msgs.length} (phase: $phase)');
        }
        lastCount[r] = msgs.length;
      }
    }

    final endAt = DateTime.now().add(Duration(hours: hours));
    var lastEpochLog = DateTime.now();
    var lastBleCycle = DateTime.now();
    var lastUsbCycle = DateTime.now();
    var cycles = 0;

    blog('monitoring until ${endAt.toIso8601String().substring(11, 16)} — '
        'BLE reconnect cycle every 15 min, USB every 45 min');

    while (DateTime.now().isBefore(endAt)) {
      samples++;
      for (final r in radios) {
        await sampleRadio(r);
      }

      if (DateTime.now().difference(lastEpochLog) >
          const Duration(minutes: 5)) {
        lastEpochLog = DateTime.now();
        blog('epoch: samples=$samples cycles=$cycles '
            'usb(msgs=${lastCount[usb]}, ${usb.connector.isConnected ? "up" : "down"}) '
            'ble(msgs=${lastCount[ble]}, ${ble.connector.isConnected ? "up" : "down"}) '
            'incidents=${incidents.length}');
      }

      // Phone-like connection churn — sampling continues throughout.
      if (DateTime.now().difference(lastBleCycle) >
          const Duration(minutes: 15)) {
        lastBleCycle = DateTime.now();
        cycles++;
        blog('cycle: ${ble.label} going offline for 60s');
        await ble.connector.disconnect();
        final resumeAt = DateTime.now().add(const Duration(seconds: 60));
        while (DateTime.now().isBefore(resumeAt)) {
          samples++;
          for (final r in radios) {
            await sampleRadio(r);
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        blog('cycle: ${ble.label} reconnecting');
        await ble.reconnect();
      }
      if (DateTime.now().difference(lastUsbCycle) >
          const Duration(minutes: 45)) {
        lastUsbCycle = DateTime.now();
        cycles++;
        blog('cycle: ${usb.label} going offline for 30s');
        await usb.connector.disconnect();
        final resumeAt = DateTime.now().add(const Duration(seconds: 30));
        while (DateTime.now().isBefore(resumeAt)) {
          samples++;
          for (final r in radios) {
            await sampleRadio(r);
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        blog('cycle: ${usb.label} reconnecting');
        await usb.reconnect();
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    blog('=== monitor complete: $samples samples, $cycles reconnect '
        'cycles, ${incidents.length} incident(s) ===');
    for (final i in incidents) {
      blog(i);
    }
    for (final r in recoveries) {
      blog(r);
    }
    blog('radios remain on 910.525 MHz (the mesh frequency)');

    expect(incidents, isEmpty,
        reason: 'Public display integrity violated ${incidents.length} '
            'time(s) over $hours hour(s) — details above');
  }, timeout: Timeout(Duration(hours: hours + 1)));

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
}
