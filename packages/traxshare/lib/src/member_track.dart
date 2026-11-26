import 'track.dart';

/// A member's track as this phone holds it: their pieces by minute, each the
/// one that reached furthest, then the finest, of those that came.
class MemberTrack {
  MemberTrack({Map<int, TrackPiece>? pieces, this.keepHours = defaultKeepHours})
    : pieces = pieces ?? {};

  /// Until their track says otherwise: TRAX settings' default.
  static const defaultKeepHours = 48;

  final Map<int, TrackPiece> pieces;

  /// The member's own setting, from their latest track.
  int keepHours;

  bool get isEmpty => pieces.isEmpty;

  /// Oldest first.
  List<TrackPiece> get inOrder =>
      pieces.values.toList()..sort((a, b) => a.minute.compareTo(b.minute));

  /// Takes what a report carried. A piece replaces the one of its minute
  /// when it reaches later, or as far on a finer grid. True when anything
  /// changed.
  bool add(TrackBlock block) {
    var changed = block.keepHours != keepHours;
    keepHours = block.keepHours;
    for (final p in block.pieces) {
      final had = pieces[p.minute];
      if (had == null ||
          p.endMinute > had.endMinute ||
          (p.endMinute == had.endMinute && p.gridM < had.gridM)) {
        pieces[p.minute] = p;
        changed = true;
      }
    }
    return changed;
  }

  /// Drops the pieces whose last point is more than [keepHours] before
  /// [now]; true when any went.
  bool expire(DateTime now) {
    final oldest = TrackPiece.minuteOf(now) - keepHours * 60;
    final before = pieces.length;
    pieces.removeWhere((_, p) => p.endMinute < oldest);
    return pieces.length != before;
  }

  /// The minutes of the pieces held at their finest, newest first: what an
  /// ask says this phone has.
  List<int> held() => [
    for (final p in pieces.values)
      if (p.gridM <= TrackPiece.fineGridM) p.minute,
  ]..sort((a, b) => b.compareTo(a));
}
