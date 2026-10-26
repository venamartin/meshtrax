import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/widgets.dart';

import 'app_logger.dart';

/// Perf builds only: one debug-log line for each scroll that dropped
/// frames. It says where, how long the scroll lasted, how many frames ran
/// over budget, and the worst of them split into build (the UI thread) and
/// raster (owner, 2026-10-26: "little performance glitches scrolling
/// through messages"). The UI stall line reports only frames of 50 ms and
/// over; a stutter while scrolling is a frame or two over 16 ms.
class ScrollJankReporter {
  ScrollJankReporter({
    int Function()? nowUs,
    bool Function()? enabled,
    void Function(String line)? log,
  })  : _nowUs = nowUs ?? (() => DateTime.now().microsecondsSinceEpoch),
        _enabled = enabled ?? (() => appLogger.isEnabled),
        _log = log ??
            ((line) => appLogger.info(line, tag: 'Perf', noNotify: true));

  static final instance = ScrollJankReporter();

  /// Over budget: a 60 Hz frame and a hair, on either thread.
  static const budgetUs = 17000;

  /// How long a finished scroll waits for its last frame timings: the
  /// engine sends them about once a second.
  static const settle = Duration(milliseconds: 2500);

  final int Function() _nowUs;
  final bool Function() _enabled;
  final void Function(String line) _log;
  _Scroll? _open;
  final _closed = <_Scroll>[];
  Timer? _flushTimer;

  /// Scroll notifications bubble up here from every list in the app.
  Widget wrap(Widget child) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          onScroll(notification);
          return false;
        },
        child: child,
      );

  @visibleForTesting
  void onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical || !_enabled()) return;
    if (notification is ScrollStartNotification) {
      _open ??= _Scroll(
          _where(notification.context), _nowUs(), notification.context);
    } else if (notification is ScrollEndNotification) {
      final scroll = _open;
      // A list inside the one being scrolled ends on its own.
      if (scroll == null || !identical(scroll.context, notification.context)) {
        return;
      }
      _open = null;
      scroll.endUs = _nowUs();
      _closed.add(scroll);
      _flushTimer?.cancel();
      _flushTimer = Timer(settle, flush);
    }
  }

  /// Each frame goes to the scroll it finished in, by the wall clock the
  /// engine stamps on its raster finish.
  void onTimings(List<FrameTiming> timings) {
    if (_open == null && _closed.isEmpty) return;
    for (final timing in timings) {
      _scrollAt(timing.timestampInMicroseconds(FramePhase.rasterFinishWallTime))
          ?.add(timing);
    }
  }

  _Scroll? _scrollAt(int at) {
    final open = _open;
    if (open != null && at >= open.startUs) return open;
    for (final scroll in _closed) {
      if (at >= scroll.startUs && at <= scroll.endUs! + budgetUs) return scroll;
    }
    return null;
  }

  /// Writes the line of every scroll whose frames have all come in.
  @visibleForTesting
  void flush() {
    final due = _nowUs() - settle.inMicroseconds;
    _closed.removeWhere((scroll) {
      if (scroll.endUs! > due) return false;
      final line = scroll.report();
      if (line != null) _log(line);
      return true;
    });
  }

  /// The screen the list is on: the nearest widget named "...Screen".
  static String _where(BuildContext? context) {
    var where = 'a list';
    context?.visitAncestorElements((element) {
      final name = element.widget.runtimeType.toString();
      if (!name.endsWith('Screen')) return true;
      where = name;
      return false;
    });
    return where;
  }
}

class _Scroll {
  _Scroll(this.where, this.startUs, this.context);

  final String where;
  final int startUs;
  final BuildContext? context;
  int? endUs;
  var _frames = 0;
  var _slow = 0;
  FrameTiming? _worst;

  /// The busier of the two threads: either one over budget drops the frame.
  static int _cost(FrameTiming timing) => math.max(
      timing.buildDuration.inMicroseconds, timing.rasterDuration.inMicroseconds);

  void add(FrameTiming timing) {
    _frames++;
    final cost = _cost(timing);
    if (cost > ScrollJankReporter.budgetUs) _slow++;
    final worst = _worst;
    if (worst == null || cost > _cost(worst)) _worst = timing;
  }

  /// Null for a smooth scroll.
  String? report() {
    final worst = _worst;
    if (_slow == 0 || worst == null) return null;
    final seconds = ((endUs! - startUs) / 1e6).toStringAsFixed(1);
    return 'Scroll in $where: $seconds s, $_slow of $_frames frames over '
        '16 ms; worst build ${worst.buildDuration.inMilliseconds} ms, '
        'raster ${worst.rasterDuration.inMilliseconds} ms';
  }
}
