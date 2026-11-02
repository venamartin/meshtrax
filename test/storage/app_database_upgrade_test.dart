import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/storage/app_database.dart';

// The v7 -> v8 upgrade must open both a database 1.7.x left behind and one
// whose first 1.8.0 launch stopped after creating the indexes but before
// the version was stamped (a Windows install that showed no messages).
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

  Future<void> rewindToV7({required bool dropIndexes}) async {
    final db = AppDatabase.instance;
    if (dropIndexes) {
      await db.customStatement('DROP INDEX idx_channel_arrival');
      await db.customStatement('DROP INDEX idx_contact_arrival');
    }
    await db.customStatement('PRAGMA user_version = 7');
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

  test('a 1.7.x database gets the arrival indexes', () async {
    await rewindToV7(dropIndexes: true);
    expect(await reopenVersion(), 8);
    expect(
      await indexNames(),
      containsAll(['idx_channel_arrival', 'idx_contact_arrival']),
    );
  });

  test('a half-finished upgrade (indexes made, still v7) opens', () async {
    await rewindToV7(dropIndexes: false);
    expect(await reopenVersion(), 8);
    expect(
      await indexNames(),
      containsAll(['idx_channel_arrival', 'idx_contact_arrival']),
    );
  });
}
