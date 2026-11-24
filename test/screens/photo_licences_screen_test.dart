import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/screens/photo_licences_screen.dart';

void main() {
  testWidgets('shows Powered by Stability AI, then the NOTICE first', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('licences');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/LICENSE-AEIC-MIT.txt').writeAsStringSync('MIT');
    File('${dir.path}/NOTICE.txt').writeAsStringSync('The notice');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhotoLicencesScreen(dir: dir),
      ),
    );

    expect(find.text(kPoweredByStability), findsOneWidget);
    final names = tester
        .widgetList<ExpansionTile>(find.byType(ExpansionTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(names, ['NOTICE.txt', 'LICENSE-AEIC-MIT.txt']);
    await tester.tap(find.text('NOTICE.txt'));
    await tester.pumpAndSettle();
    expect(find.text('The notice'), findsOneWidget);
  });

  testWidgets('says the texts come with the model when none are here', (
    tester,
  ) async {
    final dir = Directory('${Directory.systemTemp.path}/no-licences-here');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhotoLicencesScreen(dir: dir),
      ),
    );
    expect(
      find.text('The licence texts download with the photo model.'),
      findsOneWidget,
    );
  });
}
