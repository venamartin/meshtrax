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
      {required double width,
      double textScale = 1,
      Contact? target,
      void Function(PathGraph graph)? seed}) async {
    late AppSettingsService settings;
    final contact = target ?? _bob;
    final connector = _Connector([contact]);
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      service = PathGraphService();
      await service.start(connector, database: NativeDatabase.memory());
      service.graph!.ingestNode('A277', name: 'HILL');
      seed?.call(service.graph!);
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

  testWidgets('Backup asks about the areas the radio was heard in',
      (tester) async {
    await pump(tester, width: 1200, seed: (graph) {
      graph.setPlace('c1_1', const {});
      graph.observeOwnEcho(Uint8List.fromList([0xA2, 0x77]), 2);
    });
    await tester.tap(find.text('Backup & restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
    expect(find.text('Include where you have been?'), findsOneWidget);
    expect(find.text('Leave it out'), findsOneWidget);
    expect(find.text('Include'), findsOneWidget);
    // Dismissed: nothing is written.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Include where you have been?'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => service.stop());
  });

  group('Trace', () {
    // Delivered on A277 › 1000 › 4F77: Pathfinder's route out to Bob.
    void routeOut(PathGraph g) => g.reportSendResult(
        Uint8List.fromList([0xA2, 0x77, 0x10, 0x00, 0x4F, 0x77]), true,
        contactPubkey: _bob.publicKeyHex, stride: 2);

    testWidgets("goes out and back on Pathfinder's best routes",
        (tester) async {
      // The radio holds another route; it is never traced.
      final routed = _bob.copyWith(
        pathLength: 3,
        path: Uint8List.fromList([0xA2, 0x77, 0x5B, 0x98, 0x88, 0x02]),
        pathHashSize: 2,
      );
      await pump(tester, width: 1200, target: routed, seed: (g) {
        routeOut(g);
        // Heard: a packet that went 4F77 → 1000 → A277 → me.
        g.observePath(Uint8List.fromList([0x4F, 0x77, 0x10, 0x00, 0xA2, 0x77]),
            2, const ObservationOrigin.anonymous());
      });
      expect(find.text('Trace'), findsOneWidget);
      expect(
          find.textContaining("Pathfinder's best route A277 › 1000 › 4F77 "
              'and back on its best route back 4F77 › 1000 › A277'),
          findsOneWidget);
      expect(find.textContaining('5B98'), findsNothing);
      await tester.runAsync(() => service.stop());
    });

    testWidgets('no way back known: the way out reversed, and it says so',
        (tester) async {
      await pump(tester, width: 1200, seed: routeOut);
      expect(find.text('Trace'), findsOneWidget);
      expect(find.textContaining('back the same way reversed'), findsOneWidget);
      expect(find.textContaining('No way back from 4F77'), findsOneWidget);
      await tester.runAsync(() => service.stop());
    });

    testWidgets('no Pathfinder route: no trace, and why', (tester) async {
      await pump(tester, width: 1200);
      expect(find.text('Trace'), findsNothing);
      expect(find.textContaining('No trace:'), findsOneWidget);
      await tester.runAsync(() => service.stop());
    });
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
