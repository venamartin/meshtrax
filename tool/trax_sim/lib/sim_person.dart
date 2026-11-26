import 'dart:math';
import 'dart:typed_data';

import 'package:traxshare/traxshare.dart';

import 'movers.dart';

/// What a pretend member's report carried of their track.
enum SimCarry { none, trail, older, asked }

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
       _start = start,
       _rounds = PieceRounds(random),
       _session = random.nextInt(0x10000),
       battery = 90 + random.nextInt(11),
       _nextAt = start.add(Duration(seconds: 10 + random.nextInt(21)));

  final String name;

  /// The first 4 bytes of the key the reports claim.
  final Uint8List prefix;
  final Mover mover;
  final Random _random;
  final DateTime _start;
  final PieceRounds _rounds;
  final int _session;
  int battery;
  int _seq = 0;
  DateTime _nextAt;
  DateTime? _nameSentAt;
  DateTime? _trailSentAt;
  int _sinceTrail = 0;
  bool _olderSent = false;
  bool _trailAsked = false;
  double? _lastHeading;
  double? _lastSpeed;

  /// What the latest report from [due] carried.
  SimCarry carried = SimCarry.none;

  /// The minutes of its track's pieces, newest first.
  List<int> get pieceMinutes => [for (final p in _newestFirst) p.minute];

  /// Closed, oldest first, thinned as the app keeps them.
  final _pieces = <TrackPiece>[];

  /// The open piece: a point every 25 m, oldest first.
  final _open = <({TrailPoint p, DateTime at})>[];
  int _openMinute = 0;

  /// The pieces asked for, newest first.
  final _answer = <int>[];

  /// The pieces the latest trail carried at their finest.
  var _trailFine = <int>{};

  static const _gateM = 25.0;
  static const _movingFor = 120;
  static const _nameEvery = Duration(minutes: 30);
  static const _trailEvery = 5;
  static const _trailAfter = Duration(minutes: 10);
  static const _answerSpacing = Duration(seconds: 3);
  static const _maxOpenPoints = 500;
  static const keepHours = MemberTrack.defaultKeepHours;

  /// Where the radio would say they are: 0.0001° steps.
  TrailPoint get position => (
    lat: (mover.lat * 1e4).round() / 1e4,
    lon: (mover.lon * 1e4).round() / 1e4,
  );

  /// One second on, [seconds] after the start.
  void step(int seconds) {
    mover.step();
    if (mover.speed > 0) {
      _lastHeading = mover.heading;
      _lastSpeed = mover.speed;
    }
    _keep(position, _start.add(Duration(seconds: seconds)));
    if (seconds % 360 == 0 && battery > 5) battery--;
  }

  /// A member's MeshTrax asked for this one's track at [now]: the trail
  /// soon, then each piece they lack.
  void ask(TraxAsk ask, DateTime now) {
    final held = {for (final m in ask.have) m & 0xFFFF};
    for (final p in _newestFirst) {
      if (!held.contains(p.minute & 0xFFFF) && !_answer.contains(p.minute)) {
        _answer.add(p.minute);
      }
    }
    _answer.sort((a, b) => b.compareTo(a));
    _trailAsked = true;
    _nextAt = now.add(Duration(milliseconds: 500 + _random.nextInt(2000)));
  }

  /// The report due at [now], if one is, with the next one set [interval]
  /// on, ±20 %, or sooner while answering an ask.
  TraxReport? due(DateTime now, Duration interval) {
    if (now.isBefore(_nextAt)) return null;
    final oldest = TrackPiece.minuteOf(now) - keepHours * 60;
    _pieces.removeWhere((p) => p.endMinute < oldest);
    final here = position;
    final trailDue =
        _trailAsked ||
        _trailSentAt == null ||
        (_sinceTrail + 1 >= _trailEvery &&
            now.difference(_trailSentAt!) >= _trailAfter);
    final answering = !trailDue && _answer.isNotEmpty;
    final olderDue =
        !trailDue &&
        !answering &&
        !_olderSent &&
        _sinceTrail + 1 >= (_trailEvery + 1) ~/ 2 &&
        now.difference(_trailSentAt!) >= _trailAfter ~/ 2;
    final nameDue =
        !answering &&
        !olderDue &&
        (_nameSentAt == null || now.difference(_nameSentAt!) >= _nameEvery);
    final sendName = nameDue ? name : null;
    final anchor = wirePosition(here.lat, here.lon);
    final room = TraxReport.trackRoom(name: sendName);
    final TrackBlock? block;
    if (trailDue) {
      block = fitTrack(anchor, _newestFirst, room, keepHours: keepHours);
      _trailFine = {
        if (block != null && block.gridM == TrackPiece.fineGridM)
          for (final p in block.pieces) p.minute,
      };
    } else if (answering) {
      block = _piece(_answer.removeAt(0), anchor, room);
    } else if (olderDue) {
      final minute = _rounds.next([
        for (final p in _newestFirst)
          if (!_trailFine.contains(p.minute)) p.minute,
      ]);
      block = minute == null ? null : _piece(minute, anchor, room);
    } else {
      block = null;
    }
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
      icon: mover is Driver ? TraxMapIcon.vehicle : TraxMapIcon.hike,
      name: sendName,
      track: block,
    );
    _seq = (_seq + 1) & 0xFF;
    if (nameDue) _nameSentAt = now;
    carried = block == null
        ? SimCarry.none
        : trailDue
        ? SimCarry.trail
        : answering
        ? SimCarry.asked
        : SimCarry.older;
    // An answer to an ask isn't one of the schedule's reports.
    if (trailDue && block != null) {
      _trailAsked = false;
      _trailSentAt = now;
      _sinceTrail = 0;
      _olderSent = false;
      if (block.gridM == TrackPiece.fineGridM) {
        final sent = {for (final p in block.pieces) p.minute};
        _answer.removeWhere(sent.contains);
      }
    } else if (!answering) {
      _trailAsked = false;
      _sinceTrail++;
      if (olderDue) _olderSent = true;
    }
    final tenth = interval ~/ 10;
    final jitter = 0.8 + 0.4 * _random.nextDouble();
    _nextAt = now.add(
      _trailAsked || _answer.isNotEmpty
          ? (tenth > _answerSpacing ? tenth : _answerSpacing)
          : Duration(milliseconds: (interval.inMilliseconds * jitter).round()),
    );
    return report;
  }

  TrackBlock? _piece(int minute, TrailPoint anchor, int room) {
    final p = _newestFirst.where((p) => p.minute == minute).firstOrNull;
    return p == null ? null : fitTrack(anchor, [p], room, keepHours: keepHours);
  }

  /// A point every 25 m; a piece closes once its points don't fit one
  /// report, and the next starts where it ended.
  void _keep(TrailPoint here, DateTime at) {
    if (_open.isEmpty) {
      _open.add((p: here, at: at));
      _openMinute = _minuteFor(at);
      return;
    }
    if (_metres(_open.last.p, here) < _gateM) return;
    if (_open.length < _maxOpenPoints &&
        pieceFits([for (final q in _open) q.p, here])) {
      _open.add((p: here, at: at));
      return;
    }
    final end = _open.last;
    _pieces.add(_pieceOf(_open, thin: true));
    _open
      ..clear()
      ..addAll([end, (p: here, at: at)]);
    _openMinute = _minuteFor(end.at);
  }

  int _minuteFor(DateTime at) =>
      max(TrackPiece.minuteOf(at), (_pieces.lastOrNull?.minute ?? -1) + 1);

  TrackPiece _pieceOf(
    List<({TrailPoint p, DateTime at})> points, {
    bool thin = false,
  }) {
    final line = [for (final q in points) q.p];
    return TrackPiece(
      minute: _openMinute,
      endMinute: max(_openMinute, TrackPiece.minuteOf(points.last.at)),
      points: thin ? simplify(line, TrackPiece.epsilonM) : line,
    );
  }

  List<TrackPiece> get _newestFirst => [
    if (_open.length >= 2) _pieceOf(_open),
    ..._pieces.reversed,
  ];

  static double _metres(TrailPoint a, TrailPoint b) {
    final dy = (a.lat - b.lat) * metresPerDegree;
    final dx = (a.lon - b.lon) * metresPerDegree * cos(a.lat * pi / 180);
    return sqrt(dx * dx + dy * dy);
  }
}
