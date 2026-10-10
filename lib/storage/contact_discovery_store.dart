import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/contact.dart';

import 'app_database.dart';

/// Discovered-but-not-saved contacts. Unlike the saved-contact cache this is
/// NOT a mirror of anything — the radio cannot regenerate it — so the write
/// API is deliberately upsert-per-key plus targeted deletes. There is no
/// whole-list replacement: a caller holding a stale or empty in-memory list
/// must never be able to erase rows it didn't load.
class ContactDiscoveryStore {

  /// Discovery results are shared across radios (legacy semantics) — a
  /// fixed scope keeps the schema uniform with the node-scoped caches.
  static const String _scope = 'global';

  AppDatabase get _db => AppDatabase.instance;

  Future<List<Contact>> loadContacts() async {
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

  Map<String, dynamic> _toJson(Contact contact) {
    return {
      'publicKey': base64Encode(contact.publicKey),
      'name': contact.name,
      'type': contact.type,
      'flags': contact.flags,
      'pathLength': contact.pathLength,
      'path': base64Encode(contact.path),
      'pathHashSize': contact.pathHashSize,
      'inboundPath': base64Encode(contact.inboundPath),
      'inboundHopCount': contact.inboundHopCount,
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
    return Contact(
      publicKey: Uint8List.fromList(base64Decode(json['publicKey'] as String)),
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as int? ?? 0,
      flags: json['flags'] as int? ?? 0,
      pathLength: json['pathLength'] as int,
      path: Uint8List.fromList(base64Decode(json['path'] as String)),
      // Rows without a width predate it and are unreadable on purpose.
      pathHashSize: json['pathHashSize'] as int,
      inboundPath: json['inboundPath'] != null
          ? Uint8List.fromList(base64Decode(json['inboundPath'] as String))
          : null,
      inboundHopCount: json['inboundHopCount'] as int?,
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
