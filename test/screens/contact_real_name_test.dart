import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/contact_note.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/screens/chat_screen.dart';
import 'package:meshtrax/screens/chats_screen.dart';
import 'package:meshtrax/screens/new_chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/contact_info_dialog.dart';
import 'package:meshtrax/widgets/contact_tile.dart';
import 'package:meshtrax/widgets/mention_composer.dart';
import 'package:meshtrax/widgets/pathfinder_help_dialog.dart';

// The owner wanted to note who is behind a radio: a name beside the radio
// name in the lists and under a chat's title, and a note (2026-11-14). Then
// one Contact Info for it all, from every list; a short nickname beside the
// handle in channels, marked as a guess when the handle is shared, and the
// full name in the lists (2026-11-16).
class _Radio extends MeshCoreConnector {
  final notes = <String, ContactNote>{};
  List<Contact> chats = const [];
  List<Contact> everyone = const [];
  List<ChannelMessage> posts = const [];
  Message? last;

  @override
  bool get isConnected => true;

  @override
  List<Contact> get chatContacts => chats;

  @override
  List<Contact> get allContacts => everyone;

  @override
  List<Channel> get channels => const [];

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) =>
      Stream.value(posts);

  @override
  ({String name, bool guess})? nicknameForSender(String senderName) =>
      MeshCoreConnector.nicknamesByHandle(
        everyone,
        (key) => contactNote(key)?.pillName,
        null,
      )[senderName.trim().toLowerCase()];

  @override
  Message? latestContactMessage(Contact contact) => last;

  @override
  ContactNote? contactNote(String publicKeyHex) =>
      notes[publicKeyHex.toLowerCase()];

  @override
  Future<void> setContactNote(String publicKeyHex, ContactNote note) async {
    if (note.isEmpty) {
      notes.remove(publicKeyHex.toLowerCase());
    } else {
      notes[publicKeyHex.toLowerCase()] = note;
    }
    notifyListeners();
  }

  @override
  Stream<List<Message>> watchConversation(Contact contact, {int limit = 200}) =>
      Stream.value(const []);
}

Contact _contact(int seed, String name, {int hour = 9}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 11, 15, hour),
    );

final _walker = _contact(0x21, 'Ridge Walker');

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // The connector gathers its change notices before it sends one.
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

  Future<_Radio> pump(
    WidgetTester tester,
    Widget home, {
    _Radio? radio,
  }) async {
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    radio ??= _Radio()
      ..chats = [_walker]
      ..everyone = [_walker]
      ..last = Message(
        senderKey: _walker.publicKey,
        text: 'see you at noon',
        timestamp: DateTime(2026, 11, 15, 9),
        isOutgoing: false,
        status: MessageStatus.sent,
        messageId: 'm1',
      );
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
          // The test font draws every letter as wide as it is tall: at full
          // size the chat menu's longest entry runs 2 px past the menu.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.9),
            ),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await _settle(tester);
    return radio;
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fillDialog(
    WidgetTester tester, {
    String nickname = '',
    required String fullName,
    required String note,
  }) async {
    expect(find.byType(ContactInfoDialog), findsOneWidget);
    await tester.enterText(field('Nickname'), nickname);
    await tester.enterText(field('Full name'), fullName);
    await tester.enterText(field('Note'), note);
    await tester.tap(find.text('Save'));
    await _settle(tester);
  }

  testWidgets('a Chats row gets its names from the long-press sheet',
      (tester) async {
    final radio = await pump(tester, const ChatsScreen());
    expect(find.text('Ridge Walker'), findsOneWidget);

    await tester.longPress(find.text('Ridge Walker'));
    await _settle(tester);
    await tester.tap(find.text('Contact Info'));
    await _settle(tester);
    await fillDialog(
      tester,
      nickname: 'Annie',
      fullName: ' Ann Smith ',
      note: 'Lives up the hill',
    );

    final saved = radio.notes[_walker.publicKeyHex]!;
    expect(saved.nickname, 'Annie');
    expect(saved.realName, 'Ann Smith');
    expect(saved.note, 'Lives up the hill');
    expect(find.text('Ridge Walker  Ann Smith'), findsOneWidget,
        reason: 'the radio name first, the full name beside it');
  });

  testWidgets('a DM shows the name under its title, set from Contact Info',
      (tester) async {
    final radio = await pump(tester, ChatScreen(contact: _walker));
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    expect(find.text('Name and note'), findsNothing,
        reason: 'one Contact Info in the menu, not two entries');
    await tester.tap(find.text('Contact Info'));
    await _settle(tester);
    await fillDialog(tester, fullName: 'Ann Smith', note: '');

    expect(find.textContaining('Ann Smith'), findsOneWidget);
    expect(radio.notes[_walker.publicKeyHex]?.note, '');

    // Emptying all three removes them.
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Contact Info'));
    await _settle(tester);
    expect(
      tester.widget<TextField>(field('Full name')).controller!.text,
      'Ann Smith',
      reason: 'the dialog opens on what was saved',
    );
    await fillDialog(tester, fullName: '', note: '');
    expect(radio.notes, isEmpty);
    expect(find.textContaining('Ann Smith'), findsNothing);
  });

  testWidgets('Contact Info shows what the radio knows and caps a nickname',
      (tester) async {
    await pump(tester, ChatScreen(contact: _walker));
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Contact Info'));
    await _settle(tester);

    for (final label in ['Type', 'Path', 'Last seen', 'Public Key']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(_walker.publicKeyHex), findsOneWidget);

    await tester.enterText(field('Nickname'), 'Annabelle Smithson');
    await tester.pump();
    expect(
      tester.widget<TextField>(field('Nickname')).controller!.text,
      'Annabelle Sm',
      reason: 'at most ${ContactNote.nicknameMaxLength} characters',
    );
  });

  testWidgets('a long press in the contacts list opens Contact Info',
      (tester) async {
    await pump(tester, const NewChatScreen());
    await tester.longPress(find.text('Ridge Walker'));
    await _settle(tester);
    await tester.tap(find.text('Contact Info'));
    await _settle(tester);
    expect(find.byType(ContactInfoDialog), findsOneWidget);
  });

  testWidgets('a channel message shows the nickname beside the handle',
      (tester) async {
    final pineA = _contact(0x41, 'Pine Hollow', hour: 10);
    final pineB = _contact(0x61, 'Pine Hollow', hour: 8);
    final radio = _Radio()
      ..everyone = [_walker, pineA, pineB]
      ..posts = [
        for (final (i, sender, text) in [
          (0, 'Ridge Walker', 'Is the ridge repeater back up?'),
          (1, 'Pine Hollow', 'Yes, since this morning.'),
          (2, 'Stranger', 'Hello all'),
        ])
          ChannelMessage(
            senderName: sender,
            text: text,
            timestamp: DateTime(2026, 11, 16, 9, i),
            isOutgoing: false,
            status: ChannelMessageStatus.sent,
            channelIndex: 1,
            messageId: 'p$i',
          ),
      ];
    radio.notes[_walker.publicKeyHex] =
        const ContactNote(nickname: 'Annie', realName: 'Ann Smith');
    radio.notes[pineB.publicKeyHex] = const ContactNote(realName: 'Bob Jones');

    await pump(
      tester,
      ChannelChatScreen(
        channel: Channel(index: 1, name: '#test', psk: Uint8List(16)),
      ),
      radio: radio,
    );

    expect(find.text('Annie'), findsOneWidget);
    expect(find.text('Ann Smith'), findsNothing,
        reason: 'the pill shows the nickname when there is one');
    expect(find.text('Bob Jones'), findsOneWidget,
        reason: 'no nickname: the full name, in the pill');
    expect(find.byIcon(Icons.help_outline), findsOneWidget,
        reason: 'two contacts use "Pine Hollow", so that one is a guess');
    expect(find.text('Hello all'), findsOneWidget);
  });

  testWidgets('contact rows and the @ list show it beside the radio name',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Column(
            children: [
              ContactTile(
                contact: _walker,
                lastSeen: _walker.lastSeen,
                unreadCount: 0,
                isFavorite: false,
                onTap: () {},
                onLongPress: () {},
                realName: 'Ann Smith',
              ),
              MentionsOverlay(
                contacts: [_walker],
                onSelect: (_) {},
                realNameOf: (_) => 'Ann Smith',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Ridge Walker  Ann Smith'), findsNWidgets(2));
  });
}
