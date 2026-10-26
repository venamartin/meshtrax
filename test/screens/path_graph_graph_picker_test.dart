import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/path_graph_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The Pathfinder screen says which graph is open and lets the user keep
// several for one preset (owner, 2026-10-26: Washington on the US preset).
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  int? get currentFreqHz => 910525000;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('a new graph for Washington, and back again', (tester) async {
    final connector = _Connector();
    late AppSettingsService settings;
    late PathGraphService service;
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      service = PathGraphService();
      await service.start(connector,
          openDatabase: (_) => NativeDatabase.memory());
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 6000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
        ChangeNotifierProvider<PathGraphService>.value(value: service),
        ChangeNotifierProvider<AppSettingsService>.value(value: settings),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: PathGraphScreen(),
      ),
    ));
    await tester.pump();

    Future<void> settle() async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    expect(find.text('Graph: 910.525 MHz · 62.5 kHz · SF7 · CR5'),
        findsOneWidget);
    await tester.tap(find.text('Change'));
    await settle();
    expect(find.text('Pathfinder graphs'), findsOneWidget);

    await tester.tap(find.text('New graph'));
    await settle();
    await tester.enterText(
        find.widgetWithText(TextField, 'For example, Washington'), 'Washington');
    await tester.tap(find.text('Create'));
    await settle();
    expect(service.graphEntry!.label, 'Washington');
    expect(find.text('Graph: Washington'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await settle();
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('910.525 MHz · 62.5 kHz · SF7 · CR5')));
    await settle();
    expect(service.graphEntry!.isDefault, isTrue);
    expect(find.text('Graph: 910.525 MHz · 62.5 kHz · SF7 · CR5'),
        findsOneWidget);

    await tester.runAsync(() => service.stop());
  });
}
