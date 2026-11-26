import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/widgets/sos_dnd_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, {required bool samsung}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => askSosThroughDnd(context, samsung: samsung),
            child: const Text('ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
  }

  testWidgets('on Samsung it names the Do not disturb steps', (tester) async {
    await open(tester, samsung: true);
    expect(find.text('Let an SOS ring through Do Not Disturb?'), findsOne);
    expect(
      find.text(
        'Settings opens on Do not disturb. Tap App notifications, then Add '
        'apps, pick MeshTrax and turn on SOS alerts only.',
      ),
      findsOne,
    );
    expect(find.textContaining('Override Do Not Disturb'), findsNothing);
  });

  testWidgets('elsewhere it names Override Do Not Disturb, and where else '
      'to look', (tester) async {
    await open(tester, samsung: false);
    expect(
      find.text(
        'Settings opens on SOS alerts: turn on Override Do Not Disturb. If '
        'your phone has no such switch there, open Do Not Disturb, find the '
        'apps allowed to interrupt, add MeshTrax and turn on SOS alerts.',
      ),
      findsOne,
    );
  });

  testWidgets('Not now closes it without opening settings', (tester) async {
    await open(tester, samsung: true);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
