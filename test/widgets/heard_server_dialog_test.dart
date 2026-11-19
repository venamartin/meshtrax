import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxheard/traxheard.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/heard_check_settings.dart';

// The owner, 2026-11-19: the server dialog cut the server off.
void main() {
  Future<void> openDialog(WidgetTester tester, {String server = ''}) async {
    SharedPreferences.setMockInitialValues({
      if (server.isNotEmpty) 'heard_check_server': server,
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    final radio = MeshCoreConnector();
    addTearDown(radio.dispose);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);

    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => HeardServerDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the picked server shows its area and its address', (
    tester,
  ) async {
    final longest = knownServers.reduce(
      (a, b) => a.label.length >= b.label.length ? a : b,
    );
    await openDialog(tester, server: longest.address);
    expect(find.text(longest.area).hitTestable(), findsOneWidget);
    expect(find.text(longest.host).hitTestable(), findsOneWidget);
  });

  testWidgets('no server in the list is cut off', (tester) async {
    await openDialog(tester);
    // The closed list lays every entry out at its own width.
    for (final known in knownServers) {
      for (final text in [known.area, known.host]) {
        final shown = tester.renderObjectList<RenderParagraph>(
          find.text(text, skipOffstage: false),
        );
        expect(shown, isNotEmpty, reason: text);
        expect(shown.any((p) => p.didExceedMaxLines), isFalse, reason: text);
      }
    }
  });
}
