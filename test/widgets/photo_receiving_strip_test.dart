import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/photo_mesh.dart';
import 'package:meshtrax/services/photo_reassembler.dart';
import 'package:meshtrax/widgets/photo_receiving_strip.dart';

// Martin, 2026-11-27: the asks for a photo's lost packets are grouped, so
// the line says when the ask waits its turn and when someone else asked.
void main() {
  PhotoReceiving line({
    bool canAsk = false,
    bool asking = false,
    bool othersAsked = false,
    int asked = 0,
  }) => (
    key: const ImageStreamKey(
      senderPrefix: 0xBEEF,
      imgId: 0x3a,
      channelIndex: 1,
    ),
    senderName: 'Bob',
    received: 2,
    total: 4,
    lost: 2,
    canAsk: canAsk,
    asking: asking,
    othersAsked: othersAsked,
    asked: asked,
  );

  Future<void> show(WidgetTester tester, PhotoReceiving r) async {
    PhotoMesh.receiving.value = [r];
    addTearDown(() => PhotoMesh.receiving.value = const []);
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: PhotoReceivingStrip(
            channel: Channel(index: 1, name: 'Trip', psk: Uint8List(16)),
          ),
        ),
      ),
    );
    // A no-break space keeps "2 lost" on one line.
    expect(
      find.text('📷 Photo #3a from Bob: 2 of 4 packets, 2\u00A0lost'),
      findsOneWidget,
    );
  }

  testWidgets('lost packets offer Ask for the rest', (tester) async {
    await show(tester, line(canAsk: true));
    expect(find.text('Ask for the rest'), findsOneWidget);
  });

  testWidgets('while the ask waits its turn, the line says Asking…', (
    tester,
  ) async {
    await show(tester, line(asking: true));
    expect(find.text('Asking…'), findsOneWidget);
    expect(find.text('Ask for the rest'), findsNothing);
  });

  testWidgets('when someone else asked, the line says so', (tester) async {
    await show(tester, line(othersAsked: true));
    expect(find.text('Someone asked; waiting'), findsOneWidget);
    expect(find.text('Ask for the rest'), findsNothing);
  });

  testWidgets('after this phone asked, the line says for how many', (
    tester,
  ) async {
    await show(tester, line(asked: 2));
    expect(find.text('Asked for 2 packets'), findsOneWidget);
  });
}
