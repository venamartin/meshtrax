// Layout and rendering guards for the path_lab topology map.
// Run: flutter test test/path_lab/map_view_test.dart

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';

import 'main.dart' as lab;
import 'map_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  lab.graph = PathGraph(NativeDatabase.memory());

  setUpAll(() async {
    await lab.graph.init();
    lab.graph.setRadioIdentity('ab' * 32, 2);
    // A277 -> 1312 -> 5CBB overheard; the round trip measures A277<->1312.
    lab.graph.observePath(
        Uint8List.fromList([0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB]), 2,
        const ObservationOrigin.anonymous());
    lab.graph.observeTrace(['A277', '1312', 'A277'], [9.0, 6.5, -4.0]);
    // Only A277 ever advertised a position.
    lab.graph.ingestNode('A277', name: 'Alpha', lat: 36.97, lon: -121.73);
  });

  test('placed nodes get coordinates, the rest land in the strip', () {
    final layout = GraphLayout(lab.graph.snapshot().nodes, const Size(800, 600));
    expect(layout.unplaced, containsAll(['1312', '5CBB']));
    expect(layout.unplaced.contains('A277'), isFalse);
    expect(layout.positions.keys.toSet(),
        lab.graph.snapshot().nodes.keys.toSet(),
        reason: 'every node is drawable, positioned or not');
    for (final at in layout.positions.values) {
      expect(at.dx, inInclusiveRange(0, 800));
      expect(at.dy, inInclusiveRange(0, 600));
    }
    expect(layout.positions['1312']!.dy, greaterThan(layout.stripTop));
  });

  test('hit test snaps to the nearest node and misses empty space', () {
    final layout = GraphLayout(lab.graph.snapshot().nodes, const Size(800, 600));
    final at = layout.positions['1312']!;
    expect(layout.hitTest(at + const Offset(4, 4)), '1312');
    expect(layout.hitTest(at + const Offset(300, 200)), isNull);
  });

  test('snr colour tracks the estimator curve', () {
    expect(snrColor(null), const Color(0xFF78909C));
    // Green end vs red end: more green, less red.
    final good = snrColor(10), bad = snrColor(-20);
    expect(good.g, greaterThan(bad.g));
    expect(bad.r, greaterThan(good.r));
  });

  testWidgets('map renders and selecting a node lists its directed links',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    expect(find.textContaining('3 nodes'), findsOneWidget);
    expect(find.textContaining('Tap a node'), findsOneWidget);

    final layout = GraphLayout(lab.graph.snapshot().nodes,
        tester.getSize(find.byKey(const ValueKey('topology'))));
    await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('topology'))) +
            layout.positions['1312']!);
    await tester.pumpAndSettle();

    expect(find.text('reaches (they heard this node)'), findsOneWidget);
    expect(find.text('hears (this node heard them)'), findsOneWidget);
    // 1312 -> 5CBB was overheard once and never measured back.
    expect(find.textContaining('ONE-WAY'), findsWidgets);
  });
}
