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
import 'package:meshtrax/utils/telemetry_dialog.dart';

// The radio's privacy settings decide what a contact's permission does: on
// Deny all it does nothing, and the firmware answers only when base is
// allowed (owner, 2026-10-26: ask, and offer "Allow by contact flags").
class _Radio extends MeshCoreConnector {
  _Radio({
    required this.book,
    this.base = teleModeAllowFlags,
    this.loc = teleModeAllowFlags,
    this.env = teleModeAllowFlags,
  });

  List<Contact> book;
  int base, loc, env;
  final modeWrites = <(int, int, int)>[];
  final flagWrites = <(bool?, bool?, bool?)>[];

  @override
  bool get isConnected => true;
  @override
  List<Contact> get contacts => book;
  @override
  int get telemetryModeBase => base;
  @override
  int get telemetryModeLoc => loc;
  @override
  int get telemetryModeEnv => env;

  @override
  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
    int multiAcks,
  ) async {
    modeWrites.add((base, location, env));
    this.base = base;
    loc = location;
    this.env = env;
  }

  @override
  Future<void> setContactFlags(
    Contact contact, {
    bool? isFavorite,
    bool? teleBase,
    bool? teleLoc,
    bool? teleEnv,
    bool? remoteCli,
  }) async {
    flagWrites.add((teleBase, teleLoc, teleEnv));
  }
}

Contact _alice({int flags = 0}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0xA1 + i)),
      name: 'Alice',
      type: advTypeChat,
      flags: flags,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 10, 26),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  /// Opens the dialog for [shown], the copy a screen may hold; the radio's
  /// own row is in [radio]'s book.
  Future<void> open(WidgetTester tester, _Radio radio, Contact shown) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: radio,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showTelemetryPermissionsDialog(context, shown),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  SwitchListTile tile(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));

  testWidgets('the switches show the radio\'s live copy of the contact',
      (tester) async {
    final radio = _Radio(
        book: [_alice(flags: contactFlagTeleBase | contactFlagTeleLoc)]);
    await open(tester, radio, _alice());
    expect(tile(tester, 'Telemetry Base').value, isTrue);
    expect(tile(tester, 'Telemetry Location').value, isTrue);
    expect(tile(tester, 'Telemetry Environment').value, isFalse);
  });

  testWidgets('Save writes only what changed, and nothing when nothing did',
      (tester) async {
    final radio = _Radio(book: [_alice(flags: contactFlagTeleBase)]);
    await open(tester, radio, _alice());
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(radio.flagWrites, isEmpty);

    await open(tester, radio, _alice());
    await tester.tap(find.text('Telemetry Environment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(radio.flagWrites, [(null, null, true)]);
    expect(radio.modeWrites, isEmpty, reason: 'nothing was blocked');
  });

  testWidgets('location and environment wait for base', (tester) async {
    final radio = _Radio(book: [_alice()]);
    await open(tester, radio, _alice());
    expect(tile(tester, 'Telemetry Location').onChanged, isNull);
    expect(tile(tester, 'Telemetry Environment').onChanged, isNull);
    await tester.tap(find.text('Telemetry Base'));
    await tester.pumpAndSettle();
    expect(tile(tester, 'Telemetry Location').onChanged, isNotNull);
  });

  testWidgets(
      'switching on location the radio denies asks, and the answer lets '
      'contact flags decide base and location', (tester) async {
    final radio = _Radio(
      book: [_alice(flags: contactFlagTeleBase)],
      base: teleModeDeny,
      loc: teleModeDeny,
      env: teleModeAllowAll,
    );
    await open(tester, radio, _alice());
    expect(find.text('Your radio shares this with nobody (Deny all)'),
        findsNWidgets(3),
        reason: 'every part needs base, even environment on Allow all');
    await tester.tap(find.text('Telemetry Location'));
    await tester.pumpAndSettle();

    expect(find.text('Blocked by your radio'), findsOneWidget);
    expect(find.text('Telemetry Base Mode: Deny all → Allow by contact flags'),
        findsOneWidget);
    expect(
        find.text('Telemetry Location Mode: Deny all → Allow by contact flags'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Allow by contact flags'));
    await tester.pumpAndSettle();

    expect(radio.modeWrites,
        [(teleModeAllowFlags, teleModeAllowFlags, teleModeAllowAll)],
        reason: 'environment was not in the way and keeps Allow all');
    expect(find.text('Your radio shares this with nobody (Deny all)'),
        findsNothing);
    expect(tile(tester, 'Telemetry Location').value, isTrue);
  });

  testWidgets('Not now changes no setting and keeps the switch on',
      (tester) async {
    final radio = _Radio(book: [_alice()], base: teleModeDeny);
    await open(tester, radio, _alice());
    await tester.tap(find.text('Telemetry Base'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(radio.modeWrites, isEmpty);
    expect(tile(tester, 'Telemetry Base').value, isTrue);
  });

  testWidgets('a part the radio gives everyone says so, and asks nothing',
      (tester) async {
    final radio = _Radio(
        book: [_alice()], base: teleModeAllowAll, loc: teleModeAllowAll);
    await open(tester, radio, _alice());
    expect(find.text('Your radio shares this with everyone (Allow all)'),
        findsNWidgets(2));
    await tester.tap(find.text('Telemetry Base'));
    await tester.pumpAndSettle();
    expect(find.text('Blocked by your radio'), findsNothing);
  });
}
