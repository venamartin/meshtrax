import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/repeaters_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/repeater_login_dialog.dart';

// New radios no longer save repeaters by themselves, so the list is full of
// ones only heard. Looking at one must not save it: a full table would overwrite
// a person to make room for a login the user then cancels.
class _Radio extends MeshCoreConnector {
  final sent = <int>[];
  final table = <String, Uint8List>{};

  @override
  bool get isConnected => true;

  /// Answers as companion_radio MyMesh.cpp does for these two commands.
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data[0]);
    final key = data.length >= 33 ? pubKeyToHex(data.sublist(1, 33)) : '';
    void reply(List<int> frame) =>
        scheduleMicrotask(() => handleFrameForTest(frame));
    if (data[0] == cmdAddUpdateContact || data[0] == cmdRemoveContact) {
      if (data[0] == cmdAddUpdateContact) table[key] = data.sublist(1);
      reply([respCodeOk]);
    } else if (data[0] == cmdGetContactByKey) {
      final saved = table[key];
      reply(saved == null ? [respCodeErr, 2] : [respCodeContact, ...saved]);
    }
  }
}

Uint8List _heardRepeater(String name) {
  final w = BytesBuilder();
  w.addByte(pushCodeNewAdvert);
  w.add(Uint8List.fromList(List.generate(32, (i) => 0x70 + i)));
  w.addByte(advTypeRepeater);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add([1, 0, 0, 0]);
  w.add(Uint8List(8));
  return w.toBytes();
}

void main() {
  late _Radio radio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    radio = _Radio()..handleFrameForTest(_heardRepeater('Hilltop'));
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RepeatersScreen(),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Hilltop'), findsOneWidget);
  }

  void expectNotSaved() {
    expect(radio.sent, isNot(contains(cmdAddUpdateContact)));
    expect(radio.contacts, isEmpty);
  }

  testWidgets('tapping one and cancelling the login saves nothing', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Hilltop'));
    await settle(tester);
    expect(find.byType(RepeaterLoginDialog), findsOneWidget);
    expectNotSaved();

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expectNotSaved();
  });

  testWidgets('holding one to see its options saves nothing', (tester) async {
    await open(tester);
    await tester.longPress(find.text('Hilltop'));
    await settle(tester);
    expect(find.text('Ping'), findsOneWidget);
    expectNotSaved();
  });

  testWidgets('making one a favorite saves it, and it is listed once', (
    tester,
  ) async {
    await open(tester);
    await tester.longPress(find.text('Hilltop'));
    await settle(tester);
    await tester.tap(find.text('Add to favorites'));
    await settle(tester);
    await settle(tester);
    await settle(tester);

    expect(radio.contacts.single.isFavorite, isTrue);
    expect(radio.allContacts, hasLength(1));
    expect(find.text('Hilltop'), findsOneWidget);
    // The route write's cache save.
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('one only heard offers no share by advert', (tester) async {
    await open(tester);
    await tester.longPress(find.text('Hilltop'));
    await settle(tester);
    expect(find.text('Share contact by advert'), findsNothing);
  });

  testWidgets('deleting one during a download still asks the radio', (
    tester,
  ) async {
    await radio.getContacts();
    await open(tester);
    await tester.longPress(find.text('Hilltop'));
    await settle(tester);
    await tester.tap(find.text('Delete Contact').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    expect(radio.sent, contains(cmdRemoveContact));
  });

  testWidgets('deleting one sends nothing to the radio', (tester) async {
    await open(tester);
    await tester.longPress(find.text('Hilltop'));
    await settle(tester);
    await tester.tap(find.text('Delete Contact').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    expect(radio.sent, isNot(contains(cmdRemoveContact)));
    expect(radio.allContacts, isEmpty);
  });
}
