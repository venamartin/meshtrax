import 'package:drift/drift.dart';

/// One row per hash bucket. Hash alone is identity.
class GraphNodes extends Table {
  /// Uppercase hex at the graph's identity width.
  TextColumn get hashBytes => text()();
  TextColumn get name => text().nullable()();
  TextColumn get role => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  /// Arrival-time millis (never wire timestamps).
  IntColumn get lastHeard => integer().nullable()();

  /// observed | advert
  TextColumn get source => text()();

  /// Full 64-hex pubkey when known (enables re-collapse at other widths).
  TextColumn get pubkey => text().nullable()();

  @override
  Set<Column> get primaryKey => {hashBytes};
}

/// Directed edge — from→to and to→from are separate rows that never
/// copy each other. Everything here was observed by this radio.
@TableIndex(name: 'idx_edges_from', columns: {#fromHash})
class GraphEdges extends Table {
  TextColumn get fromHash => text()();
  TextColumn get toHash => text()();

  /// Attempt-counted evidence (successes / attempts).
  IntColumn get s => integer().withDefault(const Constant(0))();
  IntColumn get n => integer().withDefault(const Constant(0))();

  /// Passive-sighting EWMA (candidate ranking / tie-breaks, never p).
  RealColumn get trafficWeight => real().withDefault(const Constant(0))();

  /// Arrival-time millis of last observation.
  IntColumn get lastObserved => integer().nullable()();
  IntColumn get obsCount => integer().withDefault(const Constant(0))();
  TextColumn get source => text()();

  /// Trace-fed per-hop SNR EWMA.
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

  /// Arrival millis of the last proof in the SENDING direction (a
  /// delivered send, a trace, a Discover answer). Null = only ever
  /// heard, never proven to reach. Routes end only at proven rows.
  IntColumn get provenAt => integer().nullable()();

  /// Measured first-hop link, both directions (Discover): uplink = how
  /// well they heard US, downlink = how well we heard THEM.
  RealColumn get uplinkSnr => real().nullable()();
  RealColumn get downlinkSnr => real().nullable()();

  /// Self rows only: hub signature. A repeater that shows up second-to-
  /// last far more often than last is a hub I hear *through*, not a
  /// doorstep I can reach — the ratio demotes it.
  IntColumn get finalCount => integer().withDefault(const Constant(0))();
  IntColumn get penultimateCount =>
      integer().withDefault(const Constant(0))();

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

/// Identity width stamp and counters.
class GraphMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
