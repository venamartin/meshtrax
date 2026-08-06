import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:path_graph/src/db/database.dart';
import 'package:test/test.dart';

/// A v1 database (before uplinkSnr/downlinkSnr existed) must upgrade in
/// place, not crash on the first flush. Bench regression: path_lab.db
/// was created at v1 and INSERTs failed with "no column named
/// uplink_snr" because the schema version was never bumped.
void main() {
  test('v1 database upgrades in place and keeps its rows', () async {
    final dir = Directory.systemTemp.createTempSync('path_graph_mig');
    final file = File('${dir.path}/v1.db');

    // Opening runs onCreate (v2 schema); replace the table with its v1
    // shape and rewind user_version so the next open must migrate.
    final v1 = PathGraphDatabase(NativeDatabase(file));
    await v1.customStatement('DROP TABLE IF EXISTS contact_ingress');
    await v1.customStatement('''
      CREATE TABLE contact_ingress (
        owner_pubkey TEXT NOT NULL,
        repeater_hash TEXT NOT NULL,
        weight REAL NOT NULL,
        last_seen INTEGER NOT NULL,
        evidence TEXT NOT NULL,
        observed_lat REAL,
        observed_lon REAL,
        PRIMARY KEY (owner_pubkey, repeater_hash))''');
    final now = DateTime.now().millisecondsSinceEpoch;
    await v1.customStatement(
        "INSERT INTO contact_ingress VALUES ('me', 'A277', 3.0, $now, "
        "'proven', NULL, NULL)");
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    // Reopening the SAME FILE runs the migration.
    final graph = PathGraph(NativeDatabase(file));
    await graph.init();
    graph.setRadioIdentity('me', 2);

    // The pre-existing row survived the upgrade.
    expect(graph.egressCandidates().single.repeaterHash, 'A277');

    // And the new columns are writable — this is what crashed before.
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 8)],
        failureEpisode: false);
    await graph.flush();
    expect(graph.egressCandidates().single.uplinkSnr, 9);

    await graph.dispose();
    dir.deleteSync(recursive: true);
  });
}
