import 'dart:math' as math;
import 'dart:typed_data';

/// What a profile point is. Several can be set at once.
abstract final class PointKind {
  /// Where the path crosses a contour line: the height is that line's.
  static const crossing = 1;

  /// The top of a hill or the bottom of a valley between two crossings of
  /// the same line, where the slopes on either side meet.
  static const apex = 2;

  /// Added between other points so no two are more than the fill step
  /// apart (so the earth's curve shows on flat stretches).
  static const fill = 4;

  /// A path end, or the edge of a stretch with no data.
  static const end = 8;

  /// On a hilltop between two crossings of the same line: the real top may
  /// be higher than drawn.
  static const crest = 16;

  /// Lines may be missing here: a step of more than one interval between
  /// neighbouring crossings, or a stretch whose side (hill or valley)
  /// can't be told.
  static const uncertain = 32;

  /// The ground may be far lower than drawn: in a valley or a gap at one
  /// of the lowest contour lines, or where lines are missing next to it
  /// (the packs have no lines at or below sea level).
  static const belowLowest = 64;

  /// No data: outside every installed pack.
  static const unknown = 128;
}

/// Whether a contour [level] is one of the lowest three lines a pack can
/// have ([interval] metres apart, none at or below sea level). Next to
/// ground below sea level the packs often lack these lines (they stop
/// where the masked ground begins), so a valley or pit at one of them may
/// really be far lower.
bool isNearSeaLevel(double level, double interval) =>
    level > 0 && level <= 3 * interval + 1e-6;

/// Contour crossings along one path, in metres from its start.
class Crossings {
  Float64List _d = Float64List(64);
  Float64List _level = Float64List(64);
  Uint8List _pack = Uint8List(64);
  int length = 0;

  void add(double d, double level, int pack) {
    if (length == _d.length) {
      final n = length * 2;
      _d = Float64List(n)..setRange(0, length, _d);
      _level = Float64List(n)..setRange(0, length, _level);
      _pack = Uint8List(n)..setRange(0, length, _pack);
    }
    _d[length] = d;
    _level[length] = level;
    _pack[length] = pack;
    length++;
  }

  double d(int i) => _d[i];
  double level(int i) => _level[i];
  int pack(int i) => _pack[i];

  void clear() => length = 0;

  /// Sorts by distance.
  void sort() => _sort(0, length - 1);

  void _sort(int lo, int hi) {
    while (hi - lo > 16) {
      final p = _d[(lo + hi) >> 1];
      var i = lo, j = hi;
      while (i <= j) {
        while (_d[i] < p) {
          i++;
        }
        while (_d[j] > p) {
          j--;
        }
        if (i <= j) {
          _swap(i, j);
          i++;
          j--;
        }
      }
      if (j - lo < hi - i) {
        _sort(lo, j);
        lo = i;
      } else {
        _sort(i, hi);
        hi = j;
      }
    }
    for (var i = lo + 1; i <= hi; i++) {
      for (var j = i; j > lo && _d[j - 1] > _d[j]; j--) {
        _swap(j, j - 1);
      }
    }
  }

  void _swap(int i, int j) {
    final d = _d[i], l = _level[i], p = _pack[i];
    _d[i] = _d[j];
    _level[i] = _level[j];
    _pack[i] = _pack[j];
    _d[j] = d;
    _level[j] = l;
    _pack[j] = p;
  }
}

/// A summit with a known height projected onto the path.
class PathPeak {
  /// Distance along the path of the point nearest the peak, metres.
  final double d;

  /// How far off the path the peak is, metres.
  final double offsetM;
  final double eleM;
  final Object source;

  const PathPeak(this.d, this.offsetM, this.eleM, this.source);
}

/// The built profile: points in order of distance.
class ProfileData {
  final Float64List d;
  final Float64List h;

  /// How much higher the ground may be than drawn, for the Clear test.
  final Float64List raise;

  /// The contour interval that applies at each point, metres.
  final Float64List interval;
  final Uint8List kind;
  final double length;

  /// Peaks whose height was used for a hilltop.
  final List<PathPeak> peaksUsed;

  ProfileData(
    this.d,
    this.h,
    this.raise,
    this.interval,
    this.kind,
    this.length,
    this.peaksUsed,
  );

  int get count => d.length;

  /// The ground at [x] metres (linear between points); NaN where unknown.
  double heightAt(double x) {
    final i = indexAtOrBefore(x);
    if (i < 0) return h.isEmpty ? double.nan : h[0];
    if (i >= count - 1) return h[count - 1];
    final d0 = d[i], d1 = d[i + 1];
    if (d1 <= d0) return math.max(h[i], h[i + 1]);
    return h[i] + (h[i + 1] - h[i]) * (x - d0) / (d1 - d0);
  }

  /// The last point at or before [x], or -1.
  int indexAtOrBefore(double x) {
    var lo = 0, hi = count - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (d[mid] <= x) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi;
  }
}

/// Builds a profile from sorted [crossings].
///
/// [covered] holds the stretches with data as start, end pairs in metres;
/// the rest is unknown. [startM] and [endM] are the ground at the path's
/// ends when known. [packInterval] gives each pack's interval in metres,
/// by the pack index the crossings carry.
ProfileData buildProfile({
  required Crossings crossings,
  required double length,
  required double? startM,
  required double? endM,
  required List<double> covered,
  required List<double> packInterval,
  double fillStepM = 50,
  List<PathPeak> peaks = const [],
  double peakMaxAboveIntervals = 3,
}) {
  final b = _Builder(packInterval, fillStepM);
  final maxInterval = packInterval.isEmpty
      ? 0.0
      : packInterval.reduce(math.max);
  var ci = 0;
  var lastEnd = 0.0;
  for (var k = 0; k + 1 < covered.length; k += 2) {
    final s = covered[k], e = covered[k + 1];
    if (s > lastEnd + 1e-6) b.unknownStretch(lastEnd, s);
    while (ci < crossings.length && crossings.d(ci) < s) {
      ci++;
    }
    final run = <int>[];
    while (ci < crossings.length && crossings.d(ci) <= e) {
      run.add(ci++);
    }
    b.run(
      crossings,
      run,
      s,
      e,
      s <= 1e-6 ? startM : null,
      e >= length - 1e-6 ? endM : null,
      maxInterval,
      peaks,
      peakMaxAboveIntervals,
    );
    lastEnd = e;
  }
  if (lastEnd < length - 1e-6 || covered.isEmpty) {
    b.unknownStretch(lastEnd, length);
  }
  return b.finish(length);
}

class _Builder {
  final List<double> packInterval;
  final double fillStep;
  final _d = <double>[], _h = <double>[], _raise = <double>[];
  final _iv = <double>[];
  final _kind = <int>[];

  /// Flags and extra raise of the stretch from each point to the next.
  final _segKind = <int>[];
  final _segRaise = <double>[];
  final peaksUsed = <PathPeak>[];

  _Builder(this.packInterval, this.fillStep);

  void _add(double d, double h, int kind, double raise, double iv) {
    _d.add(d);
    _h.add(h);
    _kind.add(kind);
    _raise.add(raise);
    _iv.add(iv);
    _segKind.add(0);
    _segRaise.add(0);
  }

  void _seg(int kind, double raise) {
    _segKind.last = kind;
    _segRaise.last = raise;
  }

  void unknownStretch(double s, double e) {
    if (_d.isNotEmpty && _d.last >= s && _kind.last & PointKind.unknown != 0) {
      _d.last = math.max(_d.last, e);
      return;
    }
    _add(s, double.nan, PointKind.unknown | PointKind.end, 0, 0);
    _seg(PointKind.unknown, 0);
    _add(e, double.nan, PointKind.unknown | PointKind.end, 0, 0);
    _seg(PointKind.unknown, 0);
  }

  void run(
    Crossings c,
    List<int> raw,
    double s,
    double e,
    double? hs,
    double? he,
    double maxInterval,
    List<PathPeak> peaks,
    double peakMaxAbove,
  ) {
    // Drop doubles: the same line found twice within 1.5 m (a vertex on
    // the path, or the same line in two neighbouring tiles).
    final idx = <int>[];
    for (final i in raw) {
      if (idx.isNotEmpty) {
        final j = idx.last;
        if (c.level(i) == c.level(j) && c.d(i) - c.d(j) < 1.5) continue;
      }
      idx.add(i);
    }
    // A crossing with both neighbours on the same side of it (a "touch")
    // stays: either the path grazes the line, so the ground does reach
    // that level there, or the line's partner is missing (the packs often
    // lack the lowest lines next to the masked ground below sea level).
    // The slopes on either side then fail the side checks below and are
    // marked uncertain, so it never decides a side.
    final m = idx.length;
    double lv(int k) => c.level(idx[k]);
    double dv(int k) => c.d(idx[k]);
    double ivOf(int k) => packInterval[c.pack(idx[k])];
    bool low(int k) => isNearSeaLevel(lv(k), ivOf(k));

    if (m == 0) {
      // No lines: the ground stays within the band of the known end, which
      // has no floor below the lowest lines. Not known at all when neither
      // end is.
      final h0 = hs ?? he ?? double.nan, h1 = he ?? hs ?? double.nan;
      final known = hs ?? he;
      final below = known != null && known <= 3 * maxInterval + 1e-6;
      _add(s, h0, PointKind.end, 0, maxInterval);
      _seg(below ? PointKind.belowLowest : 0, 0);
      _add(e, h1, PointKind.end, 0, maxInterval);
      _seg(0, 0);
      return;
    }

    // The side of the ground in each gap between crossings k and k+1,
    // relative to their level, where both are the same level: +1 hill,
    // -1 valley, 0 can't tell. Neighbouring crossings decide; the path's
    // end heights only when no neighbour does.
    final side = List<int>.filled(m + 1, 0);
    // side[0]: before crossing 0 (start gap); side[k+1]: after crossing k.
    for (var k = 0; k < m; k++) {
      if (k + 1 < m && lv(k + 1) != lv(k)) {
        side[k + 1] = lv(k + 1) > lv(k) ? 1 : -1;
      }
    }
    for (var i = 0; i < m;) {
      var j = i;
      while (j + 1 < m && lv(j + 1) == lv(i)) {
        j++;
      }
      // Run of equal levels i..j; gaps i..j-1 inside it.
      int fromNeighbour(bool left) {
        if (left) return i > 0 ? (lv(i - 1) > lv(i) ? 1 : -1) : 0;
        return j + 1 < m ? (lv(j + 1) > lv(j) ? 1 : -1) : 0;
      }

      int fromEnd(bool left) {
        final h = left ? (i == 0 ? hs : null) : (j == m - 1 ? he : null);
        if (h == null || (h - lv(i)).abs() < 0.01) return 0;
        return h > lv(i) ? 1 : -1;
      }

      final nl = fromNeighbour(true), nr = fromNeighbour(false);
      final el = fromEnd(true), er = fromEnd(false);
      final n = j - i; // gaps inside the run
      // Side of the ground just before i and just after j.
      int? before, after;
      if (nl != 0 && nr != 0) {
        // Each crossing flips the side: after n+1 crossings the side
        // after j must match.
        final expected = (n + 1).isOdd ? -nl : nl;
        if (expected == nr) {
          before = nl;
          after = nr;
        }
      } else if (nl != 0 || nr != 0) {
        before = nl != 0 ? nl : ((n + 1).isOdd ? -nr : nr);
        after = nr != 0 ? nr : ((n + 1).isOdd ? -nl : nl);
      } else if (el != 0 || er != 0) {
        before = el != 0 ? el : ((n + 1).isOdd ? -er : er);
        after = er != 0 ? er : ((n + 1).isOdd ? -el : el);
      }
      if (before != null) {
        side[i] = before;
        for (var g = 0; g < n; g++) {
          side[i + 1 + g] = g.isEven ? -before : before;
        }
        side[j + 1] = after!;
      }
      i = j + 1;
    }

    // The side of the ground just after crossing k judged from its left,
    // and just before crossing k judged from its right (each crossing
    // flips the side): 1 above its level, -1 below, 0 can't tell.
    int afterLeft(int k) {
      if (k == 0) {
        if (hs == null || (hs - lv(0)).abs() < 0.01) return 0;
        return hs > lv(0) ? -1 : 1;
      }
      if (lv(k - 1) != lv(k)) return lv(k - 1) > lv(k) ? -1 : 1;
      return -side[k];
    }

    int beforeRight(int k) {
      if (k == m - 1) {
        if (he == null || (he - lv(k)).abs() < 0.01) return 0;
        return he > lv(k) ? -1 : 1;
      }
      if (lv(k + 1) != lv(k)) return lv(k + 1) > lv(k) ? -1 : 1;
      return -side[k + 1];
    }

    double? slopeOf(int gap) {
      // gap g lies between crossing g-1 and g; 0 and m are the end gaps.
      double h0, h1, d0, d1;
      if (gap <= 0) {
        if (hs == null) return null;
        h0 = hs;
        d0 = s;
        h1 = lv(0);
        d1 = dv(0);
      } else if (gap >= m) {
        if (he == null) return null;
        h0 = lv(m - 1);
        d0 = dv(m - 1);
        h1 = he;
        d1 = e;
      } else {
        h0 = lv(gap - 1);
        d0 = dv(gap - 1);
        h1 = lv(gap);
        d1 = dv(gap);
      }
      final dh = (h1 - h0).abs(), dd = d1 - d0;
      return dd > 1 && dh > 0.01 ? dh / dd : null;
    }

    // Start of the run.
    final iv0 = ivOf(0);
    var startKind = PointKind.end;
    double h0;
    if (hs != null) {
      h0 = hs;
    } else {
      final sl = slopeOf(1);
      final sd = side[0];
      h0 = lv(0) + (sl == null ? 0 : sd * math.min(iv0, sl * (dv(0) - s)));
      if (sd == 0) startKind |= PointKind.uncertain;
    }
    _add(s, h0, startKind, 0, iv0);
    final br = beforeRight(0);
    final startBelow =
        low(0) && (br < 0 || (hs != null ? hs < lv(0) - 0.01 : br == 0));
    _seg(startBelow ? PointKind.belowLowest : 0, 0);

    for (var k = 0; k < m; k++) {
      _add(dv(k), lv(k), PointKind.crossing, 0, ivOf(k));
      if (k == m - 1) break;
      final iv = math.max(ivOf(k), ivOf(k + 1));
      final da = dv(k), db = dv(k + 1);
      if (lv(k + 1) != lv(k)) {
        // A slope. Lines are missing when it spans more than one interval,
        // or when the crossings' other neighbours put the ground on the
        // wrong side of them (e.g. down through the lowest line, then up
        // through a higher one).
        final up = lv(k + 1) > lv(k);
        final a = afterLeft(k), b = beforeRight(k + 1);
        final missing =
            (lv(k + 1) - lv(k)).abs() > iv * 1.01 ||
            (a != 0 && (a > 0) != up) ||
            (b != 0 && (b < 0) != up);
        final below = (low(k) && a <= 0) || (low(k + 1) && b <= 0);
        final kind =
            (missing ? PointKind.uncertain : 0) |
            (below ? PointKind.belowLowest : 0);
        if (kind != 0) {
          final raise = missing ? iv : 0.0;
          _seg(kind, raise);
          if (db - da <= fillStep) {
            _add(
              (da + db) / 2,
              (lv(k) + lv(k + 1)) / 2,
              PointKind.fill | kind,
              raise,
              iv,
            );
            _seg(kind, raise);
          }
        }
        continue;
      }
      final sd = side[k + 1];
      final level = lv(k);
      if (sd == 0) {
        // Can't tell hill from valley: draw it flat, and allow for a hill
        // one interval high in the Clear test.
        final kind = PointKind.uncertain | (low(k) ? PointKind.belowLowest : 0);
        _seg(kind, iv);
        _add((da + db) / 2, level, PointKind.fill | kind, iv, iv);
        _seg(kind, iv);
        continue;
      }
      // Hill or valley: extend the slopes on either side until they meet,
      // rising at most one interval.
      var sl = slopeOf(k), sr = slopeOf(k + 2);
      sl ??= sr;
      sr ??= sl;
      final w = db - da;
      double x, rise;
      if (sl == null || sr == null) {
        x = w / 2;
        rise = iv / 2;
      } else {
        x = sr * w / (sl + sr);
        rise = math.min(sl * x, iv);
      }
      var apexD = da + x, apexH = level + sd * rise;
      var crestRaise = iv;
      if (sd > 0) {
        PathPeak? best;
        for (final p in peaks) {
          if (p.d <= da || p.d >= db) continue;
          if (p.eleM < apexH || p.eleM > apexH + peakMaxAbove * iv) continue;
          if (best == null || p.eleM > best.eleM) best = p;
        }
        if (best != null) {
          apexD = best.d;
          apexH = best.eleM;
          crestRaise = 0;
          peaksUsed.add(best);
        }
      }
      final gapKind = sd > 0
          ? PointKind.crest
          : (low(k) ? PointKind.belowLowest : 0);
      _seg(gapKind, 0);
      _add(apexD, apexH, PointKind.apex | gapKind, sd > 0 ? crestRaise : 0, iv);
      _seg(gapKind, 0);
    }

    // End of the run.
    final ivm = ivOf(m - 1);
    var endKind = PointKind.end;
    double h1;
    if (he != null) {
      h1 = he;
    } else {
      final sl = slopeOf(m - 1);
      final sd = side[m];
      h1 =
          lv(m - 1) +
          (sl == null ? 0 : sd * math.min(ivm, sl * (e - dv(m - 1))));
      if (sd == 0) endKind |= PointKind.uncertain;
    }
    final al = afterLeft(m - 1);
    final endBelow =
        low(m - 1) &&
        (al < 0 || (he != null ? he < lv(m - 1) - 0.01 : al == 0));
    _seg(endBelow ? PointKind.belowLowest : 0, 0);
    _add(e, h1, endKind, 0, ivm);
    _seg(0, 0);
  }

  ProfileData finish(double length) {
    // Fill: no two known points further apart than the fill step.
    final d = <double>[], h = <double>[], raise = <double>[], iv = <double>[];
    final kind = <int>[];
    for (var i = 0; i < _d.length; i++) {
      d.add(_d[i]);
      h.add(_h[i]);
      kind.add(_kind[i]);
      raise.add(_raise[i]);
      iv.add(_iv[i]);
      if (i + 1 == _d.length) break;
      final sk = _segKind[i];
      if (sk & PointKind.unknown != 0) continue;
      final d0 = _d[i], d1 = _d[i + 1];
      final gap = d1 - d0;
      if (gap <= fillStep || _h[i].isNaN || _h[i + 1].isNaN) continue;
      final n = (gap / fillStep).ceil();
      for (var k = 1; k < n; k++) {
        final f = k / n;
        d.add(d0 + gap * f);
        h.add(_h[i] + (_h[i + 1] - _h[i]) * f);
        kind.add(PointKind.fill | sk);
        raise.add(
          _segRaise[i] > 0
              ? _segRaise[i]
              : _raise[i] + (_raise[i + 1] - _raise[i]) * f,
        );
        iv.add(math.max(_iv[i], _iv[i + 1]));
      }
    }
    return ProfileData(
      Float64List.fromList(d),
      Float64List.fromList(h),
      Float64List.fromList(raise),
      Float64List.fromList(iv),
      Uint8List.fromList(kind),
      length,
      peaksUsed,
    );
  }
}
