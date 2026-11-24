import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/widgets/photo_message_card.dart';

/// A 1 x 1 PNG.
final png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('the sender\'s preview opens full screen: zoom and Enhance, '
      'no Save or menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhotoViewerScreen.preview(png, tag: 'Trailhead'),
      ),
    );
    await tester.pump();
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text(l10n.photo_enhance), findsOneWidget);
    expect(find.text('Trailhead'), findsOneWidget);
    expect(find.byTooltip(l10n.photo_save), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
