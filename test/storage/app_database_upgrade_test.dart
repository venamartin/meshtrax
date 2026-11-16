import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/storage/app_database.dart';

// Each upgrade must open both a database the previous version left behind
// and one whose first launch stopped after creating the indexes but before
// the version was stamped (a 1.8.0 Windows install that showed no messages).
void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('meshtrax_upgrade_');
    path = '${dir.path}${Platform.pathSeparator}meshtrax.sqlite';
    // A fresh file is created at the current version with every index.
    AppDatabase.useFileForTesting(path);
    await AppDatabase.instance.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    // Windows will not delete a file the database still holds open.
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTesting();
    await dir.delete(recursive: true);
  });

  Future<void> rewindTo(int version, {List<String> dropIndexes = const []}) async {
    final db = AppDatabase.instance;
    for (final index in dropIndexes) {
      await db.customStatement('DROP INDEX $index');
    }
    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
  }

  Future<int> reopenVersion() async {
    AppDatabase.useFileForTesting(path);
    final row = await AppDatabase.instance
        .customSelect('PRAGMA user_version')
        .getSingle();
    return row.data.values.first as int;
  }

  Future<Set<String>> indexNames() async {
    final rows = await AppDatabase.instance
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    return {for (final r in rows) r.read<String>('name')};
  }

  const v8Indexes = ['idx_channel_arrival', 'idx_contact_arrival'];
  const v9Index = 'idx_channel_shown_order';
  const current = 11;

  test('a 1.7.x database gets the arrival and shown-order indexes', () async {
    await rewindTo(7, dropIndexes: [...v8Indexes, v9Index]);
    expect(await reopenVersion(), current);
    expect(await indexNames(), containsAll([...v8Indexes, v9Index]));
  });

  test('a half-finished upgrade (indexes made, still v7) opens', () async {
    await rewindTo(7);
    expect(await reopenVersion(), current);
    expect(await indexNames(), containsAll([...v8Indexes, v9Index]));
  });

  test('a 1.10.1 database gets the shown-order index', () async {
    await rewindTo(8, dropIndexes: [v9Index]);
    expect(await reopenVersion(), current);
    expect(await indexNames(), contains(v9Index));
  });

  test('a half-finished v9 upgrade (index made, still v8) opens', () async {
    await rewindTo(8);
    expect(await reopenVersion(), current);
    expect(await indexNames(), contains(v9Index));
  });

  Future<Set<String>> tableNames() async {
    final rows = await AppDatabase.instance
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    return {for (final r in rows) r.read<String>('name')};
  }

  Future<Set<String>> noteColumns() async {
    final rows = await AppDatabase.instance
        .customSelect("SELECT name FROM pragma_table_info('contact_note_rows')")
        .get();
    return {for (final r in rows) r.read<String>('name')};
  }

  test('a 1.10.2 database gets the contact notes table', () async {
    await AppDatabase.instance.customStatement('DROP TABLE contact_note_rows');
    await rewindTo(9);
    expect(await reopenVersion(), current);
    expect(await tableNames(), contains('contact_note_rows'));
    expect(await noteColumns(), contains('nickname'));
  });

  test('a half-finished v10 upgrade (table made, still v9) opens', () async {
    await rewindTo(9);
    expect(await reopenVersion(), current);
    expect(await tableNames(), contains('contact_note_rows'));
  });

  // Test builds 1.10.2+204 and +205 made the table without a nickname.
  test('a v10 database gets the nickname and keeps its names', () async {
    final db = AppDatabase.instance;
    await db.customStatement('DROP TABLE contact_note_rows');
    await db.customStatement(
      'CREATE TABLE contact_note_rows ('
      "public_key_hex TEXT NOT NULL, real_name TEXT NOT NULL DEFAULT '', "
      "note TEXT NOT NULL DEFAULT '', PRIMARY KEY (public_key_hex))",
    );
    await db.customStatement(
      'INSERT INTO contact_note_rows VALUES (?, ?, ?)',
      ['ab' * 32, 'Ann Smith', 'Lives up the hill'],
    );
    await rewindTo(10);
    expect(await reopenVersion(), current);
    expect(await noteColumns(), contains('nickname'));
    final row = await AppDatabase.instance
        .customSelect('SELECT real_name, note, nickname FROM contact_note_rows')
        .getSingle();
    expect(row.read<String>('real_name'), 'Ann Smith');
    expect(row.read<String>('note'), 'Lives up the hill');
    expect(row.read<String>('nickname'), '');
  });

  test('a half-finished v11 upgrade (column made, still v10) opens', () async {
    await rewindTo(10);
    expect(await reopenVersion(), current);
    expect(await noteColumns(), contains('nickname'));
  });
}
