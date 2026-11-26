import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/link_handler.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// A hashtag channel's key comes from its name as written, so #Test and
// #test are two channels, and people kept ending up alone in the wrong one.
// A tapped #tag now joins the lowercase one; "Keep capitals" shows only
// once a capital is typed (owner, 2026-11-18). The Add page's box does the
// same: test/screens/add_screen_test.dart.
class _Radio extends MeshCoreConnector {
  List<Channel> channelList = const [];

  /// Each channel set on the radio: its name and key.
  final added = <(String, String)>[];

  @override
  bool get isConnected => true;

  @override
  List<Contact> get chatContacts => const [];

  @override
  List<Contact> get allContacts => const [];

  @override
  List<Contact> get allContactsUnfiltered => const [];

  @override
  List<Channel> get channels => channelList;

  @override
  int get maxChannels => 8;

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
}

String _key(String name) =>
    Channel.formatPskHex(Channel.derivePskFromHashtag(name));

Channel _channel(int index, String name) =>
    Channel(index: index, name: name, psk: Channel.derivePskFromHashtag(name));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<_Radio> pump(WidgetTester tester, Widget home) async {
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio();
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
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return radio;
  }

  group('a tapped #tag', () {
    Future<_Radio> tap(WidgetTester tester, String tag) async {
      final radio = await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => LinkHandler.handleHashtagTap(context, tag),
              child: const Text('tag'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tag'));
      await tester.pumpAndSettle();
      return radio;
    }

    final add = find.widgetWithText(FilledButton, 'Add Channel');

    testWidgets('offers the lowercase channel', (tester) async {
      final radio = await tap(tester, '#BayArea');
      expect(find.text('#bayarea'), findsOneWidget);
      expect(find.text('Keep capitals'), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(radio.added, [('#bayarea', _key('#bayarea'))]);
    });

    testWidgets('Keep capitals joins it as written', (tester) async {
      final radio = await tap(tester, '#BayArea');
      await tester.tap(find.text('Keep capitals'));
      await tester.pumpAndSettle();
      expect(find.text('#BayArea'), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(radio.added, [('#BayArea', _key('#BayArea'))]);
    });

    testWidgets('a lowercase tag: no Keep capitals', (tester) async {
      await tap(tester, '#bayarea');
      expect(find.text('#bayarea'), findsOneWidget);
      expect(find.text('Keep capitals'), findsNothing);
    });

    test('opens the channel named so, else the lowercase one', () {
      final test = _channel(1, '#test');
      final capital = _channel(2, '#Test');
      expect(LinkHandler.hashtagChannel([test], '#Test'), same(test));
      expect(
        LinkHandler.hashtagChannel([test, capital], '#Test'),
        same(capital),
      );
      expect(LinkHandler.hashtagChannel([capital], '#test'), isNull);
      expect(LinkHandler.hashtagChannel(const [], '#Test'), isNull);
    });
  });
}
