import 'dart:typed_data';
import '../models/contact.dart';
import '../connector/meshcore_protocol.dart';

class PathHelper {
  /// Returns the valid prefix of a path buffer, stopping at the first hop
  /// whose **first byte is 0x00**.
  ///
  /// Rule: no valid repeater public-key hash ever begins with 0x00, regardless
  /// of hash width. So the first byte of a [stride]-wide slot is the sentinel:
  ///
  ///   • 1-byte hashes (current):  slot = [0x00]          → stop
  ///   • 2-byte hashes (future):   slot = [0x00, 0x??]    → stop
  ///                               slot = [0xAA, 0x00]    → keep  (e.g. 0xAA00)
  ///
  /// When the protocol moves to multi-byte hashes, callers must pass the
  /// correct [stride] (== pathHashByteWidth from MeshCoreConnector).
  static List<int> trimPaddingZeros(List<int> pathBytes, {int stride = 1}) {
    for (int i = 0; i < pathBytes.length; i += stride) {
      if (pathBytes[i] == 0x00) return pathBytes.sublist(0, i);
    }
    return pathBytes;
  }

  /// Splits a path buffer into a list of individual hops, based on [stride].
  static List<Uint8List> getHops(List<int> pathBytes, {int stride = 1}) {
    final trimmed = trimPaddingZeros(pathBytes, stride: stride);
    final hops = <Uint8List>[];
    for (int i = 0; i < trimmed.length; i += stride) {
      final end = (i + stride > trimmed.length) ? trimmed.length : i + stride;
      hops.add(Uint8List.fromList(trimmed.sublist(i, end)));
    }
    return hops;
  }

  /// Calculates the number of hops in a raw path buffer.
  static int getHopCount(List<int> pathBytes, {int stride = 1}) {
    return trimPaddingZeros(pathBytes, stride: stride).length ~/ stride;
  }

  /// The leading [stride] bytes of a public key — the node's on-air hash
  /// prefix (its identity in a path).
  static Uint8List pubKeyPrefix(List<int> publicKey, {int stride = 1}) {
    final n = stride.clamp(1, publicKey.length);
    return Uint8List.fromList(publicKey.sublist(0, n));
  }

  /// Formats a single hop as one hex token (e.g. "AA" or "AA77").
  static String hopHex(List<int> hop) => hop
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();

  /// Hex token of the first hop, or null when the path has no hops.
  static String? firstHopHex(List<int> pathBytes, {int stride = 1}) {
    final hops = getHops(pathBytes, stride: stride);
    return hops.isEmpty ? null : hopHex(hops.first);
  }

  /// Hex token of the last hop, or null when the path has no hops.
  static String? lastHopHex(List<int> pathBytes, {int stride = 1}) {
    final hops = getHops(pathBytes, stride: stride);
    return hops.isEmpty ? null : hopHex(hops.last);
  }

  /// Returns the path with its hops in reverse order.
  static Uint8List reverseHops(List<int> pathBytes, {int stride = 1}) {
    return Uint8List.fromList(
      getHops(pathBytes, stride: stride).reversed.expand((h) => h).toList(),
    );
  }

  /// Returns the path without its final hop.
  static Uint8List dropLastHop(List<int> pathBytes, {int stride = 1}) {
    if (pathBytes.length < stride) return Uint8List(0);
    return Uint8List.fromList(
      pathBytes.sublist(0, pathBytes.length - stride),
    );
  }

  /// Builds the out-and-back path used for a round-trip trace: the original
  /// hops, optionally the target node itself, then the hops reversed.
  ///
  /// With [viaTargetPubKey] the target's hash prefix becomes the turnaround
  /// hop and every hop repeats on the way back. Without it, the turnaround
  /// hop is not repeated (the far node itself answers the trace).
  static Uint8List roundTripPath(
    List<int> pathBytes, {
    int stride = 1,
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

  /// Parses user-entered comma-separated hop prefixes ("AA77, A277") into
  /// path bytes. Each token must supply [stride] bytes (stride × 2 hex
  /// chars); characters beyond the prefix are ignored. Tokens that are too
  /// short or non-hex are returned in `invalid`.
  static ({Uint8List path, List<String> invalid}) parsePathHex(
    String text, {
    int stride = 1,
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


  /// Legacy alias – kept so call-sites that don't have stride available still
  /// compile (they fall back to stride=1 which is correct for current firmware).
  static List<int> trimTrailingZeros(List<int> pathBytes) =>
      trimPaddingZeros(pathBytes);

  static String formatPathHex(List<int> pathBytes, {int stride = 1}) {
    final trimmed = trimPaddingZeros(pathBytes, stride: stride);
    if (trimmed.isEmpty) return '';
    // Format each stride-wide slot as a single hex token (e.g. "AA" or "AA77")
    final buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i += stride) {
      if (i > 0) buffer.write(',');
      for (int j = 0; j < stride && (i + j) < trimmed.length; j++) {
        buffer.write(
          trimmed[i + j].toRadixString(16).padLeft(2, '0').toUpperCase(),
        );
      }
    }
    return buffer.toString();
  }

  static String resolvePathNames(
    List<int> pathBytes,
    List<Contact> allContacts, {
    int stride = 1,
  }) {
    final trimmed = trimPaddingZeros(pathBytes, stride: stride);
    if (trimmed.isEmpty) return '';

    final hops = <String>[];
    for (int i = 0; i < trimmed.length; i += stride) {
      // Build the hex label for this slot
      final hexLabel = StringBuffer();
      for (int j = 0; j < stride && (i + j) < trimmed.length; j++) {
        hexLabel.write(
          trimmed[i + j].toRadixString(16).padLeft(2, '0').toUpperCase(),
        );
      }

      // Match on the full hex label for this slot
      final prefixStr = hexLabel.toString();
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
    return hops.join(' \u2192 ');
  }
}
