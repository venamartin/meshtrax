import 'dart:typed_data';
import 'package:meshtrax/utils/app_logger.dart';

import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';

class Contact {
  final Uint8List publicKey;
  final String name;
  final int type;
  final int flags;
  final int pathLength; // -1 = flood, 0+ = direct hops (from device)
  final Uint8List path; // Path bytes from device
  final int pathHashSize; // The hash size (1, 2, or 3) used for this path
  final int? pathOverride; // User's path override: -1 = force flood, null = auto
  final Uint8List? pathOverrideBytes; // User's path override bytes
  final double? latitude;
  final double? longitude;
  final DateTime lastSeen;
  final DateTime lastMessageAt;
  final bool isActive;
  final bool wasPulled;
  final Uint8List? rawPacket;

  Contact({
    required this.publicKey,
    required this.name,
    required this.type,
    this.flags = 0,
    required this.pathLength,
    required this.path,
    this.pathHashSize = 1,
    this.pathOverride,
    this.pathOverrideBytes,
    this.latitude,
    this.longitude,
    required this.lastSeen,
    DateTime? lastMessageAt,
    this.isActive = true,
    this.wasPulled = false,
    this.rawPacket,
  }) : lastMessageAt = lastMessageAt ?? lastSeen;

  String get publicKeyHex => pubKeyToHex(publicKey);

  String get displayPathString => PathHelper.formatPathHex(path, stride: pathHashSize);

  String get typeLabel {
    switch (type) {
      case advTypeChat:
        return 'Chat';
      case advTypeRepeater:
        return 'Repeater';
      case advTypeRoom:
        return 'Room';
      case advTypeSensor:
        return 'Sensor';
      default:
        return 'Unknown';
    }
  }

  String get pathLabel {
    if (pathOverride != null) {
      if (pathOverride! < 0) return 'Flood (forced)';
      if (pathOverride == 0) return 'Direct (forced)';
      // Derive hop count from bytes when available — pathOverride int
      // may be stale if it was stored as a raw byte count by older code.
      if (pathOverrideBytes != null && pathOverrideBytes!.isNotEmpty) {
        final hopCount = PathHelper.getHopCount(pathOverrideBytes!, stride: pathHashSize);
        if (hopCount == 0) return 'Direct (forced)';
        return '$hopCount hops (forced)';
      }
      return '$pathOverride hops (forced)';
    }
    if (pathLength < 0) return 'Flood';
    if (pathLength == 0) return 'Direct';
    return '$pathLength hops';
  }

  bool get hasLocation {
    const double epsilon = 1e-6;
    final lat = latitude ?? 0.0;
    final lon = longitude ?? 0.0;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  bool get isFavorite => (flags & contactFlagFavorite) != 0;

  Contact copyWith({
    Uint8List? publicKey,
    String? name,
    int? type,
    int? flags,
    int? pathLength,
    Uint8List? path,
    int? pathOverride,
    Uint8List? pathOverrideBytes,
    bool clearPathOverride = false,
    double? latitude,
    double? longitude,
    DateTime? lastSeen,
    DateTime? lastMessageAt,
    bool? isActive,
    int? pathHashSize,
    Uint8List? rawPacket,
  }) {
    return Contact(
      publicKey: publicKey ?? this.publicKey,
      name: name ?? this.name,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      pathLength: pathLength ?? this.pathLength,
      path: path ?? this.path,
      pathHashSize: pathHashSize ?? this.pathHashSize,
      pathOverride: clearPathOverride
          ? null
          : (pathOverride ?? this.pathOverride),
      pathOverrideBytes: clearPathOverride
          ? null
          : (pathOverrideBytes ?? this.pathOverrideBytes),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      rawPacket: rawPacket ?? this.rawPacket,
    );
  }

  /// Formats path bytes into comma-separated hex groups of [hashSize] bytes.
  String pathFormattedIdList(int hashSize) {
    if (path.isEmpty) return '';
    return PathHelper.formatPathHex(path, stride: hashSize > 0 ? hashSize : 1);
  }

  String get pathIdList => pathFormattedIdList(pathHashSize);

  /// The repeater's own identity hash prefix (the first hop equivalent) based on its public key
  /// formatted with the provided [stride] width.
  String hashPrefixWithStride(int stride) {
    if (publicKey.isEmpty) return '';
    return PathHelper.formatPathHex(publicKey, stride: stride > 0 ? stride : 1).split(',').first;
  }

  /// The repeater's own identity hash prefix using the contact's saved pathHashSize.
  String get hashPrefix => hashPrefixWithStride(pathHashSize);

  String get shortPubKeyHex {
    return "<${publicKeyHex.substring(0, 8)}...${publicKeyHex.substring(publicKeyHex.length - 8)}>";
  }

  Uint8List get pathBytesForDisplay {
    if (pathOverride != null) {
      if (pathOverride! < 0) return Uint8List(0);
      return pathOverrideBytes ?? Uint8List(0);
    }
    return path;
  }

  static Contact? fromFrame(Uint8List data) {
    if (data.isEmpty) return null;
    final reader = BufferReader(data);
    try {
      final respCode = reader.readByte();
      if (respCode != respCodeContact && respCode != pushCodeNewAdvert) {
        return null;
      }
      final pubKey = reader.readBytes(pubKeySize);

      // Guard: reject contacts with zeroed or mostly-zeroed public keys
      // (indicates corrupt flash storage on the firmware side)
      final zeroCount = pubKey.where((b) => b == 0).length;
      if (zeroCount > pubKeySize ~/ 2) return null;

      final type = reader.readByte();
      final flags = reader.readByte();
      final pathLenByte = reader.readByte();
      final hopCount = extractPathHopCount(pathLenByte);
      final hashSize = extractPathHashSize(pathLenByte);
      
      final actualPathBytesLen = hopCount > 0 ? hopCount * hashSize : 0;
      final safePathLen = actualPathBytesLen > maxPathSize ? maxPathSize : actualPathBytesLen;
      final pathBytes = reader.readBytes(maxPathSize).sublist(0, safePathLen);
      final name = reader.readCStringGreedy(maxNameSize);

      // Guard: reject contacts with non-printable names (corrupt flash data)
      if (name.isNotEmpty &&
          name.codeUnits.every((c) => c < 0x20 || c == 0xFFFD)) {
        return null;
      }

      final lastAdvertTimestamp = reader.readUInt32LE();

      double? lat, lon;
      if (reader.remaining >= 8) {
        final latRaw = reader.readInt32LE();
        final lonRaw = reader.readInt32LE();
        if (latRaw != 0 || lonRaw != 0) {
          lat = latRaw / 1e6;
          lon = lonRaw / 1e6;
        }
      }

      int? lastMod;
      if (reader.remaining >= 4) {
        lastMod = reader.readUInt32LE();
      }

      // If lastMod is missing or 0, fallback to lastAdvertTimestamp
      final effectiveLastSeen = (lastMod != null && lastMod > 0)
          ? lastMod
          : lastAdvertTimestamp;

      final actualHopCount = hopCount < 0 ? -1 : PathHelper.getHopCount(pathBytes, stride: hashSize);

      return Contact(
        publicKey: pubKey,
        name: name.isEmpty ? 'Unknown' : name,
        type: type,
        flags: flags,
        pathLength: actualHopCount,
        path: pathBytes,
        pathHashSize: hashSize,
        latitude: lat,
        longitude: lon,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(effectiveLastSeen * 1000),
        isActive: true,
        rawPacket: null,
      );
    } catch (e) {
      appLogger.error('Failed to parse contact frame: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    // Only export the relevant portion of the path buffer
    final actualBytesLen = pathLength * pathHashSize;
    final effectivePath = (pathLength > 0 && actualBytesLen <= path.length)
        ? path.sublist(0, actualBytesLen)
        : Uint8List(0);

    return {
      'publicKey': pubKeyToHex(publicKey),
      'name': name,
      'type': type,
      'flags': flags,
      'pathLength': pathLength,
      'path': pubKeyToHex(effectivePath),
      'pathHashSize': pathHashSize,
      'pathOverride': pathOverride,
      'pathOverrideBytes': (pathOverrideBytes != null && pathOverrideBytes!.isNotEmpty) 
          ? pubKeyToHex(pathOverrideBytes!) 
          : null,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'wasPulled': wasPulled,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    final pathHex = json['path'] as String? ?? '';
    final pathOverrideBytesHex = json['pathOverrideBytes'] as String?;
    return Contact(
      publicKey: hex2Uint8List(json['publicKey'] as String),
      name: json['name'] as String,
      type: json['type'] as int,
      flags: (json['flags'] as num?)?.toInt() ?? 0,
      pathLength: json['pathLength'] as int,
      path: pathHex.isEmpty ? Uint8List(0) : hex2Uint8List(pathHex),
      pathHashSize: (json['pathHashSize'] as num?)?.toInt() ?? 1,
      pathOverride: json['pathOverride'] as int?,
      pathOverrideBytes: (pathOverrideBytesHex != null && pathOverrideBytesHex.isNotEmpty)
          ? hex2Uint8List(pathOverrideBytesHex)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageAt'] as int)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      wasPulled: json['wasPulled'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Contact && publicKeyHex == other.publicKeyHex;

  @override
  int get hashCode => publicKeyHex.hashCode;
  bool get teleBaseEnabled => (flags & contactFlagTeleBase) != 0;
  bool get teleLocEnabled => (flags & contactFlagTeleLoc) != 0;
  bool get teleEnvEnabled => (flags & contactFlagTeleEnv) != 0;
}
