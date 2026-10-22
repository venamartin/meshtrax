import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/contact.dart';
import '../utils/app_logger.dart';

import 'app_database.dart';
import 'prefs_manager.dart';

/// Cached mirror of the radio's saved-contact list, one row per contact (v5).
/// The RADIO is the source of truth — whole-list replacement on sync is the
/// correct write for a mirror. (Message history is different: it is user
/// data with no backstop, and its stores never delete.)
class ContactStore {
  static const String _keyPrefix = 'contacts';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Newest contact `lastmod` the radio reported at the end of its last
  /// contact list, per radio. Sent back as `since` so the radio streams only
  /// contacts changed after it. Comes only from END_OF_CONTACTS; the Contact
  /// model folds lastmod into lastSeen, which adverts overwrite.
  // Renamed with the v7 cache migration on purpose: the orphaned pre-v7
  // cursor would have let an incremental sync skip the untouched contacts
  // whose cached routes the migration cleared.
  static const String _cursorKeyPrefix = 'contact_sync_cursor_v7_';

  int loadSyncCursor() {
    if (publicKeyHex.isEmpty) return 0;
    return PrefsManager.instance.getInt('$_cursorKeyPrefix$publicKeyHex') ?? 0;
  }

  Future<void> saveSyncCursor(int value) async {
    if (publicKeyHex.isEmpty || value <= 0) return;
    await PrefsManager.instance.setInt('$_cursorKeyPrefix$publicKeyHex', value);
  }

  AppDatabase get _db => AppDatabase.instance;

  Future<List<Contact>> loadContacts() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load contacts.');
      return [];
    }
    final rows =
        await (_db.select(_db.contactRows)
              ..where((r) => r.nodeScope.equals(publicKeyHex)))
            .get();
    if (rows.isEmpty) {
      // No cache, no cursor: the next sync is a full download, which is
      // also how the one-time v7 wipe gets rebuilt.
      await PrefsManager.instance.remove('$_cursorKeyPrefix$publicKeyHex');
    }
    final contacts = <Contact>[];
    for (final row in rows) {
      try {
        contacts.add(
          _fromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        );
      } catch (e) {
        appLogger.warn('Skipping unreadable cached contact row: $e');
      }
    }
    return contacts;
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save contacts.');
      return;
    }
    final sw = Stopwatch()..start();
    await _db.transaction(() async {
      await (_db.delete(_db.contactRows)
            ..where((r) => r.nodeScope.equals(publicKeyHex)))
          .go();
      await _db.batch((b) {
        b.insertAll(
          _db.contactRows,
          [
            for (final contact in contacts)
              ContactRowsCompanion.insert(
                nodeScope: publicKeyHex,
                publicKeyHex: contact.publicKeyHex,
                payload: jsonEncode(_toJson(contact)),
              ),
          ],
          mode: InsertMode.insertOrReplace,
        );
      });
    });
    appLogger.perf('contact table rewrite of ${contacts.length} contacts', sw);
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
      'inboundPathHashSize': contact.inboundPathHashSize,
      'pathOverride': contact.pathOverride,
      'pathOverrideBytes': contact.pathOverrideBytes != null
          ? base64Encode(contact.pathOverrideBytes!)
          : null,
      'pathOverrideHashSize': contact.pathOverrideHashSize,
      'latitude': contact.latitude,
      'longitude': contact.longitude,
      'lastSeen': contact.lastSeen.millisecondsSinceEpoch,
      'lastMessageAt': contact.lastMessageAt.millisecondsSinceEpoch,
      'isActive': contact.isActive,
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
      // Rows without a width predate it and are unreadable on purpose: a
      // guessed width is how 2-byte routes once read as four 1-byte hops.
      pathHashSize: json['pathHashSize'] as int,
      inboundPath: json['inboundPath'] != null
          ? Uint8List.fromList(base64Decode(json['inboundPath'] as String))
          : null,
      inboundHopCount: json['inboundHopCount'] as int?,
      inboundPathHashSize: json['inboundPathHashSize'] as int?,
      pathOverride: json['pathOverride'] as int?,
      pathOverrideBytes: json['pathOverrideBytes'] != null
          ? Uint8List.fromList(
              base64Decode(json['pathOverrideBytes'] as String),
            )
          : null,
      pathOverrideHashSize: json['pathOverrideHashSize'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(lastSeenMs),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        lastMessageMs ?? lastSeenMs,
      ),
      isActive: json['isActive'] as bool? ?? true,
      rawPacket: json['rawPacket'] != null
          ? Uint8List.fromList(base64Decode(json['rawPacket'] as String))
          : null,
    );
  }
}
