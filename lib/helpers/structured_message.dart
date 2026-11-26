import 'package:latlong2/latlong.dart';

import '../models/radio_settings.dart';
import 'calendar_share.dart';
import 'maps_link.dart';
import 'meshcore_qr.dart';
import 'svg_drawing.dart';

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
    r'^(location|poi|sos|event|notice|svg|trax|repeater)\s*:\s*',
    caseSensitive: false,
  );

  static final _legacyMarker = RegExp(
    r'^m:([\-0-9.]+),([\-0-9.]+)\|([^|]*)(?:\|(.*))?$',
  );

  static final _leadingMention = RegExp(r'^@\[[^\]]+\][ \n]?');

  /// Another app's `loc: lat,lon`: read like bare coordinates, never sent.
  static final _locLine = RegExp(
    r'^loc:\s*(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)$',
    caseSensitive: false,
  );

  static LatLng? parseCoordinates(String field) {
    final m = coordinatePattern.firstMatch(field.trim());
    if (m == null || m.start != 0 || m.end != field.trim().length) return null;
    return _bounded(double.tryParse(m.group(1)!), double.tryParse(m.group(2)!));
  }

  static LatLng? _locCoordinates(String line) {
    final m = _locLine.firstMatch(line);
    if (m == null) return null;
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

  /// The `@[Name]` mentions a message starts with, as typed, or '' when it
  /// starts with none. A card hides the text around it, so a chat draws
  /// these above the card.
  static String leadingMentions(String text) {
    var rest = text.trimLeft();
    final found = <String>[];
    while (true) {
      final m = _leadingMention.firstMatch(rest);
      if (m == null || m.end == 0) break;
      found.add(m.group(0)!.trim());
      rest = rest.substring(m.end);
    }
    return found.join(' ');
  }

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
  static StructuredMessage? parse(String text, {DateTime? now}) {
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
    if (header == null) return _parseLoose(body, now);

    final keyword = header.group(1)!.toLowerCase();
    if (keyword == 'svg') return SvgMessage._fromHeader(body, header);
    if (keyword == 'trax') return TraxMessage._fromBody(body.substring(header.end));
    final fields = _splitFields(body.substring(header.end));
    if (keyword == 'repeater') return RepeaterStatusMessage._fromFields(fields);
    final sorted = _Fields.classify(fields);

    switch (keyword) {
      case 'location':
      case 'poi':
        if (sorted.position == null) return null;
        final extensions = Map.of(sorted.extensions);
        return LocationMessage(
          position: sorted.position!,
          label: sorted.freeText.isNotEmpty ? sorted.freeText[0] : null,
          note: sorted.freeText.length > 1 ? sorted.freeText[1] : null,
          link: sorted.link,
          extraText: sorted.freeText.skip(2).toList(),
          altitude: LocationMessage._take(extensions, 'alt', LocationMessage._metres),
          heading: LocationMessage._take(extensions, 'hdg', LocationMessage._degrees),
          speed: LocationMessage._take(extensions, 'spd', LocationMessage._metresPerSecond),
          extensions: extensions,
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
        // A date line is text here: a notice's date is its `expires=`.
        final lines = sorted.textAndDates;
        if (lines.isEmpty) return null;
        final extensions = Map.of(sorted.extensions);
        final expires = NoticeMessage.parseExpiry(extensions['expires']);
        if (expires != null) extensions.remove('expires');
        return NoticeMessage(
          lines: lines,
          position: sorted.position,
          link: sorted.link,
          extensions: extensions,
          expires: expires,
        );
    }
    return null;
  }

  /// A room server's own post (room.post): what [parse] makes of it, else
  /// the whole post as an announcement.
  static StructuredMessage? parseAnnouncement(String text, {DateTime? now}) {
    final parsed = parse(text, now: now);
    if (parsed != null) return parsed;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;
    return NoticeMessage(lines: lines, announcement: true);
  }

  /// Things other apps send without a keyword.
  static StructuredMessage? _parseLoose(String body, DateTime? now) {
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

    final share = ShareMessage.fromLines(lines);
    if (share != null) return share;

    LatLng? position;
    String? name;
    final free = <String>[];
    for (final line in lines) {
      final coords = parseCoordinates(line) ?? _locCoordinates(line);
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

  /// [freeText] with every date-shaped field kept in its place.
  final textAndDates = <String>[];
  final extensions = <String, String>{};

  static _Fields classify(List<String> fields) {
    final out = _Fields();
    for (final field in fields) {
      final coords = StructuredMessage.parseCoordinates(field);
      if (coords != null) {
        out.position ??= coords;
        continue;
      }
      if (MapsLink.isMapsUrl(field)) {
        final position = MapsLink.parse(field)?.position;
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
        out.textAndDates.add(field);
        continue;
      }
      final ext = StructuredMessage._extension.firstMatch(field);
      if (ext != null) {
        out.extensions[ext.group(1)!] = ext.group(2)!.trim();
        continue;
      }
      out.freeText.add(field);
      out.textAndDates.add(field);
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

  /// Calendar days the event spans: 3 for Oct 20 – 22. An overnight event
  /// shorter than a day (22:00 – 02:00) counts as one.
  int get dayCount {
    final e = end;
    if (e == null) return 1;
    if (!allDay && e.difference(start) < const Duration(days: 1)) return 1;
    return daysBetween(start, e) + 1;
  }

  /// Whole calendar days from [a] to [b], DST-proof.
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

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
  /// The title that makes a location the sender's own position. Always
  /// English on the air; readers show it in their language ("My location",
  /// "GWQ's location"). A location with any other title, or none, is just
  /// a place (owner, 2026-10-27).
  static const myLocationLabel = 'My location';

  @override
  final LatLng position;
  final String? label;
  final String? note;

  /// Metres above sea level, from the sender's GPS: `alt=35m`.
  final double? altitude;

  /// Degrees clockwise from north, while moving: `hdg=270`.
  final double? heading;

  /// Metres a second, 0 standing still: `spd=15km/h` on the air.
  final double? speed;

  const LocationMessage({
    required this.position,
    this.label,
    this.note,
    this.altitude,
    this.heading,
    this.speed,
    super.link,
    super.extraText,
    super.extensions,
  });

  /// The sender's own position: titled [myLocationLabel], in any case.
  bool get isSendersOwn =>
      label?.trim().toLowerCase() == myLocationLabel.toLowerCase();

  /// Standing still: a speed of 0 and no heading.
  bool get isStill => speed == 0 && heading == null;

  /// The value under [key] read by [read], taken out of [extensions]; a
  /// value it can't read stays there, shown as sent.
  static double? _take(
    Map<String, String> extensions,
    String key,
    double? Function(String) read,
  ) {
    final raw = extensions[key];
    final value = raw == null ? null : read(raw.trim().toLowerCase());
    if (value != null) extensions.remove(key);
    return value;
  }

  static final _number = RegExp(r'^(-?\d+(?:\.\d+)?)\s*(.*)$');

  static double? _metres(String raw) {
    final m = _number.firstMatch(raw);
    if (m == null) return null;
    final v = double.parse(m.group(1)!);
    return switch (m.group(2)) {
      '' || 'm' => v,
      'ft' => v * 0.3048,
      _ => null,
    };
  }

  static double? _degrees(String raw) {
    final m = _number.firstMatch(raw);
    if (m == null || (m.group(2) != '' && m.group(2) != '°')) return null;
    final v = double.parse(m.group(1)!);
    return v < 0 || v > 360 ? null : v % 360;
  }

  static double? _metresPerSecond(String raw) {
    final m = _number.firstMatch(raw);
    if (m == null) return null;
    final v = double.parse(m.group(1)!);
    if (v < 0) return null;
    return switch (m.group(2)) {
      '' || 'km/h' => v / 3.6,
      'mph' => v * 0.44704,
      'kn' || 'kt' => v * 0.514444,
      'm/s' => v,
      _ => null,
    };
  }

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
    _appendCommon(
      lines,
      note: note,
      link: link,
      extraText: extraText,
      extensions: {
        if (altitude case final a?) 'alt': '${a.round()}m',
        if (heading case final h?) 'hdg': '${h.round() % 360}',
        if (speed case final v?) 'spd': '${(v * 3.6).round()}km/h',
        ...extensions,
      },
    );
    return lines.join('\n');
  }
}

class SosMessage extends StructuredMessage {
  /// A receiver's answer, sent as a reply to the SOS. Always English on the
  /// air, like [LocationMessage.myLocationLabel]. Any reply to an SOS tells
  /// its sender that one more person got it.
  static const gotItText = 'Got it';

  /// What the sender's Cancel sends. Always English on the air; readers
  /// turn that sender's open SOS cards into cancelled ones.
  static const cancelText = 'SOS cancelled';

  static final _cancel = RegExp(r'^sos cancell?ed[.!]*$', caseSensitive: false);

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

  /// Whether [text] cancels its sender's SOS: a first line of
  /// [cancelText], in any case, `canceled` too, as anyone can type it.
  static bool isCancel(String text) => _cancel.hasMatch(
        StructuredMessage.stripMarkup(text).split('\n').first.trim(),
      );

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

  /// When the notice stops applying, from its `expires=` field. A date
  /// alone means the end of that day, so it is held as the next midnight.
  final DateTime? expires;

  /// A room server's post that is not in this format: the whole post as
  /// plain lines. Never on the wire.
  final bool announcement;

  const NoticeMessage({
    required this.lines,
    this.position,
    super.link,
    super.extensions,
    this.expires,
    this.announcement = false,
  });

  String get headline => lines.first;

  bool isExpired(DateTime now) => expires != null && !expires!.isAfter(now);

  /// Whether [expires] came from a date with no time.
  bool get expiresAtDayEnd =>
      expires != null && expires!.hour == 0 && expires!.minute == 0;

  /// The day an end-of-day expiry names: the day before [expires].
  DateTime get expiryDay => expiresAtDayEnd
      ? DateTime(expires!.year, expires!.month, expires!.day - 1)
      : expires!;

  static DateTime? parseExpiry(String? field) {
    if (field == null) return null;
    final when = EventWhen.parse(field);
    if (when == null || when.end != null) return null;
    final s = when.start;
    return when.allDay ? DateTime(s.year, s.month, s.day + 1) : s;
  }

  String _expiryWire() {
    final day = expiryDay;
    if (expiresAtDayEnd) return EventWhen._dateText(day);
    return '${EventWhen._dateText(day)} ${EventWhen._timeText(day)}';
  }

  @override
  String get keyword => 'Notice';

  @override
  String get summary => announcement ? headline : 'Notice: $headline';

  @override
  String toWire() {
    final out = <String>['Notice: ${StructuredMessage.sanitizeField(lines.first)}'];
    for (final line in lines.skip(1)) {
      final s = StructuredMessage.sanitizeField(line);
      if (s.isNotEmpty) out.add(s);
    }
    if (position != null) out.add(StructuredMessage.formatCoordinates(position!));
    _appendCommon(
      out,
      link: link,
      extraText: const [],
      extensions: {
        if (expires != null) 'expires': _expiryWire(),
        ...extensions,
      },
    );
    return out.join('\n');
  }
}

/// A drawing as SVG path data: `SVG:M10 10h80v80H10z`, then an optional
/// caption line. Other apps show the path data, which any SVG path viewer
/// draws.
class SvgMessage extends StructuredMessage {
  final SvgDrawing drawing;

  const SvgMessage(this.drawing);

  static SvgMessage? _fromHeader(String body, RegExpMatch header) {
    // The path starts on the header's line: path data that a line break
    // pushed down isn't one of ours.
    if (header.group(0)!.contains('\n')) return null;
    final drawing = SvgDrawing.tryParse(body.substring(header.end));
    return drawing == null ? null : SvgMessage(drawing);
  }

  /// Whether [text] is a drawing. Reads no further than the keyword for
  /// anything else, so a list row can ask.
  static bool isDrawing(String text) {
    final body = StructuredMessage.stripMarkup(text);
    final header = StructuredMessage._header.firstMatch(body);
    return header != null &&
        header.group(1)!.toLowerCase() == 'svg' &&
        _fromHeader(body, header) != null;
  }

  /// None, even over a map: drawings aren't pins on the Map tab (Martin,
  /// 2026-11-02).
  @override
  LatLng? get position => null;

  @override
  String get keyword => 'SVG';

  @override
  String get summary => 'Drawing';

  @override
  String toWire() => [
        'SVG:${drawing.pathData}',
        ?drawing.map?.toLine(),
        if (drawing.caption.isNotEmpty) drawing.caption,
      ].join('\n');
}

/// TRAX mode's Tell the group, MeshTrax only for now:
///
/// ```
/// TRAX: on until 2026-11-22 18:00 UTC-8
/// 918.000 MHz 62.5 kHz SF7 CR5
/// ```
///
/// or `TRAX: off` when the sender is leaving. The end is the sender's wall
/// clock with its offset from UTC, so every reader knows the same instant
/// and a person reads the sender's time. Anything malformed is plain text:
/// a message that could move a radio is read strictly.
class TraxMessage extends StructuredMessage {
  final bool on;

  /// The end of the trip, in UTC. Null when leaving.
  final DateTime? until;

  /// The sender's offset from UTC at [until], in minutes.
  final int utcOffsetMinutes;

  /// The TRAX preset: frequency, bandwidth, SF and CR. Off-Grid Repeat is
  /// always on in TRAX mode. Null when leaving.
  final LoRaParams? preset;

  const TraxMessage._({
    required this.on,
    this.until,
    this.utcOffsetMinutes = 0,
    this.preset,
    super.extraText,
  });

  /// Switching, until [until] (any zone; written in its local zone).
  factory TraxMessage.switching({
    required DateTime until,
    required LoRaParams preset,
  }) {
    final local = until.toLocal();
    return TraxMessage._(
      on: true,
      until: local.toUtc(),
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
      preset: preset,
    );
  }

  const TraxMessage.leaving() : this._(on: false);

  static final _onLine = RegExp(
    r'^on until (\d{4})-(\d{2})-(\d{2}) (\d{1,2}):(\d{2}) '
    r'UTC(?:([+-])(\d{1,2})(?::(\d{2}))?)?$',
    caseSensitive: false,
  );

  static final _presetLine = RegExp(
    r'^(\d{3,4}\.\d{1,3}) MHz (\d{1,3}(?:\.\d{1,2})?) kHz SF(\d{1,2}) CR(\d)$',
    caseSensitive: false,
  );

  static TraxMessage? _fromBody(String rest) {
    final lines = rest
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;
    final head = lines.first;
    if (head.toLowerCase() == 'off') {
      return TraxMessage._(on: false, extraText: lines.skip(1).toList());
    }
    final m = _onLine.firstMatch(head);
    if (m == null) return null;
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    final h = int.parse(m.group(4)!), min = int.parse(m.group(5)!);
    if (mo < 1 || mo > 12 || d < 1 || h > 23 || min > 59) return null;
    final wall = DateTime.utc(y, mo, d, h, min);
    if (wall.month != mo || wall.day != d) return null;
    var offset = 0;
    if (m.group(6) != null) {
      final hours = int.parse(m.group(7)!);
      final minutes = int.parse(m.group(8) ?? '0');
      if (hours > 14 || minutes > 59) return null;
      offset = (hours * 60 + minutes) * (m.group(6) == '-' ? -1 : 1);
    }
    LoRaParams? preset;
    final extra = <String>[];
    for (final line in lines.skip(1)) {
      final p = preset == null ? _presetLine.firstMatch(line) : null;
      if (p == null) {
        extra.add(line);
        continue;
      }
      final khz = double.parse(p.group(2)!);
      preset = LoRaParams(
        freqKhz: (double.parse(p.group(1)!) * 1000).round(),
        bwHz: (khz * 1000).round(),
        sf: int.parse(p.group(3)!),
        cr: int.parse(p.group(4)!),
      );
      if (!preset.isValid) return null;
    }
    if (preset == null) return null;
    return TraxMessage._(
      on: true,
      until: wall.subtract(Duration(minutes: offset)),
      utcOffsetMinutes: offset,
      preset: preset,
      extraText: extra,
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _untilWire() {
    final wall = until!.add(Duration(minutes: utcOffsetMinutes));
    final off = utcOffsetMinutes.abs();
    final zone = utcOffsetMinutes == 0
        ? 'UTC'
        : 'UTC${utcOffsetMinutes < 0 ? '-' : '+'}${off ~/ 60}'
              '${off % 60 == 0 ? '' : ':${_two(off % 60)}'}';
    return '${wall.year}-${_two(wall.month)}-${_two(wall.day)} '
        '${_two(wall.hour)}:${_two(wall.minute)} $zone';
  }

  @override
  LatLng? get position => null;

  @override
  String get keyword => 'TRAX';

  @override
  String get summary => on ? 'TRAX mode on' : 'TRAX mode off';

  @override
  String toWire() => [
        on ? 'TRAX: on until ${_untilWire()}' : 'TRAX: off',
        if (on) preset!.wireText,
        for (final t in extraText)
          if (StructuredMessage.sanitizeField(t) case final s
              when s.isNotEmpty)
            s,
      ].join('\n');
}

/// How a repeater's battery stands, best to worst.
enum RepeaterStage { ok, low, vlow, crit }

/// What a repeater's line says about it, for its icon and the card's
/// title: a [RepeaterStage], or no level at all.
enum RepeaterState { unreachable, crit, vlow, low, noReading, waiting, ok, other }

/// One repeater's field in a [RepeaterStatusMessage]: its name, then any of
/// volts, stage and age, `key=value` pairs, and a note.
class RepeaterReport {
  final String name;

  /// The last reading as written, e.g. "3.52"; null when there is none.
  final String? volts;
  final RepeaterStage? stage;

  /// How old the reading is.
  final Duration? age;
  final bool waiting;
  final bool unreachable;
  final bool noReading;

  /// `key=value` pairs in the order sent, known or not.
  final Map<String, String> keys;
  final String? note;

  const RepeaterReport({
    required this.name,
    this.volts,
    this.stage,
    this.age,
    this.waiting = false,
    this.unreachable = false,
    this.noReading = false,
    this.keys = const {},
    this.note,
  });

  static final _startsLikeName = RegExp(r'^[\p{L}\p{N}]', unicode: true);
  static final _volts = RegExp(r'^(\d{1,2}\.\d{1,3})V$', caseSensitive: false);
  static final _age = RegExp(r'^(\d{1,4})([mhd])$');
  static final _key = RegExp(r'^([a-z][a-z0-9_]*)=(\S*)$');

  /// A field about one repeater, or null when it doesn't start with a
  /// letter or digit: such a field is plain text.
  static RepeaterReport? parse(String field) {
    final words = field.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty || !_startsLikeName.hasMatch(words.first)) return null;
    String? volts;
    RepeaterStage? stage;
    Duration? age;
    var waiting = false, unreachable = false, noReading = false;
    final keys = <String, String>{};
    final note = <String>[];
    final rest = words.skip(1).toList();
    for (var i = 0; i < rest.length; i++) {
      final word = rest[i];
      if (_key.firstMatch(word) case final key?) {
        keys[key.group(1)!] = key.group(2)!;
        continue;
      }
      // Volts, stage, age and the fixed words come before the note.
      if (note.isEmpty) {
        final lower = word.toLowerCase();
        if (_volts.firstMatch(word) case final v? when volts == null) {
          volts = v.group(1);
          continue;
        }
        if (stageOf(lower) case final s? when stage == null) {
          stage = s;
          continue;
        }
        if (ageOf(word) case final a? when age == null) {
          age = a;
          continue;
        }
        if (lower == 'waiting') {
          waiting = true;
          continue;
        }
        if (lower == 'unreachable') {
          unreachable = true;
          continue;
        }
        if (lower == 'no' &&
            i + 1 < rest.length &&
            rest[i + 1].toLowerCase() == 'reading') {
          noReading = true;
          i++;
          continue;
        }
      }
      note.add(word);
    }
    return RepeaterReport(
      name: words.first,
      volts: volts,
      stage: stage,
      age: age,
      waiting: waiting,
      unreachable: unreachable,
      noReading: noReading,
      keys: keys,
      note: note.isEmpty ? null : note.join(' '),
    );
  }

  /// ok, low, vlow or crit, any case.
  static RepeaterStage? stageOf(String word) => switch (word.toLowerCase()) {
        'ok' => RepeaterStage.ok,
        'low' => RepeaterStage.low,
        'vlow' => RepeaterStage.vlow,
        'crit' => RepeaterStage.crit,
        _ => null,
      };

  /// 2m, 3h or 2d.
  static Duration? ageOf(String word) {
    final m = _age.firstMatch(word);
    if (m == null) return null;
    final n = int.parse(m.group(1)!);
    return switch (m.group(2)) {
      'm' => Duration(minutes: n),
      'h' => Duration(hours: n),
      _ => Duration(days: n),
    };
  }

  RepeaterState get state {
    if (unreachable) return RepeaterState.unreachable;
    if (noReading) return RepeaterState.noReading;
    if (waiting) return RepeaterState.waiting;
    return switch (stage) {
      RepeaterStage.crit => RepeaterState.crit,
      RepeaterStage.vlow => RepeaterState.vlow,
      RepeaterStage.low => RepeaterState.low,
      RepeaterStage.ok => RepeaterState.ok,
      null => RepeaterState.other,
    };
  }
}

/// How a group of repeaters stands (docs/message-format.md, "Repeater
/// status"): `Repeater: ` then one field per repeater, separated by `|`.
/// A field that starts with anything but a letter or digit is plain text,
/// and so is a message with no repeater in it. MeshTrax reads these and
/// never writes one.
class RepeaterStatusMessage extends StructuredMessage {
  final List<RepeaterReport> repeaters;

  /// This message's page of a status sent in several, from `page=k/n`.
  final int? page;
  final int? pages;

  /// From `dryrun=yes`: the sender only simulates what it reports.
  final bool dryRun;

  final String _wire;

  const RepeaterStatusMessage._(
    this._wire, {
    required this.repeaters,
    this.page,
    this.pages,
    this.dryRun = false,
    super.extraText,
    super.extensions,
  });

  static final _page = RegExp(r'^page=(\d{1,3})/(\d{1,3})$');

  static RepeaterStatusMessage? _fromFields(List<String> fields) {
    final repeaters = <RepeaterReport>[];
    final text = <String>[];
    final extensions = <String, String>{};
    int? page, pages;
    var dryRun = false;
    for (final field in fields) {
      if (_page.firstMatch(field) case final p?) {
        page = int.parse(p.group(1)!);
        pages = int.parse(p.group(2)!);
        continue;
      }
      if (StructuredMessage._extension.firstMatch(field) case final e?) {
        final value = e.group(2)!.trim();
        if (e.group(1) == 'dryrun' && value == 'yes') {
          dryRun = true;
        } else {
          extensions[e.group(1)!] = value;
        }
        continue;
      }
      if (RepeaterReport.parse(field) case final report?) {
        repeaters.add(report);
      } else {
        text.add(field);
      }
    }
    if (repeaters.isEmpty) return null;
    return RepeaterStatusMessage._(
      'Repeater: ${fields.join(' | ')}',
      repeaters: repeaters,
      page: page,
      pages: pages,
      dryRun: dryRun,
      extraText: text,
      extensions: extensions,
    );
  }

  /// How many repeaters stand in each state, worst first; repeaters with
  /// no state left out.
  List<(RepeaterState, int)> get counts => [
        for (final s in RepeaterState.values)
          if (s != RepeaterState.other)
            if (repeaters.where((r) => r.state == s).length case final n
                when n > 0)
              (s, n),
      ];

  @override
  LatLng? get position => null;

  @override
  String get keyword => 'Repeater';

  @override
  String get summary {
    String word(RepeaterState s) => switch (s) {
          RepeaterState.unreachable => 'unreachable',
          RepeaterState.crit => 'critical',
          RepeaterState.vlow => 'very low',
          RepeaterState.low => 'low',
          RepeaterState.noReading => 'no reading',
          RepeaterState.waiting => 'waiting',
          RepeaterState.ok => 'OK',
          RepeaterState.other => '',
        };
    final title = repeaters.length <= 2
        ? repeaters
            .map((r) => r.state == RepeaterState.other
                ? r.name
                : '${r.name} ${word(r.state)}')
            .join(', ')
        : counts.isEmpty
            ? '${repeaters.length} repeaters'
            : counts.map((c) => '${c.$2} ${word(c.$1)}').join(', ');
    return 'Repeater status: $title';
  }

  @override
  String toWire() => _wire;
}

/// What a meshcore:// share link adds to the radio.
enum ShareKind { channel, contact, repeater, room, sensor }

/// A `meshcore://channel/add` or `meshcore://contact/add` link, or another
/// app's `<public key:type:name>`, alone or with up to two lines of text
/// around it, shown as a card with a join or add button. A link inside a
/// longer message stays a tappable link.
class ShareMessage extends StructuredMessage {
  final ShareKind kind;
  final String name;

  /// The channel secret, or the contact's public key, as the link carries it.
  final String keyHex;

  /// The link itself, handed to the existing join and import code.
  final String url;
  final String? note;

  /// Another app's `<public key:type:name>` line as it came; [url] is the
  /// contact/add link it amounts to.
  final String? textForm;

  const ShareMessage({
    required this.kind,
    required this.name,
    required this.keyHex,
    required this.url,
    this.note,
    this.textForm,
    super.extraText,
  });

  static final _link = RegExp(r'^meshcore://\S+$', caseSensitive: false);

  /// The share in [lines] when exactly one of them is a valid meshcore://
  /// link; the other lines become the note.
  static ShareMessage? fromLines(List<String> lines) {
    final links = lines
        .where(
          (l) => _link.hasMatch(l) || MeshCoreQr.parseContactText(l) != null,
        )
        .toList();
    if (links.length != 1) return null;
    final line = links.single;
    final text = MeshCoreQr.parseContactText(line);
    final url = text == null
        ? line
        : MeshCoreQr.encodeContact(text.name, text.pubKeyHex, text.type);
    final ShareKind kind;
    final String name;
    final String keyHex;
    try {
      final channel = MeshCoreQr.parseChannelQr(url);
      final contact = channel == null ? MeshCoreQr.parseContactQr(url) : null;
      if (channel != null) {
        kind = ShareKind.channel;
        name = channel.name;
        keyHex = channel.pskHex;
      } else if (contact != null) {
        // advType* in meshcore_protocol.dart.
        kind = switch (contact.type) {
          2 => ShareKind.repeater,
          3 => ShareKind.room,
          4 => ShareKind.sensor,
          _ => ShareKind.contact,
        };
        name = contact.name;
        keyHex = contact.pubKeyHex;
      } else {
        return null;
      }
    } catch (_) {
      // A malformed query (bad % escape) is just text.
      return null;
    }
    final free = lines.where((l) => l != line).toList();
    return ShareMessage(
      kind: kind,
      name: name.trim(),
      keyHex: keyHex,
      url: url,
      note: free.isNotEmpty ? free.first : null,
      textForm: text == null ? null : line,
      extraText: free.skip(1).toList(),
    );
  }

  @override
  LatLng? get position => null;

  @override
  String get keyword => switch (kind) {
        ShareKind.channel => 'Channel',
        ShareKind.contact => 'Contact',
        ShareKind.repeater => 'Repeater',
        ShareKind.room => 'Room',
        ShareKind.sensor => 'Sensor',
      };

  @override
  String get summary => name.isEmpty ? keyword : '$keyword: $name';

  @override
  String toWire() => [?note, textForm ?? url, ...extraText].join('\n');
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
