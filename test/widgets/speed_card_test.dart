import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/geo_format.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/self_motion.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_theme.dart';
import 'package:meshtrax/widgets/speed_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxwater/traxwater.dart';

// Martin, 2026-11-26: "in other map apps it will show your speed in the
// corner": speed, altitude and heading at the map's lower left while it
// keeps you in the middle (a card, chosen from three layouts); knots and
// °M on the charts. Later: light or dark as the map is, and just the
// altitude while the speed or heading isn't known ("No need to show an
// empty speed").
class _Radio extends MeshCoreConnector {
  int speedViewers = 0;

  @override
  bool get gpsOn => true;
  @override
  bool get selfGpsIsFresh => true;
  @override
  void addSpeedViewer() => speedViewers++;
  @override
  void removeSpeedViewer() => speedViewers--;
}

void main() {
  late _Radio radio;
  late DateTime now;
  const lat0 = 36.6, lon0 = -121.8;

  /// 72 km/h north: 60 m between readings 3 s apart.
  const step = 60 / 111320;
  const every = Duration(seconds: 3);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    radio = _Radio();
    now = DateTime(2026, 11, 26, 9);
    SelfMotion.instance.attach(radio, clock: () => now);
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    UnitSystem units = UnitSystem.imperial,
    bool nautical = false,
    bool dark = false,
    Brightness app = Brightness.light,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: appTheme(app),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SpeedCard(
            connector: radio,
            units: units,
            nautical: nautical,
            dark: dark,
          ),
        ),
      ),
    ),
  );

  Size size(WidgetTester tester) => tester.getSize(find.byType(SpeedCard));

  Future<void> reading(
    WidgetTester tester,
    double lat, {
    double altitude = 61,
  }) async {
    now = now.add(every);
    radio.selfGps.value = (
      latitude: lat,
      longitude: lon0,
      altitude: altitude,
      at: now,
    );
    await tester.pump();
  }

  Future<void> drive(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await reading(tester, lat0 + i * step);
    }
  }

  testWidgets('driving: speed, heading and altitude; the radio read every '
      '3 s while it shows', (tester) async {
    await pumpCard(tester);
    expect(radio.speedViewers, 1);
    await drive(tester);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('MPH'), findsOneWidget);
    expect(find.text('N 0°'), findsOneWidget);
    expect(find.text('200 ft'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(SpeedCard)).label,
      'Speed 45 mph, Heading N 0°, Elevation 200 ft',
    );

    await tester.pumpWidget(const SizedBox());
    expect(radio.speedViewers, 0);
  });

  testWidgets('stopped: just the altitude', (tester) async {
    await pumpCard(tester, units: UnitSystem.metric);
    await drive(tester);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('KM/H'), findsOneWidget);
    await tester.pumpAndSettle();
    final full = size(tester);
    for (var i = 0; i < 4; i++) {
      await reading(tester, lat0 + 5 * step);
    }
    expect(find.text('72'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('KM/H'), findsNothing);
    expect(find.text('Not moving'), findsNothing);
    expect(find.text('N 0°'), findsNothing);
    expect(find.text('61 m'), findsOneWidget);
    expect(tester.getSemantics(find.byType(SpeedCard)).label, 'Elevation 61 m');
    await tester.pumpAndSettle();
    expect(size(tester).width, full.width);
    expect(size(tester).height, lessThan(full.height / 2));
  });

  testWidgets('not known yet: just the altitude; without it, nothing', (
    tester,
  ) async {
    await pumpCard(tester);
    await reading(tester, lat0);
    expect(find.text('200 ft'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('MPH'), findsNothing);

    await reading(tester, lat0, altitude: 0);
    expect(find.textContaining('ft'), findsNothing);
    expect(size(tester), Size.zero);
  });

  testWidgets('on the charts: knots and degrees magnetic', (tester) async {
    await pumpCard(tester, nautical: true);
    await drive(tester);
    expect(find.text('39'), findsOneWidget);
    expect(find.text('KN'), findsOneWidget);
    final variation = magneticDeclination(
      lat0 + 5 * step,
      lon0,
      DateTime.now(),
    );
    expect(variation, greaterThan(10), reason: 'about 12° E here');
    expect(
      find.text('${GeoFormat.headingText((0 - variation) % 360)}M'),
      findsOneWidget,
    );
  });

  testWidgets('light or dark as the map is, whatever the app is', (
    tester,
  ) async {
    Color card() => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(SpeedCard),
            matching: find.byType(Material),
          ),
        )
        .color!;
    Color? figures() => tester.widget<Text>(find.text('45')).style?.color;

    for (final (app, map) in [
      (Brightness.light, Brightness.dark),
      (Brightness.dark, Brightness.light),
    ]) {
      await pumpCard(tester, app: app, dark: map == Brightness.dark);
      await drive(tester);
      final scheme = appTheme(map).colorScheme;
      expect(card(), scheme.surfaceContainerHigh);
      expect(figures(), scheme.onSurface);
      expect(card(), isNot(appTheme(app).colorScheme.surfaceContainerHigh));
    }
  });
}
