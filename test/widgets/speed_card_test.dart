import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/geo_format.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/self_motion.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/speed_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxwater/traxwater.dart';

// Martin, 2026-11-26: "in other map apps it will show your speed in the
// corner": speed, altitude and heading at the map's lower left while it
// keeps you in the middle (a card, chosen from three layouts); knots and
// °M on the charts.
class _Radio extends MeshCoreConnector {
  bool fresh = true;
  int speedViewers = 0;

  @override
  bool get gpsOn => true;
  @override
  bool get selfGpsIsFresh => fresh;
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
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SpeedCard(connector: radio, units: units, nautical: nautical),
        ),
      ),
    ),
  );

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
    expect(find.text('mph'), findsOneWidget);
    expect(find.text('N 0°'), findsOneWidget);
    expect(find.text('200 ft'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(SpeedCard)).label,
      'Speed 45 mph, Heading N 0°, Elevation 200 ft',
    );

    await tester.pumpWidget(const SizedBox());
    expect(radio.speedViewers, 0);
  });

  testWidgets('stopped: 0 and not moving', (tester) async {
    await pumpCard(tester, units: UnitSystem.metric);
    await drive(tester);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await reading(tester, lat0 + 5 * step);
    }
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Not moving'), findsOneWidget);
    expect(find.text('N 0°'), findsNothing);
    expect(find.text('61 m'), findsOneWidget);
  });

  testWidgets('not known yet: a dash; altitude 0 is no fix', (tester) async {
    await pumpCard(tester);
    await reading(tester, lat0, altitude: 0);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('mph'), findsOneWidget);
    expect(find.textContaining('ft'), findsNothing);
    expect(find.text('Not moving'), findsNothing);
  });

  testWidgets('a reading that may be old: last known, in grey', (tester) async {
    await pumpCard(tester);
    await drive(tester);
    radio.fresh = false;
    await reading(tester, lat0 + 5 * step);
    expect(find.text('Last known'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('N 0°'), findsNothing);
    final context = tester.element(find.byType(SpeedCard));
    expect(
      tester.widget<Text>(find.text('200 ft')).style?.color,
      Theme.of(context).colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('on the charts: knots and degrees magnetic', (tester) async {
    await pumpCard(tester, nautical: true);
    await drive(tester);
    expect(find.text('39'), findsOneWidget);
    expect(find.text('kn'), findsOneWidget);
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
}
