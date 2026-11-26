import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import 'trax_track.dart';

/// Which way and how fast this radio is going, for a shared My location.
/// From the GPS readings the app already takes (every 60 s, every 10 s
/// while a screen shows the position or TRAX is on), measured the way
/// [TraxTrack] measures TRAX's own way. Memory only: nothing is saved.
class SelfMotion {
  SelfMotion._();

  static SelfMotion instance = SelfMotion._();

  /// Readings further apart than this start again: three missed polls.
  static const gap = Duration(minutes: 3);

  /// Points older than this are dropped, the newest one never.
  static const keepFor = Duration(minutes: 5);

  static const _distance = Distance();

  MeshCoreConnector? _connector;
  DateTime Function() _clock = DateTime.now;
  final _points = <TrackPoint>[];
  DateTime? _liveAt;

  void attach(MeshCoreConnector connector, {DateTime Function()? clock}) {
    _connector?.selfGps.removeListener(_onReading);
    _connector = connector;
    _clock = clock ?? DateTime.now;
    _points.clear();
    _liveAt = null;
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
      return;
    }
    final d = _metres(last, p);
    if (d < TraxTrack.gateM) return;
    final seconds = now.difference(last.at).inMilliseconds / 1000;
    if (seconds <= 0 || d / seconds > TraxTrack.maxSpeed) _points.clear();
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

  static LatLng _at(TrackPoint p) => LatLng(p.lat, p.lon);

  static double _metres(TrackPoint a, TrackPoint b) =>
      _distance.as(LengthUnit.Meter, _at(a), _at(b));

  static double _bearing(TrackPoint a, TrackPoint b) =>
      (_distance.bearing(_at(a), _at(b)) + 360) % 360;
}
