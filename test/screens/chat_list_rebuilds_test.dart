import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

// The chat screens keep their built message list until something a row
// shows changes: the connector notifies many times a second on a busy
// mesh, and building every row again on each notify was much of what a
// scroll stuttered on (owner, 2026-10-26).
class _Radio extends MeshCoreConnector {
  _Radio({this.posts = const [], this.dms = const [], this.livePosts});

  final List<ChannelMessage> posts; // oldest first
  final List<Message> dms;

  /// When set, the channel's rows as the test sends them.
  final StreamController<List<ChannelMessage>>? livePosts;
  final limits = <int>[];

  @override
  bool get isConnected => true;

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) {
    limits.add(limit);
    return livePosts?.stream ?? Stream.value(_newest(posts, limit));
  }

  @override
  Stream<List<Message>> watchConversation(Contact contact, {int limit = 200}) {
    limits.add(limit);
    return Stream.value(_newest(dms, limit));
  }

  static List<T> _newest<T>(List<T> all, int limit) =>
      all.length > limit ? all.sublist(all.length - limit) : all;
}

final _start = DateTime(2026, 10, 26, 8);

ChannelMessage _post(int i, {bool outgoing = false, String? text}) =>
    ChannelMessage(
      senderKey: null,
      senderName: outgoing ? 'Me' : 'Ann',
      text: text ?? 'post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: outgoing,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
      messageId: 'p$i',
    );

final _peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

Message _dm(int i) => Message(
      senderKey: _peerKey,
      text: 'dm $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: false,
      status: MessageStatus.sent,
      messageId: 'd$i',
    );

Uint8List _contactFrame(String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(_peerKey);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

// As in main: the services outlive every screen (a closing chat still
// saves its draft to one).
Future<void> _pumpScreen(
  WidgetTester tester,
  _Radio radio,
  Widget screen, {
  ChatTextScaleService? textScale,
}) =>
    tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(
              value: textScale ?? ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    );

Widget _list(WidgetTester tester) =>
    tester.widget(find.byType(ScrollablePositionedList));

// The connector batches its notifies (50 ms).
Future<void> _notified(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 100));

double _jumpButtonScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(find.ancestor(
      of: find.byType(FloatingActionButton),
      matching: find.byType(AnimatedScale),
    ))
    .scale;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final channel = Channel(index: 1, name: '#test', psk: Uint8List(16));

  testWidgets('channel: paging into history keeps the reader up there',
      (tester) async {
    // Our own post is the newest: the bigger window used to pull the
    // reader back down to it.
    final radio = _Radio(posts: [
      for (var i = 0; i < 450; i++) _post(i, outgoing: i == 449),
    ]);
    await _pumpScreen(tester, radio, ChannelChatScreen(channel: channel));
    await tester.pumpAndSettle();
    expect(find.text('post 449'), findsOneWidget);

    await tester.drag(
        find.byType(ScrollablePositionedList), const Offset(0, 40000));
    await tester.pumpAndSettle();
    expect(radio.limits, [200, 400]);
    expect(find.text('post 449'), findsNothing);
    expect(find.text('post 250'), findsOneWidget,
        reason: 'still at the top of the first window');
  });

  // The list says where its rows are only on a scroll or as a new list; a
  // row that grows with no scroll (a GIF loaded, the text zoomed) must
  // still move the jump-down button and the following of new messages.
  testWidgets('channel: a row that grows back into view hides the button',
      (tester) async {
    final textScale = ChatTextScaleService();
    final radio = _Radio(posts: [for (var i = 0; i < 30; i++) _post(i)]);
    await _pumpScreen(tester, radio, ChannelChatScreen(channel: channel),
        textScale: textScale);
    await tester.pumpAndSettle();
    expect(_jumpButtonScale(tester), 0.0);

    final newest = find.ancestor(
      of: find.text('post 29'),
      matching: find.byType(SizeChangedLayoutNotifier),
    );
    final list = tester.getRect(find.byType(ScrollablePositionedList));
    // Just past the newest row: it is off the bottom edge. A scroll counts
    // from where the drag was taken, past the touch slop.
    await tester.drag(
      find.byType(ScrollablePositionedList),
      Offset(0, list.bottom - tester.getRect(newest).top + 2 + kDragSlopDefault),
    );
    await tester.pumpAndSettle();
    // Off screen, it is not built at all (no cache past this edge).
    expect(newest, findsNothing);
    expect(_jumpButtonScale(tester), 1.0);

    textScale.setScale(ChatTextScaleService.maxScale);
    await tester.pumpAndSettle();
    // The list is built anew once sizes settle.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(tester.getRect(newest).top, lessThan(list.bottom),
        reason: 'grown back into view');
    expect(_jumpButtonScale(tester), 0.0);
  });

  testWidgets('channel: a new message that resizes rows builds the list once',
      (tester) async {
    final live = StreamController<List<ChannelMessage>>.broadcast();
    final radio = _Radio(livePosts: live);
    await _pumpScreen(tester, radio, ChannelChatScreen(channel: channel));
    final posts = [for (var i = 0; i < 5; i++) _post(i)];
    live.add(posts);
    await tester.pumpAndSettle();

    // Rows are kept by index: the row that showed the newest post now
    // shows a taller one, and resizes. The new list reports by itself.
    const tall = 'one\ntwo\nthree\nfour';
    live.add([...posts, _post(5, text: tall)]);
    // The rows land after the frame they were sent in.
    while (find.text(tall).evaluate().isEmpty) {
      await tester.pump();
    }
    final built = _list(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(_list(tester), same(built));
    await live.close();
  });

  testWidgets('channel: a notify that changes nothing keeps the list',
      (tester) async {
    final radio = _Radio(posts: [for (var i = 0; i < 5; i++) _post(i)]);
    await _pumpScreen(tester, radio, ChannelChatScreen(channel: channel));
    await tester.pumpAndSettle();
    final built = _list(tester);

    radio.notifyListeners();
    await _notified(tester);
    expect(_list(tester), same(built));
  });

  testWidgets('chat: a notify keeps the list; a renamed contact rebuilds it',
      (tester) async {
    final radio = _Radio(dms: [for (var i = 0; i < 5; i++) _dm(i)]);
    radio.handleFrameForTest(_contactFrame('Whale'));
    final peer = radio.contacts.single;
    await _pumpScreen(tester, radio, ChatScreen(contact: peer));
    await tester.pumpAndSettle();
    final built = _list(tester);
    expect(find.text('Whale'), findsWidgets);

    radio.notifyListeners();
    await _notified(tester);
    expect(_list(tester), same(built));

    radio.handleFrameForTest(_contactFrame('Orca'));
    await _notified(tester);
    expect(_list(tester), isNot(same(built)));
    expect(find.text('Orca'), findsWidgets);
  });
}
