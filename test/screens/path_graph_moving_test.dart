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

// Owner, 2026-10-19: a repeater's info sheet (opened from a doorstep table
// row or the moving-repeaters list — a car repeater that never adverts
// shows up nowhere else) says whether it moves; tapping that line opens a
// dialog with the switch (moves, moves with me, stays put, or let
// Pathfinder decide). The sheet must still close with a swipe down after a
// pick (field: a tall sheet only scrolled).
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

  Future<void> pump(WidgetTester tester,
      {String? target, Size size = const Size(1200, 6000)}) async {
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      connector = _Connector();
      service = PathGraphService();
      await service.start(connector, database: NativeDatabase.memory());
      final graph = service.graph!
        ..setRadioIdentity('ab' * 32, 2)
        ..ingestNode('C882', name: 'WHITE_WHALE');
      // C882 answered a Discover: it hears me, a row in Direct repeaters.
      graph.observeDiscoverResults(
          [const DiscoverResponse(repeaterHash: 'C882', uplinkSnr: 11, rxSnr: 12)],
          failureEpisode: false);
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
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
        home: PathGraphScreen(initialTargetKey: target),
      ),
    ));
    await tester.pump();
  }

  Future<void> stop(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(() => service.stop());
  }

  testWidgets('a direct repeater row opens the sheet; the switch is a dialog',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('Moving repeaters'), findsNothing);

    await tester.tap(find.text('C882'));
    await tester.pumpAndSettle();
    expect(find.text('Times it heard me'), findsOneWidget,
        reason: 'the row facts stay in the sheet');
    expect(find.text('Pathfinder treats it as a fixed repeater.'),
        findsOneWidget);

    await tester.tap(find.text('Does it move?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moves with me'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing,
        reason: 'picking one closes the dialog');
    expect(service.graph!.movingStatus('C882')!.reason,
        MovingReason.manualWithMe);
    expect(find.textContaining('It counts as hearing me any time'),
        findsOneWidget, reason: 'the sheet line updates at once');

    // Closed, the screen lists it; its entry opens the same sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Moving repeaters (1)'), findsOneWidget);
    await tester.tap(find.text('WHITE_WHALE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Does it move?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let Pathfinder decide'));
    await tester.pumpAndSettle();
    expect(service.graph!.movingStatus('C882'), isNull);

    await stop(tester);
  });

  testWidgets('on a phone the sheet still closes with a swipe after a pick',
      (tester) async {
    await pump(tester, size: const Size(412, 915));
    await tester.tap(find.text('C882'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Does it move?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moves'));
    await tester.pumpAndSettle();
    expect(find.text('Times it heard me'), findsOneWidget);

    await tester.fling(
        find.text('Times it heard me'), const Offset(0, 700), 2500);
    await tester.pumpAndSettle();
    expect(find.text('Times it heard me'), findsNothing,
        reason: 'the swipe closed the sheet');
    expect(service.graph!.movingStatus('C882')!.reason, MovingReason.manual);

    await stop(tester);
  });

  testWidgets("a repeater's own view no longer carries the switch",
      (tester) async {
    await pump(tester, target: 'C882');
    expect(find.text('Does it move?'), findsNothing);
    await stop(tester);
  });

  test('every reason has plain words', () {
    for (final reason in MovingReason.values) {
      expect(movingReasonText(MovingStatus(reason, acts: true)), isNotEmpty);
    }
  });
}
