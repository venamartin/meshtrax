import 'dart:math';

const metresPerDegree = 111320.0;

/// A pretend person's way, one second at a time.
abstract class Mover {
  Mover(this.lat, this.lon, this.altitude);

  double lat;
  double lon;
  double altitude;

  /// Degrees clockwise from north.
  double heading = 0;

  /// Metres a second; 0 while stopped.
  double speed = 0;

  /// Seconds since they stopped; 0 while moving.
  int stillSeconds = 0;

  void step();

  void _go(double metres) {
    final r = heading * pi / 180;
    lat += metres * cos(r) / metresPerDegree;
    lon += metres * sin(r) / (metresPerDegree * cos(lat * pi / 180));
  }

  void _stop() {
    speed = 0;
    stillSeconds++;
  }
}

double _wrap(double degrees) => (degrees % 360 + 360) % 360;

/// The signed turn from [from] to [to], -180 to 180.
double _turn(double from, double to) => (to - from + 540) % 360 - 180;

/// Walking a winding trail at about 1.4 m/s, resting for a few minutes now
/// and then.
class Walker extends Mover {
  Walker(super.lat, super.lon, super.altitude, this._random) {
    _way = _random.nextDouble() * 360;
    heading = _way;
    _left = _walkFor();
    _bendIn = _bendAfter();
  }

  final Random _random;
  late double _way;
  double _turnRate = 0;
  double _climb = 0;
  bool _resting = false;
  late int _left;
  late int _bendIn;

  int _walkFor() => 360 + _random.nextInt(360);
  int _bendAfter() => 60 + _random.nextInt(120);

  @override
  void step() {
    if (--_left <= 0) {
      _resting = !_resting;
      _left = _resting ? 60 + _random.nextInt(180) : _walkFor();
    }
    if (_resting) return _stop();
    stillSeconds = 0;
    // The trail winds: another way every 1 to 3 minutes.
    if (--_bendIn <= 0) {
      _bendIn = _bendAfter();
      _way = _wrap(_way + _random.nextDouble() * 90 - 45);
    }
    _turnRate =
        _turnRate * 0.9 +
        (_random.nextDouble() - 0.5) * 1.6 +
        _turn(heading, _way) * 0.01;
    heading = _wrap(heading + _turnRate.clamp(-6.0, 6.0));
    speed = 1.3 + _random.nextDouble() * 0.2;
    _climb = (_climb * 0.98 + (_random.nextDouble() - 0.5) * 0.02).clamp(
      -0.3,
      0.3,
    );
    altitude += _climb;
    _go(speed);
  }
}

/// Driving a road at 45 to 60 mph: straights, bends taken slower, and a
/// stop at a junction now and then.
class Driver extends Mover {
  Driver(super.lat, super.lon, super.altitude, this._random) {
    heading = _random.nextDouble() * 360;
    _cruise = _newCruise();
    _left = 30 + _random.nextInt(90);
    _toStop = _stopAfter();
  }

  final Random _random;
  late double _cruise;
  double _bend = 0;
  late int _left;
  late int _toStop;
  int _stopped = 0;
  int _side = 1;

  double _newCruise() => 20 + _random.nextDouble() * 7;
  int _stopAfter() => 360 + _random.nextInt(540);

  @override
  void step() {
    if (_stopped > 0) {
      _stopped--;
      return _stop();
    }
    if (--_toStop <= 0 && speed < 1) {
      _toStop = _stopAfter();
      _stopped = 20 + _random.nextInt(70);
      return _stop();
    }
    stillSeconds = 0;
    if (--_left <= 0) {
      if (_bend == 0) {
        _side = -_side;
        _bend = _side * (1.5 + _random.nextDouble() * 2.5);
        _left = 8 + _random.nextInt(18);
      } else {
        _bend = 0;
        _cruise = _newCruise();
        _left = 30 + _random.nextInt(90);
      }
    }
    // Slowing for a junction stop, or for a bend.
    final target = _toStop <= 0
        ? 0.0
        : _bend != 0
        ? 12 + _random.nextDouble() * 4
        : _cruise;
    speed = speed < target ? min(target, speed + 2.5) : max(target, speed - 3);
    heading = _wrap(heading + _bend);
    altitude += (_random.nextDouble() - 0.5) * 0.4;
    _go(speed);
  }
}

/// Following a track's points at [pace] m/s, then staying at its end.
class TrackFollower extends Mover {
  TrackFollower(this._points, this.pace)
    : super(_points.first.lat, _points.first.lon, _points.first.ele ?? 0);

  final List<({double lat, double lon, double? ele})> _points;
  final double pace;
  int _next = 1;

  @override
  void step() {
    var left = pace;
    while (left > 0 && _next < _points.length) {
      final p = _points[_next];
      final dy = (p.lat - lat) * metresPerDegree;
      final dx = (p.lon - lon) * metresPerDegree * cos(lat * pi / 180);
      final d = sqrt(dx * dx + dy * dy);
      if (d > 0) heading = _wrap(atan2(dx, dy) * 180 / pi);
      if (d <= left) {
        lat = p.lat;
        lon = p.lon;
        if (p.ele != null) altitude = p.ele!;
        left -= d;
        _next++;
      } else {
        _go(left);
        left = 0;
      }
    }
    if (left == pace) return _stop();
    stillSeconds = 0;
    speed = pace - left;
  }
}

/// The track points of a GPX file, in order.
List<({double lat, double lon, double? ele})> gpxPoints(String gpx) {
  final point = RegExp(
    r'<(?:trkpt|rtept)\b([^>]*?)(/>|>(.*?)</(?:trkpt|rtept)>)',
    dotAll: true,
  );
  double? attribute(String attrs, String name) => double.tryParse(
    RegExp('$name\\s*=\\s*["\']([^"\']+)["\']').firstMatch(attrs)?[1] ?? '',
  );
  return [
    for (final m in point.allMatches(gpx))
      if ((attribute(m[1]!, 'lat'), attribute(m[1]!, 'lon')) case (
        final lat?,
        final lon?,
      ))
        (
          lat: lat,
          lon: lon,
          ele: double.tryParse(
            RegExp(r'<ele>\s*([^<]+?)\s*</ele>').firstMatch(m[3] ?? '')?[1] ??
                '',
          ),
        ),
  ];
}
