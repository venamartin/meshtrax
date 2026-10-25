import 'package:drift/drift.dart';

import 'db/database.dart';

/// One repeater that heard this radio in one area: how loud (when a
/// Discover answer or a trace measured it), how often, and the last day.
class PlaceRow {
  PlaceRow({this.uplinkSnr, this.seenCount = 0, required this.lastSeenDay,
      this.failedHere = false});

  double? uplinkSnr;
  int seenCount;
  int lastSeenDay;

  /// A direct send from this repeater got no ACK here since it last
  /// proved it hears me here: the row no longer makes it eligible.
  bool failedHere;
}

/// Which repeaters heard this radio in each area it has been, keyed by an
/// opaque cell key about 500 m across that the app computes from the
/// radio's own GPS. Never a coordinate (owner, 2026-10-25), and the day
/// is as fine as time gets. A row makes a doorstep *eligible* to start a
/// route from here; it is never a proof (the no-firmware-rung rule:
/// nothing taken from storage is evidence).
class PlaceStore {
  PlaceStore(this._db);

  final PathGraphDatabase _db;

  /// (self pubkey, cell, repeater hash) → row.
  final Map<(String, String, String), PlaceRow> rows = {};
  final Set<(String, String, String)> _dirty = {};
  final Set<(String, String, String)> _deleted = {};

  static const seenCap = 20;

  /// A repeater heard me here today. A level replaces nothing: it blends
  /// in, and a proof without one leaves the stored level alone.
  void note(String self, String cell, String repeater, int day,
      {double? uplinkSnr}) {
    final key = (self, cell, repeater);
    final row = rows[key] ??= PlaceRow(lastSeenDay: day);
    row
      ..seenCount = (row.seenCount + 1).clamp(0, seenCap)
      ..lastSeenDay = day
      ..failedHere = false;
    if (uplinkSnr != null) {
      row.uplinkSnr = row.uplinkSnr == null
          ? uplinkSnr
          : row.uplinkSnr! * 0.6 + uplinkSnr * 0.4;
    }
    _dirty.add(key);
    _deleted.remove(key);
  }

  void markFailed(String self, String cell, String repeater) {
    final key = (self, cell, repeater);
    final row = rows[key];
    if (row == null || row.failedHere) return;
    row.failedHere = true;
    _dirty.add(key);
  }

  /// The row for [repeater] in any of [cells], newest first and a
  /// measured one ahead of an unmeasured one of the same day.
  PlaceRow? rowIn(String self, Set<String> cells, String repeater) {
    PlaceRow? best;
    for (final cell in cells) {
      final row = rows[(self, cell, repeater)];
      if (row == null) continue;
      if (best == null ||
          row.lastSeenDay > best.lastSeenDay ||
          (row.lastSeenDay == best.lastSeenDay &&
              row.uplinkSnr != null &&
              best.uplinkSnr == null)) {
        best = row;
      }
    }
    return best;
  }

  /// Whether any row in [cells] belongs to [self].
  bool anyIn(String self, Set<String> cells) =>
      rows.keys.any((k) => k.$1 == self && cells.contains(k.$2));

  /// Drops rows last seen more than [fadeDays] before [today].
  int sweep(int today, int fadeDays) {
    var removed = 0;
    for (final key in rows.keys.toList()) {
      if (today - rows[key]!.lastSeenDay <= fadeDays) continue;
      _remove(key);
      removed++;
    }
    return removed;
  }

  void clear() {
    for (final key in rows.keys.toList()) {
      _remove(key);
    }
  }

  void _remove((String, String, String) key) {
    rows.remove(key);
    _dirty.remove(key);
    _deleted.add(key);
  }

  List<Map<String, dynamic>> toJson() => [
        for (final e in rows.entries)
          {
            'self': e.key.$1,
            'cell': e.key.$2,
            'repeater': e.key.$3,
            if (e.value.uplinkSnr != null) 'uplink_snr': e.value.uplinkSnr,
            'seen': e.value.seenCount,
            'last_seen_day': e.value.lastSeenDay,
            if (e.value.failedHere) 'failed_here': true,
          }
      ];

  /// Replaces every row with [raw] (a [toJson] list, or null for none).
  void replaceAll(Object? raw) {
    clear();
    if (raw is! List) return;
    for (final item in raw) {
      final m = item as Map;
      final key = (m['self'] as String, m['cell'] as String, m['repeater'] as String);
      rows[key] = PlaceRow(
        uplinkSnr: (m['uplink_snr'] as num?)?.toDouble(),
        seenCount: (m['seen'] as num?)?.toInt() ?? 0,
        lastSeenDay: (m['last_seen_day'] as num).toInt(),
        failedHere: m['failed_here'] == true,
      );
      _dirty.add(key);
      _deleted.remove(key);
    }
  }

  Future<void> load() async {
    for (final row in await _db.select(_db.placeDoorsteps).get()) {
      rows[(row.selfPubkey, row.cell, row.repeaterHash)] = PlaceRow(
        uplinkSnr: row.uplinkSnr,
        seenCount: row.seenCount,
        lastSeenDay: row.lastSeenDay,
        failedHere: row.failedHere,
      );
    }
  }

  Future<void> flush() async {
    if (_dirty.isEmpty && _deleted.isEmpty) return;
    final dirty = _dirty.toList();
    final deleted = _deleted.toList();
    _dirty.clear();
    _deleted.clear();
    await _db.batch((batch) {
      for (final key in deleted) {
        batch.deleteWhere(
            _db.placeDoorsteps,
            (t) =>
                t.selfPubkey.equals(key.$1) &
                t.cell.equals(key.$2) &
                t.repeaterHash.equals(key.$3));
      }
      for (final key in dirty) {
        final r = rows[key];
        if (r == null) continue;
        batch.insert(
          _db.placeDoorsteps,
          PlaceDoorstepsCompanion.insert(
            selfPubkey: key.$1,
            cell: key.$2,
            repeaterHash: key.$3,
            uplinkSnr: Value(r.uplinkSnr),
            seenCount: Value(r.seenCount),
            lastSeenDay: r.lastSeenDay,
            failedHere: Value(r.failedHere),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
