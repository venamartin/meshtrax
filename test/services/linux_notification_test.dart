import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/notification_service.dart';

// Linux (#359): messages show as desktop pop-ups over D-Bus, and the app
// plays the tone itself, since the desktop's notification service may play
// none. An SOS sounds the Morse alarm Android sounds. Without a desktop
// session there are no pop-ups, but the tone still plays.
void main() {
  late AppLocalizations l10n;
  late Directory tmp;
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    tmp = Directory.systemTemp.createTempSync('linux_notification_test');
  });
  tearDown(() {
    tmp.deleteSync(recursive: true);
    debugDefaultTargetPlatformOverride = null;
    NotificationService.debugOnTone = null;
  });

  test('pop-ups need a session bus', () {
    expect(
      NotificationService.hasSessionBus({
        'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/user/1000/bus',
      }),
      isTrue,
    );
    expect(NotificationService.hasSessionBus({}), isFalse);
    expect(
      NotificationService.hasSessionBus({'XDG_RUNTIME_DIR': tmp.path}),
      isFalse,
    );
    File('${tmp.path}/bus').createSync();
    expect(
      NotificationService.hasSessionBus({'XDG_RUNTIME_DIR': tmp.path}),
      isTrue,
    );
  });

  test('the tone plays through paplay, else pw-play', () {
    final first = Directory('${tmp.path}/a')..createSync();
    final second = Directory('${tmp.path}/b')..createSync();
    final path = '${first.path}:${second.path}';
    expect(NotificationService.soundPlayer({'PATH': path}), isNull);
    File('${first.path}/pw-play').createSync();
    expect(
      NotificationService.soundPlayer({'PATH': path}),
      '${first.path}/pw-play',
    );
    File('${second.path}/paplay').createSync();
    expect(
      NotificationService.soundPlayer({'PATH': path}),
      '${second.path}/paplay',
      reason: 'paplay works on PulseAudio and PipeWire alike',
    );
  });

  test('pop-ups are quiet: the app sounds the tone', () {
    final details = NotificationService.linuxDetails(l10n);
    expect(details.suppressSound, isTrue);
    expect(details.defaultActionName, 'Open');
    expect(details.actions, isEmpty);

    final channel = NotificationService.channelLinuxDetails(l10n);
    expect(channel.suppressSound, isTrue);
    expect(channel.category, LinuxNotificationCategory.imReceived);
    expect(channel.actions, isEmpty);
  });

  test('a member\'s TRAX message has its button on Linux too', () {
    LinuxNotificationAction button(String action) =>
        NotificationService.channelLinuxDetails(
          l10n,
          traxAction: action,
        ).actions.single;

    final follow = button(NotificationService.traxFollowAction);
    expect(follow.key, NotificationService.traxFollowAction);
    expect(follow.label, 'Switch too');
    final leave = button(NotificationService.traxLeaveAction);
    expect(leave.key, NotificationService.traxLeaveAction);
    expect(leave.label, 'Leave too');
  });

  test('the Linux SOS sound is the Android one', () {
    expect(
      File('assets/sounds/sos_morse.wav').readAsBytesSync(),
      File('android/app/src/main/res/raw/sos_morse.wav').readAsBytesSync(),
      reason: 'tool/make_sos_sound.py writes both',
    );
    expect(
      NotificationService.linuxSosSound,
      endsWith('/data/flutter_assets/assets/sounds/sos_morse.wav'),
    );
  });

  test('a message and an SOS sound their tones; a cancel sounds none', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final tones = <String>[];
    NotificationService.debugOnTone = tones.add;
    final service = NotificationService();

    await service.showMessageNotification(contactName: 'Ann', message: 'hi');
    await pumpEventQueue();
    expect(tones, [NotificationService.linuxMessageSound]);

    tones.clear();
    await service.showSosNotification(
      chatKey: 'ab',
      senderName: 'Ann',
      where: '',
      text: 'Help',
      payload: 'ab',
    );
    expect(tones, [NotificationService.linuxSosSound]);

    tones.clear();
    await service.showSosNotification(
      chatKey: 'ab',
      senderName: 'Ann',
      where: '',
      text: 'Help',
      payload: 'ab',
      cancelled: true,
    );
    expect(tones, isEmpty);
  });

  test('no tone off Linux', () async {
    final tones = <String>[];
    NotificationService.debugOnTone = tones.add;
    await NotificationService().showSosNotification(
      chatKey: 'cd',
      senderName: 'Bob',
      where: '',
      text: 'Help',
      payload: 'cd',
    );
    expect(tones, isEmpty);
  });
}
