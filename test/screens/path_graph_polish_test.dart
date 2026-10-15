import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/screens/path_graph_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Pathfinder screen polish: it fits a phone, says things in plain words,
// and asks before it wipes what it learned.
class _Connector extends MeshCoreConnector {
  _Connector(this.list);
  final List<Contact> list;

  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;

  @override
  List<Contact> get contacts => list;

  @override
  List<Contact> get allContacts => list;
}

final _longName = 'A' * 40;
final _bob = Contact(
  publicKey: Uint8List.fromList([0x5C, 0x77, ...List.filled(30, 0x11)]),
  name: _longName,
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 10, 14),
);

void main() {
  late PathGraphService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> pump(WidgetTester tester,
      {required double width, double textScale = 1, Contact? target}) async {
    late AppSettingsService settings;
    final contact = target ?? _bob;
    final connector = _Connector([contact]);
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      service = PathGraphService();
      await service.start(connector, database: NativeDatabase.memory());
      service.graph!.ingestNode('A277', name: 'HILL');
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 6000);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: PathGraphScreen(initialTargetKey: contact.publicKeyHex),
      ),
    ));
    await tester.pump();
  }

  testWidgets('fits a 360 dp phone with a long name and large text',
      (tester) async {
    await pump(tester, width: 360, textScale: 1.5);
    expect(tester.takeException(), isNull, reason: 'no layout overflow');
    expect(find.textContaining('reaches $_longName'), findsWidgets);
    await tester.runAsync(() => service.stop());
  });

  testWidgets('Clear learned data asks first', (tester) async {
    await pump(tester, width: 1200);
    Future<void> openClear() async {
      await tester.tap(find.text('Backup & restore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear learned data'));
      await tester.pumpAndSettle();
    }

    await openClear();
    expect(find.text('Clear learned data?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.graph!.snapshot().nodes, contains('A277'),
        reason: 'Cancel keeps everything');

    await openClear();
    await tester.runAsync(() async {
      await tester.tap(find.text('Clear'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(service.graph!.snapshot().nodes, isEmpty);
    await tester.runAsync(() => service.stop());
  });

  testWidgets('Trace says which route goes out and that the way back is a guess',
      (tester) async {
    final routed = _bob.copyWith(
      pathLength: 3,
      path: Uint8List.fromList([0xA2, 0x77, 0x5B, 0x98, 0x88, 0x02]),
      pathHashSize: 2,
    );
    await pump(tester, width: 1200, target: routed);
    expect(find.text('Trace (3 hops)'), findsOneWidget);
    expect(find.textContaining("radio's route A277 › 5B98 › 8802"),
        findsOneWidget);
    expect(find.textContaining('back the same way reversed'), findsOneWidget);
    await tester.runAsync(() => service.stop());
  });

  test('every no-route reason has plain words, in every direction', () {
    for (final reason in FloodReason.values) {
      for (final (back, fromRepeater) in [
        (false, false),
        (true, false),
        (true, true),
      ]) {
        final text =
            floodReasonText(reason, back: back, fromRepeater: fromRepeater);
        expect(text, isNotEmpty);
        expect(text, isNot(contains(reason.name)));
        expect(text, isNot(contains('corridor')));
      }
    }
  });
}
