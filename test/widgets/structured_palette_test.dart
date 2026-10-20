import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';

// Every text colour on every card kind reads at 4.5:1 or better (WCAG AA),
// in both themes.
void main() {
  const here = LatLng(36.92, -121.74);
  final kinds = <String, StructuredMessage>{
    'event': EventMessage(title: 'x', when: EventWhen(start: DateTime(2026))),
    'notice': const NoticeMessage(lines: ['x']),
    'location': const LocationMessage(position: here),
    'sos': const SosMessage(position: here, text: 'x'),
    for (final kind in ShareKind.values)
      'share ${kind.name}': ShareMessage(
        kind: kind,
        name: 'x',
        keyHex: 'ab' * 32,
        url: 'meshcore://',
      ),
  };

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: message) in kinds.entries) {
      test('$name, ${brightness.name}', () {
        final p = StructuredPalette.forAccents(
          StructuredPalette.accentsOf(message),
          brightness,
        );
        final pairs = {
          'title': (p.title, p.surface),
          'body': (p.body, p.surface),
          'muted': (p.muted, p.surface),
          'ink': (p.ink, p.surface),
          'onAccent': (p.onAccent, p.accent),
          'onTonal': (p.onTonal, p.tonal),
        };
        pairs.forEach((what, colors) {
          final (fg, bg) = colors;
          expect(
            StructuredPalette.contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: what,
          );
        });
      });
    }
  }
}
