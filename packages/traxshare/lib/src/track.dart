import 'dart:math';
import 'dart:typed_data';

import 'trail.dart';

/// A stretch of a member's track, named on the air by the minute of its
/// first point: the unit reports carry and phones keep. A phone's own track
/// is cut into pieces as it grows ([pieceFits]), and a closed piece stays as
/// it is until it expires.
class TrackPiece {
  const TrackPiece({
    required this.minute,
    required this.endMinute,
    required this.points,
    this.gridM = 0,
  });

  /// Minutes since the epoch at the first point; no two of a member's
  /// pieces share one.
  final int minute;

  /// Minutes since the epoch at the last point.
  final int endMinute;

  /// Oldest first.
  final List<TrailPoint> points;

  /// The grid its points came on, in metres, finer when smaller; 0 for a
  /// phone's own.
  final int gridM;

  /// The finest a piece goes on the air: thinned to [epsilonM] on a grid of
  /// [fineGridM].
  static const epsilonM = 15.0;
  static const fineGridM = 8;

  /// The most a piece's points take at their finest, measured from its own
  /// newest point. Alone in a report, with the step from the report's own
  /// position, they fit with room to spare.
  static const maxBytes = 108;

  static int minuteOf(DateTime t) => t.millisecondsSinceEpoch ~/ 60000;
}

/// Whether [points] (oldest first) fit one piece: thinned to
/// [TrackPiece.epsilonM], within [TrackPiece.maxBytes].
bool pieceFits(List<TrailPoint> points) {
  if (points.length < 2) return true;
  final newestFirst = simplify(points, TrackPiece.epsilonM).reversed.toList();
  return encodeTrail(
        newestFirst.first,
        TrackPiece.fineGridM,
        newestFirst,
      ).length <=
      TrackPiece.maxBytes;
}

/// What a report carries of a member's track: whole pieces, newest first, on
/// one grid, and how many hours phones keep a piece after its last point.
class TrackBlock {
  const TrackBlock({
    required this.gridM,
    required this.keepHours,
    required this.pieces,
  });

  final int gridM;
  final int keepHours;

  /// Newest first.
  final List<TrackPiece> pieces;

  /// The grid, the hours kept and the number of pieces.
  static const headerBytes = 3;

  /// Per piece: its minute's low 16 bits, its span in minutes and its number
  /// of points.
  static const pieceBytes = 5;

  /// Two pieces begun in one minute are named a minute apart, so a piece's
  /// minute can be a little after the report's.
  static const _aheadMinutes = 2;

  /// The block as sent after a report's fields: the header, each piece's
  /// minute, span and count, then all the points, newest first, as steps
  /// from [anchor] ([encodeTrail]). Multi-byte numbers are little-endian.
  Uint8List encode(TrailPoint anchor) {
    final bits = encodeTrail(anchor, gridM, [
      for (final p in pieces) ...p.points.reversed,
    ]);
    final head = headerBytes + pieceBytes * pieces.length;
    final out = Uint8List(head + bits.length);
    final data = ByteData.sublistView(out);
    out[0] = gridM;
    out[1] = keepHours;
    out[2] = pieces.length;
    var at = headerBytes;
    for (final p in pieces) {
      data.setUint16(at, p.minute & 0xFFFF, Endian.little);
      final span = (p.endMinute - p.minute).clamp(0, 0xFFFF);
      data.setUint16(at + 2, span, Endian.little);
      out[at + 4] = p.points.length;
      at += pieceBytes;
    }
    out.setRange(head, out.length, bits);
    return out;
  }

  /// The block at [offset] and the bytes it took; null when malformed. A
  /// piece's minute is the latest with its low 16 bits at or before
  /// [sentAt], give or take [_aheadMinutes].
  static ({TrackBlock block, int bytes})? decode(
    TrailPoint anchor,
    DateTime sentAt,
    Uint8List data,
    int offset,
  ) {
    if (data.length < offset + headerBytes) return null;
    final grid = data[offset], keep = data[offset + 1], n = data[offset + 2];
    if (grid == 0 || keep == 0 || n == 0) return null;
    final head = offset + headerBytes + pieceBytes * n;
    if (data.length < head) return null;
    final view = ByteData.sublistView(data);
    final sent = TrackPiece.minuteOf(sentAt) + _aheadMinutes;
    final heads = <({int minute, int span, int count})>[];
    var total = 0;
    for (var at = offset + headerBytes; at < head; at += pieceBytes) {
      final count = data[at + 4];
      if (count == 0) return null;
      final low = view.getUint16(at, Endian.little);
      heads.add((
        minute: sent - ((sent - low) & 0xFFFF),
        span: view.getUint16(at + 2, Endian.little),
        count: count,
      ));
      total += count;
    }
    final read = decodeTrail(anchor, grid, total, data, head);
    if (read == null) return null;
    final pieces = <TrackPiece>[];
    var i = 0;
    for (final h in heads) {
      pieces.add(
        TrackPiece(
          minute: h.minute,
          endMinute: h.minute + h.span,
          gridM: grid,
          points: read.points.sublist(i, i + h.count).reversed.toList(),
        ),
      );
      i += h.count;
    }
    return (
      block: TrackBlock(gridM: grid, keepHours: keep, pieces: pieces),
      bytes: head - offset + read.bytes,
    );
  }
}

/// The track a report carries back from [anchor]: the first of [pieces]
/// (newest first, the open one first), then as many more as lie within
/// [reachM] along the way and fit [maxBytes], whole and thinned alike:
/// Douglas–Peucker from 15 m, doubled until they fit, then bisected to
/// within 1 m, on a grid of max(8, ⌈ε/2⌉) m. Each piece keeps its ends.
TrackBlock? fitTrack(
  TrailPoint anchor,
  List<TrackPiece> pieces,
  int maxBytes, {
  required int keepHours,
  double reachM = 16093.44,
}) {
  final within = <TrackPiece>[];
  var walked = 0.0;
  for (final p in pieces) {
    if (within.isNotEmpty && walked >= reachM) break;
    within.add(p);
    walked += pathMetres(p.points);
  }
  for (var n = within.length; n > 0; n--) {
    final fit = _fit(anchor, within.sublist(0, n), maxBytes, keepHours);
    if (fit != null) return fit;
  }
  return null;
}

TrackBlock? _fit(
  TrailPoint anchor,
  List<TrackPiece> pieces,
  int maxBytes,
  int keepHours,
) {
  TrackBlock? attempt(double epsilon) {
    final grid = max(TrackPiece.fineGridM, (epsilon / 2).ceil());
    if (grid > 255) return null;
    final thinned = [
      for (final p in pieces)
        TrackPiece(
          minute: p.minute,
          endMinute: p.endMinute,
          gridM: grid,
          points: simplify(p.points, epsilon),
        ),
    ];
    if (thinned.any((p) => p.points.length > 255)) return null;
    final block = TrackBlock(
      gridM: grid,
      keepHours: keepHours,
      pieces: thinned,
    );
    return block.encode(anchor).length <= maxBytes ? block : null;
  }

  var epsilon = TrackPiece.epsilonM;
  var fit = attempt(epsilon);
  if (fit != null) return fit;
  var failed = epsilon;
  while (fit == null) {
    epsilon *= 2;
    if (epsilon > 510) return null;
    fit = attempt(epsilon);
    if (fit == null) failed = epsilon;
  }
  while (epsilon - failed > 1) {
    final mid = (failed + epsilon) / 2;
    final finer = attempt(mid);
    if (finer == null) {
      failed = mid;
    } else {
      epsilon = mid;
      fit = finer;
    }
  }
  return fit;
}

/// [pieces], oldest first, as lines to draw: a piece runs on into the next
/// where that one starts where it ended, within their grids.
List<List<TrailPoint>> trackLines(List<TrackPiece> pieces) {
  final lines = <List<TrailPoint>>[];
  TrackPiece? last;
  for (final p in pieces) {
    if (p.points.isEmpty) continue;
    if (last != null &&
        metresBetween(last.points.last, p.points.first) <=
            2.0 * max(last.gridM, p.gridM)) {
      lines.last.addAll(p.points.skip(1));
    } else {
      lines.add([...p.points]);
    }
    last = p;
  }
  return lines;
}

/// The older pieces in rounds: each once a round, in a new random order
/// every round, so a phone that hears only some reports still gets them all
/// in time. A piece closed during a round waits for the next.
class PieceRounds {
  PieceRounds([Random? random]) : _random = random ?? Random();

  final Random _random;
  final _round = <int>[];

  /// Which of [minutes] goes next; null when there are none.
  int? next(Iterable<int> minutes) {
    final present = minutes.toSet();
    if (present.isEmpty) return null;
    while (true) {
      while (_round.isNotEmpty) {
        final m = _round.removeLast();
        if (present.contains(m)) return m;
      }
      _round.addAll(present.toList()..shuffle(_random));
    }
  }
}
