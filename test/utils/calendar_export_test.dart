import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/utils/calendar_export.dart';

void main() {
  test('timed event uses floating local time', () {
    final ics = CalendarExport.buildIcs(
      title: 'Mesh meetup',
      start: DateTime(2026, 10, 18, 14, 0),
      end: DateTime(2026, 10, 18, 16, 30),
      allDay: false,
      location: 'Hauptplatz, Graz',
      description: 'https://example.org',
      position: const LatLng(47.070123, 15.440123),
    );
    expect(ics, contains('DTSTART:20261018T140000\r\n'));
    expect(ics, contains('DTEND:20261018T163000\r\n'));
    expect(ics, contains('SUMMARY:Mesh meetup\r\n'));
    expect(ics, contains('LOCATION:Hauptplatz\\, Graz\r\n'));
    expect(ics, contains('GEO:47.070123;15.440123\r\n'));
    expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));
  });

  test('all-day event uses DATE values', () {
    final ics = CalendarExport.buildIcs(
      title: 'Fieldday',
      start: DateTime(2026, 10, 18),
      end: DateTime(2026, 10, 20),
      allDay: true,
    );
    expect(ics, contains('DTSTART;VALUE=DATE:20261018\r\n'));
    expect(ics, contains('DTEND;VALUE=DATE:20261020\r\n'));
    expect(ics, isNot(contains('LOCATION')));
  });
}
