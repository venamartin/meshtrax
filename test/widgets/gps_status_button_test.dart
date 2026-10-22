import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/gps_status_button.dart';

class _Radio extends MeshCoreConnector {
  _Radio({this.gps});

  /// The radio's `gps` setting: null when it has no GPS module.
  String? gps;
  final gpsSets = <bool>[];
  var viewers = 0;

  @override
  bool get isConnected => true;
  @override
  bool get hasGps => gps != null;
  @override
  bool get gpsOn => gps == '1';
  @override
  Future<void> setGps(bool on) async {
    gpsSets.add(on);
    gps = on ? '1' : '0';
    notifyListeners();
  }

  @override
  void addSelfPositionViewer() => viewers++;
  @override
  void removeSelfPositionViewer() => viewers--;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> pump(WidgetTester tester, _Radio radio) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
        ChangeNotifierProvider(create: (_) => AppSettingsService()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: GpsStatusButton())),
      ),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('no GPS module: no icon', (tester) async {
    await pump(tester, _Radio());
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the icon says on or off', (tester) async {
    final radio = _Radio(gps: '0');
    await pump(tester, radio);
    expect(find.byIcon(Icons.gps_off), findsOneWidget);
    radio.gps = '1';
    radio.notifyListeners();
    await settle(tester);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('the dialog: position, altitude, and the switch', (tester) async {
    final radio = _Radio(gps: '1');
    await pump(tester, radio);
    await tester.tap(find.byType(IconButton));
    await settle(tester);
    expect(radio.viewers, 1, reason: 'reads every 10 s while open');
    expect(find.text('Asking the radio...'), findsOneWidget);

    radio.selfGps.value = (
      latitude: 36.9558,
      longitude: -121.7293,
      altitude: 34.3,
      at: DateTime.now(),
    );
    await tester.pump();
    expect(find.text('36.9558, -121.7293'), findsOneWidget);
    expect(find.text('34 m'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(radio.gpsSets, [false]);
    expect(find.text('36.9558, -121.7293'), findsNothing);
    expect(find.textContaining('saves the radio'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(radio.viewers, 0);
  });
}
