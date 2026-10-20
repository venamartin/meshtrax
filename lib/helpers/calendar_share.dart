/// Reads the text Google Calendar produces when an event is shared:
///
/// ```
/// SCCARC Board Zoom
/// Oct 15  •  5 – 6 PM  •  View details & RSVP https://calendar.app.google/abc
/// ```
///
/// Google can change this wording at any time, so the parser returns null
/// rather than guessing when the date line does not match. English month
/// names only.
class CalendarShare {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String link;

  const CalendarShare({
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    required this.link,
  });

  static final _link = RegExp(r'https://calendar\.app\.google/\S+');

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static final _date = RegExp(
    r'(?:(?:mon|tue|wed|thu|fri|sat|sun)[a-z]*,?\s+)?'
    r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+'
    r'(\d{1,2})(?:,?\s+(\d{4}))?',
    caseSensitive: false,
  );

  static final _time = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*[-–—]\s*'
    r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    caseSensitive: false,
  );

  static final _singleTime =
      RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false);

  static bool looksLike(String text) => _link.hasMatch(text);

  static CalendarShare? parse(String text, {DateTime? now}) {
    final linkMatch = _link.firstMatch(text);
    if (linkMatch == null) return null;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    int dateLine = -1;
    RegExpMatch? date;
    for (var i = 0; i < lines.length; i++) {
      final m = _date.firstMatch(lines[i]);
      if (m != null) {
        dateLine = i;
        date = m;
        break;
      }
    }
    if (date == null) return null;
    final title = lines.take(dateLine).join(' ').trim();
    if (title.isEmpty) return null;

    final today = now ?? DateTime.now();
    final month = _months[date.group(1)!.toLowerCase().substring(0, 3)]!;
    final day = int.parse(date.group(2)!);
    final year = date.group(3) != null
        ? int.parse(date.group(3)!)
        : _inferYear(month, day, today);
    if (!_validDay(year, month, day)) return null;

    // Everything after the date on that line: a second date (range), a time
    // range, "All day", and the call to action with the link.
    var rest = lines[dateLine].substring(date.end).replaceAll(_link, '');
    DateTime? endDate;
    final secondDate = _date.firstMatch(rest);
    if (secondDate != null) {
      final m2 = _months[secondDate.group(1)!.toLowerCase().substring(0, 3)]!;
      final d2 = int.parse(secondDate.group(2)!);
      final y2 =
          secondDate.group(3) != null ? int.parse(secondDate.group(3)!) : year;
      if (_validDay(y2, m2, d2)) endDate = DateTime(y2, m2, d2);
      rest = rest.replaceRange(secondDate.start, secondDate.end, ' ');
    }

    final link = linkMatch.group(0)!;
    final time = _time.firstMatch(rest);
    if (time != null) {
      final startMeridiem = time.group(3)?.toLowerCase();
      final endMeridiem = time.group(6)?.toLowerCase();
      final sh =
          _hour24(int.parse(time.group(1)!), startMeridiem ?? endMeridiem);
      final eh = _hour24(int.parse(time.group(4)!), endMeridiem ?? startMeridiem);
      if (sh == null || eh == null) return null;
      final sm = int.tryParse(time.group(2) ?? '0') ?? 0;
      final em = int.tryParse(time.group(5) ?? '0') ?? 0;
      final start = DateTime(year, month, day, sh, sm);
      final endBase = endDate ?? DateTime(year, month, day);
      var end = DateTime(endBase.year, endBase.month, endBase.day, eh, em);
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
      return CalendarShare(
        title: title,
        start: start,
        end: end,
        allDay: false,
        link: link,
      );
    }

    final single = _singleTime.firstMatch(rest);
    if (single != null) {
      final h =
          _hour24(int.parse(single.group(1)!), single.group(3)!.toLowerCase());
      if (h == null) return null;
      final start = DateTime(
        year,
        month,
        day,
        h,
        int.tryParse(single.group(2) ?? '0') ?? 0,
      );
      return CalendarShare(
        title: title,
        start: start,
        end: null,
        allDay: false,
        link: link,
      );
    }

    return CalendarShare(
      title: title,
      start: DateTime(year, month, day),
      end: endDate,
      allDay: true,
      link: link,
    );
  }

  /// The next occurrence of month/day, allowing 30 days into the past so a
  /// share forwarded a little late still lands on the right year.
  static int _inferYear(int month, int day, DateTime today) {
    for (final year in [today.year - 1, today.year, today.year + 1]) {
      if (!_validDay(year, month, day)) continue;
      final candidate = DateTime(year, month, day);
      if (!candidate.isBefore(today.subtract(const Duration(days: 30)))) {
        return year;
      }
    }
    return today.year;
  }

  static bool _validDay(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return false;
    final d = DateTime(year, month, day);
    return d.month == month && d.day == day;
  }

  static int? _hour24(int hour, String? meridiem) {
    if (meridiem == null) return hour >= 0 && hour < 24 ? hour : null;
    if (hour < 1 || hour > 12) return null;
    if (meridiem == 'am') return hour == 12 ? 0 : hour;
    return hour == 12 ? 12 : hour + 12;
  }
}
