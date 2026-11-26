
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/screens/add_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The Add page: one box reads any contact or channel format and shows what
// it found before adding it (owner, 2026-11-26: "the add is way too
// complicated").
class _Radio extends MeshCoreConnector {
  List<Channel> channelList = const [];
  List<Contact> saved = const [];

  /// Each channel set on the radio: its name and key.
  final added = <(String, String)>[];
  final imported = <Contact>[];

  @override
  bool get isConnected => true;

  @override
  List<Channel> get channels => channelList;

  @override
  int get maxChannels => 8;

  @override
  List<Contact> get contacts => saved;

  @override
  List<Contact> get discoveredContacts => const [];

  @override
  Future<void> setChannel(int index, String name, Uint8List psk) async {
    added.add((name, Channel.formatPskHex(psk)));
  }

  @override
  Future<Channel?> awaitChannelByPsk(
    Uint8List psk, {
    Duration timeout = const Duration(seconds: 20),
    Duration poll = const Duration(milliseconds: 200),
    int maxResyncs = 2,
  }) async => null;

  @override
  Future<bool> importDiscoveredContact(
    Contact contact, {
    int? lastAdvertEpochSeconds,
  }) async {
    imported.add(contact);
    return true;
  }
}

const _key = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
const _secret = '0123456789abcdef0123456789abcdef';

String _hashtagKey(String name) =>
    Channel.formatPskHex(Channel.derivePskFromHashtag(name));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  final box = find.widgetWithText(TextField, 'Paste or type');
  final addChannel = find.widgetWithText(FilledButton, 'Add Channel');
  final addContact = find.widgetWithText(FilledButton, 'Add contact');

  /// The New chat screen's Add page, opened over a home screen.
  Future<_Radio> open(WidgetTester tester, [_Radio? given]) async {
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = given ?? _Radio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddScreen()),
                  ),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    return radio;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(box, text);
    await tester.pumpAndSettle();
  }

  group('channels', () {
    testWidgets('a hashtag: the lowercase channel, Keep capitals as typed', (
      tester,
    ) async {
      final radio = await open(tester);
      await type(tester, '#BayArea');
      expect(find.text('#bayarea'), findsOneWidget);
      expect(find.text('Hashtag channel'), findsOneWidget);
      expect(find.text('Keep capitals'), findsOneWidget);
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(radio.added, [('#bayarea', _hashtagKey('#bayarea'))]);
    });

    testWidgets('Keep capitals adds the channel as written', (tester) async {
      final radio = await open(tester);
      await type(tester, '#BayArea');
      await tester.tap(find.text('Keep capitals'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('#BayArea')),
        findsOneWidget,
      );
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(radio.added, [('#BayArea', _hashtagKey('#BayArea'))]);
    });

    testWidgets('no capital typed: no Keep capitals', (tester) async {
      await open(tester);
      await type(tester, 'bayarea');
      expect(find.text('#bayarea'), findsOneWidget);
      expect(find.text('Keep capitals'), findsNothing);
    });

    // On the owner's phone the keyboard left room for little more than the
    // box, and the switch appeared out of sight under it (2026-11-18).
    testWidgets('with the keyboard up, the switch scrolls into view', (
      tester,
    ) async {
      await open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 1000);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(box);
      await tester.pumpAndSettle();
      await type(tester, 'ThBi');
      expect(find.text('Keep capitals').hitTestable(), findsOneWidget);
    });

    testWidgets('a link shows its channel and adds it with no second ask', (
      tester,
    ) async {
      final radio = await open(tester);
      await type(tester, 'meshcore://channel/add?name=Hiking&secret=$_secret');
      expect(find.text('Hiking'), findsOneWidget);
      expect(find.text('Private channel'), findsOneWidget);
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(radio.added, [('Hiking', _secret)]);
    });

    testWidgets('a key alone: Add waits for its name', (tester) async {
      final radio = await open(tester);
      await type(tester, _secret);
      final name = find.widgetWithText(TextField, 'Channel Name');
      expect(name, findsOneWidget);
      expect(tester.widget<FilledButton>(addChannel).onPressed, isNull);
      await tester.enterText(name, 'Family');
      await tester.pumpAndSettle();
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(radio.added, [('Family', _secret)]);
    });

    testWidgets('a key with its name around it fills the name in', (
      tester,
    ) async {
      final radio = await open(tester);
      await type(tester, 'Hiking $_secret');
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(radio.added, [('Hiking', _secret)]);
    });

    testWidgets('already joined: Open chat, nothing added', (tester) async {
      final radio = _Radio()
        ..channelList = [
          Channel(
            index: 2,
            name: '#bayarea',
            psk: Channel.derivePskFromHashtag('#bayarea'),
          ),
        ];
      await open(tester, radio);
      await type(tester, '#bayarea');
      expect(find.text('You are already in bayarea'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Open chat'), findsOneWidget);
      expect(addChannel, findsNothing);
    });

    testWidgets('a new private channel: a name, then its own new key', (
      tester,
    ) async {
      final radio = await open(tester);
      await tester.tap(find.text('Create a Private Channel'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Channel Name'),
        'Family',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(radio.added, hasLength(1));
      expect(radio.added.single.$1, 'Family');
      expect(radio.added.single.$2, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    testWidgets('Join the Public Channel when it is missing', (tester) async {
      final radio = await open(tester);
      await tester.tap(find.text('Join the Public Channel'));
      await tester.pumpAndSettle();
      expect(radio.added, [('Public', Channel.publicChannelPsk)]);
    });

    testWidgets('no Join the Public Channel when it is there', (tester) async {
      await open(
        tester,
        _Radio()
          ..channelList = [
            Channel(
              index: 0,
              name: 'Public',
              psk: Channel.parsePskHex(Channel.publicChannelPsk),
            ),
          ],
      );
      expect(find.text('Join the Public Channel'), findsNothing);
    });
  });

  group('contacts', () {
    testWidgets('as text: who it is, then added', (tester) async {
      final radio = await open(tester);
      await type(tester, '<$_key:2:Hill Top>');
      expect(find.text('Hill Top'), findsOneWidget);
      expect(find.text('Repeater · a1b2c3d4…'), findsOneWidget);
      await tester.tap(addContact);
      await tester.pumpAndSettle();
      expect(radio.imported.single.publicKeyHex, _key);
      expect(radio.imported.single.name, 'Hill Top');
      expect(radio.imported.single.type, 2);
      expect(find.text('home'), findsOneWidget, reason: 'back to the list');
    });

    testWidgets('a bare key takes a name if you give one', (tester) async {
      final radio = await open(tester);
      await type(tester, _key);
      expect(find.text('Contact'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Name (optional)'),
        'Anna',
      );
      await tester.pumpAndSettle();
      await tester.tap(addContact);
      await tester.pumpAndSettle();
      expect(radio.imported.single.name, 'Anna');
    });

    testWidgets('already a contact: Open chat, nothing imported', (
      tester,
    ) async {
      final radio = _Radio()
        ..saved = [
          Contact(
            publicKey: Uint8List.fromList(List.generate(32, (i) => i)),
            name: 'Anna',
            type: 1,
            pathLength: -1,
            path: Uint8List(0),
            pathHashSize: 1,
            lastSeen: DateTime(2026, 11, 26),
          ),
        ];
      await open(tester, radio);
      final key = radio.saved.single.publicKeyHex;
      await type(tester, 'meshcore://contact/add?name=Anna&public_key=$key&type=1');
      expect(find.text('Anna is already in your contacts.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Open chat'), findsOneWidget);
      expect(addContact, findsNothing);
      expect(radio.imported, isEmpty);
    });
  });

  testWidgets('text it can\'t read says what it takes', (tester) async {
    await open(tester);
    await type(tester, 'hello there');
    expect(find.text('Nothing to add yet'), findsOneWidget);
    expect(addChannel, findsNothing);
    expect(addContact, findsNothing);
  });

  testWidgets('Paste fills the box from the clipboard', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, dynamic>{'text': '  #team  '}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await open(tester);
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(find.text('#team'), findsWidgets);
    expect(addChannel, findsOneWidget);
  });

  // Martin, 2026-11-26: "We also need to say how to add a # hashtag
  // channel" and "How would you manually enter a channel by name a PK
  // (same as a person)".
  group('the rows under the box', () {
    testWidgets('Join a hashtag channel puts # in the box for its name', (
      tester,
    ) async {
      final radio = await open(tester);
      await tester.tap(find.text('Join a hashtag channel'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(box).controller!.text, '#');
      expect(find.text('Nothing to add yet'), findsNothing,
          reason: 'a lone # waits for the name');
      await type(tester, '#team');
      await tester.tap(addChannel);
      await tester.pumpAndSettle();
      expect(radio.added, [('#team', _hashtagKey('#team'))]);
    });

    Future<void> nameAndKey(WidgetTester tester, String name, String key) async {
      await tester.tap(find.text('Enter a name and a key'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), name);
      await tester.enterText(find.widgetWithText(TextField, 'Key'), key);
      await tester.pumpAndSettle();
    }

    final add = find.widgetWithText(FilledButton, 'Add');

    testWidgets('a name and a 32-character key: a private channel', (
      tester,
    ) async {
      final radio = await open(tester);
      await nameAndKey(tester, 'Hiking', _secret.toUpperCase());
      expect(find.text('Private channel'), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(radio.added, [('Hiking', _secret)]);
    });

    testWidgets('a name and a 64-character key: a contact of the type picked',
        (tester) async {
      final radio = await open(tester);
      await nameAndKey(tester, 'Ridge', _key);
      expect(find.text('Contact'), findsOneWidget);
      await tester.tap(find.text('Repeater'));
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(radio.imported.single.name, 'Ridge');
      expect(radio.imported.single.publicKeyHex, _key);
      expect(radio.imported.single.type, 2);
    });

    testWidgets('a channel key needs a name; a key of neither length says so', (
      tester,
    ) async {
      await open(tester);
      await nameAndKey(tester, '', _secret);
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
      await tester.enterText(find.widgetWithText(TextField, 'Key'), '1234');
      await tester.pumpAndSettle();
      expect(
        find.text("A channel's key is 32 characters, a contact's 64."),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
    });
  });
}
