import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/notification_service.dart';

// SOS alerts go out on a notification category of their own: the loudest,
// the alarm sound and a long vibration, asking to pass Do Not Disturb.
// Plain channel messages keep theirs, so muting chatter in the phone's
// settings never mutes an SOS.
void main() {
  late AppLocalizations l10n;
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('SOS has its own category, made the same wherever it is made', () {
    final sos = NotificationService.sosAndroidDetails(l10n);
    final category = NotificationService.sosChannel(l10n);
    expect(sos.channelId, 'meshtrax_sos_morse');
    expect(category.id, sos.channelId);
    expect(sos.channelName, 'SOS alerts');
    expect(category.name, 'SOS alerts');
    expect(sos.importance, Importance.max);
    expect(category.importance, Importance.max);
    expect(sos.priority, Priority.max);
    expect(sos.channelBypassDnd, isTrue);
    expect(category.bypassDnd, isTrue);
    expect(sos.category, AndroidNotificationCategory.alarm);
    expect(sos.audioAttributesUsage, AudioAttributesUsage.alarm);
    expect(category.audioAttributesUsage, AudioAttributesUsage.alarm);
    expect(
      (sos.sound! as RawResourceAndroidNotificationSound).sound,
      'sos_morse',
      reason: 'SOS in Morse, android/app/src/main/res/raw',
    );
    expect(sos.vibrationPattern, category.vibrationPattern);
    expect(sos.vibrationPattern, isNotEmpty);
    expect(sos.visibility, NotificationVisibility.public);
    expect(sos.groupKey, isNull, reason: 'never folded into the messages');
    expect(sos.silent, isFalse);
    expect(
      NotificationService.sosAndroidDetails(l10n, silent: true).silent,
      isTrue,
    );
    expect(sos.actions, isNull);
  });

  test('Got it on the notification opens the app to send it', () {
    final details = NotificationService.sosAndroidDetails(l10n, gotIt: true);
    final action = details.actions!.single;
    expect(action.id, NotificationService.sosGotItAction);
    expect(action.title, 'Got it');
    expect(action.showsUserInterface, isTrue);
    expect(action.cancelNotification, isTrue, reason: 'the sound stops');

    String? tapped(String? actionId) => NotificationService.tapPayload(
      NotificationResponse(
        notificationResponseType: actionId == null
            ? NotificationResponseType.selectedNotification
            : NotificationResponseType.selectedNotificationAction,
        actionId: actionId,
        payload: 'mention:1:abc',
      ),
    );
    expect(tapped(null), 'mention:1:abc');
    expect(tapped(NotificationService.sosGotItAction), 'gotit:mention:1:abc');
  });

  test('channel messages keep their own category', () {
    final plain = NotificationService.channelAndroidDetails(l10n);
    expect(plain.channelId, 'meshtrax_channels');
    expect(plain.audioAttributesUsage, AudioAttributesUsage.notification);
  });

  test('one SOS notification per sender and chat, clear of message ids', () {
    final ann = NotificationService.sosNotificationId('trip', 'Ann');
    expect(NotificationService.sosNotificationId('trip', 'Ann'), ann);
    expect(NotificationService.sosNotificationId('trip', 'Bob'), isNot(ann));
    expect(NotificationService.sosNotificationId('camp', 'Ann'), isNot(ann));
    expect(ann & 0x40000000, isNonZero);
    expect(ann, lessThan(0x80000000), reason: 'an Android id is 32-bit');
  });
}
