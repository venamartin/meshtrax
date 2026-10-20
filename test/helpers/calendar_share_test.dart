import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/calendar_share.dart';

void main() {
  const link = 'https://calendar.app.google/nsnPfzPVoxmm3DBDA';
  final now = DateTime(2026, 10, 1);

  test('the owner sample', () {
    final s = CalendarShare.parse(
      'SCCARC Board Zoom\nOct 15  •  5 – 6 PM  •  View details & RSVP $link',
      now: now,
    );
    expect(s, isNotNull);
    expect(s!.title, 'SCCARC Board Zoom');
    expect(s.start, DateTime(2026, 10, 15, 17));
    expect(s.end, DateTime(2026, 10, 15, 18));
    expect(s.allDay, isFalse);
    expect(s.link, link);
  });

  test('time wording variants', () {
    final cases = {
      '5:30 – 6 PM': [DateTime(2026, 10, 15, 17, 30), DateTime(2026, 10, 15, 18)],
      '11 AM – 1 PM': [DateTime(2026, 10, 15, 11), DateTime(2026, 10, 15, 13)],
      '5 PM – 6 PM': [DateTime(2026, 10, 15, 17), DateTime(2026, 10, 15, 18)],
      '9 - 10 AM': [DateTime(2026, 10, 15, 9), DateTime(2026, 10, 15, 10)],
      '12 – 1 PM': [DateTime(2026, 10, 15, 12), DateTime(2026, 10, 15, 13)],
      '11:30 PM – 12:30 AM': [
        DateTime(2026, 10, 15, 23, 30),
        DateTime(2026, 10, 16, 0, 30),
      ],
    };
    cases.forEach((time, expected) {
      final s = CalendarShare.parse('Title\nOct 15  •  $time  •  View $link', now: now);
      expect(s, isNotNull, reason: time);
      expect(s!.start, expected[0], reason: time);
      expect(s.end, expected[1], reason: time);
    });
  });

  test('all day, weekday prefix, explicit year, date range', () {
    final a = CalendarShare.parse('Fieldday\nSat, Oct 18  •  All day  •  View $link', now: now);
    expect(a!.allDay, isTrue);
    expect(a.start, DateTime(2026, 10, 18));
    final b = CalendarShare.parse('Fieldday\nOct 18, 2027  •  All day  •  $link', now: now);
    expect(b!.start, DateTime(2027, 10, 18));
    final c = CalendarShare.parse('Fieldday\nOct 18 – Oct 19  •  All day  •  $link', now: now);
    expect(c!.start, DateTime(2026, 10, 18));
    expect(c.end, DateTime(2026, 10, 19));
    expect(c.allDay, isTrue);
  });

  test('single start time', () {
    final s = CalendarShare.parse('Call\nOct 15  •  5 PM  •  $link', now: now);
    expect(s!.start, DateTime(2026, 10, 15, 17));
    expect(s.end, isNull);
  });

  test('missing year resolves forward, allowing 30 days back', () {
    final late = DateTime(2026, 12, 20);
    expect(CalendarShare.parse('T\nJan 5  •  All day  •  $link', now: late)!.start,
        DateTime(2027, 1, 5));
    expect(CalendarShare.parse('T\nDec 1  •  All day  •  $link', now: late)!.start,
        DateTime(2026, 12, 1));
    expect(CalendarShare.parse('T\nOct 1  •  All day  •  $link', now: late)!.start,
        DateTime(2027, 10, 1));
  });

  test('declines without the link or a date line', () {
    expect(CalendarShare.parse('Title\nOct 15  •  5 – 6 PM'), isNull);
    expect(CalendarShare.parse('Title\nsometime soon $link'), isNull);
    expect(CalendarShare.parse('$link'), isNull);
    expect(CalendarShare.looksLike('hello'), isFalse);
  });
}
