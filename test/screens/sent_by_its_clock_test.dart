import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/date_time_helper.dart';
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
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// A message the radio held past a failed queue read stands where it got
// here; under its text, a small line gives the time its sender claimed.
class _Radio extends MeshCoreConnector {
  _Radio({this.channelRows = const [], this.dmRows = const []});
  final List<ChannelMessage> channelRows;
  final List<Message> dmRows;

  @override
  bool get isConnected => true;

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

final _now = DateTime.now();
final _todayAt2 = DateTime(_now.year, _now.month, _now.day, 14);
final _yesterdayLate = DateTime(_now.year, _now.month, _now.day - 1, 23, 5);

ChannelMessage _post(String text, {DateTime? claimedAt, bool mine = false}) =>
    ChannelMessage(
      senderName: mine ? 'Base' : 'Bob',
      text: text,
      timestamp: _now,
      isOutgoing: mine,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
      messageId: text,
      claimedAt: claimedAt,
    );

Message _dm(String text, {DateTime? claimedAt, bool mine = false}) => Message(
  senderKey: _peerKey,
  text: text,
  timestamp: claimedAt ?? _now,
  isOutgoing: mine,
  status: MessageStatus.sent,
  messageId: text,
  claimedAt: claimedAt,
);

final _line = find.textContaining('by its clock');

void main() {
  final systemFormats = DateTimeHelper.systemFormats;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    // The machine running the tests must not decide how dates read.
    DateTimeHelper.systemFormats = () => null;
  });
  tearDown(() => DateTimeHelper.systemFormats = systemFormats);

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    required _Radio radio,
    bool tracing = false,
    bool h24 = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
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
          // The phone's 24-hour switch, as the app's MediaQuery passes it on.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String lineText(WidgetTester tester) => tester.widget<Text>(_line).data!;

  void expectUnder(WidgetTester tester, String text) {
    expect(
      tester.getRect(_line).top,
      greaterThanOrEqualTo(tester.getRect(find.text(text)).bottom),
      reason: 'the line stands under the text',
    );
  }

  group('channel chat', () {
    for (final tracing in [false, true]) {
      testWidgets('a held message shows its sender\'s time under the text '
          '(tracing ${tracing ? 'on' : 'off'})', (tester) async {
        await open(
          tester,
          ChannelChatScreen(channel: _channel),
          tracing: tracing,
          radio: _Radio(
            channelRows: [
              _post('Leaving camp'),
              _post('Water at the spring', claimedAt: _todayAt2),
            ],
          ),
        );
        expect(_line, findsOneWidget);
        expect(
          lineText(tester),
          matches(RegExp(r'^sent 2:00\sPM by its clock$')),
        );
        expectUnder(tester, 'Water at the spring');
      });
    }

    testWidgets('a claim from another day gives the day, the 24-hour '
        'switch its clock', (tester) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        h24: true,
        radio: _Radio(
          channelRows: [_post('Late last night', claimedAt: _yesterdayLate)],
        ),
      );
      final day = '${_yesterdayLate.month}/${_yesterdayLate.day}';
      expect(lineText(tester), 'sent $day 23:05 by its clock');
    });

    testWidgets('never on my own messages, nor on any other', (tester) async {
      await open(
        tester,
        ChannelChatScreen(channel: _channel),
        radio: _Radio(
          channelRows: [
            _post('Leaving camp'),
            _post('Heading down', mine: true, claimedAt: _todayAt2),
          ],
        ),
      );
      expect(find.text('Heading down'), findsOneWidget);
      expect(_line, findsNothing);
    });
  });

  group('DM chat', () {
    testWidgets('a held message shows its sender\'s time under the text', (
      tester,
    ) async {
      await open(
        tester,
        ChatScreen(contact: _peer),
        radio: _Radio(
          dmRows: [
            _dm('Morning'),
            _dm('Running low on water', claimedAt: _todayAt2),
          ],
        ),
      );
      expect(_line, findsOneWidget);
      expect(
        lineText(tester),
        matches(RegExp(r'^sent 2:00\sPM by its clock$')),
      );
      expectUnder(tester, 'Running low on water');
    });

    testWidgets('never on my own messages, nor on any other', (tester) async {
      await open(
        tester,
        ChatScreen(contact: _peer),
        radio: _Radio(
          dmRows: [
            _dm('Morning'),
            _dm('See you there', mine: true, claimedAt: _todayAt2),
          ],
        ),
      );
      expect(find.text('See you there'), findsOneWidget);
      expect(_line, findsNothing);
    });
  });
}
