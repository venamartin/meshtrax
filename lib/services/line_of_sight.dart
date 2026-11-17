import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:traxlos/traxlos.dart';
import 'package:traxmap/latlong2.dart';
import 'package:traxmap/traxmap.dart' hide LatLng, LatLngBounds;

import '../models/app_settings.dart';
import 'map_packs_service.dart';

/// The installed packs line of sight reads, offline: the contours packs in
/// order of preference, each with the outline it was downloaded for, and
/// the street maps whose named peaks lend their heights.
class LosPacks {
  final List<ContourPack> contours;
  final List<String> peaks;

  const LosPacks(this.contours, this.peaks);

  bool get isEmpty => contours.isEmpty;

  /// Changes when a pack comes or goes.
  String get key => [...contours.map((c) => c.path), '|', ...peaks].join('\n');
}

/// What line of sight reads for [units]: 20 ft contours where installed
/// (the finer lines), then the set in the user's units, then any other;
/// and every street map's peaks.
LosPacks losPacksFrom(MapPacksService maps, UnitSystem units) {
  final wanted = units == UnitSystem.imperial ? Units.imperial : Units.metric;
  int rank(Pack p) => p.variant == '20ft'
      ? 0
      : p.units == wanted
      ? 1
      : 2;
  final contours = [
    for (final p in maps.installed)
      if (p.kind == PackKind.contours) p,
  ]..sort((a, b) => rank(a).compareTo(rank(b)));
  return LosPacks(
    [
      for (final p in contours)
        ContourPack(p.file.path, coverage: _outline(maps, p)),
    ],
    [
      for (final p in maps.installed)
        if (p.kind == PackKind.osm) p.file.path,
    ],
  );
}

/// The outline [pack] was cut for, or its bounds when the region list
/// doesn't have it. Outer rings only: the list cuts big lakes out of a
/// region for drawing, but the packs were cut with them.
List<List<List<Geo>>> _outline(MapPacksService maps, Pack pack) {
  final region = pack.region == null ? null : maps.regions?[pack.region!];
  if (region != null) {
    return [
      for (final polygon in region.polygons)
        [
          [for (final p in polygon.first) Geo(p.latitude, p.longitude)],
        ],
    ];
  }
  final b = pack.bounds;
  return [
    [
      [
        Geo(b.south, b.west),
        Geo(b.south, b.east),
        Geo(b.north, b.east),
        Geo(b.north, b.west),
        Geo(b.south, b.west),
      ],
    ],
  ];
}

Geo geoOf(LatLng p) => Geo(p.latitude, p.longitude);

LatLng latLngOf(Geo g) => LatLng(g.lat, g.lon);

/// Where contours are missing: the regions whose contours can be
/// downloaded, and whether some of it has none to download.
class MissingContours {
  /// Regions with contours to download, and the pack each would get.
  final List<({Region region, PackIndexEntry pack})> offers;

  /// Some of it lies where no contours exist (Canada, Mexico, the sea).
  final bool noData;

  /// The catalogue isn't known (never fetched): nothing can be offered.
  final bool noCatalogue;

  const MissingContours({
    required this.offers,
    required this.noData,
    required this.noCatalogue,
  });

  bool get isEmpty => offers.isEmpty && !noData && !noCatalogue;

  int get bytes => offers.fold(0, (sum, o) => sum + o.pack.bytes);
}

/// The contours missing at [points]: each point's region (only to name
/// it), with the region's contours in [units] when it has any.
MissingContours missingContours(
  MapPacksService maps,
  UnitSystem units,
  Iterable<LatLng> points,
) {
  final regions = maps.regions;
  if (maps.index == null || regions == null) {
    return MissingContours(
      offers: const [],
      noData: false,
      noCatalogue: points.isNotEmpty,
    );
  }
  final offers = <String, ({Region region, PackIndexEntry pack})>{};
  var noData = false;
  for (final p in points) {
    final region = regions.regionAt(p.toOvm());
    if (region == null) {
      noData = true;
      continue;
    }
    if (offers.containsKey(region.path)) continue;
    final entry = maps.preferredContours(region.path, units);
    if (entry == null) {
      noData = true;
    } else if (maps.statusOf(entry) == PackStatus.available) {
      offers[region.path] = (region: region, pack: entry);
    }
  }
  return MissingContours(
    offers: offers.values.toList(),
    noData: noData,
    noCatalogue: false,
  );
}

/// Points every [stepM] metres along [stretches] of a line, for
/// [missingContours].
List<LatLng> pointsAlong(List<Stretch> stretches, {double stepM = 500}) => [
  for (final s in stretches)
    for (var k = 0, n = math.max(1, (s.lengthM / stepM).ceil()); k <= n; k++)
      latLngOf(
        k == 0
            ? s.start
            : k == n
            ? s.end
            : destination(s.start, _bearing(s.start, s.end), s.lengthM * k / n),
      ),
];

/// Points around [center] out to [radiusM] that no installed contours
/// pack covers, for [missingContours].
List<LatLng> uncoveredAround(LosPacks packs, LatLng center, double radiusM) {
  final c = geoOf(center);
  return [
    for (final p in [
      c,
      for (var b = 0; b < 360; b += 30)
        for (final f in const [0.35, 0.7, 1.0])
          destination(c, b + 15.0 * f, radiusM * f),
    ])
      if (!covers(packs, p)) latLngOf(p),
  ];
}

/// Whether one of [packs]' outlines holds [p].
bool covers(LosPacks packs, Geo p) {
  for (final pack in packs.contours) {
    for (final polygon in pack.coverage) {
      var inside = false;
      for (final ring in polygon) {
        for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
          final a = ring[i], b = ring[j];
          if ((a.lat > p.lat) != (b.lat > p.lat) &&
              p.lon <
                  a.lon + (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat)) {
            inside = !inside;
          }
        }
      }
      if (inside) return true;
    }
  }
  return false;
}

double _bearing(Geo a, Geo b) =>
    const Distance().bearing(LatLng(a.lat, a.lon), LatLng(b.lat, b.lon));

/// Line of sight and radio reach in an isolate of their own, so the map
/// never waits on the files or the maths.
///
/// The isolate stays for the next question and keeps the decoded tiles,
/// so a new antenna height is answered from memory. It has the pack files
/// open only while it works: Windows can't replace or delete an open file.
/// [dispose] kills it.
class LosWorker {
  Isolate? _isolate;
  ReceivePort? _inbox;
  Completer<SendPort>? _port;
  final _waiting = <int, _Waiting>{};
  var _next = 0;
  var _closed = false;

  /// The answer for the link [from] → [to].
  Future<LineOfSight> line(
    LosPacks packs,
    LinkEnd from,
    LinkEnd to, {
    required double frequencyMHz,
  }) async =>
      await _ask(_Line(++_next, packs, from, to, frequencyMHz), null)
          as LineOfSight;

  /// The sweep from [center] out to [radiusM], with the full answer for
  /// each of [targets]; null when [stop] came first. [onProgress] hears
  /// the share done.
  Future<Reach?> reach(
    LosPacks packs,
    LinkEnd center, {
    required double radiusM,
    required int rays,
    required List<LinkEnd> targets,
    required double frequencyMHz,
    double targetAntennaM = 1.5,
    void Function(double done)? onProgress,
  }) async => await _ask(
    _Reach(
      ++_next,
      packs,
      center,
      radiusM,
      rays,
      targetAntennaM,
      targets,
      frequencyMHz,
    ),
    onProgress,
  ) as Reach?;

  /// Stops every sweep asked for so far.
  void stop() {
    final port = _port;
    if (port == null || _closed) return;
    final upTo = _next;
    unawaited(port.future.then((p) => p.send(_Stop(upTo)), onError: (_) {}));
  }

  void dispose() {
    _closed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _inbox?.close();
    final closed = StateError('line of sight closed');
    if (_port case final port? when !port.isCompleted) {
      port.completeError(closed);
    }
    for (final w in _waiting.values) {
      w.completer.completeError(closed);
    }
    _waiting.clear();
  }

  Future<Object?> _ask(_Question q, void Function(double)? onProgress) async {
    if (_closed) throw StateError('line of sight closed');
    final port = await _start();
    if (_closed) throw StateError('line of sight closed');
    final waiting = _Waiting(onProgress);
    _waiting[q.id] = waiting;
    port.send(q);
    return waiting.completer.future;
  }

  Future<SendPort> _start() {
    if (_port case final port?) return port.future;
    final port = _port = Completer<SendPort>();
    final inbox = _inbox = ReceivePort();
    inbox.listen((m) {
      switch (m) {
        case final SendPort p:
          if (!port.isCompleted) port.complete(p);
        case _Progress(:final id, :final done):
          _waiting[id]?.onProgress?.call(done);
        case _Answer(:final id, :final result, :final error):
          final w = _waiting.remove(id);
          if (w == null) return;
          if (error == null) {
            w.completer.complete(result);
          } else {
            w.completer.completeError(StateError(error));
          }
      }
    });
    Isolate.spawn(_work, inbox.sendPort, debugName: 'line of sight').then(
      (isolate) {
        if (_closed) {
          isolate.kill(priority: Isolate.immediate);
        } else {
          _isolate = isolate;
        }
      },
      onError: (Object e) {
        if (!port.isCompleted) port.completeError(e);
      },
    );
    return port.future;
  }
}

class _Waiting {
  final completer = Completer<Object?>();
  final void Function(double)? onProgress;

  _Waiting(this.onProgress);
}

sealed class _Question {
  final int id;
  final LosPacks packs;

  const _Question(this.id, this.packs);
}

class _Line extends _Question {
  final LinkEnd from, to;
  final double frequencyMHz;

  const _Line(super.id, super.packs, this.from, this.to, this.frequencyMHz);
}

class _Reach extends _Question {
  final LinkEnd center;
  final double radiusM;
  final int rays;
  final double targetAntennaM;
  final List<LinkEnd> targets;
  final double frequencyMHz;

  const _Reach(
    super.id,
    super.packs,
    this.center,
    this.radiusM,
    this.rays,
    this.targetAntennaM,
    this.targets,
    this.frequencyMHz,
  );
}

class _Stop {
  final int upTo;

  const _Stop(this.upTo);
}

class _Progress {
  final int id;
  final double done;

  const _Progress(this.id, this.done);
}

class _Answer {
  final int id;
  final Object? result;
  final String? error;

  const _Answer(this.id, this.result, this.error);
}

/// The worker isolate: answers one question at a time, in order.
void _work(SendPort out) {
  final inbox = ReceivePort();
  out.send(inbox.sendPort);
  ContourTerrain? terrain;
  var key = '';
  var stopUpTo = 0;
  final queue = Queue<_Question>();
  var busy = false;

  ContourTerrain terrainFor(LosPacks packs) {
    if (terrain == null || key != packs.key) {
      terrain?.close();
      key = packs.key;
      terrain = ContourTerrain(
        contours: packs.contours,
        peakPacks: packs.peaks,
      );
    }
    return terrain!;
  }

  Future<void> drain() async {
    if (busy) return;
    busy = true;
    while (queue.isNotEmpty) {
      final q = queue.removeFirst();
      Object? result;
      String? error;
      try {
        switch (q) {
          case _Line():
            result = terrainFor(q.packs)
                .lineOfSight(q.from, q.to, frequencyMHz: q.frequencyMHz);
          case _Reach():
            result = q.id <= stopUpTo
                ? null
                : await terrainFor(q.packs).reach(
                    q.center,
                    radiusM: q.radiusM,
                    rays: q.rays,
                    targetAntennaM: q.targetAntennaM,
                    targets: q.targets,
                    frequencyMHz: q.frequencyMHz,
                    shouldStop: () => q.id <= stopUpTo,
                    onProgress: (done) => out.send(_Progress(q.id, done)),
                  );
        }
      } on Object catch (e) {
        error = '$e';
      }
      out.send(_Answer(q.id, result, error));
    }
    busy = false;
  }

  inbox.listen((m) {
    switch (m) {
      case _Stop(:final upTo):
        stopUpTo = math.max(stopUpTo, upTo);
      case final _Question q:
        queue.add(q);
        unawaited(drain());
    }
  });
}
