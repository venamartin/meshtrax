import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/screens/path_graph_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Owner, 2026-10-19: a repeater's view says whether Pathfinder treats it as
// moving and why, with the user's three-way switch (moves, moves with me,
// stays put) beside "let Pathfinder decide".
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;

  @override
  List<Contact> get contacts => const [];

  @override
  List<Contact> get allContacts => const [];
}

void main() {
  late PathGraphService service;
  late _Connector connector;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      connector = _Connector();
      service = PathGraphService();
      await service.start(connector, database: NativeDatabase.memory());
      service.graph!.ingestNode('C882', name: 'WHITE_WHALE');
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
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const PathGraphScreen(initialTargetKey: 'C882'),
      ),
    ));
    await tester.pump();
  }

  testWidgets('the switch tags a repeater and the list shows it',
      (tester) async {
    await pump(tester);
    expect(find.text('Does it move?'), findsOneWidget);
    expect(find.text('Pathfinder treats it as a fixed repeater.'),
        findsOneWidget);
    expect(find.textContaining('Moving repeaters'), findsNothing);

    await tester.tap(find.text('Moves with me'));
    await tester.pump();
    expect(service.graph!.movingStatus('C882')!.reason,
        MovingReason.manualWithMe);
    expect(find.text('Moving repeaters (1)'), findsOneWidget);
    expect(find.textContaining('It counts as hearing me any time'),
        findsOneWidget);

    await tester.tap(find.text('Let Pathfinder decide'));
    await tester.pump();
    expect(service.graph!.movingStatus('C882'), isNull);
    expect(find.textContaining('Moving repeaters'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(() => service.stop());
  });

  test('every reason has plain words', () {
    for (final reason in MovingReason.values) {
      expect(movingReasonText(MovingStatus(reason, acts: true)), isNotEmpty);
    }
  });
}
