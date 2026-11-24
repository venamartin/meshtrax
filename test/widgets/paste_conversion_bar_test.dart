import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/widgets/paste_conversion_bar.dart';

// Short links went online to find their position (owner, 2026-11-16: no
// internet but Giphy and map downloads). Now the bar only says what to do.
class _NoNetwork extends HttpOverrides {
  int clients = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clients++;
    throw StateError('this test has no network');
  }
}

const _shortLinkLine =
    'This short link has no location in it. Open it in your maps app and '
    'copy the coordinates.';

void main() {
  late _NoNetwork network;
  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() => HttpOverrides.global = null);

  Future<TextEditingController> pump(
    WidgetTester tester,
    void Function(String) onReplace,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: PasteConversionBar(
            controller: controller,
            onReplace: onReplace,
          ),
        ),
      ),
    );
    return controller;
  }

  for (final link in [
    'https://maps.app.goo.gl/AbCdEf123',
    'Meet here\ngoo.gl/maps/AbCdEf',
  ]) {
    testWidgets('a pasted short link says how to get its position: $link', (
      tester,
    ) async {
      String? replaced;
      final controller = await pump(tester, (wire) => replaced = wire);
      controller.text = link;
      await tester.pumpAndSettle();

      expect(find.text(_shortLinkLine), findsOneWidget);
      expect(find.text('Convert'), findsNothing);
      expect(replaced, isNull);
      expect(network.clients, 0, reason: 'nothing goes online');
    });
  }

  for (final (link, position, label) in [
    (
      'Hut\nhttps://www.google.com/maps/place/Hauptplatz/@47.0707,15.4395,17z',
      const LatLng(47.0707, 15.4395),
      'Hut',
    ),
    (
      'https://maps.google.com/?q=47.07,15.44',
      const LatLng(47.07, 15.44),
      null,
    ),
    ('geo:47.0707,15.4395', const LatLng(47.0707, 15.4395), null),
  ]) {
    testWidgets('a link with coordinates still converts: $link', (
      tester,
    ) async {
      String? replaced;
      final controller = await pump(tester, (wire) => replaced = wire);
      controller.text = link;
      await tester.pumpAndSettle();
      expect(
        find.text('Looks like a maps link. Convert it to a Location?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
      final message = StructuredMessage.parse(replaced!) as LocationMessage;
      expect(message.position, position);
      expect(message.label, label);
      expect(network.clients, 0);
    });
  }
}
