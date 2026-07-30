import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'arrival_clock.dart';

part 'app_database.g.dart';

/// One row per channel message. The keys are real columns so the database
/// enforces what the JSON-blob store never could: a message exists exactly
/// once per (node, channel identity), writes are transactional, and order
/// is a query — not a fragile in-memory list.
@TableIndex(
  name: 'idx_channel_packet_hash',
  columns: {#nodeScope, #channelIdKey, #packetHash},
)
class ChannelMessageRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Scope: the connected node's pubkey prefix (one phone, many radios).
  TextColumn get nodeScope => text()();

  /// Channel identity (Channel.idKey == pskHex) — never a slot index.
  TextColumn get channelIdKey => text()();

  TextColumn get messageId => text()();

  /// When the SENDER says it sent this. Display only, and not trustworthy:
  /// mesh clocks drift, reset on a flat battery, and the firmware refuses to
  /// wind one backwards. Ingest also rewrites this when it looks implausible.
  /// Never order or deduplicate on it.
  IntColumn get timestampMs => integer()();

  /// When THIS app first saw the message, in microseconds. The radio hands
  /// its offline queue over strictly in receive order, so this is a fact we
  /// know even when the sender's clock is nonsense — which makes it the only
  /// sound basis for ordering a conversation (v6).
  ///
  /// Written once, at first insert, and preserved by every later upsert: a
  /// status change must not move a message in the chat.
  IntColumn get receivedAtUs => integer().withDefault(const Constant(0))();

  /// Firmware packet hash when known — repeat/echo dedup is a SQL lookup,
  /// not an in-memory scan (v3).
  TextColumn get packetHash => text().nullable()();

  /// Promoted so ordering/unread queries never parse JSON (v3).
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();

  /// Decided ONCE at ingest: true only for messages that should count
  /// toward unread (not outgoing, not authored by this node) (v3).
  BoolColumn get unreadEligible =>
      boolean().withDefault(const Constant(false))();

  /// Remaining message fields as JSON. Keys live in real columns; promoting
  /// more fields to columns later is an additive migration.
  TextColumn get payload => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nodeScope, channelIdKey, messageId},
  ];
}

/// Last-read watermark per channel identity; unread is a watched COUNT of
/// eligible rows newer than this — never a mutable counter (v3).
class ChannelReadMarks extends Table {
  TextColumn get nodeScope => text()();
  TextColumn get idKey => text()();
  IntColumn get lastReadMs => integer().withDefault(const Constant(0))();

  /// The watermark in the same units the rows are ordered by (v6). Unread is
  /// a comparison, so it has to move to arrival time along with the messages
  /// or every badge goes wrong the moment ordering changes.
  IntColumn get lastReadSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {nodeScope, idKey};
}

/// Same watermark model for DM conversations (wired in the DM cut) (v3).
class ContactReadMarks extends Table {
  TextColumn get nodeScope => text()();
  TextColumn get contactKey => text()();
  IntColumn get lastReadMs => integer().withDefault(const Constant(0))();

  /// Arrival-time watermark, mirroring ChannelReadMarks (v6).
  IntColumn get lastReadSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {nodeScope, contactKey};
}

/// Saved-contact cache, one row per contact (v5). The RADIO is the source
/// of truth for saved contacts; these rows are the offline mirror, so
/// whole-list replacement on sync is the correct write here.
class ContactRows extends Table {
  TextColumn get nodeScope => text()();
  TextColumn get publicKeyHex => text()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {nodeScope, publicKeyHex};
}

/// Discovered-but-not-saved contacts (v5) — app-only state with no radio
/// backstop. Deliberately unscoped (scope='global'), matching the legacy
/// store's semantics: discovery results are shared across radios.
class DiscoveredContactRows extends Table {
  TextColumn get nodeScope => text()();
  TextColumn get publicKeyHex => text()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {nodeScope, publicKeyHex};
}

/// Cached channel slot table (v5) — mirror of the radio's slots for offline
/// display and identity mapping before the first live sync.
class CachedChannelRows extends Table {
  TextColumn get nodeScope => text()();
  IntColumn get slotIndex => integer()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {nodeScope, slotIndex};
}

/// One row per contact (DM) message — same contract as channel rows: a
/// message exists exactly once per (node, contact), writes are transactional.
class ContactMessageRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Scope: the connected node's pubkey prefix (one phone, many radios).
  TextColumn get nodeScope => text()();

  /// The other party's full pubkey hex — contacts' stable identity.
  TextColumn get contactKey => text()();

  TextColumn get messageId => text()();

  /// The sender's claimed send time — display only. See the note on
  /// ChannelMessageRows.timestampMs.
  IntColumn get timestampMs => integer()();

  /// When THIS app first saw the message, in microseconds (v6). DMs drain
  /// from the same receive-ordered offline queue as channel messages, so they
  /// have the same problem and the same fix.
  IntColumn get receivedAtUs => integer().withDefault(const Constant(0))();

  /// Promoted so unread/ordering queries never parse JSON (v4).
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();

  /// Decided ONCE at ingest: counts toward unread only when not outgoing,
  /// not CLI traffic, and the contact tracks unread (v4).
  BoolColumn get unreadEligible =>
      boolean().withDefault(const Constant(false))();

  /// Remaining message fields as JSON; keys live in real columns.
  TextColumn get payload => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nodeScope, contactKey, messageId},
  ];
}

@DriftDatabase(
  tables: [
    ChannelMessageRows,
    ContactMessageRows,
    ChannelReadMarks,
    ContactReadMarks,
    ContactRows,
    DiscoveredContactRows,
    CachedChannelRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.e);

  static AppDatabase? _instance;

  static AppDatabase get instance =>
      _instance ??= AppDatabase._(driftDatabase(name: 'meshtrax'));

  @visibleForTesting
  static void useInMemoryForTesting() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    _instance?.close();
    _instance = AppDatabase._(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(contactMessageRows);
      }
      if (from < 3) {
        await m.addColumn(channelMessageRows, channelMessageRows.packetHash);
        await m.addColumn(channelMessageRows, channelMessageRows.isOutgoing);
        await m.addColumn(
          channelMessageRows,
          channelMessageRows.unreadEligible,
        );
        await m.createTable(channelReadMarks);
        await m.createTable(contactReadMarks);
        await m.createIndex(idxChannelPacketHash);
        // Pre-v3 rows never count as unread: read marks initialize to the
        // newest existing message per channel on first use.
      }
      if (from < 4) {
        await m.addColumn(contactMessageRows, contactMessageRows.isOutgoing);
        await m.addColumn(
          contactMessageRows,
          contactMessageRows.unreadEligible,
        );
      }
      if (from < 5) {
        await m.createTable(contactRows);
        await m.createTable(discoveredContactRows);
        await m.createTable(cachedChannelRows);
      }
      if (from < 6) {
        await m.addColumn(channelMessageRows, channelMessageRows.receivedAtUs);
        await m.addColumn(contactMessageRows, contactMessageRows.receivedAtUs);
        await m.addColumn(channelReadMarks, channelReadMarks.lastReadSeq);
        await m.addColumn(contactReadMarks, contactReadMarks.lastReadSeq);

        // Seed arrival time from the sender's timestamp. Conversations are
        // ordered by timestamp_ms today, so x1000 reproduces exactly the order
        // every existing chat already displays — nobody's history rearranges
        // on upgrade. Only messages arriving from here on get a true arrival
        // time, which is right: they are the only ones we actually witnessed.
        //
        // MAX(..., 1): a stamp of 0 means "unstamped" to the preservation
        // logic, so a legacy row with timestamp_ms = 0 would be handed a
        // fresh stamp by its next status update and teleport to the newest
        // position. Floor it at 1µs — still sorts oldest, never re-stamps.
        await customStatement(
          'UPDATE channel_message_rows '
          'SET received_at_us = MAX(timestamp_ms, 1) * 1000',
        );
        await customStatement(
          'UPDATE contact_message_rows '
          'SET received_at_us = MAX(timestamp_ms, 1) * 1000',
        );
        // Same scaling for the watermarks, so unread counts do not shift.
        await customStatement(
          'UPDATE channel_read_marks SET last_read_seq = last_read_ms * 1000',
        );
        await customStatement(
          'UPDATE contact_read_marks SET last_read_seq = last_read_ms * 1000',
        );
      }
    },
    beforeOpen: (details) async {
      // Seed the arrival clock past everything already stored, every open.
      // Without this, a phone clock that stepped backwards between sessions
      // would stamp new messages below existing rows — mid-conversation, and
      // invisibly read if they land under the watermark.
      final row = await customSelect(
        'SELECT MAX('
        '  COALESCE((SELECT MAX(received_at_us) FROM channel_message_rows), 0),'
        '  COALESCE((SELECT MAX(received_at_us) FROM contact_message_rows), 0)'
        ') AS m',
      ).getSingleOrNull();
      ArrivalClock.seed(row?.read<int?>('m') ?? 0);
    },
  );
}
