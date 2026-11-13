import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/utils/route_transitions.dart';

// Flutter 3.50 made Android's page transition animate a picture of the
// page's first frame. A chat gets its messages a frame later, so it came in
// showing "No messages yet" for the whole 450 ms (owner's phone, 2026-11-13).
void main() {
  Future<bool> snapshotsWhileComingIn(
    WidgetTester tester,
    PageTransitionsTheme? transitions,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
          pageTransitionsTheme: transitions,
        ),
        home: const Scaffold(body: Text('chats')),
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('chat')),
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final snapshots = tester
        .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
        .any((widget) => widget.controller.allowSnapshotting);
    await tester.pumpAndSettle();
    return snapshots;
  }

  // If this stops holding, the test below proves nothing: look again at how
  // the framework brings a page in.
  testWidgets("Flutter's own Android transition animates a snapshot",
      (tester) async {
    expect(await snapshotsWhileComingIn(tester, null), isTrue);
  });

  testWidgets('a page coming in on Android is drawn live', (tester) async {
    expect(await snapshotsWhileComingIn(tester, appPageTransitions), isFalse);
  });

  test("the other platforms keep Flutter's transitions", () {
    final defaults = const PageTransitionsTheme().builders;
    for (final platform in TargetPlatform.values) {
      if (platform == TargetPlatform.android) continue;
      expect(
        appPageTransitions.builders[platform],
        defaults[platform],
        reason: '$platform',
      );
    }
  });
}
