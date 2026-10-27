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

  test('every SOS pins, newest first, until dismissed', () {
    final both = [
      c('old', 'SOS: first\n$pos', minutesAgo: 30),
      c('new', 'SOS: second\n$pos', minutesAgo: 5),
    ];
    expect(compute(both).map((p) => p.id), ['new', 'old']);
    expect(compute(both, dismissed: {'new'}).map((p) => p.id), ['old']);
  });

  test('every upcoming event pins, soonest first; past events do not', () {
    final pins = compute([
      c('past', 'Event: Done\n2026-10-19 10:00-11:00'),
      c('later', 'Event: Later\n2026-10-25 10:00', minutesAgo: 30),
      c('soon', 'Event: Soon\n2026-10-21 18:00', minutesAgo: 40),
    ]);
    expect(pins.map((p) => p.id), ['soon', 'later']);
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

  test('channel and DM notices pin until they expire or are dismissed', () {
    final pins = compute([
      c('old', 'Notice: hello', minutesAgo: 30),
      c('new', 'Notice: Net tonight\nexpires=2026-10-20 21:00', minutesAgo: 10),
      c('gone', 'Notice: Old\nexpires=2026-10-20 11:00', minutesAgo: 5),
    ]);
    expect(pins.map((p) => p.id), ['new', 'old']);
    expect(
      compute([c('n', 'Notice: hello')], dismissed: {'n'}),
      isEmpty,
    );
  });

  test('a channel stacks SOS, then events, then notices', () {
    final pins = compute([
      c('notice', 'Notice: Road closed', minutesAgo: 1),
      c('later', 'Event: Picnic\n2026-10-27 14:00', minutesAgo: 2),
      c('sos', 'SOS: need a ride\n$pos', minutesAgo: 50),
      c('soon', 'Event: Net check-in\n2026-10-26 09:00', minutesAgo: 3),
    ]);
    expect(pins.map((p) => p.id), ['sos', 'soon', 'later', 'notice']);
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

  test('a room orders SOS, events, notices, then the announcement', () {
    final pins = compute(
      [
        c('a', 'Board meeting moved', server: true),
        c('n', 'Notice: Net\nexpires=2026-10-22', minutesAgo: 1, server: true),
        c('e', 'Event: Meetup\n2026-10-21 18:00'),
        c('s', 'SOS: help\n$pos'),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['s', 'e', 'n', 'a']);
  });

  test("members' events in a room stack with the server's, by start", () {
    final pins = compute(
      [
        c('server', 'Event: Field day\n2026-10-25', minutesAgo: 1, server: true),
        c('m2', 'Event: Coffee\n2026-10-22 08:00', minutesAgo: 2),
        c('m1', 'Event: Meetup\n2026-10-21 18:00', minutesAgo: 3),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['m1', 'm2', 'server']);
  });

  test('server notices with an expiry stack until they expire', () {
    final pins = compute(
      [
        c('n1', 'Notice: Road closed\nexpires=2026-10-22', minutesAgo: 30,
            server: true),
        c('n2', 'Notice: Net tonight\nexpires=2026-10-20 21:00', minutesAgo: 10,
            server: true),
        c('gone', 'Notice: Old\nexpires=2026-10-20 11:00', minutesAgo: 5,
            server: true),
        c('plain', 'Welcome to the room', minutesAgo: 20, server: true),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['n2', 'n1', 'plain']);
  });

  test('only the newest plain announcement pins', () {
    final pins = compute(
      [
        c('a1', 'First news', minutesAgo: 30, server: true),
        c('a2', 'Notice: no expiry', minutesAgo: 20, server: true),
        c('a3', 'Latest news', minutesAgo: 10, server: true),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['a3']);
    expect((pins.single.message as NoticeMessage).announcement, isTrue);
  });

  test('a server event takes one slot and stacks with others', () {
    final pins = compute(
      [
        c('e1', 'Event: Meetup\n2026-10-21 18:00', minutesAgo: 30,
            server: true),
        c('e2', 'Event: Field day\n2026-10-25', minutesAgo: 10, server: true),
        c('past', 'Event: Over\n2026-10-19 10:00', minutesAgo: 5,
            server: true),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['e1', 'e2']);
    expect(pins.every((p) => p.message is EventMessage), isTrue);
  });

  test('at most five rows', () {
    final pins = compute(
      [
        for (var i = 0; i < 8; i++)
          c('n$i', 'Notice: item $i\nexpires=2026-10-30', minutesAgo: i,
              server: true),
      ],
      isRoom: true,
    );
    expect(pins.map((p) => p.id), ['n0', 'n1', 'n2', 'n3', 'n4']);
  });

  test('entries run out at their expiry or end', () {
    final pins = compute(
      [
        c('n', 'Notice: Net\nexpires=2026-10-20 15:00', server: true),
        c('e', 'Event: Meetup\n2026-10-20 13:00-14:00'),
      ],
      isRoom: true,
    );
    expect(PinnedMessagesBar.nextChange(pins), DateTime(2026, 10, 20, 14));
    final later = DateTime(2026, 10, 20, 14, 30);
    expect(
      pins.where((p) => PinnedMessagesBar.stillPinned(p, later)).map((p) => p.id),
      ['n'],
    );
    expect(
      pins.where((p) =>
          PinnedMessagesBar.stillPinned(p, DateTime(2026, 10, 20, 15))),
      isEmpty,
    );
  });
}
