import 'dart:math';
import 'dart:typed_data';

import 'package:traxshare/traxshare.dart';

import 'movers.dart';

/// One pretend trip member: their way, and the reports MeshTrax would send
/// for them in TRAX mode, by the app's rules.
class SimPerson {
  SimPerson({
    required this.name,
    required this.prefix,
    required this.mover,
    required DateTime start,
    required Random random,
  }) : _random = random,
       _session = random.nextInt(0x10000),
       battery = 90 + random.nextInt(11),
       _nextAt = start.add(Duration(seconds: 10 + random.nextInt(21)));

  final String name;

  /// The first 4 bytes of the key the reports claim.
  final Uint8List prefix;
  final Mover mover;
  final Random _random;
  final int _session;
  int battery;
  int _seq = 0;
  DateTime _nextAt;
  DateTime? _nameSentAt;
  DateTime? _trailSentAt;
  int _sinceTrail = 0;
  double? _lastHeading;
  double? _lastSpeed;

  /// Newest last: a point every 25 m, as the app keeps them.
  final _kept = <TrailPoint>[];

  static const _gateM = 25.0;
  static const _windowM = 16093.44;
  static const _movingFor = 120;
  static const _nameEvery = Duration(minutes: 30);
  static const _trailEvery = 5;
  static const _trailAfter = Duration(minutes: 10);

  /// Where the radio would say they are: 0.0001° steps.
  TrailPoint get position => (
    lat: (mover.lat * 1e4).round() / 1e4,
    lon: (mover.lon * 1e4).round() / 1e4,
  );

  /// One second on.
  void step(int seconds) {
    mover.step();
    if (mover.speed > 0) {
      _lastHeading = mover.heading;
      _lastSpeed = mover.speed;
    }
    final here = position;
    if (_kept.isEmpty || _metres(_kept.last, here) >= _gateM) {
      _kept.add(here);
      if (_kept.length > 3000) _kept.removeAt(0);
    }
    if (seconds % 360 == 0 && battery > 5) battery--;
  }

  /// The report due at [now], if one is, with the next one set [interval]
  /// on, ±20 %.
  TraxReport? due(DateTime now, Duration interval) {
    if (now.isBefore(_nextAt)) return null;
    final jitter = 0.8 + 0.4 * _random.nextDouble();
    _nextAt = now.add(
      Duration(milliseconds: (interval.inMilliseconds * jitter).round()),
    );
    final here = position;
    final nameDue =
        _nameSentAt == null || now.difference(_nameSentAt!) >= _nameEvery;
    final sendName = nameDue ? name : null;
    final trailDue =
        _trailSentAt == null ||
        (_sinceTrail + 1 >= _trailEvery &&
            now.difference(_trailSentAt!) >= _trailAfter);
    final trail = trailDue
        ? fitTrail(
            wirePosition(here.lat, here.lon),
            _trailBack(here),
            TraxReport.trailRoom(name: sendName),
          )
        : null;
    // Moving for 2 minutes after the last move, as the app counts it.
    final still = mover.stillSeconds >= _movingFor;
    final report = TraxReport(
      seq: _seq,
      senderPrefix: prefix,
      session: _session,
      sentAt: now,
      lat: here.lat,
      lon: here.lon,
      altitude: mover.altitude.round(),
      heading: still ? null : _lastHeading,
      speed: still ? null : _lastSpeed,
      stillFor: still ? Duration(seconds: mover.stillSeconds) : null,
      fixAge: Duration(seconds: _random.nextInt(10)),
      battery: battery,
      requester: true,
      name: sendName,
      trail: trail,
    );
    _seq = (_seq + 1) & 0xFF;
    if (nameDue) _nameSentAt = now;
    if (trail != null) {
      _trailSentAt = now;
      _sinceTrail = 0;
    } else {
      _sinceTrail++;
    }
    return report;
  }

  /// The kept points back from [here], newest first, 10 miles of them,
  /// without the ones next to [here].
  List<TrailPoint> _trailBack(TrailPoint here) {
    final out = <TrailPoint>[];
    var walked = 0.0;
    for (var i = _kept.length - 1; i >= 0; i--) {
      final p = _kept[i];
      if (out.isNotEmpty) walked += _metres(out.last, p);
      if (walked > _windowM) break;
      out.add(p);
    }
    return out.skipWhile((p) => _metres(here, p) < _gateM).toList();
  }

  static double _metres(TrailPoint a, TrailPoint b) {
    final dy = (a.lat - b.lat) * metresPerDegree;
    final dx = (a.lon - b.lon) * metresPerDegree * cos(a.lat * pi / 180);
    return sqrt(dx * dx + dy * dy);
  }
}
