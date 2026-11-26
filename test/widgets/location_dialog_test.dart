import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/date_time_helper.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/self_motion.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';
import 'package:meshtrax/widgets/structured_message_dialogs.dart';

import '../helpers/map_fakes.dart';

// The tray's location dialogs and how a location is named (owner,
// 2026-10-27): "My location" is the sender's own position, titled so on
// the air; anything else, or no title, is just a place.
class _Radio extends MeshCoreConnector {
  _Radio({this.lat, this.lon, this.gps = false, this.fresh = false, this.at});
  final double? lat, lon;

  /// GPS on, whether its reading changed lately, and when it last did.
  final bool gps, fresh;
  final DateTime? at;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  bool get gpsOn => gps;
  @override
  bool get selfGpsIsFresh => fresh;
  @override
  DateTime? get selfGpsChangedAt => at;
}

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

const _here = '36.970000, -121.900000';

class _NoNetwork extends HttpOverrides {
  int clients = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    throw StateError('this test has no network');
  }
}

void main() {
  final systemFormats = DateTimeHelper.systemFormats;
  setUp(() async {
    // Times as a US phone writes them, whatever machine runs the tests.
    DateTimeHelper.systemFormats = () => null;
    addTearDown(() => DateTimeHelper.systemFormats = systemFormats);
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  group('a pasted position', () {
    void reads(String text, double lat, double lon) {
      final p = StructuredMessageDialogs.readPosition(text);
      expect(p, isNotNull, reason: text);
      expect(p!.latitude, closeTo(lat, 1e-9), reason: text);
      expect(p.longitude, closeTo(lon, 1e-9), reason: text);
    }

    test('lat, lon with any decimals, with or without the comma', () {
      reads('36.97, -121.9', 36.97, -121.9);
      reads(' 36.970120 -121.902340 ', 36.97012, -121.90234);
      reads('36,-121', 36, -121);
    });

    test('maps links and geo: URIs', () {
      reads('geo:36.97,-121.9', 36.97, -121.9);
      reads('https://www.google.com/maps?q=36.97,-121.9', 36.97, -121.9);
    });

    test('nothing else', () {
      for (final text in ['hello', '91, 10', '10, 181', '0, 0', '36.97', '']) {
        expect(StructuredMessageDialogs.readPosition(text), isNull,
            reason: text);
      }
    });
  });

  group('what a location is called', () {
    late AppLocalizations l10n;
    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });
    LocationMessage parse(String wire) =>
        StructuredMessage.parse(wire)! as LocationMessage;

    test("My location: mine, or the sender's", () {
      final m = parse('Location: My location\n$_here');
      expect(m.isSendersOwn, isTrue);
      expect(
          StructuredMessageCard.locationTitle(l10n, m, isOutgoing: true),
          'My location');
      expect(
          StructuredMessageCard.locationTitle(l10n, m,
              isOutgoing: false, senderName: 'GWQ'),
          "GWQ's location");
      expect(parse('Location: MY LOCATION\n$_here').isSendersOwn, isTrue);
    });

    test('no title is just a place; any other title is shown as written', () {
      final untitled = parse('Location: $_here');
      expect(untitled.isSendersOwn, isFalse);
      expect(
          StructuredMessageCard.locationTitle(l10n, untitled,
              isOutgoing: false, senderName: 'GWQ'),
          'Location');
      expect(
          StructuredMessageCard.locationTitle(
              l10n, parse('Location: Water tap\n$_here'),
              isOutgoing: true),
          'Water tap');
    });
  });

  group('the dialogs', () {
    Future<void> host(
      WidgetTester tester,
      MeshCoreConnector radio,
      void Function(BuildContext) open,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => open(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextField, label);
    FilledButton insert(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Insert'));

    Future<void> done(WidgetTester tester) async {
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
    }

    testWidgets('My location: the radio position, titled My location, and '
        'a note', (tester) async {
      String? wire;
      await host(tester, _Radio(lat: 36.97, lon: -121.9), (context) async {
        wire = await StructuredMessageDialogs.myLocation(
          context,
          context.read<MeshCoreConnector>(),
        );
      });
      expect(find.text(_here), findsOneWidget);
      expect(field('Label'), findsNothing, reason: 'its title is fixed');
      await tester.enterText(field('Note (optional)'), 'at the trailhead');
      await done(tester);
      expect(wire, 'Location: My location\n$_here\nat the trailhead');
    });

    testWidgets('My location without a radio position waits for one',
        (tester) async {
      await host(tester, _Radio(), (context) {
        StructuredMessageDialogs.myLocation(
          context,
          context.read<MeshCoreConnector>(),
        );
      });
      expect(find.text('Your radio has no location yet. Pick one on the map.'),
          findsOneWidget);
      expect(insert(tester).onPressed, isNull);
      await tester.enterText(field('Location'), '36.97, -121.9');
      await tester.pump();
      expect(insert(tester).onPressed, isNotNull);
    });

    testWidgets('Point on map: a pasted position, a title and a note',
        (tester) async {
      String? wire;
      await host(tester, _Radio(), (context) async {
        wire = await StructuredMessageDialogs.pointOnMap(context);
      });
      expect(insert(tester).onPressed, isNull, reason: 'no position yet');
      await tester.enterText(field('Location'), 'hello');
      await tester.pump();
      expect(find.text("Can't read a location here"), findsOneWidget);
      expect(insert(tester).onPressed, isNull);

      await tester.enterText(field('Location'), 'geo:36.97,-121.9');
      await tester.pump();
      expect(find.text(_here), findsOneWidget,
          reason: 'a link shows the coordinates that will be sent');
      await tester.enterText(field('Label'), 'Water tap');
      await tester.enterText(field('Note (optional)'), 'behind the hut');
      await done(tester);
      expect(wire, 'Location: Water tap\n$_here\nbehind the hut');
    });

    testWidgets('Point on map: a short link says how to get its position, '
        'offline', (tester) async {
      await host(tester, _Radio(), (context) {
        StructuredMessageDialogs.pointOnMap(context);
      });
      final network = _NoNetwork();
      HttpOverrides.global = network;
      addTearDown(() => HttpOverrides.global = null);
      await tester.enterText(
        field('Location'),
        'https://maps.app.goo.gl/AbCdEf',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This short link has no location in it. Open it in your '
          'maps app and copy the coordinates.',
        ),
        findsOneWidget,
      );
      expect(insert(tester).onPressed, isNull);
      expect(network.clients, 0);
    });

    testWidgets('a note without a title goes out as the title',
        (tester) async {
      String? wire;
      await host(tester, _Radio(), (context) async {
        wire = await StructuredMessageDialogs.pointOnMap(context);
      });
      await tester.enterText(field('Location'), '36.97 -121.9');
      await tester.enterText(field('Note (optional)'), 'behind the hut');
      await done(tester);
      expect(wire, 'Location: behind the hut\n$_here',
          reason: 'readers take the first text for the title');
    });

    testWidgets('no title and no note: just a place', (tester) async {
      String? wire;
      await host(tester, _Radio(), (context) async {
        wire = await StructuredMessageDialogs.pointOnMap(context);
      });
      await tester.enterText(field('Location'), '36.97, -121.9');
      await tester.pump();
      await done(tester);
      expect(wire, 'Location: $_here');
    });

    // A radio that lost its fix keeps reporting the last one (safety review
    // CH-07): the dialogs say so, and never stop you sending it.
    testWidgets('My location from a GPS that may be old says so', (
      tester,
    ) async {
      String? wire;
      final radio = _Radio(
        lat: 36.97,
        lon: -121.9,
        gps: true,
        at: DateTime(2026, 11, 16, 14, 2),
      );
      await host(tester, radio, (context) async {
        wire = await StructuredMessageDialogs.myLocation(
          context,
          context.read<MeshCoreConnector>(),
        );
      });
      expect(
        find.textContaining(
          RegExp(r'^Your last known location \(2:02\sPM\), may be old$'),
        ),
        findsOneWidget,
      );
      await done(tester);
      expect(wire, 'Location: My location\n$_here');
    });

    testWidgets('SOS says so too, until another position is typed', (
      tester,
    ) async {
      String? wire;
      await host(tester, _Radio(lat: 36.97, lon: -121.9, gps: true), (
        context,
      ) async {
        wire = await StructuredMessageDialogs.sos(
          context,
          context.read<MeshCoreConnector>(),
        );
      });
      const line = 'Your last known location, may be old';
      expect(find.text(line), findsOneWidget);
      expect(insert(tester).onPressed, isNotNull, reason: 'it never blocks');

      await tester.enterText(field('Location'), '36.98, -121.9');
      await tester.pump();
      expect(find.text(line), findsNothing);
      await tester.enterText(field('What happened?'), 'Broken leg');
      await done(tester);
      expect(wire, 'SOS: Broken leg\n36.980000, -121.900000');
    });

    testWidgets('a fresh GPS position, or one typed in: no line', (
      tester,
    ) async {
      for (final radio in [
        _Radio(lat: 36.97, lon: -121.9, gps: true, fresh: true),
        _Radio(lat: 36.97, lon: -121.9),
      ]) {
        await host(tester, radio, (context) {
          StructuredMessageDialogs.sos(context, radio);
        });
        expect(find.text(_here), findsOneWidget);
        expect(find.textContaining('last known'), findsNothing);
      }
    });

    testWidgets('SOS takes a pasted position too', (tester) async {
      String? wire;
      await host(tester, _Radio(), (context) async {
        wire = await StructuredMessageDialogs.sos(
          context,
          context.read<MeshCoreConnector>(),
        );
      });
      await tester.enterText(field('What happened?'), 'Broken leg');
      expect(insert(tester).onPressed, isNull);
      await tester.enterText(field('Location'), '36.97, -121.9');
      await tester.pump();
      await done(tester);
      expect(wire, 'SOS: Broken leg\n$_here');
    });

    // Martin, 2026-11-26: My location can also send heading, speed and
    // altitude. The choice starts on Only the position and keeps the last
    // pick.
    group('heading, speed and altitude', () {
      const onlyPosition = 'Only the position';
      const withMotion = 'Position, heading, speed and altitude';
      late DateTime now;

      _Radio gpsRadio() => _Radio(lat: 36.97, lon: -121.9, gps: true, fresh: true);

      /// The radio's readings a minute apart, the last one at its position.
      Future<void> readings(
        WidgetTester tester,
        _Radio radio,
        List<double> lats,
      ) async {
        now = DateTime(2026, 11, 26, 9);
        SelfMotion.instance.attach(radio, clock: () => now);
        for (final (i, lat) in lats.indexed) {
          if (i > 0) now = now.add(const Duration(minutes: 1));
          radio.selfGps.value =
              (latitude: lat, longitude: -121.9, altitude: 35, at: now);
          await tester.pump();
        }
      }

      /// Opens My location again, for what it shows.
      Future<void> reopen(WidgetTester tester, _Radio radio) => host(
            tester,
            radio,
            (context) => StructuredMessageDialogs.myLocation(context, radio),
          );

      bool? picked(WidgetTester tester) =>
          tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>))
              .groupValue;

      testWidgets('first Only the position, and nothing more goes',
          (tester) async {
        final radio = gpsRadio();
        await readings(tester, radio, [36.96, 36.97]);
        String? wire;
        await host(tester, radio, (context) async {
          wire = await StructuredMessageDialogs.myLocation(context, radio);
        });
        expect(find.text(onlyPosition), findsOneWidget);
        expect(find.text(withMotion), findsOneWidget);
        expect(picked(tester), isFalse);
        await done(tester);
        expect(wire, 'Location: My location\n$_here');
      });

      testWidgets('moving: what the radio knows goes, and the pick is kept',
          (tester) async {
        final radio = gpsRadio();
        // 1.1 km north in a minute.
        await readings(tester, radio, [36.96, 36.97]);
        String? wire;
        await host(tester, radio, (context) async {
          wire = await StructuredMessageDialogs.myLocation(context, radio);
        });
        expect(find.text('N 0° · 67 km/h · 35 m'), findsOneWidget);
        await tester.tap(find.text(withMotion));
        await tester.pump();
        await done(tester);
        expect(wire, 'Location: My location\n$_here\nalt=35m\nhdg=0\nspd=67km/h');
        expect(PrefsManager.instance.getBool('location_send_motion'), isTrue);

        await reopen(tester, radio);
        expect(picked(tester), isTrue, reason: 'the last pick');
      });

      testWidgets('standing still: not moving, a speed of 0', (tester) async {
        final radio = gpsRadio();
        await readings(tester, radio, [36.97, 36.97, 36.97, 36.97]);
        await PrefsManager.instance.setBool('location_send_motion', true);
        String? wire;
        await host(tester, radio, (context) async {
          wire = await StructuredMessageDialogs.myLocation(context, radio);
        });
        expect(find.text('Not moving · 35 m'), findsOneWidget);
        await done(tester);
        expect(wire, 'Location: My location\n$_here\nalt=35m\nspd=0km/h');
      });

      testWidgets('not known yet: the altitude goes alone', (tester) async {
        final radio = gpsRadio();
        await readings(tester, radio, [36.97]);
        await PrefsManager.instance.setBool('location_send_motion', true);
        String? wire;
        await host(tester, radio, (context) async {
          wire = await StructuredMessageDialogs.myLocation(context, radio);
        });
        expect(find.text("Heading and speed aren't known yet · 35 m"),
            findsOneWidget);
        await done(tester);
        expect(wire, 'Location: My location\n$_here\nalt=35m');
      });

      testWidgets("a position typed over the radio's, or GPS off: no choice",
          (tester) async {
        final radio = gpsRadio();
        await readings(tester, radio, [36.96, 36.97]);
        await PrefsManager.instance.setBool('location_send_motion', true);
        String? wire;
        await host(tester, radio, (context) async {
          wire = await StructuredMessageDialogs.myLocation(context, radio);
        });
        await tester.enterText(field('Location'), '36.5, -121.5');
        await tester.pump();
        expect(find.text(withMotion), findsNothing);
        await done(tester);
        expect(wire, 'Location: My location\n36.500000, -121.500000');

        await reopen(tester, _Radio(lat: 36.97, lon: -121.9));
        expect(find.text(onlyPosition), findsNothing);
      });
    });
  });

  group('the distance on a card', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('card'));
    tearDown(() => tmp.delete(recursive: true));

    // An SOS 2.2 km north of a radio at 36.97, -121.9, unless [wire] says.
    Future<void> card(
      WidgetTester tester,
      MeshCoreConnector radio, {
      String wire = 'SOS: Broken leg\n36.990000, -121.900000',
      AppSettingsService? settings,
      String? senderName,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(
            create: (_) => settings ?? AppSettingsService(),
          ),
          ChangeNotifierProvider(
            create: (_) => MapPacksService(
              manager: PackManager(Directory('${tmp.path}/packs')),
              downloader: _NoDownloads(),
              cacheDir: tmp,
              styles: StyleRegistry(MemoryStyles()),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 322,
                child: StructuredMessageCard(
                  message: StructuredMessage.parse(wire)!,
                  textScale: 1,
                  senderName: senderName,
                ),
              ),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('from a GPS position that may be old: the map\'s mark', (
      tester,
    ) async {
      await card(
        tester,
        _Radio(
          lat: 36.97,
          lon: -121.9,
          gps: true,
          at: DateTime(2026, 11, 16, 14, 2),
        ),
      );
      expect(find.textContaining(RegExp(r' N$')), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^Last known · 2:02\sPM$')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.navigation_outlined), findsOneWidget);
    });

    testWidgets('from a fresh one, or one typed in: no mark', (tester) async {
      for (final radio in [
        _Radio(lat: 36.97, lon: -121.9, gps: true, fresh: true),
        _Radio(lat: 36.97, lon: -121.9),
      ]) {
        await card(tester, radio);
        expect(find.textContaining(RegExp(r' N$')), findsOneWidget);
        expect(find.textContaining('Last known'), findsNothing);
        expect(find.byIcon(Icons.navigation), findsOneWidget);
      }
    });

    // Martin, 2026-11-26: heading, speed and altitude on a shared My
    // location, as the map shows them for TRAX, in the reader's units.
    testWidgets('heading, speed and altitude in my units', (tester) async {
      final settings = AppSettingsService();
      await settings.setUnitSystem(UnitSystem.imperial);
      await card(
        tester,
        _Radio(lat: 36.97, lon: -121.9),
        wire: 'Location: My location\n36.990000, -121.900000\nalt=35m\n'
            'hdg=270\nspd=15km/h',
        settings: settings,
        senderName: 'GWQ',
      );
      expect(find.text("GWQ's location"), findsOneWidget);
      expect(find.text('W 270°'), findsOneWidget);
      expect(find.text('9 mph'), findsOneWidget);
      expect(find.text('115 ft'), findsOneWidget);
      expect(find.byIcon(Icons.north), findsOneWidget);
      expect(find.text('alt: 35m'), findsNothing, reason: 'read, not raw');
    });

    testWidgets('standing still: Not moving', (tester) async {
      await card(
        tester,
        _Radio(lat: 36.97, lon: -121.9),
        wire: 'Location: My location\n36.990000, -121.900000\nspd=0km/h',
      );
      expect(find.text('Not moving'), findsOneWidget);
      expect(find.text('0 km/h'), findsNothing);
    });
  });
}
