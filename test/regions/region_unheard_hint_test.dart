import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Your own channel text that no radio repeated and no observer heard gets
// an amber check once the wait for a repeat is over; one that didn't go is
// red, as a failed DM is. A DM's radio ACK reads "Received".
//
// Regions: in a region the amber check's words name it, and a Nearby only
// channel, where no repeat is ever expected, never shows amber.
class _Radio extends MeshCoreConnector {
  _Radio({this.channelRows = const []});
  final List<ChannelMessage> channelRows;
  final retrying = <String>{};

  @override
  bool get isConnected => true;

  @override
  bool isChannelMessageRetrying(String messageId) =>
      retrying.contains(messageId);

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) => Stream.value(channelRows);

}

final _channel = Channel(index: 1, name: '#trip', psk: Uint8List(16));

ChannelMessage _mine(
  String text, {
  ChannelMessageStatus status = ChannelMessageStatus.sent,
  int repeats = 0,
}) => ChannelMessage(
  senderName: 'Base',
  text: text,
  timestamp: DateTime.now(),
  isOutgoing: true,
  status: status,
  channelIndex: 1,
  messageId: text,
  repeatCount: repeats,
);

const _noSign = 'Sent · no sign of who got it';

final _amberCheck = find.byWidgetPredicate(
  (w) => w is Icon && w.icon == Icons.check && w.color == Colors.amber[700],
);

void main() {
  late RegionService regions;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    regions = RegionService();
    await regions.load();
  });

  Future<void> open(WidgetTester tester, _Radio radio) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
          ChangeNotifierProvider<RegionService>.value(value: regions),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChannelChatScreen(channel: _channel),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('in a region, the amber check names it', (tester) async {
    await regions.setChannelRegion(_channel.idKey, 'sf');
    await open(tester, _Radio(channelRows: [_mine('At the spring')]));
    await tester.longPress(_amberCheck);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text(
        "Sent in sf · no sign of who got it. Repeaters that don't know sf "
        'drop it.',
      ),
      findsOneWidget,
    );
    expect(find.text(_noSign), findsNothing);
  });

  testWidgets('with no region, the words are as before', (tester) async {
    await open(tester, _Radio(channelRows: [_mine('At the spring')]));
    await tester.longPress(_amberCheck);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_noSign), findsOneWidget);
  });

  testWidgets('Nearby only: a grey check, never amber', (tester) async {
    await regions.setChannelRegion(_channel.idKey, RegionHelper.nearbyOnly);
    await open(tester, _Radio(channelRows: [_mine('At the spring')]));
    expect(_amberCheck, findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.check && w.color == Colors.grey[600],
      ),
      findsOneWidget,
    );
  });
}
