import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/room_announcement_dialog.dart';
import 'package:meshtrax/widgets/structured_message_dialogs.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  /// Taps a button that calls [open] with a context under the app.
  Future<void> host(WidgetTester tester, void Function(BuildContext) open) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>(
            create: (_) => MeshCoreConnector()),
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

  group('editing fills the dialog in', () {
    final day = DateTime.now().add(const Duration(days: 30));
    DateTime at(int h, int m, {int plusDays = 0}) =>
        DateTime(day.year, day.month, day.day + plusDays, h, m);
    final date = DateTime(day.year, day.month, day.day);

    Future<String?> roundTrip(
      WidgetTester tester,
      Future<String?> Function(BuildContext) show,
    ) async {
      String? wire;
      await host(tester, (context) => show(context).then((w) => wire = w));
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      return wire;
    }

    for (final (label, notice) in [
      (
        'with a time',
        NoticeMessage(lines: const ['Road closed', 'Detour north'],
            expires: at(18, 30)),
      ),
      (
        'to the end of a day',
        NoticeMessage(lines: const ['Net tonight'],
            expires: DateTime(date.year, date.month, date.day + 1)),
      ),
    ]) {
      testWidgets('a notice $label comes back unchanged', (tester) async {
        final wire = await roundTrip(
          tester,
          (context) => StructuredMessageDialogs.notice(
            context,
            requireExpiry: true,
            initial: notice,
          ),
        );
        expect(wire, notice.toWire());
      });
    }

    for (final (label, span) in [
      ('with an end', EventWhen(start: at(18, 0), end: at(20, 0))),
      ('overnight', EventWhen(start: at(22, 0), end: at(2, 0, plusDays: 1))),
      (
        'over three days',
        EventWhen(start: at(9, 0), end: at(17, 0, plusDays: 2)),
      ),
      ('without an end', EventWhen(start: at(18, 0))),
      ('all day', EventWhen(start: date, allDay: true)),
      (
        'all day, three days',
        EventWhen(
          start: date,
          end: DateTime(date.year, date.month, date.day + 2),
          allDay: true,
        ),
      ),
    ]) {
      testWidgets('an event $label comes back unchanged', (tester) async {
        final event = EventMessage(
          title: 'Mesh meetup',
          when: span,
          place: 'Hauptplatz',
          position: const LatLng(47.070123, 15.440123),
        );
        final wire = await roundTrip(
          tester,
          (context) => StructuredMessageDialogs.event(context, initial: event),
        );
        expect(wire, event.toWire());
      });
    }
  });

  testWidgets(
      'the announcement dialog keeps a composed post on a re-tap, and Edit '
      'opens it filled in', (tester) async {
    final room = Contact(
      publicKey: Uint8List.fromList(List.filled(32, 0x42)),
      name: 'Summit Room',
      type: advTypeRoom,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime(2026, 10, 25),
    );
    await host(
      tester,
      (context) => showDialog<void>(
        context: context,
        builder: (_) => RoomAnnouncementDialog(room: room),
      ),
    );

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Meetup');
    await tester.pump();
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    expect(find.text('Meetup'), findsOneWidget, reason: 'the preview');

    // The chosen chip again: nothing opens, nothing is lost.
    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();
    expect(find.text('Insert'), findsNothing);
    expect(find.text('Meetup'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Meetup'), findsOneWidget);
  });
}
