import 'dart:typed_data';

/// The first 9 bytes of every TRAX packet from version 2 on, the same in
/// every later version: the version and kind, who sent it and when. A
/// reader reads only these from a version it doesn't know, to say whose
/// location it can't show. Version 1, MeshTrax 1.12.0's, had a layout of
/// its own and isn't read.
///
/// Byte 0 is version << 4 | kind. Bytes 1–4 are the first 4 bytes of the
/// sender's key. Bytes 5–8 are when it was sent, in seconds since 1970
/// (UTC), little-endian.
class TraxHeader {
  const TraxHeader({
    required this.version,
    required this.kind,
    required this.senderPrefix,
    required this.sentAt,
  });

  static const size = 9;

  /// 2 to 15.
  final int version;

  /// 1 to 15. Kind 0 is never sent.
  final int kind;

  final Uint8List senderPrefix;

  /// By the sender's clock.
  final DateTime sentAt;

  Uint8List encode() {
    final out = Uint8List(size);
    out[0] = version << 4 | kind;
    out.setRange(1, 5, senderPrefix);
    ByteData.sublistView(
      out,
    ).setUint32(5, sentAt.millisecondsSinceEpoch ~/ 1000, Endian.little);
    return out;
  }

  /// The header of a packet from version 2 on, or null for version 1, kind
  /// 0 or fewer than [size] bytes. What follows it is not read.
  static TraxHeader? decode(Uint8List data) {
    if (data.length < size) return null;
    final version = data[0] >> 4, kind = data[0] & 0x0F;
    if (version < 2 || kind == 0) return null;
    return TraxHeader(
      version: version,
      kind: kind,
      senderPrefix: Uint8List.fromList(data.sublist(1, 5)),
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        ByteData.sublistView(data).getUint32(5, Endian.little) * 1000,
        isUtc: true,
      ),
    );
  }
}
