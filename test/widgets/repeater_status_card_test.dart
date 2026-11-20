import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';

// The repeater status card the owner approved from a mock-up, 2026-11-19:
// one row per repeater, the battery drawn from the stage, under a one-line
// header (his pick after seeing the first build).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> show(WidgetTester tester, String text) => tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: AppSettingsService(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StructuredMessageCard(
                  message: StructuredMessage.parse(text)!,
                  textScale: 1,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a status of several repeaters', (tester) async {
    await show(
      tester,
      'Repeater: A277 3.52V crit 2m | A377 3.41V crit 40m missed=1 | '
      'AD77 waiting | A477 waiting | AA77 waiting',
    );
    expect(find.text('Repeater status'), findsOneWidget);
    expect(find.text('2 critical, 3 waiting'), findsNothing,
        reason: 'the rows say it; no summary above them (owner, 11-19)');
    expect(find.text('3.52 V'), findsOneWidget);
    expect(find.text('Critical'), findsNWidgets(2));
    expect(find.text('2 min ago'), findsOneWidget);
    expect(find.text('40 min ago · 1 missed poll'), findsOneWidget);
    expect(find.text('waiting for its advert'), findsNWidgets(3));
    expect(find.byIcon(Icons.battery_1_bar), findsNWidgets(2));
    expect(find.byIcon(Icons.battery_unknown), findsNWidgets(3));
  });

  testWidgets("one repeater's details, with its note last", (tester) async {
    await show(
      tester,
      'Repeater: A277 3.52V crit 2m tx=22 repeat=off trend=-12mV/h '
      'next=40m restore waits for daylight',
    );
    expect(
      find.text('2 min ago · TX 22 · repeat off · −12mV/h · '
          'next poll in 40 min · restore waits for daylight'),
      findsOneWidget,
    );
  });

  testWidgets('unreachable, no reading, page and dry run', (tester) async {
    await show(
      tester,
      'Repeater: A277 3.48V crit was=vlow | A377 unreachable missed=2 | '
      'A477 no reading reading=0.00V sensor fault | dryrun=yes | page=2/4',
    );
    expect(find.text('was very low'), findsOneWidget);
    expect(find.text('unreachable'), findsOneWidget);
    expect(find.byIcon(Icons.battery_alert), findsOneWidget);
    expect(find.text('reading 0.00V ignored · sensor fault'), findsOneWidget);
    expect(find.text('Page 2 of 4'), findsOneWidget);
    expect(find.text('Simulation only'), findsOneWidget);
  });

  testWidgets('a renamed stage, a note alone, and a plain line', (tester) async {
    await show(
      tester,
      'Repeater: A277 3.60V low label=night-mode | A377 reachable again | '
      '+2 more: ask again',
    );
    expect(find.text('Night mode'), findsOneWidget,
        reason: "the sender's own name for the stage");
    expect(find.text('reachable again'), findsOneWidget);
    expect(find.byIcon(Icons.cell_tower), findsOneWidget);
    expect(find.text('+2 more: ask again'), findsOneWidget);
  });
}
