import 'dart:typed_data';

/// The channel data type of a request one MeshTrax node makes of another on
/// a channel: one of the block 0170–017F that MeshTrax asked for in
/// MeshCore's `docs/number_allocations.md` (meshcore-dev/MeshCore#3925).
/// Generic: what is asked is its [ChannelRequest.kind], and each kind sets
/// its own body and how it is answered. 0x0174 is kept free for a reply type
/// of the same shape, should a kind ever need one.
const int dataTypeChannelRequest = 0x0173;

/// What a request asks for ([ChannelRequest.kind]). 0 is reserved.
abstract final class ChannelRequestKind {
  /// The packets of a photo the asker is missing: answered with the packets
  /// again (traxpix's `photoPacketsRequest`).
  static const int photoPackets = 1;
}

/// A request one node makes of another, or of anyone, on a channel:
///
/// ```
///   off  size  field
///   0    1     kind: what is asked; 0 reserved
///   1    1     version (high 4 bits, 0) and flags (low 4 bits, 0 so far;
///              a receiver ignores flags it doesn't know)
///   2    2     build: the asker's MeshTrax build, the number after the +
///              in its version (252 in 1.12.1+252), low byte first; 0
///              unknown
///   4    1     id: the asker's own number for this request, so an answer
///              can name it
///   5    2     asker: the first 2 bytes of the asker's public key
///   7    2     asked: the first 2 bytes of the public key of the node
///              asked; 0000 is anyone who can answer
///   9    ..    the kind's own bytes; a receiver ignores bytes past the
///              ones its kind knows
/// ```
///
/// A node takes a request only when it is the one asked, or anyone is, and
/// it knows the kind; anything else, an unknown version too, it ignores.
class ChannelRequest {
  ChannelRequest({
    required this.kind,
    required this.id,
    required this.asker,
    this.asked = anyone,
    this.flags = 0,
    this.build = 0,
    Uint8List? body,
  }) : body = body ?? Uint8List(0);

  /// [asked] when any node that can answer may.
  static const int anyone = 0x0000;

  /// The version this build writes and reads.
  static const int version = 0;

  static const int _headerBytes = 9;

  final int kind;
  final int flags;
  final int build;
  final int id;
  final int asker;
  final int asked;
  final Uint8List body;

  /// Whether the node whose public key starts with [prefix] is asked.
  bool isFor(int prefix) => asked == anyone || asked == prefix;

  Uint8List encode() => Uint8List.fromList([
    kind & 0xFF,
    (version << 4) | (flags & 0x0F),
    build & 0xFF,
    (build >> 8) & 0xFF,
    id & 0xFF,
    (asker >> 8) & 0xFF,
    asker & 0xFF,
    (asked >> 8) & 0xFF,
    asked & 0xFF,
    ...body,
  ]);

  /// The request [bytes] are, or null when they are too short to be one or
  /// of a version this build doesn't know.
  static ChannelRequest? decode(Uint8List bytes) {
    if (bytes.length < _headerBytes || bytes[0] == 0) return null;
    if (bytes[1] >> 4 != version) return null;
    return ChannelRequest(
      kind: bytes[0],
      flags: bytes[1] & 0x0F,
      build: bytes[2] | (bytes[3] << 8),
      id: bytes[4],
      asker: (bytes[5] << 8) | bytes[6],
      asked: (bytes[7] << 8) | bytes[8],
      body: Uint8List.fromList(bytes.sublist(_headerBytes)),
    );
  }

  @override
  String toString() =>
      'ChannelRequest(kind $kind, id $id, '
      '${asker.toRadixString(16).padLeft(4, '0')} asks '
      '${asked == anyone ? 'anyone' : asked.toRadixString(16).padLeft(4, '0')}, '
      'build $build, ${body.length} bytes)';
}
