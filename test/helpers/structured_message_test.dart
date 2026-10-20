import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/structured_message.dart';

void main() {
  const graz = '47.070123, 15.440123';

  group('Location', () {
    test('coordinates only', () {
      final m = StructuredMessage.parse('Location: $graz');
      expect(m, isA<LocationMessage>());
      final loc = m as LocationMessage;
      expect(loc.position, const LatLng(47.070123, 15.440123));
      expect(loc.label, isNull);
      expect(loc.toWire(), 'Location: $graz');
      expect(loc.summary, 'Location');
    });

    test('label then coordinates, newline separated', () {
      final loc = StructuredMessage.parse('Location: SCCARC Picnic\n$graz')
          as LocationMessage;
      expect(loc.label, 'SCCARC Picnic');
      expect(loc.toWire(), 'Location: SCCARC Picnic\n$graz');
      expect(loc.summary, 'Location: SCCARC Picnic');
    });

    test('pipe separated and reordered fields', () {
      final loc = StructuredMessage.parse(
        'location: $graz | Water tap | behind the hut',
      ) as LocationMessage;
      expect(loc.label, 'Water tap');
      expect(loc.note, 'behind the hut');
      expect(loc.toWire(), 'Location: Water tap\n$graz\nbehind the hut');
    });

    test('POI alias and mixed separators', () {
      final loc = StructuredMessage.parse('POI: Pub | $graz\nnote')
          as LocationMessage;
      expect(loc.label, 'Pub');
      expect(loc.note, 'note');
    });

    test('needs a position', () {
      expect(StructuredMessage.parse('Location: home'), isNull);
    });

    test('rejects out-of-range coordinates', () {
      expect(StructuredMessage.parse('Location: 91.000, 15.000'), isNull);
      expect(StructuredMessage.parse('Location: 47.000, 181.000'), isNull);
    });

    test('maps link as the position field', () {
      final loc = StructuredMessage.parse(
        'Location: Hauptplatz\nhttps://www.google.com/maps?q=47.0707,15.4395',
      ) as LocationMessage;
      expect(loc.position, const LatLng(47.0707, 15.4395));
      expect(loc.label, 'Hauptplatz');
    });

    test('sanitises pipes and newlines in free text when building', () {
      const loc = LocationMessage(
        position: LatLng(47.070123, 15.440123),
        label: 'A | B\nC',
      );
      expect(loc.toWire(), 'Location: A / B C\n$graz');
      expect(StructuredMessage.parse(loc.toWire()), isA<LocationMessage>());
    });
  });

  group('SOS', () {
    test('round trip', () {
      const sos = SosMessage(
        position: LatLng(47.070123, 15.440123),
        text: 'Broken leg, need help',
      );
      expect(sos.toWire(), 'SOS: Broken leg, need help\n$graz');
      final back = StructuredMessage.parse(sos.toWire()) as SosMessage;
      expect(back.text, 'Broken leg, need help');
      expect(back.position, sos.position);
      expect(back.summary, 'SOS: Broken leg, need help');
    });

    test('needs a position', () {
      expect(StructuredMessage.parse('SOS: help'), isNull);
    });
  });

  group('Event', () {
    test('full event round trip', () {
      final e = EventMessage(
        title: 'Mesh meetup',
        when: EventWhen(
          start: DateTime(2026, 10, 18, 14, 0),
          end: DateTime(2026, 10, 18, 16, 0),
        ),
        place: 'Hauptplatz',
        position: const LatLng(47.070123, 15.440123),
      );
      expect(
        e.toWire(),
        'Event: Mesh meetup\n2026-10-18 14:00-16:00\nHauptplatz\n$graz',
      );
      final back = StructuredMessage.parse(e.toWire()) as EventMessage;
      expect(back.title, 'Mesh meetup');
      expect(back.when.start, DateTime(2026, 10, 18, 14));
      expect(back.when.end, DateTime(2026, 10, 18, 16));
      expect(back.when.allDay, isFalse);
      expect(back.place, 'Hauptplatz');
      expect(back.position, e.position);
      expect(back.summary, 'Event: Mesh meetup');
    });

    test('every when shape', () {
      final cases = <String, EventWhen>{
        '2026-10-18': EventWhen(start: DateTime(2026, 10, 18), allDay: true),
        '2026-10-18 - 2026-10-19': EventWhen(
          start: DateTime(2026, 10, 18),
          end: DateTime(2026, 10, 19),
          allDay: true,
        ),
        '2026-10-18 14:00': EventWhen(start: DateTime(2026, 10, 18, 14)),
        '2026-10-18 14:00-16:00': EventWhen(
          start: DateTime(2026, 10, 18, 14),
          end: DateTime(2026, 10, 18, 16),
        ),
        '2026-10-18 22:00 - 2026-10-19 02:00': EventWhen(
          start: DateTime(2026, 10, 18, 22),
          end: DateTime(2026, 10, 19, 2),
        ),
      };
      cases.forEach((wire, expected) {
        final parsed = EventWhen.parse(wire);
        expect(parsed, isNotNull, reason: wire);
        expect(parsed!.start, expected.start, reason: wire);
        expect(parsed.end, expected.end, reason: wire);
        expect(parsed.allDay, expected.allDay, reason: wire);
        expect(parsed.toWire(), wire);
      });
    });

    test('tolerant when forms', () {
      expect(EventWhen.parse('2026-10-18T14:00')!.start,
          DateTime(2026, 10, 18, 14));
      expect(EventWhen.parse('2026-10-18 14:00 – 16:00')!.end,
          DateTime(2026, 10, 18, 16));
      expect(EventWhen.parse('2026-10-18 9:05')!.start,
          DateTime(2026, 10, 18, 9, 5));
      expect(EventWhen.parse('2026-13-18'), isNull);
      expect(EventWhen.parse('2026-02-30'), isNull);
      expect(EventWhen.parse('2026-10-18 25:00'), isNull);
    });

    test('reordered and partial lines', () {
      final a = StructuredMessage.parse('Event: 2026-10-18 14:00\nMesh meetup')
          as EventMessage;
      expect(a.title, 'Mesh meetup');
      expect(a.place, isNull);
      final b = StructuredMessage.parse(
        'Event: Fieldday | 2026-10-18 - 2026-10-19 | Schöckl',
      ) as EventMessage;
      expect(b.when.allDay, isTrue);
      expect(b.place, 'Schöckl');
    });

    test('a casual sentence stays plain', () {
      expect(StructuredMessage.parse('Event: see you at 5'), isNull);
    });

    test('link, unknown extension and extra text are kept', () {
      final e = StructuredMessage.parse(
        'Event: Meetup\n2026-10-18\nalt=420\nhttps://example.org/x\nbring cake\nand chairs',
      ) as EventMessage;
      expect(e.link, 'https://example.org/x');
      expect(e.extensions, {'alt': '420'});
      expect(e.place, 'bring cake');
      expect(e.extraText, ['and chairs']);
      expect(
        e.toWire(),
        'Event: Meetup\n2026-10-18\nbring cake\nhttps://example.org/x\nalt=420\nand chairs',
      );
    });

    test('effectiveEnd for pinning', () {
      expect(
        EventWhen(start: DateTime(2026, 10, 18, 14)).effectiveEnd,
        DateTime(2026, 10, 18, 15),
      );
      expect(
        EventWhen(start: DateTime(2026, 10, 18), allDay: true).effectiveEnd,
        DateTime(2026, 10, 19),
      );
    });
  });

  group('Notice', () {
    test('headline and further lines', () {
      final n = StructuredMessage.parse(
        'Notice: Repeater F857 down Saturday\nBack Sunday noon',
      ) as NoticeMessage;
      expect(n.headline, 'Repeater F857 down Saturday');
      expect(n.lines, ['Repeater F857 down Saturday', 'Back Sunday noon']);
      expect(n.summary, 'Notice: Repeater F857 down Saturday');
      expect(n.toWire(), 'Notice: Repeater F857 down Saturday\nBack Sunday noon');
    });

    test('empty notice is plain', () {
      expect(StructuredMessage.parse('Notice:'), isNull);
    });
  });

  group('markup and prefixes', () {
    test('parses after a mention and after reply markup', () {
      expect(StructuredMessage.parse('@[Bob] Location: $graz'),
          isA<LocationMessage>());
      expect(StructuredMessage.parse('@[Bob]\n>hi there..\nLocation: $graz'),
          isA<LocationMessage>());
      expect(StructuredMessage.parse('@[Bob] re:hi there…Location: $graz'),
          isA<LocationMessage>());
    });

    test('hasPrefix looks past a mention', () {
      expect(StructuredMessage.hasPrefix('@[Bob] Event: x'), isTrue);
      expect(StructuredMessage.hasPrefix('m:47.1,15.4|x|poi'), isTrue);
      expect(StructuredMessage.hasPrefix('hello'), isFalse);
      expect(StructuredMessage.hasPrefix(graz), isFalse);
    });

    test('unknown keyword stays plain', () {
      expect(StructuredMessage.parse('Alert: $graz'), isNull);
    });
  });

  group('inbound without keyword', () {
    test('legacy m: markers from meshcore-open and MeshTrax', () {
      final a = StructuredMessage.parse('m:47.070123,15.440123|Parking|poi')
          as LocationMessage;
      expect(a.label, 'Parking');
      expect(a.position, const LatLng(47.070123, 15.440123));
      final b = StructuredMessage.parse('m:47.070123,15.440123||poi')
          as LocationMessage;
      expect(b.label, isNull);
      expect(StructuredMessage.parse('m:91,0|x|poi'), isNull);
    });

    test('bare coordinates, with and without a label line', () {
      final a = StructuredMessage.parse(graz) as LocationMessage;
      expect(a.label, isNull);
      final b = StructuredMessage.parse('Hauptplatz\n$graz') as LocationMessage;
      expect(b.label, 'Hauptplatz');
    });

    test('maps links and geo URIs', () {
      final g = StructuredMessage.parse(
        'https://www.google.com/maps/place/Hauptplatz/@47.0707,15.4395,17z',
      ) as LocationMessage;
      expect(g.label, 'Hauptplatz');
      final geo = StructuredMessage.parse('geo:47.0707,15.4395') as LocationMessage;
      expect(geo.position, const LatLng(47.0707, 15.4395));
    });

    test('short link waits for the resolver', () {
      const url = 'https://maps.app.goo.gl/AbCdEf';
      expect(StructuredMessage.parse(url), isNull);
      final resolved = StructuredMessage.parse(
        url,
        resolveShortLink: (u) => u == url ? const LatLng(47.07, 15.44) : null,
      ) as LocationMessage;
      expect(resolved.position, const LatLng(47.07, 15.44));
    });

    test('ordinary text with inline coordinates in a long message is plain', () {
      expect(
        StructuredMessage.parse('a\nb\nc\nmeet at $graz'),
        isNull,
      );
    });

    test('Google Calendar share', () {
      final e = StructuredMessage.parse(
        'SCCARC Board Zoom\nOct 15  •  5 – 6 PM  •  View details & RSVP https://calendar.app.google/nsnPfzPVoxmm3DBDA',
        now: DateTime(2026, 10, 1),
      ) as EventMessage;
      expect(e.title, 'SCCARC Board Zoom');
      expect(e.when.start, DateTime(2026, 10, 15, 17));
      expect(e.when.end, DateTime(2026, 10, 15, 18));
      expect(e.link, 'https://calendar.app.google/nsnPfzPVoxmm3DBDA');
      expect(
        e.toWire(),
        'Event: SCCARC Board Zoom\n2026-10-15 17:00-18:00\nhttps://calendar.app.google/nsnPfzPVoxmm3DBDA',
      );
    });

    test('plain text is plain', () {
      expect(StructuredMessage.parse('hello there'), isNull);
      expect(StructuredMessage.parse(''), isNull);
    });
  });

  test('coordinatePattern finds standalone tokens only', () {
    final found = StructuredMessage.coordinatePattern
        .allMatches('see $graz and 1.5,2.5 and v47.070123, 15.440123')
        .map((m) => m.group(0))
        .toList();
    expect(found, [graz]);
  });

  test('EventWhen.dayCount', () {
    int days(String field) => EventWhen.parse(field)!.dayCount;
    expect(days('2026-10-20'), 1);
    expect(days('2026-10-20 18:00-20:00'), 1);
    expect(days('2026-10-20 - 2026-10-22'), 3);
    expect(days('2026-10-30 - 2026-11-02'), 4);
    // Across the end of daylight saving time (US, Nov 1 2026).
    expect(days('2026-10-31 - 2026-11-02'), 3);
    // Overnight but shorter than a day stays one day.
    expect(days('2026-10-20 22:00-02:00'), 1);
    expect(days('2026-10-20 18:00 - 2026-10-22 09:00'), 3);
  });

  group('meshcore:// share links', () {
    final secret = 'a1' * 16;
    final key = 'C0FFEE${'ab' * 29}';
    final channel = 'meshcore://channel/add?name=%23hike&secret=$secret';
    String contact(int type, [String name = 'Watsonville%20BBS']) =>
        'meshcore://contact/add?name=$name&public_key=$key&type=$type';

    test('a channel link alone', () {
      final m = StructuredMessage.parse(channel) as ShareMessage;
      expect(m.kind, ShareKind.channel);
      expect(m.name, '#hike');
      expect(m.keyHex, secret);
      expect(m.url, channel);
      expect(m.note, isNull);
      expect(m.summary, 'Channel: #hike');
      expect(m.toWire(), channel);
    });

    test('contact types map to kinds', () {
      final kinds = {
        1: ShareKind.contact,
        2: ShareKind.repeater,
        3: ShareKind.room,
        4: ShareKind.sensor,
        9: ShareKind.contact,
      };
      kinds.forEach((type, kind) {
        final m = StructuredMessage.parse(contact(type)) as ShareMessage;
        expect(m.kind, kind, reason: 'type $type');
        expect(m.name, 'Watsonville BBS');
        expect(m.keyHex, key);
      });
      expect(
        (StructuredMessage.parse(contact(3)) as ShareMessage).summary,
        'Room: Watsonville BBS',
      );
    });

    test('text around the link becomes the note', () {
      final m = StructuredMessage.parse(
        'Join our hike channel!\n$channel\nsee you there',
      ) as ShareMessage;
      expect(m.note, 'Join our hike channel!');
      expect(m.extraText, ['see you there']);
      expect(m.toWire(), 'Join our hike channel!\n$channel\nsee you there');
    });

    test('a reply mention in front still makes a card', () {
      expect(StructuredMessage.parse('@[Bob] ${contact(1)}'), isA<ShareMessage>());
    });

    test('emoji names decode', () {
      final m = StructuredMessage.parse(
        contact(1, Uri.encodeComponent('🚲 Ride')),
      ) as ShareMessage;
      expect(m.name, '🚲 Ride');
    });

    test('a bad escape keeps the contact without a name', () {
      final m = StructuredMessage.parse(contact(1, '%E0%A4%A')) as ShareMessage;
      expect(m.name, '');
      expect(m.summary, 'Contact');
    });

    test('invalid or embedded links stay text', () {
      // Secret is not 32 hex characters.
      expect(
        StructuredMessage.parse('meshcore://channel/add?name=x&secret=abcd'),
        isNull,
      );
      expect(
        StructuredMessage.parse('meshcore://contact/add?name=x&public_key=ab'),
        isNull,
      );
      // A bad % escape in a channel name.
      expect(
        StructuredMessage.parse(
            'meshcore://channel/add?name=%E0%A4%A&secret=$secret'),
        isNull,
      );
      // Inside a sentence, or more than two lines of text around it.
      expect(StructuredMessage.parse('join $channel tonight'), isNull);
      expect(StructuredMessage.parse('a\nb\nc\n$channel'), isNull);
      // Two links.
      expect(StructuredMessage.parse('$channel\n${contact(1)}'), isNull);
    });
  });
}
