import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/widgets/cli_console.dart';

void main() {
  final sent = <String>[];

  Future<void> pumpConsole(WidgetTester tester) async {
    sent.clear();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: CliConsole(
          title: 'Command line',
          subtitle: 'Base',
          onSend: (command) async {
            sent.add(command);
            if (command == 'bad') throw Exception('nope');
            return '> $command ok';
          },
          quickCommands: const [CliQuickCommand('Version', 'ver')],
          helpNote: 'note',
          helpSections: (_) => const [
            CliHelpSection('General', [
              CliHelpEntry(command: 'ver', description: 'Shows the version.'),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> type(WidgetTester tester, String command) async {
    await tester.enterText(find.byType(TextField), command);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
  }

  testWidgets('shows each command with its reply, trimmed', (tester) async {
    await pumpConsole(tester);

    await type(tester, '  get name  ');

    expect(sent, ['get name']);
    expect(find.text('get name'), findsOneWidget);
    expect(find.text('> get name ok'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('a failed send shows as an error line', (tester) async {
    await pumpConsole(tester);

    await type(tester, 'bad');

    expect(find.text('Error: Exception: nope'), findsOneWidget);
  });

  testWidgets('quick commands send at once', (tester) async {
    await pumpConsole(tester);

    await tester.tap(find.text('Version'));
    await tester.pumpAndSettle();

    expect(sent, ['ver']);
  });

  testWidgets('up recalls the last command', (tester) async {
    await pumpConsole(tester);
    await type(tester, 'get tx');

    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'get tx');
  });

  testWidgets('a help entry fills the input', (tester) async {
    await pumpConsole(tester);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shows the version.'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ver');
    expect(sent, isEmpty);
  });
}
