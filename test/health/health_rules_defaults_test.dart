import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/health/health_rules.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The health check must not flag a new user for the app's own defaults. If
// one of these fails, change the default and the rule together.
class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];
  List<Channel> channelList = const [];

  @override
  List<Channel> get channels => channelList;

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }
}

/// A 1-byte radio: byte 81 is the path hash mode.
Uint8List _deviceInfo({String version = 'v1.18.0', int code = 14}) {
  final frame = Uint8List(82);
  frame[0] = respCodeDeviceInfo;
  frame[1] = code;
  frame.setRange(60, 60 + version.length, version.codeUnits);
  return frame;
}

Uint8List _selfInfo({required int manualAdd, int freq = 910525, int sf = 7}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List(32)..fillRange(0, 32, 0x11));
  w.add(Uint8List(8)); // lat, lon
  w.add([0, 0, 0, manualAdd]); // multi_acks, loc policy, telemetry, manual add
  w.add(
    (ByteData(8)
          ..setUint32(0, freq, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([sf, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Future<void> _settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late HealthContext ctx;

  Future<List<String>> findings(bool Function(HealthRule) which) async {
    final found = <String>[];
    for (final rule in healthRules.where((r) => r.enabled && which(r))) {
      if (await rule.check(ctx)) found.add(rule.id);
    }
    return found;
  }

  Uint8List? sentFrame(int cmd) {
    for (final f in c.sent) {
      if (f[0] == cmd) return f;
    }
    return null;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.initialize(retryService: MessageRetryService());
    ctx = HealthContext(c, AppSettingsService());
  });

  test('default app settings raise no finding', () async {
    expect(await findings((r) => !r.needsRadio), isEmpty);
  });

  test('a factory radio is moved to the recommended values', () async {
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo(manualAdd: 0));
    c.sent.clear();
    c.handleFrameForTest([respCodeAutoAddConfig, 0, 0]);
    await _settle();

    final autoAdd = sentFrame(cmdSetAutoAddConfig);
    expect(autoAdd, isNotNull);
    expect(autoAdd![1], autoAddChatFlag | autoAddOverwriteOldestFlag);
    expect(sentFrame(cmdSetOtherParams)![4], 1, reason: '2 ACKs');
    expect(sentFrame(cmdSetPathHashMode)![2], 1, reason: '2-byte codes');

    expect(
      await findings(
        (r) =>
            r.id.startsWith('radio_auto_add') ||
            r.id == 'radio_multi_acks' ||
            r.id == 'radio_path_hash_width',
      ),
      isEmpty,
    );
  });

  group('firmware rule', () {
    final rule = healthRules.firstWhere((r) => r.id == 'radio_firmware');

    for (final (version, flagged) in [
      ('v1.16.0-abc', true),
      ('v1.17.0-abc', true),
      ('v1.17.1-d929643', false),
      ('v1.18.0', false),
      ('v2.0.0', false),
    ]) {
      test('$version ${flagged ? 'is' : 'is not'} flagged', () async {
        c.handleFrameForTest(_deviceInfo(version: version));
        expect(await rule.check(ctx), flagged);
      });
    }
  });

  test('a full contact list only matters with overwrite off', () async {
    final rule = healthRules.firstWhere((r) => r.id == 'radio_contacts_full');
    c.handleFrameForTest(_selfInfo(manualAdd: 1));
    c.handleFrameForTest([
      respCodeAutoAddConfig,
      autoAddOverwriteOldestFlag,
      0,
    ]);
    expect(await rule.check(ctx), isFalse);
  });

  test('the factory settings are flagged, a regional preset is not', () async {
    final rule = healthRules.firstWhere(
      (r) => r.id == 'radio_factory_settings',
    );
    c.handleFrameForTest(_selfInfo(manualAdd: 1));
    expect(await rule.check(ctx), isFalse);
    c.handleFrameForTest(_selfInfo(manualAdd: 1, freq: 869618, sf: 8));
    expect(await rule.check(ctx), isTrue);
  });

  test('direct message retries pass at 4 or 5', () async {
    final rule = healthRules.firstWhere((r) => r.id == 'app_dm_retries');
    for (final (retries, flagged) in [
      (1, true),
      (3, true),
      (4, false),
      (5, false),
    ]) {
      await ctx.settingsService.setMaxMessageRetries(retries);
      expect(await rule.check(ctx), flagged, reason: '$retries tries');
    }
  });

  group('notifications', () {
    late _Connector withPublic;
    late HealthContext publicCtx;
    final rule = healthRules.firstWhere(
      (r) => r.id == 'app_notify_public_channel',
    );

    setUp(() {
      withPublic = _Connector()
        ..channelList = [Channel.fromHex(0, '', Channel.publicChannelPsk)];
      publicCtx = HealthContext(withPublic, ctx.settingsService);
    });

    test('defaults are on, advert off, Public muted', () async {
      final s = ctx.app;
      expect(s.notificationsEnabled, isTrue);
      expect(s.notifyOnNewMessage, isTrue);
      expect(s.notifyOnNewChannelMessage, isTrue);
      expect(s.notifyOnMention, isTrue);
      expect(s.notifyOnNewAdvert, isFalse);
      expect(await rule.check(publicCtx), isFalse);
    });

    test('Public flags only while it would notify, and Fix mutes it', () async {
      final service = ctx.settingsService;
      await service.unmuteChannel(Channel.publicChannelPsk);
      expect(await rule.check(publicCtx), isTrue);

      await service.setNotifyOnNewChannelMessage(false);
      expect(await rule.check(publicCtx), isFalse);
      await service.setNotifyOnNewChannelMessage(true);

      await service.setNotificationsEnabled(false);
      expect(await rule.check(publicCtx), isFalse);
      await service.setNotificationsEnabled(true);

      await rule.apply!(publicCtx);
      expect(service.isChannelMuted(Channel.publicChannelPsk), isTrue);
      expect(await rule.check(publicCtx), isFalse);
    });

    test(
      'a saved unmute stays unmuted and a radio without Public passes',
      () async {
        final saved = AppSettings.fromJson({'muted_channels': <String>[]});
        expect(saved.mutedChannels, isEmpty);

        await ctx.settingsService.unmuteChannel(Channel.publicChannelPsk);
        withPublic.channelList = [Channel.fromHex(0, 'Friends', 'ab' * 16)];
        expect(await rule.check(publicCtx), isFalse);
      },
    );

    test('with the master switch off, only that rule speaks', () async {
      final service = ctx.settingsService;
      await service.setNotificationsEnabled(false);
      await service.setNotifyOnNewMessage(false);
      await service.setNotifyOnMention(false);
      await service.setNotifyOnNewAdvert(true);
      expect((await findings((r) => r.id.startsWith('app_notif'))), [
        'app_notifications_off',
      ]);
    });
  });

  group('phone notification permission', () {
    final rule = healthRules.firstWhere(
      (r) => r.id == 'app_notifications_blocked',
    );

    HealthContext withPhone(bool? allowed) => HealthContext(
      c,
      ctx.settingsService,
      notificationsAllowed: () async => allowed,
    );

    test('flags only a phone that blocks them', () async {
      expect(await rule.check(withPhone(false)), isTrue);
      expect(await rule.check(withPhone(true)), isFalse);
      expect(await rule.check(withPhone(null)), isFalse, reason: 'unknown');
    });

    test('stays quiet with notifications off in the app', () async {
      await ctx.settingsService.setNotificationsEnabled(false);
      expect(await rule.check(withPhone(false)), isFalse);
    });
  });

  group('firmware without a feature', () {
    test('old firmware is not told a missing feature is off', () async {
      c.handleFrameForTest(_deviceInfo(version: 'v1.7.0', code: 6));
      c.handleFrameForTest(_selfInfo(manualAdd: 1));
      expect(
        await findings(
          (r) =>
              r.id.startsWith('radio_auto_add') ||
              r.id == 'radio_multi_acks' ||
              r.id == 'radio_path_hash_width',
        ),
        isEmpty,
      );
    });
  });

  test('several auto-add fixes in a row keep each other', () async {
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo(manualAdd: 1));
    c.handleFrameForTest([
      respCodeAutoAddConfig,
      autoAddChatFlag |
          autoAddRepeaterFlag |
          autoAddRoomServerFlag |
          autoAddSensorFlag,
      3,
    ]);
    await _settle();
    c.sent.clear();

    for (final id in [
      'radio_auto_add_repeaters',
      'radio_auto_add_rooms',
      'radio_auto_add_sensors',
      'radio_auto_add_overwrite_oldest',
    ]) {
      await healthRules.firstWhere((r) => r.id == id).apply!(ctx);
    }

    final last = c.sent.lastWhere((f) => f[0] == cmdSetAutoAddConfig);
    expect(last[1], autoAddChatFlag | autoAddOverwriteOldestFlag);
    expect(last[2], 3, reason: 'max hops are kept');
  });

  group('waiting for the radio', () {
    test('finishes as soon as the replies are in', () async {
      c.handleFrameForTest(_deviceInfo());
      var done = false;
      final wait = c.refreshDeviceInfoAndWait().then((_) => done = true);
      await _settle();
      expect(done, isFalse);

      c.handleFrameForTest(_deviceInfo());
      c.handleFrameForTest(_selfInfo(manualAdd: 1));
      c.handleFrameForTest([respCodeBattAndStorage, 0, 0]);
      await _settle();
      expect(done, isFalse, reason: 'the auto-add reply is still out');

      c.handleFrameForTest([respCodeAutoAddConfig, 0, 0]);
      await wait;
      expect(done, isTrue);
    });

    test('gives up when a reply never comes', () async {
      c.handleFrameForTest(_deviceInfo());
      await c.refreshDeviceInfoAndWait(
        timeout: const Duration(milliseconds: 10),
      );
    });
  });

  test('a radio already set up is left alone', () async {
    c.handleFrameForTest(_selfInfo(manualAdd: 1));
    c.sent.clear();
    c.handleFrameForTest([respCodeAutoAddConfig, autoAddRepeaterFlag, 0]);
    await _settle();

    expect(sentFrame(cmdSetAutoAddConfig), isNull);
    expect(sentFrame(cmdSetOtherParams), isNull);
    expect(c.autoAddRepeaters, isTrue);
  });
}
