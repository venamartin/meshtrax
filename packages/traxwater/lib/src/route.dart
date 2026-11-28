import 'dart:math' as math;
import 'dart:typed_data';

import 'magnetic.dart';
import 'mesh.dart';
import 'trip.dart';
import 'wrm.dart';

const _nm = 1852.0;

/// How far a route keeps in from either end of each edge it crosses, at
/// most a quarter of the edge: its turns stay off the corners of the water it
/// may use, and a river's small bends make fewer of them.
const _cornerM = 50.0;

/// US charts in feet carry depths in metres to 0.1 m (6 ft is 1.8, not
/// 1.83), so a depth limit is compared this much low.
const _chartRoundingM = 0.05;

/// Where security zones come first, a metre in one counts as a kilometre
/// closer to land than the distance off.
const _securityFirstM = 1000.0;

/// Triangles are closed, and this much wider, so a line along an edge or
/// through a corner is in them.
const _eps = 1e-6;

/// A straightened leg may leave the usable water by this much in all.
const _tolM = 0.01;

/// A leg's price counts a stretch this close to a better triangle as in it:
/// a leg between two turns on an area's edge runs a hair inside the area.
const _nearM = 0.5;

/// Couldn't-keep stretches closer than this join, and shorter ones are left
/// out.
const _reportM = 25.0;

/// Areas the trip runs through for less than this aren't listed.
const _listM = 0.005 * _nm;

const _earthM = 6371008.8;

// Why an attribute row is out of a trip, by bit.
const _outDepth = 1, _outHazard = 2, _outNoEntry = 4, _outMast = 8;

// What a metre in a triangle adds to open water's 1.
const _wPreferred = 2.0, _wNearHazard = 1.0, _wKelp = 2.0, _wAvoid = 100.0;

/// Where a limit is relaxed to find out why a trip ends short, a metre it
/// would block costs this many times more.
const _relaxedCost = 1000.0;

/// A trip searches at most this many triangles unless told otherwise:
/// Seattle to San Diego takes about 2.6 million.
const _maxTriangles = 4000000;

/// A trip on the water from [from] to [to], for the boat in [options].
/// [hasTile] says which tiles there are, and [tileAt] reads one (null where
/// it can't). [when] sets the magnetic variation of the courses.
///
/// The search follows the tiles: the shortest chain of tiles whose water
/// joins, from the start's to the end's, with the tiles around them. Where
/// the water the boat can use runs on past those, the tiles it runs into
/// join, with the tiles around them, and it searches again. A trip that would
/// take more than [maxTriangles] ends short as too long, and where no tiles
/// join the ends, it ends short at the water nearest the end.
///
/// Limits take triangles out: the depth with room under the keel, hazards
/// within 15 m, "entry prohibited", and with a mast height whatever is
/// lower. The distance off land comes first: the search minimises metres
/// closer than it (outside the harbour approaches), then the cost, which
/// adds for security zones, traffic lanes, kelp, water near a hazard and
/// water shallower than preferred. Where the distance can't be kept anyway,
/// security zones come first instead (never without [secondSearch], for
/// comparing with the builder's test router). The corridor of triangles is
/// pulled taut, then straightened where a straight leg stays in the water
/// and costs no more.
///
/// Throws a [WaterRoutingException] when there are no tiles at an end, or
/// tiles of two builds.
WaterTrip routeOnWater(
  LatLon from,
  LatLon to, {
  required bool Function(int ix, int iy) hasTile,
  required WaterTile? Function(int ix, int iy) tileAt,
  WaterRouteOptions options = const WaterRouteOptions(),
  DateTime? when,
  int maxTriangles = _maxTriangles,
  bool secondSearch = true,
}) {
  final watch = Stopwatch()..start();
  bool has(int key) => hasTile(key % tileColumns, key ~/ tileColumns);
  WaterTile? read(int key) {
    final ix = key % tileColumns, iy = key ~/ tileColumns;
    final t = tileAt(ix, iy);
    if (t != null && (t.ix != ix || t.iy != iy)) {
      throw FormatException('tile ${t.iy}_${t.ix} read as ${iy}_$ix');
    }
    return t;
  }

  final chain = _chain(from, to, has, read);
  final keys = <int>[], taken = <int>{};
  void take(int key) {
    for (final k in _around(key)) {
      if (taken.add(k) && has(k)) keys.add(k);
    }
  }

  chain.tiles.forEach(take);
  var searches = 0, loadMs = watch.elapsedMilliseconds, searchMs = 0;
  while (true) {
    final loading = Stopwatch()..start();
    final tiles = <WaterTile>[], loaded = <int>{};
    var triangles = 0, cut = false;
    for (final k in keys) {
      final t = read(k);
      if (t == null) continue;
      if (triangles + t.triangleCount > maxTriangles) {
        cut = true;
        break;
      }
      triangles += t.triangleCount;
      tiles.add(t);
      loaded.add(k);
    }
    final m = WaterMesh.load(tiles);
    loadMs += loading.elapsedMilliseconds;
    final search = _Search(
      m,
      from,
      to,
      options,
      goalIn: chain.reaches && loaded.contains(chain.goal),
    );
    searches++;
    searchMs += search.ms;
    if (!search.found && search.goal >= 0 && !cut) {
      final before = keys.length;
      for (final k in search.frontier()) {
        if (has(k)) take(k);
      }
      if (keys.length > before) continue;
    }
    return search.trip(
      when: when ?? DateTime.now(),
      secondSearch: secondSearch,
      because: !chain.reaches || (!cut && search.goal < 0)
          ? EndsShortReason.noConnection
          : cut
          ? EndsShortReason.tooLong
          : null,
      watch: watch,
      searches: searches,
      loadMs: loadMs,
      searchMs: searchMs,
    );
  }
}

/// The tiles a trip follows: the shortest chain of tiles whose water joins,
/// from the part of the water at the start (in its tile, or the nearest
/// tile within two) to the part at the end. Where none joins them, the chain
/// runs to the tile it reaches nearest the end.
///
/// A tile's water joins the next tile's where their border edges share a
/// stretch, as the mesh joins them, and its own parts are what join inside
/// it, so the chain never crosses land.
({List<int> tiles, int goal, bool reaches}) _chain(
  LatLon from,
  LatLon to,
  bool Function(int key) has,
  WaterTile? Function(int key) read,
) {
  final startKey = _tileNear(from, has), goalKey = _tileNear(to, has);
  if (startKey == null || goalKey == null) {
    throw const WaterRoutingException(WaterRoutingProblem.noTiles);
  }
  final joins = <int, _Joins?>{};
  _Joins? joinsOf(int key) => joins.putIfAbsent(key, () {
    final t = read(key);
    return t == null ? null : _Joins(t);
  });
  int? partAt(int key, LatLon p) {
    final t = read(key);
    if (t == null) return null;
    return (joins[key] = _Joins(t, p)).atPart;
  }

  final startPart = partAt(startKey, from), goalPart = partAt(goalKey, to);
  if (startPart == null || goalPart == null) {
    throw const WaterRoutingException(WaterRoutingProblem.noTiles);
  }
  final goal = goalKey << 20 | goalPart;
  final ids = <int, int>{}, nodes = <int>[], best = <double>[];
  final back = <int>[], done = <int>{};
  int idOf(int node) => ids.putIfAbsent(node, () {
    nodes.add(node);
    best.add(double.infinity);
    back.add(-1);
    return nodes.length - 1;
  });
  final heap = _Heap();
  final first = idOf(startKey << 20 | startPart);
  best[first] = 0;
  heap.push(_apart(startKey, goalKey), 0, first);
  var reached = -1, nearest = first, nearestApart = double.infinity;
  while (heap.isNotEmpty) {
    final i = heap.pop();
    if (!done.add(i)) continue;
    final node = nodes[i], key = node >> 20, part = node & 0xfffff;
    if (node == goal) {
      reached = i;
      break;
    }
    final apart = _apart(key, goalKey);
    if (apart < nearestApart) (nearest, nearestApart) = (i, apart);
    final here = joins[key]!;
    for (var side = 0; side < 4; side++) {
      final mine = here.sides[part * 4 + side];
      final next = _across(key, side);
      if (mine == null || next == null || !has(next)) continue;
      final there = joinsOf(next);
      if (there == null) continue;
      for (final q in there.partsOn[side ^ 1]) {
        if (!_overlap(mine, there.sides[q * 4 + (side ^ 1)]!)) continue;
        final n = idOf(next << 20 | q);
        final d = best[i] + _apart(key, next);
        if (done.contains(n) || d >= best[n]) continue;
        best[n] = d;
        back[n] = i;
        heap.push(d + _apart(next, goalKey), 0, n);
      }
    }
  }
  final tiles = <int>[];
  for (var i = reached >= 0 ? reached : nearest; i >= 0; i = back[i]) {
    tiles.add(nodes[i] >> 20);
  }
  return (tiles: tiles.reversed.toList(), goal: goalKey, reaches: reached >= 0);
}

/// A tile's water in the parts that join inside it, and for each part and
/// side of the tile (0 west, 1 east, 2 south, 3 north) the stretches of the
/// side it meets: lo, hi, … in units along the side, merged. Given [at], it
/// also finds the part there.
class _Joins {
  factory _Joins(WaterTile t, [LatLon? at]) {
    final n = t.triangleCount, up = Int32List(n);
    for (var i = 0; i < n; i++) {
      up[i] = i;
    }
    int root(int a) {
      while (up[a] != a) {
        a = up[a] = up[up[a]];
      }
      return a;
    }

    for (var j = 0; j < 3 * n; j++) {
      final b = t.neighbours[j];
      if (b < 0) continue;
      final ra = root(j ~/ 3), rb = root(b);
      if (ra != rb) up[ra] = rb;
    }
    final part = Int32List(n), ids = <int, int>{};
    for (var i = 0; i < n; i++) {
      part[i] = ids.putIfAbsent(root(i), () => ids.length);
    }
    final x0 = t.ix * tileUnits - 1800000000, x1 = x0 + tileUnits;
    final y0 = t.iy * tileUnits - 900000000, y1 = y0 + tileUnits;
    final v = t.vertices, raw = <int, List<int>>{};
    for (var j = 0; j < t.triangles.length; j++) {
      if (t.neighbours[j] >= 0) continue;
      final a = 2 * t.triangles[j];
      final b = 2 * t.triangles[j - j % 3 + (j + 1) % 3];
      final ax = v[a], ay = v[a + 1], bx = v[b], by = v[b + 1];
      void add(int side, int p, int q) => (raw[part[j ~/ 3] * 4 + side] ??= [])
          .addAll([math.min(p, q), math.max(p, q)]);
      if (ax == bx && ax == x0) add(0, ay, by);
      if (ax == bx && ax == x1) add(1, ay, by);
      if (ay == by && ay == y0) add(2, ax, bx);
      if (ay == by && ay == y1) add(3, ax, bx);
    }
    final sides = <int, List<int>>{};
    final partsOn = [<int>[], <int>[], <int>[], <int>[]];
    for (final MapEntry(:key, :value) in raw.entries) {
      final order = List.generate(value.length ~/ 2, (i) => 2 * i)
        ..sort((p, q) => value[p].compareTo(value[q]));
      final merged = <int>[];
      for (final i in order) {
        if (merged.isNotEmpty && value[i] <= merged.last) {
          merged.last = math.max(merged.last, value[i + 1]);
        } else {
          merged.addAll([value[i], value[i + 1]]);
        }
      }
      sides[key] = merged;
      partsOn[key % 4].add(key ~/ 4);
    }
    return _Joins._(
      sides,
      partsOn,
      at == null ? -1 : part[_nearestTriangle(t, at)],
    );
  }

  _Joins._(this.sides, this.partsOn, this.atPart);

  final Map<int, List<int>> sides;

  /// By side, the parts that meet it.
  final List<List<int>> partsOn;

  /// The part at the point the tile was read for, or −1.
  final int atPart;
}

/// The triangle of [t] that holds [p], or else the one nearest it.
int _nearestTriangle(WaterTile t, LatLon p) {
  final v = t.vertices, tri = t.triangles;
  final px = p.lon * 1e7, py = p.lat * 1e7;
  final k = math.cos(p.lat * math.pi / 180);
  var best = 0, bestD = double.infinity;
  for (var i = 0; i < t.triangleCount && bestD > 0; i++) {
    var d = 0.0, inside = true;
    for (var e = 0; e < 3; e++) {
      final a = 2 * tri[3 * i + e], b = 2 * tri[3 * i + (e + 1) % 3];
      final ax = (v[a] - px) * k, ay = v[a + 1] - py;
      final bx = (v[b] - px) * k, by = v[b + 1] - py;
      if (ax * by - ay * bx < 0) inside = false;
      final ex = bx - ax, ey = by - ay, l = ex * ex + ey * ey;
      final s = l == 0 ? 0.0 : (-(ax * ex + ay * ey) / l).clamp(0.0, 1.0);
      final dx = ax + s * ex, dy = ay + s * ey;
      d = e == 0 ? dx * dx + dy * dy : math.min(d, dx * dx + dy * dy);
    }
    if (inside) d = 0;
    if (d < bestD) (best, bestD) = (i, d);
  }
  return best;
}

/// Whether two lists of stretches (lo, hi, …, sorted) share any length.
bool _overlap(List<int> a, List<int> b) {
  var i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (math.min(a[i + 1], b[j + 1]) > math.max(a[i], b[j])) return true;
    if (a[i + 1] < b[j + 1]) {
      i += 2;
    } else {
      j += 2;
    }
  }
  return false;
}

/// The tile across [side] of tile [key] (0 west, 1 east, 2 south, 3
/// north), or null past a pole.
int? _across(int key, int side) {
  final r = key ~/ tileColumns, c = key % tileColumns;
  return switch (side) {
    0 => r * tileColumns + (c - 1) % tileColumns,
    1 => r * tileColumns + (c + 1) % tileColumns,
    2 => r > 0 ? key - tileColumns : null,
    _ => r + 1 < tileRows ? key + tileColumns : null,
  };
}

/// The tile at [p], or else the nearest within two tiles of it, or null.
int? _tileNear(LatLon p, bool Function(int key) has) {
  final u = (p.lon + 180) / tileDeg, v = (p.lat + 90) / tileDeg;
  final k = math.cos(p.lat * math.pi / 180);
  int? found;
  var best = double.infinity;
  for (var dr = -2; dr <= 2; dr++) {
    for (var dc = -2; dc <= 2; dc++) {
      final r = v.floor() + dr, c = u.floor() + dc;
      if (r < 0 || r >= tileRows) continue;
      final key = r * tileColumns + c % tileColumns;
      if (!has(key)) continue;
      final ex = math.max(0.0, math.max(c - u, u - c - 1)) * k;
      final ey = math.max(0.0, math.max(r - v, v - r - 1));
      final d = ex * ex + ey * ey;
      if (d < best) (found, best) = (key, d);
    }
  }
  return found;
}

/// Tile [key] and the tiles around it, corners too.
Iterable<int> _around(int key) sync* {
  final r = key ~/ tileColumns, c = key % tileColumns;
  for (var dr = -1; dr <= 1; dr++) {
    if (r + dr < 0 || r + dr >= tileRows) continue;
    for (var dc = -1; dc <= 1; dc++) {
      yield (r + dr) * tileColumns + (c + dc) % tileColumns;
    }
  }
}

/// How far apart two tiles are, in tiles (a column narrower by cos lat).
double _apart(int a, int b) {
  final ra = a ~/ tileColumns, rb = b ~/ tileColumns;
  final dc = (a % tileColumns - b % tileColumns).abs();
  final x =
      math.min(dc, tileColumns - dc) *
      math.cos(((ra + rb + 1) / 2 * tileDeg - 90) * math.pi / 180);
  return math.sqrt(x * x + (ra - rb) * (ra - rb));
}

/// One search over a mesh: the trip's ends, costs and A*. [goal] is the
/// end's triangle, or −1 where the end isn't in the mesh.
class _Search {
  _Search(this.m, this.from, this.to, this.o, {required bool goalIn})
    : rows = _Rows(m, o, o.draftM + o.underKeelM - _chartRoundingM),
      inside = Float64List(m.triangleCount),
      zone = Uint8List(m.triangleCount) {
    final n = m.triangleCount;
    if (n == 0) throw const WaterRoutingException(WaterRoutingProblem.noTiles);
    cost = rows.triangles(m);
    final (s, x, y, fromAt) = _end(m, rows, cost, from);
    start = s;
    sx = x;
    sy = y;
    fromEnd = fromAt;
    if (goalIn) {
      final (g, ex, ey, toAt) = _end(m, rows, cost, to);
      goal = g;
      gx = ex;
      gy = ey;
      toEnd = toAt;
    } else {
      final (ex, ey) = m.toXY(to.lat, to.lon);
      goal = -1;
      gx = ex;
      gy = ey;
      toEnd = WaterEnd(asked: to, at: to, movedM: 0, moved: null, depthM: null);
    }
    final offLand = o.offLandNm;
    if (offLand != null) {
      inner = ringsNm.where((r) => r <= offLand + 1e-9).length;
      _approach(m, cost, inner, start, offLand, zone);
      if (goal >= 0) _approach(m, cost, inner, goal, offLand, zone);
      for (var t = 0; t < n; t++) {
        if (m.ring[m.row[t]] < inner && zone[t] == 0) inside[t] = 1;
      }
    }
    final w = Stopwatch()..start();
    astar = _AStar(m, cost, inside).run(start, sx, sy, goal, gx, gy);
    ms = w.elapsedMilliseconds;
  }

  final WaterMesh m;
  final LatLon from, to;
  final WaterRouteOptions o;
  final _Rows rows;
  final Float64List inside;
  final Uint8List zone;
  late final Float64List cost;
  late final int start, goal;
  late final double sx, sy, gx, gy;
  late final WaterEnd fromEnd, toEnd;
  var inner = 0;
  late final _AStar astar;
  late final int ms;

  bool get found => astar.found;

  /// The tiles not in the mesh that the water the search reached runs on
  /// into.
  Set<int> frontier() => {
    for (var j = 0; j < m.frontierTri.length; j++)
      if (astar.closed[m.frontierTri[j]] != 0) m.frontierTile[j],
  };

  /// The trip. Where the search didn't reach the end, it ends short
  /// [because] of that, or for the reason [_whyShort] finds.
  WaterTrip trip({
    required DateTime when,
    required bool secondSearch,
    required EndsShortReason? because,
    required Stopwatch watch,
    required int searches,
    required int loadMs,
    required int searchMs,
  }) {
    final more = Stopwatch()..start();
    final n = m.triangleCount;
    var (end, ex, ey) = (goal, gx, gy);
    EndsShort? short;
    if (!found) {
      // The water the search reached nearest the end.
      var best = double.infinity;
      for (var t = 0; t < n; t++) {
        if (astar.closed[t] == 0) continue;
        final (x, y) = _closest(m, t, gx, gy);
        final d = (x - gx) * (x - gx) + (y - gy) * (y - gy);
        if (d < best) (best, end, ex, ey) = (d, t, x, y);
      }
      short = because == null
          ? _whyShort(m, rows, o, inside, start, goal)
          : EndsShort(
              reason: because,
              remainingM: 0,
              lowObjects: const [],
              deepestWayM: null,
            );
    }
    var (tris, steps) = astar.pathTo(end);
    Float64List? keep;
    final offLand = o.offLandNm;
    if (secondSearch && offLand != null && o.avoidSecurityZones) {
      final sec = Float64List(n);
      for (var t = 0; t < n; t++) {
        if (m.flags[m.row[t]] & flagSecurityZone != 0) sec[t] = 1;
      }
      var ran = false;
      (tris, steps, ran) = _securityFirst(m, cost, inside, sec, tris, steps);
      if (ran) keep = sec;
    }
    final moreMs = more.elapsedMilliseconds;

    final straightenWatch = Stopwatch()..start();
    final taut = _funnel(m, tris, steps, sx, sy, ex, ey);
    final path = _straighten(m, taut, cost, [inside, ?keep]);
    final straightenMs = straightenWatch.elapsedMilliseconds;

    final points = [
      for (var i = 0; i < path.length; i++)
        if (i == 0 && fromEnd.moved == null)
          from
        else if (i == path.length - 1 && toEnd.moved == null && short == null)
          to
        else
          m.toLatLon(path[i].$1, path[i].$2),
    ];
    final speed = o.speedKn * _nm / 3600;
    final legs = <WaterLeg>[], scale = <double>[];
    for (var i = 0; i + 1 < points.length; i++) {
      final (d, course) = _rhumb(points[i], points[i + 1]);
      final variation = magneticDeclination(points[i].lat, points[i].lon, when);
      legs.add(
        WaterLeg(
          from: points[i],
          to: points[i + 1],
          distanceM: d,
          courseTrue: course,
          courseMagnetic: (course - variation) % 360,
          time: Duration(milliseconds: (d / speed * 1000).round()),
        ),
      );
      final flat = math.sqrt(
        math.pow(path[i + 1].$1 - path[i].$1, 2) +
            math.pow(path[i + 1].$2 - path[i].$2, 2),
      );
      scale.add(flat > 0 ? d / flat : 1);
    }
    if (short != null && points.isNotEmpty) {
      short = EndsShort(
        reason: short.reason,
        remainingM: _rhumb(points.last, to).$1,
        lowObjects: short.lowObjects,
        deepestWayM: short.deepestWayM,
        deepestWayToM: short.deepestWayToM,
        deepestDraftM: short.deepestDraftM,
      );
    }

    final through = _Along(m, cost, inside, zone, inner, o)..walk(path, scale);
    return WaterTrip(
      legs: legs,
      from: fromEnd,
      to: toEnd,
      endsShort: short,
      areas: through.areas(),
      securityZoneM: through.securityM,
      trafficLaneM: through.laneM,
      leastDepthM: through.leastDepthM,
      leastDepthToM: through.leastDepthToM,
      shallowerThanPreferredM: o.preferDepthM == null ? null : through.shallowM,
      surveyM: through.surveyM,
      offLand: offLand == null
          ? null
          : OffLand(
              distanceNm: offLand,
              reachesDistance: through.reaches,
              insideInApproachesM: through.insideInApproachesM,
              insideElsewhereM: through.insideElsewhereM,
              couldntKeep: through.stretches(),
            ),
      lowestClearance: through.lowest(),
      outsideM: through.outsideM,
      magneticModelExpired: decimalYear(when) > magneticModelValidUntil,
      stats: WaterSearchStats(
        tiles: m.tileCount,
        triangles: n,
        searches: searches,
        expanded: astar.expanded,
        loadMs: loadMs,
        searchMs: searchMs + moreMs,
        straightenMs: straightenMs,
        totalMs: watch.elapsedMilliseconds,
      ),
    );
  }
}

/// Each attribute row's limits (why it's out, 0 when the boat can use it)
/// and cost per metre, for one trip.
class _Rows {
  _Rows(WaterMesh m, this.o, double lim)
    : out = Uint8List(m.depth.length),
      cost = Float64List(m.depth.length) {
    final mast = o.mastHeightM;
    final low = [
      for (final set in m.sets)
        mast != null && set.any((a) => a.isOverhead && _clearance(a, o) < mast),
    ];
    final prefer = o.preferDepthM;
    for (var r = 0; r < out.length; r++) {
      final f = m.flags[r], depth = m.depth[r];
      out[r] =
          (depth >= lim ? 0 : _outDepth) |
          (m.hazardInner[r] < lim ? _outHazard : 0) |
          (f & flagNoEntry != 0 ? _outNoEntry : 0) |
          (low[m.rowSet[r]] ? _outMast : 0);
      var c = 1.0;
      if (prefer != null && !(depth >= prefer - 0.2)) c += _wPreferred;
      if (m.hazardOuter[r] < lim) c += _wNearHazard;
      if (f & flagKelp != 0) c += _wKelp;
      if (o.avoidSecurityZones && f & flagSecurityZone != 0) c += _wAvoid;
      if (o.avoidTrafficLanes && f & flagTrafficLane != 0) c += _wAvoid;
      if (o.avoidTrafficLanes && f & flagSeparationZone != 0) c += _wAvoid;
      cost[r] = c;
    }
  }

  final WaterRouteOptions o;
  final Uint8List out;
  final Float64List cost;

  /// Each triangle's cost per metre: infinite where a limit takes it out,
  /// or [_relaxedCost] times more where only limits in [relax] do.
  Float64List triangles(WaterMesh m, {int relax = 0}) {
    final t = Float64List(m.triangleCount);
    for (var i = 0; i < t.length; i++) {
      final r = m.row[i], why = out[r];
      t[i] = why == 0
          ? cost[r]
          : why & ~relax == 0
          ? cost[r] * _relaxedCost
          : double.infinity;
    }
    return t;
  }
}

/// The clearance a mast is compared with under an overhead object: a bridge
/// that opens counts open (no limit where no open clearance is charted)
/// unless the trip avoids them; no charted clearance blocks, except at a
/// gate.
double _clearance(WaterArea a, WaterRouteOptions o) {
  if (a.opens && !o.avoidOpeningBridges) {
    return a.clearanceOpenM ?? double.infinity;
  }
  return a.charted ?? (a.isGate ? double.infinity : double.negativeInfinity);
}

BridgeNote? _note(WaterArea a, WaterRouteOptions o) {
  final mast = o.mastHeightM;
  if (mast == null || !a.isOverhead || !a.opens) return null;
  if (o.avoidOpeningBridges) return BridgeNote.clearsClosed;
  final closed = a.clearanceClosedM;
  return closed == null || closed < mast
      ? BridgeNote.needsOpening
      : BridgeNote.clearsClosed;
}

/// The charted clearance a trip passes under an object at: a bridge's open
/// clearance where it needs opening.
double? _passed(WaterArea a, WaterRouteOptions o) =>
    _note(a, o) == BridgeNote.needsOpening && !o.avoidOpeningBridges
    ? a.clearanceOpenM
    : a.charted;

/// A trip end: its triangle and point, moved to the nearest water the boat
/// can use when it isn't in some.
(int, double, double, WaterEnd) _end(
  WaterMesh m,
  _Rows rows,
  Float64List cost,
  LatLon p,
) {
  final (x, y) = m.toXY(p.lat, p.lon);
  final t = m.locate(x, y);
  final charted = t < 0 ? double.nan : m.depth[m.row[t]].toDouble();
  final depth = charted.isNaN ? null : charted;
  if (t >= 0 && cost[t].isFinite) {
    return (
      t,
      x,
      y,
      WaterEnd(asked: p, at: p, movedM: 0, moved: null, depthM: depth),
    );
  }
  var best = -1, bx = x, by = y, bd = double.infinity;
  for (var i = 0; i < cost.length; i++) {
    if (!cost[i].isFinite) continue;
    final (cx, cy) = _closest(m, i, x, y);
    final d = (cx - x) * (cx - x) + (cy - y) * (cy - y);
    if (d < bd) (best, bx, by, bd) = (i, cx, cy, d);
  }
  if (best < 0) throw const WaterRoutingException(WaterRoutingProblem.noWater);
  final why = t < 0 ? 0 : rows.out[m.row[t]];
  return (
    best,
    bx,
    by,
    WaterEnd(
      asked: p,
      at: m.toLatLon(bx, by),
      movedM: math.sqrt(bd),
      moved: t < 0
          ? EndMoved.notInWater
          : why & _outDepth != 0
          ? EndMoved.depth
          : why & _outHazard != 0
          ? EndMoved.hazard
          : why & _outNoEntry != 0
          ? EndMoved.noEntry
          : EndMoved.mastHeight,
      depthM: depth,
    ),
  );
}

/// The point of triangle [t] nearest (px, py).
(double, double) _closest(WaterMesh m, int t, double px, double py) {
  final xy = m.xy;
  final a = 2 * m.tri[3 * t],
      b = 2 * m.tri[3 * t + 1],
      c = 2 * m.tri[3 * t + 2];
  final ax = xy[a], ay = xy[a + 1], bx = xy[b], by = xy[b + 1];
  final cx = xy[c], cy = xy[c + 1];
  final abx = bx - ax, aby = by - ay, acx = cx - ax, acy = cy - ay;
  final d1 = abx * (px - ax) + aby * (py - ay);
  final d2 = acx * (px - ax) + acy * (py - ay);
  if (d1 <= 0 && d2 <= 0) return (ax, ay);
  final d3 = abx * (px - bx) + aby * (py - by);
  final d4 = acx * (px - bx) + acy * (py - by);
  if (d3 >= 0 && d4 <= d3) return (bx, by);
  final vc = d1 * d4 - d3 * d2;
  if (vc <= 0 && d1 >= 0 && d3 <= 0) {
    final v = d1 / (d1 - d3);
    return (ax + v * abx, ay + v * aby);
  }
  final d5 = abx * (px - cx) + aby * (py - cy);
  final d6 = acx * (px - cx) + acy * (py - cy);
  if (d6 >= 0 && d5 <= d6) return (cx, cy);
  final vb = d5 * d2 - d1 * d6;
  if (vb <= 0 && d2 >= 0 && d6 <= 0) {
    final w = d2 / (d2 - d6);
    return (ax + w * acx, ay + w * acy);
  }
  final va = d3 * d6 - d5 * d4;
  if (va <= 0 && d4 - d3 >= 0 && d5 - d6 >= 0) {
    final w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
    return (bx + w * (cx - bx), by + w * (cy - by));
  }
  final sum = va + vb + vc;
  if (sum == 0) return (ax, ay);
  final v = vb / sum, w = vc / sum;
  return (ax + abx * v + acx * w, ay + aby * v + acy * w);
}

/// A binary min-heap of (key, then key, then value).
class _Heap {
  var _k0 = Float64List(1024), _k1 = Float64List(1024), _v = Int32List(1024);
  var _n = 0;

  /// The first key of the value [pop] last returned.
  var popped = 0.0;

  bool get isNotEmpty => _n > 0;

  bool _below(double a0, double a1, int av, int j) =>
      a0 < _k0[j] ||
      (a0 == _k0[j] && (a1 < _k1[j] || (a1 == _k1[j] && av < _v[j])));

  void push(double k0, double k1, int v) {
    if (_n == _v.length) {
      _k0 = Float64List(2 * _n)..setRange(0, _n, _k0);
      _k1 = Float64List(2 * _n)..setRange(0, _n, _k1);
      _v = Int32List(2 * _n)..setRange(0, _n, _v);
    }
    var i = _n++;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (!_below(k0, k1, v, p)) break;
      _k0[i] = _k0[p];
      _k1[i] = _k1[p];
      _v[i] = _v[p];
      i = p;
    }
    _k0[i] = k0;
    _k1[i] = k1;
    _v[i] = v;
  }

  int pop() {
    final top = _v[0];
    popped = _k0[0];
    final n = --_n;
    if (n == 0) return top;
    final k0 = _k0[n], k1 = _k1[n], v = _v[n];
    var i = 0;
    while (true) {
      var c = 2 * i + 1;
      if (c >= n) break;
      if (c + 1 < n && _below(_k0[c + 1], _k1[c + 1], _v[c + 1], c)) c++;
      if (_below(k0, k1, v, c)) break;
      _k0[i] = _k0[c];
      _k1[i] = _k1[c];
      _v[i] = _v[c];
      i = c;
    }
    _k0[i] = k0;
    _k1[i] = k1;
    _v[i] = v;
    return top;
  }
}

/// A* over the steps from triangle to triangle, least (metres in [inside],
/// cost) compared as a pair: a trip never goes closer to land than the
/// distance off to save anything else. A step runs inside the triangle it
/// crosses, from the middle of the edge it came in by (or the start) to the
/// middle of the edge it leaves by (or the goal), so a long, thin triangle
/// costs about the water a trip crosses in it, not its length.
///
/// The search's states are those steps: 3t + k leaves triangle t by its
/// edge k, 3n + j by link j, and [_end] is the goal reached.
class _AStar {
  _AStar(this.m, this.cost, this.inside)
    : closed = Uint8List(m.triangleCount),
      _into = Int32List(m.triangleCount)..fillRange(0, m.triangleCount, -1),
      _n3 = 3 * m.triangleCount,
      _end = 3 * m.triangleCount + m.linkTo.length,
      _linkFrom = Int32List(m.linkTo.length) {
    final states = _end + 1;
    _g0 = Int32List(states)..fillRange(0, states, _never);
    _g1 = Float64List(states)..fillRange(0, states, double.infinity);
    _came = Int32List(states)..fillRange(0, states, -1);
    _done = Uint8List(states);
    for (var t = 0; t < m.triangleCount; t++) {
      for (var j = m.linkStart[t]; j < m.linkStart[t + 1]; j++) {
        _linkFrom[j] = t;
      }
    }
  }

  final WaterMesh m;
  final Float64List cost, inside;

  /// The triangles the search has been in.
  final Uint8List closed;

  /// The step the search first came into each triangle by.
  final Int32List _into;
  final int _n3, _end;
  final Int32List _linkFrom;

  /// Centimetres in [inside] and cost to each state.
  late final Int32List _g0;
  late final Float64List _g1;
  static const _never = 0x7fffffff;
  late final Int32List _came;
  late final Uint8List _done;
  final _heap = _Heap();
  var expanded = 0;
  var found = false;
  var _start = -1, _goal = -1;
  var _sx = 0.0, _sy = 0.0, _gx = 0.0, _gy = 0.0;

  /// The middle of the edge [_middle] was last asked about.
  var _mx = 0.0, _my = 0.0;

  _AStar run(int start, double sx, double sy, int goal, double gx, double gy) {
    _start = start;
    _sx = sx;
    _sy = sy;
    _goal = goal;
    _gx = gx;
    _gy = gy;
    closed[start] = 1;
    expanded = 1;
    if (start == goal) {
      found = true;
      return this;
    }
    _leave(start, sx, sy, 0, 0, -1);
    while (_heap.isNotEmpty) {
      final s = _heap.pop();
      if (_done[s] != 0) continue;
      _done[s] = 1;
      if (s == _end) {
        expanded++;
        found = true;
        break;
      }
      final r = _rev(s);
      if (r >= 0 &&
          (_g0[r] < _g0[s] || (_g0[r] == _g0[s] && _g1[r] < _g1[s]))) {
        continue;
      }
      final t = _to(s);
      _middle(s);
      final x = _mx, y = _my;
      if (_beaten(s, t, x, y)) continue;
      _done[s] = 2;
      expanded++;
      if (closed[t] == 0) {
        closed[t] = 1;
        _into[t] = s;
      }
      _leave(t, x, y, _g0[s], _g1[s], s);
    }
    return this;
  }

  /// Every step out of triangle [t] from (px, py), where the search got to
  /// at (g0, g1) by step [by]; and the goal, where [t] holds it. A step
  /// straight back never saves anything.
  void _leave(int t, double px, double py, int g0, double g1, int by) {
    final back = by < 0 ? -1 : _from(by);
    for (var s = 3 * t; s < 3 * t + 3; s++) {
      final nb = m.nbr[s];
      if (nb < 0 || nb == back || _done[s] != 0 || !cost[nb].isFinite) {
        continue;
      }
      _middle(s);
      _try(s, t, px, py, _mx, _my, g0, g1, by, _hypot(_mx - _gx, _my - _gy));
    }
    for (var j = m.linkStart[t]; j < m.linkStart[t + 1]; j++) {
      final s = _n3 + j, nb = m.linkTo[j];
      if (nb == back || _done[s] != 0 || !cost[nb].isFinite) continue;
      _middle(s);
      _try(s, t, px, py, _mx, _my, g0, g1, by, _hypot(_mx - _gx, _my - _gy));
    }
    if (t == _goal) _try(_end, t, px, py, _gx, _gy, g0, g1, by, 0);
  }

  /// State [s], reached from (px, py) straight to (x, y) across triangle
  /// [t], with [h] still to go at least.
  void _try(
    int s,
    int t,
    double px,
    double py,
    double x,
    double y,
    int g0,
    double g1,
    int by,
    double h,
  ) {
    final d = _hypot(x - px, y - py);
    final n0 = g0 + (d * inside[t] * 100).round();
    final n1 = g1 + d * cost[t];
    final r = s == _end ? -1 : _rev(s);
    if (r >= 0 && (_g0[r] < n0 || (_g0[r] == n0 && _g1[r] <= n1))) return;
    if (n0 < _g0[s] || (n0 == _g0[s] && n1 < _g1[s])) {
      _g0[s] = n0;
      _g1[s] = n1;
      _came[s] = by;
      _heap.push(n0.toDouble(), n1 + h, s);
    }
  }

  /// Whether the search already came into triangle [t] some other way that
  /// reaches (x, y), where step [s] comes in, no dearer: then nothing on
  /// from [s] can be cheaper.
  bool _beaten(int s, int t, double x, double y) {
    if (t == _start && _noDearer(s, t, x, y, _sx, _sy, 0, 0)) return true;
    for (var k = 3 * t; k < 3 * t + 3; k++) {
      final nb = m.nbr[k];
      if (nb < 0) continue;
      for (var e = 3 * nb; e < 3 * nb + 3; e++) {
        if (m.nbr[e] != t || e == s || _done[e] != 2) continue;
        _middle(e);
        if (_noDearer(s, t, x, y, _mx, _my, _g0[e], _g1[e])) return true;
      }
    }
    for (var j = m.linkStart[t]; j < m.linkStart[t + 1]; j++) {
      final nb = m.linkTo[j];
      for (var i = m.linkStart[nb]; i < m.linkStart[nb + 1]; i++) {
        final e = _n3 + i;
        if (m.linkTo[i] != t || e == s || _done[e] != 2) continue;
        _middle(e);
        if (_noDearer(s, t, x, y, _mx, _my, _g0[e], _g1[e])) return true;
      }
    }
    return false;
  }

  /// Whether (ex, ey) in triangle [t], reached for (e0, e1), goes on to
  /// (x, y) for no more than step [s] got there for.
  bool _noDearer(
    int s,
    int t,
    double x,
    double y,
    double ex,
    double ey,
    int e0,
    double e1,
  ) {
    final d = _hypot(x - ex, y - ey);
    return e0 + (d * inside[t] * 100).round() <= _g0[s] &&
        e1 + d * cost[t] <= _g1[s];
  }

  /// The same crossing the other way. Only the cheaper of the two is worth
  /// going on from: what the dearer one reaches, the step before the
  /// cheaper one reaches straight for less.
  int _rev(int s) {
    final t = _from(s), nb = _to(s);
    if (s < _n3) {
      for (var e = 3 * nb; e < 3 * nb + 3; e++) {
        if (m.nbr[e] == t) return e;
      }
    } else {
      for (var i = m.linkStart[nb]; i < m.linkStart[nb + 1]; i++) {
        if (m.linkTo[i] == t) return _n3 + i;
      }
    }
    return -1;
  }

  int _from(int s) => s < _n3 ? s ~/ 3 : _linkFrom[s - _n3];

  int _to(int s) => s < _n3 ? m.nbr[s] : m.linkTo[s - _n3];

  /// The step's code for [WaterMesh.portal] from the triangle it leaves.
  int _via(int s) => s < _n3 ? s % 3 : 3 + s - _n3;

  /// Sets (_mx, _my) to the middle of the edge step [s] crosses.
  void _middle(int s) {
    final xy = m.xy;
    if (s < _n3) {
      final k = s % 3;
      final a = 2 * m.tri[s], b = 2 * m.tri[k == 2 ? s - 2 : s + 1];
      _mx = (xy[a] + xy[b]) / 2;
      _my = (xy[a + 1] + xy[b + 1]) / 2;
    } else {
      final j = 4 * (s - _n3), l = m.linkXY;
      _mx = (l[j] + l[j + 2]) / 2;
      _my = (l[j + 1] + l[j + 3]) / 2;
    }
  }

  /// The triangles from the start to [t] (closed), and the step into each
  /// after the first.
  (List<int>, List<int>) pathTo(int t) {
    var s = t == _goal && found ? _came[_end] : _into[t];
    final tris = [t], steps = <int>[];
    while (s >= 0) {
      steps.add(_via(s));
      tris.add(_from(s));
      s = _came[s];
    }
    return (tris.reversed.toList(), steps.reversed.toList());
  }
}

double _hypot(double x, double y) => math.sqrt(x * x + y * y);

/// One end's harbour approach for the distance off: the water within about
/// the shortest way from the end out to the distance (× 1.2, + 0.1 nm). An
/// end that doesn't reach the distance within twice it plus 1 nm is in
/// narrow water and has none.
void _approach(
  WaterMesh m,
  Float64List cost,
  int inner,
  int end,
  double offLandNm,
  Uint8List zone,
) {
  final n = m.triangleCount, c = m.centroid;
  var cap = (2 * offLandNm + 1) * _nm;
  final dist = Float64List(n)..fillRange(0, n, double.infinity);
  final closed = Uint8List(n), done = <int>[];
  final heap = _Heap()..push(0, 0, end);
  dist[end] = 0;
  double? reach;
  while (heap.isNotEmpty) {
    final t = heap.pop(), d = heap.popped;
    if (closed[t] != 0) continue;
    if (d > cap) break;
    closed[t] = 1;
    done.add(t);
    if (reach == null && m.ring[m.row[t]] >= inner) {
      reach = d;
      cap = math.min(cap, d * 1.2 + 0.1 * _nm);
    }
    void step(int nb, double mx, double my) {
      if (closed[nb] != 0 || !cost[nb].isFinite) return;
      final nd =
          d +
          _hypot(mx - c[2 * t], my - c[2 * t + 1]) +
          _hypot(c[2 * nb] - mx, c[2 * nb + 1] - my);
      if (nd < dist[nb]) {
        dist[nb] = nd;
        heap.push(nd, 0, nb);
      }
    }

    for (var k = 0; k < 3; k++) {
      final nb = m.nbr[3 * t + k];
      if (nb < 0) continue;
      final (ax, ay, bx, by) = m.portal(t, k);
      step(nb, (ax + bx) / 2, (ay + by) / 2);
    }
    for (var j = m.linkStart[t]; j < m.linkStart[t + 1]; j++) {
      final (ax, ay, bx, by) = m.portal(t, 3 + j);
      step(m.linkTo[j], (ax + bx) / 2, (ay + by) / 2);
    }
  }
  if (reach != null) {
    for (final t in done) {
      zone[t] = 1;
    }
  }
}

/// Where a trip can't keep the distance off anyway, security zones come
/// first. Each run of the corridor closer than the distance that crosses a
/// security zone is searched again between the triangles either side of it,
/// with a metre in a zone counting as a kilometre closer, and spliced in.
/// Also says whether any search found a way.
(List<int>, List<int>, bool) _securityFirst(
  WaterMesh m,
  Float64List cost,
  Float64List inside,
  Float64List sec,
  List<int> tris,
  List<int> steps,
) {
  final first = Float64List(inside.length);
  for (var t = 0; t < first.length; t++) {
    first[t] = inside[t] + _securityFirstM * sec[t];
  }
  final runs = <(int, int)>[];
  for (var i = 0; i < tris.length;) {
    if (inside[tris[i]] <= 0) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < tris.length && inside[tris[j + 1]] > 0) {
      j++;
    }
    if (tris.sublist(i, j + 1).any((t) => sec[t] > 0)) runs.add((i, j));
    i = j + 1;
  }
  var ran = false;
  for (final (i, j) in runs.reversed) {
    final a = math.max(i - 1, 0), b = math.min(j + 1, tris.length - 1);
    final goal = tris[b];
    final c = m.centroid, from = tris[a];
    final again = _AStar(m, cost, first).run(
      from,
      c[2 * from],
      c[2 * from + 1],
      goal,
      c[2 * goal],
      c[2 * goal + 1],
    );
    if (!again.found) continue;
    ran = true;
    final (sub, subSteps) = again.pathTo(goal);
    tris = [...tris.sublist(0, a), ...sub, ...tris.sublist(b + 1)];
    steps = [...steps.sublist(0, a), ...subSteps, ...steps.sublist(b)];
  }
  return (tris, steps, ran);
}

double _cross(
  double ox,
  double oy,
  double ax,
  double ay,
  double bx,
  double by,
) => (ax - ox) * (by - oy) - (ay - oy) * (bx - ox);

/// The taut path through the corridor (a simple stupid funnel), with each
/// edge it crosses [_cornerM] shorter at both ends.
List<(double, double)> _funnel(
  WaterMesh m,
  List<int> tris,
  List<int> steps,
  double sx,
  double sy,
  double gx,
  double gy,
) {
  final gates = <(double, double, double, double)>[(sx, sy, sx, sy)];
  for (var i = 0; i < steps.length; i++) {
    final t = tris[i];
    final (ax, ay, bx, by) = m.portal(t, steps[i]);
    final left =
        _cross(
          m.centroid[2 * t],
          m.centroid[2 * t + 1],
          (ax + bx) / 2,
          (ay + by) / 2,
          ax,
          ay,
        ) >
        0;
    final (lx, ly, rx, ry) = left ? (ax, ay, bx, by) : (bx, by, ax, ay);
    final w = _hypot(rx - lx, ry - ly);
    final f = w > 0 ? math.min(_cornerM, w / 4) / w : 0.0;
    gates.add((
      lx + (rx - lx) * f,
      ly + (ry - ly) * f,
      rx - (rx - lx) * f,
      ry - (ry - ly) * f,
    ));
  }
  gates.add((gx, gy, gx, gy));
  bool same(double ax, double ay, double bx, double by) =>
      (ax - bx).abs() < 1e-6 && (ay - by).abs() < 1e-6;
  var (px, py, lx, ly, rx, ry) = (sx, sy, sx, sy, sx, sy);
  var apex = 0, li = 0, ri = 0;
  final path = [(sx, sy)];
  for (var i = 1; i < gates.length;) {
    final (glx, gly, grx, gry) = gates[i];
    if (_cross(px, py, rx, ry, grx, gry) >= 0) {
      if (same(px, py, rx, ry) || _cross(px, py, lx, ly, grx, gry) < 0) {
        (rx, ry, ri) = (grx, gry, i);
      } else {
        path.add((lx, ly));
        (px, py, apex) = (lx, ly, li);
        (rx, ry, li, ri) = (px, py, apex, apex);
        i = apex + 1;
        continue;
      }
    }
    if (_cross(px, py, lx, ly, glx, gly) <= 0) {
      if (same(px, py, lx, ly) || _cross(px, py, rx, ry, glx, gly) > 0) {
        (lx, ly, li) = (glx, gly, i);
      } else {
        path.add((rx, ry));
        (px, py, apex) = (rx, ry, ri);
        (lx, ly, li, ri) = (px, py, apex, apex);
        i = apex + 1;
        continue;
      }
    }
    i++;
  }
  path.add((gx, gy));
  final out = [path.first];
  for (final p in path.skip(1)) {
    if (!same(p.$1, p.$2, out.last.$1, out.last.$2)) out.add(p);
  }
  return out;
}

/// The part of the line p + t·d (0 ≤ t ≤ 1) in triangle [t] widened by
/// [_eps]: (t0, t1), with t0 ≥ t1 when there's none.
(double, double) _clip(
  WaterMesh m,
  int t,
  double px,
  double py,
  double dx,
  double dy,
) {
  final xy = m.xy, tri = m.tri;
  var t0 = 0.0, t1 = 1.0;
  for (var k = 0; k < 3; k++) {
    final a = 2 * tri[3 * t + k], b = 2 * tri[3 * t + (k + 1) % 3];
    final ex = xy[b] - xy[a], ey = xy[b + 1] - xy[a + 1];
    final length = math.sqrt(ex * ex + ey * ey);
    if (length == 0) continue;
    final f0 = ex * (py - xy[a + 1]) - ey * (px - xy[a]) + _eps * length;
    final f1 = ex * dy - ey * dx;
    if (f1 == 0) {
      if (f0 < 0) return (1, 0);
      continue;
    }
    final s = -f0 / f1;
    if (f1 > 0) {
      if (s > t0) t0 = s;
    } else if (s < t1) {
      t1 = s;
    }
    if (t0 >= t1) return (1, 0);
  }
  return (t0, t1);
}

/// The part of the line p + t·d (0 ≤ t ≤ 1, [length] long) within [r] of
/// triangle [t], given the part in it, (t0, t1): with t0 ≥ t1 when there's
/// none.
(double, double) _within(
  WaterMesh m,
  int t,
  double px,
  double py,
  double dx,
  double dy,
  double length,
  double r,
  double t0,
  double t1,
) {
  final xy = m.xy, tri = m.tri;
  final ux = dx / length, uy = dy / length;
  // In metres along the line. The triangle with the bands along its edges
  // and the discs round its corners is convex, so their parts make one.
  var lo = double.infinity, hi = double.negativeInfinity;
  if (t1 > t0) (lo, hi) = (t0 * length, t1 * length);
  for (var k = 0; k < 3; k++) {
    final a = 2 * tri[3 * t + k], b = 2 * tri[3 * t + (k + 1) % 3];
    final fx = px - xy[a], fy = py - xy[a + 1];
    final off = fx * uy - fy * ux;
    if (off.abs() <= r) {
      final mid = -(fx * ux + fy * uy), half = math.sqrt(r * r - off * off);
      lo = math.min(lo, mid - half);
      hi = math.max(hi, mid + half);
    }
    final ex = xy[b] - xy[a], ey = xy[b + 1] - xy[a + 1];
    final e = _hypot(ex, ey);
    if (e == 0) continue;
    final vx = ex / e, vy = ey / e;
    final (a0, a1) = _slab(fx * vx + fy * vy, ux * vx + uy * vy, 0, e);
    final (c0, c1) = _slab(fx * vy - fy * vx, ux * vy - uy * vx, -r, r);
    final s0 = math.max(a0, c0), s1 = math.min(a1, c1);
    if (s0 <= s1) {
      lo = math.min(lo, s0);
      hi = math.max(hi, s1);
    }
  }
  return (math.max(lo / length, 0.0), math.min(hi / length, 1.0));
}

/// Where a + s·b is from [lo] to [hi]: (s0, s1), with s0 > s1 when nowhere.
(double, double) _slab(double a, double b, double lo, double hi) {
  if (b == 0) {
    return a >= lo && a <= hi
        ? (double.negativeInfinity, double.infinity)
        : (double.infinity, double.negativeInfinity);
  }
  final s0 = (lo - a) / b, s1 = (hi - a) / b;
  return b > 0 ? (s0, s1) : (s1, s0);
}

/// Walks the line from (px, py) to (qx, qy) through the triangles [counts]
/// takes, exactly: calls [piece] with each stretch (as fractions of the
/// line, in order) and the triangles covering it. Returns the metres none
/// covers. With [near], [piece] has each triangle wherever the line comes
/// within [near] of it, and the metres returned are still those none holds.
double _sweep(
  WaterMesh m,
  double px,
  double py,
  double qx,
  double qy,
  bool Function(int t) counts,
  void Function(double t0, double t1, List<int> active) piece, {
  double near = 0,
}) {
  final dx = qx - px, dy = qy - py;
  final length = _hypot(dx, dy);
  if (length == 0) return 0;
  final ids = <int>[], at = <double>[], nearIds = <int>[], nearAt = <double>[];
  m.nearLine(px, py, qx, qy, math.max(_eps, near), (t) {
    if (!counts(t)) return;
    final (t0, t1) = _clip(m, t, px, py, dx, dy);
    if (t1 > t0) {
      ids.add(t);
      at.addAll([t0, t1]);
    }
    if (near > 0) {
      final (n0, n1) = _within(m, t, px, py, dx, dy, length, near, t0, t1);
      if (n1 > n0) {
        nearIds.add(t);
        nearAt.addAll([n0, n1]);
      }
    }
  });
  final gap = _cover(ids, at, near > 0 ? null : piece);
  if (near > 0) _cover(nearIds, nearAt, piece);
  return gap * length;
}

/// Calls [piece] with each stretch of the line (as fractions of it, in
/// order) that the stretches [at] of triangles [ids] cover, and the
/// triangles covering it. Returns the fraction none covers.
double _cover(
  List<int> ids,
  List<double> at,
  void Function(double t0, double t1, List<int> active)? piece,
) {
  // Events: 2k starts stretch k, 2k + 1 ends it; at a tie starts go first.
  final events = List.generate(at.length, (e) => e)
    ..sort((a, b) {
      final c = at[a].compareTo(at[b]);
      return c != 0 ? c : (a & 1) - (b & 1);
    });
  final active = <int>[];
  var from = 0.0, gap = 0.0;
  for (final e in events) {
    if (at[e] > from) {
      if (active.isEmpty) {
        gap += at[e] - from;
      } else {
        piece?.call(from, at[e], active);
      }
      from = at[e];
    }
    if (e & 1 == 0) {
      active.add(ids[e >> 1]);
    } else {
      active.remove(ids[e >> 1]);
    }
  }
  return gap + 1 - math.min(1.0, from);
}

/// Fewer legs: from each turn, the farthest later turn (up to 80 on) a
/// straight leg reaches through the usable water, with no more metres in
/// any of [measures] (closer than the distance off; in a security zone
/// once they come first somewhere) and no more than 2% extra cost.
List<(double, double)> _straighten(
  WaterMesh m,
  List<(double, double)> path,
  Float64List cost,
  List<Float64List> measures,
) {
  const slack = 0.02, ahead = 80;
  final sums = [
        for (final _ in measures) <double>[0],
      ],
      costs = <double>[0];
  for (var i = 0; i + 1 < path.length; i++) {
    final (ins, c, gap) = _price(m, path[i], path[i + 1], cost, measures);
    for (var k = 0; k < measures.length; k++) {
      sums[k].add(sums[k].last + ins[k]);
    }
    costs.add(costs.last + (gap <= _tolM ? c : double.infinity));
  }
  final out = [path.first];
  final last = path.length - 1;
  for (var i = 0; i < last;) {
    var next = i + 1;
    for (var j = math.min(last, i + ahead); j > i + 1; j--) {
      final ref = costs[j] - costs[i];
      if (!ref.isFinite) continue;
      // Points every eighth of the way first: most legs that leave the
      // water fail there, and the exact walk is the test.
      final (px, py) = path[i];
      final (qx, qy) = path[j];
      var wet = true;
      for (var k = 1; k < 8 && wet; k++) {
        wet = m.inWater(
          px + (qx - px) * k / 8,
          py + (qy - py) * k / 8,
          _tolM / 2,
          (t) => cost[t].isFinite,
        );
      }
      if (!wet) continue;
      final (ins, c, gap) = _price(m, path[i], path[j], cost, measures);
      if (gap > _tolM || c > ref * (1 + slack)) continue;
      var ok = true;
      for (var k = 0; k < measures.length && ok; k++) {
        ok = ins[k] <= sums[k][j] - sums[k][i] + 1;
      }
      if (ok) {
        next = j;
        break;
      }
    }
    out.add(path[next]);
    i = next;
  }
  return out;
}

/// A straight leg's metres in each of [measures] and its cost, counting
/// each stretch in the best usable triangle within [_nearM] (fewest metres
/// in the measure, then the cheapest), and the metres outside usable water.
(List<double>, double, double) _price(
  WaterMesh m,
  (double, double) p,
  (double, double) q,
  Float64List cost,
  List<Float64List> measures,
) {
  final ins = List<double>.filled(measures.length, 0);
  final length = _hypot(q.$1 - p.$1, q.$2 - p.$2);
  var c = 0.0;
  final gap = _sweep(m, p.$1, p.$2, q.$1, q.$2, (t) => cost[t].isFinite, (
    t0,
    t1,
    active,
  ) {
    final metres = (t1 - t0) * length;
    for (var k = 0; k < measures.length; k++) {
      final measure = measures[k];
      var best = active.first;
      for (final t in active.skip(1)) {
        if (measure[t] < measure[best] ||
            (measure[t] == measure[best] && cost[t] < cost[best])) {
          best = t;
        }
      }
      ins[k] += metres * measure[best];
      if (k == 0) c += metres * cost[best];
    }
  }, near: _nearM);
  return (ins, c, gap);
}

/// What a trip runs through, worked out exactly along its legs.
class _Along {
  _Along(this.m, this.cost, this.inside, this.zone, this.inner, this.o);

  final WaterMesh m;
  final Float64List cost, inside;
  final Uint8List zone;
  final int inner;
  final WaterRouteOptions o;

  var outsideM = 0.0, securityM = 0.0, laneM = 0.0, shallowM = 0.0;
  var insideInApproachesM = 0.0, insideElsewhereM = 0.0;
  var reaches = false;
  double? leastDepthM, leastDepthToM;
  final surveyM = <int, double>{};
  final _metres = <String, double>{}, _from = <String, double>{};
  final _area = <String, WaterArea>{};
  final _stretches = <Stretch>[];
  Stretch? _open;

  void walk(List<(double, double)> path, List<double> scale) {
    var run = 0.0;
    final prefer = o.preferDepthM;
    for (var i = 0; i + 1 < path.length; i++) {
      final (px, py) = path[i];
      final (qx, qy) = path[i + 1];
      final length = _hypot(qx - px, qy - py) * scale[i];
      outsideM +=
          _sweep(m, px, py, qx, qy, (_) => true, (t0, t1, active) {
            var best = active.first;
            for (final t in active.skip(1)) {
              if (inside[t] < inside[best] ||
                  (inside[t] == inside[best] &&
                      _rank(cost[t]) < _rank(cost[best]))) {
                best = t;
              }
            }
            final r = m.row[best], metres = (t1 - t0) * length;
            final at = run + t0 * length;
            final depth = m.depth[r], to = m.depthTo[r];
            if (!depth.isNaN && !(depth > (leastDepthM ?? depth))) {
              if (depth != leastDepthM) leastDepthToM = null;
              leastDepthM = depth;
              if (!to.isNaN) leastDepthToM = math.min(leastDepthToM ?? to, to);
            }
            if (prefer != null && !(depth >= prefer - 0.2)) shallowM += metres;
            surveyM[m.zoc[r]] = (surveyM[m.zoc[r]] ?? 0) + metres;
            final f = m.flags[r];
            if (f & flagSecurityZone != 0) securityM += metres;
            if (f & (flagTrafficLane | flagSeparationZone) != 0) {
              laneM += metres;
            }
            for (final a in m.sets[m.rowSet[r]]) {
              _metres[a.id] = (_metres[a.id] ?? 0) + metres;
              _from.putIfAbsent(a.id, () => at);
              _area.putIfAbsent(a.id, () => a);
            }
            if (o.offLandNm == null) return;
            if (m.ring[r] >= inner) {
              reaches = true;
            } else if (zone[best] != 0) {
              insideInApproachesM += metres;
            } else {
              insideElsewhereM += metres;
              final start = m.toLatLon(
                px + t0 * (qx - px),
                py + t0 * (qy - py),
              );
              final end = m.toLatLon(px + t1 * (qx - px), py + t1 * (qy - py));
              final open = _open;
              if (open != null && open.fromM + open.metres >= at - _reportM) {
                _open = Stretch(
                  fromM: open.fromM,
                  metres: at + metres - open.fromM,
                  start: open.start,
                  end: end,
                );
              } else {
                _close();
                _open = Stretch(
                  fromM: at,
                  metres: metres,
                  start: start,
                  end: end,
                );
              }
            }
          }) *
          scale[i];
      run += length;
    }
    _close();
  }

  static double _rank(double c) => c.isFinite ? c : 1e13;

  void _close() {
    final open = _open;
    if (open != null && open.metres >= _reportM) _stretches.add(open);
    _open = null;
  }

  List<Stretch> stretches() => _stretches;

  List<AreaPassed> areas() => [
    for (final id in _metres.keys)
      if (_metres[id]! >= _listM)
        AreaPassed(
          area: _area[id]!,
          metres: _metres[id]!,
          fromM: _from[id]!,
          note: _note(_area[id]!, o),
        ),
  ]..sort((a, b) => b.metres.compareTo(a.metres));

  /// The lowest charted clearance among the objects passed under.
  LowestClearance? lowest() {
    final over = areas().where((a) => a.area.isOverhead).toList();
    if (over.isEmpty) return null;
    AreaPassed? low;
    double? clearance;
    var uncharted = 0;
    for (final a in over) {
      final c = _passed(a.area, o);
      if (c == null) {
        if (!a.area.isGate) uncharted++;
      } else if (clearance == null || c < clearance) {
        (low, clearance) = (a, c);
      }
    }
    return LowestClearance(
      clearanceM: clearance,
      object: low?.area,
      fromM: low?.fromM,
      uncharted: uncharted,
    );
  }
}

/// Why the search can't reach the end. With a mast height it searches
/// again where a metre under something too low costs a lot instead of
/// blocking: if that reaches, the mast is why, and the objects on that way
/// are what's too low. Otherwise, if the end is reachable at any depth, the
/// depth is why, and the deepest way on is found.
EndsShort _whyShort(
  WaterMesh m,
  _Rows rows,
  WaterRouteOptions o,
  Float64List inside,
  int start,
  int goal,
) {
  final mast = o.mastHeightM;
  if (mast != null) {
    final search = _AStar(m, rows.triangles(m, relax: _outMast), inside);
    final c = m.centroid;
    final ran = search.run(
      start,
      c[2 * start],
      c[2 * start + 1],
      goal,
      c[2 * goal],
      c[2 * goal + 1],
    );
    if (ran.found) {
      final low = <String, WaterArea>{};
      for (final t in search.pathTo(goal).$1) {
        final r = m.row[t];
        if (rows.out[r] & _outMast == 0) continue;
        for (final a in m.sets[m.rowSet[r]]) {
          if (a.isOverhead && _clearance(a, o) < mast) {
            low.putIfAbsent(a.id, () => a);
          }
        }
      }
      return EndsShort(
        reason: EndsShortReason.mastHeight,
        remainingM: 0,
        lowObjects: low.values.toList(),
        deepestWayM: null,
      );
    }
  }
  final deepest = _deepestWay(m, rows, start, goal);
  return EndsShort(
    reason: deepest == null
        ? EndsShortReason.noConnection
        : EndsShortReason.depth,
    remainingM: 0,
    lowObjects: const [],
    deepestWayM: deepest?.depth,
    deepestWayToM: deepest?.to,
    deepestDraftM: deepest == null
        ? null
        : math.max(0, deepest.depth - o.underKeelM + _chartRoundingM),
  );
}

/// The deepest way from [start] to [goal] (a widest-path search over the
/// charted depths and the hazards within 15 m, where entry isn't
/// prohibited): its depth at its shallowest, and the deep end of the depth
/// band charted there (the least, where several are; null where only a
/// hazard or no charted depth sets it). Null where no water joins them.
({double depth, double? to})? _deepestWay(
  WaterMesh m,
  _Rows rows,
  int start,
  int goal,
) {
  final n = m.triangleCount;
  double depth(int t) {
    final r = m.row[t];
    var d = m.depth[r].isNaN ? 0.0 : m.depth[r].toDouble();
    final hazard = m.hazardInner[r];
    if (!hazard.isNaN && hazard < d) d = hazard.toDouble();
    return math.max(0, d);
  }

  bool open(int t) => rows.out[m.row[t]] & _outNoEntry == 0;
  final best = Float64List(n)..fillRange(0, n, -1);
  final came = Int32List(n)..fillRange(0, n, -1);
  final closed = Uint8List(n);

  ({double depth, double? to}) way() {
    final least = best[goal];
    double? to;
    for (var t = goal; t >= 0; t = came[t]) {
      final r = m.row[t], band = m.depthTo[r];
      if (depth(t) == least && m.depth[r] == least && !band.isNaN) {
        to = math.min(to ?? band, band);
      }
    }
    return (depth: least, to: to);
  }

  final heap = _Heap()..push(-depth(start), 0, start);
  best[start] = depth(start);
  while (heap.isNotEmpty) {
    final t = heap.pop();
    if (closed[t] != 0) continue;
    closed[t] = 1;
    if (t == goal) return way();
    void step(int nb) {
      if (closed[nb] != 0 || !open(nb)) return;
      final d = math.min(best[t], depth(nb));
      if (d > best[nb]) {
        best[nb] = d;
        came[nb] = t;
        heap.push(-d, 0, nb);
      }
    }

    for (var k = 0; k < 3; k++) {
      final nb = m.nbr[3 * t + k];
      if (nb >= 0) step(nb);
    }
    for (var j = m.linkStart[t]; j < m.linkStart[t + 1]; j++) {
      step(m.linkTo[j]);
    }
  }
  return null;
}

/// The rhumb line from [a] to [b] on the mean sphere: its length (m) and
/// course (degrees true).
(double, double) _rhumb(LatLon a, LatLon b) {
  final p1 = a.lat * math.pi / 180, p2 = b.lat * math.pi / 180;
  final dp = p2 - p1;
  var dl = (b.lon - a.lon) * math.pi / 180;
  if (dl.abs() > math.pi) dl -= 2 * math.pi * dl.sign;
  final dpsi = math.log(
    math.tan(math.pi / 4 + p2 / 2) / math.tan(math.pi / 4 + p1 / 2),
  );
  final q = dpsi.abs() > 1e-12 ? dp / dpsi : math.cos(p1);
  final d = math.sqrt(dp * dp + q * q * dl * dl) * _earthM;
  return (d, (math.atan2(dl, dpsi) * 180 / math.pi + 360) % 360);
}
