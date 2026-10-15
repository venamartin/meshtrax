import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/wifi_settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/companion_cli_service.dart';

// What a firmware 1.18 BLE+WiFi radio answers to the wifi.* CLI keys.
class _Cli extends CompanionCliService {
  _Cli(super.connector);

  final commands = <String>[];
  final values = <String, String>{
    'wifi.enabled': '1',
    'wifi.ssid': 'HomeNet',
    'wifi.status': 'connected',
    'wifi.ip': '192.168.1.42',
    'wifi.pwd': 'hunter22',
  };
  String? refuse;

  @override
  Future<String> run(String command) async {
    if (command.startsWith('get ')) return '> ${values[command.substring(4)]}';
    commands.add(command);
    if (command == refuse) return 'Error, bad value';
    return command == 'set wifi.clear'
        ? '> wifi config cleared (reboot to apply)'
        : '> ok (reboot to apply)';
  }
}

class _Connector extends MeshCoreConnector {
  late final _Cli cli = _Cli(this);
  int reboots = 0;

  @override
  CompanionCliService get companionCli => cli;

  @override
  Future<void> rebootDevice() async => reboots++;
}

void main() {
  late _Connector connector;

  Future<void> pumpScreen(WidgetTester tester) async {
    connector = _Connector();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider<AppSettingsService>(
            create: (_) => AppSettingsService(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const WifiSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) =>
      find.widgetWithText(TextField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the radio reports', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Connected · 192.168.1.42'), findsOneWidget);
    expect(find.text('HomeNet'), findsOneWidget);
    expect(find.text('Connect over WiFi'), findsOneWidget);
  });

  testWidgets('saves only what changed, then offers a restart',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(field('Network name'), 'Cabin');
    await tester.enterText(field('Password'), 'secret123');
    await save(tester);

    expect(connector.cli.commands,
        ['set wifi.ssid Cabin', 'set wifi.pwd secret123']);
    expect(find.text('Restart the radio?'), findsOneWidget);

    await tester.tap(find.text('Reboot'));
    await tester.pumpAndSettle();

    expect(connector.reboots, 1);
  });

  testWidgets('an untouched password is never sent', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await save(tester);

    expect(connector.cli.commands, ['set wifi.enabled 0']);
  });

  testWidgets('emptying a shown password sets an open network',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();
    expect(find.text('hunter22'), findsOneWidget);

    await tester.enterText(field('Password'), '');
    await save(tester);

    expect(connector.cli.commands, ['set wifi.pwd ']);
  });

  testWidgets('stops at the first command the radio refuses',
      (tester) async {
    await pumpScreen(tester);
    connector.cli.refuse = 'set wifi.ssid Cabin';

    await tester.enterText(field('Network name'), 'Cabin');
    await tester.enterText(field('Password'), 'secret123');
    await save(tester);

    expect(connector.cli.commands, ['set wifi.ssid Cabin']);
    expect(find.text('The radio did not accept that: Error, bad value'),
        findsOneWidget);
    expect(find.text('Restart the radio?'), findsNothing);
  });

  testWidgets('a network name longer than 32 bytes is refused here',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(field('Network name'), 'x' * 33);
    await save(tester);

    expect(connector.cli.commands, isEmpty);
    expect(find.text('The network name is too long (32 bytes at most)'),
        findsOneWidget);
  });
}
