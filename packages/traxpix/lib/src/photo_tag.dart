import 'dart:convert';
import 'dart:typed_data';

/// The sender's tag: a few words typed with the photo, sent as exact text
/// ahead of its bitstream, so the AI that rebuilds the photo can never invent
/// it. Out in the desert the decision is "is the spring flowing", "is the road
/// washed out" -- details a generative rebuild might get wrong.
const int kPhotoTagMaxCharacters = 24;

/// The most UTF-8 bytes a tag may take, so emoji can't stretch it past a
/// fraction of a packet.
const int kPhotoTagMaxBytes = 64;

/// [bitstream] with [tag] ahead of it: a length byte, then its UTF-8 bytes.
/// [bitstream] alone when [tag] is null or blank. Throws [ArgumentError] for
/// a tag over [kPhotoTagMaxBytes].
Uint8List photoPayloadWithTag(Uint8List bitstream, String? tag) {
  final text = tag?.trim() ?? '';
  if (text.isEmpty) return bitstream;
  final bytes = utf8.encode(text);
  if (bytes.length > kPhotoTagMaxBytes) {
    throw ArgumentError.value(tag, 'tag', 'over $kPhotoTagMaxBytes bytes');
  }
  return Uint8List.fromList([bytes.length, ...bytes, ...bitstream]);
}

/// A received payload's tag and bitstream; [hasTag] comes from the photo's
/// metadata byte. Null when the tag runs past the payload or is too long:
/// the photo is damaged.
({String? tag, Uint8List bitstream})? photoPayloadParts(
  Uint8List payload, {
  required bool hasTag,
}) {
  if (!hasTag) return (tag: null, bitstream: payload);
  if (payload.isEmpty) return null;
  final length = payload[0];
  if (length > kPhotoTagMaxBytes || 1 + length > payload.length) return null;
  final text = utf8
      .decode(payload.sublist(1, 1 + length), allowMalformed: true)
      .trim();
  return (
    tag: text.isEmpty ? null : text,
    bitstream: Uint8List.sublistView(payload, 1 + length),
  );
}
