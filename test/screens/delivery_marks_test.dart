import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/screens/chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Your own channel text that no radio repeated and no observer heard gets
// an amber check once the wait for a repeat is over; one that didn't go is
// red, as a failed DM is. A DM's radio ACK reads "Received".
class _Radio extends MeshCoreConnector {
  _Radio({this.channelRows = const [], this.dmRows = const []});
  final List<ChannelMessage> channelRows;
  final List<Message> dmRows;
  final retrying = <String>{};

  @override
  bool get isConnected => true;

  @override
  bool isChannelMessageRetrying(String messageId) =>
      retrying.contains(messageId);

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) => Stream.value(channelRows);

  @override
  Stream<List<Message>> watchConversation(Contact contact, {int limit = 200}) =>
      Stream.value(dmRows);
}

final _peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
final _channel = Channel(index: 1, name: '#trip', psk: Uint8List(16));
final _peer = Contact(
  publicKey: _peerKey,
  name: 'Bob',
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime.now(),
);

ChannelMessage _mine(
  String text, {
  ChannelMessageStatus status = ChannelMessageStatus.sent,
  int repeats = 0,
}) => ChannelMessage(
  senderName: 'Base',
  text: text,
  timestamp: DateTime.now(),
  isOutgoing: true,
  status: status,
  channelIndex: 1,
  messageId: text,
  repeatCount: repeats,
);

const _noSign = 'Sent · no sign of who got it';

final _amberCheck = find.byWidgetPredicate(
  (w) => w is Icon && w.icon == Icons.check && w.color == Colors.amber[700],
);
final _redCross = find.byWidgetPredicate(
  (w) => w is Icon && w.icon == Icons.cancel && w.color == Colors.red,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'heard_check_heard': jsonEncode({
        'Heard by Ridge': [
          {'observer': 'Ridge'},
        ],
      }),
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    required _Radio radio,
    bool tracing = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
    final settings = AppSettingsService();
    await settings.setEnableMessageTracing(tracing);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tracing in [false, true]) {
    final mode = 'tracing ${tracing ? 'on' : 'off'}';

    testWidgets('no repeat and the wait over: an amber check ($mode)', (
      tester,
    ) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        tracing: tracing,
        radio: _Radio(channelRows: [_mine('At the spring')]),
      );
      expect(_amberCheck, findsOneWidget);
      expect(find.byTooltip(_noSign), findsOneWidget);
    });

    testWidgets('still listening for a repeat: a grey check ($mode)', (
      tester,
    ) async {
      final radio = _Radio(channelRows: [_mine('At the spring')])
        ..retrying.add('At the spring');
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        tracing: tracing,
        radio: radio,
      );
      expect(_amberCheck, findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.check && w.color == Colors.grey[600],
        ),
        findsOneWidget,
      );
    });

    testWidgets('repeated, or heard by an observer: no amber ($mode)', (
      tester,
    ) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        tracing: tracing,
        radio: _Radio(
          channelRows: [
            _mine(
              'Repeated',
              status: ChannelMessageStatus.delivered,
              repeats: 1,
            ),
            _mine('Heard by Ridge'),
          ],
        ),
      );
      expect(find.text('Repeated'), findsOneWidget);
      expect(find.text('Heard by Ridge'), findsOneWidget);
      expect(_amberCheck, findsNothing);
    });

    testWidgets('a text that didn\'t go is red ($mode)', (tester) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        tracing: tracing,
        radio: _Radio(
          channelRows: [
            _mine('Never went', status: ChannelMessageStatus.failed),
          ],
        ),
      );
      expect(_redCross, findsOneWidget);
      expect(_amberCheck, findsNothing);
    });

    testWidgets('not yet sent by the radio: the clock ($mode)', (
      tester,
    ) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        tracing: tracing,
        radio: _Radio(
          channelRows: [_mine('Typed', status: ChannelMessageStatus.pending)],
        ),
      );
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(_amberCheck, findsNothing);
    });
  }

  testWidgets('a long press on the amber check says it in words', (
    tester,
  ) async {
    await open(
      tester,
      ChannelChatScreen(channel: _channel),
      radio: _Radio(channelRows: [_mine('At the spring')]),
    );
    await tester.longPress(_amberCheck);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_noSign), findsOneWidget);
  });

  testWidgets('a DM their radio ACKed says Received, not "Delivered"', (
    tester,
  ) async {
    await open(
      tester,
      ChatScreen(contact: _peer),
      radio: _Radio(
        dmRows: [
          Message(
            senderKey: _peerKey,
            text: 'See you there',
            timestamp: DateTime.now(),
            isOutgoing: true,
            status: MessageStatus.delivered,
            messageId: 'See you there',
            tripTimeMs: 2300,
          ),
        ],
      ),
    );
    expect(find.textContaining('Received · 2.3 s'), findsOneWidget);
    expect(find.textContaining('Delivered'), findsNothing);
  });
}
