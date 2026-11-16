import 'dart:math' as math;
import 'dart:typed_data';

import 'coverage.dart';
import 'geo.dart';
import 'line_of_sight.dart';
import 'mvt.dart';
import 'pmtiles.dart';
import 'profile.dart';
import 'reach.dart';

/// An installed contours pack and the region it was downloaded for.
class ContourPack {
  final String path;

  /// The region's outline: polygons, each its outer ring followed by any
  /// holes. Inside it a missing tile means "no lines here"; outside every
  /// pack's outline the ground counts as not downloaded.
  final List<List<List<Geo>>> coverage;

  const ContourPack(this.path, {required this.coverage});
}

/// Line of sight and radio reach from installed contours packs, offline.
///
/// Give the packs in order of preference (the 20 ft variant before the
/// 10 m one): each z13 tile comes from the first pack that has it. Map
/// packs in [peakPacks] lend their named peaks' heights to hilltops and
/// ends near them.
///
/// Pack files are open only during a call and closed after it, so they
/// can be replaced or deleted between calls (Windows can't while they're
/// open). Decoded tiles stay in memory between calls; a replaced pack is
/// noticed and read afresh. Not safe to use from two isolates at once.
class ContourTerrain {
  /// Most decoded z13 tiles kept between calls (about 50 KB each).
  final int maxCachedTiles;

  /// How far above the contours' own hilltop height a peak's height may
  /// be and still be used, in contour intervals. Three by default: a
  /// summit can stand well above its highest line (Telescope Peak is
  /// 3369 m in OpenStreetMap, against about 3353 m from the 20 ft lines).
  final double peakMaxAboveIntervals;

  final List<_Pack> _packs;
  final List<_PeakPack> _peakPacks;
  final _tiles = <int, ContourTile>{};

  /// Tiles no pack has (small: kept apart from the decoded ones).
  final _absent = <int>{};
  final _peakTiles = <int, List<_PeakAt>>{};
  Coverage _coverage = Coverage(const []);
  int _depth = 0;
  final _usedPacks = <int>{};
  var _peaksUsed = false;

  ContourTerrain({
    required List<ContourPack> contours,
    List<String> peakPacks = const [],
    this.maxCachedTiles = 400,
    this.peakMaxAboveIntervals = 3,
  }) : _packs = [for (final p in contours) _Pack(PmtilesFile(p.path), p)],
       _peakPacks = [for (final p in peakPacks) _PeakPack(PmtilesFile(p))] {
    if (_packs.length > 255) throw ArgumentError('too many packs');
  }

  /// The answer for the link [from] → [to].
  LineOfSight lineOfSight(
    LinkEnd from,
    LinkEnd to, {
    double frequencyMHz = defaultFrequencyMHz,
  }) {
    _checkEnd(from);
    _checkEnd(to);
    if (!(frequencyMHz > 0)) {
      throw ArgumentError.value(frequencyMHz, 'frequencyMHz');
    }
    _begin();
    try {
      _usedPacks.clear();
      _peaksUsed = false;
      return _line(from, to, frequencyMHz);
    } finally {
      _end();
    }
  }

  /// The ground height at [p] from the contours (and a nearby peak).
  EndHeight groundAt(Geo p) {
    _begin();
    try {
      return _contourGround(p);
    } finally {
      _end();
    }
  }

  /// The 360° sweep from [center]: which ground a radio with
  /// [targetAntennaM] could be reached on, out to [radiusM], plus the full
  /// answer for each of [targets].
  ///
  /// Runs in steps, giving the event loop a turn every few milliseconds:
  /// [onProgress] hears the share done (0 to 1), and the sweep stops and
  /// returns null as soon as [shouldStop] returns true.
  Future<Reach?> reach(
    LinkEnd center, {
    double radiusM = 20000,
    int rays = 360,
    double stepM = 100,
    double targetAntennaM = 1.5,
    List<LinkEnd> targets = const [],
    double frequencyMHz = defaultFrequencyMHz,
    bool Function()? shouldStop,
    void Function(double done)? onProgress,
  }) async {
    _checkEnd(center);
    if (!(radiusM > 0) || radiusM > 100000) {
      throw ArgumentError.value(radiusM, 'radiusM');
    }
    if (rays < 4 || rays > 7200) throw ArgumentError.value(rays, 'rays');
    if (!(stepM >= 10)) throw ArgumentError.value(stepM, 'stepM');
    _begin();
    try {
      _usedPacks.clear();
      _peaksUsed = false;
      return await sweep(
        terrain: this,
        center: center,
        radiusM: radiusM,
        rays: rays,
        stepM: stepM,
        targetAntennaM: targetAntennaM,
        targets: targets,
        frequencyMHz: frequencyMHz,
        shouldStop: shouldStop,
        onProgress: onProgress,
      );
    } finally {
      _end();
    }
  }

  /// Drops the decoded tiles and closes the files.
  void close() {
    _tiles.clear();
    _absent.clear();
    _peakTiles.clear();
    for (final p in _packs) {
      p.file.close();
    }
    for (final p in _peakPacks) {
      p.file.close();
    }
  }

  // ---- internals shared with the sweep ----

  Coverage get coverage => _coverage;

  /// Each pack's contour interval in metres (0 for packs that can't be
  /// read).
  List<double> get packIntervals => [
    for (final p in _packs) p.info?.intervalM ?? 0,
  ];

  /// The z13 tile [x], [y] from the first pack that has it, or null.
  ContourTile? tileAt(int x, int y) {
    final key = x << tileZoom | y;
    var t = _tiles.remove(key) ?? ContourTile.none;
    if (identical(t, ContourTile.none) && !_absent.contains(key)) {
      for (var p = 0; p < _packs.length; p++) {
        final info = _packs[p].info;
        if (info == null) continue;
        final bytes = _packs[p].file.tile(tileZoom, x, y);
        if (bytes == null) continue;
        t = ContourTile(x, y, p, decodeContours(bytes, feet: info.feet));
        break;
      }
    }
    if (t.pack < 0) {
      _absent.add(key);
      return null;
    }
    if (_tiles.length >= maxCachedTiles) _tiles.remove(_tiles.keys.first);
    _tiles[key] = t;
    _usedPacks.add(t.pack);
    return t;
  }

  LineOfSight lineFrom(
    LinkEnd from,
    EndHeight fromGround,
    LinkEnd to,
    double frequencyMHz,
  ) => _line(from, to, frequencyMHz, fromGround: fromGround);

  EndHeight endHeight(LinkEnd end) => _endHeight(end);

  List<String> get credits {
    final out = <String>[];
    for (final p in _usedPacks) {
      final a = _packs[p].info?.attribution;
      if (a != null && !out.contains(a)) out.add(a);
    }
    if (_peaksUsed) {
      for (final p in _peakPacks) {
        final a = p.attribution;
        if (a != null && !out.contains(a)) out.add(a);
      }
    }
    return out;
  }

  List<String> get skippedPacks => [
    for (final p in _packs)
      if (p.info == null) p.file.path,
  ];

  // ---- sessions ----

  void _begin() {
    if (_depth++ > 0) return;
    var changed = false;
    for (final p in _packs) {
      final before = p.file.generation;
      try {
        p.file.open();
        if (p.file.generation != before || p.info == null) {
          p.info = _PackInfo.read(p.file);
          changed = true;
        }
      } catch (_) {
        if (p.info != null || !p.failed) changed = true;
        p.info = null;
        p.failed = true;
        p.file.close();
      }
    }
    if (changed) {
      _tiles.clear();
      _absent.clear();
      _coverage = Coverage([
        for (final p in _packs)
          if (p.info != null) ...p.pack.coverage,
      ]);
    }
    for (final p in _peakPacks) {
      final before = p.file.generation;
      try {
        p.file.open();
        if (p.file.generation != before || !p.ready) {
          p.read();
          _peakTiles.clear();
        }
      } catch (_) {
        p.ready = false;
        p.file.close();
      }
    }
  }

  void _end() {
    if (--_depth > 0) return;
    for (final p in _packs) {
      p.file.close();
    }
    for (final p in _peakPacks) {
      p.file.close();
    }
  }

  static void _checkEnd(LinkEnd e) {
    if (!(e.antennaM >= 0) || e.antennaM > 1000) {
      throw ArgumentError.value(e.antennaM, 'antennaM');
    }
    if (!(e.position.lat.abs() <= 85) || !(e.position.lon.abs() <= 180)) {
      throw ArgumentError.value(e.position, 'position');
    }
  }

  // ---- one line ----

  LineOfSight _line(
    LinkEnd from,
    LinkEnd to,
    double frequencyMHz, {
    EndHeight? fromGround,
  }) {
    final a = from.position, b = to.position;
    final length = distanceM(a, b);
    final fg = fromGround ?? _endHeight(from);
    final tg = _endHeight(to);
    final path = walk(a, b, length);
    path.crossings.sort();
    final peaks = _pathPeaks(path);
    final profile = buildProfile(
      crossings: path.crossings,
      length: length,
      startM: fg.groundM,
      endM: tg.groundM,
      covered: path.covered,
      packInterval: packIntervals,
      peaks: peaks,
      peakMaxAboveIntervals: peakMaxAboveIntervals,
    );
    final used = <Peak>[
      if (fg.peak != null) fg.peak!,
      if (tg.peak != null) tg.peak!,
      for (final p in profile.peaksUsed) p.source as Peak,
    ];
    if (used.isNotEmpty) _peaksUsed = true;
    return assembleLineOfSight(
      profile: profile,
      from: a,
      to: b,
      fromGround: fg,
      toGround: tg,
      fromAntennaM: from.antennaM,
      toAntennaM: to.antennaM,
      frequencyMHz: frequencyMHz,
      peaksUsed: used,
      credits: credits,
      skippedPacks: skippedPacks,
    );
  }

  /// The crossings along a→b ([length] metres on the great circle), cut
  /// into pieces of at most 1 km that are straight in Web Mercator.
  ///
  /// [stop] is asked after each piece whether the walk can end there.
  PathWalk walk(
    Geo a,
    Geo b,
    double length, {
    bool Function(Crossings crossings, List<double> covered)? stop,
  }) {
    final n = math.max(1, (length / 1000).ceil());
    final w = PathWalk(length);
    var prev = a;
    var ax = worldX(a.lon), ay = worldY(a.lat);
    for (var i = 1; i <= n; i++) {
      final next = i == n ? b : interpolate(a, b, i / n);
      var bx = worldX(next.lon);
      final by = worldY(next.lat);
      // Stay on the short way round across the antimeridian.
      if (bx - ax > worldUnits / 2) bx -= worldUnits;
      if (ax - bx > worldUnits / 2) bx += worldUnits;
      final d0 = i == 1 ? 0.0 : length * (i - 1) / n;
      final d1 = i == n ? length : length * i / n;
      w.pieces.addAll([ax, ay, bx, by, d0, d1]);
      final parts = _coverage.coveredParts(ax, ay, bx, by);
      double at(double t) => t <= 0 ? d0 : (t >= 1 ? d1 : d0 + (d1 - d0) * t);
      for (var k = 0; k + 1 < parts.length; k += 2) {
        final s = at(parts[k]), e = at(parts[k + 1]);
        if (w.covered.isNotEmpty && w.covered.last == s) {
          w.covered.last = e;
        } else {
          w.covered.addAll([s, e]);
        }
      }
      _walkTiles(ax, ay, bx, by, d0, d1, w.crossings);
      if (stop != null && stop(w.crossings, w.covered)) break;
      prev = next;
      ax = worldX(prev.lon);
      ay = by;
    }
    return w;
  }

  /// Visits the z13 tiles along one straight piece and collects its
  /// crossings.
  void _walkTiles(
    double ax,
    double ay,
    double bx,
    double by,
    double d0,
    double d1,
    Crossings out,
  ) {
    final fx0 = ax / tileUnits, fy0 = ay / tileUnits;
    final fx1 = bx / tileUnits, fy1 = by / tileUnits;
    var tx = fx0.floor(), ty = fy0.floor();
    final ex = fx1.floor(), ey = fy1.floor();
    final dx = fx1 - fx0, dy = fy1 - fy0;
    final sx = dx > 0 ? 1 : -1, sy = dy > 0 ? 1 : -1;
    var tmx = dx != 0 ? ((tx + (sx > 0 ? 1 : 0)) - fx0) / dx : double.infinity;
    var tmy = dy != 0 ? ((ty + (sy > 0 ? 1 : 0)) - fy0) / dy : double.infinity;
    final tdx = dx != 0 ? (1 / dx).abs() : double.infinity;
    final tdy = dy != 0 ? (1 / dy).abs() : double.infinity;
    const wrap = 1 << tileZoom;
    for (var guard = 0; guard < 4096; guard++) {
      final x = tx % wrap;
      if (ty >= 0 && ty < wrap) {
        final t = tileAt(x, ty);
        if (t != null) {
          final shift = (tx - x) * tileUnits.toDouble();
          crossTile(t, ax - shift, ay, bx - shift, by, d0, d1, out);
        }
      }
      if (tx == ex && ty == ey) break;
      if (tmx < tmy) {
        tx += sx;
        tmx += tdx;
      } else {
        ty += sy;
        tmy += tdy;
      }
    }
  }

  // ---- end heights ----

  EndHeight _endHeight(LinkEnd end) {
    final given = end.groundM;
    if (given != null && !end.groundIsFallback) {
      return EndHeight(given, HeightSource.given);
    }
    final est = _contourGround(end.position);
    if (est.isKnown || given == null) return est;
    return EndHeight(given, HeightSource.given);
  }

  /// The ground at [p] from 8 rays of 1.5 km (5 and then 15 km where
  /// they find too little).
  ///
  /// Each ray tells which side of the first line it meets the point is
  /// on, from whether the ground then rises or falls and how often it
  /// recrosses that line first. With a line known below and one above,
  /// the height is interpolated between their nearest points; inside a
  /// closed hill or pit it is the level plus or minus the slope times the
  /// distance, at most one interval. It is unknown where the rays
  /// disagree, or where the point may be below the lowest lines: the
  /// packs have none at or below sea level and often lack the lowest
  /// three next to that ground (see [isNearSeaLevel]), so a pit at one of
  /// them may be far deeper.
  EndHeight _contourGround(Geo p) {
    if (!_coverage.contains(worldX(p.lon), worldY(p.lat))) {
      return const EndHeight.unknown(HeightIssue.notDownloaded);
    }
    var hits = <_RayHit>[];
    for (final r in const [1500.0, 5000.0, 15000.0]) {
      hits = [for (var k = 0; k < 8; k++) ?_rayHit(p, k * 45.0, r)];
      final levels = {for (final h in hits) h.level};
      final sides = {for (final h in hits) h.side};
      if (hits.length == 8 ||
          (levels.length >= 2 && sides.contains(1) && sides.contains(-1))) {
        break;
      }
    }
    if (hits.isEmpty) return const EndHeight.unknown(HeightIssue.noLinesNearby);
    final intervals = packIntervals;
    hits.sort((a, b) => a.d.compareTo(b.d));
    final nearest = hits.first;
    final iv = intervals[nearest.pack];
    bool nearSea(double level) =>
        intervals.any((i) => i > 0 && isNearSeaLevel(level, i));
    const unknownBelow = EndHeight.unknown(HeightIssue.belowLowestContour);
    double nearestOf(double level) =>
        hits.firstWhere((h) => h.level == level).d;
    double between(double lo, double hi) {
      final a = nearestOf(lo), b = nearestOf(hi);
      if (a < 1) return lo;
      if (b < 1) return hi;
      return (lo / a + hi / b) / (1 / a + 1 / b);
    }

    double bend(int side) {
      final slopes = [
        for (final x in hits)
          if (x.side == side && x.nextD != null)
            (x.nextLevel! - x.level).abs() / math.max(1.0, x.nextD! - x.d),
      ]..sort();
      final dists = [
        for (final x in hits)
          if (x.side == side) x.d,
      ]..sort();
      if (slopes.isEmpty) return 0;
      return math.min(
        iv,
        slopes[slopes.length ~/ 2] * dists[dists.length ~/ 2],
      );
    }

    double? h;
    EndHeight? fail;
    if (nearest.d < 5) {
      // Standing on a line.
      h = nearest.level;
    } else {
      double? below, above; // the highest line below, the lowest above
      for (final x in hits) {
        if (x.side > 0 && (below == null || x.level > below)) below = x.level;
        if (x.side < 0 && (above == null || x.level < above)) above = x.level;
      }
      final levels = {for (final x in hits) x.level}.toList()..sort();
      if (below != null && above != null) {
        if (below < above) {
          h = between(below, above);
        } else if (below == above) {
          h = below;
        } else {
          fail = unknownBelow;
        }
      } else if (below != null) {
        final higher = levels.where((l) => l > below!).firstOrNull;
        h = higher != null ? between(below, higher) : below + bend(1);
      } else if (above != null) {
        final lower = levels.where((l) => l < above!).lastOrNull;
        if (lower != null) {
          h = nearSea(lower) ? null : between(lower, above);
        } else if (!nearSea(above)) {
          h = above - bend(-1);
        }
        if (h == null) fail = unknownBelow;
      } else if (nearSea(levels.first)) {
        fail = unknownBelow;
      } else {
        h = levels.length >= 2 ? between(levels[0], levels[1]) : levels.first;
      }
    }
    if (fail != null || h == null) return fail ?? unknownBelow;
    final top = h;
    final peak = _peakNear(
      p,
      50,
      (e) => e >= top && e <= top + peakMaxAboveIntervals * iv,
    );
    if (peak != null) {
      _peaksUsed = true;
      return EndHeight(peak.eleM, HeightSource.peak, peak: peak);
    }
    return EndHeight(h, HeightSource.contours);
  }

  /// The first line a ray from [p] meets within the covered part of the
  /// ray, and the side of it the point is on: the ground after a run of
  /// crossings of that line is on the side of the next line met, and
  /// each crossing in the run flips it.
  _RayHit? _rayHit(Geo p, double bearing, double r) {
    final q = destination(p, bearing, r);
    bool enough(Crossings c, List<double> covered) {
      if (covered.isEmpty || covered[0] > 0.5) return true;
      if (c.length < 2) return false;
      c.sort();
      final first = c.level(0);
      for (var i = 1; i < c.length; i++) {
        if (c.level(i) != first) return true;
      }
      return false;
    }

    final w = walk(p, q, r, stop: enough);
    final c = w.crossings..sort();
    final reach = w.covered.isEmpty || w.covered[0] > 0.5 ? 0.0 : w.covered[1];
    if (c.length == 0 || c.d(0) > reach) return null;
    final first = c.level(0);
    var runs = 1;
    var lastD = c.d(0);
    for (var i = 1; i < c.length && c.d(i) <= reach; i++) {
      final level = c.level(i);
      if (level == first) {
        // The same line again: a real recrossing unless it's a double.
        if (c.d(i) - lastD >= 1.5) runs++;
        lastD = c.d(i);
        continue;
      }
      final after = level > first ? 1 : -1;
      return _RayHit(
        c.d(0),
        first,
        c.pack(0),
        runs.isOdd ? -after : after,
        c.d(i),
        level,
      );
    }
    return _RayHit(c.d(0), first, c.pack(0), 0, null, null);
  }

  // ---- peaks ----

  List<_PeakAt> _peaksIn(int x13, int y13) {
    final key = x13 << tileZoom | y13;
    final cached = _peakTiles[key];
    if (cached != null) return cached;
    final out = <_PeakAt>[];
    final seen = <(double, double, String)>{};
    for (final pp in _peakPacks) {
      if (!pp.ready) continue;
      final z = math.min(tileZoom, pp.maxZoom);
      final shift = tileZoom - z;
      final tx = x13 >> shift, ty = y13 >> shift;
      final bytes = pp.file.tile(z, tx, ty);
      if (bytes == null) continue;
      final span = (tileUnits << shift).toDouble();
      for (final pk in decodePeaks(bytes)) {
        final wx = tx * span + pk.x * span / pk.extent;
        final wy = ty * span + pk.y * span / pk.extent;
        if (!seen.add((wx, wy, pk.name))) continue;
        out.add(_PeakAt(wx, wy, Peak(pk.name, pk.eleM, fromWorld(wx, wy))));
      }
    }
    if (_peakTiles.length > 4 * maxCachedTiles) _peakTiles.clear();
    _peakTiles[key] = out;
    return out;
  }

  Peak? _peakNear(Geo p, double withinM, bool Function(double ele) ok) {
    if (_peakPacks.isEmpty) return null;
    final x = worldX(p.lon) ~/ tileUnits, y = worldY(p.lat) ~/ tileUnits;
    Peak? best;
    var bestD = double.infinity;
    for (final pk in _peaksIn(x, y)) {
      final d = distanceM(p, pk.peak.position);
      if (d <= withinM && d < bestD && ok(pk.peak.eleM)) {
        best = pk.peak;
        bestD = d;
      }
    }
    return best;
  }

  /// Peaks within 30 m of the path, placed along it.
  List<PathPeak> _pathPeaks(PathWalk w) {
    if (_peakPacks.isEmpty) return const [];
    final tiles = <int>{};
    final pc = w.pieces;
    for (var i = 0; i < pc.length; i += 6) {
      _tilesOnPiece(pc[i], pc[i + 1], pc[i + 2], pc[i + 3], tiles);
    }
    final out = <PathPeak>[];
    final seen = <Peak>{};
    for (final key in tiles) {
      for (final pk in _peaksIn(key >> tileZoom, key & ((1 << tileZoom) - 1))) {
        if (seen.contains(pk.peak)) continue;
        var best = double.infinity, along = 0.0;
        for (var i = 0; i < pc.length; i += 6) {
          final ax = pc[i], ay = pc[i + 1], bx = pc[i + 2], by = pc[i + 3];
          final vx = bx - ax, vy = by - ay;
          final len2 = vx * vx + vy * vy;
          final t = len2 == 0
              ? 0.0
              : (((pk.x - ax) * vx + (pk.y - ay) * vy) / len2).clamp(0.0, 1.0);
          final px = ax + vx * t, py = ay + vy * t;
          final off =
              math.sqrt((pk.x - px) * (pk.x - px) + (pk.y - py) * (pk.y - py)) *
              metresPerUnit(py);
          if (off < best) {
            best = off;
            along = pc[i + 4] + (pc[i + 5] - pc[i + 4]) * t;
          }
        }
        if (best <= 30) {
          seen.add(pk.peak);
          out.add(PathPeak(along, best, pk.peak.eleM, pk.peak));
        }
      }
    }
    return out;
  }

  static void _tilesOnPiece(
    double ax,
    double ay,
    double bx,
    double by,
    Set<int> out,
  ) {
    final n = math.max(
      1,
      (math.max((bx - ax).abs(), (by - ay).abs()) / 512).ceil(),
    );
    for (var k = 0; k <= n; k++) {
      final x = ax + (bx - ax) * k / n, y = ay + (by - ay) * k / n;
      out.add(x ~/ tileUnits << tileZoom | y ~/ tileUnits);
    }
  }
}

/// The crossings along one path.
class PathWalk {
  final double length;
  final crossings = Crossings();

  /// Covered stretches: start, end pairs in metres.
  final covered = <double>[];

  /// Each piece: ax, ay, bx, by (world units), d0, d1 (metres).
  final pieces = <double>[];

  PathWalk(this.length);
}

/// A decoded z13 contour tile and a lazily built grid of its segments.
class ContourTile {
  final int tx, ty;

  /// Index of the pack it came from; -1 for "no pack has it".
  final int pack;
  final ContourLines lines;

  Int32List? _cellStart, _cellSeg, _lineOf, _stamp;
  int _visit = 0;

  ContourTile(this.tx, this.ty, this.pack, this.lines);

  static final none = ContourTile(-1, -1, -1, ContourLines.empty);

  static const _cells = 16;

  void _index() {
    final l = lines;
    final n = l.pointCount;
    final xy = l.xy;
    final cs = l.extent / _cells;
    final lineOf = Int32List(n);
    final counts = Int32List(_cells * _cells + 1);
    for (var pass = 0; pass < 2; pass++) {
      final fill = pass == 1 ? Int32List.fromList(counts) : null;
      final segs = pass == 1 ? Int32List(counts[_cells * _cells]) : null;
      for (var li = 0; li < l.lineCount; li++) {
        for (var j = l.starts[li]; j < l.starts[li + 1] - 1; j++) {
          if (pass == 0) lineOf[j] = li;
          final x0 = xy[2 * j], y0 = xy[2 * j + 1];
          final x1 = xy[2 * j + 2], y1 = xy[2 * j + 3];
          final c0 = _cell(math.min(x0, x1) / cs),
              c1 = _cell(math.max(x0, x1) / cs);
          final r0 = _cell(math.min(y0, y1) / cs),
              r1 = _cell(math.max(y0, y1) / cs);
          for (var r = r0; r <= r1; r++) {
            for (var c = c0; c <= c1; c++) {
              if (pass == 0) {
                counts[r * _cells + c + 1]++;
              } else {
                segs![fill![r * _cells + c]++] = j;
              }
            }
          }
        }
      }
      if (pass == 0) {
        for (var i = 1; i < counts.length; i++) {
          counts[i] += counts[i - 1];
        }
      } else {
        _cellSeg = segs;
      }
    }
    _cellStart = counts;
    _lineOf = lineOf;
    _stamp = Int32List(n);
  }

  static int _cell(double v) =>
      v < 0 ? 0 : (v >= _cells ? _cells - 1 : v.floor());
}

/// Adds the crossings of the straight piece a→b (world units; d0, d1 the
/// distances at its ends) with [t]'s lines. A crossing counts only inside
/// the tile's own square: tiles repeat their neighbours' lines near the
/// edges.
void crossTile(
  ContourTile t,
  double ax,
  double ay,
  double bx,
  double by,
  double d0,
  double d1,
  Crossings out,
) {
  final l = t.lines;
  if (l.lineCount == 0) return;
  if (t._cellStart == null) t._index();
  final ext = l.extent.toDouble();
  final s = ext / tileUnits;
  final ox = t.tx * tileUnits.toDouble(), oy = t.ty * tileUnits.toDouble();
  final lax = (ax - ox) * s, lay = (ay - oy) * s;
  final rx = (bx - ax) * s, ry = (by - ay) * s;
  final tol = 0.5 * s;
  // Clip the piece to the tile square.
  var t0 = 0.0, t1 = 1.0;
  bool clip(double p, double q) {
    if (p == 0) return q >= 0;
    final r = q / p;
    if (p < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
    return true;
  }

  if (!clip(-rx, lax + tol) ||
      !clip(rx, ext + tol - lax) ||
      !clip(-ry, lay + tol) ||
      !clip(ry, ext + tol - lay)) {
    return;
  }
  if (t0 > t1) return;
  const cells = ContourTile._cells;
  final cs = ext / cells;
  final sxf = (lax + rx * t0) / cs, syf = (lay + ry * t0) / cs;
  final exf = (lax + rx * t1) / cs, eyf = (lay + ry * t1) / cs;
  var cx = ContourTile._cell(sxf), cy = ContourTile._cell(syf);
  final ecx = ContourTile._cell(exf), ecy = ContourTile._cell(eyf);
  final ddx = exf - sxf, ddy = eyf - syf;
  final stx = ddx > 0 ? 1 : -1, sty = ddy > 0 ? 1 : -1;
  var tmx = ddx != 0 ? ((cx + (stx > 0 ? 1 : 0)) - sxf) / ddx : double.infinity;
  var tmy = ddy != 0 ? ((cy + (sty > 0 ? 1 : 0)) - syf) / ddy : double.infinity;
  final tdx = ddx != 0 ? (1 / ddx).abs() : double.infinity;
  final tdy = ddy != 0 ? (1 / ddy).abs() : double.infinity;
  final visit = ++t._visit;
  final stamp = t._stamp!, cellStart = t._cellStart!, cellSeg = t._cellSeg!;
  final lineOf = t._lineOf!, xy = l.xy, levels = l.levels;
  for (var guard = 0; guard < 4 * cells; guard++) {
    final cell = cy * cells + cx;
    for (var k = cellStart[cell]; k < cellStart[cell + 1]; k++) {
      final j = cellSeg[k];
      if (stamp[j] == visit) continue;
      stamp[j] = visit;
      final px = xy[2 * j].toDouble(), py = xy[2 * j + 1].toDouble();
      final sx = xy[2 * j + 2] - px, sy = xy[2 * j + 3] - py;
      final den = rx * sy - ry * sx;
      if (den == 0) continue;
      final tt = ((px - lax) * sy - (py - lay) * sx) / den;
      if (tt < 0 || tt > 1) continue;
      final uu = ((px - lax) * ry - (py - lay) * rx) / den;
      if (uu < 0 || uu > 1) continue;
      final ix = lax + rx * tt, iy = lay + ry * tt;
      if (ix < -tol || ix >= ext + tol || iy < -tol || iy >= ext + tol) {
        continue;
      }
      out.add(d0 + (d1 - d0) * tt, levels[lineOf[j]], t.pack);
    }
    if (cx == ecx && cy == ecy) break;
    if (tmx < tmy) {
      cx += stx;
      tmx += tdx;
    } else {
      cy += sty;
      tmy += tdy;
    }
    if (cx < 0 || cy < 0 || cx >= cells || cy >= cells) break;
  }
}

class _Pack {
  final PmtilesFile file;
  final ContourPack pack;
  _PackInfo? info;
  bool failed = false;

  _Pack(this.file, this.pack);
}

/// What a contours pack's metadata says about its lines.
class _PackInfo {
  final bool feet;
  final double intervalM;
  final String? attribution;

  _PackInfo(this.feet, this.intervalM, this.attribution);

  static _PackInfo read(PmtilesFile f) {
    final m = f.metadata;
    if (m['kind'] != null && m['kind'] != 'contours') {
      throw FormatException('not a contours pack: ${m['kind']}', f.path);
    }
    var interval = num.tryParse('${m['interval']}');
    var unit = m['interval_unit'] as String?;
    unit ??= switch (m['units']) {
      'imperial' => 'ft',
      'metric' => 'm',
      _ => null,
    };
    final variant = RegExp(r'^(\d+)(ft|m)$').firstMatch('${m['variant']}');
    if (variant != null) {
      interval ??= int.parse(variant.group(1)!);
      unit ??= variant.group(2);
    }
    if (interval == null || interval <= 0 || (unit != 'ft' && unit != 'm')) {
      throw FormatException('not a contours pack: no interval', f.path);
    }
    final feet = unit == 'ft';
    final a = m['attribution'];
    return _PackInfo(
      feet,
      interval * (feet ? 0.3048 : 1.0),
      a is String && a.isNotEmpty ? a : null,
    );
  }
}

class _PeakPack {
  final PmtilesFile file;
  bool ready = false;
  int maxZoom = 0;
  String? attribution;

  _PeakPack(this.file);

  void read() {
    maxZoom = file.header.maxZoom;
    final a = file.metadata['attribution'];
    attribution = a is String && a.isNotEmpty ? a : null;
    ready = true;
  }
}

class _PeakAt {
  final double x, y;
  final Peak peak;

  _PeakAt(this.x, this.y, this.peak);
}

class _RayHit {
  final double d, level;
  final int pack;

  /// Which side of the line the point is on: 1 above, -1 below, 0 unknown.
  final int side;
  final double? nextD, nextLevel;

  _RayHit(this.d, this.level, this.pack, this.side, this.nextD, this.nextLevel);
}
