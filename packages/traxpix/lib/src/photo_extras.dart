import 'dart:convert';
import 'dart:typed_data';

// A photo's extras: what it carries besides its picture, ahead of the
// bitstream when the photo byte's extras bit is set ([ImageStreamMetadata]).
// Each item is a type byte, a length byte and that many bytes of data:
//
//   type    another follows (1) | must understand (1) | item number (6)
//   length  0-255
//   data
//
// The picture is everything after the item without "another follows". A
// receiver skips an item it doesn't know, unless it's marked must-understand:
// then the photo needs a newer app. So a later release can add items and
// every earlier one still shows the photo.

/// The most characters a tag may have.
const int kPhotoTagMaxCharacters = 24;

/// The most UTF-8 bytes a sender's tag may take, so emoji can't stretch it
/// past a fraction of a packet.
const int kPhotoTagMaxBytes = 64;

/// Item 1, the sender's tag: a few words typed with the photo, sent as exact
/// text so the AI that rebuilds the photo can never invent it. Out in the
/// desert the decision is "is the spring flowing", "is the road washed out":
/// details a generative rebuild might get wrong.
const int kPhotoItemTag = 1;

/// Item 2, the sender's position: see [PhotoPosition].
const int kPhotoItemPosition = 2;

/// Item 3, no data: the sender kept only what they tapped and made the rest
/// black ("Subject only"), so a viewer opens zoomed in on the subject.
const int kPhotoItemSubjectOnly = 3;

/// The sizes a position may take, in bytes: about 10 km, 600 m, 40 m and 2 m.
const List<int> kPhotoPositionSizes = [3, 4, 5, 6];

const int _anotherFollows = 0x80;
const int _mustUnderstand = 0x40;
const int _itemNumber = 0x3F;

/// Where a photo was sent from, as the bits of a geohash packed in [bytes]
/// bytes, so its length is its accuracy. Of the 8 bits in each byte, 4 halve
/// the longitude and 4 the latitude: 3 bytes is a cell of about 10 x 5 km at
/// the equator, 4 about 600 x 300 m, 5 (an 8-character geohash) about
/// 40 x 20 m, 6 about 2 x 1 m. [lat] and [lon] are the middle of the cell.
class PhotoPosition {
  final double lat;
  final double lon;
  final int bytes;

  const PhotoPosition._(this.lat, this.lon, this.bytes);

  /// The cell [lat], [lon] falls in, [bytes] long. Throws [ArgumentError] for
  /// a size not in [kPhotoPositionSizes] or a position off the globe.
  factory PhotoPosition.at(double lat, double lon, {required int bytes}) {
    if (!kPhotoPositionSizes.contains(bytes)) {
      throw ArgumentError.value(bytes, 'bytes', 'not $kPhotoPositionSizes');
    }
    if (!(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180)) {
      throw ArgumentError('not a position: $lat, $lon');
    }
    return decode(_pack(lat, lon, bytes))!;
  }

  /// The position in [data], or null when its length isn't one of
  /// [kPhotoPositionSizes].
  static PhotoPosition? decode(List<int> data) {
    final bytes = data.length;
    if (!kPhotoPositionSizes.contains(bytes)) return null;
    final steps = bytes * 4;
    var x = 0;
    var y = 0;
    for (var i = 0; i < steps; i++) {
      x = (x << 1) | _bit(data, 2 * i);
      y = (y << 1) | _bit(data, 2 * i + 1);
    }
    final cells = 1 << steps;
    return PhotoPosition._(
      -90 + (y + 0.5) * 180 / cells,
      -180 + (x + 0.5) * 360 / cells,
      bytes,
    );
  }

  /// The cell's height, north to south, in degrees.
  double get latSpan => 180 / (1 << (bytes * 4));

  /// The cell's width, west to east, in degrees.
  double get lonSpan => 360 / (1 << (bytes * 4));

  Uint8List encode() => _pack(lat, lon, bytes);

  static int _bit(List<int> data, int i) => (data[i >> 3] >> (7 - (i & 7))) & 1;

  /// Geohash order: a longitude bit, then a latitude bit, each saying which
  /// half of the range the point is in, the upper half from its middle up.
  static Uint8List _pack(double lat, double lon, int bytes) {
    final steps = bytes * 4;
    final cells = 1 << steps;
    int cell(double v, double min, double span) =>
        ((v - min) / span * cells).floor().clamp(0, cells - 1);
    final x = cell(lon, -180, 360);
    final y = cell(lat, -90, 180);
    final out = Uint8List(bytes);
    for (var i = 0; i < steps; i++) {
      final shift = steps - 1 - i;
      for (final (j, v) in [(2 * i, x), (2 * i + 1, y)]) {
        out[j >> 3] |= ((v >> shift) & 1) << (7 - (j & 7));
      }
    }
    return out;
  }
}

/// What a photo carries besides its picture.
class PhotoExtras {
  final String? tag;
  final PhotoPosition? position;

  /// Only the subject was kept, on black.
  final bool subjectOnly;

  const PhotoExtras({this.tag, this.position, this.subjectOnly = false});

  /// The tag as it's sent: trimmed, and null when blank.
  String? get sentTag {
    final text = tag?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// Whether nothing would be sent, so the photo byte's extras bit stays off.
  bool get isEmpty => sentTag == null && position == null && !subjectOnly;
}

/// [bitstream] with [extras] ahead of it, or [bitstream] itself when there
/// are none. Throws [ArgumentError] for a tag over [kPhotoTagMaxBytes].
Uint8List photoPayload(Uint8List bitstream, PhotoExtras extras) {
  final items = <(int, List<int>)>[];
  if (extras.sentTag case final tag?) {
    final bytes = utf8.encode(tag);
    if (bytes.length > kPhotoTagMaxBytes) {
      throw ArgumentError.value(tag, 'tag', 'over $kPhotoTagMaxBytes bytes');
    }
    items.add((kPhotoItemTag, bytes));
  }
  if (extras.position case final position?) {
    items.add((kPhotoItemPosition, position.encode()));
  }
  if (extras.subjectOnly) items.add((kPhotoItemSubjectOnly, const <int>[]));
  if (items.isEmpty) return bitstream;
  final out = BytesBuilder(copy: false);
  for (var i = 0; i < items.length; i++) {
    final (number, data) = items[i];
    out
      ..addByte(number | (i < items.length - 1 ? _anotherFollows : 0))
      ..addByte(data.length)
      ..add(data);
  }
  out.add(bitstream);
  return out.toBytes();
}

/// A received payload split into its extras and the picture's bitstream.
class PhotoPayloadParts {
  final PhotoExtras extras;
  final Uint8List bitstream;

  /// An item this build doesn't know was marked must-understand: the photo
  /// needs a newer app and isn't to be rebuilt.
  final bool needsNewerApp;

  const PhotoPayloadParts({
    required this.extras,
    required this.bitstream,
    this.needsNewerApp = false,
  });
}

/// Splits [payload]; [hasExtras] is the photo byte's extras bit. Null when an
/// item runs past the end. Unknown items are skipped, and so is a position
/// of a size this build doesn't know.
PhotoPayloadParts? photoPayloadParts(
  Uint8List payload, {
  required bool hasExtras,
}) {
  if (!hasExtras) {
    return PhotoPayloadParts(extras: const PhotoExtras(), bitstream: payload);
  }
  String? tag;
  PhotoPosition? position;
  var subjectOnly = false;
  var needsNewerApp = false;
  var at = 0;
  while (true) {
    if (at + 2 > payload.length) return null;
    final type = payload[at];
    final end = at + 2 + payload[at + 1];
    if (end > payload.length) return null;
    final data = Uint8List.sublistView(payload, at + 2, end);
    switch (type & _itemNumber) {
      case kPhotoItemTag:
        final text = utf8.decode(data, allowMalformed: true).trim();
        tag ??= text.isEmpty ? null : text;
      case kPhotoItemPosition:
        position ??= PhotoPosition.decode(data);
      case kPhotoItemSubjectOnly:
        subjectOnly = true;
      default:
        if (type & _mustUnderstand != 0) needsNewerApp = true;
    }
    at = end;
    if (type & _anotherFollows == 0) break;
  }
  return PhotoPayloadParts(
    extras: PhotoExtras(tag: tag, position: position, subjectOnly: subjectOnly),
    bitstream: Uint8List.sublistView(payload, at),
    needsNewerApp: needsNewerApp,
  );
}
