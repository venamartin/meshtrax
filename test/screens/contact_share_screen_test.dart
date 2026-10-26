import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/meshcore_qr.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/contact_share_screen.dart';

void main() {
  final key = 'ab' * 32;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: screen,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a room shares as a type 3 link with no password',
      (tester) async {
    await pump(
      tester,
      ContactShareScreen(name: 'Summit Room', pubKeyHex: key, type: advTypeRoom),
    );
    final link = MeshCoreQr.encodeContact('Summit Room', key, advTypeRoom);
    expect(link, contains('type=3'));
    expect(link, isNot(contains('password')));
    expect(find.text('Share Room'), findsOneWidget);
    expect(find.textContaining("You'll need its password"), findsOneWidget);
    expect(find.text(link), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('your own identity keeps its wording', (tester) async {
    await pump(
      tester,
      ContactShareScreen(
        name: 'Me',
        pubKeyHex: key,
        type: advTypeChat,
        isSelf: true,
      ),
    );
    expect(find.text('Share My QR Code'), findsOneWidget);
    expect(find.text('Let others scan to add you as a contact'), findsOneWidget);
  });
}
