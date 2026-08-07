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
  /// v3 (2026-08-07): the Corescope prior (importedScore/avgSnr — one
  /// symmetric number seeded into both directions) is replaced by the
  /// per-direction meshtrax-graph-v2 prior. The old columns are dropped
  /// rather than migrated: a symmetric estimate has no honest
  /// per-direction value to become.
  /// v4 (2026-08-07): contact_ingress gains finalCount/penultimateCount.
  /// They were in-memory only, so every restart reset the hub-signature
  /// demotion to zero and inferred egress candidates briefly looked
  /// better than they are.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(contactIngress, contactIngress.uplinkSnr);
            await m.addColumn(contactIngress, contactIngress.downlinkSnr);
          }
          if (from < 3) {
            // Rebuild from the new schema: copies the local-evidence
            // columns across, drops imported_score/avg_snr, defaults the
            // imported_* columns.
            await m.alterTable(TableMigration(
              graphEdges,
              newColumns: [
                graphEdges.importedSnr,
                graphEdges.importedObservations,
                graphEdges.importedDelivered,
                graphEdges.importedAttempts,
                graphEdges.importedLastObserved,
              ],
            ));
          }
          if (from < 4) {
            await m.addColumn(contactIngress, contactIngress.finalCount);
            await m.addColumn(
                contactIngress, contactIngress.penultimateCount);
          }
        },
      );
}
