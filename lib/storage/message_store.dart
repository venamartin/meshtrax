import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../helpers/reaction_helper.dart';
import '../helpers/smaz.dart';
import '../models/message.dart';
import '../utils/app_logger.dart';
import 'app_database.dart';
import 'arrival_clock.dart';
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

  ContactMessageRowsCompanion _toRow(
    String contactKeyHex,
    Message msg, {
    bool? unreadEligible,
    required int receivedAtUs,
  }) {
    return ContactMessageRowsCompanion.insert(
      nodeScope: publicKeyHex,
      contactKey: contactKeyHex,
      messageId: msg.messageId,
      timestampMs: msg.timestamp.millisecondsSinceEpoch,
      receivedAtUs: Value(receivedAtUs),
      isOutgoing: Value(msg.isOutgoing),
      unreadEligible: Value(
        unreadEligible ?? (!msg.isOutgoing && !msg.isCli),
      ),
      payload: jsonEncode(_messageToJson(msg)),
    );
  }

  /// The arrival stamp a write should carry — see the channel store's
  /// equivalent. insertOrReplace is delete-then-insert, so without this a
  /// delivery receipt would move a DM to the bottom of the conversation.
  Future<int> _arrivalStampFor(String contactKeyHex, String messageId) async {
    if (publicKeyHex.isEmpty) return ArrivalClock.next();
    final existing =
        await (_db.selectOnly(_db.contactMessageRows)
              ..addColumns([_db.contactMessageRows.receivedAtUs])
              ..where(
                _db.contactMessageRows.nodeScope.equals(publicKeyHex) &
                    _db.contactMessageRows.contactKey.equals(contactKeyHex) &
                    _db.contactMessageRows.messageId.equals(messageId),
              )
              ..limit(1))
            .map((r) => r.read(_db.contactMessageRows.receivedAtUs))
            .getSingleOrNull();
    if (existing != null && existing > 0) return existing;
    return ArrivalClock.next();
  }

  /// Arrival stamps already on record for a conversation, by messageId.
  Future<Map<String, int>> _arrivalStampsFor(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) return const {};
    final rows =
        await (_db.selectOnly(_db.contactMessageRows)
              ..addColumns([
                _db.contactMessageRows.messageId,
                _db.contactMessageRows.receivedAtUs,
              ])
              ..where(
                _db.contactMessageRows.nodeScope.equals(publicKeyHex) &
                    _db.contactMessageRows.contactKey.equals(contactKeyHex),
              ))
            .get();
    return {
      for (final r in rows)
        if ((r.read(_db.contactMessageRows.receivedAtUs) ?? 0) > 0)
          r.read(_db.contactMessageRows.messageId)!:
              r.read(_db.contactMessageRows.receivedAtUs)!,
    };
  }

  // --- Phase 3d: the database is the only message state ------------------

  /// Watched, ordered view of a conversation's newest [limit] messages,
  /// emitted oldest-first. The UI's ONLY read path.
  Stream<List<Message>> watchConversation(
    String contactKeyHex, {
    int limit = 200,
  }) {
    if (publicKeyHex.isEmpty) return Stream.value(const []);
    unawaited(_importLegacyBlobs(contactKeyHex));
    final query = (_db.select(_db.contactMessageRows)
      ..where(
        (r) =>
            r.nodeScope.equals(publicKeyHex) &
            r.contactKey.equals(contactKeyHex),
      )
      ..orderBy([
        (r) => OrderingTerm.desc(r.timestampMs),
        (r) => OrderingTerm.desc(r.id),
      ])
      ..limit(limit));
    return query.watch().map((rows) {
      final messages = <Message>[];
      for (final row in rows.reversed) {
        try {
          messages.add(
            _messageFromJson(jsonDecode(row.payload) as Map<String, dynamic>),
          );
        } catch (e) {
          appLogger.warn('Skipping unreadable contact message row: $e');
        }
      }
      return messages;
    });
  }

  /// Atomic ingest: true ONLY when no row with this id exists — the unique
  /// constraint is the dedup authority.
  Future<bool> insertIfNew(
    String contactKeyHex,
    Message msg, {
    bool? unreadEligible,
  }) async {
    if (publicKeyHex.isEmpty) return false;
    final inserted = await _db
        .into(_db.contactMessageRows)
        .insertReturningOrNull(
          // insertOrIgnore: a losing insert changes nothing, so a fresh stamp
          // can never overwrite one we already hold.
          _toRow(
            contactKeyHex,
            msg,
            unreadEligible: unreadEligible,
            receivedAtUs: ArrivalClock.next(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return inserted != null;
  }

  Future<Message?> findByMessageId(
    String contactKeyHex,
    String messageId,
  ) async {
    if (publicKeyHex.isEmpty) return null;
    final row =
        await (_db.select(_db.contactMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.contactKey.equals(contactKeyHex) &
                    r.messageId.equals(messageId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      return _messageFromJson(jsonDecode(row.payload) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Load-transform-upsert of a single row.
  Future<bool> updateMessage(
    String contactKeyHex,
    String messageId,
    Message Function(Message) transform,
  ) async {
    final existing = await findByMessageId(contactKeyHex, messageId);
    if (existing == null) return false;
    await upsertMessage(contactKeyHex, transform(existing));
    return true;
  }

  /// Scope-wide variant for ACK bookkeeping that only holds a messageId;
  /// returns (updated, contactKey).
  Future<(bool, String?)> updateAnyByMessageId(
    String messageId,
    Message Function(Message) transform,
  ) async {
    if (publicKeyHex.isEmpty) return (false, null);
    final row =
        await (_db.select(_db.contactMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.messageId.equals(messageId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return (false, null);
    try {
      final msg = _messageFromJson(
        jsonDecode(row.payload) as Map<String, dynamic>,
      );
      await upsertMessage(row.contactKey, transform(msg));
      return (true, row.contactKey);
    } catch (_) {
      return (false, null);
    }
  }

  /// Fallback ACK bookkeeping when no id is known: flips the NEWEST
  /// outgoing row with status [from] to [to]; returns (updated, contactKey).
  Future<(bool, String?)> promoteLatestOutgoing({
    required MessageStatus from,
    required MessageStatus to,
  }) async {
    if (publicKeyHex.isEmpty) return (false, null);
    final row = await _db
        .customSelect(
          'SELECT contact_key AS k, message_id AS id '
          'FROM contact_message_rows '
          'WHERE node_scope = ?1 AND is_outgoing = 1 '
          "AND json_extract(payload, '\$.status') = ?2 "
          'ORDER BY timestamp_ms DESC LIMIT 1',
          variables: [
            Variable.withString(publicKeyHex),
            Variable.withInt(from.index),
          ],
          readsFrom: {_db.contactMessageRows},
        )
        .getSingleOrNull();
    if (row == null) return (false, null);
    final key = row.read<String>('k');
    final updated = await updateMessage(
      key,
      row.read<String>('id'),
      (m) => m.copyWith(status: to),
    );
    return (updated, key);
  }

  // --- Read marks: unread is a watched COUNT, never a mutable counter ----

  Future<void> markRead(String contactKeyHex, {int? upToMs}) async {
    if (publicKeyHex.isEmpty) return;
    await _db
        .into(_db.contactReadMarks)
        .insertOnConflictUpdate(
          ContactReadMarksCompanion.insert(
            nodeScope: publicKeyHex,
            contactKey: contactKeyHex,
            lastReadMs: Value(
              upToMs ?? DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
  }

  /// First-use initialization so pre-existing history never floods unread.
  Future<void> initializeReadMarkIfAbsent(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) return;
    final newest =
        await (_db.select(_db.contactMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.contactKey.equals(contactKeyHex),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.timestampMs)])
              ..limit(1))
            .getSingleOrNull();
    await _db
        .into(_db.contactReadMarks)
        .insert(
          ContactReadMarksCompanion.insert(
            nodeScope: publicKeyHex,
            contactKey: contactKeyHex,
            lastReadMs: Value(newest?.timestampMs ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Watched unread counts per contact — one query feeds every badge.
  Stream<Map<String, int>> watchUnreadCounts() {
    if (publicKeyHex.isEmpty) return Stream.value(const {});
    return _db
        .customSelect(
          'SELECT m.contact_key AS k, COUNT(*) AS c '
          'FROM contact_message_rows m '
          'WHERE m.node_scope = ?1 AND m.unread_eligible = 1 '
          'AND m.timestamp_ms > COALESCE((SELECT last_read_ms '
          'FROM contact_read_marks '
          'WHERE node_scope = ?1 AND contact_key = m.contact_key), 0) '
          'GROUP BY m.contact_key',
          variables: [Variable.withString(publicKeyHex)],
          readsFrom: {_db.contactMessageRows, _db.contactReadMarks},
        )
        .watch()
        .map((rows) => {
              for (final row in rows)
                row.read<String>('k'): row.read<int>('c'),
            });
  }

  /// Watched newest message per contact (chats screen subtitles/ordering).
  Stream<Map<String, Message>> watchLatestPerContact() {
    if (publicKeyHex.isEmpty) return Stream.value(const {});
    return _db
        .customSelect(
          'SELECT m.contact_key AS k, m.payload AS p '
          'FROM contact_message_rows m '
          'INNER JOIN (SELECT contact_key, MAX(timestamp_ms) AS mx '
          'FROM contact_message_rows WHERE node_scope = ?1 '
          'GROUP BY contact_key) latest '
          'ON m.contact_key = latest.contact_key '
          'AND m.timestamp_ms = latest.mx '
          'WHERE m.node_scope = ?1 GROUP BY m.contact_key',
          variables: [Variable.withString(publicKeyHex)],
          readsFrom: {_db.contactMessageRows},
        )
        .watch()
        .map((rows) {
          final latest = <String, Message>{};
          for (final row in rows) {
            try {
              latest[row.read<String>('k')] = _messageFromJson(
                jsonDecode(row.read<String>('p')) as Map<String, dynamic>,
              );
            } catch (_) {}
          }
          return latest;
        });
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
          [
            for (final msg in messages)
              // This path clears the conversation first, so nothing survives
              // to preserve; seed from the sender's timestamp exactly as the
              // v6 migration seeded existing history.
              _toRow(
                contactKeyHex,
                msg,
                receivedAtUs: ArrivalClock.fromSenderTimestamp(msg.timestamp),
              ),
          ],
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// Insert or update a single message — the preferred write path going
  /// forward; no read-modify-write of a whole conversation.
  Future<void> upsertMessage(String contactKeyHex, Message msg) async {
    if (publicKeyHex.isEmpty) return;
    await _db.into(_db.contactMessageRows).insert(
          _toRow(
            contactKeyHex,
            msg,
            receivedAtUs:
                await _arrivalStampFor(contactKeyHex, msg.messageId),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Insert-or-update a batch WITHOUT touching any other rows — the only
  /// write live message paths may use. Unlike [saveMessages] this can NEVER
  /// shrink a conversation's stored history.
  Future<void> upsertMessages(
    String contactKeyHex,
    List<Message> messages,
  ) async {
    if (publicKeyHex.isEmpty || messages.isEmpty) return;
    // One query for the batch: these rewrite rows we already hold, and each
    // must keep the arrival time it was first given.
    final known = await _arrivalStampsFor(contactKeyHex);
    await _db.batch((b) {
      b.insertAll(
        _db.contactMessageRows,
        [
          for (final msg in messages)
            _toRow(
              contactKeyHex,
              msg,
              receivedAtUs: known[msg.messageId] ?? ArrivalClock.next(),
            ),
        ],
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
              [
                for (final msg in messages)
                  // Imported history was never witnessed arriving; seed from
                  // the sender's timestamp, as the v6 migration does.
                  _toRow(
                    contactKeyHex,
                    msg,
                    receivedAtUs:
                        ArrivalClock.fromSenderTimestamp(msg.timestamp),
                  ),
              ],
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
      'reactionSenders': msg.reactionSenders,
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
      reactionSenders: ReactionHelper.decodeSenders(json['reactionSenders']),
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
