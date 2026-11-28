import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/services/trax_beacon_service.dart';
import 'package:meshtrax/services/trip_positions.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/widgets/trax_dialogs.dart';
import 'package:meshtrax/widgets/trax_sheet.dart';
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
import 'package:meshtrax/widgets/my_location_button.dart';
import 'package:meshtrax/widgets/trax_button.dart';

// The TRAX button made four 48 dp icons, and the owner's radio name was cut
// to "GWQ…" on his phone (2026-11-18). The name is smaller now, and the
// icons 36 dp apart.
class _Radio extends MeshCoreConnector {
  _Radio({this.onTrax = false});

  static const name = 'GWQ∆🍓';

  /// On a TRAX preset, with Off-Grid Repeat on.
  final bool onTrax;

  @override
  bool get isConnected => true;
  @override
  String? get selfName => name;
  @override
  int? get batteryMillivolts => 4000;
  @override
  int? get batteryPercent => 80;
  @override
  List<DirectRepeater> get directRepeaters => [
    DirectRepeater(pubkeyPrefix: Uint8List.fromList([0xA2]), snr: 12.0),
  ];
  @override
  int? get currentSf => 7;
  @override
  bool? get clientRepeat => onTrax;
  @override
  int? get currentFreqHz => onTrax ? 918000 : 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentCr => 5;
  @override
  int? get firmwareVerCode => 14;
  @override
  String get selfPublicKeyHex => '11' * 32;
  @override
  Future<List<({int lowerKhz, int upperKhz})>?>
  getAllowedRepeatFrequencies() async => null;
  @override
  bool get hasGps => true;
  @override
  bool get gpsOn => true;
  @override
  bool get positionVisible => true;
  @override
  List<Channel> get channels => const [];
  @override
  List<Contact> get chatContacts => const [];
  @override
  List<Contact> get allContacts => const [];
  @override
  List<Contact> get allContactsUnfiltered => const [];
  @override
  Stream<
    Map<String, ({ChannelMessage message, int sortUs, ChannelMessage? unread})>
  >
  watchChannelLatest() => const Stream.empty();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      LocationButtonNote.prefKey: true,
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets("a phone's Chats bar has room for the radio's name beside "
      'its three icons', (tester) async {
    // The owner's phone.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio();
    addTearDown(radio.dispose);
    final trax = TraxService(radio);
    addTearDown(trax.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: trax),
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
    await tester.pump(const Duration(milliseconds: 300));

    final title = tester.renderObject<RenderParagraph>(find.text(_Radio.name));
    expect(title.didExceedMaxLines, isFalse, reason: 'the name is not cut');
    for (final button in [
      find.byType(TraxButton),
      find.byType(MyLocationButton),
    ]) {
      expect(tester.getSize(button).width, 36);
    }
    expect(
      tester.getSize(find.byIcon(Icons.adaptive.more)).width,
      22,
      reason: 'the menu icon is the size of the others',
    );
  });

  testWidgets('TRAX mode is in the menu too, in the logo\'s orange while on, '
      'and opens the TRAX sheet', (tester) async {
    final radio = _Radio(onTrax: true);
    addTearDown(radio.dispose);
    final trax = TraxService(radio);
    final asks = RadioAskService(radio);
    final positions = TripPositions(radio, trax);
    final trip = TripService(radio, trax, asks, positions: positions);
    final beacon = TraxBeaconService(radio, trax, trip);
    addTearDown(() {
      beacon.dispose();
      trip.dispose();
      positions.dispose();
      asks.dispose();
      trax.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: trax),
          ChangeNotifierProvider.value(value: asks),
          ChangeNotifierProvider.value(value: trip),
          ChangeNotifierProvider.value(value: positions),
          ChangeNotifierProvider.value(value: beacon),
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
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.adaptive.more));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final item = find.widgetWithText(PopupMenuItem<void>, 'TRAX mode');
    expect(item, findsOneWidget);
    expect(
      tester
          .widget<TraxIcon>(
            find.descendant(of: item, matching: find.byType(TraxIcon)),
          )
          .color,
      const Color(Trax.orange),
    );

    await tester.tap(item);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TraxSheet), findsOneWidget);
    expect(find.text('Leave TRAX'), findsOneWidget);
  });
}
