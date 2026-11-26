import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import 'trax_track.dart';

/// Which way and how fast this radio is going, for a shared My location and
/// the map's speed card. From the GPS readings the app already takes (every
/// 60 s, every 10 s while a screen shows the position or TRAX is on, every
/// 3 s while the speed card shows), measured the way [TraxTrack] measures
/// TRAX's own way. Memory only: nothing is saved.
class SelfMotion {
  SelfMotion._();

  static SelfMotion instance = SelfMotion._();

  /// Readings further apart than this start again: three missed polls.
  static const gap = Duration(minutes: 3);

  /// Points older than this are dropped, the newest one never.
  static const keepFor = Duration(minutes: 5);

  /// [motionNow] measures over at least this long where it can, for a
  /// steadier speed: readings come in 11 m steps.
  static const smoothFor = Duration(seconds: 10);

  /// [motionNow] tells a stop no sooner than this.
  static const stillAfter = Duration(seconds: 10);

  static const _distance = Distance();

  MeshCoreConnector? _connector;
  DateTime Function() _clock = DateTime.now;
  final _points = <TrackPoint>[];
  DateTime? _liveAt;

  /// The first point after the last stop [motionNow] told: it measures
  /// from there, not across the stop.
  DateTime? _runFrom;

  void attach(MeshCoreConnector connector, {DateTime Function()? clock}) {
    _connector?.selfGps.removeListener(_onReading);
    _connector = connector;
    _clock = clock ?? DateTime.now;
    _points.clear();
    _liveAt = null;
    _runFrom = null;
    connector.selfGps.addListener(_onReading);
  }

  // The connector notes whether the reading changed after it sets it.
  void _onReading() => scheduleMicrotask(_keep);

  void _keep() {
    final c = _connector;
    final gps = c?.selfGps.value;
    if (c == null ||
        gps == null ||
        !c.selfGpsIsFresh ||
        !c.hasValidLocation(gps.latitude, gps.longitude)) {
      return;
    }
    final now = _clock();
    final p = (lat: gps.latitude, lon: gps.longitude, at: now);
    final live = _liveAt;
    _liveAt = now;
    final last = _points.lastOrNull;
    if (last == null || live == null || now.difference(live) > gap) {
      _points
        ..clear()
        ..add(p);
      _runFrom = null;
      return;
    }
    final d = _metres(last, p);
    if (d < TraxTrack.gateM) return;
    final seconds = now.difference(last.at).inMilliseconds / 1000;
    if (seconds <= 0 || d / seconds > TraxTrack.maxSpeed) {
      _points.clear();
      _runFrom = null;
    } else if (now.difference(last.at) > _stillAfter(_runMotion()?.speed)) {
      _runFrom = now;
    }
    _points.add(p);
    while (_points.length > 1 && now.difference(_points.first.at) > keepFor) {
      _points.removeAt(0);
    }
  }

  /// Moving: heading and speed. Still for 2 minutes: how long. Null
  /// without a recent reading, or before the radio has gone far enough to
  /// tell.
  TrackMotion? motion() {
    final live = _liveAt;
    final now = _clock();
    if (_points.isEmpty || live == null || now.difference(live) > gap) {
      return null;
    }
    final newest = _points.last;
    final since = now.difference(newest.at);
    if (since > TraxTrack.movingFor) {
      return (heading: null, speed: null, stillFor: since);
    }
    for (var i = _points.length - 2; i >= 0; i--) {
      final from = _points[i];
      if (newest.at.difference(from.at) > TraxTrack.movingFor) break;
      final d = _metres(from, newest);
      if (d < TraxTrack.motionM) continue;
      final seconds = newest.at.difference(from.at).inMilliseconds / 1000;
      return (
        heading: _bearing(from, newest),
        speed: d / seconds,
        stillFor: null,
      );
    }
    return null;
  }

  /// [motion] for a speed shown as it goes: measured over [smoothFor] where
  /// it can, never across a stop, and still sooner, once the radio has kept
  /// within [TraxTrack.gateM] three times as long as its speed takes to
  /// cross it, and at least [stillAfter].
  TrackMotion? motionNow() {
    final live = _liveAt;
    final now = _clock();
    if (_points.isEmpty || live == null || now.difference(live) > gap) {
      return null;
    }
    final since = now.difference(_points.last.at);
    final moving = _runMotion();
    if (since > _stillAfter(moving?.speed)) {
      return (heading: null, speed: null, stillFor: since);
    }
    return moving;
  }

  /// Heading and speed to the newest point since the last stop, over at
  /// least [TraxTrack.motionM] and, where there is one, [smoothFor].
  TrackMotion? _runMotion() {
    final newest = _points.last;
    final runFrom = _runFrom;
    TrackPoint? from;
    for (var i = _points.length - 2; i >= 0; i--) {
      final p = _points[i];
      final took = newest.at.difference(p.at);
      if ((runFrom != null && p.at.isBefore(runFrom)) ||
          took > TraxTrack.movingFor) {
        break;
      }
      if (_metres(p, newest) < TraxTrack.motionM) continue;
      from = p;
      if (took >= smoothFor) break;
    }
    if (from == null) return null;
    final seconds = newest.at.difference(from.at).inMilliseconds / 1000;
    return (
      heading: _bearing(from, newest),
      speed: _metres(from, newest) / seconds,
      stillFor: null,
    );
  }

  static Duration _stillAfter(double? speed) {
    if (speed == null || speed <= 0) return TraxTrack.movingFor;
    final after = Duration(
      milliseconds: (3 * TraxTrack.gateM / speed * 1000).round(),
    );
    if (after < stillAfter) return stillAfter;
    if (after > TraxTrack.movingFor) return TraxTrack.movingFor;
    return after;
  }

  static LatLng _at(TrackPoint p) => LatLng(p.lat, p.lon);

  static double _metres(TrackPoint a, TrackPoint b) =>
      _distance.as(LengthUnit.Meter, _at(a), _at(b));

  static double _bearing(TrackPoint a, TrackPoint b) =>
      (_distance.bearing(_at(a), _at(b)) + 360) % 360;
}
