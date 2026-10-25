import 'dart:math' as math;

/// Where the radio is, coarsely: a grid cell about 500 m across, named
/// by its indices only. The cell is all Pathfinder ever sees of the
/// radio's position (owner, 2026-10-25: no precise location is stored),
/// and the key is never written to a log.
///
/// Cells are 0.0045° tall (about 500 m) and as wide as makes them about
/// 500 m at their own latitude band, so the eight neighbours of a cell
/// cover roughly the same ground anywhere the mesh is likely to run.
class PlaceCell {
  PlaceCell._(this.key, this.near);

  /// The cell the position falls in.
  final String key;

  /// The eight cells around it. Together with [key] they cover about
  /// 1.5 km across, so a radio a street away from a proof still matches.
  final Set<String> near;

  static const double _step = 0.0045;

  static PlaceCell of(double lat, double lon) {
    final band = (lat / _step).floor();
    final key = _key(band, lon);
    final near = <String>{};
    for (var b = band - 1; b <= band + 1; b++) {
      final centre = _lonIndex(b, lon);
      for (var d = -1; d <= 1; d++) {
        final k = 'c${b}_${centre + d}';
        if (k != key) near.add(k);
      }
    }
    return PlaceCell._(key, near);
  }

  static String _key(int band, double lon) => 'c${band}_${_lonIndex(band, lon)}';

  static int _lonIndex(int band, double lon) {
    final centreLat = (band + 0.5) * _step * math.pi / 180;
    final lonStep = _step / math.max(math.cos(centreLat), 0.2);
    return (lon / lonStep).floor();
  }
}
