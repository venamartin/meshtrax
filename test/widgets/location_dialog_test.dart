import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';
import 'package:meshtrax/widgets/structured_message_dialogs.dart';

// The tray's location dialogs and how a location is named (owner,
// 2026-10-27): "My location" is the sender's own position, titled so on
// the air; anything else, or no title, is just a place.
class _Radio extends MeshCoreConnector {
  _Radio({this.lat, this.lon});
  final double? lat, lon;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
}

const _here = '36.970000, -121.900000';

void main() {
  setUp(() async {
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
      expect(find.text('Your radio has no position yet. Pick one on the map.'),
          findsOneWidget);
      expect(insert(tester).onPressed, isNull);
      await tester.enterText(field('Position'), '36.97, -121.9');
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
      await tester.enterText(field('Position'), 'hello');
      await tester.pump();
      expect(find.text("Can't read a position here"), findsOneWidget);
      expect(insert(tester).onPressed, isNull);

      await tester.enterText(field('Position'), 'geo:36.97,-121.9');
      await tester.pump();
      expect(find.text(_here), findsOneWidget,
          reason: 'a link shows the coordinates that will be sent');
      await tester.enterText(field('Label'), 'Water tap');
      await tester.enterText(field('Note (optional)'), 'behind the hut');
      await done(tester);
      expect(wire, 'Location: Water tap\n$_here\nbehind the hut');
    });

    testWidgets('a note without a title goes out as the title',
        (tester) async {
      String? wire;
      await host(tester, _Radio(), (context) async {
        wire = await StructuredMessageDialogs.pointOnMap(context);
      });
      await tester.enterText(field('Position'), '36.97 -121.9');
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
      await tester.enterText(field('Position'), '36.97, -121.9');
      await tester.pump();
      await done(tester);
      expect(wire, 'Location: $_here');
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
      await tester.enterText(field('Position'), '36.97, -121.9');
      await tester.pump();
      await done(tester);
      expect(wire, 'SOS: Broken leg\n$_here');
    });
  });
}
