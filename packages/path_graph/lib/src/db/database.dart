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
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(contactIngress, contactIngress.uplinkSnr);
            await m.addColumn(contactIngress, contactIngress.downlinkSnr);
          }
          if (from < 4) {
            await m.addColumn(contactIngress, contactIngress.finalCount);
            await m.addColumn(
                contactIngress, contactIngress.penultimateCount);
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
            await m.addColumn(contactIngress, contactIngress.provenAt);
          }
        },
      );
}
