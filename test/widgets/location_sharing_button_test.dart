import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/location_sharing_button.dart';

class _Radio extends MeshCoreConnector {
  _Radio({
    this.base = teleModeDeny,
    this.loc = teleModeDeny,
    this.advert = 0,
    this.lat,
    this.lon,
    this.saved = const [],
  });
  int base, loc, advert;
  double? lat, lon;
  final List<Contact> saved;
  bool connected = true;

  /// (base, location, environment, advert) as written to the radio.
  final writes = <(int, int, int, int)>[];

  @override
  bool get isConnected => connected;
  @override
  int get telemetryModeBase => base;
  @override
  int get telemetryModeLoc => loc;
  @override
  int get advertLocationPolicy => advert;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  List<Contact> get contacts => saved;
  @override
  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
    int multiAcks,
  ) async {
    writes.add((base, location, env, advert));
    this.base = base;
    loc = location;
    this.advert = advert;
    notifyListeners();
  }

  @override
  Future<void> refreshDeviceInfo() async {}
}

Contact _contact(String name, int seed, {int flags = 0}) => Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
  name: name,
  type: advTypeChat,
  flags: flags,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 10, 27),
  isActive: true,
);

const _both = contactFlagTeleBase | contactFlagTeleLoc;
final _carol = _contact('Carol', 0x10, flags: _both);
final _dave = _contact('Dave', 0x40, flags: contactFlagTeleBase);
final _erin = _contact('Erin', 0x70);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> pump(WidgetTester tester, _Radio radio) => tester.pumpWidget(
    ChangeNotifierProvider<MeshCoreConnector>.value(
      value: radio,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: LocationSharingButton())),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, _Radio radio) async {
    await pump(tester, radio);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  const hide = 'Hide my location from everyone';
  const nobody = 'Nobody can see your location';

  testWidgets('grey while nobody can see it, blue once the radio has a '
      'position its adverts carry', (tester) async {
    final radio = _Radio(advert: 1);
    await pump(tester, radio);
    Color? color() =>
        tester.widget<Icon>(find.byIcon(Icons.share_location)).color;
    expect(color(), Colors.grey);
    expect(find.byTooltip(nobody), findsOneWidget);

    radio
      ..lat = 36.6
      ..lon = -121.9
      ..notifyListeners();
    // The connector batches its notifications on a short timer.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final scheme = Theme.of(tester.element(find.byType(IconButton))).colorScheme;
    expect(color(), scheme.primary);
    expect(find.byTooltip('Someone can see your location'), findsOneWidget);
  });

  testWidgets('no icon while disconnected', (tester) async {
    await pump(tester, _Radio()..connected = false);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the dialog names who can see it, and one tap hides it from '
      'everyone', (tester) async {
    final radio = _Radio(
      base: teleModeAllowFlags,
      loc: teleModeAllowFlags,
      lat: 36.6,
      lon: -121.9,
      saved: [_dave, _carol, _erin],
    );
    await open(tester, radio);
    expect(find.text('Contacts you allowed can see your location'),
        findsOneWidget);
    expect(find.text('Location · Battery'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Erin'), findsNothing, reason: 'Erin may not ask');
    expect(tester.getTopLeft(find.text('Carol')).dy,
        lessThan(tester.getTopLeft(find.text('Dave')).dy),
        reason: 'who gets the location comes first');

    await tapText(tester, hide);
    expect(radio.writes, [(teleModeAllowFlags, teleModeDeny, teleModeDeny, 0)],
        reason: 'battery stays; location and adverts off');
    expect(find.text(nobody), findsOneWidget);
    expect(find.text(hide), findsNothing);
    expect(find.text('Battery'), findsNWidgets(2));
  });

  testWidgets('a contact row opens their permissions', (tester) async {
    await open(
      tester,
      _Radio(
        base: teleModeAllowFlags,
        loc: teleModeAllowFlags,
        lat: 36.6,
        lon: -121.9,
        saved: [_carol],
      ),
    );
    await tapText(tester, 'Carol');
    expect(find.text('Telemetry'), findsOneWidget);
    expect(find.text('Telemetry Location'), findsOneWidget);
  });

  testWidgets('on Allow all one row stands for every contact', (tester) async {
    await open(
      tester,
      _Radio(
        base: teleModeAllowAll,
        loc: teleModeAllowAll,
        lat: 36.6,
        lon: -121.9,
        saved: [_carol, _dave],
      ),
    );
    expect(find.text('All your contacts can see your location'),
        findsOneWidget);
    expect(find.text('All your contacts (2)'), findsOneWidget);
    expect(find.text('Location · Battery'), findsOneWidget);
    expect(find.text('Carol'), findsNothing);
  });

  testWidgets('adverts: everyone, and the switch turns them off',
      (tester) async {
    final radio = _Radio(advert: 1, lat: 36.6, lon: -121.9);
    await open(tester, radio);
    expect(find.text('Everyone who hears your radio can see your location'),
        findsOneWidget);
    expect(find.text('None. Your radio answers no telemetry requests.'),
        findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(radio.writes, [(teleModeDeny, teleModeDeny, teleModeDeny, 0)]);
    expect(find.text(nobody), findsOneWidget);
  });

  testWidgets('fits a small phone in German', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: _Radio(
          base: teleModeAllowFlags,
          loc: teleModeAllowFlags,
          advert: 1,
          lat: 36.6,
          lon: -121.9,
          saved: [_carol, _dave],
        ),
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: LocationSharingButton())),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Meinen Standort vor allen verbergen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no position yet: nobody sees it, and it can still be hidden',
      (tester) async {
    await open(tester, _Radio(advert: 1));
    expect(find.text('Your radio has no location yet, so nobody can see it'),
        findsOneWidget);
    expect(find.text(hide), findsOneWidget);
  });
}
