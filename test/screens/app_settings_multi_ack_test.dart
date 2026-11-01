import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/app_settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

class _Radio extends MeshCoreConnector {
  _Radio(this.connected);
  final bool connected;
  final sent = <Uint8List>[];

  @override
  bool get isConnected => connected;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }
}

class _NoDownloads implements PackDownloader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('multi_ack');
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pump(WidgetTester tester, _Radio radio) async {
    tester.view.physicalSize = const Size(600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(create: (_) => ChatTextScaleService()),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider(
            create: (_) => MapPacksService(
              manager: PackManager(Directory('${tmp.path}/packs')),
              downloader: _NoDownloads(),
              cacheDir: tmp,
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Finder multiAckSwitch() => find.widgetWithText(SwitchListTile, 'Multi-ACKs');

  Uint8List deviceInfo({String version = 'v1.18.0', int code = 14}) {
    final frame = Uint8List(82);
    frame[0] = respCodeDeviceInfo;
    frame[1] = code;
    frame.setRange(60, 60 + version.length, version.codeUnits);
    return frame;
  }

  testWidgets('the switch sits in Messaging and writes to the radio', (
    tester,
  ) async {
    final radio = _Radio(true)..handleFrameForTest(deviceInfo());
    await pump(tester, radio);

    final messaging = find.text('Messaging');
    expect(messaging, findsOneWidget);
    expect(
      find.ancestor(of: multiAckSwitch(), matching: find.byType(Card)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(of: messaging, matching: find.byType(Card)),
        matching: multiAckSwitch(),
      ),
      findsOneWidget,
    );

    await tester.tap(multiAckSwitch());
    await tester.pump();

    final frame = radio.sent.firstWhere((f) => f[0] == cmdSetOtherParams);
    expect(frame[4], 0, reason: 'turned off: 1 ACK');
    expect(radio.multiAcks, 0);
    expect(
      radio.sent.where((f) => f[0] == cmdAppStart),
      isEmpty,
      reason: 'CMD_APP_START would stop a contact download',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('the switch is disabled on firmware that ignores it', (
    tester,
  ) async {
    final radio = _Radio(true)
      ..handleFrameForTest(deviceInfo(version: 'v1.7.3', code: 7));
    await pump(tester, radio);

    radio.sent.clear();
    await tester.tap(multiAckSwitch());
    await tester.pump();
    expect(radio.sent, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('the switch is disabled with no radio connected', (tester) async {
    final radio = _Radio(false);
    await pump(tester, radio);

    await tester.tap(multiAckSwitch());
    await tester.pump();

    expect(radio.sent, isEmpty);
  });
}
