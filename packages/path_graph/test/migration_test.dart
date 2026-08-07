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

  test('v2 sheds the Corescope prior and keeps local evidence', () async {
    final dir = Directory.systemTemp.createTempSync('path_graph_mig3');
    final file = File('${dir.path}/v2.db');

    // Rebuild graph_edges in its v2 shape (imported_score / avg_snr —
    // the symmetric Corescope prior) and rewind to user_version 2.
    final v2 = PathGraphDatabase(NativeDatabase(file));
    await v2.customStatement('DROP TABLE IF EXISTS graph_edges');
    await v2.customStatement('''
      CREATE TABLE graph_edges (
        from_hash TEXT NOT NULL,
        to_hash TEXT NOT NULL,
        s INTEGER NOT NULL DEFAULT 0,
        n INTEGER NOT NULL DEFAULT 0,
        traffic_weight REAL NOT NULL DEFAULT 0,
        last_observed INTEGER,
        obs_count INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL,
        imported_score REAL,
        avg_snr REAL,
        measured_snr REAL,
        PRIMARY KEY (from_hash, to_hash))''');
    await v2.customStatement(
        "INSERT INTO graph_edges VALUES ('A277', '1312', 4, 5, 9.0, 1000, "
        "9, 'observed', 0.9, 6.0, -3.5)");
    await v2.customStatement('PRAGMA user_version = 2');
    await v2.close();

    final graph = PathGraph(NativeDatabase(file));
    await graph.init();

    final e = graph.snapshot().edges[('A277', '1312')]!;
    expect(e.s, 4, reason: 'local evidence rides through the rebuild');
    expect(e.n, 5);
    expect(e.trafficWeight, 9.0);
    expect(e.obsCount, 9);
    expect(e.measuredSnr, -3.5);
    expect(e.hasImport, isFalse,
        reason: 'a symmetric score has no honest per-direction successor');

    // The v2 columns are writable and independent of the local ones.
    await graph.importGraph({
      'format': 'meshtrax-graph-v2',
      'directed': true,
      'graph': {'region_hint': 'testland'},
      'nodes': [
        {'id': 'A277'},
        {'id': '1312'}
      ],
      'links': [
        {'source': 'A277', 'target': '1312', 'measured_snr': 7.0,
         'observations': 3}
      ],
    });
    await graph.flush();
    expect(graph.snapshot().edges[('A277', '1312')]!.importedSnr, 7.0);

    await graph.dispose();
    dir.deleteSync(recursive: true);
  });
}
