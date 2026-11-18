import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/heard_ear.dart';

// The owner, 2026-11-17: a grey ear after the checkmark, and the observers
// listed in the packet path screen, not in a dialog of their own.
void main() {
  late MeshCoreConnector radio;

  Future<void> heard(Map<String, List<Map<String, Object>>> byMessage) async {
    SharedPreferences.setMockInitialValues({
      'heard_check_heard': jsonEncode(byMessage),
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    radio = MeshCoreConnector();
    addTearDown(radio.dispose);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
  }

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: ListView(children: [child])),
        ),
      );

  testWidgets('nothing for a message no observer heard', (tester) async {
    await heard({});
    await pump(tester, const Column(children: [HeardEar('m1'), HeardBySection('m1')]));
    expect(find.byIcon(Icons.hearing), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('the ear is grey', (tester) async {
    await heard({
      'm1': [
        {'observer': 'Ridge'},
      ],
    });
    await pump(tester, const HeardEar('m1'));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.hearing)).color,
      Colors.grey[600],
    );
  });

  testWidgets('the path screen lists who heard, direct or via, and signal', (
    tester,
  ) async {
    await heard({
      'm1': [
        {'observer': 'Ridge', 'snr': -8.5, 'hops': 0},
        {'observer': 'Hollow', 'snr': 4, 'hops': 2},
        {'observer': 'Pine'},
      ],
    });
    await pump(tester, const HeardBySection('m1'));
    expect(find.text('Heard by 3 observers'), findsOneWidget);
    expect(find.text('Ridge'), findsOneWidget);
    expect(find.text('direct'), findsOneWidget);
    expect(find.text('-8.5 dB'), findsOneWidget);
    expect(find.text('Hollow'), findsOneWidget);
    expect(find.text('via 2 repeaters'), findsOneWidget);
    expect(find.text('4.0 dB'), findsOneWidget);
    expect(find.text('Pine'), findsOneWidget, reason: 'no path, no signal');
  });
}
