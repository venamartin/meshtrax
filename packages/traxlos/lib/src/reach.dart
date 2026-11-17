import 'dart:math' as math;
import 'dart:typed_data';

import 'geo.dart';
import 'line_of_sight.dart';
import 'profile.dart';
import 'reach_areas.dart';
import 'terrain.dart';

/// A stretch of one ray with one answer.
class ReachRun {
  /// Metres from the centre.
  final double startM;
  final double endM;
  final Verdict verdict;

  const ReachRun(this.startM, this.endM, this.verdict);

  @override
  String toString() =>
      'ReachRun(${startM.toStringAsFixed(0)}-${endM.toStringAsFixed(0)} m, '
      '${verdict.name})';
}

/// The 360° sweep from one point.
class Reach {
  final Geo center;
  final EndHeight centerGround;
  final double antennaM;
  final double targetAntennaM;
  final double radiusM;
  final double stepM;
  final double frequencyMHz;
  final int rays;

  /// For each ray, at bearing [bearingOf] its index, the stretches with
  /// the answer for a radio [targetAntennaM] above the ground there,
  /// in order from the centre. Samples are [stepM] apart.
  final List<List<ReachRun>> runs;

  /// The full answer for each target, in the order given.
  final List<LineOfSight> targets;

  final List<String> credits;
  final List<String> skippedPacks;

  const Reach({
    required this.center,
    required this.centerGround,
    required this.antennaM,
    required this.targetAntennaM,
    required this.radiusM,
    required this.stepM,
    required this.frequencyMHz,
    required this.rays,
    required this.runs,
    required this.targets,
    required this.credits,
    required this.skippedPacks,
  });

  /// Ray [ray]'s bearing, degrees clockwise from north.
  double bearingOf(int ray) => ray * 360.0 / rays;

  /// The share of the disc with one of [verdicts].
  double share(Set<Verdict> verdicts) {
    var area = 0.0;
    for (final ray in runs) {
      for (final r in ray) {
        if (verdicts.contains(r.verdict)) {
          area += r.endM * r.endM - r.startM * r.startM;
        }
      }
    }
    return area / (rays * radiusM * radiusM);
  }

  /// The ground with one of [verdicts], as areas to draw: neighbouring
  /// runs and rays join into one outline per patch of ground.
  List<ReachArea> areas(Set<Verdict> verdicts) =>
      reachAreas(center, [for (final ray in runs) _stretches(ray, verdicts)]);

  /// [ray]'s stretches with one of [verdicts], neighbouring runs joined.
  static List<(double, double)> _stretches(
    List<ReachRun> ray,
    Set<Verdict> verdicts,
  ) {
    final out = <(double, double)>[];
    double? start;
    var end = 0.0;
    for (final r in ray) {
      if (verdicts.contains(r.verdict)) {
        start ??= r.startM;
        end = r.endM;
      } else if (start != null) {
        out.add((start, end));
        start = null;
      }
    }
    if (start != null) out.add((start, end));
    return out;
  }
}

Future<Reach?> sweep({
  required ContourTerrain terrain,
  required LinkEnd center,
  required double radiusM,
  required int rays,
  required double stepM,
  required double targetAntennaM,
  required List<LinkEnd> targets,
  required double frequencyMHz,
  bool Function()? shouldStop,
  void Function(double done)? onProgress,
}) async {
  final pacer = Pacer(shouldStop, onProgress);
  final cg = terrain.endHeight(center);
  final runs = <List<ReachRun>>[];
  if (!cg.isKnown) {
    for (var k = 0; k < rays; k++) {
      runs.add([ReachRun(0, radiusM, Verdict.unknown)]);
    }
  } else {
    final c = center.position;
    final cx = worldX(c.lon), cy = worldY(c.lat);
    final r0 = radiusM / metresPerUnit(cy);
    final rUnits =
        radiusM / math.min(metresPerUnit(cy - r0), metresPerUnit(cy + r0)) + 2;
    // The tiles that reach into the disc.
    final tiles = <ContourTile>[];
    final x0 = ((cx - rUnits) / tileUnits).floor();
    final x1 = ((cx + rUnits) / tileUnits).floor();
    final y0 = ((cy - rUnits) / tileUnits).floor();
    final y1 = ((cy + rUnits) / tileUnits).floor();
    final total = (x1 - x0 + 1) * (y1 - y0 + 1);
    var done = 0;
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        done++;
        final left = (x * tileUnits).toDouble(),
            top = (y * tileUnits).toDouble();
        final nx = cx.clamp(left, left + tileUnits) - cx;
        final ny = cy.clamp(top, top + tileUnits) - cy;
        if (nx * nx + ny * ny > rUnits * rUnits) continue;
        final t = terrain.tileAt(x, y);
        if (t != null) tiles.add(t);
        if (await pacer.tick(0.5 * done / total)) return null;
      }
    }
    final perRay = [for (var k = 0; k < rays; k++) Crossings()];
    bucketCrossings(tiles, cx, cy, rUnits, radiusM, perRay);
    if (await pacer.tick(0.55)) return null;
    final intervals = terrain.packIntervals;
    final guards = terrain.packSeaGuardIntervals;
    final lambda = 299792458.0 / (frequencyMHz * 1e6);
    for (var k = 0; k < rays; k++) {
      final theta = 2 * math.pi * k / rays;
      final ux = math.sin(theta), uy = -math.cos(theta);
      final parts = terrain.coverage.coveredParts(
        cx,
        cy,
        cx + rUnits * ux,
        cy + rUnits * uy,
      );
      final covered = <double>[];
      for (var i = 0; i + 1 < parts.length; i += 2) {
        double m(double t) => math.min(
          radiusM,
          t * rUnits * metresPerUnit(cy + 0.5 * t * rUnits * uy),
        );
        final s = m(parts[i]), e = m(parts[i + 1]);
        if (e > s) covered.addAll([s, e]);
      }
      final cr = perRay[k]..sort();
      final p = buildProfile(
        crossings: cr,
        length: radiusM,
        startM: cg.groundM,
        endM: null,
        covered: covered,
        packInterval: intervals,
        packSeaGuardInterval: guards,
        fillStepM: 50,
      );
      final reachable = covered.isEmpty || covered[0] > 0 ? 0.0 : covered[1];
      runs.add(
        _rayRuns(
          p,
          cg.groundM!,
          center.antennaM,
          targetAntennaM,
          radiusM,
          stepM,
          reachable,
          lambda,
        ),
      );
      perRay[k] = Crossings();
      if (await pacer.tick(0.55 + 0.35 * (k + 1) / rays)) return null;
    }
  }
  final answers = <LineOfSight>[];
  for (var i = 0; i < targets.length; i++) {
    answers.add(terrain.lineFrom(center, cg, targets[i], frequencyMHz));
    if (await pacer.tick(0.9 + 0.1 * (i + 1) / targets.length)) return null;
  }
  onProgress?.call(1);
  return Reach(
    center: center.position,
    centerGround: cg,
    antennaM: center.antennaM,
    targetAntennaM: targetAntennaM,
    radiusM: radiusM,
    stepM: stepM,
    frequencyMHz: frequencyMHz,
    rays: rays,
    runs: runs,
    targets: answers,
    credits: terrain.credits,
    skippedPacks: terrain.skippedPacks,
  );
}

/// Sorts every contour segment in [tiles] into the rays its ends' angles
/// span (seen from the centre cx, cy) and adds its crossing with each,
/// in metres from the centre, to that ray's list in [out].
///
/// Rays are straight in Web Mercator, which keeps angles: ray k points
/// k / rays of the way round from north, clockwise. As on a line, a
/// crossing counts only inside its tile's own square.
void bucketCrossings(
  List<ContourTile> tiles,
  double cx,
  double cy,
  double rUnits,
  double radiusM,
  List<Crossings> out,
) {
  final rays = out.length;
  final step = 2 * math.pi / rays;
  final ux = Float64List(rays), uy = Float64List(rays);
  for (var k = 0; k < rays; k++) {
    ux[k] = math.sin(step * k);
    uy[k] = -math.cos(step * k);
  }
  final rr = rUnits * rUnits;
  const tol = 0.5;
  for (final t in tiles) {
    final l = t.lines;
    final s = tileUnits / l.extent;
    final ox = t.tx * tileUnits - cx, oy = t.ty * tileUnits - cy;
    final lox = ox - tol, hix = ox + tileUnits + tol;
    final loy = oy - tol, hiy = oy + tileUnits + tol;
    final xy = l.xy;
    for (var li = 0; li < l.lineCount; li++) {
      final level = l.levels[li];
      final j0 = l.starts[li], j1 = l.starts[li + 1];
      var px = ox + xy[2 * j0] * s, py = oy + xy[2 * j0 + 1] * s;
      var pa = math.atan2(px, -py);
      var pr = px * px + py * py;
      for (var j = j0 + 1; j < j1; j++) {
        final qx = ox + xy[2 * j] * s, qy = oy + xy[2 * j + 1] * s;
        final qa = math.atan2(qx, -qy);
        final qr = qx * qx + qy * qy;
        final ex = qx - px, ey = qy - py;
        var skip = false;
        if (pr > rr && qr > rr) {
          // Both ends outside: skip unless the segment dips into the disc.
          final len2 = ex * ex + ey * ey;
          final w = len2 == 0
              ? 0.0
              : (-(px * ex + py * ey) / len2).clamp(0.0, 1.0);
          final mx = px + ex * w, my = py + ey * w;
          skip = mx * mx + my * my > rr;
        }
        if (!skip) {
          var da = qa - pa;
          if (da > math.pi) da -= 2 * math.pi;
          if (da < -math.pi) da += 2 * math.pi;
          final lo = da >= 0 ? pa : pa + da, hi = da >= 0 ? pa + da : pa;
          final k0 = (lo / step).ceil(), k1 = (hi / step).floor();
          for (var k = k0; k <= k1; k++) {
            final kk = k % rays;
            final vx = ux[kk], vy = uy[kk];
            final den = vx * ey - vy * ex;
            if (den == 0) continue;
            final tr = (px * ey - py * ex) / den;
            if (tr <= 0) continue;
            final w = (px * vy - py * vx) / den;
            if (w < -1e-9 || w > 1 + 1e-9) continue;
            final ix = tr * vx, iy = tr * vy;
            if (ix < lox || ix >= hix || iy < loy || iy >= hiy) continue;
            final d = tr * metresPerUnit(cy + 0.5 * iy);
            if (d > radiusM) continue;
            out[kk].add(d, level, t.pack);
          }
        }
        px = qx;
        py = qy;
        pa = qa;
        pr = qr;
      }
    }
  }
}

/// The answer along one ray at every [step] metres, merged into runs.
List<ReachRun> _rayRuns(
  ProfileData p,
  double hA,
  double antA,
  double antT,
  double radius,
  double step,
  double reachable,
  double lambda,
) {
  const twoKR = 2 * kFactor * earthRadiusM;
  final za = hA + antA;
  final d = p.d, h = p.h, raise = p.raise, iv = p.interval, kind = p.kind;
  final n = p.count;
  final out = <ReachRun>[];
  Verdict? current;
  var runStart = 0.0;
  var idx = 0;
  final samples = (radius / step).floor();
  for (var s = 1; s <= samples; s++) {
    final t = s * step;
    Verdict v;
    while (idx + 1 < n && d[idx + 1] <= t) {
      idx++;
    }
    final gT = p.heightAt(t);
    final below =
        (kind[idx] | (idx + 1 < n ? kind[idx + 1] : 0)) & PointKind.belowLowest;
    if (t > reachable || gT.isNaN || below != 0) {
      v = Verdict.unknown;
    } else {
      final zt = gT + antT;
      var cls = 0;
      for (var i = 0; i <= idx; i++) {
        final x = d[i];
        if (x <= 0) continue;
        if (x >= t) break;
        final f = x / t;
        final o = h[i] + x * (t - x) / twoKR - (za + (zt - za) * f);
        if (x < nearEndM || x > t - nearEndM) {
          if (o > iv[i] + nearEndBlockedM) {
            cls = 2;
            break;
          }
          if (o > 0) cls = 1;
          continue;
        }
        if (o > 0) {
          final e = x * (t - x) / twoKR - (antA + (antT - antA) * f);
          if (o > iv[i] || e > 0) {
            cls = 2;
            break;
          }
        }
        if (cls == 0) {
          final c = o + raise[i];
          if (c >= 0 || 0.36 * lambda * x * (t - x) / t > c * c) cls = 1;
        }
      }
      v = cls == 2
          ? Verdict.blocked
          : (cls == 1 ? Verdict.marginal : Verdict.clear);
    }
    final start = s == 1 ? 0.0 : t - step / 2;
    if (v != current) {
      if (current != null) out.add(ReachRun(runStart, start, current));
      current = v;
      runStart = start;
    }
  }
  if (current != null) out.add(ReachRun(runStart, radius, current));
  return out;
}

/// Hands the event loop a turn now and then during long work.
class Pacer {
  final bool Function()? shouldStop;
  final void Function(double)? onProgress;
  final _clock = Stopwatch()..start();

  Pacer(this.shouldStop, this.onProgress);

  /// True when asked to stop. Every 15 ms or so it also reports [done]
  /// and lets other events run (such as the message that asks to stop).
  Future<bool> tick(double done) async {
    if (shouldStop?.call() ?? false) return true;
    if (_clock.elapsedMilliseconds < 15) return false;
    onProgress?.call(done.clamp(0.0, 1.0));
    await Future<void>.delayed(Duration.zero);
    _clock.reset();
    return shouldStop?.call() ?? false;
  }
}
