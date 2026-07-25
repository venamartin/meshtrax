import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/contact.dart';
import '../utils/app_logger.dart';
import '../helpers/path_helper.dart';
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

  AppDatabase get _db => AppDatabase.instance;

  Future<List<Contact>> loadContacts() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load contacts.');
      return [];
    }
    await _importLegacyBlobs();
    final rows =
        await (_db.select(_db.contactRows)
              ..where((r) => r.nodeScope.equals(publicKeyHex)))
            .get();
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
  }

  /// One-time import of the prefs JSON blobs (scoped first, then the
  /// ancient unscoped key); the keys are removed either way.
  Future<void> _importLegacyBlobs() async {
    final prefs = PrefsManager.instance;
    for (final key in [keyFor, _keyPrefix]) {
      final jsonString = prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        final existing =
            await (_db.select(_db.contactRows)
                  ..where((r) => r.nodeScope.equals(publicKeyHex))
                  ..limit(1))
                .getSingleOrNull();
        if (existing == null) {
          try {
            final jsonList = jsonDecode(jsonString) as List<dynamic>;
            await _db.batch((b) {
              b.insertAll(
                _db.contactRows,
                [
                  for (final entry in jsonList)
                    ContactRowsCompanion.insert(
                      nodeScope: publicKeyHex,
                      publicKeyHex: _fromJson(
                        entry as Map<String, dynamic>,
                      ).publicKeyHex,
                      payload: jsonEncode(entry),
                    ),
                ],
                mode: InsertMode.insertOrIgnore,
              );
            });
            appLogger.info('Imported contact cache from legacy key $key');
          } catch (e) {
            appLogger.warn('Failed contact cache import from $key: $e');
          }
        }
      }
      await prefs.remove(key);
    }
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
      'isActive': contact.isActive,
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
      isActive: json['isActive'] as bool? ?? true,
      rawPacket: json['rawPacket'] != null
          ? Uint8List.fromList(base64Decode(json['rawPacket'] as String))
          : null,
    );
  }
}
