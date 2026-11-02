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

// The chat screens watch the newest 200 rows, so in a busy channel a new
// message pushes the oldest out and the row count never changes. Following
// the newest message went by that count: a send or a receive left the new
// row hanging below the screen (owner, 2026-10-30).
class _Radio extends MeshCoreConnector {
  final posts = StreamController<List<ChannelMessage>>.broadcast();
  final dms = StreamController<List<Message>>.broadcast();

  @override
  bool get isConnected => true;

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) =>
      posts.stream;

  @override
  Stream<List<Message>> watchConversation(Contact contact, {int limit = 200}) =>
      dms.stream;
}

final _start = DateTime(2026, 10, 30, 8);

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

Message _dm(int i, {bool outgoing = false}) => Message(
      senderKey: _peerKey,
      text: 'dm $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: outgoing,
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

Future<void> _pumpScreen(WidgetTester tester, _Radio radio, Widget screen) =>
    tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
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

Finder get _listFinder => find.byType(ScrollablePositionedList);

/// The whole bubble, not just its first line: the row in the owner's
/// screenshot showed its text with the rest cut off by the composer.
Rect _rowRect(WidgetTester tester, String text) => tester.getRect(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(SizeChangedLayoutNotifier),
          )
          .first,
    );

void _expectFullyOnScreen(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget, reason: '$text was not built');
  expect(
    _rowRect(tester, text).bottom,
    lessThanOrEqualTo(tester.getRect(_listFinder).bottom),
    reason: '$text hangs below the list',
  );
}

double _jumpButtonScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(find.ancestor(
      of: find.byType(FloatingActionButton),
      matching: find.byType(AnimatedScale),
    ))
    .scale;

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final channel = Channel(index: 1, name: '#test', psk: Uint8List(16));

  /// A full watched window: each new row drops the oldest, like a channel
  /// with more than 200 messages stored.
  List<ChannelMessage> window(
    int newest, {
    Set<int> mine = const {},
    Map<int, String> texts = const {},
  }) =>
      [
        for (var i = newest - 199; i <= newest; i++)
          _post(i, outgoing: mine.contains(i), text: texts[i]),
      ];

  // Taller than the row before it. A list opened on an older row keeps its
  // rows in the same slots, so a new row of the same height still fits: only
  // a taller one hung below the screen, which is why this came and went.
  const tall = 'one\ntwo\nthree\nfour\nfive';

  Future<_Radio> openChannel(WidgetTester tester, {int? unread}) async {
    final radio = _Radio();
    addTearDown(radio.posts.close);
    addTearDown(radio.dms.close);
    await _pumpScreen(
      tester,
      radio,
      ChannelChatScreen(channel: channel, unreadCount: unread),
    );
    radio.posts.add(window(299));
    await _settle(tester);
    return radio;
  }

  testWidgets('opened at the bottom: a received row is followed',
      (tester) async {
    final radio = await openChannel(tester);
    radio.posts.add(window(300));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'post 300');
  });

  testWidgets('opened on NEW MESSAGES: a taller received row is followed',
      (tester) async {
    final radio = await openChannel(tester, unread: 2);
    expect(find.text('NEW MESSAGES'), findsOneWidget);
    await tester.drag(_listFinder, const Offset(0, -2000));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'post 299');

    radio.posts.add(window(300, texts: {300: tall}));
    await _settle(tester);
    _expectFullyOnScreen(tester, tall);
  });

  testWidgets('opened on NEW MESSAGES: our taller send is followed',
      (tester) async {
    final radio = await openChannel(tester, unread: 2);
    expect(find.text('NEW MESSAGES'), findsOneWidget);
    await tester.drag(_listFinder, const Offset(0, -2000));
    await _settle(tester);

    radio.posts.add(window(300, mine: {300}, texts: {300: tall}));
    await _settle(tester);
    _expectFullyOnScreen(tester, tall);
  });

  testWidgets('opened on NEW MESSAGES: the newest row growing stays in view',
      (tester) async {
    // A GIF loading, or a repeat adding the via line: no new row at all.
    final radio = await openChannel(tester, unread: 2);
    expect(find.text('NEW MESSAGES'), findsOneWidget);
    await tester.drag(_listFinder, const Offset(0, -2000));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'post 299');

    radio.posts.add(window(299, texts: {299: tall}));
    await _settle(tester);
    _expectFullyOnScreen(tester, tall);
  });

  testWidgets('newest row partly off screen: a received row is followed',
      (tester) async {
    final radio = await openChannel(tester);
    await tester.drag(_listFinder, const Offset(0, 30 + kDragSlopDefault));
    await _settle(tester);
    expect(find.text('post 299'), findsOneWidget, reason: 'still in view');

    radio.posts.add(window(300));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'post 300');
  });

  testWidgets('a reader far up stays there when a row is received',
      (tester) async {
    final radio = await openChannel(tester);
    await tester.drag(_listFinder, const Offset(0, 3000));
    await _settle(tester);
    expect(find.text('post 299'), findsNothing);
    expect(_jumpButtonScale(tester), 1.0);

    radio.posts.add(window(300));
    await _settle(tester);
    expect(find.text('post 300'), findsNothing);
    expect(_jumpButtonScale(tester), 1.0);
  });

  testWidgets('a reader far up is brought down by our own send',
      (tester) async {
    final radio = await openChannel(tester);
    await tester.drag(_listFinder, const Offset(0, 3000));
    await _settle(tester);
    expect(find.text('post 299'), findsNothing);

    radio.posts.add(window(300, mine: {300}));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'post 300');
  });

  testWidgets('the newest row removed: a reader far up stays there',
      (tester) async {
    // A parked reaction's stub is deleted when it lands; if the row under
    // it is ours, that is not a send.
    final radio = _Radio();
    addTearDown(radio.posts.close);
    addTearDown(radio.dms.close);
    await _pumpScreen(tester, radio, ChannelChatScreen(channel: channel));
    final rows = window(299, mine: {298});
    radio.posts.add(rows);
    await _settle(tester);
    await tester.drag(_listFinder, const Offset(0, 3000));
    await _settle(tester);
    expect(find.text('post 298'), findsNothing);

    radio.posts.add(rows.sublist(0, rows.length - 1));
    await _settle(tester);
    expect(find.text('post 298'), findsNothing);
  });

  testWidgets('DM: a received row and our send are followed', (tester) async {
    final radio = _Radio();
    addTearDown(radio.posts.close);
    addTearDown(radio.dms.close);
    radio.handleFrameForTest(_contactFrame('Whale'));
    await _pumpScreen(tester, radio, ChatScreen(contact: radio.contacts.single));
    List<Message> dms(int newest, {Set<int> mine = const {}}) => [
          for (var i = newest - 199; i <= newest; i++)
            _dm(i, outgoing: mine.contains(i)),
        ];
    radio.dms.add(dms(299));
    await _settle(tester);

    await tester.drag(_listFinder, const Offset(0, 30 + kDragSlopDefault));
    await _settle(tester);
    expect(find.text('dm 299'), findsOneWidget, reason: 'still in view');
    radio.dms.add(dms(300));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'dm 300');

    await tester.drag(_listFinder, const Offset(0, 3000));
    await _settle(tester);
    expect(find.text('dm 300'), findsNothing);
    radio.dms.add(dms(301, mine: {301}));
    await _settle(tester);
    _expectFullyOnScreen(tester, 'dm 301');
  });
}
