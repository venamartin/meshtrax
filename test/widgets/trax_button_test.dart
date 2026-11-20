import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/trax_button.dart';

// The boot print in the Chats and Map bars: grey while TRAX mode is off,
// the logo's orange while the radio is on a TRAX preset, whichever phone
// switched it.
class _Radio extends MeshCoreConnector {
  _Radio({this.repeat = false, this.freq = 910525});

  bool repeat;
  int freq;

  @override
  bool get isConnected => true;
  @override
  bool? get clientRepeat => repeat;
  @override
  int? get currentFreqHz => freq;
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

  Future<TraxService> pump(WidgetTester tester, _Radio radio) async {
    final trax = TraxService(radio);
    final asks = RadioAskService(radio);
    final trip = TripService(radio, trax, asks);
    addTearDown(() {
      trip.dispose();
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
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(appBar: AppBar(actions: const [TraxButton()])),
        ),
      ),
    );
    return trax;
  }

  Color? iconColor(WidgetTester tester) =>
      tester.widget<ImageIcon>(find.byType(ImageIcon)).color;

  testWidgets('grey while off', (tester) async {
    await pump(tester, _Radio());
    expect(find.byTooltip('TRAX mode is off'), findsOneWidget);
    expect(iconColor(tester), isNot(const Color(Trax.orange)));
  });

  testWidgets('a radio found on a TRAX preset shows it on', (tester) async {
    await pump(tester, _Radio(repeat: true, freq: 918000));
    expect(find.byTooltip('TRAX mode is on'), findsOneWidget);
    expect(iconColor(tester), const Color(Trax.orange));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Leave TRAX'), findsOneWidget);
    expect(find.text('Nobody heard on TRAX yet'), findsOneWidget);
    expect(
      find.textContaining('No saved settings on this phone'),
      findsOneWidget,
      reason: 'another phone switched it',
    );
  });

  testWidgets('the sheet says what one tap changes, and waits for an end', (
    tester,
  ) async {
    await pump(tester, _Radio());
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(
      find.text('910.525\u00A0MHz · 62.5\u00A0kHz · SF7 · CR5'),
      findsOneWidget,
    );
    expect(
      find.text(
        '918.000\u00A0MHz · 62.5\u00A0kHz · SF7 · CR5\nOff-Grid Repeat on',
      ),
      findsOneWidget,
    );
    expect(find.text('Trip ends'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Switch to TRAX'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the sheet\'s buttons clear the navigation bar', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.resetPadding);
    await pump(tester, _Radio());
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    final ratio = tester.view.devicePixelRatio;
    final screen = tester.view.physicalSize.height / ratio;
    final button = tester.getRect(
      find.widgetWithText(FilledButton, 'Switch to TRAX'),
    );
    expect(button.bottom, lessThanOrEqualTo(screen - 144 / ratio));
  });
}
