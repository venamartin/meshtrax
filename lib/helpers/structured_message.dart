import 'package:latlong2/latlong.dart';

import 'calendar_share.dart';
import 'maps_link.dart';

/// The MeshTrax structured message format, documented in
/// docs/message-format.md.
///
/// ```
/// TYPE: field
/// field
/// field
/// ```
///
/// A type keyword starts the body (after any reply or mention markup), fields
/// follow one per line (or separated by `|`), and every field is recognised
/// by its shape: a position, a link, a date, a `key=value` extension, or free
/// text. Anything a reader does not understand is kept and shown, never
/// dropped. Lines other apps send without the keyword (bare coordinates, maps
/// links, the legacy `m:` marker, a Google Calendar share) are read too.
sealed class StructuredMessage {
  /// Free-text fields beyond the ones the type uses, shown as extra lines.
  final List<String> extraText;

  /// `key=value` fields, kept for forward compatibility and shown in a footer.
  final Map<String, String> extensions;

  /// A non-maps http(s) link carried by the message.
  final String? link;

  const StructuredMessage({
    this.extraText = const [],
    this.extensions = const {},
    this.link,
  });

  LatLng? get position;

  /// One line for reply previews and notifications, e.g. "Event: Mesh meetup".
  String get summary;

  String get keyword;

  /// The wire text MeshTrax sends.
  String toWire();

  // ---------------------------------------------------------------------
  // Shapes

  /// A standalone `lat, lon` token with at least three decimals on each.
  static final coordinatePattern = RegExp(
    r'(?<![\w.\-])(-?\d{1,2}\.\d{3,})\s*,\s*(-?\d{1,3}\.\d{3,})(?![\w.])',
  );

  static final _httpLink = RegExp(r'^https?://\S+$', caseSensitive: false);

  static final _extension = RegExp(r'^([a-z][a-z0-9_]*)=(.*)$');

  static final _header = RegExp(
    r'^(location|poi|sos|event|notice)\s*:\s*',
    caseSensitive: false,
  );

  static final _legacyMarker = RegExp(
    r'^m:([\-0-9.]+),([\-0-9.]+)\|([^|]*)(?:\|(.*))?$',
  );

  static final _leadingMention = RegExp(r'^@\[[^\]]+\][ \n]?');

  static LatLng? parseCoordinates(String field) {
    final m = coordinatePattern.firstMatch(field.trim());
    if (m == null || m.start != 0 || m.end != field.trim().length) return null;
    return _bounded(double.tryParse(m.group(1)!), double.tryParse(m.group(2)!));
  }

  static LatLng? _bounded(double? lat, double? lon) {
    if (lat == null || lon == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return LatLng(lat, lon);
  }

  static String formatCoordinates(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';

  /// Free text safe for one field: no `|`, no line breaks.
  static String sanitizeField(String text) => text
      .replaceAll('|', '/')
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// The body without leading `@[Name]` mentions and without a reply quote
  /// (`@[Name]\n>snippet..\n` or the older `@[Name] re:snippet…`).
  static String stripMarkup(String text) {
    var out = text.trimLeft();
    var hadMention = false;
    while (true) {
      final m = _leadingMention.firstMatch(out);
      if (m == null || m.end == 0) break;
      out = out.substring(m.end);
      hadMention = true;
    }
    if (!hadMention) return out.trim();
    if (out.startsWith('>')) {
      final nl = out.indexOf('\n');
      out = nl < 0 ? '' : out.substring(nl + 1);
    } else {
      final re = RegExp(r'^re:.*?(?:…|\.\.\.)\s*', caseSensitive: false);
      final m = re.firstMatch(out);
      if (m != null) out = out.substring(m.end);
    }
    return out.trim();
  }

  /// Whether [text] is one of ours (or a legacy marker), used to keep it out
  /// of SMAZ compression so other apps can read it.
  static bool hasPrefix(String text) {
    final body = stripMarkup(text);
    return _header.hasMatch(body) || _legacyMarker.hasMatch(body);
  }

  /// Parses [text] into a structured message, or null for ordinary text.
  ///
  /// [resolveShortLink] answers a Google short link from a cache; without it
  /// a message that only carries a short link stays plain until resolved.
  static StructuredMessage? parse(
    String text, {
    LatLng? Function(String url)? resolveShortLink,
    DateTime? now,
  }) {
    final body = stripMarkup(text);
    if (body.isEmpty) return null;

    final legacy = _legacyMarker.firstMatch(body);
    if (legacy != null) {
      final position =
          _bounded(double.tryParse(legacy.group(1)!), double.tryParse(legacy.group(2)!));
      if (position == null) return null;
      final label = legacy.group(3)!.trim();
      return LocationMessage(
        position: position,
        label: label.isEmpty ? null : label,
      );
    }

    final header = _header.firstMatch(body);
    if (header == null) return _parseLoose(body, resolveShortLink, now);

    final keyword = header.group(1)!.toLowerCase();
    final fields = _splitFields(body.substring(header.end));
    final sorted = _Fields.classify(fields, resolveShortLink);

    switch (keyword) {
      case 'location':
      case 'poi':
        if (sorted.position == null) return null;
        return LocationMessage(
          position: sorted.position!,
          label: sorted.freeText.isNotEmpty ? sorted.freeText[0] : null,
          note: sorted.freeText.length > 1 ? sorted.freeText[1] : null,
          link: sorted.link,
          extraText: sorted.freeText.skip(2).toList(),
          extensions: sorted.extensions,
        );
      case 'sos':
        if (sorted.position == null) return null;
        return SosMessage(
          position: sorted.position!,
          text: sorted.freeText.isNotEmpty ? sorted.freeText[0] : '',
          note: sorted.freeText.length > 1 ? sorted.freeText[1] : null,
          link: sorted.link,
          extraText: sorted.freeText.skip(2).toList(),
          extensions: sorted.extensions,
        );
      case 'event':
        if (sorted.when == null || sorted.freeText.isEmpty) return null;
        return EventMessage(
          title: sorted.freeText[0],
          when: sorted.when!,
          place: sorted.freeText.length > 1 ? sorted.freeText[1] : null,
          position: sorted.position,
          link: sorted.link,
          extraText: sorted.freeText.skip(2).toList(),
          extensions: sorted.extensions,
        );
      case 'notice':
        if (sorted.freeText.isEmpty) return null;
        return NoticeMessage(
          lines: sorted.freeText,
          position: sorted.position,
          link: sorted.link,
          extensions: sorted.extensions,
        );
    }
    return null;
  }

  /// Things other apps send without a keyword.
  static StructuredMessage? _parseLoose(
    String body,
    LatLng? Function(String url)? resolveShortLink,
    DateTime? now,
  ) {
    if (CalendarShare.looksLike(body)) {
      final share = CalendarShare.parse(body, now: now);
      if (share == null) return null;
      return EventMessage(
        title: share.title,
        when: EventWhen(start: share.start, end: share.end, allDay: share.allDay),
        link: share.link,
      );
    }

    final lines = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty || lines.length > 3) return null;

    LatLng? position;
    String? name;
    final free = <String>[];
    for (final line in lines) {
      final coords = parseCoordinates(line);
      if (coords != null && position == null) {
        position = coords;
        continue;
      }
      if (MapsLink.isMapsUrl(line) && position == null) {
        final parsed = MapsLink.parse(line);
        if (parsed != null) {
          position = parsed.position;
          name ??= parsed.name;
          continue;
        }
        if (MapsLink.isShortLink(line)) {
          position = resolveShortLink?.call(line);
          if (position == null) return null;
          continue;
        }
        return null;
      }
      free.add(line);
    }
    if (position == null) return null;
    final label = free.isNotEmpty ? free[0] : name;
    return LocationMessage(
      position: position,
      label: label,
      note: free.length > 1 ? free[1] : null,
      extraText: free.skip(2).toList(),
    );
  }

  static List<String> _splitFields(String rest) => rest
      .split(RegExp(r'[\n|]'))
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();
}

class _Fields {
  LatLng? position;
  EventWhen? when;
  String? link;
  final freeText = <String>[];
  final extensions = <String, String>{};

  static _Fields classify(
    List<String> fields,
    LatLng? Function(String url)? resolveShortLink,
  ) {
    final out = _Fields();
    for (final field in fields) {
      final coords = StructuredMessage.parseCoordinates(field);
      if (coords != null) {
        out.position ??= coords;
        continue;
      }
      if (MapsLink.isMapsUrl(field)) {
        final parsed = MapsLink.parse(field);
        final position = parsed?.position ??
            (MapsLink.isShortLink(field) ? resolveShortLink?.call(field) : null);
        if (position != null) {
          out.position ??= position;
          continue;
        }
        out.link ??= field;
        continue;
      }
      if (StructuredMessage._httpLink.hasMatch(field)) {
        out.link ??= field;
        continue;
      }
      final when = EventWhen.parse(field);
      if (when != null) {
        out.when ??= when;
        continue;
      }
      final ext = StructuredMessage._extension.firstMatch(field);
      if (ext != null) {
        out.extensions[ext.group(1)!] = ext.group(2)!.trim();
        continue;
      }
      out.freeText.add(field);
    }
    return out;
  }
}

/// `YYYY-MM-DD`, optionally ` HH:MM`, optionally an end as `-HH:MM` (same
/// day) or ` - YYYY-MM-DD HH:MM`. Date only means all day. Floating local
/// time.
class EventWhen {
  final DateTime start;
  final DateTime? end;
  final bool allDay;

  const EventWhen({required this.start, this.end, this.allDay = false});

  static const _d = r'(\d{4})-(\d{2})-(\d{2})';
  static const _t = r'(\d{1,2}):(\d{2})';
  static final _dateOnly = RegExp('^$_d\$');
  static final _dateRange = RegExp('^$_d\\s*-\\s*$_d\$');
  static final _dateTime = RegExp('^$_d[ T]$_t\$');
  static final _sameDay = RegExp('^$_d[ T]$_t\\s*-\\s*$_t\$');
  static final _multiDay = RegExp('^$_d[ T]$_t\\s*-\\s*$_d[ T]$_t\$');

  static EventWhen? parse(String field) {
    final text = field.trim().replaceAll(RegExp(r'[–—]'), '-');
    var m = _dateOnly.firstMatch(text);
    if (m != null) {
      final d = _date(m, 1);
      return d == null ? null : EventWhen(start: d, allDay: true);
    }
    m = _dateRange.firstMatch(text);
    if (m != null) {
      final a = _date(m, 1), b = _date(m, 4);
      if (a == null || b == null || b.isBefore(a)) return null;
      return EventWhen(start: a, end: b, allDay: true);
    }
    m = _dateTime.firstMatch(text);
    if (m != null) {
      final s = _dateTimeOf(m, 1, 4);
      return s == null ? null : EventWhen(start: s);
    }
    m = _sameDay.firstMatch(text);
    if (m != null) {
      final s = _dateTimeOf(m, 1, 4);
      final e = s == null ? null : _withTime(s, m, 6);
      if (s == null || e == null) return null;
      return EventWhen(start: s, end: e.isAfter(s) ? e : e.add(const Duration(days: 1)));
    }
    m = _multiDay.firstMatch(text);
    if (m != null) {
      final s = _dateTimeOf(m, 1, 4);
      final e = _dateTimeOf(m, 6, 9);
      if (s == null || e == null || e.isBefore(s)) return null;
      return EventWhen(start: s, end: e);
    }
    return null;
  }

  static DateTime? _date(RegExpMatch m, int i) {
    final y = int.parse(m.group(i)!);
    final mo = int.parse(m.group(i + 1)!);
    final d = int.parse(m.group(i + 2)!);
    if (mo < 1 || mo > 12 || d < 1) return null;
    final out = DateTime(y, mo, d);
    return (out.month == mo && out.day == d) ? out : null;
  }

  static DateTime? _dateTimeOf(RegExpMatch m, int di, int ti) {
    final d = _date(m, di);
    return d == null ? null : _withTime(d, m, ti);
  }

  static DateTime? _withTime(DateTime d, RegExpMatch m, int ti) {
    final h = int.parse(m.group(ti)!);
    final min = int.parse(m.group(ti + 1)!);
    if (h > 23 || min > 59) return null;
    return DateTime(d.year, d.month, d.day, h, min);
  }

  /// When the event is over, for pinning: the end, else start plus an hour,
  /// else the end of the day for an all-day event.
  DateTime get effectiveEnd {
    if (end != null) {
      return allDay ? DateTime(end!.year, end!.month, end!.day + 1) : end!;
    }
    if (allDay) return DateTime(start.year, start.month, start.day + 1);
    return start.add(const Duration(hours: 1));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _dateText(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _timeText(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String toWire() {
    final e = end;
    if (allDay) {
      if (e == null || _sameDate(e, start)) return _dateText(start);
      return '${_dateText(start)} - ${_dateText(e)}';
    }
    final head = '${_dateText(start)} ${_timeText(start)}';
    if (e == null) return head;
    if (_sameDate(e, start)) return '$head-${_timeText(e)}';
    return '$head - ${_dateText(e)} ${_timeText(e)}';
  }
}

class LocationMessage extends StructuredMessage {
  @override
  final LatLng position;
  final String? label;
  final String? note;

  const LocationMessage({
    required this.position,
    this.label,
    this.note,
    super.link,
    super.extraText,
    super.extensions,
  });

  @override
  String get keyword => 'Location';

  @override
  String get summary =>
      label == null || label!.isEmpty ? 'Location' : 'Location: $label';

  @override
  String toWire() {
    final lines = <String>[];
    final head = label == null ? '' : StructuredMessage.sanitizeField(label!);
    if (head.isEmpty) {
      lines.add('Location: ${StructuredMessage.formatCoordinates(position)}');
    } else {
      lines.add('Location: $head');
      lines.add(StructuredMessage.formatCoordinates(position));
    }
    _appendCommon(lines, note: note, link: link, extraText: extraText, extensions: extensions);
    return lines.join('\n');
  }
}

class SosMessage extends StructuredMessage {
  @override
  final LatLng position;
  final String text;
  final String? note;

  const SosMessage({
    required this.position,
    required this.text,
    this.note,
    super.link,
    super.extraText,
    super.extensions,
  });

  @override
  String get keyword => 'SOS';

  @override
  String get summary => text.isEmpty ? 'SOS' : 'SOS: $text';

  @override
  String toWire() {
    final lines = <String>[
      'SOS: ${StructuredMessage.sanitizeField(text)}'.trimRight(),
      StructuredMessage.formatCoordinates(position),
    ];
    _appendCommon(lines, note: note, link: link, extraText: extraText, extensions: extensions);
    return lines.join('\n');
  }
}

class EventMessage extends StructuredMessage {
  final String title;
  final EventWhen when;
  final String? place;
  @override
  final LatLng? position;

  const EventMessage({
    required this.title,
    required this.when,
    this.place,
    this.position,
    super.link,
    super.extraText,
    super.extensions,
  });

  @override
  String get keyword => 'Event';

  @override
  String get summary => 'Event: $title';

  @override
  String toWire() {
    final lines = <String>[
      'Event: ${StructuredMessage.sanitizeField(title)}',
      when.toWire(),
    ];
    final p = place == null ? '' : StructuredMessage.sanitizeField(place!);
    if (p.isNotEmpty) lines.add(p);
    if (position != null) lines.add(StructuredMessage.formatCoordinates(position!));
    _appendCommon(lines, link: link, extraText: extraText, extensions: extensions);
    return lines.join('\n');
  }
}

class NoticeMessage extends StructuredMessage {
  /// The headline first, then any further lines.
  final List<String> lines;
  @override
  final LatLng? position;

  const NoticeMessage({
    required this.lines,
    this.position,
    super.link,
    super.extensions,
  });

  String get headline => lines.first;

  @override
  String get keyword => 'Notice';

  @override
  String get summary => 'Notice: $headline';

  @override
  String toWire() {
    final out = <String>['Notice: ${StructuredMessage.sanitizeField(lines.first)}'];
    for (final line in lines.skip(1)) {
      final s = StructuredMessage.sanitizeField(line);
      if (s.isNotEmpty) out.add(s);
    }
    if (position != null) out.add(StructuredMessage.formatCoordinates(position!));
    _appendCommon(out, link: link, extraText: const [], extensions: extensions);
    return out.join('\n');
  }
}

void _appendCommon(
  List<String> lines, {
  String? note,
  String? link,
  required List<String> extraText,
  required Map<String, String> extensions,
}) {
  final n = note == null ? '' : StructuredMessage.sanitizeField(note);
  if (n.isNotEmpty) lines.add(n);
  if (link != null && link.isNotEmpty) lines.add(link.trim());
  for (final e in extensions.entries) {
    lines.add('${e.key}=${StructuredMessage.sanitizeField(e.value)}');
  }
  for (final t in extraText) {
    final s = StructuredMessage.sanitizeField(t);
    if (s.isNotEmpty) lines.add(s);
  }
}
