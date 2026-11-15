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
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';

// On the map there was no way to see that messages had come in (owner,
// 2026-11-14): the Chats tab now carries the count.
class _Radio extends MeshCoreConnector {
  List<Contact> chats = const [];
  List<Channel> rooms = const [];
  Map<String, int> unread = {};

  void receive(String idKey, int count) {
    unread = {...unread, idKey: count};
    notifyListeners();
  }

  @override
  List<Contact> get chatContacts => chats;

  @override
  List<Channel> get channels => rooms;

  @override
  int getUnreadCountForContact(Contact contact) =>
      unread[contact.publicKeyHex] ?? 0;

  @override
  int getUnreadCountForChannel(Channel channel) => unread[channel.idKey] ?? 0;
}

Contact _contact(String name, int seed) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 11, 15),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  final public = Channel.fromHex(0, 'Public', Channel.publicChannelPsk);
  final hike = Channel.fromHex(1, '#hike', 'A1B2C3D4' * 4);
  final ann = _contact('Ann', 0x10);
  final bob = _contact('Bob', 0x40);

  Future<(_Radio, AppSettingsService)> pump(WidgetTester tester) async {
    final radio = _Radio()
      ..chats = [ann, bob]
      ..rooms = [public, hike];
    addTearDown(radio.dispose);
    final settings = AppSettingsService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            bottomNavigationBar: QuickSwitchBar(
              selectedIndex: 1,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    return (radio, settings);
  }

  Badge badge(WidgetTester tester) => tester.widget<Badge>(find.byType(Badge));

  // The connector gathers its change notices before it sends one.
  Future<void> shown(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 300));

  testWidgets('counts the unread messages of chats that are not muted',
      (tester) async {
    final (radio, _) = await pump(tester);
    radio
      ..receive(public.idKey, 40)
      ..receive(hike.idKey, 3)
      ..receive(ann.publicKeyHex, 2);
    await shown(tester);
    expect(find.text('5'), findsOneWidget,
        reason: 'Public is muted by default and is left out');
  });

  testWidgets('shows no count while only muted chats have news',
      (tester) async {
    final (radio, _) = await pump(tester);
    radio.receive(public.idKey, 40);
    await shown(tester);
    expect(badge(tester).isLabelVisible, isFalse);
    expect(find.text('40'), findsNothing);
  });

  testWidgets('goes up as messages come in', (tester) async {
    final (radio, _) = await pump(tester);
    expect(badge(tester).isLabelVisible, isFalse);
    radio.receive(hike.idKey, 1);
    await shown(tester);
    expect(find.text('1'), findsOneWidget);
    radio.receive(hike.idKey, 2);
    await shown(tester);
    expect(find.text('2'), findsOneWidget);
    radio.receive(hike.idKey, 0);
    await shown(tester);
    expect(badge(tester).isLabelVisible, isFalse);
  });

  testWidgets('stops at 99+', (tester) async {
    final (radio, _) = await pump(tester);
    radio.receive(hike.idKey, 150);
    await shown(tester);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('follows a chat being muted and unmuted', (tester) async {
    final (radio, settings) = await pump(tester);
    radio
      ..receive(hike.idKey, 3)
      ..receive(bob.publicKeyHex, 4);
    await shown(tester);
    expect(find.text('7'), findsOneWidget);

    await settings.muteContact(bob.publicKeyHex);
    await shown(tester);
    expect(find.text('3'), findsOneWidget);

    await settings.muteChannel(hike.idKey);
    await shown(tester);
    expect(badge(tester).isLabelVisible, isFalse);

    await settings.unmuteChannel(Channel.publicChannelPsk);
    radio.receive(public.idKey, 6);
    await shown(tester);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('a mute stored under the channel name counts as muted',
      (tester) async {
    final (radio, settings) = await pump(tester);
    await settings.muteChannel('#hike');
    radio.receive(hike.idKey, 3);
    await shown(tester);
    expect(badge(tester).isLabelVisible, isFalse);
  });
}
