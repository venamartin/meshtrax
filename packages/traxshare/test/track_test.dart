import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxshare/traxshare.dart';

const _start = (lat: 36.4570, lon: -116.8660);
const _mPerDegree = 111320.0;

/// [n] points, oldest first, from [from] every [stepM] metres on [heading]
/// degrees, wiggling [wiggleM] either side.
List<TrailPoint> _walk(
  TrailPoint from,
  int n, {
  double stepM = 25,
  double heading = 20,
  double wiggleM = 0,
}) {
  final cosLat = cos(from.lat * pi / 180);
  final h = heading * pi / 180;
  return [
    for (var i = 0; i < n; i++)
      (
        lat:
            from.lat +
            (i * stepM * cos(h) + (i.isEven ? wiggleM : -wiggleM) * sin(h)) /
                _mPerDegree,
        lon:
            from.lon +
            (i * stepM * sin(h) - (i.isEven ? wiggleM : -wiggleM) * cos(h)) /
                (_mPerDegree * cosLat),
      ),
  ];
}

final _sent = DateTime.utc(2026, 11, 26, 15);
final _now = TrackPiece.minuteOf(_sent);

/// A walk cut into pieces the way a phone cuts its own track, oldest first.
List<TrackPiece> _cut(List<TrailPoint> walk, {int minutesEach = 20}) {
  final pieces = <TrackPiece>[];
  var open = <TrailPoint>[walk.first];
  for (final p in walk.skip(1)) {
    if (pieceFits([...open, p])) {
      open.add(p);
      continue;
    }
    pieces.add(
      TrackPiece(
        minute: _now - 600 + pieces.length * minutesEach,
        endMinute: _now - 600 + (pieces.length + 1) * minutesEach,
        points: open,
      ),
    );
    open = [open.last, p];
  }
  pieces.add(
    TrackPiece(
      minute: _now - 600 + pieces.length * minutesEach,
      endMinute: _now,
      points: open,
    ),
  );
  return pieces;
}

TraxReport _report({TrackBlock? track, String? name, TrailPoint? at}) =>
    TraxReport(
      seq: 1,
      senderPrefix: Uint8List.fromList([1, 2, 3, 4]),
      session: 9,
      sentAt: _sent,
      lat: (at ?? _start).lat,
      lon: (at ?? _start).lon,
      name: name,
      track: track,
    );

void main() {
  group('pieces', () {
    test('a piece takes points while they fit 108 bytes at 15 m', () {
      final walk = _walk(_start, 400, wiggleM: 30);
      expect(pieceFits(walk.take(20).toList()), isTrue);
      expect(pieceFits(walk), isFalse);
      final pieces = _cut(walk);
      expect(pieces.length, greaterThan(2));
      for (var i = 1; i < pieces.length; i++) {
        expect(
          pieces[i].points.first,
          pieces[i - 1].points.last,
          reason: 'a piece starts where the one before ends',
        );
      }
    });

    test('alone in a report, the fullest piece fits, whatever the step from '
        'the report', () {
      final pieces = _cut(_walk(_start, 2000, wiggleM: 30));
      final far = (lat: _start.lat + 9, lon: _start.lon + 9);
      for (final p in pieces.take(pieces.length - 1)) {
        final block = TrackBlock(
          gridM: TrackPiece.fineGridM,
          keepHours: 48,
          pieces: [
            TrackPiece(
              minute: p.minute,
              endMinute: p.endMinute,
              points: simplify(p.points, TrackPiece.epsilonM),
            ),
          ],
        );
        expect(
          _report(track: block, at: far).encode().length,
          lessThanOrEqualTo(TraxReport.maxSize),
        );
      }
    });
  });

  group('the block', () {
    test('pieces read back: minutes, spans, hours kept and points to within '
        'half a grid step', () {
      final pieces = _cut(_walk(_start, 120, wiggleM: 20)).reversed.toList();
      final block = TrackBlock(gridM: 8, keepHours: 48, pieces: pieces);
      final back = TraxReport.decode(_report(track: block).encode())!.track!;
      expect(back.keepHours, 48);
      expect(back.gridM, 8);
      expect(back.pieces.length, pieces.length);
      for (var i = 0; i < pieces.length; i++) {
        expect(back.pieces[i].minute, pieces[i].minute);
        expect(back.pieces[i].endMinute, pieces[i].endMinute);
        expect(back.pieces[i].gridM, 8);
        expect(back.pieces[i].points.length, pieces[i].points.length);
        for (var j = 0; j < pieces[i].points.length; j++) {
          expect(
            metresBetween(back.pieces[i].points[j], pieces[i].points[j]),
            lessThan(6),
          );
        }
      }
    });

    test('a minute is found across the 16-bit wrap, a week back and up to '
        'two ahead', () {
      // A sending minute just past a multiple of 65536.
      final sent = DateTime.fromMillisecondsSinceEpoch(
        (65536 * 450 + 30) * 60000,
        isUtc: true,
      );
      final minute = TrackPiece.minuteOf(sent);
      // Two pieces begun in one minute are named a minute apart.
      for (final back in [-2, -1, 0, 5, 60, 10080]) {
        final block = TrackBlock(
          gridM: 8,
          keepHours: 168,
          pieces: [
            TrackPiece(
              minute: minute - back,
              endMinute: minute - back + 3,
              points: _walk(_start, 3),
            ),
          ],
        );
        final read = TrackBlock.decode(
          wirePosition(_start.lat, _start.lon),
          sent,
          block.encode(wirePosition(_start.lat, _start.lon)),
          0,
        )!;
        expect(read.block.pieces.single.minute, minute - back);
        expect(read.block.pieces.single.endMinute, minute - back + 3);
      }
    });

    test('a truncated or broken block drops the report', () {
      final block = TrackBlock(
        gridM: 8,
        keepHours: 48,
        pieces: _cut(_walk(_start, 30, wiggleM: 20)).reversed.toList(),
      );
      final bytes = _report(track: block).encode();
      expect(TraxReport.decode(bytes.sublist(0, bytes.length - 2)), isNull);
      for (final (at, value) in [(29, 0), (30, 0), (31, 0), (36, 0)]) {
        final broken = Uint8List.fromList(bytes)..[at] = value;
        expect(TraxReport.decode(broken), isNull, reason: 'byte $at');
      }
      final tooMany = Uint8List.fromList(bytes)..[36] = 250;
      expect(TraxReport.decode(tooMany), isNull);
    });
  });

  group('the trail', () {
    test('the open piece and the closed ones behind it, whole, within 10 '
        'miles, in the room beside a name', () {
      final pieces = _cut(_walk(_start, 1600, wiggleM: 30)).reversed.toList();
      final here = wirePosition(
        pieces.first.points.last.lat,
        pieces.first.points.last.lon,
      );
      final room = TraxReport.trackRoom(name: 'Trail Radio');
      final fit = fitTrack(here, pieces, room, keepHours: 48)!;
      expect(fit.encode(here).length, lessThanOrEqualTo(room));
      expect(fit.pieces.first.minute, pieces.first.minute, reason: 'open');
      expect(fit.pieces.length, greaterThan(1));
      var walked = 0.0;
      for (var i = 0; i < fit.pieces.length; i++) {
        final whole = pieces[i];
        expect(fit.pieces[i].minute, whole.minute);
        expect(fit.pieces[i].points.first, whole.points.first, reason: 'ends');
        expect(fit.pieces[i].points.last, whole.points.last, reason: 'ends');
        if (i < fit.pieces.length - 1) walked += pathMetres(whole.points);
      }
      expect(walked, lessThan(16093.44));
      final report = _report(track: fit, name: 'Trail Radio', at: here);
      expect(report.encode().length, lessThanOrEqualTo(TraxReport.maxSize));
      expect(TraxReport.decode(report.encode())!.name, 'Trail Radio');
    });

    test('a short track goes at its finest', () {
      final pieces = _cut(_walk(_start, 15, wiggleM: 30)).reversed.toList();
      final fit = fitTrack(
        _start,
        pieces,
        TraxReport.trackRoom(),
        keepHours: 48,
      )!;
      expect(fit.gridM, 8);
      expect(fit.pieces.single.points.length, 15);
    });

    test('no room, no track', () {
      final pieces = _cut(_walk(_start, 5)).reversed.toList();
      expect(fitTrack(_start, pieces, 0, keepHours: 48), isNull);
      expect(fitTrack(_start, const [], 140, keepHours: 48), isNull);
    });
  });

  test('pieces drawn: one line on into the next where it starts where '
      'that ended, within their grids', () {
    final walk = _walk(_start, 40, wiggleM: 20);
    TrailPoint east(TrailPoint p, double m) =>
        (lat: p.lat, lon: p.lon + m / (_mPerDegree * cos(p.lat * pi / 180)));
    TrackPiece piece(int minute, List<TrailPoint> points, {int grid = 0}) =>
        TrackPiece(
          minute: minute,
          endMinute: minute + 5,
          points: points,
          gridM: grid,
        );
    final own = trackLines([
      piece(0, walk.sublist(0, 15)),
      piece(5, walk.sublist(14, 30)),
      piece(10, walk.sublist(30)),
    ]);
    expect([for (final l in own) l.length], [30, 10], reason: 'a gap');

    final heard = trackLines([
      piece(0, walk.sublist(0, 15), grid: 8),
      piece(5, [east(walk[14], 12), ...walk.sublist(15, 30)], grid: 8),
      piece(10, [east(walk[29], 30), ...walk.sublist(30)], grid: 8),
    ]);
    expect([for (final l in heard) l.length], [30, 11], reason: '12 m, 30 m');
  });

  test('older pieces go in rounds: each once a round, in a new order, a new '
      'piece from the next round, a gone one never', () {
    final rounds = PieceRounds(Random(3));
    final minutes = [for (var i = 0; i < 8; i++) 1000 + i];
    final first = [for (var i = 0; i < 8; i++) rounds.next(minutes)!];
    final second = [for (var i = 0; i < 8; i++) rounds.next(minutes)!];
    expect(first.toSet(), minutes.toSet());
    expect(second.toSet(), minutes.toSet());
    expect(first, isNot(second));

    // A piece closed mid-round waits for the next round.
    final more = [...minutes, 2000];
    final third = [
      for (var i = 0; i < 4; i++) rounds.next(minutes)!,
      for (var i = 0; i < 4; i++) rounds.next(more)!,
    ];
    expect(third.toSet(), minutes.toSet());
    final fourth = [for (var i = 0; i < 9; i++) rounds.next(more)!];
    expect(fourth.toSet(), more.toSet());
    // An expired piece is never sent.
    final fewer = more.where((m) => m != 1003).toList();
    final fifth = [for (var i = 0; i < 8; i++) rounds.next(fewer)!];
    expect(fifth.toSet(), fewer.toSet());
    expect(PieceRounds().next(const []), isNull);
  });

  group('held by a phone', () {
    TrackPiece piece(int minute, int end, int grid) => TrackPiece(
      minute: minute,
      endMinute: end,
      gridM: grid,
      points: _walk(_start, 3),
    );
    TrackBlock block(List<TrackPiece> pieces, {int keep = 48}) =>
        TrackBlock(gridM: pieces.first.gridM, keepHours: keep, pieces: pieces);

    test('a piece replaces its minute\'s when it reaches later, or as far '
        'on a finer grid', () {
      final track = MemberTrack();
      expect(track.add(block([piece(100, 110, 40)])), isTrue);
      expect(
        track.add(block([piece(100, 110, 60)])),
        isFalse,
        reason: 'coarser',
      );
      expect(track.add(block([piece(100, 110, 8)])), isTrue, reason: 'finer');
      expect(track.pieces[100]!.gridM, 8);
      expect(track.add(block([piece(100, 125, 40)])), isTrue, reason: 'later');
      expect(track.pieces[100]!.endMinute, 125);
      track.add(block([piece(130, 140, 8)]));
      expect(track.inOrder.map((p) => p.minute), [100, 130]);
      expect(track.held(), [130], reason: 'only the finest, newest first');
    });

    test('each piece goes the sender\'s hours after its last point', () {
      final track = MemberTrack();
      track.add(block([piece(_now - 50 * 60, _now - 49 * 60, 8)]));
      track.add(block([piece(_now - 47 * 60, _now - 46 * 60, 8)]));
      expect(track.expire(_sent), isTrue);
      expect(track.pieces.keys, [_now - 47 * 60]);
      track.add(block([piece(_now - 10, _now, 8)], keep: 6));
      expect(track.keepHours, 6, reason: 'their newest setting');
      expect(track.expire(_sent), isTrue);
      expect(track.pieces.keys, [_now - 10]);
      expect(track.expire(_sent), isFalse);
    });
  });

  group('the ask', () {
    test('reads back: who asks, whom, and the pieces held', () {
      final ask = TraxAsk(
        seq: 4,
        senderPrefix: Uint8List.fromList([9, 8, 7, 6]),
        session: 77,
        sentAt: _sent,
        target: Uint8List.fromList([1, 2, 3, 4]),
        have: [_now - 5, _now - 70000 % 65536, _now - 10080],
      );
      final bytes = ask.encode();
      expect(bytes.length, 17 + 6);
      final back = TraxAsk.decode(bytes)!;
      expect(back.target, [1, 2, 3, 4]);
      expect(back.senderPrefix, [9, 8, 7, 6]);
      expect(back.sentAt, _sent);
      expect(back.have, ask.have);
      expect(TraxReport.decode(bytes), isNull, reason: 'not a report');
      expect(TraxAsk.decode(_report().encode()), isNull, reason: 'a report');
    });

    test('at most 70 held fit, and anything broken is null', () {
      final ask = TraxAsk(
        seq: 0,
        senderPrefix: Uint8List(4),
        session: 0,
        sentAt: _sent,
        target: Uint8List(4),
        have: [for (var i = 0; i < 100; i++) _now - i],
      );
      final bytes = ask.encode();
      expect(bytes.length, TraxReport.maxSize);
      expect(TraxAsk.decode(bytes)!.have, hasLength(70));
      expect(TraxAsk.decode(bytes.sublist(0, 20)), isNull);
      expect(TraxAsk.decode(Uint8List(3)), isNull);
    });
  });
}
