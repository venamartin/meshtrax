import 'dart:convert';
import 'dart:typed_data';

import 'package:traxproto/traxproto.dart';

import 'smaz.dart';

/// A MeshTrax DM's text on the air. It is always packed, with nothing for
/// the user to set (owner, 2026-11-27): Smaz when that is smaller, as its
/// own bytes and not as text, else the UTF-8 as typed.
class MeshTraxDmText {
  const MeshTraxDmText._();

  static ({int packing, Uint8List bytes}) pack(String text) {
    final plain = Uint8List.fromList(utf8.encode(text));
    final smaz = Smaz.compressBytes(plain);
    return smaz.length < plain.length
        ? (packing: textSmaz, bytes: smaz)
        : (packing: textPlain, bytes: plain);
  }

  /// Null for a packing this MeshTrax does not know.
  static String? unpack(int packing, Uint8List bytes) => switch (packing) {
        textPlain => utf8.decode(bytes, allowMalformed: true),
        textSmaz =>
          utf8.decode(Smaz.decompressBytes(bytes), allowMalformed: true),
        _ => null,
      };
}
