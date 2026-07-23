import 'dart:convert';

import 'package:drift/drift.dart';

import '../helpers/smaz.dart';
import '../models/message.dart';
import '../utils/app_logger.dart';
import 'app_database.dart';
import 'prefs_manager.dart';

/// Contact (DM) messages are stored one row per message, keyed by the
/// contact's pubkey with a UNIQUE(nodeScope, contactKey, messageId)
/// constraint — same contract as the channel store. Legacy SharedPreferences
/// JSON blobs import once and are removed; JSON remains only as the payload
/// encoding inside a row and for user-facing export/import.
class MessageStore {
  static const String _keyPrefix = 'messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  AppDatabase get _db => AppDatabase.instance;

  ContactMessageRowsCompanion _toRow(String contactKeyHex, Message msg) {
    return ContactMessageRowsCompanion.insert(
      nodeScope: publicKeyHex,
      contactKey: contactKeyHex,
      messageId: msg.messageId,
      timestampMs: msg.timestamp.millisecondsSinceEpoch,
      payload: jsonEncode(_messageToJson(msg)),
    );
  }

  /// Replace a conversation's stored messages atomically.
  Future<void> saveMessages(
    String contactKeyHex,
    List<Message> messages,
  ) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save messages.');
      return;
    }
    await _db.transaction(() async {
      await (_db.delete(_db.contactMessageRows)..where(
            (r) =>
                r.nodeScope.equals(publicKeyHex) &
                r.contactKey.equals(contactKeyHex),
          ))
          .go();
      await _db.batch((b) {
        b.insertAll(
          _db.contactMessageRows,
          [for (final msg in messages) _toRow(contactKeyHex, msg)],
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// Insert or update a single message — the preferred write path going
  /// forward; no read-modify-write of a whole conversation.
  Future<void> upsertMessage(String contactKeyHex, Message msg) async {
    if (publicKeyHex.isEmpty) return;
    await _db
        .into(_db.contactMessageRows)
        .insert(_toRow(contactKeyHex, msg), mode: InsertMode.insertOrReplace);
  }

  /// Insert-or-update a batch WITHOUT touching any other rows — the only
  /// write live message paths may use. Unlike [saveMessages] this can NEVER
  /// shrink a conversation's stored history.
  Future<void> upsertMessages(
    String contactKeyHex,
    List<Message> messages,
  ) async {
    if (publicKeyHex.isEmpty || messages.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.contactMessageRows,
        [for (final msg in messages) _toRow(contactKeyHex, msg)],
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Remove exactly one message — explicit user deletion only.
  Future<void> deleteMessage(String contactKeyHex, String messageId) async {
    if (publicKeyHex.isEmpty) return;
    await (_db.delete(_db.contactMessageRows)..where(
          (r) =>
              r.nodeScope.equals(publicKeyHex) &
              r.contactKey.equals(contactKeyHex) &
              r.messageId.equals(messageId),
        ))
        .go();
  }

  Future<List<Message>> loadMessages(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load messages.');
      return [];
    }
    await _importLegacyBlobs(contactKeyHex);
    final rows =
        await (_db.select(_db.contactMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.contactKey.equals(contactKeyHex),
              )
              ..orderBy([
                (r) => OrderingTerm.asc(r.timestampMs),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final messages = <Message>[];
    for (final row in rows) {
      try {
        messages.add(
          _messageFromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        );
      } catch (e) {
        appLogger.warn('Skipping unreadable contact message row: $e');
      }
    }
    return messages;
  }

  /// One-time import of the JSON blobs written by the previous store
  /// generation: the node-scoped key and the ancient unscoped key.
  /// Existing rows win (insertOrIgnore).
  Future<void> _importLegacyBlobs(String contactKeyHex) async {
    final prefs = PrefsManager.instance;
    for (final oldKey in [
      '$keyFor$contactKeyHex',
      '$_keyPrefix$contactKeyHex',
    ]) {
      final legacy = prefs.getString(oldKey);
      if (legacy != null && legacy.isNotEmpty) {
        appLogger.info(
          'Migrating contact messages from legacy key $oldKey into database',
        );
        try {
          final jsonList = jsonDecode(legacy) as List<dynamic>;
          final messages = [
            for (final json in jsonList)
              _messageFromJson(json as Map<String, dynamic>),
          ];
          await _db.batch((b) {
            b.insertAll(
              _db.contactMessageRows,
              [for (final msg in messages) _toRow(contactKeyHex, msg)],
              mode: InsertMode.insertOrIgnore,
            );
          });
          appLogger.info('Imported ${messages.length} messages from $oldKey');
        } catch (e) {
          appLogger.warn('Failed to import legacy messages from $oldKey: $e');
        }
      }
      await prefs.remove(oldKey);
    }
  }

  Future<void> clearMessages(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot clear messages.');
      return;
    }
    final prefs = PrefsManager.instance;
    await prefs.remove('$keyFor$contactKeyHex');
    await (_db.delete(_db.contactMessageRows)..where(
          (r) =>
              r.nodeScope.equals(publicKeyHex) &
              r.contactKey.equals(contactKeyHex),
        ))
        .go();
  }

  Map<String, dynamic> _messageToJson(Message msg) {
    return {
      'senderKey': base64Encode(msg.senderKey),
      'text': msg.text,
      'timestamp': msg.timestamp.millisecondsSinceEpoch,
      'isOutgoing': msg.isOutgoing,
      'isCli': msg.isCli,
      'status': msg.status.index,
      'messageId': msg.messageId,

      'retryCount': msg.retryCount,
      'estimatedTimeoutMs': msg.estimatedTimeoutMs,
      'expectedAckHash': msg.expectedAckHash,
      'sentAt': msg.sentAt?.millisecondsSinceEpoch,
      'deliveredAt': msg.deliveredAt?.millisecondsSinceEpoch,
      'tripTimeMs': msg.tripTimeMs,
      'pathLength': msg.pathLength,
      'pathBytes': msg.pathBytes.isNotEmpty
          ? base64Encode(msg.pathBytes)
          : null,
      'reactions': msg.reactions,
      'reactionStatuses': msg.reactionStatuses.map(
        (key, value) => MapEntry(key, value.index),
      ),
      'fourByteRoomContactKey': base64Encode(msg.fourByteRoomContactKey),
    };
  }

  Message _messageFromJson(Map<String, dynamic> json) {
    final rawText = json['text'] as String;
    final isCli = json['isCli'] as bool? ?? false;
    final decodedText = isCli
        ? rawText
        : (Smaz.tryDecodePrefixed(rawText) ?? rawText);
    return Message(
      senderKey: Uint8List.fromList(base64Decode(json['senderKey'] as String)),
      text: decodedText,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isOutgoing: json['isOutgoing'] as bool,
      isCli: isCli,
      status: MessageStatus.values[json['status'] as int],
      messageId: json['messageId'] as String?,

      retryCount: json['retryCount'] as int? ?? 0,
      estimatedTimeoutMs: json['estimatedTimeoutMs'] as int?,
      expectedAckHash: json['expectedAckHash'] as int? ?? 0,
      sentAt: json['sentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sentAt'] as int)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'] as int)
          : null,
      tripTimeMs: json['tripTimeMs'] as int?,
      pathLength: () {
        int? pLen = json['pathLength'] as int?;
        if (pLen != null && pLen > 0) {
          pLen = (pLen == 0xFF) ? -1 : (pLen & 0x3F);
        }
        return pLen;
      }(),
      pathBytes: json['pathBytes'] != null
          ? Uint8List.fromList(base64Decode(json['pathBytes'] as String))
          : Uint8List(0),
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      reactionStatuses:
          (json['reactionStatuses'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, MessageStatus.values[value as int]),
          ) ??
          {},
      fourByteRoomContactKey: json['fourByteRoomContactKey'] != null
          ? Uint8List.fromList(
              base64Decode(json['fourByteRoomContactKey'] as String),
            )
          : null,
    );
  }
}
