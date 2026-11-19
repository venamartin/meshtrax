import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/app_settings_screen.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/sos_service.dart';
import 'package:meshtrax/widgets/active_sos_bar.dart';

// The sender's own SOS above its chat: when it last went out, who answered
// and Cancel, which asks first. The settings row says what the phone lets
// an SOS do.
void main() {
  ActiveSos sos({
    SosPhase phase = SosPhase.active,
    DateTime? lastSent,
    List<String> gotIt = const [],
  }) => ActiveSos(
    channelIdKey: 'trip',
    channelName: 'trip',
    messageId: 'row0',
    text: 'Broken leg',
    position: const LatLng(36.46, -116.87),
    startedAt: DateTime(2026, 11, 16, 14),
    lastSentAt: lastSent,
    phase: phase,
    gotIt: gotIt,
  );

  Future<void> pump(
    WidgetTester tester,
    ActiveSos sos, {
    bool connected = true,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: ActiveSosBar(
          sos: sos,
          connected: connected,
          onCancel: () {},
          onSendAgain: () {},
        ),
      ),
    ),
  );

  testWidgets('active: when it last went out, who got it, and Cancel', (
    tester,
  ) async {
    await pump(
      tester,
      sos(lastSent: DateTime(2026, 11, 16, 14, 6), gotIt: const ['Ann', 'Bob']),
    );
    expect(find.text('Your SOS is active'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^Last sent 2:06\sPM$')),
      findsOneWidget,
    );
    expect(find.text('Got it (2): Ann, Bob'), findsOneWidget);
    expect(find.text('Cancel SOS'), findsOneWidget);
    expect(find.text('Send again'), findsNothing);
  });

  testWidgets('with the radio away it says it waits for the radio', (
    tester,
  ) async {
    await pump(
      tester,
      sos(lastSent: DateTime(2026, 11, 16, 14, 6)),
      connected: false,
    );
    expect(find.text('Waiting for the radio to send it'), findsOneWidget);
    expect(find.textContaining('Last sent'), findsOneWidget);
    expect(find.text('No Got it yet'), findsOneWidget);
  });

  testWidgets('stopped after the app closed: Send again or Cancel', (
    tester,
  ) async {
    await pump(
      tester,
      sos(phase: SosPhase.stopped, lastSent: DateTime(2026, 11, 16, 9, 20)),
    );
    expect(
      find.textContaining(
        RegExp(
          r'^SOS stopped when MeshTrax closed\. Last sent 9:20\sAM\.$',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Send again'), findsOneWidget);
    expect(find.text('Cancel SOS'), findsOneWidget);
  });

  testWidgets('a cancel waiting for the radio says so, with nothing to tap', (
    tester,
  ) async {
    await pump(tester, sos(phase: SosPhase.cancelling));
    expect(
      find.text('SOS cancelled. Sends when the radio connects.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('Cancel asks first, naming who gets "SOS cancelled"', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                answer = await ActiveSosBar.confirmCancel(context, 'trip'),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone in trip gets "SOS cancelled".'), findsOneWidget);
    await tester.tap(find.text('Keep SOS'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel SOS'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  group('the SOS alerts row in settings', () {
    Future<void> row(
      WidgetTester tester,
      SosAlertState state, {
      bool enabled = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SosAlertsTile(enabled: enabled, state: state),
          ),
        ),
      );
    }

    const always =
        'An SOS always alerts, even in a muted chat or with '
        'message notifications off.';

    testWidgets('says what Do Not Disturb does to it', (tester) async {
      await row(tester, SosAlertState.silencedByDnd);
      expect(
        find.text(
          '$always Do Not Disturb silences it. Tap and allow '
          'Override Do Not Disturb.',
        ),
        findsOneWidget,
      );
      await row(tester, SosAlertState.throughDnd);
      expect(
        find.text('$always It sounds through Do Not Disturb.'),
        findsOneWidget,
      );
      await row(tester, SosAlertState.blocked);
      expect(
        find.text(
          '$always The phone has SOS alerts turned off. Tap to turn '
          'them on.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('with notifications off, SOS alerts are off too', (
      tester,
    ) async {
      await row(tester, SosAlertState.throughDnd, enabled: false);
      expect(
        find.text('Notifications are off, so SOS alerts are off too.'),
        findsOneWidget,
      );
    });
  });
}
