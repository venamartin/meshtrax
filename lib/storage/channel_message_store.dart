import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:meshtrax/utils/app_logger.dart';

import '../models/channel_message.dart';

import '../helpers/smaz.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import 'app_database.dart';
import 'arrival_clock.dart';
import 'prefs_manager.dart';

/// Channel message persistence: one database row per message, keyed by
/// (node scope, channel identity, messageId) with a UNIQUE constraint — the
/// store, not the caller, enforces that a message exists exactly once.
/// Legacy SharedPreferences JSON blobs are imported on first touch.
class ChannelMessageStore {
  static const String _keyPrefix = 'channel_messages_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  AppDatabase get _db => AppDatabase.instance;

  String? _senderHex(ChannelMessage msg) {
    final key = msg.senderKey;
    if (key == null || key.isEmpty) return null;
    return key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// True when the message was authored by this node (sender pubkey starts
  /// with our scope prefix). Own messages never count toward unread.
  bool _isFromSelf(ChannelMessage msg) {
    final sender = _senderHex(msg);
    if (sender == null || publicKeyHex.isEmpty) return false;
    return sender.startsWith(publicKeyHex);
  }

  ChannelMessageRowsCompanion _toRow(
    String idKey,
    ChannelMessage msg, {
    bool? unreadEligible,
    required int receivedAtUs,
  }) {
    return ChannelMessageRowsCompanion.insert(
      nodeScope: publicKeyHex,
      channelIdKey: idKey,
      messageId: msg.messageId,
      timestampMs: msg.timestamp.millisecondsSinceEpoch,
      receivedAtUs: Value(receivedAtUs),
      packetHash: Value(msg.packetHash),
      isOutgoing: Value(msg.isOutgoing),
      unreadEligible: Value(
        unreadEligible ?? (!msg.isOutgoing && !_isFromSelf(msg)),
      ),
      payload: jsonEncode(_messageToJson(msg)),
    );
  }

  /// The arrival stamp a write should carry: whatever the row already has, or
  /// a fresh one if this is the first time we have seen the message.
  ///
  /// Preserving it is the whole point. `upsertMessage` writes with
  /// InsertMode.insertOrReplace, which SQLite implements as delete-then-insert
  /// — so anything derived from the row id would change on every status
  /// update, and a message would jump to the bottom of the chat each time it
  /// went pending -> sent -> delivered.
  Future<int> _arrivalStampFor(String idKey, String messageId) async {
    if (publicKeyHex.isEmpty) return ArrivalClock.next();
    final existing =
        await (_db.selectOnly(_db.channelMessageRows)
              ..addColumns([_db.channelMessageRows.receivedAtUs])
              ..where(
                _db.channelMessageRows.nodeScope.equals(publicKeyHex) &
                    _db.channelMessageRows.channelIdKey.equals(idKey) &
                    _db.channelMessageRows.messageId.equals(messageId),
              )
              ..limit(1))
            .map((r) => r.read(_db.channelMessageRows.receivedAtUs))
            .getSingleOrNull();
    if (existing != null && existing > 0) return existing;
    return ArrivalClock.next();
  }

  // --- Phase 3d: the database is the only message state ------------------

  /// Watched, ordered view of a channel's newest [limit] messages, emitted
  /// oldest-first for display. The UI's ONLY read path; re-emits on every
  /// row change (Drift's Room-style notification hook).
  Stream<List<ChannelMessage>> watchChannelMessages(
    String idKey, {
    int limit = 200,
  }) {
    if (publicKeyHex.isEmpty) return Stream.value(const []);
    unawaited(_importLegacyIdentityBlob(idKey));
    final query = (_db.select(_db.channelMessageRows)
      ..where(
        (r) =>
            r.nodeScope.equals(publicKeyHex) & r.channelIdKey.equals(idKey),
      )
      ..orderBy([
        (r) => OrderingTerm.desc(r.timestampMs),
        (r) => OrderingTerm.desc(r.id),
      ])
      ..limit(limit));
    return query.watch().map((rows) {
      final messages = <ChannelMessage>[];
      for (final row in rows.reversed) {
        try {
          messages.add(
            _messageFromJson(jsonDecode(row.payload) as Map<String, dynamic>),
          );
        } catch (e) {
          appLogger.warn('Skipping unreadable channel message row: $e');
        }
      }
      return messages;
    });
  }

  /// Atomic ingest: inserts and returns true ONLY if no row with this
  /// (scope, idKey, messageId) exists. The unique constraint is the dedup
  /// authority — replaces every in-memory "have I seen this?" scan.
  Future<bool> insertIfNew(
    String idKey,
    ChannelMessage msg, {
    bool? unreadEligible,
  }) async {
    if (publicKeyHex.isEmpty) return false;
    // insertOrIgnore: a losing insert changes nothing, so a fresh stamp here
    // can never overwrite the arrival time of a message we already hold.
    final inserted = await _db
        .into(_db.channelMessageRows)
        .insertReturningOrNull(
          _toRow(
            idKey,
            msg,
            unreadEligible: unreadEligible,
            receivedAtUs: ArrivalClock.next(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return inserted != null;
  }

  /// Lookup by messageId — status updates and same-id echo merges.
  Future<ChannelMessage?> findByMessageId(
    String idKey,
    String messageId,
  ) async {
    if (publicKeyHex.isEmpty) return null;
    final row =
        await (_db.select(_db.channelMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.channelIdKey.equals(idKey) &
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

  /// Scope-wide variant for callers that only hold a messageId (send-ack
  /// bookkeeping): returns (updated, idKey).
  Future<(bool, String?)> updateAnyByMessageId(
    String messageId,
    ChannelMessage Function(ChannelMessage) transform,
  ) async {
    if (publicKeyHex.isEmpty) return (false, null);
    final row =
        await (_db.select(_db.channelMessageRows)
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
      await upsertMessage(row.channelIdKey, transform(msg));
      return (true, row.channelIdKey);
    } catch (_) {
      return (false, null);
    }
  }

  /// Load-transform-upsert of a single row; returns false when the row
  /// does not exist. The only mutation primitive live paths may use.
  Future<bool> updateMessage(
    String idKey,
    String messageId,
    ChannelMessage Function(ChannelMessage) transform,
  ) async {
    final existing = await findByMessageId(idKey, messageId);
    if (existing == null) return false;
    await upsertMessage(idKey, transform(existing));
    return true;
  }

  /// Watched newest message per channel identity — one query feeds the
  /// chats screen's subtitles and ordering (SQL decides "latest").
  Stream<Map<String, ChannelMessage>> watchLatestPerChannel() {
    if (publicKeyHex.isEmpty) return Stream.value(const {});
    return _db
        .customSelect(
          'SELECT m.channel_id_key AS k, m.payload AS p '
          'FROM channel_message_rows m '
          'INNER JOIN (SELECT channel_id_key, MAX(timestamp_ms) AS mx, '
          'MAX(id) AS mi FROM channel_message_rows WHERE node_scope = ?1 '
          'GROUP BY channel_id_key) latest '
          'ON m.channel_id_key = latest.channel_id_key '
          'AND m.timestamp_ms = latest.mx '
          'WHERE m.node_scope = ?1 GROUP BY m.channel_id_key',
          variables: [Variable.withString(publicKeyHex)],
          readsFrom: {_db.channelMessageRows},
        )
        .watch()
        .map((rows) {
          final latest = <String, ChannelMessage>{};
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

  /// Repeat/echo lookup by firmware packet hash (indexed).
  Future<ChannelMessage?> findByPacketHash(
    String idKey,
    String packetHash,
  ) async {
    if (publicKeyHex.isEmpty) return null;
    final row =
        await (_db.select(_db.channelMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.channelIdKey.equals(idKey) &
                    r.packetHash.equals(packetHash),
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

  // --- Read marks: unread is a watched COUNT, never a mutable counter ----

  /// Sets the last-read watermark (defaults to now).
  Future<void> markRead(String idKey, {int? upToMs}) async {
    if (publicKeyHex.isEmpty) return;
    await _db
        .into(_db.channelReadMarks)
        .insertOnConflictUpdate(
          ChannelReadMarksCompanion.insert(
            nodeScope: publicKeyHex,
            idKey: idKey,
            lastReadMs: Value(
              upToMs ?? DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
  }

  /// First-use initialization: pre-existing history never floods unread.
  Future<void> initializeReadMarkIfAbsent(String idKey) async {
    if (publicKeyHex.isEmpty) return;
    final newest =
        await (_db.select(_db.channelMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.channelIdKey.equals(idKey),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.timestampMs)])
              ..limit(1))
            .getSingleOrNull();
    await _db
        .into(_db.channelReadMarks)
        .insert(
          ChannelReadMarksCompanion.insert(
            nodeScope: publicKeyHex,
            idKey: idKey,
            lastReadMs: Value(newest?.timestampMs ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Watched unread count for one channel identity.
  Stream<int> watchUnreadCount(String idKey) {
    if (publicKeyHex.isEmpty) return Stream.value(0);
    return _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM channel_message_rows m '
          'WHERE m.node_scope = ?1 AND m.channel_id_key = ?2 '
          'AND m.unread_eligible = 1 '
          'AND m.timestamp_ms > COALESCE((SELECT last_read_ms '
          'FROM channel_read_marks WHERE node_scope = ?1 AND id_key = ?2), 0)',
          variables: [
            Variable.withString(publicKeyHex),
            Variable.withString(idKey),
          ],
          readsFrom: {_db.channelMessageRows, _db.channelReadMarks},
        )
        .watchSingle()
        .map((row) => row.read<int>('c'));
  }

  /// Watched unread counts for every channel identity under this node —
  /// one query feeds the whole chats screen.
  Stream<Map<String, int>> watchUnreadCounts() {
    if (publicKeyHex.isEmpty) return Stream.value(const {});
    return _db
        .customSelect(
          'SELECT m.channel_id_key AS k, COUNT(*) AS c '
          'FROM channel_message_rows m '
          'WHERE m.node_scope = ?1 AND m.unread_eligible = 1 '
          'AND m.timestamp_ms > COALESCE((SELECT last_read_ms '
          'FROM channel_read_marks '
          'WHERE node_scope = ?1 AND id_key = m.channel_id_key), 0) '
          'GROUP BY m.channel_id_key',
          variables: [Variable.withString(publicKeyHex)],
          readsFrom: {_db.channelMessageRows, _db.channelReadMarks},
        )
        .watch()
        .map((rows) => {
              for (final row in rows)
                row.read<String>('k'): row.read<int>('c'),
            });
  }

  /// Replace a channel's stored messages atomically.
  Future<void> saveChannelMessages(
    String idKey,
    List<ChannelMessage> messages,
  ) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel messages.',
      );
      return;
    }
    await _db.transaction(() async {
      await (_db.delete(_db.channelMessageRows)..where(
            (r) =>
                r.nodeScope.equals(publicKeyHex) & r.channelIdKey.equals(idKey),
          ))
          .go();
      await _db.batch((b) {
        b.insertAll(
          _db.channelMessageRows,
          [
            for (final msg in messages)
              // This path deletes the channel first, so nothing survives to
              // preserve. Seed from the sender's timestamp, matching how the
              // v6 migration seeded existing history.
              _toRow(
                idKey,
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
  Future<void> upsertMessage(String idKey, ChannelMessage msg) async {
    if (publicKeyHex.isEmpty) return;
    await _db.into(_db.channelMessageRows).insert(
          _toRow(
            idKey,
            msg,
            receivedAtUs: await _arrivalStampFor(idKey, msg.messageId),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Insert-or-update a batch WITHOUT touching any other rows — the only
  /// write live message paths may use. Unlike [saveChannelMessages] this can
  /// NEVER shrink a channel's stored history: persisting a windowed or
  /// stale in-memory list only refreshes the rows it actually contains.
  Future<void> upsertMessages(
    String idKey,
    List<ChannelMessage> messages,
  ) async {
    if (publicKeyHex.isEmpty || messages.isEmpty) return;
    // One query for the whole batch rather than one per message: these are
    // rewrites of rows we already hold (reaction updates, repeat merges), and
    // every one of them must keep the arrival time it was first given.
    final known = await _arrivalStampsFor(idKey);
    await _db.batch((b) {
      b.insertAll(
        _db.channelMessageRows,
        [
          for (final msg in messages)
            _toRow(
              idKey,
              msg,
              receivedAtUs: known[msg.messageId] ?? ArrivalClock.next(),
            ),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Arrival stamps already on record for a channel, by messageId.
  Future<Map<String, int>> _arrivalStampsFor(String idKey) async {
    if (publicKeyHex.isEmpty) return const {};
    final rows =
        await (_db.selectOnly(_db.channelMessageRows)
              ..addColumns([
                _db.channelMessageRows.messageId,
                _db.channelMessageRows.receivedAtUs,
              ])
              ..where(
                _db.channelMessageRows.nodeScope.equals(publicKeyHex) &
                    _db.channelMessageRows.channelIdKey.equals(idKey),
              ))
            .get();
    return {
      for (final r in rows)
        if ((r.read(_db.channelMessageRows.receivedAtUs) ?? 0) > 0)
          r.read(_db.channelMessageRows.messageId)!:
              r.read(_db.channelMessageRows.receivedAtUs)!,
    };
  }

  /// Remove exactly one message — explicit user deletion only.
  Future<void> deleteMessage(String idKey, String messageId) async {
    if (publicKeyHex.isEmpty) return;
    await (_db.delete(_db.channelMessageRows)..where(
          (r) =>
              r.nodeScope.equals(publicKeyHex) &
              r.channelIdKey.equals(idKey) &
              r.messageId.equals(messageId),
        ))
        .go();
  }

  Future<List<ChannelMessage>> loadChannelMessages(String idKey) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel messages.',
      );
      return [];
    }
    await _importLegacyIdentityBlob(idKey);
    final rows =
        await (_db.select(_db.channelMessageRows)
              ..where(
                (r) =>
                    r.nodeScope.equals(publicKeyHex) &
                    r.channelIdKey.equals(idKey),
              )
              ..orderBy([
                (r) => OrderingTerm.asc(r.timestampMs),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final messages = <ChannelMessage>[];
    for (final row in rows) {
      try {
        messages.add(
          _messageFromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        );
      } catch (e) {
        appLogger.warn('Skipping unreadable channel message row: $e');
      }
    }
    return messages;
  }

  /// One-time import of the identity-keyed JSON blob written by the
  /// previous store generation.
  Future<void> _importLegacyIdentityBlob(String idKey) async {
    final prefs = PrefsManager.instance;
    final key = '${keyFor}id_$idKey';
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await _importJsonList(idKey, jsonString, source: key);
    await prefs.remove(key);
  }

  /// One-time import of a pre-identity slot-index blob into the identity's
  /// rows. Existing rows win (insertOrIgnore) — legacy indexes can't be
  /// trusted after slot reshuffles.
  Future<void> migrateLegacyIndexKey(int channelIndex, String idKey) async {
    if (publicKeyHex.isEmpty) return;
    final prefs = PrefsManager.instance;
    for (final oldKey in ['$keyFor$channelIndex', '$_keyPrefix$channelIndex']) {
      final legacy = prefs.getString(oldKey);
      if (legacy != null && legacy.isNotEmpty) {
        appLogger.info(
          'Migrating channel messages from legacy key $oldKey into database',
        );
        await _importJsonList(idKey, legacy, source: oldKey);
      }
      await prefs.remove(oldKey);
    }
  }

  Future<void> _importJsonList(
    String idKey,
    String jsonString, {
    required String source,
  }) async {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final messages = [
        for (final json in jsonList)
          _messageFromJson(json as Map<String, dynamic>),
      ];
      await _db.batch((b) {
        b.insertAll(
          _db.channelMessageRows,
          [
            for (final msg in messages)
              // Imported history was never witnessed arriving, so seed from
              // the sender's timestamp — same rule as the v6 migration.
              _toRow(
                idKey,
                msg,
                receivedAtUs: ArrivalClock.fromSenderTimestamp(msg.timestamp),
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        );
      });
      appLogger.info('Imported ${messages.length} messages from $source');
    } catch (e) {
      appLogger.warn('Failed to import legacy messages from $source: $e');
    }
  }

  /// Clear messages for a channel identity.
  Future<void> clearChannelMessages(String idKey) async {
    final prefs = PrefsManager.instance;
    await prefs.remove('${keyFor}id_$idKey');
    await (_db.delete(_db.channelMessageRows)..where(
          (r) =>
              r.nodeScope.equals(publicKeyHex) & r.channelIdKey.equals(idKey),
        ))
        .go();
  }

  /// Clear all channel messages for the current node.
  Future<void> clearAllChannelMessages() async {
    final prefs = PrefsManager.instance;
    final keys = prefs.getKeys().where((k) => k.startsWith(keyFor));
    for (var key in keys) {
      await prefs.remove(key);
    }
    if (publicKeyHex.isEmpty) return;
    await (_db.delete(
      _db.channelMessageRows,
    )..where((r) => r.nodeScope.equals(publicKeyHex))).go();
  }

  /// Convert ChannelMessage to JSON map
  Map<String, dynamic> _messageToJson(ChannelMessage msg) {
    return {
      'senderKey': msg.senderKey != null ? base64Encode(msg.senderKey!) : null,
      'senderName': msg.senderName,
      'text': msg.text,

      'timestamp': msg.timestamp.millisecondsSinceEpoch,
      'isOutgoing': msg.isOutgoing,
      'status': msg.status.index,
      'channelIndex': msg.channelIndex,
      'repeatCount': msg.repeatCount,
      'sendRetryCount': msg.sendRetryCount,
      'pathLength': msg.pathLength,
      'pathBytes': base64Encode(msg.pathBytes),
      'pathHashSize': msg.pathHashSize,
      'pathVariants': msg.pathVariants.map(base64Encode).toList(),
      'repeats': msg.repeats.map(_repeatToJson).toList(),
      'messageId': msg.messageId,
      'packetHash': msg.packetHash,
      'replyToMessageId': msg.replyToMessageId,
      'replyToSenderName': msg.replyToSenderName,
      'replyToText': msg.replyToText,
      'reactions': msg.reactions,
      'reactionSenders': msg.reactionSenders,
    };
  }

  /// Convert JSON map to ChannelMessage
  ChannelMessage _messageFromJson(Map<String, dynamic> json) {
    final rawText = json['text'] as String;
    final decodedText = Smaz.tryDecodePrefixed(rawText) ?? rawText;
    final pathBytes = json['pathBytes'] != null
        ? Uint8List.fromList(base64Decode(json['pathBytes'] as String))
        : Uint8List(0);
    final pathHashSize = (json['pathHashSize'] as int?) ?? 1;

    return ChannelMessage(
      senderKey: json['senderKey'] != null
          ? Uint8List.fromList(base64Decode(json['senderKey'] as String))
          : null,
      senderName: json['senderName'] as String,
      text: decodedText,

      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isOutgoing: json['isOutgoing'] as bool,
      status: ChannelMessageStatus.values[json['status'] as int],
      repeatCount: (json['repeatCount'] as int?) ?? 0,
      sendRetryCount: (json['sendRetryCount'] as int?) ?? 0,
      pathLength: () {
        if (pathBytes.isNotEmpty) {
          return PathHelper.getHopCount(pathBytes, stride: pathHashSize);
        }
        int? pLen = json['pathLength'] as int?;
        if (pLen != null && pLen > 0) {
          pLen = (pLen == 0xFF) ? -1 : (pLen & 0x3F);
        }
        return pLen;
      }(),
      pathBytes: pathBytes,
      pathHashSize: pathHashSize,
      pathVariants: (json['pathVariants'] as List<dynamic>?)
          ?.map((entry) => Uint8List.fromList(base64Decode(entry as String)))
          .toList(),
      repeats:
          (json['repeats'] as List<dynamic>?)
              ?.map((entry) => _repeatFromJson(entry as Map<String, dynamic>))
              .toList() ??
          const [],
      channelIndex: json['channelIndex'] as int?,
      messageId: json['messageId'] as String?,
      packetHash: json['packetHash'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToText: json['replyToText'] as String?,
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      reactionSenders: ReactionHelper.decodeSenders(json['reactionSenders']),
    );
  }

  Map<String, dynamic> _repeatToJson(Repeat repeat) {
    return {
      'repeaterKey': repeat.repeaterKey != null
          ? base64Encode(repeat.repeaterKey!)
          : null,
      'repeaterName': repeat.repeaterName,
      'tripTimeMs': repeat.tripTimeMs,
      'path': repeat.path?.map((bytes) => base64Encode(bytes)).toList() ?? [],
    };
  }

  Repeat _repeatFromJson(Map<String, dynamic> json) {
    return Repeat(
      repeaterKey: json['repeaterKey'] != null
          ? Uint8List.fromList(base64Decode(json['repeaterKey']))
          : null,
      repeaterName: json['repeaterName'] as String? ?? 'Unknown',
      tripTimeMs: json['tripTimeMs'] as int? ?? 0,
      path: (json['path'] as List<dynamic>?)
          ?.map((entry) => Uint8List.fromList(base64Decode(entry as String)))
          .toList(),
    );
  }
}
