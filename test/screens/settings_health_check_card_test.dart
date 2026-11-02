import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  bool get isSynced => true;

  @override
  Future<bool> readRadioSettings({
    Duration syncTimeout = const Duration(seconds: 90),
    Duration replyTimeout = const Duration(seconds: 3),
  }) => Future<bool>.delayed(const Duration(seconds: 1), () => true);

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

/// A radio still called by its public key: its firmware's default name.
Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List(32)..fillRange(0, 32, 0xAB));
  w.add(Uint8List(8));
  w.add([1, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add('ABABABAB'.codeUnits);
  return w.toBytes();
}

void main() {
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
  });

  testWidgets('Settings opens the check, and Fix reaches the name dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final radio = _Radio()..handleFrameForTest(_selfInfo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    // First thing on the screen, above the device card.
    final card = find.text('Health check');
    expect(card, findsOneWidget);
    expect(
      tester.getTopLeft(card).dy,
      lessThan(tester.getTopLeft(find.text('Device Info')).dy),
    );

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Checking your settings…'), findsOneWidget);
    await tester.pumpAndSettle();

    const title = 'Radio still has its default name';
    expect(find.text(title), findsOneWidget);

    final fix = find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
      matching: find.widgetWithText(FilledButton, 'Fix'),
    );
    await tester.tap(fix);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Node Name'), findsOneWidget);
  });
}
