import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_message_path_screen.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// A DM the app opened from a copy still on its route says so on the Path
// line of its details, with the hops it still had to go; the radio reports
// a routed DM's hops as unknown, which reads "Flood" for every other DM.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> show(WidgetTester tester, {String? hopsLeft}) async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: connector,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChannelMessagePathScreen(
            message: ChannelMessage(
              senderName: 'A',
              text: 'hello B',
              timestamp: DateTime(2026, 11, 19, 9, 30),
              isOutgoing: false,
              pathLength: -1,
              pathBytes: Uint8List(0),
            ),
            channelMessage: true,
            passingCopyHopsLeft: hopsLeft,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a DM picked up on its way: the hops it still had to go',
      (tester) async {
    await show(tester, hopsLeft: 'AD77,BEEF');
    expect(find.text('Picked up on its way, AD77,BEEF still to go'),
        findsOneWidget);
    expect(find.text('Flood'), findsNothing);
  });

  testWidgets('any other DM keeps its path line', (tester) async {
    await show(tester);
    expect(find.text('Flood'), findsOneWidget);
    expect(find.textContaining('Picked up'), findsNothing);
  });
}
