import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxproto/traxproto.dart';

import 'package:meshtrax/helpers/meshtrax_dm.dart';

void main() {
  test('English text goes as Smaz, smaller, and comes back as typed', () {
    const text = 'Are you on the way home? I am at the trailhead and the '
        'weather is turning.';
    final packed = MeshTraxDmText.pack(text);
    expect(packed.packing, textSmaz);
    expect(packed.bytes.length, lessThan(utf8.encode(text).length * 0.7));
    expect(MeshTraxDmText.unpack(packed.packing, packed.bytes), text);
  });

  test('text Smaz cannot shrink goes as typed', () {
    for (final text in ['Здравей, как си?', '👍🏔️', 'こんにちは', '']) {
      final packed = MeshTraxDmText.pack(text);
      expect(packed.packing, textPlain, reason: text);
      expect(packed.bytes, utf8.encode(text));
      expect(MeshTraxDmText.unpack(packed.packing, packed.bytes), text);
    }
  });

  test('a packing from a later MeshTrax is not guessed at', () {
    expect(MeshTraxDmText.unpack(7, Uint8List.fromList([1, 2, 3])), isNull);
  });
}
