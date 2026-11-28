import 'dart:isolate';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxproto/traxproto.dart';

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
]);

// Encoded by hand from proto/meshtrax.proto, field by field. These bytes
// must never change: a phone on an older MeshTrax reads them.
final reportBytes = _hex(
  '0A024379' // name "Cy"
  '10FC01' // build 252
  '1A0408300101', // track, 4 bytes
);

// Fields this MeshTrax has never heard of, of each kind the rules allow.
final _future = [
  _hex('782A'), // field 15, varint
  _hex('A20102FFFF'), // field 20, bytes
  _hex('AD0101020304'), // field 21, 32-bit
  _hex('B1010102030405060708'), // field 22, 64-bit
];

void main() {
  group('the report', () {
    test('byte for byte', () {
      final m = TraxReportGrowth(
        name: 'Cy',
        build: 252,
        track: _hex('08300101'),
      );
      expect(m.encode(), reportBytes);
      final back = TraxReportGrowth.decode(reportBytes)!;
      expect(back.name, 'Cy');
      expect(back.build, 252);
      expect(back.track, _hex('08300101'));
    });

    test('nothing set is no bytes, and no bytes is nothing set', () {
      expect(TraxReportGrowth().encode(), isEmpty);
      final none = TraxReportGrowth.decode(const [])!;
      expect((none.name, none.build), ('', 0));
      expect(none.track, isEmpty);
    });

    test('fields from the future are skipped, before, between and after '
        'the ones it knows', () {
      final m = TraxReportGrowth.decode([
        ..._future[0],
        ...reportBytes.sublist(0, 4),
        ..._future[1],
        ..._future[2],
        ...reportBytes.sublist(4),
        ..._future[3],
      ])!;
      expect(m.name, 'Cy');
      expect(m.build, 252);
      expect(m.track, _hex('08300101'));
    });

    test('a known number with another type is skipped, not misread', () {
      // The name as a number, the build as bytes, the track as 32 bits.
      final m = TraxReportGrowth.decode(
        _hex(
          '0805'
          '1202FFFF'
          '1D01020304'
          '10FC01',
        ),
      )!;
      expect((m.name, m.build), ('', 252));
      expect(m.track, isEmpty);
    });

    test('cut short, a group, a field 0 or a wire type that doesn\'t exist '
        'is no report', () {
      for (final bad in [
        reportBytes.sublist(0, reportBytes.length - 1),
        _hex('1A10AB'),
        _hex('10FCFC'),
        _hex('7B08017C'),
        _hex('7C'),
        _hex('0200'),
        _hex('7E00'),
        _hex('7F00'),
      ]) {
        expect(TraxReportGrowth.decode(bad), isNull, reason: '$bad');
      }
    });

    test(
      'a negative length is no report, never a step back for ever',
      () async {
        for (final bad in [
          _hex('7AFAFFFFFF0F'), // field 15, length -6: back to its own tag
          _hex('0AFEFFFFFF0F'), // the name, length -2
          _hex('1AFEFFFFFF0F'), // the track
        ]) {
          final none = await Isolate.run(
            () => TraxReportGrowth.decode(bad) == null,
          ).timeout(const Duration(seconds: 20));
          expect(none, isTrue, reason: '$bad');
        }
      },
    );
  });

  group('the ask', () {
    test(
      'nothing yet: no bytes, and what a later MeshTrax adds is skipped',
      () {
        expect(TraxAskGrowth().encode(), isEmpty);
        expect(TraxAskGrowth.decode(const []), isNotNull);
        expect(
          TraxAskGrowth.decode([for (final f in _future) ...f]),
          isNotNull,
        );
      },
    );

    test('what doesn\'t parse is no ask', () {
      expect(TraxAskGrowth.decode(_hex('A201')), isNull);
      expect(TraxAskGrowth.decode(_hex('7B08017C')), isNull);
      expect(TraxAskGrowth.decode(_hex('7AFAFFFFFF0F')), isNull);
    });
  });
}
