import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/health_check_prompt.dart';

class _Radio extends MeshCoreConnector {
  _Radio(this.connected, this.synced);
  final bool connected;
  final Future<bool>? synced;

  @override
  bool get isConnected => connected;

  @override
  bool get isSynced => true;

  @override
  Future<bool> waitUntilSynced({
    Duration timeout = const Duration(seconds: 90),
  }) async => await synced ?? connected;

  @override
  Future<bool> readRadioSettings({
    Duration syncTimeout = const Duration(seconds: 90),
    Duration replyTimeout = const Duration(seconds: 3),
  }) async => true;

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

  Future<void> show(
    WidgetTester tester, {
    bool connected = true,
    Future<bool>? synced,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Radio(connected, synced),
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
    expect(settings.settings.healthCheckPromptSeen, isFalse);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(settings.settings.healthCheckPromptSeen, isTrue);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Run a health check?'), findsNothing);
  });

  testWidgets('a stray tap outside does not use up the question', (
    tester,
  ) async {
    await show(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text('Run a health check?'), findsOneWidget);
    expect(settings.settings.healthCheckPromptSeen, isFalse);
  });

  testWidgets('waits until a radio is connected', (tester) async {
    await show(tester, connected: false);
    expect(find.text('Run a health check?'), findsNothing);
    expect(settings.settings.healthCheckPromptSeen, isFalse);
  });

  testWidgets('waits for the radio to finish syncing', (tester) async {
    final synced = Completer<bool>();
    await show(tester, synced: synced.future);
    expect(find.text('Run a health check?'), findsNothing);

    synced.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Run a health check?'), findsOneWidget);
  });

  testWidgets('a radio that never finishes syncing asks on a later launch', (
    tester,
  ) async {
    await show(tester, synced: Future.value(false));
    expect(find.text('Run a health check?'), findsNothing);
    expect(settings.settings.healthCheckPromptSeen, isFalse);
  });

  testWidgets('leaves another screen alone and asks on a later launch', (
    tester,
  ) async {
    final synced = Completer<bool>();
    await show(tester, synced: synced.future);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const Text('a chat')),
      ),
    );
    await tester.pumpAndSettle();

    synced.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Run a health check?'), findsNothing);
    expect(settings.settings.healthCheckPromptSeen, isFalse);
  });

  testWidgets('Run check opens the health check, and back leads home', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Run check'));
    await tester.pumpAndSettle();

    expect(settings.settings.healthCheckPromptSeen, isTrue);
    expect(find.text('Health check'), findsOneWidget);
    expect(find.textContaining('Checks passed'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Run by itself after the first sync: back where it was offered, not in
    // Settings (owner, 2026-11-02).
    expect(find.text('Settings'), findsNothing);
    expect(find.text('go'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('opened from Settings, back returns to Settings', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Health check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Checks passed'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
