import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The owner, 2026-11-21: a DM waiting for a repeater read "No repeater
// heard you", which confuses people standing next to their repeater. It
// says nothing now: only the wait icon shows.
class _Radio extends MeshCoreConnector {
  _Radio(this.messages);

  final List<Message> messages;

  @override
  bool get isConnected => true;

  @override
  Stream<List<Message>> watchConversation(
    Contact contact, {
    int limit = 200,
  }) async* {
    yield messages;
  }
}

final _peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
final _at = DateTime(2026, 11, 21, 15, 0);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  for (final tracing in [true, false]) {
    testWidgets('a DM waiting for a repeater shows the wait icon and no '
        'words, tracing ${tracing ? 'on' : 'off'}', (tester) async {
      final settings = AppSettingsService();
      await settings.setEnableMessageTracing(tracing);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MeshCoreConnector>.value(
              value: _Radio([
                Message(
                  senderKey: _peerKey,
                  text: 'parked',
                  timestamp: _at,
                  isOutgoing: true,
                  status: MessageStatus.sent,
                  messageId: 'parked',
                  pathLength: -1,
                  waitingForRepeater: true,
                ),
              ]),
            ),
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: UiViewStateService()),
            ChangeNotifierProvider.value(value: ChatTextScaleService()),
            ChangeNotifierProvider.value(value: PathGraphService()),
            ChangeNotifierProvider.value(value: MessageRetryService()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: ChatScreen(
              contact: Contact(
                publicKey: _peerKey,
                name: 'Peer',
                type: advTypeChat,
                pathLength: -1,
                path: Uint8List(0),
                pathHashSize: 1,
                lastSeen: _at,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('parked'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.cell_tower), findsNothing);
      expect(find.textContaining('repeater'), findsNothing);
      expect(find.textContaining('Sending'), findsNothing);
    });
  }
}
