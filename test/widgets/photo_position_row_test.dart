import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/widgets/photo_message_card.dart';
import 'package:provider/provider.dart';
import 'package:traxpix/traxpix.dart';

void main() {
  testWidgets('a photo position says where, how exact, with Map and Navigate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsService>(
        create: (_) => AppSettingsService(),
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PhotoPositionRow(
              PhotoPosition.at(57.64911, 10.40744, bytes: 5),
              label: 'Camp',
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('57.64'), findsOneWidget);
    expect(find.textContaining(', to about 40 m'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
  });
}
