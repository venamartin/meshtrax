import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Why a region name can't be used, see [RegionHelper.check].
enum RegionNameProblem { empty, tooLong, badCharacter }

/// The firmware's region rules (MeshCore src/helpers/RegionMap.cpp and
/// TransportKeyStore.cpp); see docs/technical/regions.md.
class RegionHelper {
  /// The firmware keeps a name in 31 bytes with its terminator.
  static const int maxNameBytes = 30;

  /// Stored in place of a name: the channel sends with no region even when
  /// the radio has a default one. The firmware's own word for "no region".
  static const String everywhere = '*';

  /// [name] with one leading '#' taken off, as the firmware matches names.
  static String normalize(String name) {
    final trimmed = name.trim();
    return trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  }

  /// Null when the firmware accepts [name] (after [normalize]).
  static RegionNameProblem? check(String name) {
    final bytes = utf8.encode(normalize(name));
    if (bytes.isEmpty) return RegionNameProblem.empty;
    if (bytes.length > maxNameBytes) return RegionNameProblem.tooLong;
    // RegionMap::is_name_char, byte by byte. '$' names need the firmware's
    // key store, which isn't built, so they are refused here.
    final allowed = bytes.every(
      (c) =>
          c == 0x2D || c == 0x23 || (c >= 0x30 && c <= 0x39) || c >= 0x41,
    );
    return allowed ? null : RegionNameProblem.badCharacter;
  }

  /// The 16-byte key: SHA-256 of '#' + name, as written (case matters).
  static Uint8List keyFor(String name) {
    final hashed = '#${normalize(name)}';
    return Uint8List.fromList(
      crypto.sha256.convert(utf8.encode(hashed)).bytes.sublist(0, 16),
    );
  }

  /// The 2-byte code a packet in this region carries:
  /// HMAC-SHA256(key, payload type + payload), little-endian, 0000 and FFFF
  /// reserved.
  static int transportCode(Uint8List key, int payloadType, Uint8List payload) {
    final mac = crypto.Hmac(crypto.sha256, key)
        .convert([payloadType, ...payload]).bytes;
    final code = mac[0] | (mac[1] << 8);
    if (code == 0) return 1;
    if (code == 0xFFFF) return 0xFFFE;
    return code;
  }
}
