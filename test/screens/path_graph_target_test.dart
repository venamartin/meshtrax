import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

// The Pathfinder screen resolves what it was asked to show to the right
// contact and view: a hash picked from the graph's list opens its contact
// (a room as a room), and a chat contact the graph also met as a hop opens
// in the contact view DMs use, with the repeater view one tap away.
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

Contact _contact(int first, String name, int type) => Contact(
      publicKey: Uint8List.fromList([first, 0x77, ...List.filled(30, 0x11)]),
      name: name,
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime(2026, 10, 14),
    );

void main() {
  final room = _contact(0x3F, 'HARBOUR ROOM', advTypeRoom);
  final bob = _contact(0x5C, 'BOB', advTypeChat);

  late PathGraphService service;
  late _Connector connector;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> pump(WidgetTester tester, String target) async {
    await tester.runAsync(() async {
      settings = AppSettingsService();
      await settings.loadSettings();
      connector = _Connector([room, bob]);
      service = PathGraphService();
      await service.start(connector, database: NativeDatabase.memory());
      // The room adverted (the graph keeps its key); Bob's hash 5C77 was
      // seen as a hop in someone's path.
      service.graph!.ingestNode('3F77', name: 'HARBOUR ROOM',
          pubkey: room.publicKeyHex);
      service.graph!.ingestNode('5C77');
    });
    // Wide and tall: every card is built (the phone-width layout has its
    // own test).
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
        home: PathGraphScreen(initialTargetKey: target),
      ),
    ));
    await tester.pump();
  }

  Future<void> stop(WidgetTester tester) =>
      tester.runAsync(() => service.stop());

  testWidgets('a room picked by its hash opens as the room', (tester) async {
    await pump(tester, '3F77');
    expect(find.text('HARBOUR ROOM'), findsWidgets);
    expect(find.textContaining('no contact record'), findsNothing);
    await stop(tester);
  });

  testWidgets('a chat contact also seen as a hop opens as a contact',
      (tester) async {
    await pump(tester, bob.publicKeyHex);
    expect(find.textContaining('also seen as a repeater hop'), findsOneWidget);
    expect(find.text('Show as a repeater'), findsOneWidget);

    await tester.tap(find.text('Show as a repeater'));
    await tester.pump();
    expect(find.text('Show as a contact'), findsOneWidget);
    await stop(tester);
  });
}
