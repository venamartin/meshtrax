import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

/// One row per channel message. The keys are real columns so the database
/// enforces what the JSON-blob store never could: a message exists exactly
/// once per (node, channel identity), writes are transactional, and order
/// is a query — not a fragile in-memory list.
class ChannelMessageRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Scope: the connected node's pubkey prefix (one phone, many radios).
  TextColumn get nodeScope => text()();

  /// Channel identity (Channel.idKey == pskHex) — never a slot index.
  TextColumn get channelIdKey => text()();

  TextColumn get messageId => text()();
  IntColumn get timestampMs => integer()();

  /// Remaining message fields as JSON. Keys live in real columns; promoting
  /// more fields to columns later is an additive migration.
  TextColumn get payload => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nodeScope, channelIdKey, messageId},
  ];
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

  /// Remaining message fields as JSON; keys live in real columns.
  TextColumn get payload => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nodeScope, contactKey, messageId},
  ];
}

@DriftDatabase(tables: [ChannelMessageRows, ContactMessageRows])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(contactMessageRows);
      }
    },
  );
}
