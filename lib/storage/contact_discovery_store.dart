import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/contact.dart';
import '../helpers/path_helper.dart';
import 'app_database.dart';
import 'prefs_manager.dart';

/// Discovered-but-not-saved contacts. Unlike the saved-contact cache this is
/// NOT a mirror of anything — the radio cannot regenerate it — so the write
/// API is deliberately upsert-per-key plus targeted deletes. There is no
/// whole-list replacement: a caller holding a stale or empty in-memory list
/// must never be able to erase rows it didn't load.
class ContactDiscoveryStore {
  static const String _keyPrefix = 'discovered_contacts';

  /// Discovery results are shared across radios (legacy semantics) — a
  /// fixed scope keeps the schema uniform with the node-scoped caches.
  static const String _scope = 'global';

  AppDatabase get _db => AppDatabase.instance;

  Future<List<Contact>> loadContacts() async {
    await _importLegacyBlob();
    final rows =
        await (_db.select(_db.discoveredContactRows)
              ..where((r) => r.nodeScope.equals(_scope)))
            .get();
    final contacts = <Contact>[];
    for (final row in rows) {
      try {
        contacts.add(
          _fromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        );
      } catch (_) {}
    }
    return contacts;
  }

  Future<void> upsertContacts(List<Contact> contacts) async {
    if (contacts.isEmpty) return;
    final rows = [
      for (final contact in contacts)
        DiscoveredContactRowsCompanion.insert(
          nodeScope: _scope,
          publicKeyHex: contact.publicKeyHex,
          payload: jsonEncode(_toJson(contact)),
        ),
    ];
    await _db.batch((b) {
      b.insertAll(
        _db.discoveredContactRows,
        rows,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> removeContacts(Iterable<String> publicKeyHexes) async {
    final keys = publicKeyHexes.toList();
    if (keys.isEmpty) return;
    await (_db.delete(_db.discoveredContactRows)
          ..where((r) => r.nodeScope.equals(_scope) & r.publicKeyHex.isIn(keys)))
        .go();
  }

  /// One-time import of the legacy prefs blob.
  Future<void> _importLegacyBlob() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_keyPrefix);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final existing =
          await (_db.select(_db.discoveredContactRows)
                ..where((r) => r.nodeScope.equals(_scope))
                ..limit(1))
              .getSingleOrNull();
      if (existing == null) {
        try {
          final jsonList = jsonDecode(jsonStr) as List<dynamic>;
          await _db.batch((b) {
            b.insertAll(
              _db.discoveredContactRows,
              [
                for (final entry in jsonList)
                  DiscoveredContactRowsCompanion.insert(
                    nodeScope: _scope,
                    publicKeyHex: _fromJson(
                      entry as Map<String, dynamic>,
                    ).publicKeyHex,
                    payload: jsonEncode(entry),
                  ),
              ],
              mode: InsertMode.insertOrIgnore,
            );
          });
        } catch (_) {}
      }
    }
    await prefs.remove(_keyPrefix);
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
