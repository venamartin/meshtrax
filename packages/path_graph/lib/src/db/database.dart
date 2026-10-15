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
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // An older build reopening the file stamps its own (lower)
          // version back, and early v1 files already had some columns:
          // adding a column that exists throws, so add only what is
          // missing.
          final columns = {
            for (final row in await customSelect(
                    'PRAGMA table_info(contact_ingress)')
                .get())
              row.read<String>('name'),
          };
          Future<void> addIfMissing(GeneratedColumn column) async {
            if (!columns.add(column.name)) return;
            await m.addColumn(contactIngress, column);
          }

          if (from < 2) {
            await addIfMissing(contactIngress.uplinkSnr);
            await addIfMissing(contactIngress.downlinkSnr);
          }
          if (from < 4) {
            await addIfMissing(contactIngress.finalCount);
            await addIfMissing(contactIngress.penultimateCount);
          }
          if (from < 5) {
            await customStatement(
                "UPDATE graph_nodes SET source = 'observed' "
                "WHERE source = 'imported'");
            // Rebuilds copy the columns both shapes share and drop the
            // rest (imported_score/avg_snr from v2, imported_* from v3+,
            // region from graph_nodes).
            await m.alterTable(TableMigration(graphNodes));
            await m.alterTable(TableMigration(graphEdges));
            await addIfMissing(contactIngress.provenAt);
          }
          if (from < 6) {
            await addIfMissing(contactIngress.provenCount);
            // Rows proven before the count existed were proven at least
            // once.
            await customStatement(
                'UPDATE contact_ingress SET proven_count = 1 '
                'WHERE proven_at IS NOT NULL AND proven_count = 0');
          }
          if (from < 7) {
            await addIfMissing(contactIngress.floodProvenAt);
            await addIfMissing(contactIngress.lastHeardAt);
            // Best guess for rows heard before the clock was split.
            await customStatement(
                'UPDATE contact_ingress SET last_heard_at = last_seen '
                'WHERE final_count > 0 AND last_heard_at IS NULL');
          }
        },
      );
}
