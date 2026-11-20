import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
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

// The owner, 2026-11-19: a tiny grey icon, like the observer ear, on a
// message MeshTrax picked up on its way, to show that it is working. His
// pick of six: airwave.
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
final _at = DateTime(2026, 11, 19, 13, 9);

Message _dm(String text, {String? hopsLeft, bool outgoing = false}) => Message(
      senderKey: _peerKey,
      text: text,
      timestamp: _at,
      isOutgoing: outgoing,
      status: MessageStatus.sent,
      messageId: text,
      passingCopyHopsLeft: hopsLeft,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> open(WidgetTester tester, {required bool tracing}) async {
    final settings = AppSettingsService();
    await settings.setEnableMessageTracing(tracing);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Radio([
              _dm('picked up', hopsLeft: '7E7E'),
              _dm('opened by the radio'),
              _dm('mine', outgoing: true),
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
  }

  for (final tracing in [true, false]) {
    testWidgets('only the message picked up on its way shows the grey icon, '
        'tracing ${tracing ? 'on' : 'off'}', (tester) async {
      await open(tester, tracing: tracing);
      final icon = find.byIcon(Symbols.airwave);
      expect(icon, findsOneWidget);
      expect(
        tester.widget<Icon>(icon).semanticLabel,
        'Picked up on its way, 7E7E still to go',
      );
      expect(tester.widget<Icon>(icon).color, Colors.grey[600]);
      // In the picked-up message's bubble, not another one.
      final bubble = find.ancestor(
        of: find.text('picked up'),
        matching: find.byType(Container),
      );
      expect(
        find.descendant(of: bubble.first, matching: icon),
        findsOneWidget,
      );
    });
  }
}
