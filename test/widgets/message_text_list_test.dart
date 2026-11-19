import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/message_text.dart';

// Bulleted lists hang (owner, 2026-11-18): a bullet's wrapped lines line up
// under its text, not under the bullet. A message with no list is drawn as
// it always was.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> pump(WidgetTester tester, String text) => tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppSettingsService(),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: MessageText(
                text: text,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('a bullet that wraps lines up under its text', (tester) async {
    await pump(
      tester,
      'Packing list:\n- Radio and a spare battery pack for the trip\n- Water',
    );
    expect(find.text('•'), findsNWidgets(2));
    final left = tester.getTopLeft(find.byType(MessageText)).dx;
    final item = find.textContaining('Radio and a spare');
    // 1.25 em of bullet at 10 px.
    expect(tester.getTopLeft(item).dx, closeTo(left + 12.5, 0.01));
    expect(tester.getSize(item).height, greaterThan(15), reason: 'it wraps');
    expect(tester.getTopLeft(find.textContaining('Packing list:')).dx, left);
    expect(
      tester.getTopLeft(find.textContaining('Water')).dy,
      greaterThan(tester.getBottomLeft(item).dy - 0.01),
    );
  });

  testWidgets('a message with no list is one text, as before', (tester) async {
    await pump(tester, 'a - dash, *italic* and\n-5 degrees');
    expect(find.text('•'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MessageText),
        matching: find.byType(Column),
      ),
      findsNothing,
    );
  });
}
