import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/widgets/pull_down_card.dart';

void main() {
  testWidgets('slides down to its header and back up', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: SizedBox.expand(key: Key('map'))),
              PullDownCard(
                openHeight: 300,
                header: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Hops'),
                ),
                child: ListView(
                  children: [
                    for (var i = 0; i < 20; i++)
                      ListTile(title: Text('Hop $i')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    double map() => tester.getSize(find.byKey(const Key('map'))).height;
    // Open, it is as tall as asked, with its 8 px under it.
    final open = map();
    expect(open, 800 - 300 - 8);
    expect(find.text('Hop 0').hitTestable(), findsOneWidget);

    await tester.drag(find.text('Hops'), const Offset(0, 300));
    await tester.pumpAndSettle();
    final down = map();
    expect(down, greaterThan(open + 200));
    expect(find.text('Hop 0').hitTestable(), findsNothing);

    // A flick up opens it again, and a tap on the header lowers it.
    await tester.fling(find.text('Hops'), const Offset(0, -60), 1000);
    await tester.pumpAndSettle();
    expect(map(), open);
    await tester.tap(find.text('Hops'));
    await tester.pumpAndSettle();
    expect(map(), down);

    // A slow drag goes to the nearer end.
    await tester.timedDrag(
      find.text('Hops'),
      const Offset(0, -60),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(map(), down);
  });
}
