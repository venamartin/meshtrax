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

      // Match on the first byte of the slot (the identifying hash prefix)
      final firstByte = trimmed[i];
      final matches = allContacts
          .where(
            (c) =>
                c.publicKey.isNotEmpty &&
                c.publicKey.first == firstByte &&
                (c.type == advTypeRepeater || c.type == advTypeRoom),
          )
          .toList();

      if (matches.isEmpty) {
        hops.add(hexLabel.toString());
      } else if (matches.length == 1) {
        hops.add(matches.first.name);
      } else {
        hops.add(matches.map((c) => c.name).join(' | '));
      }
    }
    return hops.join(' \u2192 ');
  }
}
