import 'package:drift/drift.dart';

part 'points_database.g.dart';

/// A region's "Points of interest" file, opened read-only. The build stamps
/// `PRAGMA user_version` with the schema version, so drift never writes.
@DriftDatabase(include: {'points.drift'})
class PointsDatabase extends _$PointsDatabase {
  PointsDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => throw StateError('Not a points of interest file'),
    onUpgrade: (m, from, to) async =>
        throw StateError('Points of interest schema $from, app reads $to'),
  );
}
