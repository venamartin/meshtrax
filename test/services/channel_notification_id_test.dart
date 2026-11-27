import 'package:flutter_test/flutter_test.dart';

import 'package:meshtrax/services/notification_service.dart';

// A channel's notification ids. Each channel has one for its messages and
// one for its mentions. Before, a mention on slot n had the id of a plain
// message on slot n ^ 2 (a mention on Public in slot 1 and a message on
// slot 3 were both 15), so the message took the mention's place.
void main() {
  int message(int slot) =>
      NotificationService.channelNotificationId(slot, '', mention: false);
  int mention(int slot) =>
      NotificationService.channelNotificationId(slot, '', mention: true);

  test('a mention on one channel never has the id of a message on another',
      () {
    expect(mention(1), isNot(message(3)));
    final ids = {
      for (var i = 0; i < 64; i++) ...[message(i), mention(i)],
    };
    expect(ids, hasLength(128));
  });

  test('clear of the app\'s other ids', () {
    final ids = {
      for (var i = 0; i < 64; i++) ...[message(i), mention(i)],
    };
    final others = {
      for (var i = 0; i < 64; i++) NotificationService.traxNotificationId(i),
      NotificationService.traxEndedId,
      0x4D54, // the group summary
      1000, // MeshTrax running
    };
    expect(ids.intersection(others), isEmpty);
  });

  test('a channel without a slot: its mention and its message differ', () {
    final byName = NotificationService.channelNotificationId(
      null,
      '#offroad',
      mention: false,
    );
    final mentionByName = NotificationService.channelNotificationId(
      null,
      '#offroad',
      mention: true,
    );
    expect(mentionByName, isNot(byName));
    final slotted = {
      for (var i = 0; i < 64; i++) ...[message(i), mention(i)],
    };
    expect(slotted.contains(byName) || slotted.contains(mentionByName),
        isFalse);
  });
}
