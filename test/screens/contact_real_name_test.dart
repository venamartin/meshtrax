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
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/contact_note.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/chat_screen.dart';
import 'package:meshtrax/screens/chats_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/contact_tile.dart';
import 'package:meshtrax/widgets/mention_composer.dart';
import 'package:meshtrax/widgets/pathfinder_help_dialog.dart';

// The owner wanted to note who is behind a radio: a real name beside the
// radio name in the lists and under a chat's title, and a note (2026-11-14).
class _Radio extends MeshCoreConnector {
  final notes = <String, ContactNote>{};
  List<Contact> chats = const [];
  Message? last;

  @override
  bool get isConnected => true;

  @override
  List<Contact> get chatContacts => chats;

  @override
  List<Channel> get channels => const [];

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

final _key = Uint8List.fromList(List.generate(32, (i) => 0x21 + i));

final _walker = Contact(
  publicKey: _key,
  name: 'Ridge Walker',
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 11, 15, 9),
);

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

  Future<_Radio> pump(WidgetTester tester, Widget home) async {
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio()
      ..chats = [_walker]
      ..last = Message(
        senderKey: _key,
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

  Future<void> fillDialog(
    WidgetTester tester, {
    required String realName,
    required String note,
  }) async {
    expect(find.text('Name and note'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Real name'), realName);
    await tester.enterText(find.widgetWithText(TextField, 'Note'), note);
    await tester.tap(find.text('Save'));
    await _settle(tester);
  }

  testWidgets('a Chats row gets its real name from the long-press sheet',
      (tester) async {
    final radio = await pump(tester, const ChatsScreen());
    expect(find.text('Ridge Walker'), findsOneWidget);

    await tester.longPress(find.text('Ridge Walker'));
    await _settle(tester);
    await tester.tap(find.text('Name and note'));
    await _settle(tester);
    await fillDialog(tester, realName: ' Ann Smith ', note: 'Lives up the hill');

    expect(radio.notes[_walker.publicKeyHex]?.realName, 'Ann Smith');
    expect(radio.notes[_walker.publicKeyHex]?.note, 'Lives up the hill');
    expect(find.text('Ridge Walker  Ann Smith'), findsOneWidget,
        reason: 'the radio name first, the real name beside it');
  });

  testWidgets('a DM shows the real name under its title, set from its menu',
      (tester) async {
    final radio = await pump(tester, ChatScreen(contact: _walker));
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Name and note'));
    await _settle(tester);
    await fillDialog(tester, realName: 'Ann Smith', note: '');

    expect(find.textContaining('Ann Smith'), findsOneWidget);
    expect(radio.notes[_walker.publicKeyHex]?.note, '');

    // Emptying both removes them.
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Name and note'));
    await _settle(tester);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Real name'))
          .controller!
          .text,
      'Ann Smith',
      reason: 'the dialog opens on what was saved',
    );
    await fillDialog(tester, realName: '', note: '');
    expect(radio.notes, isEmpty);
    expect(find.textContaining('Ann Smith'), findsNothing);
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
