import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A tap on the little quote in a reply opened the path screen more often than
// the original: a quote with no stored link had no tap of its own, and one with
// a link gave no sign of where it went when the original was on screen (owner,
// 2026-11-01).
class _Radio extends MeshCoreConnector {
  final posts = StreamController<List<ChannelMessage>>.broadcast();
  final dms = StreamController<List<Message>>.broadcast();
  final limits = <int>[];
  ({ChannelMessage message, int fromNewest})? target;
  List<({ChannelMessage message, int fromNewest})> searchHits = const [];
  List<Message> room = const [];
  List<ChannelMessage> channelRows = const [];

  @override
  bool get isConnected => true;

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) {
    limits.add(limit);
    if (limits.length > 1) {
      // Comes from the database's isolate, after the next frame.
      return Stream.fromFuture(
        Future.delayed(const Duration(milliseconds: 50), () => channelRows),
      );
    }
    return posts.stream;
  }

  @override
  Stream<List<Message>> watchConversation(Contact contact, {int limit = 200}) {
    limits.add(limit);
    final start = room.length > limit ? room.length - limit : 0;
    final rows = room.sublist(start);
    if (limits.length == 1) return Stream.value(rows);
    return Stream.fromFuture(
      Future.delayed(const Duration(milliseconds: 50), () => rows),
    );
  }

  @override
  Future<List<({ChannelMessage message, int fromNewest})>> searchChannelMessages(
    Channel channel,
    String query,
  ) async =>
      searchHits;

  @override
  Future<({ChannelMessage message, int fromNewest})?> findChannelReplyTarget(
    Channel channel,
    ChannelMessage reply,
  ) async =>
      target;
}

final _start = DateTime(2026, 11, 1, 8);

ChannelMessage _post(
  int i, {
  String sender = 'Ann',
  String? text,
  String? replyTo,
  String? quotedSender,
  String? quoted,
}) =>
    ChannelMessage(
      senderKey: null,
      senderName: sender,
      text: text ?? 'post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
      messageId: 'p$i',
      replyToMessageId: replyTo,
      replyToSenderName: quotedSender,
      replyToText: quoted,
    );

final _roomKey = Uint8List.fromList(List.generate(32, (i) => 0x40 + i));
final _authorKey = Uint8List.fromList(List.generate(32, (i) => 0x60 + i));

Message _roomPost(int i, {String? text}) => Message(
      senderKey: _roomKey,
      text: text ?? 'room post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: false,
      status: MessageStatus.sent,
      messageId: 'r$i',
      fourByteRoomContactKey: _authorKey.sublist(0, 4),
    );

/// The chat's double-tap (zoom reset) holds every tap for this long.
Future<void> tapLands(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final channel = Channel(index: 1, name: '#test', psk: Uint8List(16));
  final notFound = find.text('Original message not found');

  Future<_Radio> pump(WidgetTester tester, Widget screen, _Radio radio) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(radio.posts.close);
    addTearDown(radio.dms.close);
    addTearDown(radio.dispose);
    await tester.pumpWidget(
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
          navigatorObservers: [NotificationService.routeObserver],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    );
    await tester.pump();
    return radio;
  }

  Future<_Radio> openChannel(
    WidgetTester tester,
    List<ChannelMessage> posts,
  ) async {
    final radio = await pump(
      tester,
      ChannelChatScreen(channel: channel),
      _Radio()..channelRows = posts,
    );
    radio.posts.add(posts);
    await tester.pumpAndSettle();
    return radio;
  }

  Finder tint(String text) => find.ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(12) &&
              (w.decoration as BoxDecoration).color?.a == 0.12,
        ),
      );

  // The room's tint wraps a whole row, so it is found from the widget itself.
  Finder roomTint() => find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(12) &&
            ((w.decoration as BoxDecoration).color?.a ?? 0) == 0.12,
      );

  group('a channel quote', () {
    testWidgets('jumps to a linked original far up the list and tints it',
        (tester) async {
      final posts = [
        for (var i = 0; i < 60; i++) _post(i),
        _post(
          60,
          replyTo: 'p0',
          quotedSender: 'Ann',
          quoted: 'post 0',
        ),
      ];
      final radio = await openChannel(tester, posts);
      radio.target = (message: posts.first, fromNewest: 60);
      expect(find.text('post 1'), findsNothing);

      await tester.tap(find.text('Reply to Ann'));
      await tapLands(tester);
      await tester.pumpAndSettle();

      expect(find.text('post 1'), findsOneWidget);
      expect(tint('post 1'), findsNothing);
      expect(tint('Ann').evaluate(), isNotEmpty);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tint('Ann'), findsNothing, reason: 'the tint fades by itself');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('says so when the original cannot be found', (tester) async {
      await openChannel(tester, [
        _post(0),
        _post(1, quotedSender: 'Bob', quoted: 'never heard'),
      ]);

      await tester.tap(find.text('Reply to Bob'));
      await tapLands(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(notFound, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('takes a tap in its gap and in its empty width', (tester) async {
      await openChannel(tester, [
        _post(0, text: 'a long reply that runs wider than the quote above it'),
        _post(1, quotedSender: 'B', quoted: 'x'),
      ]);
      final box = tester.getRect(
        find
            .ancestor(
              of: find.text('Reply to B'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(box.width, greaterThanOrEqualTo(160));

      for (final spot in [
        Offset(box.right - 2, box.center.dy),
        Offset(box.left + 4, box.bottom + 4),
      ]) {
        await tester.tapAt(spot);
        await tapLands(tester);
        await tester.pump(const Duration(milliseconds: 100));
        expect(notFound, findsOneWidget, reason: 'tap at $spot');
        ScaffoldMessenger.of(
          tester.element(find.byType(ChannelChatScreen)),
        ).clearSnackBars();
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tints the original even with a search match showing',
        (tester) async {
      final posts = [
        for (var i = 0; i < 3; i++) _post(i),
        _post(3, replyTo: 'p0', quotedSender: 'Ann', quoted: 'post 0'),
      ];
      final radio = await openChannel(tester, posts);
      radio.target = (message: posts.first, fromNewest: 3);
      radio.searchHits = [(message: posts[1], fromNewest: 2)];
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(TextField),
        ),
        'post 1',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(tint('post 1'), findsWidgets);

      await tester.tap(find.text('Reply to Ann'));
      await tapLands(tester);
      await tester.pumpAndSettle();

      expect(tint('post 1'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('grows the loaded window for an older original', (tester) async {
      final older = _post(0, text: 'way back');
      final window = [
        for (var i = 1; i <= 200; i++) _post(i),
        _post(201, quotedSender: 'Ann', quoted: 'way back'),
      ];
      final radio = await openChannel(tester, window);
      radio
        ..channelRows = [older, ...window]
        ..target = (message: older, fromNewest: 201);

      await tester.tap(find.text('Reply to Ann'));
      await tapLands(tester);
      await tester.pumpAndSettle();

      expect(radio.limits.last, 400);
      expect(notFound, findsNothing);
      expect(find.text('way back'), findsOneWidget);
      expect(find.text('post 201'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('a room quote', () {
    final room = Contact(
      publicKey: _roomKey,
      name: 'Room',
      type: advTypeRoom,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: _start,
    );
    // Name resolution needs an author in contacts; the hex stands in for one.
    final authorHex = pubKeyToHex(_authorKey.sublist(0, 4)).toUpperCase();

    Future<_Radio> openRoom(WidgetTester tester, List<Message> posts) async {
      final radio = await pump(
        tester,
        ChatScreen(contact: room),
        _Radio()..room = posts,
      );
      await tester.pumpAndSettle();
      return radio;
    }

    testWidgets('says so when the history runs out', (tester) async {
      await openRoom(tester, [
        _roomPost(0),
        _roomPost(1, text: '@[Bob]\n>never hea..\nmy answer'),
      ]);

      await tester.tap(find.text('Reply to Bob'));
      await tapLands(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(notFound, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pages back to an older original', (tester) async {
      final posts = [
        _roomPost(0, text: 'way back when'),
        for (var i = 1; i <= 200; i++) _roomPost(i),
        _roomPost(201, text: '@[$authorHex]\n>way back w..\nmy answer'),
      ];
      final radio = await openRoom(tester, posts);
      expect(radio.limits, [200]);

      await tester.tap(find.text('Reply to $authorHex'));
      await tapLands(tester);
      await tester.pumpAndSettle();

      expect(radio.limits, [200, 400]);
      expect(notFound, findsNothing);
      expect(find.text('room post 1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pages back more than once without snapping to the newest',
        (tester) async {
      final posts = [
        _roomPost(0, text: 'way back when'),
        for (var i = 1; i <= 450; i++) _roomPost(i),
        _roomPost(451, text: '@[$authorHex]\n>way back w..\nmy answer'),
      ];
      final radio = await openRoom(tester, posts);

      await tester.tap(find.text('Reply to $authorHex'));
      await tapLands(tester);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(radio.limits, [200, 400, 600]);
      expect(find.text('room post 1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a second tap while a page loads does not call it missing',
        (tester) async {
      final posts = [
        _roomPost(0, text: 'way back when'),
        for (var i = 1; i <= 200; i++) _roomPost(i),
        _roomPost(201, text: '@[$authorHex]\n>way back w..\nmy answer'),
      ];
      await openRoom(tester, posts);
      final quote = tester.getCenter(find.text('Reply to $authorHex'));

      await tester.tapAt(quote);
      // The tap lands, and its page takes 50 ms. Tap again before that.
      await tester.pump(const Duration(milliseconds: 320));
      await tester.tapAt(quote);
      await tester.pump(const Duration(milliseconds: 20));

      expect(notFound, findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(notFound, findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tints an original that is already on screen, then fades',
        (tester) async {
      await openRoom(tester, [
        _roomPost(0, text: 'way back when'),
        _roomPost(1, text: '@[$authorHex]\n>way back w..\nmy answer'),
      ]);
      expect(roomTint(), findsNothing);

      await tester.tap(find.text('Reply to $authorHex'));
      await tapLands(tester);
      await tester.pumpAndSettle();
      expect(roomTint(), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(roomTint(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('findReplyTarget', () {
    const idKey = 'k';
    late ChannelMessageStore store;

    setUp(() async {
      store = ChannelMessageStore()..setPublicKeyHex = 'deadbeef00cafe';
    });

    Future<void> put(ChannelMessage m) async {
      await store.insertIfNew(idKey, m, unreadEligible: false);
      // Row order is by arrival, to the microsecond.
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    test('a link finds its row and how far back it is', () async {
      await put(_post(0, text: 'first'));
      await put(_post(1));
      final reply = _post(2, replyTo: 'p0', quotedSender: 'Ann', quoted: 'first');
      await put(reply);

      final found = await store.findReplyTarget(idKey, reply);

      expect(found!.message.messageId, 'p0');
      expect(found.fromNewest, 2);
    });

    test('a stale link finds nothing', () async {
      final reply = _post(2, replyTo: 'gone', quotedSender: 'Ann', quoted: 'x');
      await put(reply);
      expect(await store.findReplyTarget(idKey, reply), isNull);
    });

    test('no link matches sender and snippet, nearest before the reply', () async {
      await put(_post(0, text: 'hello world, the older one'));
      await put(_post(1, text: 'Hello  World, the right one'));
      await put(_post(2, sender: 'Bob', text: 'hello world Ann, wrong sender'));
      final reply = _post(3, sender: 'Cy', quotedSender: 'Ann', quoted: 'hello worl');
      await put(reply);
      await put(_post(4, text: 'hello world, after the reply'));

      final found = await store.findReplyTarget(idKey, reply);

      expect(found!.message.messageId, 'p1');
    });

    test('an original that arrived after its reply still counts', () async {
      final reply = _post(0, sender: 'Cy', quotedSender: 'Ann', quoted: 'late one');
      await put(reply);
      await put(_post(1, text: 'late one, heard after the reply'));
      await put(_post(2, text: 'late one again'));

      final found = await store.findReplyTarget(idKey, reply);

      expect(found!.message.messageId, 'p1');
    });

    test('an empty snippet matches nothing rather than anything', () async {
      await put(_post(0));
      final reply = _post(1, sender: 'Cy', quotedSender: 'Ann', quoted: ' ');
      await put(reply);
      expect(await store.findReplyTarget(idKey, reply), isNull);
    });

    test('a reply does not match itself', () async {
      final reply = _post(0, text: 'same words', quotedSender: 'Ann', quoted: 'same');
      await put(reply);
      expect(await store.findReplyTarget(idKey, reply), isNull);
    });
  });
}
