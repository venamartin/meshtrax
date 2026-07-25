import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
  IntColumn get timestampMs => integer()();

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

  @override
  Set<Column> get primaryKey => {nodeScope, idKey};
}

/// Same watermark model for DM conversations (wired in the DM cut) (v3).
class ContactReadMarks extends Table {
  TextColumn get nodeScope => text()();
  TextColumn get contactKey => text()();
  IntColumn get lastReadMs => integer().withDefault(const Constant(0))();

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
  IntColumn get timestampMs => integer()();

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
  int get schemaVersion => 5;

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
    },
  );
}
