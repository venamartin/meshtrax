import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:traxshare/traxshare.dart';

import '../connector/meshcore_connector.dart';
import '../storage/prefs_manager.dart';

typedef TrackPoint = ({double lat, double lon, DateTime at});

/// Which way and how fast while moving; how long since the last move
/// while not. All null right after a break, before a second point.
typedef TrackMotion = ({double? heading, double? speed, Duration? stillFor});

/// This radio's own way while TRAX mode is on, in pieces ([TrackPiece]):
/// the line behind its dot and what its reports carry, for [keepHours]. The
/// radio is read every 10 s (3 s while the map shows your speed) and a point
/// is kept every 25 m, never before its reading changes. A piece closes once
/// its points don't fit one report, or at a break: where live readings
/// stopped for 2 minutes or the position jumped. Nothing is drawn or sent
/// across a break. The line shows the points as kept; reports carry them
/// thinned.
class TraxTrack extends ChangeNotifier {
  TraxTrack(this._connector, {DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _rounds = PieceRounds(random);

  final MeshCoreConnector _connector;
  final DateTime Function() _clock;
  final PieceRounds _rounds;

  static const gateM = 25.0;
  static const gap = Duration(minutes: 2);

  /// Faster than this is a jump, not a drive.
  static const maxSpeed = 60.0;

  /// Moving while a point was kept this recently.
  static const movingFor = Duration(minutes: 2);

  /// Heading and speed are measured over at least this far: the radio's
  /// positions come in steps of about 11 m.
  static const motionM = 50.0;

  /// However straight the way, a piece closes at this many points.
  static const _maxOpenPoints = 500;

  /// The closed pieces' points, the oldest pieces going first.
  static const _maxPoints = 10000;

  /// The closed pieces' points as kept, for the line; beyond this many the
  /// oldest show thinned.
  static const _maxKeptPoints = 20000;
  static const _saveEvery = Duration(minutes: 1);

  static String keyFor(String radioKey) => 'trax_track_$radioKey';

  /// Closed, oldest first, thinned to [TrackPiece.epsilonM].
  final _pieces = <TrackPiece>[];

  /// The closed pieces' points as kept since the app started, by minute.
  final _kept = <int, List<TrailPoint>>{};

  /// The open piece's points as kept, oldest first.
  final _open = <TrackPoint>[];
  int _openMinute = 0;

  /// The points kept since the last break, the last [movingFor] of them.
  final _live = <TrackPoint>[];

  /// The pieces the latest trail carried at their finest.
  var _trailFine = <int>{};

  String _radioKey = '';
  bool _recording = false;
  DateTime? _liveAt;
  Timer? _saveTimer;
  int _keepHours = MemberTrack.defaultKeepHours;

  bool get recording => _recording;

  /// Whether the radio's reading is live: one came within [gap].
  bool get live {
    final at = _liveAt;
    return at != null && _clock().difference(at) <= gap;
  }

  /// How long each piece is kept after its last point: TRAX settings' "Keep
  /// my track".
  int get keepHours => _keepHours;
  set keepHours(int hours) {
    if (hours == _keepHours) return;
    _keepHours = hours;
    if (_expire()) _changed();
  }

  /// Starts reading the radio every 10 s and keeping points.
  void start() {
    if (_recording) return;
    _recording = true;
    _load();
    // A new start is a break: the time between wasn't recorded.
    _liveAt = null;
    _live.clear();
    if (_expire()) _changed();
    _connector.selfGps.addListener(_onReading);
    _connector.addSelfPositionViewer();
  }

  void stop() {
    if (!_recording) return;
    _recording = false;
    _connector.selfGps.removeListener(_onReading);
    _connector.removeSelfPositionViewer();
    _saveTimer?.cancel();
    _saveTimer = null;
    unawaited(_save());
  }

  /// The trail a report from [anchor] carries: the open piece, then the
  /// newest closed ones within 10 miles, as fine as fits [room].
  TrackBlock? trail(TrailPoint anchor, int room) {
    if (_expire()) _changed();
    final block = fitTrack(anchor, _newestFirst, room, keepHours: _keepHours);
    _trailFine = {
      if (block != null && block.gridM == TrackPiece.fineGridM)
        for (final p in block.pieces) p.minute,
    };
    return block;
  }

  /// The next piece of the rounds, alone, as fine as fits [room]: each piece
  /// once a round, but for those the latest trail carried at their finest.
  TrackBlock? nextOlder(TrailPoint anchor, int room) {
    if (_expire()) _changed();
    final minute = _rounds.next([
      for (final p in _newestFirst)
        if (!_trailFine.contains(p.minute)) p.minute,
    ]);
    return minute == null ? null : piece(minute, anchor, room);
  }

  /// The piece of [minute], alone, as fine as fits [room]; null once gone.
  TrackBlock? piece(int minute, TrailPoint anchor, int room) {
    final p = _newestFirst.where((p) => p.minute == minute).firstOrNull;
    return p == null
        ? null
        : fitTrack(anchor, [p], room, keepHours: _keepHours);
  }

  /// The minutes of the pieces not in [have], newest first; matched by their
  /// low 16 bits, as an ask carries them.
  List<int> missing(Iterable<int> have) {
    if (_expire()) _changed();
    final held = {for (final m in have) m & 0xFFFF};
    return [
      for (final p in _newestFirst)
        if (!held.contains(p.minute & 0xFFFF)) p.minute,
    ];
  }

  /// How the radio is moving, from the points kept; null without a live
  /// reading.
  TrackMotion? motion() {
    final live = _liveAt;
    final now = _clock();
    if (_live.isEmpty || live == null || now.difference(live) > gap) {
      return null;
    }
    final newest = _live.last;
    final since = now.difference(newest.at);
    if (since > movingFor) return (heading: null, speed: null, stillFor: since);
    TrackPoint? from;
    var seconds = 0.0;
    for (var i = _live.length - 2; i >= 0; i--) {
      final p = _live[i];
      if (from != null && newest.at.difference(p.at) > movingFor) break;
      from = p;
      seconds = newest.at.difference(p.at).inMilliseconds / 1000;
      if (_metres(from, newest) >= motionM) break;
    }
    if (from == null || seconds <= 0) {
      return (heading: null, speed: null, stillFor: null);
    }
    return (
      heading: _bearing(from, newest),
      speed: _metres(from, newest) / seconds,
      stillFor: null,
    );
  }

  /// The lines to draw behind the dot, each oldest first: all of the track,
  /// with its points as kept since the app started and those before as
  /// reports carry them. While the reading is live, the line runs on from
  /// the last point kept to [dot].
  List<List<TrailPoint>> lines({TrailPoint? dot}) {
    final open = [for (final p in _open) (lat: p.lat, lon: p.lon)];
    if (dot != null && open.isNotEmpty && live) open.add(dot);
    return trackLines([
      for (final p in _pieces)
        switch (_kept[p.minute]) {
          final points? => TrackPiece(
            minute: p.minute,
            endMinute: p.endMinute,
            points: points,
          ),
          null => p,
        },
      if (open.length >= 2)
        TrackPiece(minute: _openMinute, endMinute: _openMinute, points: open),
    ]);
  }

  TrackPiece? get _openPiece => _open.length < 2
      ? null
      : TrackPiece(
          minute: _openMinute,
          endMinute: max(_openMinute, TrackPiece.minuteOf(_open.last.at)),
          points: [for (final p in _open) (lat: p.lat, lon: p.lon)],
        );

  List<TrackPiece> get _newestFirst => [?_openPiece, ..._pieces.reversed];

  // The connector notes whether the reading changed after it sets it.
  void _onReading() => scheduleMicrotask(_keep);

  void _keep() {
    final c = _connector;
    final gps = c.selfGps.value;
    if (!_recording ||
        gps == null ||
        !c.selfGpsIsFresh ||
        !c.hasValidLocation(gps.latitude, gps.longitude)) {
      return;
    }
    final expired = _expire();
    final now = _clock();
    final p = (lat: gps.latitude, lon: gps.longitude, at: now);
    final live = _liveAt;
    _liveAt = now;
    final last = _live.lastOrNull;
    if (last == null || live == null || now.difference(live) > gap) {
      _restart(p);
    } else {
      final d = _metres(last, p);
      if (d < gateM) {
        if (expired) _changed();
        return;
      }
      final seconds = now.difference(last.at).inMilliseconds / 1000;
      if (seconds <= 0 || d / seconds > maxSpeed) {
        _restart(p);
      } else {
        _extend(p);
      }
    }
    _changed();
  }

  /// After a break: the open piece closes and [p] starts the next.
  void _restart(TrackPoint p) {
    _close();
    _open.add(p);
    _openMinute = _minuteFor(p);
    _live
      ..clear()
      ..add(p);
  }

  void _extend(TrackPoint p) {
    _live.add(p);
    while (_live.length > 2 && p.at.difference(_live[1].at) > movingFor) {
      _live.removeAt(0);
    }
    if (_open.isEmpty) {
      _open.add(p);
      _openMinute = _minuteFor(p);
      return;
    }
    final fits =
        _open.length < _maxOpenPoints &&
        pieceFits([
          for (final q in [..._open, p]) (lat: q.lat, lon: q.lon),
        ]);
    if (fits) {
      _open.add(p);
      return;
    }
    // The next piece starts where this one ends.
    final end = _open.last;
    _close();
    _open.addAll([end, p]);
    _openMinute = _minuteFor(end);
  }

  /// No two pieces share a minute.
  int _minuteFor(TrackPoint first) => max(
    TrackPiece.minuteOf(first.at),
    (_pieces.lastOrNull?.minute ?? -1) + 1,
  );

  void _close() {
    if (_open.length >= 2) {
      final points = [for (final p in _open) (lat: p.lat, lon: p.lon)];
      _kept[_openMinute] = points;
      _pieces.add(
        TrackPiece(
          minute: _openMinute,
          endMinute: max(_openMinute, TrackPiece.minuteOf(_open.last.at)),
          points: simplify(points, TrackPiece.epsilonM),
        ),
      );
      var count = _pieces.fold(0, (n, p) => n + p.points.length);
      while (count > _maxPoints && _pieces.length > 1) {
        count -= _pieces.removeAt(0).points.length;
      }
      _forgetKept();
    }
    _open.clear();
  }

  /// The kept points of pieces gone, and the oldest beyond
  /// [_maxKeptPoints].
  void _forgetKept() {
    final minutes = {for (final p in _pieces) p.minute};
    _kept.removeWhere((minute, _) => !minutes.contains(minute));
    var count = _kept.values.fold(0, (n, p) => n + p.length);
    for (final minute in _kept.keys.toList()..sort()) {
      if (count <= _maxKeptPoints) break;
      count -= _kept.remove(minute)!.length;
    }
  }

  /// Drops what ended more than [keepHours] ago; true when anything went.
  bool _expire() {
    final oldest = TrackPiece.minuteOf(_clock()) - _keepHours * 60;
    final before = _pieces.length;
    _pieces.removeWhere((p) => p.endMinute < oldest);
    var changed = _pieces.length != before;
    if (changed) _forgetKept();
    if (_open.isNotEmpty && TrackPiece.minuteOf(_open.last.at) < oldest) {
      _open.clear();
      changed = true;
    }
    return changed;
  }

  void _changed() {
    if (_recording) {
      _saveTimer ??= Timer(_saveEvery, () {
        _saveTimer = null;
        unawaited(_save());
      });
    }
    notifyListeners();
  }

  void _load() {
    final key = _connector.selfPublicKeyHex;
    if (key.isEmpty || key == _radioKey) return;
    _radioKey = key;
    _pieces.clear();
    _kept.clear();
    _open.clear();
    final raw = PrefsManager.instance.getString(keyFor(key));
    if (raw == null) return;
    try {
      // An older app kept the raw points: it starts over.
      final json = jsonDecode(raw);
      if (json is! Map) return;
      for (final p in json['pieces'] as List) {
        if (p case [final int minute, final int end, final List points]) {
          _pieces.add(
            TrackPiece(
              minute: minute,
              endMinute: end,
              points: [
                for (final q in points)
                  if (q case [final num lat, final num lon])
                    (lat: lat.toDouble(), lon: lon.toDouble()),
              ],
            ),
          );
        }
      }
      if (json['open'] case {
        'minute': final int minute,
        'points': final List points,
      }) {
        _openMinute = minute;
        for (final q in points) {
          if (q case [final num lat, final num lon, final int at]) {
            _open.add((
              lat: lat.toDouble(),
              lon: lon.toDouble(),
              at: DateTime.fromMillisecondsSinceEpoch(at),
            ));
          }
        }
      }
    } catch (_) {
      _pieces.clear();
      _open.clear();
    }
  }

  Future<void> _save() async {
    if (_radioKey.isEmpty) return;
    await PrefsManager.instance.setString(
      keyFor(_radioKey),
      jsonEncode({
        'pieces': [
          for (final p in _pieces)
            [
              p.minute,
              p.endMinute,
              [
                for (final q in p.points) [_round(q.lat), _round(q.lon)],
              ],
            ],
        ],
        if (_open.isNotEmpty)
          'open': {
            'minute': _openMinute,
            'points': [
              for (final q in _open)
                [_round(q.lat), _round(q.lon), q.at.millisecondsSinceEpoch],
            ],
          },
      }),
    );
  }

  static double _round(double v) => (v * 1e5).round() / 1e5;

  static double _bearing(TrackPoint a, TrackPoint b) {
    final dy = b.lat - a.lat;
    final dx = (b.lon - a.lon) * cos(a.lat * pi / 180);
    return (atan2(dx, dy) * 180 / pi + 360) % 360;
  }

  static double _metres(TrackPoint a, TrackPoint b) {
    const m = 111320.0;
    final dy = (a.lat - b.lat) * m;
    final dx = (a.lon - b.lon) * m * cos(a.lat * pi / 180);
    return sqrt(dx * dx + dy * dy);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
