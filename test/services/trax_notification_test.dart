import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/notification_service.dart';

// TRAX mode's notifications. The reminder at the trip's end goes out on a
// category of its own, an ordinary one: not an alarm, and muting messages
// in the phone's settings doesn't mute it. A member's TRAX message is a
// channel message with one button, Switch too or Leave too, which opens
// the app to ask: nothing switches from the notification.
void main() {
  late AppLocalizations l10n;
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('the trip\'s end reminder has an ordinary category of its own', () {
    final details = NotificationService.traxAndroidDetails(l10n);
    expect(details.channelId, NotificationService.traxChannelId);
    expect(details.channelId, isNot('meshtrax_channels'));
    expect(details.channelName, 'TRAX mode');
    expect(details.importance, Importance.defaultImportance);
    expect(details.priority, Priority.defaultPriority);
    expect(details.audioAttributesUsage, AudioAttributesUsage.notification);
    expect(details.groupKey, isNull, reason: 'not folded into the messages');
    expect(details.actions, isNull);
  });

  test('Switch too and Leave too open the app to ask', () {
    AndroidNotificationAction button(String action) =>
        NotificationService.channelAndroidDetails(
          l10n,
          traxAction: action,
        ).actions!.single;

    final follow = button(NotificationService.traxFollowAction);
    expect(follow.id, NotificationService.traxFollowAction);
    expect(follow.title, 'Switch too');
    expect(follow.showsUserInterface, isTrue);
    expect(follow.cancelNotification, isTrue);
    final leave = button(NotificationService.traxLeaveAction);
    expect(leave.id, NotificationService.traxLeaveAction);
    expect(leave.title, 'Leave too');
    expect(leave.showsUserInterface, isTrue);

    final plain = NotificationService.channelAndroidDetails(l10n);
    expect(plain.channelId, 'meshtrax_channels');
    expect(plain.importance, Importance.max);
    expect(plain.actions, isNull);
  });

  test('a button\'s tap is told apart from a tap on the notification', () {
    String? tapped(String? action, {String payload = 'channel:1'}) =>
        NotificationService.tapPayload(
          NotificationResponse(
            notificationResponseType: action == null
                ? NotificationResponseType.selectedNotification
                : NotificationResponseType.selectedNotificationAction,
            actionId: action,
            payload: payload,
          ),
        );
    expect(tapped(null), 'channel:1');
    expect(
      tapped(NotificationService.traxFollowAction),
      'traxfollow:channel:1',
    );
    expect(tapped(NotificationService.traxLeaveAction), 'traxleave:channel:1');
    expect(tapped(null, payload: ''), isNull);

    expect(NotificationService.channelIndexOf('channel:3'), 3);
    expect(NotificationService.channelIndexOf('mention:12:abc'), 12);
    expect(NotificationService.channelIndexOf('ab' * 32), isNull);
  });

  test('a button keeps its own id, so the chat after it leaves it there', () {
    final others = {
      for (var i = 0; i < 64; i++) ...[i ^ 0x0C, i ^ 0x0E],
      0x4D54,
      NotificationService.traxEndedId,
    };
    final ids = {
      for (var i = 0; i < 64; i++) NotificationService.traxNotificationId(i),
    };
    expect(ids, hasLength(64), reason: 'one per channel');
    expect(ids.intersection(others), isEmpty);
  });
}
