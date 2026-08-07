import 'package:drift/drift.dart';

/// One row per 2-byte hash bucket. Hash alone is identity — region is
/// metadata on imported rows, so observed + imported never fragment.
class GraphNodes extends Table {
  /// 4 hex chars, uppercase (2-byte hash).
  TextColumn get hashBytes => text()();
  TextColumn get name => text().nullable()();
  TextColumn get role => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  /// Arrival-time millis (never wire timestamps).
  IntColumn get lastHeard => integer().nullable()();

  /// imported | observed | advert
  TextColumn get source => text()();
  TextColumn get region => text().nullable()();

  /// Full 64-hex pubkey when known (enables re-collapse at other widths).
  TextColumn get pubkey => text().nullable()();

  @override
  Set<Column> get primaryKey => {hashBytes};
}

/// Directed edge — from→to and to→from are separate rows that never
/// copy each other. Local evidence (s/n, trafficWeight, measuredSnr) is
/// never touched by imports; the imported_* prior is replaceable
/// wholesale. Calibrated p combines the layers at read.
@TableIndex(name: 'idx_edges_from', columns: {#fromHash})
class GraphEdges extends Table {
  TextColumn get fromHash => text()();
  TextColumn get toHash => text()();

  /// Attempt-counted local evidence (successes / attempts).
  IntColumn get s => integer().withDefault(const Constant(0))();
  IntColumn get n => integer().withDefault(const Constant(0))();

  /// Passive-sighting EWMA (candidate ranking / tie-breaks, never p).
  RealColumn get trafficWeight => real().withDefault(const Constant(0))();

  /// Arrival-time millis of last observation.
  IntColumn get lastObserved => integer().nullable()();
  IntColumn get obsCount => integer().withDefault(const Constant(0))();
  TextColumn get source => text()();

  // Import layer (meshtrax-graph-v2, replaceable). Another collector's
  // measurements OF THIS DIRECTION — mirrors the local columns above so
  // the two layers stay separable at read.
  RealColumn get importedSnr => real().nullable()();
  IntColumn get importedObservations =>
      integer().withDefault(const Constant(0))();
  IntColumn get importedDelivered => integer().withDefault(const Constant(0))();
  IntColumn get importedAttempts => integer().withDefault(const Constant(0))();
  IntColumn get importedLastObserved => integer().nullable()();

  // Local layer: trace-fed per-hop SNR EWMA.
  RealColumn get measuredSnr => real().nullable()();

  @override
  Set<Column> get primaryKey => {fromHash, toHash};
}

/// Weighted "who hears them" (and, for self rows keyed by radio pubkey,
/// "who hears me") lists. Evidence: proven | inferred | direct.
class ContactIngress extends Table {
  TextColumn get ownerPubkey => text()();
  TextColumn get repeaterHash => text()();
  RealColumn get weight => real()();
  IntColumn get lastSeen => integer()();
  TextColumn get evidence => text()();
  RealColumn get observedLat => real().nullable()();
  RealColumn get observedLon => real().nullable()();

  /// Measured first-hop link, both directions (Discover): uplink = how
  /// well they heard US, downlink = how well we heard THEM.
  RealColumn get uplinkSnr => real().nullable()();
  RealColumn get downlinkSnr => real().nullable()();

  @override
  Set<Column> get primaryKey => {ownerPubkey, repeaterHash};
}

/// Contact mirror fed exclusively by ingestContact (isolation invariant).
class KnownContacts extends Table {
  TextColumn get contactPubkey => text()();
  TextColumn get name => text()();
  RealColumn get lastKnownLat => real().nullable()();
  RealColumn get lastKnownLon => real().nullable()();
  IntColumn get lastRefreshed => integer()();

  @override
  Set<Column> get primaryKey => {contactPubkey};
}

/// Import identity, home position, and counters.
class GraphMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
