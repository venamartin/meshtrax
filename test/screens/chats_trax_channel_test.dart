import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/screens/chats_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/icon_help.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Martin, 2026-11-26: in TRAX mode the trip channel goes to the top of
// Chats, marked as the active TRAX channel.
final _public = Channel(
  index: 0,
  name: 'Public',
  psk: Uint8List.fromList([
    for (var i = 0; i < 32; i += 2)
      int.parse(Channel.publicChannelPsk.substring(i, i + 2), radix: 16),
  ]),
);
final _trip = Channel(
  index: 1,
  name: 'Desert trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x40 + i)),
);

final _at = DateTime(2026, 11, 26, 14);

ChannelMessage _post(Channel channel, String text, Duration ago) =>
    ChannelMessage(
      senderKey: null,
      senderName: 'Ana',
      text: text,
      timestamp: _at.subtract(ago),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: channel.index,
      messageId: '${channel.index}-$text',
    );

class _Radio extends MeshCoreConnector {
  // Public has the newer message, so it leads by arrival.
  final _latest = {
    _public.idKey: _post(_public, 'Radio check', Duration.zero),
    _trip.idKey: _post(_trip, 'At the spring', const Duration(hours: 1)),
  };

  @override
  bool get isConnected => true;

  @override
  List<Channel> get channels => [_public, _trip];

  @override
  ChannelMessage? latestChannelMessage(Channel channel) =>
      _latest[channel.idKey];

  @override
  ChannelMessage? newestUnreadChannelMessage(Channel channel) => null;

  @override
  int latestChannelSortUs(Channel channel) =>
      _latest[channel.idKey]!.timestamp.microsecondsSinceEpoch;
}

class _Trax extends TraxService {
  _Trax(super.connector, {required this.on});

  final bool on;

  @override
  bool get isOn => on;

  @override
  Channel? get tripChannel => _trip;
}

Future<void> _pumpChats(WidgetTester tester, {required bool traxOn}) async {
  final radio = _Radio();
  final trax = _Trax(radio, on: traxOn);
  addTearDown(() {
    trax.dispose();
    radio.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
        ChangeNotifierProvider<TraxService>.value(value: trax),
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
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String title) =>
    tester.getTopLeft(find.text(title)).dy;

ShapeBorder? _cardShape(WidgetTester tester, String title) => tester
    .widget<Card>(
      find.ancestor(of: find.text(title), matching: find.byType(Card)),
    )
    .shape;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({LocationButtonNote.prefKey: true});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('in TRAX mode the trip channel leads, marked TRAX', (
    tester,
  ) async {
    await _pumpChats(tester, traxOn: true);

    expect(_top(tester, 'Desert trip'), lessThan(_top(tester, 'Public')));
    expect(find.text('TRAX'), findsOneWidget);
    final outline = _cardShape(tester, 'Desert trip')! as OutlinedBorder;
    expect(outline.side.color, const Color(Trax.orange));
    expect(_cardShape(tester, 'Public'), isNull);
  });

  testWidgets('out of TRAX mode it keeps its place by its latest message', (
    tester,
  ) async {
    await _pumpChats(tester, traxOn: false);

    expect(_top(tester, 'Public'), lessThan(_top(tester, 'Desert trip')));
    expect(find.text('TRAX'), findsNothing);
    expect(_cardShape(tester, 'Desert trip'), isNull);
  });
}
