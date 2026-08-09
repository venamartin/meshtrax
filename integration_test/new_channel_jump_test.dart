import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// Hardware proof for "jump into a channel right after creating it".
///
/// The first attempt read `connector.channels` straight after `setChannel`
/// and found nothing, so the app never navigated. `setChannel` returns once
/// the slot resync is *requested*: slots arrive one CHANNEL_INFO at a time,
/// and `channels` serves the pre-sync cache until the pass completes. This
/// pins that timing down on a real radio.
///
/// Writes one channel into a free slot and deletes it again — the bench
/// radios are dedicated (BenchConfig.radiosAreDedicated) and pre-existing
/// slots are snapshotted and refused.
///
/// Run with:
///   flutter test integration_test/new_channel_jump_test.dart -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  var ready = false;

  const hashtag = 'jumptest';
  final psk = Channel.derivePskFromHashtag(hashtag);
  final idKey = Channel.formatPskHex(psk);

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  testWidgets('C0 USB companion up, channel map verified', (tester) async {
    await beginScenario(tester, 'C0 bring-up');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();

    // Everything already on the radio is off limits; the test only ever
    // touches a slot freeSlot() hands out.
    snapshotProtectedSlots(usb, {idKey});
    await removeChannelIfPresent(usb, idKey);

    blog('C0: ${usb.connector.channels.length} channels, '
        'test slot target = ${freeSlot(usb)}');
    ready = true;
  });

  // Whether the radio commits SET_CHANNEL before the resync pass reaches
  // that slot is a coin flip — observed both ways on this bench, and a pass
  // that loses reports the slot empty with nothing re-reading it. One
  // create/resolve is one sample, so take several.
  testWidgets('C1 awaitChannelByPsk resolves the channel setChannel just made',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'C1 create then resolve');

    for (var attempt = 1; attempt <= 4; attempt++) {
      await removeChannelIfPresent(usb, idKey);
      final slot = freeSlot(usb);
      final before = DateTime.now();
      await usb.connector.setChannel(slot, '#$hashtag', psk);

      // The bug, measured: this is what the screen read to decide whether
      // to navigate, and on a real radio it is still empty here.
      expect(
        liveByIdKey(usb.connector, idKey),
        isNull,
        reason: 'attempt $attempt: setChannel returned with the channel '
            'already listed — the resync outran the bug this test pins '
            'down; re-check whether the wait is still needed',
      );

      final resolved = await usb.connector.awaitChannelByPsk(psk);
      final waited = DateTime.now().difference(before);
      blog('C1 attempt $attempt: slot $slot resolved after '
          '${waited.inMilliseconds}ms -> ${resolved?.displayName}');

      expect(resolved, isNotNull,
          reason: 'attempt $attempt: the radio never reported the channel');
      expect(resolved!.idKey, idKey);
      expect(resolved.name, '#$hashtag');

      // The screen navigates with this object, so the slot has to be the
      // radio's answer and not the index we asked for. Read it back off a
      // settled map: the public channels getter serves the pre-sync cache
      // while a pass is in flight.
      await awaitSyncIdle(usb);
      final live = liveByIdKey(usb.connector, idKey);
      expect(live, isNotNull,
          reason: 'attempt $attempt: resolved channel is not on the '
              'settled map');
      expect(resolved.index, live!.index);
    }
  });

  testWidgets('C2 resolves immediately when the channel already exists',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'C2 already present');

    final start = DateTime.now();
    final resolved = await usb.connector.awaitChannelByPsk(psk);
    final waited = DateTime.now().difference(start);
    blog('C2: resolved in ${waited.inMilliseconds}ms');

    expect(resolved, isNotNull);
    expect(resolved!.idKey, idKey);
    expect(waited.inSeconds, lessThan(2));
  });

  testWidgets('C3 returns null for a channel the radio does not have',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'C3 unknown channel + cleanup');

    await removeChannelIfPresent(usb, idKey);
    expect(liveByIdKey(usb.connector, idKey), isNull,
        reason: 'cleanup: test channel left on the radio');

    // No navigation, and no hanging on the timeout either: the map is
    // verified and settled, so the answer is available at once.
    final start = DateTime.now();
    final resolved = await usb.connector.awaitChannelByPsk(psk);
    blog('C3: null after ${DateTime.now().difference(start).inMilliseconds}ms');
    expect(resolved, isNull);

    await verifyUserChannelsIntact(usb);
  });
}
