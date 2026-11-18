import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/notification_service.dart';

// TRAX mode's notifications. The reminder at the trip's end goes out on a
// category of its own, an ordinary one: not an alarm, and muting messages
// in the phone's settings doesn't mute it.
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
}
