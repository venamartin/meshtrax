import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/screens/chats_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/pathfinder_help_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Public showed 90 unread, and opening it from its Chats row went to the
// bottom with no NEW MESSAGES line: the row marks the chat read before it
// opens it, and the line was looked up from the read mark (owner,
// 2026-11-07).
class _Radio extends MeshCoreConnector {
  _Radio(this.channel);

  final Channel channel;
  final store = ChannelMessageStore()..setPublicKeyHex = 'deadbeef00cafe';
  ChannelMessage? newest;
  int unread = 0;

  @override
  bool get isConnected => true;

  @override
  List<Channel> get channels => [channel];

  @override
  ChannelMessage? latestChannelMessage(Channel channel) => newest;

  @override
  int getUnreadCountForChannel(Channel channel) => unread;

  @override
  int getUnreadCountForChannelIndex(int channelIndex) => unread;

  /// The rows once, in the order the chat shows: a database watch closes on
  /// a timer the test clock never runs.
  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) =>
      Stream.fromFuture(store.loadChannelMessages(channel.idKey));

  @override
  Future<ChannelMessage?> oldestUnreadChannelMessage(
    Channel channel,
    int count,
  ) =>
      store.oldestUnread(channel.idKey, count);

  /// As the connector does: the read mark moves to the newest arrival.
  @override
  void markChannelRead(int channelIndex) {
    unread = 0;
    unawaited(store.markRead(channel.idKey));
    notifyListeners();
  }
}

final _start = DateTime(2026, 11, 7, 8);

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

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({PathfinderHelpDialog.prefKey: true});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final channel = Channel(index: 1, name: '#test', psk: Uint8List(16));

  testWidgets('a Chats row opens its chat on NEW MESSAGES', (tester) async {
    final radio = _Radio(channel);
    addTearDown(radio.dispose);
    final rows = [for (var i = 0; i < 30; i++) _post(i)];
    for (final m in rows.take(20)) {
      await radio.store.insertIfNew(channel.idKey, m);
    }
    await radio.store.markRead(channel.idKey);
    for (final m in rows.skip(20)) {
      await radio.store.insertIfNew(channel.idKey, m);
    }
    Future<int?> storedUnread() => tester.runAsync(
          () => radio.store.watchUnreadCount(channel.idKey).first,
        );
    radio
      ..newest = rows.last
      ..unread = (await storedUnread())!;
    expect(radio.unread, 10);

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ChatsScreen(),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.text('#test'));
    await tester.pump(const Duration(milliseconds: 100));
    await _settle(tester);

    expect(find.byType(ChannelChatScreen), findsOneWidget);
    expect(await storedUnread(), 0,
        reason: 'the row marks the chat read before it opens');
    expect(find.text('NEW MESSAGES'), findsOneWidget);
    expect(
      tester.getRect(find.text('NEW MESSAGES')).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('post 20')).top),
      reason: 'the line sits above the first message missed',
    );
  });
}
