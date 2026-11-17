import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/radio_settings.dart';

// TRAX mode's Tell the group: short readable text, MeshTrax only for now.
// The end is the sender's wall clock with its UTC offset, so every phone
// knows the same instant; anything malformed is plain text.
void main() {
  const us = LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5);

  TraxMessage? parse(String text) {
    final m = StructuredMessage.parse(text);
    return m is TraxMessage ? m : null;
  }

  group('wire text', () {
    test('switching names the end, with its offset, and the preset', () {
      const wire =
          'TRAX: on until 2026-11-22 18:00 UTC-8\n'
          '918.000 MHz 62.5 kHz SF7 CR5';
      final m = parse(wire)!;
      expect(m.on, isTrue);
      expect(m.until, DateTime.utc(2026, 11, 23, 2));
      expect(m.utcOffsetMinutes, -480);
      expect(m.preset, us);
      expect(m.toWire(), wire, reason: 'written back the same');
      expect(m.summary, 'TRAX mode on');
    });

    test('the same instant from any zone', () {
      for (final (text, offset) in [
        ('TRAX: on until 2026-11-23 02:00 UTC', 0),
        ('TRAX: on until 2026-11-23 07:30 UTC+5:30', 330),
        ('TRAX: on until 2026-11-22 21:00 UTC-5', -300),
      ]) {
        final m = parse('$text\n918.000 MHz 62.5 kHz SF7 CR5')!;
        expect(m.until, DateTime.utc(2026, 11, 23, 2), reason: text);
        expect(m.utcOffsetMinutes, offset);
        expect(m.toWire().split('\n').first, text);
      }
    });

    test('written from a local time in its own zone', () {
      final end = DateTime(2026, 11, 22, 18);
      final wire = TraxMessage.switching(until: end, preset: us).toWire();
      final back = parse(wire)!;
      expect(back.until, end.toUtc());
      expect(wire, startsWith('TRAX: on until 2026-11-22 18:00 UTC'));
      expect(wire.length, lessThan(80), reason: 'fits any channel message');
    });

    test('leaving', () {
      expect(const TraxMessage.leaving().toWire(), 'TRAX: off');
      final m = parse('trax: OFF')!;
      expect(m.on, isFalse);
      expect(m.until, isNull);
      expect(m.preset, isNull);
      expect(m.summary, 'TRAX mode off');
    });

    test('other bandwidths read and write', () {
      const long = LoRaParams(freqKhz: 918000, bwHz: 250000, sf: 11, cr: 5);
      expect(long.wireText, '918.000 MHz 250 kHz SF11 CR5');
      for (final bw in LoRaBandwidth.values) {
        final p = LoRaParams(freqKhz: 869495, bwHz: bw.hz, sf: 8, cr: 6);
        final m = parse('TRAX: on until 2026-11-22 18:00 UTC+1\n${p.wireText}');
        expect(m?.preset, p, reason: p.wireText);
      }
    });

    test('kept out of SMAZ, like the other cards', () {
      expect(StructuredMessage.hasPrefix('TRAX: off'), isTrue);
    });

    test('a reply quoting it is no TRAX message', () {
      expect(parse('@[Ana]\n>TRAX: off..\nok, see you'), isNull);
    });
  });

  group('read strictly: anything else is plain text', () {
    for (final text in [
      'TRAX: on',
      'TRAX: on until 2026-11-22 18:00\n918.000 MHz 62.5 kHz SF7 CR5',
      'TRAX: on until 2026-11-22 18:00 UTC-8',
      'TRAX: on until 2026-11-22 18:00 UTC-8\n918 MHz',
      'TRAX: on until 2026-02-30 18:00 UTC-8\n918.000 MHz 62.5 kHz SF7 CR5',
      'TRAX: on until 2026-11-22 25:00 UTC-8\n918.000 MHz 62.5 kHz SF7 CR5',
      'TRAX: on until 2026-11-22 18:00 UTC-15\n918.000 MHz 62.5 kHz SF7 CR5',
      'TRAX: on until 2026-11-22 18:00 UTC-8\n918.000 MHz 61 kHz SF7 CR5',
      'TRAX: on until 2026-11-22 18:00 UTC-8\n918.000 MHz 62.5 kHz SF13 CR5',
      'TRAX: on until 2026-11-22 18:00 UTC-8\n918.000 MHz 62.5 kHz SF7 CR9',
      'TRAX: maybe',
      'TRAX:',
      'trax mode is fun',
    ]) {
      test(text.replaceAll('\n', ' | '), () => expect(parse(text), isNull));
    }
  });

  group('private channels', () {
    Uint8List key(int seed) =>
        Uint8List.fromList(List.generate(16, (i) => seed + i));

    test('a channel with its own key is private', () {
      expect(
        Channel(index: 1, name: 'Desert trip', psk: key(9)).isPrivate,
        isTrue,
      );
      expect(
        Channel(index: 1, name: '#trip', psk: key(9)).isPrivate,
        isTrue,
        reason: 'a # name with a key of its own',
      );
    });

    test('Public, empty, nameless and hashtag channels are not', () {
      expect(
        Channel.fromHex(0, '', Channel.publicChannelPsk).isPrivate,
        isFalse,
      );
      expect(
        Channel(index: 1, name: 'x', psk: Uint8List(16)).isPrivate,
        isFalse,
      );
      expect(Channel(index: 1, name: ' ', psk: key(9)).isPrivate, isFalse);
      for (final name in ['#desert', 'desert', '#Desert', 'Desert']) {
        expect(
          Channel(
            index: 2,
            name: name,
            psk: Channel.derivePskFromHashtag('#desert'),
          ).isPrivate,
          isFalse,
          reason: name,
        );
      }
    });

    test('a # name cut at the radio\'s limit counts as a hashtag channel', () {
      final long = '#${'a' * 30}';
      expect(Channel(index: 3, name: long, psk: key(9)).isPrivate, isFalse);
      expect(Channel(index: 3, name: '#caf�', psk: key(9)).isPrivate, isFalse);
    });
  });
}
