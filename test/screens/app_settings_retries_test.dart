import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/app_settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

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
    tmp = await Directory.systemTemp.createTemp('retries');
  });
  tearDown(() => tmp.delete(recursive: true));

  testWidgets('the retries sliders show their values', (tester) async {
    tester.view.physicalSize = const Size(600, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettingsService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MeshCoreConnector()),
          ChangeNotifierProvider.value(value: settings),
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
    await settings.setMaxMessageRetries(5);
    await settings.setMaxChannelMessageRetries(2);
    await tester.pump();

    final direct = find.widgetWithText(ListTile, 'Max Direct Message Tries');
    final channel = find.widgetWithText(
      ListTile,
      'Max Channel Message Retries',
    );
    expect(find.descendant(of: direct, matching: find.text('5')), findsOne);
    expect(find.descendant(of: channel, matching: find.text('2')), findsOne);

    await tester.drag(
      find.descendant(of: direct, matching: find.byType(Slider)),
      const Offset(-1000, 0),
    );
    await tester.pump();

    expect(settings.settings.maxMessageRetries, 1);
    expect(find.descendant(of: direct, matching: find.text('1')), findsOne);
  });
}
