import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/health_check_prompt.dart';

class _Radio extends MeshCoreConnector {
  _Radio(this.connected);
  final bool connected;

  @override
  bool get isConnected => connected;

  @override
  Future<void> refreshDeviceInfoAndWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {}

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

void main() {
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MeshTrax',
      packageName: 'test',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
  });

  Future<void> show(WidgetTester tester, {bool connected = true}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Radio(connected),
          ),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showHealthCheckPromptIfNeeded(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks once, and Not now does not ask again', (tester) async {
    await show(tester);
    expect(find.text('Run a health check?'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(settings.settings.healthCheckPromptSeen, isTrue);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Run a health check?'), findsNothing);
  });

  testWidgets('waits until a radio is connected', (tester) async {
    await show(tester, connected: false);
    expect(find.text('Run a health check?'), findsNothing);
    expect(settings.settings.healthCheckPromptSeen, isFalse);
  });

  testWidgets('Run check opens the health check over Settings', (tester) async {
    await show(tester);
    await tester.tap(find.text('Run check'));
    await tester.pumpAndSettle();

    expect(find.text('Health check'), findsOneWidget);
    expect(find.textContaining('Checks passed'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
