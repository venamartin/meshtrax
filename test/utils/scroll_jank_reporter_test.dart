import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/scroll_jank_reporter.dart';

// A stutter while scrolling is a frame or two over 16 ms, under the UI stall
// line's 50 ms. Perf builds write one line per scroll that dropped any
// (owner, 2026-10-26: "little performance glitches scrolling through
// messages").
class _PretendScreen extends StatelessWidget {
  const _PretendScreen({this.axis = Axis.vertical});

  final Axis axis;

  @override
  Widget build(BuildContext context) => ListView(
        scrollDirection: axis,
        children: [
          for (var i = 0; i < 100; i++)
            SizedBox(width: 50, height: 50, child: Text('row $i')),
        ],
      );
}

/// A frame finishing at [endUs] on the wall clock.
FrameTiming _frame(int endUs, {int buildMs = 5, int rasterMs = 4}) {
  final rasterStart = endUs - rasterMs * 1000;
  final buildStart = rasterStart - buildMs * 1000;
  return FrameTiming(
    vsyncStart: buildStart,
    buildStart: buildStart,
    buildFinish: rasterStart,
    rasterStart: rasterStart,
    rasterFinish: endUs,
    rasterFinishWallTime: endUs,
  );
}

void main() {
  late int clock;
  late List<String> lines;
  late ScrollJankReporter reporter;

  setUp(() {
    clock = 1000000;
    lines = [];
    reporter = ScrollJankReporter(
        nowUs: () => clock, enabled: () => true, log: lines.add);
  });

  /// One drag: it starts at 1.0 s and ends at 3.0 s on the clock.
  Future<void> scroll(WidgetTester tester, {Axis axis = Axis.vertical}) async {
    await tester.pumpWidget(MaterialApp(
      home: reporter.wrap(Scaffold(body: _PretendScreen(axis: axis))),
    ));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(
        axis == Axis.vertical ? const Offset(0, -300) : const Offset(-300, 0));
    await tester.pump();
    clock = 3000000;
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// The frame timings come in; the line is written once they all have.
  Future<void> report(WidgetTester tester, List<FrameTiming> frames) async {
    reporter.onTimings(frames);
    clock += ScrollJankReporter.settle.inMicroseconds;
    await tester.pump(ScrollJankReporter.settle);
  }

  testWidgets('a scroll that dropped frames says where, how many and the worst',
      (tester) async {
    await scroll(tester);
    await report(tester, [
      _frame(1500000, buildMs: 30),
      _frame(2000000),
      _frame(2500000, rasterMs: 20),
      _frame(5000000, buildMs: 40), // after the scroll: not its frame
    ]);
    expect(lines, [
      'Scroll in _PretendScreen: 2.0 s, 2 of 3 frames over 16 ms; '
          'worst build 30 ms, raster 4 ms',
    ]);
  });

  testWidgets('a smooth scroll writes nothing', (tester) async {
    await scroll(tester);
    await report(tester, [_frame(1500000), _frame(2500000, buildMs: 15)]);
    expect(lines, isEmpty);
  });

  testWidgets('a sideways list is not a message list', (tester) async {
    await scroll(tester, axis: Axis.horizontal);
    await report(tester, [_frame(1500000, buildMs: 30)]);
    expect(lines, isEmpty);
  });
}
