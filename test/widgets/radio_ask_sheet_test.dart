import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/helpers/date_time_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/radio_ask_sheet.dart';

import '../helpers/radio_ask_fakes.dart';

void main() {
  final systemFormats = DateTimeHelper.systemFormats;
  setUp(() async {
    DateTimeHelper.systemFormats = () => null;
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });
  tearDown(() => DateTimeHelper.systemFormats = systemFormats);

  final at = DateTime.now().copyWith(hour: 14, minute: 2, second: 0);

  Future<(AskRadio, RadioAskService)> open(
    WidgetTester tester, {
    ValueChanged<LatLng>? onShowOnMap,
  }) async {
    final radio = AskRadio();
    final asks = RadioAskService(radio, now: () => at);
    addTearDown(asks.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: asks),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    RadioAskSheet.show(context, gwq, onShowOnMap: onShowOnMap),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    return (radio, asks);
  }

  testWidgets('an answer shows where, when and the battery, then checks '
      'again', (tester) async {
    LatLng? shown;
    final (radio, _) = await open(tester, onShowOnMap: (p) => shown = p);
    var reads = 0;
    radio.reply = (_, _) => radio.telemetry([
      ...lppBattery,
      ...lppGps(36.5, -117.0, 610.0 + reads++),
      ...lppTemperature,
    ]);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text("Ask GWQ's radio"), findsOneWidget);
    expect(
      find.textContaining(RegExp(r"^GWQ's radio · 2:02\WPM$")),
      findsOneWidget,
    );
    expect(find.text('36.50000, -117.00000'), findsOneWidget);
    expect(find.text('4.15 V · 40°C / 104°F'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'^Checking again at 2:03\WPM$'),
      ),
      findsOneWidget,
    );
    expect(find.text('Ask again'), findsNothing);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Checking again'), findsNothing);
    expect(find.textContaining('May be old'), findsNothing);
    expect(find.text('Ask again'), findsOneWidget);

    await tester.tap(find.text('Show on map'));
    await tester.pumpAndSettle();
    expect(shown, const LatLng(36.5, -117.0));
    expect(find.text("Ask GWQ's radio"), findsNothing);
  });

  testWidgets('the same reading twice: may be old', (tester) async {
    final (radio, _) = await open(tester);
    radio.reply = (_, _) => radio.telemetry(lppGps(36.5, -117.0, 610));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('May be old: no change in 1 min'), findsOneWidget);
  });

  testWidgets('altitude 0: may be old, no live fix', (tester) async {
    final (radio, _) = await open(tester);
    radio.reply = (_, _) => radio.telemetry(lppGps(36.5, -117.0, 0));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.text('May be old: no GPS fix'),
      findsOneWidget,
    );
    expect(find.textContaining('Checking again'), findsNothing);
  });

  testWidgets('no position: their GPS may be off, and no map button', (
    tester,
  ) async {
    final (radio, _) = await open(tester, onShowOnMap: (_) {});
    radio.reply = (_, _) => radio.telemetry(lppBattery);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('No GPS location'), findsOneWidget);
    expect(find.text('4.15 V'), findsOneWidget);
    expect(find.text('Show on map'), findsNothing);
  });

  testWidgets('no answer: says so, and offers to ask again', (
    tester,
  ) async {
    final (radio, _) = await open(tester);

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('Asking… 1/3'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(find.text('No answer'), findsOneWidget);
    expect(radio.tags, hasLength(RadioAskService.attempts));

    await tester.tap(find.text('Ask again'));
    await tester.pump();
    expect(find.text('Asking… 1/3'), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
  });
}
