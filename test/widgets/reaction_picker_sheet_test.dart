import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/helpers/quick_reactions.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/reaction_picker_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<(AppSettingsService, List<String>)> pump(
    WidgetTester tester, {
    Locale? locale,
    bool desktop = false,
  }) async {
    if (desktop) {
      // A Windows window at its default size, less the title bar.
      tester.view.physicalSize = const Size(1280, 681);
      tester.view.devicePixelRatio = 1;
    } else {
      // A phone with a navigation bar.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      tester.view.padding = const FakeViewPadding(top: 100, bottom: 126);
    }
    addTearDown(tester.view.reset);
    final settings = AppSettingsService();
    final picked = <String>[];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        ReactionPickerSheet(onEmojiSelected: picked.add),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (settings, picked);
  }

  testWidgets('twelve quick reactions in two rows of six', (tester) async {
    await pump(tester);
    final cells = [
      for (final e in QuickReactions.defaults) tester.getCenter(find.text(e).first),
    ];
    final rows = cells.map((c) => c.dy.round()).toSet();
    expect(rows, hasLength(2));
    expect(cells.where((c) => c.dy.round() == rows.first), hasLength(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pick is sent and becomes the first quick reaction',
      (tester) async {
    final (settings, picked) = await pump(tester);
    await tester.tap(find.text('🔥').first);
    await tester.pumpAndSettle();
    expect(picked, ['🔥']);
    expect(settings.settings.recentReactions.first, '🔥');
    expect(QuickReactions.of(settings.settings.recentReactions).first, '🔥');
  });

  testWidgets('search finds emoji by keyword', (tester) async {
    final (_, picked) = await pump(tester);
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('🍕'), findsOneWidget);
    await tester.tap(find.text('🍕'));
    await tester.pumpAndSettle();
    expect(picked, ['🍕']);
  });

  testWidgets('search knows the app language, and English too',
      (tester) async {
    await pump(tester, locale: const Locale('de'));
    await tester.enterText(find.byType(TextField), 'Herz');
    await tester.pumpAndSettle();
    expect(find.text('❤️'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'heart');
    await tester.pumpAndSettle();
    expect(find.text('❤️'), findsWidgets);
  });

  testWidgets('a desktop window keeps rows of emoji below the quick grid',
      (tester) async {
    await pump(tester, desktop: true);
    expect(tester.takeException(), isNull);
    // Fixed-height quick rows leave the category picker real room.
    expect(
      tester.getSize(find.byType(epf.EmojiPicker)).height,
      greaterThan(140),
    );
  });
}
