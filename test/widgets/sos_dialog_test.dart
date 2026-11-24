import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/sos_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_dialogs.dart';

// The SOS dialog reads the radio first and says how old its position is,
// as far as the radio says; it never makes sending wait (Martin's decision
// 16, preliminary). "Also send to Public" is ticked and shows it.
class _Radio extends MeshCoreConnector {
  _Radio({this.lat, this.lon, this.asks = true});

  double? lat, lon;
  final bool asks;
  int viewers = 0;

  @override
  bool get canAskSelfPosition => asks;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  void addSelfPositionViewer() => viewers++;
  @override
  void removeSelfPositionViewer() => viewers--;

  /// The radio answers its self telemetry request.
  void answer(double lat, double lon, {DateTime? at}) {
    this.lat = lat;
    this.lon = lon;
    selfGps.value = (
      latitude: lat,
      longitude: lon,
      altitude: 900,
      at: at ?? DateTime.now(),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  /// Opens the channel SOS dialog; the function returned gives what it
  /// closed with.
  Future<SosRequest? Function()> open(
    WidgetTester tester,
    _Radio radio, {
    bool offerPublic = true,
    String? replaces,
    bool repeats = true,
    bool traxOnly = false,
  }) async {
    SosRequest? result;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await StructuredMessageDialogs.sosInChannel(
                      context,
                      radio,
                      offerPublic: offerPublic,
                      replaces: replaces,
                      repeats: repeats,
                      traxOnly: traxOnly,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return () => result;
  }

  FilledButton send(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Send SOS'),
  );

  testWidgets('asks the radio, then shows the time and age of its answer', (
    tester,
  ) async {
    final radio = _Radio(lat: 36.46, lon: -116.87);
    await open(tester, radio);
    expect(radio.viewers, 1, reason: 'asks now, and every 10 s while open');
    expect(find.text('Asking the radio for its location…'), findsOneWidget);
    expect(
      send(tester).onPressed,
      isNotNull,
      reason: 'sending never waits for the answer',
    );

    final at = DateTime.now();
    radio.answer(36.461234, -116.871234, at: at);
    await tester.pump();
    expect(
      find.textContaining(
        RegExp(r'^Radio location from \d{1,2}:\d\d\W+[AP]M \(Just now\)$'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('36.461234, -116.871234'),
      findsOneWidget,
      reason: 'the field takes the new position',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
    await tester.pumpAndSettle();
    expect(radio.viewers, 0);
  });

  testWidgets('no answer: the last known position, with its age', (
    tester,
  ) async {
    final radio = _Radio(lat: 36.46, lon: -116.87);
    radio.selfGps.value = (
      latitude: 36.46,
      longitude: -116.87,
      altitude: 900,
      at: DateTime.now().subtract(const Duration(minutes: 22)),
    );
    await open(tester, radio);
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.textContaining(
        RegExp(
          r'^No new location\. Last known .+ \(22m ago\)\.$',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a position with no reading: its age is unknown, and it says '
      'so', (tester) async {
    final radio = _Radio(lat: 36.46, lon: -116.87, asks: false);
    await open(tester, radio);
    expect(
      find.text('Last known location, age unknown.'),
      findsOneWidget,
    );
    expect(radio.viewers, 0, reason: 'a radio that cannot answer is not asked');
  });

  testWidgets('Also send to Public is ticked, and goes with the request', (
    tester,
  ) async {
    final radio = _Radio(lat: 36.46, lon: -116.87, asks: false);
    final result = await open(tester, radio);
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isTrue);
    expect(find.text('Also send to Public'), findsOneWidget);
    expect(
      find.text('Anyone in range can read it and your location. Sent once.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'What happened?'),
      'Broken leg',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
    await tester.pumpAndSettle();
    final request = result()!;
    expect(request.alsoPublic, isTrue);
    expect(request.followRadio, isTrue);
    expect(request.message.toWire(), 'SOS: Broken leg\n36.460000, -116.870000');
  });

  testWidgets('unticked, no Public copy; in Public itself, no box', (
    tester,
  ) async {
    final radio = _Radio(lat: 36.46, lon: -116.87, asks: false);
    final result = await open(tester, radio);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
    await tester.pumpAndSettle();
    expect(result()!.alsoPublic, isFalse);
  });

  testWidgets('no Public box where it is not offered', (tester) async {
    await open(
      tester,
      _Radio(lat: 36.46, lon: -116.87, asks: false),
      offerPublic: false,
    );
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('a typed position over the radio\'s is kept for the repeats, '
      'and a later answer does not replace it', (tester) async {
    final radio = _Radio(lat: 36.46, lon: -116.87);
    final result = await open(tester, radio);
    await tester.enterText(
      find.widgetWithText(TextField, '36.460000, -116.870000'),
      '36.5, -117',
    );
    await tester.pump();
    expect(
      find.text("Your own location: every repeat sends it."),
      findsOneWidget,
    );
    radio.answer(36.47, -116.88);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
    await tester.pumpAndSettle();
    final request = result()!;
    expect(request.followRadio, isFalse);
    expect(request.message.position.latitude, 36.5);
  });

  testWidgets('in Public: no Public box, and it says it goes once', (
    tester,
  ) async {
    final result = await open(
      tester,
      _Radio(lat: 36.46, lon: -116.87, asks: false),
      offerPublic: false,
      repeats: false,
    );
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(
      find.text('In Public it goes once.'),
      findsOneWidget,
    );
    expect(find.textContaining('Repeats every 2 min'), findsNothing);
    expect(
      find.text('Last known location, age unknown.'),
      findsOneWidget,
      reason: 'the position age stays',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send SOS'));
    await tester.pumpAndSettle();
    expect(result()!.alsoPublic, isFalse);
  });

  testWidgets('says when it cancels an SOS in another chat', (tester) async {
    await open(
      tester,
      _Radio(lat: 36.46, lon: -116.87, asks: false),
      replaces: 'camp',
    );
    expect(find.text('This cancels your SOS in camp.'), findsOneWidget);
    expect(find.textContaining('Repeats every 2 min'), findsOneWidget);
  });

  // Martin, 2026-11-18: in TRAX mode only the group's radios are on that
  // frequency, so an SOS (its Public copy too) reaches nobody else.
  testWidgets('in TRAX mode it says only TRAX radios hear it', (tester) async {
    const only = 'TRAX mode: only TRAX radios hear it.';
    await open(tester, _Radio(lat: 36.46, lon: -116.87, asks: false));
    expect(find.text(only), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    await open(
      tester,
      _Radio(lat: 36.46, lon: -116.87, asks: false),
      traxOnly: true,
    );
    expect(find.text(only), findsOneWidget);
  });
}
