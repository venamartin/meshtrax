// Adapted from meshcore-open lib/services/image_chunk_transport.dart (MIT,
// see the repository's LICENSE), commit 3944c4f. The framing is theirs;
// MeshTrax uses its own data type, quality, chunk size and retry byte.

/// A photo as MeshCore channel datagrams (`PAYLOAD_TYPE_GRP_DATA`): the group
/// of packets a photo goes out as, and the photo a group of packets makes.
///
/// Nothing here sends, receives or keeps time. The app hands the packets to
/// the radio, collects the ones it receives, and asks [ImagePackets] for the
/// photo (lib/services/photo_mesh.dart, photo_reassembler.dart).
///
/// This file is the single source of truth for the packet format: the blob
/// size, the header, per-packet capacities and the XOR repair packet.
///
/// ## Wire format
///
/// Photos travel as data type [dataTypeMeshTraxPhoto] (0x0172), one blob of
/// at most [kImageChunkBlobBytes] bytes per packet:
///
/// ```
///   off  size  field
///   0    2     sender_prefix  selfPublicKey[0..1]: the firmware gives no
///                             sender identity with channel data, so it is
///                             in EVERY packet (packet 0 may be lost).
///   2    1     img_id         uint8, per photo
///   3    1     idx<<4 | total idx 0..15, total 1..15.
///                             idx == total  =>  the repair packet.
///   4    1     retry          low 4 bits: how many times the packet went
///                             before this copy, 0 the first time. High 4
///                             bits: flags, 0 so far; a receiver ignores
///                             flags it doesn't know.
///   5    ..    body           see below
/// ```
///
/// The retry byte makes a packet sent again a new packet on the air: the
/// ciphertext differs, so every repeater passes it on, as it does a channel
/// text sent again with a new timestamp. A receiver takes it as the packet it
/// repeats: copies match without it ([samePhotoPacket]), and only the body
/// goes into the photo.
///
/// MeshTrax 1.12.0 sent photos as 0x0170, without the retry byte. Later
/// releases neither send nor read 0x0170.
///
/// Data packet body:
///   * packet 0: `[meta]` + payload. `meta` is [ImageStreamMetadata] packed as
///     `extras(1) | version(3) | resolution(2) | rate(2)`. A change a receiver
///     must understand bumps its version; with the extras bit set, the
///     payload opens with the photo's extras ([photoPayload]), then the image
///     bytes.
///   * others: image bytes
///   * at most [kImageChunkBodyBytes] bytes.
///
/// Repair packet body:
///   * `[len_xor]` + XOR of every data packet's body, each zero-padded to
///     [kImageChunkBodyBytes].
///   * `len_xor` is the XOR of the data bodies' LENGTHS, so a lost packet's
///     length is `len_xor ^ XOR(lengths of the bodies that came)`, and the
///     last (short) packet can be rebuilt without sending a total length.
///
/// Body capacity is the blob (157) less the header less the repair packet's
/// length byte, so that the repair packet still fits in one blob.
///
/// ## Integrity
///
/// There is deliberately NO app-level checksum. The LoRa PHY CRCs every
/// packet (`setCRC(1)` in each radio driver; a failing packet is dropped by
/// the modem), and MeshCore checks a 2-byte HMAC-SHA256 per packet
/// (`Utils::MACThenDecrypt` returns 0 for a bad tag). What no lower layer can
/// see is a MERGE of two photos: two senders on the same sender prefix, img_id
/// and channel at once, about 1 in 65536 per pair, which makes a corrupt
/// picture rather than a clean failure. That risk is accepted: 2 more bytes in
/// every packet would cost a packet on many photos.
///
/// ## Capacity against measured `ft8` output
///   packet 0: 150 image bytes (151 body - 1 meta), later packets: 151.
///   Real photos are 208-796 bytes, mean about 410: 2 to 6 data packets, so 3
///   to 7 with the repair packet.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'photo_extras.dart';
import 'rate_point.dart';

// ---------------------------------------------------------------------------
// Data types and geometry
// ---------------------------------------------------------------------------

/// The data type MeshTrax photos travel as: one of the block 0170–017F that
/// MeshTrax asked for in MeshCore's `docs/number_allocations.md`
/// (meshcore-dev/MeshCore#3925). Its packets carry the retry byte.
const int dataTypeMeshTraxPhoto = 0x0172;

/// Maximum blob we will ever put in one GRP_DATA packet.
///
/// Binding limits, smallest first:
///   * raw log: the radio copies a heard packet to the app
///     (`PUSH_CODE_LOG_RX_DATA`) only up to 173 bytes (`MyMesh::logRxRaw`,
///     `MAX_FRAME_SIZE` 176 - 3), which is how a sender hears its packets
///     repeated. A packet is 2 (header, path length) + its path + 3 (channel
///     hash, MAC) + the ciphertext: whole 16-byte blocks of data type (2) +
///     length (1) + blob. 157 makes 160 bytes of ciphertext, so a 165-byte
///     packet heard with up to 8 bytes of path (4 repeaters with 2-byte IDs)
///     = **157** <- used. A flood in a region carries 4 bytes of transport
///     codes too, leaving up to 4 bytes of path; the first repeater's copy
///     still fits at any hash width (172 bytes at 3-byte IDs)
///   * app  `maxFrameSize` 172 - 9 byte RESP header = 163
///   * BLE  ATT_MTU 176 - 3 notify - 9 resp header  = 164
///   * radio `MAX_GROUP_DATA_LENGTH` 184 - 16 - 3   = 165
///   * serial `MAX_CHANNEL_DATA_LENGTH` 176 - 9     = 167
const int kImageChunkBlobBytes = 157;

/// The header of a packet sent as [dataTypeMeshTraxPhoto]: sender_prefix(2)
/// + img_id(1) + idx/total(1) + retry(1).
const int kImageChunkHeaderBytes = 5;

/// Where the retry byte is in a packet.
const int kImageRetryByteOffset = 4;

/// The retry byte's bits that count the sends before this one.
const int kImageRetryCountMask = 0x0F;

/// The repair packet spends one body byte on the XOR of the data body
/// lengths.
const int kImageParityLengthBytes = 1;

/// Maximum body bytes in any packet, data or repair.
const int kImageChunkBodyBytes =
    kImageChunkBlobBytes - kImageChunkHeaderBytes - kImageParityLengthBytes;

/// The single [ImageStreamMetadata] byte carried by packet 0.
const int kImageChunkMetadataBytes = 1;

/// Body bytes of packet 0 that are NOT image data: just the metadata byte.
const int kImageChunkZeroMetadataBytes = kImageChunkMetadataBytes;

/// Image bytes carried by packet 0.
const int kImageChunkFirstCapacity =
    kImageChunkBodyBytes - kImageChunkZeroMetadataBytes;

/// Image bytes carried by every packet after packet 0.
const int kImageChunkCapacity = kImageChunkBodyBytes;

/// `total` is 4 bits and must be >= 1, so at most 15 data packets.
const int kImageMaxDataChunks = 15;

/// Largest image bitstream this framing can carry.
const int kImageMaxPayloadBytes =
    kImageChunkFirstCapacity + (kImageMaxDataChunks - 1) * kImageChunkCapacity;

/// Bytes of the sender public key repeated in every packet.
const int kImageSenderPrefixBytes = 2;

/// Bytes a full photo packet puts on the air with no path: header and path
/// length (2), channel hash and MAC (3), then the encrypted data type, length
/// and blob (2 + 1 + 157) padded to whole AES blocks (160).
const int kPhotoPacketAirBytes =
    2 + 3 + (3 + kImageChunkBlobBytes + 15) ~/ 16 * 16;

// ---------------------------------------------------------------------------
// Rate point <-> wire code
// ---------------------------------------------------------------------------

/// Wire code for `ft8` in the low bits of the packet-0 metadata byte.
///
/// Codes 0, 1 and 3 aren't used: a photo carrying one is refused, never
/// guessed at. The switch is exhaustive on purpose: adding a quality is a
/// compile error here, not a silent shift.
const int kImageRateWireFt8 = 2;

/// Maps a quality to the wire code written into the metadata byte.
int imageRateWireCode(ImageCodecRatePoint rate) {
  switch (rate) {
    case ImageCodecRatePoint.ft8:
      return kImageRateWireFt8;
  }
}

/// Inverse of [imageRateWireCode]; null for a code this build cannot decode.
ImageCodecRatePoint? imageRatePointFromWireCode(int code) {
  switch (code) {
    case kImageRateWireFt8:
      return ImageCodecRatePoint.ft8;
    default:
      return null;
  }
}

// ---------------------------------------------------------------------------
// Stream metadata (the single byte carried by packet 0)
// ---------------------------------------------------------------------------

/// Square sizes addressable by the 2-bit resolution code in the metadata byte.
///
/// Index == wire code. 512 is code 0 because it is the only size the current
/// decoder supports; the rest exist so a future model can be signalled without
/// a format change.
const List<int> kImageResolutionCodes = <int>[512, 256, 768, 1024];

/// Contents of the packet-0 metadata byte:
/// `extras(1) | version(3) | resolution(2) | rate(2)`. The format version is
/// 0. A receiver refuses any other, which leaves it to signal a change no
/// earlier release could skip; anything that can be skipped is an extra.
class ImageStreamMetadata {
  /// Codec rate point. Reuses the UI enum — there is deliberately no second
  /// rate-point enum in this codebase.
  final ImageCodecRatePoint rate;

  /// Square edge length in pixels the sender encoded at.
  final int squareSize;

  /// Whether the payload starts with the photo's extras (see
  /// [photoPayload]).
  final bool hasExtras;

  const ImageStreamMetadata({
    required this.rate,
    this.squareSize = 512,
    this.hasExtras = false,
  });

  /// Encodes to the single wire byte.
  ///
  /// Throws [ArgumentError] if [squareSize] is not one of
  /// [kImageResolutionCodes].
  int encode() {
    final code = kImageResolutionCodes.indexOf(squareSize);
    if (code < 0) {
      throw ArgumentError.value(
        squareSize,
        'squareSize',
        'not representable; must be one of $kImageResolutionCodes',
      );
    }
    // extras(1) | version(3) | resolution(2) | rate(2), version 0.
    return (hasExtras ? 0x80 : 0) |
        ((code & 0x03) << 2) |
        (imageRateWireCode(rate) & 0x03);
  }

  /// Decodes the wire byte, or returns null if it names a format version,
  /// rate point or resolution this build does not know.
  ///
  /// Deliberately never falls back to a default rate: an unknown code means the
  /// sender is running a format we cannot decode, and guessing would hand the
  /// wrong model a bitstream it will happily turn into garbage.
  static ImageStreamMetadata? decode(int byte) {
    final rate = imageRatePointFromWireCode(byte & 0x03);
    final code = (byte >> 2) & 0x03;
    if (byte & 0x70 != 0) return null;
    if (rate == null) return null;
    if (code >= kImageResolutionCodes.length) return null;
    return ImageStreamMetadata(
      rate: rate,
      squareSize: kImageResolutionCodes[code],
      hasExtras: byte & 0x80 != 0,
    );
  }

  @override
  String toString() =>
      'ImageStreamMetadata(${rate.name}, ${squareSize}px'
      '${hasExtras ? ', with extras' : ''})';

  @override
  bool operator ==(Object other) =>
      other is ImageStreamMetadata &&
      other.rate == rate &&
      other.squareSize == squareSize &&
      other.hasExtras == hasExtras;

  @override
  int get hashCode => Object.hash(rate, squareSize, hasExtras);
}

// ---------------------------------------------------------------------------
// Packet header
// ---------------------------------------------------------------------------

/// A packet's header, as [parseImageChunkHeader] reads it.
class ImageChunkHeader {
  /// First [kImageSenderPrefixBytes] bytes of the sender's public key.
  final int senderPrefix;

  final int imgId;

  /// 0-based packet index. Equals [total] for the repair packet.
  final int index;

  /// Number of DATA packets in this photo (the repair packet not counted).
  /// 1..15.
  final int total;

  /// How many times the packet went before this copy: 0 the first time.
  final int retry;

  const ImageChunkHeader({
    required this.senderPrefix,
    required this.imgId,
    required this.index,
    required this.total,
    this.retry = 0,
  });

  bool get isParity => index == total;

  /// Where the packet's body starts.
  int get bodyOffset => kImageChunkHeaderBytes;

  @override
  String toString() =>
      'ImageChunkHeader(sender: 0x'
      '${senderPrefix.toRadixString(16).padLeft(4, '0')}, img: $imgId, '
      'idx: $index/$total${isParity ? ' parity' : ''}, retry: $retry)';
}

/// Reads the first two bytes of a public key as the sender prefix integer.
///
/// Returns null when [publicKey] is too short to identify a sender.
int? senderPrefixFromKey(List<int>? publicKey) {
  if (publicKey == null || publicKey.length < kImageSenderPrefixBytes) {
    return null;
  }
  return ((publicKey[0] & 0xFF) << 8) | (publicKey[1] & 0xFF);
}

/// Reads the header of [blob], a packet of [dataTypeMeshTraxPhoto], or null
/// if it cannot be one.
ImageChunkHeader? parseImageChunkHeader(Uint8List blob) {
  if (blob.length < kImageChunkHeaderBytes) return null;
  if (blob.length > kImageChunkBlobBytes) return null;
  final total = blob[3] & 0x0F;
  if (total == 0) return null;
  final index = (blob[3] >> 4) & 0x0F;
  if (index > total) return null; // index == total is the repair packet
  return ImageChunkHeader(
    senderPrefix: ((blob[0] & 0xFF) << 8) | (blob[1] & 0xFF),
    imgId: blob[2] & 0xFF,
    index: index,
    total: total,
    retry: blob[kImageRetryByteOffset] & kImageRetryCountMask,
  );
}

// ---------------------------------------------------------------------------
// A photo into packets
// ---------------------------------------------------------------------------

/// Number of DATA packets needed for a [payloadBytes]-long bitstream.
///
/// A zero-length payload still needs one packet: packet 0 carries the
/// metadata byte, and a receiver must be able to observe an empty image rather
/// than nothing at all.
int imageDataChunkCount(int payloadBytes) {
  final n = math.max(payloadBytes, 0);
  if (n <= kImageChunkFirstCapacity) return 1;
  final remaining = n - kImageChunkFirstCapacity;
  return 1 + (remaining / kImageChunkCapacity).ceil();
}

/// The packets of one photo, each first time it goes.
class ImageChunkSet {
  /// Every blob in send order; the repair blob, if any, is last.
  final List<Uint8List> blobs;

  /// Number of data packets (excludes the repair packet).
  final int dataChunkCount;

  final bool hasParity;

  final int imgId;

  final int senderPrefix;

  const ImageChunkSet({
    required this.blobs,
    required this.dataChunkCount,
    required this.hasParity,
    required this.imgId,
    required this.senderPrefix,
  });

  int get totalBytes => blobs.fold<int>(0, (a, b) => a + b.length);
}

/// Splits an encoded image bitstream into the packets of
/// [dataTypeMeshTraxPhoto], each with its retry byte at 0.
///
/// Packet 0's body opens with the metadata byte; the rest is image bytes.
///
/// [senderPrefix] must come from the local node's public key (see
/// [senderPrefixFromKey]); receivers key a photo on it and drop packets whose
/// prefix equals their own.
///
/// [parity] appends the XOR repair packet, which rebuilds any one lost data
/// packet.
///
/// Throws [ArgumentError] when [payload] exceeds [kImageMaxPayloadBytes].
ImageChunkSet buildImageChunks({
  required Uint8List payload,
  required ImageStreamMetadata metadata,
  required int senderPrefix,
  required int imgId,
  bool parity = true,
}) {
  if (payload.length > kImageMaxPayloadBytes) {
    throw ArgumentError.value(
      payload.length,
      'payload',
      'exceeds kImageMaxPayloadBytes ($kImageMaxPayloadBytes)',
    );
  }
  final total = imageDataChunkCount(payload.length);

  // Build the bodies first; the repair packet is a pure function of them.
  final bodies = <Uint8List>[];
  var offset = 0;
  for (var i = 0; i < total; i++) {
    final capacity = i == 0 ? kImageChunkFirstCapacity : kImageChunkCapacity;
    final take = math.min(capacity, payload.length - offset);
    final body = BytesBuilder();
    if (i == 0) body.addByte(metadata.encode());
    if (take > 0) body.add(payload.sublist(offset, offset + take));
    offset += take;
    bodies.add(body.toBytes());
  }

  Uint8List header(int index) => Uint8List.fromList(<int>[
    (senderPrefix >> 8) & 0xFF,
    senderPrefix & 0xFF,
    imgId & 0xFF,
    ((index & 0x0F) << 4) | (total & 0x0F),
    0, // retry byte: the first send, no flags
  ]);

  final blobs = <Uint8List>[
    for (var i = 0; i < total; i++)
      (BytesBuilder()
            ..add(header(i))
            ..add(bodies[i]))
          .toBytes(),
  ];
  if (parity) {
    blobs.add(
      (BytesBuilder()
            ..add(header(total))
            ..add(_parityBody(bodies, kImageChunkBodyBytes)))
          .toBytes(),
    );
  }

  return ImageChunkSet(
    blobs: blobs,
    dataChunkCount: total,
    hasParity: parity,
    imgId: imgId,
    senderPrefix: senderPrefix,
  );
}

/// `[len_xor] + XOR(bodies zero-padded to [bodyBytes])`.
Uint8List _parityBody(Iterable<Uint8List> bodies, int bodyBytes) {
  final xor = Uint8List(bodyBytes);
  var lenXor = 0;
  for (final body in bodies) {
    lenXor ^= body.length;
    for (var j = 0; j < body.length; j++) {
      xor[j] ^= body[j];
    }
  }
  return Uint8List.fromList(<int>[lenXor & 0xFF, ...xor]);
}

/// Packet [blob] as it goes the [retry]th time after its first (1 the first
/// time again, up to 15): its retry count set, its flags kept. A new packet
/// to every repeater, the same packet to a receiver ([samePhotoPacket]).
Uint8List photoPacketAgain(Uint8List blob, int retry) {
  final again = Uint8List.fromList(blob);
  again[kImageRetryByteOffset] =
      (blob[kImageRetryByteOffset] & ~kImageRetryCountMask & 0xFF) |
      (retry.clamp(0, kImageRetryCountMask));
  return again;
}

/// Whether [a] and [b], packets of [dataTypeMeshTraxPhoto], are copies of one
/// packet: the same bytes but for how many times it went before.
bool samePhotoPacket(Uint8List a, Uint8List b) {
  if (a.length != b.length || a.length <= kImageRetryByteOffset) return false;
  for (var i = 0; i < a.length; i++) {
    final differ = i == kImageRetryByteOffset
        ? (a[i] ^ b[i]) & ~kImageRetryCountMask & 0xFF
        : a[i] ^ b[i];
    if (differ != 0) return false;
  }
  return true;
}

/// Hands out per-photo ids, avoiding immediate reuse.
///
/// The id is only 8 bits, so it wraps; a receiver keys a photo on the sender
/// prefix and channel too, and gives a photo up after a while, which bounds
/// the damage of a wrap.
class ImageIdAllocator {
  int _next;

  ImageIdAllocator({int? seed, math.Random? random})
    : _next = seed ?? (random ?? math.Random()).nextInt(256);

  int next() {
    final id = _next & 0xFF;
    _next = (_next + 1) & 0xFF;
    return id;
  }
}

// ---------------------------------------------------------------------------
// Packets into a photo
// ---------------------------------------------------------------------------

/// What [ImagePackets.add] made of a packet.
enum ImagePacketAdded {
  /// A packet it didn't have yet.
  accepted,

  /// A copy of a packet it has.
  duplicate,

  /// A different packet under a number it has: not added.
  conflicting,
}

/// A photo rebuilt from its packets.
class ImageRebuilt {
  /// Null when packet 0's metadata byte names a format version, rate point or
  /// resolution this build cannot read.
  final ImageStreamMetadata? metadata;

  /// The encoded image bitstream, exactly as the sender produced it; empty
  /// when [metadata] is null.
  final Uint8List data;

  /// True when one data packet was rebuilt from the repair packet.
  final bool recoveredWithParity;

  /// Number of data packets in the photo.
  final int chunkCount;

  const ImageRebuilt({
    required this.metadata,
    required this.data,
    required this.recoveredWithParity,
    required this.chunkCount,
  });
}

/// The packets of one photo collected so far, and the photo they make once
/// every data packet is in, or all but one and the repair packet.
///
/// Out-of-order and duplicate tolerant. Every packet must say the same
/// [total].
class ImagePackets {
  /// Number of data packets the photo has.
  final int total;

  /// Data packet bodies by index.
  final Map<int, Uint8List> bodies = <int, Uint8List>{};

  /// The repair packet's body, once it came.
  Uint8List? parityBody;

  ImagePackets({required this.total});

  bool get hasParity => parityBody != null;

  /// Data packets in.
  int get received => bodies.length;

  /// Whether [header], with [body] after it, is a packet this set can hold:
  /// a repair packet with its length byte, and no data body longer than the
  /// repair packet could cover.
  bool fits(ImageChunkHeader header, Uint8List body) => header.isParity
      ? body.isNotEmpty && body.length <= kImageChunkBodyBytes + kImageParityLengthBytes
      : body.length <= kImageChunkBodyBytes;

  /// Adds packet [header] with [body].
  ImagePacketAdded add(ImageChunkHeader header, Uint8List body) {
    if (header.isParity) {
      if (parityBody != null) return ImagePacketAdded.duplicate;
      parityBody = Uint8List.fromList(body);
      return ImagePacketAdded.accepted;
    }
    final known = bodies[header.index];
    if (known != null) {
      return _sameBytes(known, body)
          ? ImagePacketAdded.duplicate
          : ImagePacketAdded.conflicting;
    }
    bodies[header.index] = Uint8List.fromList(body);
    return ImagePacketAdded.accepted;
  }

  /// Whether [header] with [body] repeats a packet of this set as it was
  /// held: a late copy of a photo already rebuilt.
  ///
  /// Conservative by design: anything that does not byte-match is treated as
  /// new, because dropping a real photo is far worse than starting again for
  /// a straggler. In the loss-free case the photo completes on its last data
  /// packet, so the repair packet comes afterwards and was never held: it is
  /// recomputed from the bodies rather than guessed at.
  bool repeats(ImageChunkHeader header, Uint8List body) {
    if (header.total != total) return false;
    final known = header.isParity
        ? (parityBody ?? _expectedParityBody())
        : bodies[header.index];
    return known != null && _sameBytes(known, body);
  }

  Uint8List? _expectedParityBody() {
    if (bodies.length != total) return null;
    return _parityBody(
      [for (var i = 0; i < total; i++) bodies[i]!],
      kImageChunkBodyBytes,
    );
  }

  /// The photo the packets make, or null while they don't make one yet (or
  /// the repair packet doesn't add up).
  ImageRebuilt? rebuild() {
    if (bodies.length == total) return _assemble(recovered: false);
    if (bodies.length != total - 1 || parityBody == null) return null;

    // Exactly one data packet missing and the repair packet in: rebuild it.
    final missing = List<int>.generate(
      total,
      (i) => i,
    ).firstWhere((i) => !bodies.containsKey(i));
    final parity = parityBody!;
    var lengthXor = parity[0] & 0xFF;
    final xor = Uint8List(kImageChunkBodyBytes);
    final parityData = parity.length - kImageParityLengthBytes;
    for (var i = 0; i < parityData && i < xor.length; i++) {
      xor[i] = parity[kImageParityLengthBytes + i];
    }
    for (final body in bodies.values) {
      lengthXor ^= body.length;
      for (var i = 0; i < body.length; i++) {
        xor[i] ^= body[i];
      }
    }
    if (lengthXor > kImageChunkBodyBytes) return null; // corrupt repair packet
    if (missing == 0 && lengthXor < kImageChunkZeroMetadataBytes) return null;
    // Only the LAST data packet may be short; every earlier one is full by
    // construction. Without this, a single flipped bit in the length byte
    // silently yields a truncated photo reported as complete, which is worse
    // than failing: the caller has no way to know the bytes are wrong.
    if (missing < total - 1 && lengthXor != kImageChunkBodyBytes) return null;
    bodies[missing] = Uint8List.sublistView(xor, 0, lengthXor);
    return _assemble(recovered: true);
  }

  ImageRebuilt _assemble({required bool recovered}) {
    final first = bodies[0]!;
    final metadata = first.length < kImageChunkZeroMetadataBytes
        ? null
        : ImageStreamMetadata.decode(first[0]);
    if (metadata == null) {
      return ImageRebuilt(
        metadata: null,
        data: Uint8List(0),
        recoveredWithParity: recovered,
        chunkCount: total,
      );
    }
    final out = BytesBuilder()
      ..add(Uint8List.sublistView(first, kImageChunkZeroMetadataBytes));
    for (var i = 1; i < total; i++) {
      out.add(bodies[i]!);
    }
    return ImageRebuilt(
      metadata: metadata,
      data: out.toBytes(),
      recoveredWithParity: recovered,
      chunkCount: total,
    );
  }
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Asking for lost packets
// ---------------------------------------------------------------------------

/// The data packets [packets] still lacks, one bit each: packet i at bit i.
int missingPacketBits(ImagePackets packets) {
  var bits = 0;
  for (var i = 0; i < packets.total; i++) {
    if (!packets.bodies.containsKey(i)) bits |= 1 << i;
  }
  return bits;
}

/// The body of a request for the packets of photo [imgId], of [total] data
/// packets, that the asker is missing: [missing], one bit each, packet i at
/// bit i and the repair packet at bit [total].
///
/// ```
///   off  size  field
///   0    1     photo id
///   1    1     data packets
///   2    2     missing, big-endian
/// ```
///
/// The app sends it as a channel request; the photo's sender answers with
/// the packets again ([photoPacketAgain]). A longer body is read as far as
/// this.
Uint8List photoPacketsRequest({
  required int imgId,
  required int total,
  required int missing,
}) => Uint8List.fromList([
  imgId & 0xFF,
  total & 0xFF,
  (missing >> 8) & 0xFF,
  missing & 0xFF,
]);

/// What a [photoPacketsRequest] body asks for, or null when it can't be one.
({int imgId, int total, int missing})? readPhotoPacketsRequest(
  Uint8List body,
) {
  if (body.length < 4) return null;
  final total = body[1];
  if (total == 0 || total > kImageMaxDataChunks) return null;
  final missing = ((body[2] << 8) | body[3]) & ((1 << (total + 1)) - 1);
  return (imgId: body[0], total: total, missing: missing);
}
