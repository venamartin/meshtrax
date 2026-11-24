import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/screens/location_people_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/icon_help.dart';
import 'package:meshtrax/widgets/location_icon.dart';
import 'package:meshtrax/widgets/my_location_button.dart';

// One My location button for the radio's GPS and who can see its location
// (Martin, 2026-11-21): the shape is who, the fill is the GPS.
class _Radio extends MeshCoreConnector {
  _Radio({
    this.base = teleModeDeny,
    this.loc = teleModeDeny,
    this.advert = 0,
    this.gps,
    this.fresh = false,
    List<Contact> saved = const [],
  }) : saved = [...saved];

  int base, loc, advert;

  /// The radio's `gps` setting: null when it has no GPS module.
  String? gps;
  bool fresh;
  bool connected = true;
  final List<Contact> saved;
  final latest = <String, Message>{};

  /// (base, location, environment, advert) as written to the radio.
  final writes = <(int, int, int, int)>[];
  final gpsSets = <bool>[];

  /// Each contact write: name, base, location.
  final flagWrites = <(String, bool?, bool?)>[];
  var viewers = 0;

  @override
  bool get isConnected => connected;
  @override
  int get telemetryModeBase => base;
  @override
  int get telemetryModeLoc => loc;
  @override
  int get advertLocationPolicy => advert;
  @override
  bool get hasGps => gps != null;
  @override
  bool get gpsOn => gps == '1';
  @override
  bool get selfGpsIsFresh => gpsOn && fresh;
  @override
  DateTime? get selfGpsChangedAt =>
      fresh ? DateTime.now().subtract(const Duration(seconds: 4)) : null;
  @override
  List<Contact> get contacts => saved;
  @override
  Message? latestContactMessage(Contact contact) =>
      latest[contact.publicKeyHex];

  @override
  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
    int multiAcks,
  ) async {
    writes.add((base, location, env, advert));
    this.base = base;
    loc = location;
    this.advert = advert;
    notifyListeners();
  }

  @override
  Future<void> refreshRadioSettings() async {}

  @override
  Future<void> setGps(bool on) async {
    gpsSets.add(on);
    gps = on ? '1' : '0';
    notifyListeners();
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
    flagWrites.add((contact.name, teleBase, teleLoc));
    final i = saved.indexWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    var flags = saved[i].flags;
    int set(int flags, int bit, bool? on) =>
        on == null ? flags : (on ? flags | bit : flags & ~bit);
    flags = set(flags, contactFlagTeleBase, teleBase);
    flags = set(flags, contactFlagTeleLoc, teleLoc);
    saved[i] = saved[i].copyWith(flags: flags);
    notifyListeners();
  }

  @override
  void addSelfPositionViewer() => viewers++;
  @override
  void removeSelfPositionViewer() => viewers--;
}

/// Trip setup as the people list sees it: who it lets ask, and Remove.
class _Trip extends ChangeNotifier implements TripService {
  _Trip(this.memberContacts);

  @override
  final List<Contact> memberContacts;
  final removed = <String>[];

  @override
  bool get active => true;
  @override
  void removeMember(Contact contact) => removed.add(contact.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Trax extends ChangeNotifier implements TraxService {
  _Trax(this.setup);

  @override
  final TraxSetup setup;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Contact _contact(String name, int seed, {int flags = 0}) => Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
  name: name,
  type: advTypeChat,
  flags: flags,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 11, 20),
  isActive: true,
);

const _asks = contactFlagTeleBase | contactFlagTeleLoc;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> pump(
    WidgetTester tester,
    _Radio radio, {
    Widget? home,
    _Trip? trip,
    _Trax? trax,
  }) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
        ChangeNotifierProvider(create: (_) => AppSettingsService()),
        if (trip != null)
          ChangeNotifierProvider<TripService>.value(value: trip),
        if (trax != null)
          ChangeNotifierProvider<TraxService>.value(value: trax),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home ?? const Scaffold(body: Center(child: MyLocationButton())),
      ),
    ),
  );

  LocationIcon icon(WidgetTester tester) =>
      tester.widget<LocationIcon>(find.byType(LocationIcon).first);

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  bool switchOn(WidgetTester tester, String title) => tester
      .widget<SwitchListTile>(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(SwitchListTile),
        ),
      )
      .value;

  testWidgets('the shape is who can see it, the fill the GPS; red when '
      'someone can and there is no fix', (tester) async {
    final carol = _contact('Carol', 0x10, flags: _asks);
    final cases = <(_Radio, LocationAudience, LocationGps, String)>[
      (_Radio(), LocationAudience.onlyYou, LocationGps.off, 'Only you'),
      (
        _Radio(gps: '0'),
        LocationAudience.onlyYou,
        LocationGps.off,
        'Only you · GPS off',
      ),
      (
        _Radio(gps: '1', fresh: true),
        LocationAudience.onlyYou,
        LocationGps.on,
        'Only you · GPS on',
      ),
      (
        _Radio(gps: '1'),
        LocationAudience.onlyYou,
        LocationGps.noFix,
        'Only you · GPS on, no fix yet',
      ),
      (
        _Radio(
          base: teleModeAllowFlags,
          loc: teleModeAllowFlags,
          gps: '1',
          fresh: true,
          saved: [carol],
        ),
        LocationAudience.people,
        LocationGps.on,
        'People you picked can ask · GPS on',
      ),
      (
        _Radio(
          base: teleModeAllowAll,
          loc: teleModeAllowAll,
          gps: '0',
          saved: [_contact('Dave', 0x40)],
        ),
        LocationAudience.people,
        LocationGps.off,
        'Everyone saved on your radio can ask · GPS off',
      ),
      (
        _Radio(advert: 1, gps: '1', fresh: true),
        LocationAudience.adverts,
        LocationGps.on,
        'In your adverts · GPS on',
      ),
      (
        _Radio(advert: 1, gps: '1'),
        LocationAudience.adverts,
        LocationGps.noFix,
        'In your adverts · GPS on, no fix yet',
      ),
    ];
    for (final (radio, audience, gps, words) in cases) {
      await pump(tester, radio);
      expect((icon(tester).audience, icon(tester).gps), (audience, gps));
      expect(find.byTooltip(words), findsOneWidget);
      final scheme = Theme.of(tester.element(find.byType(LocationIcon)))
          .colorScheme;
      expect(
        icon(tester).color,
        audience == LocationAudience.onlyYou
            ? scheme.onSurfaceVariant
            : gps == LocationGps.noFix
            ? scheme.error
            : scheme.primary,
        reason: words,
      );
    }
  });

  testWidgets('no button while disconnected', (tester) async {
    await pump(tester, _Radio()..connected = false);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the sheet: the icon in words, and each switch changes only '
      'its own setting', (tester) async {
    final radio = _Radio(
      base: teleModeAllowFlags,
      loc: teleModeAllowFlags,
      gps: '1',
      fresh: true,
      saved: [_contact('Carol', 0x10, flags: _asks)],
    );
    radio.selfGps.value = (
      latitude: 36.457,
      longitude: -116.866,
      altitude: 0,
      at: DateTime.now(),
    );
    await pump(tester, radio);
    await openSheet(tester);
    expect(find.text('My location'), findsOneWidget);
    expect(find.text('People you picked can ask · GPS on'), findsNWidgets(1));
    expect(radio.viewers, 1, reason: 'the GPS is asked every 10 s meanwhile');
    expect(find.textContaining('Fix 4s ago · '), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);

    await tapText(tester, 'In my adverts');
    expect(radio.writes, [
      (teleModeAllowFlags, teleModeAllowFlags, teleModeDeny, 1),
    ]);
    expect(find.text('In your adverts · GPS on'), findsOneWidget);

    await tapText(tester, 'Radio GPS');
    expect(radio.gpsSets, [false]);
    expect(switchOn(tester, 'Radio GPS'), isFalse);
    expect(find.textContaining('Off saves battery. Last fix '), findsOneWidget);
    expect(radio.writes, hasLength(1), reason: 'the GPS is its own setting');

    Navigator.pop(tester.element(find.text('My location')));
    await tester.pumpAndSettle();
    expect(radio.viewers, 0);
  });

  testWidgets('a radio with no GPS has no GPS row', (tester) async {
    await pump(tester, _Radio());
    await openSheet(tester);
    expect(find.text('Radio GPS'), findsNothing);
    expect(find.text('In my adverts'), findsOneWidget);
  });

  testWidgets('who can ask: Nobody, the names, or on allow all a red line '
      'and Pick people instead', (tester) async {
    await pump(tester, _Radio());
    await openSheet(tester);
    expect(find.text('Nobody'), findsOneWidget);

    final radio = _Radio(
      base: teleModeAllowAll,
      loc: teleModeAllowAll,
      saved: [_contact('Carol', 0x10), _contact('Dave', 0x40)],
    );
    await pump(tester, radio);
    await openSheet(tester);
    final line = find.text('Everyone saved on your radio (2)');
    expect(line, findsOneWidget);
    final scheme = Theme.of(tester.element(line)).colorScheme;
    expect(tester.widget<Text>(line).style?.color, scheme.error);

    await tapText(tester, 'Pick people instead');
    expect(radio.writes, [
      (teleModeAllowFlags, teleModeAllowFlags, teleModeDeny, 0),
    ]);
    expect(find.text('Nobody'), findsOneWidget);
    expect(find.text('Pick people instead'), findsNothing);
  });

  testWidgets('the people list: Add someone gives a favourite both '
      'permissions and starts answering by contact; × takes them off', (
    tester,
  ) async {
    final dave = _contact('Dave', 0x40, flags: contactFlagFavorite);
    final radio = _Radio(saved: [_contact('Carol', 0x10), dave]);
    await pump(tester, radio, home: const LocationPeopleScreen());
    expect(find.text('Dave'), findsNothing);

    await tapText(tester, 'Add someone');
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Search 2 contacts'), findsOneWidget);
    await tapText(tester, 'Dave');
    expect(radio.flagWrites, [('Dave', true, true)]);
    expect(radio.writes, [
      (teleModeAllowFlags, teleModeAllowFlags, teleModeDeny, 0),
    ]);
    expect(find.byType(LocationPeopleScreen), findsOneWidget);
    expect(find.text('Dave'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(radio.flagWrites.last, ('Dave', false, false));
    expect(find.text('Dave'), findsNothing);
  });

  testWidgets('Add someone: the favourites, then the latest conversations; '
      'a search covers everyone', (tester) async {
    final erin = _contact('Erin', 0x70);
    final fay = _contact('Fay', 0x90);
    final radio = _Radio(
      base: teleModeAllowFlags,
      loc: teleModeAllowFlags,
      saved: [
        _contact('Ana', 0x10, flags: contactFlagFavorite | _asks),
        erin,
        fay,
        _contact('Gus', 0xA0),
      ],
    );
    Message said(Contact c, int day) => Message(
      senderKey: c.publicKey,
      text: 'hi',
      timestamp: DateTime(2026, 11, day),
      isOutgoing: false,
    );
    radio.latest[erin.publicKeyHex] = said(erin, 20);
    radio.latest[fay.publicKeyHex] = said(fay, 22);
    await pump(tester, radio, home: const LocationPeopleScreen());
    await tapText(tester, 'Add someone');

    expect(find.text('Can ask'), findsOneWidget, reason: 'Ana, a favourite');
    expect(find.text('Recent messages'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Fay')).dy,
      lessThan(tester.getTopLeft(find.text('Erin')).dy),
      reason: 'the newest first',
    );
    expect(find.text('Gus'), findsNothing);

    await tester.enterText(find.byType(TextField), 'gu');
    await tester.pumpAndSettle();
    expect(find.text('Gus'), findsOneWidget);
    expect(find.text('Fay'), findsNothing);
  });

  testWidgets('a trip member says until when, and × lets them go from the '
      'trip', (tester) async {
    final bo = _contact('Bo', 0x11, flags: _asks);
    final radio = _Radio(
      base: teleModeAllowFlags,
      loc: teleModeAllowFlags,
      saved: [
        bo,
        _contact('Carol', 0x10, flags: _asks),
      ],
    );
    final trip = _Trip([bo]);
    await pump(
      tester,
      radio,
      home: const LocationPeopleScreen(),
      trip: trip,
      trax: _Trax(TraxSetup(until: DateTime(2026, 11, 29, 18))),
    );
    expect(find.textContaining('Until '), findsOneWidget);

    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    expect(trip.removed, ['Bo']);
    expect(
      radio.flagWrites,
      isEmpty,
      reason: 'the trip puts back what it gave',
    );
  });

  testWidgets('the help names every icon; the note comes once and opens it', (
    tester,
  ) async {
    await pump(tester, _Radio());
    final context = tester.element(find.byType(MyLocationButton));
    LocationButtonNote.showOnce(context);
    await tester.pumpAndSettle();
    expect(find.text('One location button'), findsOneWidget);
    await tester.tap(find.text('What the icons mean'));
    await tester.pumpAndSettle();
    expect(find.byType(IconHelpSheet), findsOneWidget);
    for (final text in [
      'Radio battery',
      'Repeaters heard',
      'TRAX mode on',
      'People you picked',
      'In your adverts',
      'Dashed: no GPS fix yet',
      'Red: no fix, and someone can see it',
    ]) {
      await tester.ensureVisible(find.text(text));
      expect(find.text(text), findsOneWidget);
    }
    Navigator.pop(tester.element(find.byType(IconHelpSheet)));
    await tester.pumpAndSettle();

    LocationButtonNote.showOnce(context);
    await tester.pumpAndSettle();
    expect(find.text('One location button'), findsNothing);
  });
}
