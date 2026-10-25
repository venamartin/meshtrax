import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [GraphNodes, GraphEdges, ContactIngress, KnownContacts, GraphMeta],
)
class PathGraphDatabase extends _$PathGraphDatabase {
  /// The executor is injected — the package knows nothing about
  /// platforms. The app passes drift_flutter's executor for
  /// `path_graph.db`; tests pass `NativeDatabase.memory()`.
  PathGraphDatabase(super.executor);

  /// v2 (2026-08-05): contact_ingress gains uplinkSnr/downlinkSnr —
  /// the Discover-measured first-hop link in both directions.
  /// v3 (2026-08-07): the symmetric Corescope prior columns were
  /// replaced by a per-direction imported prior.
  /// v4 (2026-08-07): contact_ingress gains finalCount/penultimateCount
  /// so the hub-signature demotion survives a restart.
  /// v5 (2026-09-23): the graph learns itself — every imported prior
  /// column and the node region tag are dropped (a rebuild copies the
  /// locally observed columns across; nodes that only an import knew
  /// become plain observed nodes), and contact_ingress gains provenAt:
  /// routes may only start and end at doorsteps proven in the sending
  /// direction.
  /// v6 (2026-10-13): contact_ingress gains provenCount — how many times
  /// the row was proven, for the Pathfinder screen's row detail.
  /// v7 (2026-10-14): contact_ingress gains floodProvenAt (a flood echo
  /// proved it) and lastHeardAt (the heard clock, apart from proofs).
  /// v8 (2026-10-17): contact_ingress gains failedSinceProof — failed
  /// direct sends from a doorstep since its last proof, the route-start
  /// gate's counter.
  /// v9 (2026-10-19): graph_edges gains firstObserved (when a link was
  /// first seen — a moving repeater keeps gaining new ones) and
  /// graph_nodes gains the moving-repeater tags.
  /// v10 (2026-10-23): no new columns. The tags the first detector rules
  /// set are cleared (they caught hilltops), as are advert moves and
  /// stored positions with a 0 in them (a half-set position read as a
  /// 10,000 km move). The user's own moving switch is kept. Junk codes
  /// from flood paths are wiped with their links and doorstep rows: never
  /// adverted, nothing proven or measured, every sighting in one burst
  /// (field: 3,674 of 5,014 codes).
  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // An older build reopening the file stamps its own (lower)
          // version back, and early v1 files already had some columns:
          // adding a column that exists throws, so add only what is
          // missing. Read per call: the v5 rebuild below recreates
          // graph_nodes and graph_edges with every current column.
          Future<void> addIfMissing(
              TableInfo table, GeneratedColumn column) async {
            final columns = {
              for (final row in await customSelect(
                      'PRAGMA table_info(${table.actualTableName})')
                  .get())
                row.read<String>('name'),
            };
            if (columns.contains(column.name)) return;
            await m.addColumn(table, column);
          }

          if (from < 2) {
            await addIfMissing(contactIngress, contactIngress.uplinkSnr);
            await addIfMissing(contactIngress, contactIngress.downlinkSnr);
          }
          if (from < 4) {
            await addIfMissing(contactIngress, contactIngress.finalCount);
            await addIfMissing(contactIngress, contactIngress.penultimateCount);
          }
          if (from < 5) {
            await customStatement(
                "UPDATE graph_nodes SET source = 'observed' "
                "WHERE source = 'imported'");
            // Rebuilds copy the columns both shapes share and drop the
            // rest (imported_score/avg_snr from v2, imported_* from v3+,
            // region from graph_nodes).
            // Columns added after v5 do not exist in the old table yet.
            await m.alterTable(TableMigration(graphNodes, newColumns: [
              graphNodes.movedAt,
              graphNodes.movingOverride,
              graphNodes.autoMovingAt,
              graphNodes.autoRidesWithMeAt,
            ]));
            await m.alterTable(TableMigration(graphEdges,
                newColumns: [graphEdges.firstObserved]));
            await addIfMissing(contactIngress, contactIngress.provenAt);
          }
          if (from < 6) {
            await addIfMissing(contactIngress, contactIngress.provenCount);
            // Rows proven before the count existed were proven at least
            // once.
            await customStatement(
                'UPDATE contact_ingress SET proven_count = 1 '
                'WHERE proven_at IS NOT NULL AND proven_count = 0');
          }
          if (from < 7) {
            await addIfMissing(contactIngress, contactIngress.floodProvenAt);
            await addIfMissing(contactIngress, contactIngress.lastHeardAt);
            // Best guess for rows heard before the clock was split.
            await customStatement(
                'UPDATE contact_ingress SET last_heard_at = last_seen '
                'WHERE final_count > 0 AND last_heard_at IS NULL');
          }
          if (from < 8) {
            await addIfMissing(contactIngress, contactIngress.failedSinceProof);
          }
          if (from < 9) {
            await addIfMissing(graphEdges, graphEdges.firstObserved);
            await addIfMissing(graphNodes, graphNodes.movedAt);
            await addIfMissing(graphNodes, graphNodes.movingOverride);
            await addIfMissing(graphNodes, graphNodes.autoMovingAt);
            await addIfMissing(graphNodes, graphNodes.autoRidesWithMeAt);
          }
          if (from < 10) {
            await customStatement(
                'UPDATE graph_nodes SET moved_at = NULL, auto_moving_at = NULL, '
                'auto_rides_with_me_at = NULL');
            await customStatement(
                'UPDATE graph_nodes SET lat = NULL, lon = NULL '
                'WHERE lat = 0 OR lon = 0');
            // Junk codes: every sighting of every link within the 10
            // minutes of PathGraphConfig.newCodeConfirmMinutes. A link
            // seen twice before first sightings were kept has an unknown
            // span and keeps its codes.
            await customStatement('''
                CREATE TEMP TABLE one_off_codes AS
                SELECT l.hash AS hash FROM (
                  SELECT from_hash AS hash, s, n, measured_snr, obs_count,
                         first_observed, last_observed FROM graph_edges
                  UNION ALL
                  SELECT to_hash, s, n, measured_snr, obs_count,
                         first_observed, last_observed FROM graph_edges
                ) l JOIN graph_nodes g ON g.hash_bytes = l.hash
                WHERE g.name IS NULL AND g.pubkey IS NULL
                  AND g.source = 'observed' AND g.moving_override IS NULL
                  AND l.hash NOT IN (SELECT repeater_hash FROM contact_ingress
                                     WHERE proven_at IS NOT NULL)
                GROUP BY l.hash
                HAVING SUM(l.s > 0 OR l.n > 0 OR l.measured_snr IS NOT NULL
                           OR (l.obs_count > 1 AND l.first_observed IS NULL))
                         = 0
                   AND MAX(l.last_observed)
                       - MIN(COALESCE(l.first_observed, l.last_observed))
                       < 600000''');
            await customStatement(
                'DELETE FROM graph_edges WHERE from_hash IN '
                '(SELECT hash FROM one_off_codes) OR to_hash IN '
                '(SELECT hash FROM one_off_codes)');
            await customStatement('DELETE FROM contact_ingress WHERE '
                'repeater_hash IN (SELECT hash FROM one_off_codes)');
            await customStatement('DELETE FROM graph_nodes WHERE hash_bytes '
                'IN (SELECT hash FROM one_off_codes)');
            await customStatement('DROP TABLE one_off_codes');
          }
          if (from < 11) {
            // The radio's exact position used to be written onto my
            // doorstep rows. No precise location is stored any more
            // (owner, 2026-10-25); the rebuild drops the two columns.
            await m.alterTable(TableMigration(contactIngress));
          }
        },
      );
}
