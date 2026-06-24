import 'dart:convert';
import 'dart:typed_data';

import '../models/contact.dart';
import '../helpers/path_helper.dart';
import 'prefs_manager.dart';

class ContactDiscoveryStore {
  static const String _keyPrefix = 'discovered_contacts';

  Future<List<Contact>> loadContacts() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_keyPrefix);
    if (jsonStr == null) return [];

    try {
      final jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList
          .map((entry) => _fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = PrefsManager.instance;
    final jsonList = contacts.map(_toJson).toList();
    await prefs.setString(_keyPrefix, jsonEncode(jsonList));
  }

  Map<String, dynamic> _toJson(Contact contact) {
    return {
      'publicKey': base64Encode(contact.publicKey),
      'name': contact.name,
      'type': contact.type,
      'flags': contact.flags,
      'pathLength': contact.pathLength,
      'path': base64Encode(contact.path),
      'pathOverride': contact.pathOverride,
      'pathOverrideBytes': contact.pathOverrideBytes != null
          ? base64Encode(contact.pathOverrideBytes!)
          : null,
      'latitude': contact.latitude,
      'longitude': contact.longitude,
      'lastSeen': contact.lastSeen.millisecondsSinceEpoch,
      'lastMessageAt': contact.lastMessageAt.millisecondsSinceEpoch,
      'rawPacket': contact.rawPacket != null
          ? base64Encode(contact.rawPacket!)
          : null,
    };
  }

  Contact _fromJson(Map<String, dynamic> json) {
    final lastSeenMs = json['lastSeen'] as int? ?? 0;
    final lastMessageMs = json['lastMessageAt'] as int?;
    final pathBytes = json['path'] != null
        ? Uint8List.fromList(base64Decode(json['path'] as String))
        : Uint8List(0);
    final pathHashSize = json['pathHashSize'] as int? ?? 1;

    return Contact(
      publicKey: Uint8List.fromList(base64Decode(json['publicKey'] as String)),
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as int? ?? 0,
      flags: json['flags'] as int? ?? 0,
      pathLength: () {
        if (pathBytes.isNotEmpty) {
          return PathHelper.getHopCount(pathBytes, stride: pathHashSize);
        }
        int pLen = json['pathLength'] as int? ?? -1;
        if (pLen > 0) {
          pLen = (pLen == 0xFF) ? -1 : (pLen & 0x3F);
        }
        return pLen;
      }(),
      path: pathBytes,
      pathHashSize: pathHashSize,
      pathOverride: json['pathOverride'] as int?,
      pathOverrideBytes: json['pathOverrideBytes'] != null
          ? Uint8List.fromList(
              base64Decode(json['pathOverrideBytes'] as String),
            )
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMs),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        lastMessageMs ?? lastSeenMs,
      ),
      isActive: false,
      rawPacket: json['rawPacket'] != null
          ? Uint8List.fromList(base64Decode(json['rawPacket'] as String))
          : null,
    );
  }
}
