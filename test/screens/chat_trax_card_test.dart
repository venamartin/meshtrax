import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';

// Martin, 2026-11-27: someone who hadn't switched when asked heard the group
// leaving later. The two cards stacked, and the older one's Switch too
// joined a group that had left. Only the newest TRAX card from the others
// offers anything.
class _Radio extends MeshCoreConnector {
  _Radio(this.rows);
  final List<ChannelMessage> rows;

  @override
  bool get isConnected => true;
  @override
  List<Channel> get channels => [_trip];
  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) => Stream.value(rows);
  @override
  bool? get clientRepeat => false;
  @override
  int? get currentFreqHz => 910525;
  @override
  int? get firmwareVerCode => 14;
  @override
  String get selfPublicKeyHex => '11' * 32;
}

final _trip = Channel(
  index: 1,
  name: 'Desert trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x40 + i)),
);

final _on = TraxMessage.switching(
  until: DateTime.now().add(const Duration(days: 1)),
  preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
).toWire();

var _minute = 0;

ChannelMessage _post(String sender, String text, {bool mine = false}) =>
    ChannelMessage(
      senderName: sender,
      text: text,
      timestamp: DateTime.now()
          .subtract(const Duration(hours: 1))
          .add(Duration(minutes: ++_minute)),
      isOutgoing: mine,
      status: ChannelMessageStatus.sent,
      channelIndex: _trip.index,
      messageId: 'm$_minute',
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> open(WidgetTester tester, List<ChannelMessage> rows) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio(rows);
    final trax = TraxService(radio);
    addTearDown(trax.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
          ChangeNotifierProvider.value(value: trax),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChannelChatScreen(channel: _trip),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final switchToo = find.text('Switch too');
  String? whoseButton(WidgetTester tester) => tester
      .widget<StructuredMessageCard>(
        find.ancestor(
          of: switchToo,
          matching: find.byType(StructuredMessageCard),
        ),
      )
      .senderName;

  testWidgets('the newest TRAX card offers Switch too', (tester) async {
    await open(tester, [_post('Ana', _on), _post('Me', 'Coming!', mine: true)]);
    expect(whoseButton(tester), 'Ana', reason: 'my own posts change nothing');
  });

  testWidgets('once they leave, the older card offers nothing', (tester) async {
    await open(tester, [_post('Ana', _on), _post('Ana', 'TRAX: off')]);
    expect(find.text('Ana switched to TRAX mode'), findsOneWidget);
    expect(find.text('Ana is leaving TRAX mode'), findsOneWidget);
    expect(switchToo, findsNothing);
    expect(find.text('Leave too'), findsNothing, reason: 'not on TRAX here');
  });

  testWidgets('of two, only the newer offers it', (tester) async {
    await open(tester, [_post('Ana', _on), _post('Cy', _on)]);
    expect(switchToo, findsOneWidget);
    expect(whoseButton(tester), 'Cy');
  });
}
