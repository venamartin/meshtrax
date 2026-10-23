import 'dart:io';
import 'dart:typed_data';

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
    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
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

  test('hub-signature counters survive a restart', () async {
    final dir = Directory.systemTemp.createTempSync('path_graph_hub');
    final file = File('${dir.path}/hub.db');
    const self = 'ab' 'ab' 'ab';

    final first = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await first.init();
    first.setRadioIdentity(self, 2);
    // A277 is a hub: heard through it three times, at my doorstep once.
    for (var i = 0; i < 3; i++) {
      first.observePath(
          Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous(),
          messageId: 'm$i');
    }
    first.observePath(Uint8List.fromList([0xA2, 0x77]), 2,
        const ObservationOrigin.anonymous());
    final before = first.egressCandidates()
        .firstWhere((c) => c.repeaterHash == 'A277').weight;
    await first.dispose();

    final second = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await second.init();
    second.setRadioIdentity(self, 2);
    final after = second.egressCandidates()
        .firstWhere((c) => c.repeaterHash == 'A277').weight;
    expect(after, closeTo(before, 0.01),
        reason: 'the demotion must not reset to zero across a restart');

    await second.dispose();
    dir.deleteSync(recursive: true);
  });

  test('a v2 database rebuilds to the current shape and keeps its evidence',
      () async {
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
    // v2 contact_ingress: uplink/downlink present, hub counters not yet.
    await v2.customStatement('DROP TABLE IF EXISTS contact_ingress');
    await v2.customStatement('''
      CREATE TABLE contact_ingress (
        owner_pubkey TEXT NOT NULL,
        repeater_hash TEXT NOT NULL,
        weight REAL NOT NULL,
        last_seen INTEGER NOT NULL,
        evidence TEXT NOT NULL,
        observed_lat REAL,
        observed_lon REAL,
        uplink_snr REAL,
        downlink_snr REAL,
        PRIMARY KEY (owner_pubkey, repeater_hash))''');
    await v2.customStatement(
        "INSERT INTO contact_ingress VALUES ('me', 'A277', 3.0, "
        "${DateTime.now().millisecondsSinceEpoch}, 'proven', NULL, NULL, "
        '9.0, 7.0)');
    // A node only an import ever knew becomes an ordinary observed node.
    await v2.customStatement(
        "INSERT INTO graph_nodes (hash_bytes, source) VALUES ('1312', 'imported')");
    await v2.customStatement('PRAGMA user_version = 2');
    await v2.close();

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity('me', 2);

    // v4 adds the hub counters; the pre-existing row keeps its measured
    // SNRs and starts the counters at zero.
    final egress = graph.egressCandidates().single;
    expect(egress.repeaterHash, 'A277');
    expect(egress.uplinkSnr, 9.0);

    final e = graph.snapshot().edges[('A277', '1312')]!;
    expect(e.s, 4, reason: 'local evidence rides through the rebuild');
    expect(e.n, 5);
    expect(e.trafficWeight, 9.0);
    expect(e.obsCount, 9);
    expect(e.measuredSnr, -3.5);
    expect(graph.snapshot().nodes['1312']!.source, NodeSource.observed,
        reason: 'imported nodes are plain observed nodes now');

    // The rebuilt table is writable.
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), true);
    await graph.flush();
    expect(graph.snapshot().edges[('A277', '1312')]!.s, 5);

    await graph.dispose();
    dir.deleteSync(recursive: true);
  });

  test('a v5 database gains proven_count and can write it', () async {
    final dir = Directory.systemTemp.createTempSync('path_graph_mig6');
    final file = File('${dir.path}/v5.db');
    const self = 'ab' 'ab' 'ab';

    // contact_ingress in its v5 shape: everything up to proven_at.
    final v5 = PathGraphDatabase(NativeDatabase(file));
    await v5.customStatement('DROP TABLE IF EXISTS contact_ingress');
    await v5.customStatement('''
      CREATE TABLE contact_ingress (
        owner_pubkey TEXT NOT NULL,
        repeater_hash TEXT NOT NULL,
        weight REAL NOT NULL,
        last_seen INTEGER NOT NULL,
        evidence TEXT NOT NULL,
        observed_lat REAL,
        observed_lon REAL,
        proven_at INTEGER,
        uplink_snr REAL,
        downlink_snr REAL,
        final_count INTEGER NOT NULL DEFAULT 0,
        penultimate_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (owner_pubkey, repeater_hash))''');
    await v5.customStatement(
        "INSERT INTO contact_ingress VALUES ('$self', 'A277', 3.0, "
        "${DateTime.now().millisecondsSinceEpoch}, 'proven', NULL, NULL, "
        '${DateTime.now().millisecondsSinceEpoch}, 9.0, 7.0, 4, 1)');
    await v5.customStatement('PRAGMA user_version = 5');
    await v5.close();

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(self, 2);
    var a277 = graph.egressCandidates().single;
    expect(a277.provenCount, 1,
        reason: 'the row was proven (proven_at set): proven once at least');
    expect(a277.finalCount, 4, reason: 'older columns survive');

    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77]), true);
    await graph.flush();
    await graph.dispose();

    final reopened = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await reopened.init();
    reopened.setRadioIdentity(self, 2);
    a277 = reopened.egressCandidates().single;
    expect(a277.provenCount, 2, reason: 'the new column is written and read');
    await reopened.dispose();
    dir.deleteSync(recursive: true);
  });

  /// Opens a fresh file at the current schema, runs [setup] on it, then
  /// rewinds user_version so the next open migrates from [version].
  Future<File> atVersion(int version,
      [Future<void> Function(PathGraphDatabase db)? setup]) async {
    final dir = Directory.systemTemp.createTempSync('path_graph_rewind');
    final file = File('${dir.path}/g.db');
    final db = PathGraphDatabase(NativeDatabase(file));
    await setup?.call(db);
    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
    return file;
  }

  test('an older build stamping v5 back over a v6 file reopens cleanly',
      () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // proven_count already exists; a v5 row proven before it was counted.
    final file = await atVersion(5, (db) => db.customStatement(
        'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
        "last_seen, evidence, proven_at, proven_count) VALUES ('me', 'A277', "
        "3.0, $now, 'proven', $now, 0)"));

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity('me', 2);

    final a277 = graph.egressCandidates().single;
    expect(a277.provenCount, 1,
        reason: 'a row proven before the count existed was proven once');
    await graph.dispose();
    file.parent.deleteSync(recursive: true);
  });

  test('a v1 file that already has the SNR columns migrates', () async {
    final file = await atVersion(1);

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity('me', 2);
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'A277', uplinkSnr: 9, rxSnr: 8)],
        failureEpisode: false);
    await graph.flush();
    expect(graph.egressCandidates().single.uplinkSnr, 9);
    await graph.dispose();
    file.parent.deleteSync(recursive: true);
  });

  test('v6 to v7: heard rows get their heard clock from last_seen', () async {
    final seen = DateTime.now().millisecondsSinceEpoch - 3600 * 1000;
    final file = await atVersion(6, (db) async {
      await db.customStatement(
          'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
          "last_seen, evidence, final_count) VALUES ('me', 'A277', 1.0, "
          "$seen, 'inferred', 3)");
      await db.customStatement(
          'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
          "last_seen, evidence, proven_at, proven_count) VALUES ('me', "
          "'BEEF', 3.0, $seen, 'proven', $seen, 1)");
    });

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    final rows = {
      for (final r in graph.saveSession()['ingress'] as List)
        (r as Map)['repeater']: r,
    };
    expect(rows['A277']!['last_heard_at'], seen);
    expect(rows['BEEF']!.containsKey('last_heard_at'), isFalse,
        reason: 'only ever proven, never heard');
    expect(rows['BEEF']!.containsKey('flood_proven_at'), isFalse);
    await graph.dispose();
    file.parent.deleteSync(recursive: true);
  });

  test('v7 to v8: failed_since_proof starts at 0 and is writable', () async {
    final seen = DateTime.now().millisecondsSinceEpoch;
    final file = await atVersion(7, (db) async {
      await db.customStatement(
          'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
          "last_seen, evidence, proven_at, proven_count) VALUES ('me', "
          "'A277', 3.0, $seen, 'proven', $seen, 1)");
    });

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity('me', 2);
    expect(graph.egressCandidates().single.failedSinceProof, 0);

    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]), false);
    await graph.flush();
    await graph.dispose();

    final reopened = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await reopened.init();
    reopened.setRadioIdentity('me', 2);
    expect(reopened.egressCandidates().single.failedSinceProof, 1,
        reason: 'the count survives a restart');
    await reopened.dispose();
    file.parent.deleteSync(recursive: true);
  });

  test('v8 to v9: links gain a first-seen time, nodes their moving tags',
      () async {
    final seen = DateTime.now().millisecondsSinceEpoch;
    final file = await atVersion(8, (db) async {
      await db.customStatement('DROP TABLE graph_edges');
      await db.customStatement('DROP TABLE graph_nodes');
      await db.customStatement('''
        CREATE TABLE graph_nodes (
          hash_bytes TEXT NOT NULL, name TEXT, role TEXT, lat REAL, lon REAL,
          last_heard INTEGER, source TEXT NOT NULL, pubkey TEXT,
          PRIMARY KEY (hash_bytes))''');
      await db.customStatement('''
        CREATE TABLE graph_edges (
          from_hash TEXT NOT NULL, to_hash TEXT NOT NULL,
          s INTEGER NOT NULL DEFAULT 0, n INTEGER NOT NULL DEFAULT 0,
          traffic_weight REAL NOT NULL DEFAULT 0, last_observed INTEGER,
          obs_count INTEGER NOT NULL DEFAULT 0, source TEXT NOT NULL,
          measured_snr REAL, PRIMARY KEY (from_hash, to_hash))''');
      // Named: v10 wipes unnamed codes heard only once.
      await db.customStatement(
          'INSERT INTO graph_nodes (hash_bytes, source, name) '
          "VALUES ('C882', 'advert', 'WHITE_WHALE')");
      await db.customStatement(
          'INSERT INTO graph_edges (from_hash, to_hash, traffic_weight, '
          "last_observed, obs_count, source) VALUES ('C882', '9105', 1, "
          "$seen, 1, 'observed')");
    });

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    expect(graph.snapshot().edges[('C882', '9105')]!.firstObserved, isNull,
        reason: 'a link from before v9 reads as old');
    graph.observePath(Uint8List.fromList([0xC8, 0x82, 0x41, 0xB1]), 2,
        const ObservationOrigin.anonymous());
    graph.setMovingOverride('C882', MovingOverride.moves);
    await graph.flush();
    await graph.dispose();

    final reopened = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await reopened.init();
    expect(reopened.snapshot().edges[('C882', '41B1')]!.firstObserved,
        isNotNull);
    expect(reopened.movingStatus('C882')!.reason, MovingReason.manual);
    await reopened.dispose();
    file.parent.deleteSync(recursive: true);
  });

  // 2026-10-23: the first detector tagged hilltops, and a half-set position
  // (Caribou Palace, 37.70, 0) read as a 10,000 km move.
  test('v9 to v10: tags from the old rules and half positions are cleared',
      () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final file = await atVersion(9, (db) async {
      await db.customStatement(
          'INSERT INTO graph_nodes (hash_bytes, source, lat, lon, moved_at, '
          'auto_moving_at, auto_rides_with_me_at) VALUES '
          "('A98E', 'advert', 37.703768, -122.427759, $now, $now, $now), "
          "('219D', 'advert', 0, -121.908836, NULL, NULL, NULL), "
          "('1000', 'advert', 37.10981, -121.8439, NULL, $now, NULL)");
      await db.customStatement(
          'INSERT INTO graph_nodes (hash_bytes, source, moving_override) '
          "VALUES ('BEEF', 'observed', 'staysPut'), "
          "('C882', 'observed', 'moves')");
    });

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    expect(graph.movingRepeaters().keys, ['C882'],
        reason: "only the user's word survives");
    final nodes = graph.snapshot().nodes;
    expect(nodes['A98E']!.movedAt, isNull);
    expect(nodes['A98E']!.autoRidesWithMeAt, isNull);
    expect((nodes['A98E']!.lat, nodes['A98E']!.lon), (37.703768, -122.427759));
    expect((nodes['219D']!.lat, nodes['219D']!.lon), (null, null));
    expect(nodes['1000']!.autoMovingAt, isNull);
    expect(nodes['BEEF']!.movingOverride, MovingOverride.staysPut);
    await graph.dispose();
    file.parent.deleteSync(recursive: true);
  });

  // 2026-10-23: 3,674 of the owner's 5,014 codes were junk from flood paths
  // — heard in one burst, never again, never adverted.
  test('v9 to v10: codes heard in one burst and never again are wiped',
      () async {
    const t0 = 1792600000000, s = 1000, h = 3600 * 1000;
    Future<void> link(PathGraphDatabase db, String from, String to,
        {int? first, required int last, int count = 1, String extra = ''}) =>
        db.customStatement(
            'INSERT INTO graph_edges (from_hash, to_hash, traffic_weight, '
            'last_observed, obs_count, source, first_observed$extra) VALUES '
            "('$from', '$to', $count, $last, $count, 'observed', "
            "${first ?? 'NULL'}${extra.isEmpty ? '' : ', 1'})");
    final file = await atVersion(9, (db) async {
      await db.customStatement(
          'INSERT INTO graph_nodes (hash_bytes, source, name) VALUES '
          "('A277', 'advert', 'INTERLAKEN')");
      await db.customStatement(
          'INSERT INTO graph_nodes (hash_bytes, source) VALUES '
          "('0041', 'observed'), ('B107', 'observed'), ('1312', 'observed'), "
          "('0F3B', 'observed'), ('D6ED', 'observed'), ('9C50', 'observed'), "
          "('BEEF', 'observed'), ('E4CB', 'observed')");
      // A junk run ending at a real repeater, and a doorstep it left.
      await link(db, '0041', 'B107', first: t0, last: t0);
      await link(db, 'B107', 'A277', first: t0 + 5 * s, last: t0 + 5 * s);
      await db.customStatement(
          'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
          "last_seen, evidence, final_count) VALUES ('me', 'B107', 1.0, "
          "$t0, 'inferred', 1)");
      // Junk from before first sightings were kept: one sighting each.
      await link(db, '0F3B', 'D6ED', last: t0 - 9 * h);
      // A real repeater nobody named, heard two hours apart.
      await link(db, 'A277', '1312', first: t0, last: t0);
      await link(db, '1312', 'A277', first: t0 + 2 * h, last: t0 + 2 * h);
      // Heard twice before first sightings were kept: span unknown.
      await link(db, '9C50', 'A277', last: t0, count: 2);
      // Proven to hear me, or measured by a trace: never junk.
      await link(db, 'BEEF', 'A277', first: t0, last: t0);
      await db.customStatement(
          'INSERT INTO contact_ingress (owner_pubkey, repeater_hash, weight, '
          "last_seen, evidence, proven_at, proven_count) VALUES ('me', "
          "'BEEF', 3.0, $t0, 'proven', $t0, 1)");
      await link(db, 'E4CB', 'A277',
          first: t0, last: t0, extra: ', measured_snr');
    });

    final graph = PathGraph(NativeDatabase(file),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    final snap = graph.snapshot();
    expect(snap.nodes.keys,
        unorderedEquals(['A277', '1312', '9C50', 'BEEF', 'E4CB']));
    expect(snap.edges.keys, unorderedEquals([
      ('A277', '1312'),
      ('1312', 'A277'),
      ('9C50', 'A277'),
      ('BEEF', 'A277'),
      ('E4CB', 'A277'),
    ]));
    final rows = [
      for (final r in graph.saveSession()['ingress'] as List)
        (r as Map)['repeater'],
    ];
    expect(rows, ['BEEF'], reason: 'the junk doorstep went with its code');
    await graph.dispose();
    file.parent.deleteSync(recursive: true);
  });
}
