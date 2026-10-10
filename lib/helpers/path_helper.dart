import 'dart:typed_data';
import '../models/contact.dart';
import '../connector/meshcore_protocol.dart';

/// The one owner of path-hash math.
///
/// A MeshCore path is a run of repeater hash prefixes, each [stride] bytes
/// wide. The wire path_len byte packs the hop count (bits 0-5) with the width
/// (bits 6-7, width − 1), so every path carries its own width and every caller
/// must say which width it is working at. There is no default: a silently
/// assumed 1 byte is how 2-byte routes turned into "4 hops · A2,77,BE,EF".
class PathHelper {
  // ── path_len byte codec (firmware Packet.h getPathHashSize/Count) ──

  /// Hash width in bytes from a path_len byte. 0xFF (route unknown, or a
  /// signed read of -1) reads as 1.
  static int pathLenWidth(int pathLenByte) {
    final b = pathLenByte & 0xFF;
    if (b == 0xFF) return 1;
    return ((b >> 6) & 0x03) + 1;
  }

  /// Hop count from a path_len byte; 0xFF means "no route" and reads as -1.
  static int pathLenHops(int pathLenByte) {
    final b = pathLenByte & 0xFF;
    if (b == 0xFF) return -1;
    return b & 0x3F;
  }

  /// Byte length of the path that follows a wire path_len byte. No 0xFF
  /// special case on purpose: it decodes to an impossible 252, so a malformed
  /// raw frame keeps failing its read instead of parsing garbage.
  static int pathLenBytes(int pathLenByte) {
    final b = pathLenByte & 0xFF;
    return (b & 0x3F) * (((b >> 6) & 0x03) + 1);
  }

  /// Packs a hop count and width into a path_len byte; a negative count is
  /// "no route" (0xFF).
  static int encodePathLen(int hopCount, int width) {
    if (hopCount < 0 || hopCount >= 0xFF) return 0xFF;
    return (hopCount & 0x3F) | ((width - 1).clamp(0, 3) << 6);
  }

  /// Flags byte for CMD_SEND_TRACE_PATH, or null when the width has no trace
  /// encoding. The firmware reads `path_sz = flags & 0x03` as the log2 of the
  /// entry width (Mesh.cpp: each entry is `1 << path_sz` bytes), so only 1, 2
  /// and 4-byte hashes can be traced.
  static int? traceFlags(int width) => switch (width) {
        1 => 0,
        2 => 1,
        4 => 2,
        _ => null,
      };

  /// CMD_SET_PATH_HASH_MODE value for an on-air width (mode 0..2 → 1..3 B).
  static int hashModeFromWidth(int width) => (width - 1).clamp(0, 2);

  /// Hops that fit in the 64-byte path buffer at [stride].
  static int maxHops(int stride) => maxPathSize ~/ stride;

  /// Longest text the custom-path editor accepts at [stride]: every hop as
  /// hex, comma separated.
  static int maxPathInputChars(int stride) =>
      maxHops(stride) * (stride * 2 + 1) - 1;

  // ── path bytes ──

  /// The valid prefix of a path buffer, stopping at the first slot whose
  /// first byte is 0x00. No repeater hash begins with 0x00, so the first byte
  /// of a [stride]-wide slot is the padding sentinel: `[0x00, 0x??]` stops,
  /// `[0xAA, 0x00]` is kept (hash 0xAA00).
  static List<int> trimPaddingZeros(
    List<int> pathBytes, {
    required int stride,
  }) {
    for (int i = 0; i < pathBytes.length; i += stride) {
      if (pathBytes[i] == 0x00) return pathBytes.sublist(0, i);
    }
    return pathBytes;
  }

  /// Splits a path buffer into its hops at [stride].
  static List<Uint8List> getHops(List<int> pathBytes, {required int stride}) {
    final trimmed = trimPaddingZeros(pathBytes, stride: stride);
    final hops = <Uint8List>[];
    for (int i = 0; i < trimmed.length; i += stride) {
      final end = (i + stride > trimmed.length) ? trimmed.length : i + stride;
      hops.add(Uint8List.fromList(trimmed.sublist(i, end)));
    }
    return hops;
  }

  static int getHopCount(List<int> pathBytes, {required int stride}) {
    return trimPaddingZeros(pathBytes, stride: stride).length ~/ stride;
  }

  /// The leading [stride] bytes of a public key: the node's on-air hash
  /// prefix, its identity in a path.
  static Uint8List pubKeyPrefix(List<int> publicKey, {required int stride}) {
    final n = stride.clamp(1, publicKey.length);
    return Uint8List.fromList(publicKey.sublist(0, n));
  }

  /// One hop as a hex token (e.g. "AA" or "AA77").
  static String hopHex(List<int> hop) => hop
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();

  static String? firstHopHex(List<int> pathBytes, {required int stride}) {
    final hops = getHops(pathBytes, stride: stride);
    return hops.isEmpty ? null : hopHex(hops.first);
  }

  static Uint8List? lastHop(List<int> pathBytes, {required int stride}) {
    final hops = getHops(pathBytes, stride: stride);
    return hops.isEmpty ? null : hops.last;
  }

  static String? lastHopHex(List<int> pathBytes, {required int stride}) {
    final hop = lastHop(pathBytes, stride: stride);
    return hop == null ? null : hopHex(hop);
  }

  static Uint8List reverseHops(List<int> pathBytes, {required int stride}) {
    return Uint8List.fromList(
      getHops(pathBytes, stride: stride).reversed.expand((h) => h).toList(),
    );
  }

  static Uint8List dropLastHop(List<int> pathBytes, {required int stride}) {
    if (pathBytes.length < stride) return Uint8List(0);
    return Uint8List.fromList(
      pathBytes.sublist(0, pathBytes.length - stride),
    );
  }

  /// The out-and-back path for a round-trip trace: the original hops,
  /// optionally the target node itself, then the hops reversed.
  ///
  /// With [viaTargetPubKey] the target's hash prefix becomes the turnaround
  /// hop and every hop repeats on the way back. Without it, the turnaround
  /// hop is not repeated (the far node itself answers the trace).
  static Uint8List roundTripPath(
    List<int> pathBytes, {
    required int stride,
    List<int>? viaTargetPubKey,
  }) {
    final hops = getHops(pathBytes, stride: stride);
    final writer = BytesBuilder();
    writer.add(pathBytes);
    if (viaTargetPubKey != null) {
      writer.add(pubKeyPrefix(viaTargetPubKey, stride: stride));
      for (final hop in hops.reversed) {
        writer.add(hop);
      }
    } else {
      for (final hop in hops.reversed.skip(1)) {
        writer.add(hop);
      }
    }
    return writer.toBytes();
  }

  /// Whether [pathBytes] is already a complete round trip: a palindrome of at
  /// least three hops (e.g. A2 → F5 → A2). Such a path must be sent verbatim;
  /// passing it through [roundTripPath] would append a second return trip and
  /// make every hop report its SNR twice.
  static bool isRoundTrip(List<int> pathBytes, {required int stride}) {
    final hops = getHops(pathBytes, stride: stride);
    if (hops.length < 3) return false;
    for (int i = 0, j = hops.length - 1; i < j; i++, j--) {
      final a = hops[i];
      final b = hops[j];
      if (a.length != b.length) return false;
      for (int k = 0; k < a.length; k++) {
        if (a[k] != b[k]) return false;
      }
    }
    return true;
  }

  /// Parses user-entered comma-separated hop prefixes ("AA77, A277") into
  /// path bytes. Each token must supply [stride] bytes (stride × 2 hex
  /// chars); characters beyond the prefix are ignored. Tokens that are too
  /// short or non-hex come back in `invalid`.
  static ({Uint8List path, List<String> invalid}) parsePathHex(
    String text, {
    required int stride,
  }) {
    final bytes = <int>[];
    final invalid = <String>[];
    final chars = stride * 2;
    for (final token
        in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      if (token.length < chars) {
        invalid.add(token);
        continue;
      }
      final hop = <int>[];
      for (var i = 0; i < chars; i += 2) {
        final b = int.tryParse(token.substring(i, i + 2), radix: 16);
        if (b == null) break;
        hop.add(b);
      }
      if (hop.length == stride) {
        bytes.addAll(hop);
      } else {
        invalid.add(token);
      }
    }
    return (path: Uint8List.fromList(bytes), invalid: invalid);
  }

  /// Comma-separated hex tokens, one per hop ("A277,BEEF").
  static String formatPathHex(List<int> pathBytes, {required int stride}) {
    return getHops(pathBytes, stride: stride).map(hopHex).join(',');
  }

  /// Hops as repeater/room names where a contact's prefix matches at
  /// [stride], hex otherwise; ambiguous prefixes list every match.
  static String resolvePathNames(
    List<int> pathBytes,
    List<Contact> allContacts, {
    required int stride,
  }) {
    final hops = <String>[];
    for (final hop in getHops(pathBytes, stride: stride)) {
      final prefixStr = hopHex(hop);
      final matches = allContacts
          .where(
            (c) =>
                c.publicKey.isNotEmpty &&
                c.hashPrefixWithStride(stride) == prefixStr &&
                (c.type == advTypeRepeater || c.type == advTypeRoom),
          )
          .toList();

      if (matches.isEmpty) {
        hops.add(prefixStr);
      } else if (matches.length == 1) {
        hops.add(matches.first.name);
      } else {
        hops.add(matches.map((c) => c.name).join(' | '));
      }
    }
    return hops.join(' → ');
  }
}
