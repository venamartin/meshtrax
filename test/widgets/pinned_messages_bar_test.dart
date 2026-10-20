import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/widgets/pinned_messages_bar.dart';

void main() {
  final now = DateTime(2026, 10, 20, 12);
  const pos = '47.070123, 15.440123';

  PinCandidate c(
    String id,
    String text, {
    int minutesAgo = 0,
    int index = 0,
    bool server = false,
  }) =>
      PinCandidate(
        id: id,
        text: text,
        timestamp: now.subtract(Duration(minutes: minutesAgo)),
        index: index,
        serverAuthored: server,
      );

  List<PinnedEntry> compute(
    List<PinCandidate> candidates, {
    Set<String> dismissed = const {},
    bool isRoom = false,
  }) =>
      PinnedMessagesBar.compute(
        candidates: candidates,
        dismissed: dismissed,
        isRoom: isRoom,
        now: now,
      );

  test('Location never pins, plain text never pins', () {
    expect(compute([c('a', 'Location: $pos'), c('b', 'hello')]), isEmpty);
  });

  test('newest SOS wins, and a dismissed one stays hidden', () {
    final pins = compute([
      c('old', 'SOS: first\n$pos', minutesAgo: 30),
      c('new', 'SOS: second\n$pos', minutesAgo: 5),
    ]);
    expect(pins.map((p) => p.id), ['new']);
    final afterDismiss = compute(
      [c('old', 'SOS: first\n$pos', minutesAgo: 30), c('new', 'SOS: second\n$pos', minutesAgo: 5)],
      dismissed: {'new'},
    );
    expect(afterDismiss.map((p) => p.id), ['old']);
  });

  test('the next upcoming event pins, past events do not', () {
    final pins = compute([
      c('past', 'Event: Done\n2026-10-19 10:00-11:00'),
      c('later', 'Event: Later\n2026-10-25 10:00'),
      c('soon', 'Event: Soon\n2026-10-21 18:00'),
    ]);
    expect(pins.map((p) => p.id), ['soon']);
  });

  test('an event still running pins; one without an end lasts an hour', () {
    expect(
      compute([c('a', 'Event: Now\n2026-10-20 11:30')]).map((p) => p.id),
      ['a'],
    );
    expect(compute([c('a', 'Event: Earlier\n2026-10-20 10:30')]), isEmpty);
    expect(
      compute([c('a', 'Event: Today\n2026-10-20')]).map((p) => p.id),
      ['a'],
    );
  });

  test('channel notices do not pin', () {
    expect(compute([c('n', 'Notice: hello')]), isEmpty);
  });

  test('rooms pin the newest server-authored post, prefixed or not', () {
    final pins = compute(
      [
        c('member', 'Notice: from a member', minutesAgo: 1),
        c('s1', 'Repeater down', minutesAgo: 20, server: true),
        c('s2', 'Notice: Repeater back up', minutesAgo: 10, server: true),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['s2']);
    expect((pins.single.message as NoticeMessage).headline, 'Repeater back up');
  });

  test('order is SOS, Event, Notice', () {
    final pins = compute(
      [
        c('n', 'Board meeting moved', server: true),
        c('e', 'Event: Meetup\n2026-10-21 18:00'),
        c('s', 'SOS: help\n$pos'),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['s', 'e', 'n']);
  });
}
