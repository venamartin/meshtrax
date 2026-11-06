import 'package:drift/drift.dart';

part 'addresses_database.g.dart';

/// A region's "Addresses" file, opened read-only, like the points file.
@DriftDatabase(include: {'addresses.drift'})
class AddressesDatabase extends _$AddressesDatabase {
  AddressesDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => throw StateError('Not an addresses file'),
    onUpgrade: (m, from, to) async =>
        throw StateError('Addresses schema $from, app reads $to'),
  );
}
