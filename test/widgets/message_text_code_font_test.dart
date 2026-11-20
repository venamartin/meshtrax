import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/message_text.dart';

// The owner, 2026-11-19, of a bot's help in a code block that wrapped on
// his phone: code text smaller, in a more computer-like font. His pick of
// five: JetBrains Mono, carried in the app.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  /// The style of the span whose text holds [piece]. A desktop draws
  /// selectable text, a phone plain rich text.
  TextStyle styleOf(WidgetTester tester, String piece) {
    final shown = tester.widget(
      find
          .descendant(
            of: find.byType(MessageText),
            matching: find.byWidgetPredicate(
              (w) =>
                  (w is SelectableText && w.textSpan != null) ||
                  (w is Text && w.textSpan != null),
            ),
          )
          .first,
    );
    final root =
        shown is SelectableText ? shown.textSpan! : (shown as Text).textSpan!;
    TextStyle? found;
    root.visitChildren((span) {
      if (span is TextSpan && (span.text ?? '').contains(piece)) {
        found = span.style;
      }
      return found == null;
    });
    return found!;
  }

  Future<void> show(WidgetTester tester, String text) => tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppSettingsService(),
          child: MaterialApp(
            home: Scaffold(
              body: MessageText(
                text: text,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      );

  testWidgets('a code block is JetBrains Mono at 80% of the text size',
      (tester) async {
    await show(tester, 'help:\n```\n!status   all repeaters\n```');
    final code = styleOf(tester, '!status   all repeaters');
    expect(code.fontFamily, 'JetBrains Mono');
    expect(code.fontSize, closeTo(12, 0.001));
    expect(styleOf(tester, 'help:').fontSize, 15);
  });

  testWidgets('inline code too', (tester) async {
    await show(tester, 'send `!status` here');
    expect(styleOf(tester, '!status').fontFamily, 'JetBrains Mono');
    expect(styleOf(tester, '!status').fontSize, closeTo(12, 0.001));
  });

  test('the font and its licence ship with the app', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final licence =
        await rootBundle.loadString('assets/fonts/JetBrainsMono-OFL.txt');
    expect(licence, contains('SIL Open Font License, Version 1.1'));
    expect(
      (await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
          .lengthInBytes,
      greaterThan(100000),
    );
  });
}
