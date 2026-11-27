import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/screens/trax_settings_screen.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/services/trax_beacon_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/trip_positions.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/trax_guide.dart';

// Martin, 2026-11-26: "a very simple explanation ... how TRAX mode works",
// with its icons, told as "going on a hike with people behind you and
// others joining the next day". By itself after switching on until "Don't
// show this again"; from an info button in TRAX settings any time.
class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;
  @override
  bool? get clientRepeat => false;
  @override
  int? get currentFreqHz => 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
  @override
  int? get firmwareVerCode => 14;
  @override
  String get selfPublicKeyHex => '11' * 32;
  @override
  Future<List<({int lowerKhz, int upperKhz})>?>
  getAllowedRepeatFrequencies() async => null;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  final title = find.text('How TRAX works');
  final dontShow = find.text("Don't show this again");
  final close = find.byTooltip('Close');

  Future<void> pumpHome(WidgetTester tester, void Function(BuildContext) tap) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => tap(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

  testWidgets('the hike in steps, then the icons', (tester) async {
    await pumpHome(tester, showTraxGuide);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);
    for (final step in [
      'Before you go',
      'At the trailhead',
      'On the trail',
      'Friends behind you',
      'Someone quiet?',
      'Joining the next day',
      'SOS',
      'When the trip ends',
      'The icons',
      'TRAX mode off',
      'TRAX mode on',
      'A member, as the icon they picked',
      'Grey: their GPS position may be old',
      'Your track',
      'The trip channel',
    ]) {
      await tester.scrollUntilVisible(find.text(step), 200);
      expect(find.text(step), findsOneWidget, reason: step);
    }
    expect(dontShow, findsNothing, reason: 'opened by hand');
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(title, findsNothing);
  });

  // Martin, 2026-11-27: as a sheet its foot hid behind the navigation bar
  // (||| O <), and few would know to slide it down. Now a dialog with an X.
  testWidgets('a dialog clear of the navigation bar, closed by its X', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    const bars = FakeViewPadding(top: 63, bottom: 126);
    tester.view.padding = bars;
    tester.view.viewPadding = bars;
    addTearDown(tester.view.reset);
    const navigationBarTop = (2340 - 126) / 2.625;

    await pumpHome(tester, TraxGuide.showIfNotSeen);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(CheckboxListTile)).bottom,
      lessThan(navigationBarTop),
      reason: 'in sight as it opens',
    );
    final last = find.text('The trip channel');
    await tester.scrollUntilVisible(last, 200);
    expect(tester.getRect(last).bottom, lessThan(navigationBarTop));

    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(title, findsNothing);
  });

  testWidgets('by itself until "Don\'t show this again"', (tester) async {
    await pumpHome(tester, TraxGuide.showIfNotSeen);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget, reason: 'not ticked: again');
    await tester.tap(dontShow);
    await tester.pump();
    expect(PrefsManager.instance.getBool(TraxGuide.prefKey), isTrue);
    await tester.tap(close);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(title, findsNothing);
  });

  testWidgets('the info button in TRAX settings opens it', (tester) async {
    final radio = _Radio();
    final trax = TraxService(radio);
    final asks = RadioAskService(radio);
    final positions = TripPositions(radio, trax);
    final trip = TripService(radio, trax, asks, positions: positions);
    final beacon = TraxBeaconService(radio, trax, trip);
    addTearDown(() {
      beacon.dispose();
      trip.dispose();
      positions.dispose();
      asks.dispose();
      trax.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: trax),
          ChangeNotifierProvider.value(value: asks),
          ChangeNotifierProvider.value(value: trip),
          ChangeNotifierProvider.value(value: positions),
          ChangeNotifierProvider.value(value: beacon),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TraxSettingsScreen(),
        ),
      ),
    );
    await tester.tap(find.byTooltip('How TRAX works'));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);
    expect(dontShow, findsNothing);
  });
}
