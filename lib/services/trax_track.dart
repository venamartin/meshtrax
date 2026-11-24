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

/// This radio's own way while TRAX mode is on: the trail its reports carry
/// and the line behind its dot. The radio is read every 10 s and a point is
/// kept every 25 m, never before its reading changes. A line breaks where
/// live readings stopped for 2 minutes or the position jumped, and nothing
/// is drawn or sent across a break.
class TraxTrack extends ChangeNotifier {
  TraxTrack(this._connector, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MeshCoreConnector _connector;
  final DateTime Function() _clock;

  static const gateM = 25.0;
  static const gap = Duration(minutes: 2);

  /// Faster than this is a jump, not a drive.
  static const maxSpeed = 60.0;

  /// 10 miles: the trail a report carries, and the line behind the dot.
  static const windowM = 16093.44;

  /// Moving while a point was kept this recently.
  static const movingFor = Duration(minutes: 2);

  /// Heading and speed are measured over at least this far: the radio's
  /// positions come in steps of about 11 m.
  static const motionM = 50.0;

  static const _maxPoints = 3000;
  static const _saveEvery = Duration(minutes: 1);

  static String keyFor(String radioKey) => 'trax_track_$radioKey';

  /// Oldest first, each oldest point first.
  final _segments = <List<TrackPoint>>[];
  String _radioKey = '';
  bool _recording = false;
  DateTime? _liveAt;
  Timer? _saveTimer;

  bool get recording => _recording;

  /// Starts reading the radio every 10 s and keeping points.
  void start() {
    if (_recording) return;
    _recording = true;
    _load();
    // A new start is a break: the time between wasn't recorded.
    _liveAt = null;
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

  /// The way back from the newest point, newest first, up to [windowM]
  /// along it; empty when live readings stopped since.
  List<TrailPoint> trail() {
    final live = _liveAt;
    if (_segments.isEmpty || live == null || _clock().difference(live) > gap) {
      return const [];
    }
    final out = <TrailPoint>[];
    var walked = 0.0;
    final segment = _segments.last;
    for (var i = segment.length - 1; i >= 0; i--) {
      final p = (lat: segment[i].lat, lon: segment[i].lon);
      if (out.isNotEmpty) walked += _metres(out.last, p);
      if (walked > windowM) break;
      out.add(p);
    }
    return out;
  }

  /// [trail] without the points next to where the radio is now: they add
  /// nothing to the report's own position.
  List<TrailPoint> trailFrom(double lat, double lon) {
    final here = (lat: lat, lon: lon);
    return trail().skipWhile((p) => _metres(here, p) < gateM).toList();
  }

  /// How the radio is moving, from the points kept; null without a live
  /// reading.
  TrackMotion? motion() {
    final live = _liveAt;
    final now = _clock();
    if (_segments.isEmpty || live == null || now.difference(live) > gap) {
      return null;
    }
    final segment = _segments.last;
    final newest = segment.last;
    final since = now.difference(newest.at);
    if (since > movingFor) return (heading: null, speed: null, stillFor: since);
    final to = (lat: newest.lat, lon: newest.lon);
    TrailPoint? from;
    var seconds = 0.0;
    for (var i = segment.length - 2; i >= 0; i--) {
      final p = segment[i];
      if (from != null && newest.at.difference(p.at) > movingFor) break;
      from = (lat: p.lat, lon: p.lon);
      seconds = newest.at.difference(p.at).inMilliseconds / 1000;
      if (_metres(from, to) >= motionM) break;
    }
    if (from == null || seconds <= 0) {
      return (heading: null, speed: null, stillFor: null);
    }
    return (
      heading: _bearing(from, to),
      speed: _metres(from, to) / seconds,
      stillFor: null,
    );
  }

  /// The lines to draw behind the dot: [windowM] back along the way, each
  /// oldest first.
  List<List<TrailPoint>> get recent {
    final out = <List<TrailPoint>>[];
    var walked = 0.0;
    for (var s = _segments.length - 1; s >= 0 && walked <= windowM; s--) {
      final line = <TrailPoint>[];
      final segment = _segments[s];
      for (var i = segment.length - 1; i >= 0; i--) {
        final p = (lat: segment[i].lat, lon: segment[i].lon);
        if (line.isNotEmpty) walked += _metres(line.last, p);
        if (walked > windowM) break;
        line.add(p);
      }
      if (line.length >= 2) out.add(line.reversed.toList());
    }
    return out.reversed.toList();
  }

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
    final now = _clock();
    final p = (lat: gps.latitude, lon: gps.longitude, at: now);
    final live = _liveAt;
    _liveAt = now;
    final last = _segments.lastOrNull?.lastOrNull;
    if (last == null || live == null || now.difference(live) > gap) {
      _segments.add([p]);
    } else {
      final d = _metres(
        (lat: last.lat, lon: last.lon),
        (lat: p.lat, lon: p.lon),
      );
      if (d < gateM) return;
      final seconds = now.difference(last.at).inMilliseconds / 1000;
      if (seconds <= 0 || d / seconds > maxSpeed) {
        _segments.add([p]);
      } else {
        _segments.last.add(p);
      }
    }
    _trim();
    _saveTimer ??= Timer(_saveEvery, () {
      _saveTimer = null;
      unawaited(_save());
    });
    notifyListeners();
  }

  void _trim() {
    var count = _segments.fold(0, (n, s) => n + s.length);
    while (count > _maxPoints && _segments.isNotEmpty) {
      final first = _segments.first;
      first.removeAt(0);
      count--;
      if (first.isEmpty) _segments.removeAt(0);
    }
  }

  void _load() {
    final key = _connector.selfPublicKeyHex;
    if (key.isEmpty || key == _radioKey) return;
    _radioKey = key;
    _segments.clear();
    final raw = PrefsManager.instance.getString(keyFor(key));
    if (raw == null) return;
    try {
      for (final s in jsonDecode(raw) as List) {
        final segment = <TrackPoint>[
          for (final p in s as List)
            if (p case [final num lat, final num lon, final int at])
              (
                lat: lat.toDouble(),
                lon: lon.toDouble(),
                at: DateTime.fromMillisecondsSinceEpoch(at),
              ),
        ];
        if (segment.isNotEmpty) _segments.add(segment);
      }
    } catch (_) {
      _segments.clear();
    }
  }

  Future<void> _save() async {
    if (_radioKey.isEmpty) return;
    await PrefsManager.instance.setString(
      keyFor(_radioKey),
      jsonEncode([
        for (final s in _segments)
          [
            for (final p in s)
              [_round(p.lat), _round(p.lon), p.at.millisecondsSinceEpoch],
          ],
      ]),
    );
  }

  static double _round(double v) => (v * 1e5).round() / 1e5;

  static double _bearing(TrailPoint a, TrailPoint b) {
    final dy = b.lat - a.lat;
    final dx = (b.lon - a.lon) * cos(a.lat * pi / 180);
    return (atan2(dx, dy) * 180 / pi + 360) % 360;
  }

  static double _metres(TrailPoint a, TrailPoint b) {
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
