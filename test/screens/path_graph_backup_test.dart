import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/path_graph_screen.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Pathfinder's Backup names its graph and preset, and a restore says what it
// replaces with what before it does (owner, 2026-11-16: a Washington backup
// went into the home graph on the same preset without a word).
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  int? get currentFreqHz => 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
}

const _vietnam = {
  'key': 'm920250_250000_11_5',
  'freq_hz': 920250,
  'bw_hz': 250000,
  'sf': 11,
  'cr': 5,
};

void main() {
  late PathGraphService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> start(WidgetTester tester) => tester.runAsync(() async {
        service = PathGraphService();
        await service.start(_Connector(),
            openDatabase: (_) => NativeDatabase.memory());
      });

  testWidgets('a backup carries the graph and preset names', (tester) async {
    await start(tester);
    final unnamed = service.backupDocument()!;
    expect(unnamed['preset_name'], 'USA/Canada');
    expect(unnamed.containsKey('graph_name'), isFalse);
    expect(PathGraphService.backupGraphName(unnamed), 'the USA/Canada graph');

    await tester.runAsync(() => service.createGraph('Washington'));
    final named = service.backupDocument()!;
    expect(named['graph_name'], 'Washington');
    expect(PathGraphService.backupGraphName(named), '“Washington”');
    expect(PathGraphService.backupGraphName({}), 'an unnamed graph');
    await tester.runAsync(() => service.stop());
  });

  testWidgets('a backup for another preset is refused in words',
      (tester) async {
    await start(tester);
    expect(service.restoreRefusal(service.backupDocument()!), isNull);
    expect(service.restoreRefusal({}), isNull);
    expect(
        service.restoreRefusal({'mesh': _vietnam}),
        'This backup is for Vietnam, 920.250 MHz · 250 kHz · SF11 · CR5. '
        'The radio is on USA/Canada, 910.525 MHz · 62.5 kHz · SF7 · CR5. '
        'Switch the radio to that preset, then restore.');
    await tester.runAsync(() => service.stop());
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(ChangeNotifierProvider<PathGraphService>.value(
      value: service,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: SizedBox()),
      ),
    ));
    return tester.element(find.byType(SizedBox));
  }

  testWidgets('restore names both graphs and waits for Replace',
      (tester) async {
    await start(tester);
    final home = service.backupDocument()!;
    await tester.runAsync(() => service.createGraph('Washington'));
    final context = await pumpHost(tester);

    var answer = confirmRestore(context, home);
    await tester.pumpAndSettle();
    expect(find.text('Replace this graph?'), findsOneWidget);
    expect(
        find.textContaining('everything Pathfinder knows in “Washington” '
            'with the backup of the USA/Canada graph, saved '),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);

    answer = confirmRestore(context, home);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);

    answer = confirmRestore(context, {...home, 'mesh': _vietnam});
    await tester.pumpAndSettle();
    expect(find.text('Backup for another mesh'), findsOneWidget);
    expect(find.text('Replace'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
    await tester.runAsync(() => service.stop());
  });
}
