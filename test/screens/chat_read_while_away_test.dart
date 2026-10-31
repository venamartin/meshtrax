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
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// An open chat counted as being read whatever was on screen: leaving the app
// on Public and coming back found everything read, with nothing to show what
// was missed (owner, 2026-10-31).
class _Radio extends MeshCoreConnector {
  final posts = StreamController<List<ChannelMessage>>.broadcast();
  final dms = StreamController<List<Message>>.broadcast();
  final channelsActive = <int?>[];
  final contactsActive = <String?>[];
  int unread = 0;

  /// Unread at the moment the chat went active, which zeroes it.
  int? unreadWhenActive;

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

  @override
  int getUnreadCountForChannelIndex(int channelIndex) => unread;

  @override
  int getUnreadCountForContactKey(String contactKeyHex) => unread;

  @override
  void setActiveChannel(int? channelIndex) {
    channelsActive.add(channelIndex);
    if (channelIndex != null) {
      unreadWhenActive = unread;
      unread = 0;
    }
  }

  @override
  void setActiveContact(String? contactKeyHex) {
    contactsActive.add(contactKeyHex);
    if (contactKeyHex != null) {
      unreadWhenActive = unread;
      unread = 0;
    }
  }
}

final _start = DateTime(2026, 10, 31, 8);

ChannelMessage _post(int i) => ChannelMessage(
      senderKey: null,
      senderName: 'Ann',
      text: 'post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: false,
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

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _goAway(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
}

Future<void> _comeBack(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _settle(tester);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final channel = Channel(index: 1, name: '#test', psk: Uint8List(16));
  final navigator = GlobalKey<NavigatorState>();

  Future<_Radio> pump(WidgetTester tester, Widget screen) async {
    final radio = _Radio();
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
          navigatorKey: navigator,
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

  Future<_Radio> openChannel(WidgetTester tester, {int count = 10}) async {
    final radio = await pump(tester, ChannelChatScreen(channel: channel));
    radio.posts.add([for (var i = 0; i < count; i++) _post(i)]);
    await _settle(tester);
    return radio;
  }

  Future<void> receivePosts(WidgetTester tester, _Radio radio, int total) async {
    radio.posts.add([for (var i = 0; i < total; i++) _post(i)]);
    await tester.pump();
  }

  final newMessages = find.text('NEW MESSAGES');

  testWidgets('messages missed while away show under a divider on return',
      (tester) async {
    final radio = await openChannel(tester);
    expect(newMessages, findsNothing);
    expect(radio.channelsActive, [1]);

    await _goAway(tester);
    await receivePosts(tester, radio, 12);
    radio.unread = 2;

    await _comeBack(tester);

    expect(radio.unreadWhenActive, 2,
        reason: 'the divider needs the count from before it was zeroed');
    expect(newMessages, findsOneWidget);
    expect(radio.channelsActive, [1, 1]);
  });

  testWidgets('nothing missed: no divider', (tester) async {
    await openChannel(tester);

    await _goAway(tester);
    await _comeBack(tester);

    expect(newMessages, findsNothing);
  });

  testWidgets('the notification shade is not leaving', (tester) async {
    final radio = await openChannel(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);

    expect(newMessages, findsNothing);
    expect(radio.channelsActive.where((c) => c == null), isEmpty);
  });

  testWidgets('a page on top stops the chat being read until it comes off',
      (tester) async {
    final radio = await openChannel(tester);

    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const Scaffold()),
    );
    await _settle(tester);
    expect(radio.channelsActive, [1, null]);

    await receivePosts(tester, radio, 11);
    radio.unread = 1;

    navigator.currentState!.pop();
    await _settle(tester);

    expect(radio.channelsActive, [1, null, 1]);
    expect(radio.unreadWhenActive, 1);
  });

  testWidgets('a dialog on top is still reading the chat', (tester) async {
    final radio = await openChannel(tester);

    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(),
    );
    await _settle(tester);

    expect(radio.channelsActive, [1]);
  });

  testWidgets('coming back under a page leaves the top page in charge',
      (tester) async {
    final radio = await openChannel(tester);

    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const Scaffold()),
    );
    await _settle(tester);

    await _goAway(tester);
    await _comeBack(tester);

    expect(radio.channelsActive, [1, null]);
  });

  testWidgets('closing a second copy of the chat leaves the first one active',
      (tester) async {
    final radio = await openChannel(tester);

    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
    );
    await tester.pump();
    radio.posts.add([for (var i = 0; i < 10; i++) _post(i)]);
    await _settle(tester);

    navigator.currentState!.pop();
    await _settle(tester);

    expect(radio.channelsActive.last, 1,
        reason: 'the copy underneath is on screen and being read');
  });

  testWidgets('closing the chat ends the active state', (tester) async {
    final radio = await pump(tester, const Scaffold());

    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
    );
    await tester.pump();
    radio.posts.add([for (var i = 0; i < 10; i++) _post(i)]);
    await _settle(tester);
    expect(radio.channelsActive, [1]);

    navigator.currentState!.pop();
    await _settle(tester);

    expect(radio.channelsActive, [1, null]);
  });

  testWidgets('a DM catches up the same way', (tester) async {
    final contact = Contact.fromFrame(_contactFrame('Peer'))!;
    final radio = await pump(tester, ChatScreen(contact: contact));
    radio.dms.add([for (var i = 0; i < 10; i++) _dm(i)]);
    await _settle(tester);
    expect(radio.contactsActive, [contact.publicKeyHex]);
    expect(newMessages, findsNothing);

    await _goAway(tester);
    radio.dms.add([for (var i = 0; i < 12; i++) _dm(i)]);
    await tester.pump();
    radio.unread = 2;

    await _comeBack(tester);

    expect(radio.unreadWhenActive, 2);
    expect(newMessages, findsOneWidget);
  });
}
