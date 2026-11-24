import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_message_path_screen.dart';
import 'package:meshtrax/screens/regions_screen.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/nearby_repeaters_dialog.dart';
import 'package:meshtrax/widgets/region_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Phase 2 (what nearby repeaters said they carry) and Phase 3 (the region a
// message came in) on screen.
final _repeaterKey = Uint8List.fromList(List.generate(32, (i) => 0x40 + i));

class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;
  @override
  bool get supportsRegions => true;
  @override
  bool get supportsRadioDefaultRegion => true;
  @override
  bool get radioDefaultRegionKnown => true;
  @override
  Future<void> loadRadioDefaultRegion() async {}
  @override
  List<DirectRepeater> get directRepeaters => [
    DirectRepeater(
      pubkeyPrefix: _repeaterKey.sublist(0, 2),
      publicKey: _repeaterKey,
      name: 'Ridge',
      snr: 8,
    ),
  ];
  @override
  int? get currentSf => 9;
}

final _channel = Channel(
  index: 1,
  name: '#hiking',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
);

void main() {
  late RegionService regions;
  late _Radio radio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    regions = RegionService();
    await regions.load();
    radio = _Radio();
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider<RegionService>.value(value: regions),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  Widget opener(void Function(BuildContext) open) => Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      );

  group('Phase 2', () {
    setUp(() async {
      await regions.saveReport(pubKeyToHex(_repeaterKey), ['*', 'sf']);
      await regions.saveReport('00' * 32, ['SF', 'sf']);
    });

    testWidgets("the channel's Region dialog counts the carriers",
        (tester) async {
      await regions.add('sf');
      await regions.add('la');
      await pump(
          tester, opener((c) => showChannelRegionDialog(c, _channel)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('2 nearby repeaters'), findsOneWidget);
      expect(find.text('No nearby repeater carries it'), findsOneWidget);
    });

    testWidgets('Settings lists names heard from repeaters, to add',
        (tester) async {
      await regions.add('sf');
      await pump(tester, const RegionsScreen());
      expect(find.text('Heard from nearby repeaters'), findsOneWidget);
      expect(find.text('SF'), findsOneWidget);
      await tester.tap(find.byTooltip('Add').last);
      await tester.pumpAndSettle();
      expect(regions.regions, containsAll(['SF', 'sf']));
      expect(find.text('Heard from nearby repeaters'), findsNothing);
    });

    testWidgets('Add region offers the spelling repeaters use',
        (tester) async {
      await regions.saveReport('00' * 32, ['bayArea']);
      await pump(tester, opener((c) => showAddRegionDialog(c)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bayarea');
      await tester.pump();
      expect(find.text('Nearby repeaters spell it bayArea'), findsOneWidget);
      await tester.tap(find.text('Use it'));
      await tester.pump();
      expect(find.text('bayArea'), findsOneWidget);
      expect(find.text('Nearby repeaters spell it bayArea'), findsNothing);
    });

    testWidgets('the Nearby repeaters dialog shows what each one carries',
        (tester) async {
      await pump(tester, Scaffold(body: NearbyRepeatersDialog(connector: radio)));
      expect(
        find.text('Regions: sf, and messages with no region'),
        findsOneWidget,
      );
    });
  });

  group('Phase 3: the Packet Path screen', () {
    ChannelMessage message({int? code, String? region}) => ChannelMessage(
          senderName: 'Bob',
          text: 'Trail is clear',
          timestamp: DateTime(2026, 11, 22, 9, 30),
          isOutgoing: false,
          pathLength: 1,
          pathBytes: Uint8List.fromList([0xA2]),
          regionCode: code,
          region: region,
        );

    testWidgets('names the region the message came in', (tester) async {
      await pump(
        tester,
        ChannelMessagePathScreen(
          message: message(code: 0x1A2B, region: 'sf'),
          channelMessage: true,
        ),
      );
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('sf'), findsOneWidget);
    });

    testWidgets('an unknown region shows its code', (tester) async {
      await pump(
        tester,
        ChannelMessagePathScreen(
          message: message(code: 0x1A2B),
          channelMessage: true,
        ),
      );
      expect(find.text("One you don't know (code 1A2B)"), findsOneWidget);
    });

    testWidgets('no region, no line', (tester) async {
      await pump(
        tester,
        ChannelMessagePathScreen(message: message(), channelMessage: true),
      );
      expect(find.text('Region'), findsNothing);
    });
  });
}
