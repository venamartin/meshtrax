import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/structured_message.dart';
import 'platform_info.dart';

/// Puts an event into the device calendar: the native insert flow on
/// phones, a generated .ics opened with the default calendar app on desktop.
class CalendarExport {
  static Future<bool> addEvent(EventMessage event) async {
    final when = event.when;
    final end = when.end ?? when.effectiveEnd;
    final location = [
      if (event.place != null && event.place!.isNotEmpty) event.place!,
      if (event.position != null)
        StructuredMessage.formatCoordinates(event.position!),
    ].join(', ');
    final description = [
      if (event.link != null) event.link!,
      ...event.extraText,
    ].join('\n');

    if (PlatformInfo.isMobile) {
      final e = cal.Event(
        title: event.title,
        description: description,
        location: location,
        startDate: when.start,
        endDate: end,
        allDay: when.allDay,
      );
      return cal.Add2Calendar.addEvent2Cal(e);
    }

    final ics = buildIcs(
      title: event.title,
      start: when.start,
      end: end,
      allDay: when.allDay,
      location: location,
      description: description,
      position: event.position,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/meshtrax-event.ics');
    await file.writeAsString(ics);
    return launchUrl(Uri.file(file.path));
  }

  static String buildIcs({
    required String title,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String location = '',
    String description = '',
    LatLng? position,
  }) {
    final uid =
        'meshtrax-${start.millisecondsSinceEpoch}-${title.hashCode}@meshtrax';
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//MeshTrax//Event//EN',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_utcStamp(DateTime.now().toUtc())}',
      if (allDay) 'DTSTART;VALUE=DATE:${_date(start)}',
      if (allDay) 'DTEND;VALUE=DATE:${_date(end)}',
      if (!allDay) 'DTSTART:${_local(start)}',
      if (!allDay) 'DTEND:${_local(end)}',
      'SUMMARY:${_escape(title)}',
      if (location.isNotEmpty) 'LOCATION:${_escape(location)}',
      if (description.isNotEmpty) 'DESCRIPTION:${_escape(description)}',
      if (position != null)
        'GEO:${position.latitude.toStringAsFixed(6)};${position.longitude.toStringAsFixed(6)}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return '${lines.join('\r\n')}\r\n';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';
  static String _local(DateTime d) =>
      '${_date(d)}T${_two(d.hour)}${_two(d.minute)}00';
  static String _utcStamp(DateTime d) => '${_local(d)}Z';
  static String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');
}
