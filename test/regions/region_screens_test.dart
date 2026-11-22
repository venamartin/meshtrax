import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/screens/channel_share_screen.dart';
import 'package:meshtrax/screens/regions_screen.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/region_dialogs.dart';
import 'package:meshtrax/widgets/region_label.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connector extends MeshCoreConnector {
  _Connector({this.radioDefault, this.everywhere = true, this.nearby = true});

  String? radioDefault;
  final bool everywhere;
  final bool nearby;
  final saved = <String?>[];

  @override
  bool get isConnected => true;
  @override
  bool get supportsRegions => true;
  @override
  bool get supportsRegionEverywhere => everywhere;
  @override
  bool get supportsRadioDefaultRegion => true;
  @override
  bool get supportsNearbyOnly => nearby;
  @override
  String? get radioDefaultRegion => radioDefault;
  @override
  bool get radioDefaultRegionKnown => true;
  @override
  Future<void> loadRadioDefaultRegion() async {}
  @override
  Future<bool> setRadioDefaultRegion(String? name) async {
    saved.add(name);
    radioDefault = name;
    notifyListeners();
    return true;
  }
}

final _channel = Channel(
  index: 1,
  name: '#hiking',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
);

Future<void> _pump(
  WidgetTester tester,
  _Connector c,
  RegionService regions,
  Widget home,
) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(value: c),
        ChangeNotifierProvider<RegionService>.value(value: regions),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

/// A page with one button that opens the channel's region dialog.
Widget _opener() => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showChannelRegionDialog(context, _channel),
          child: const Text('open'),
        ),
      ),
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

  group("the channel's region dialog", () {
    testWidgets('picks a region and closes', (tester) async {
      await regions.add('sf');
      await regions.add('bayarea');
      await _pump(tester, _Connector(), regions, _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('None'), findsOneWidget);
      expect(find.text('Everywhere (no region)'), findsNothing,
          reason: 'no radio default region to step out of');
      await tester.tap(find.text('sf'));
      await tester.pumpAndSettle();

      expect(find.text('Region'), findsNothing, reason: 'closed on pick');
      expect(regions.regionOf(_channel.idKey), 'sf');
    });

    testWidgets('with a radio default: names it, and offers everywhere',
        (tester) async {
      await _pump(tester, _Connector(radioDefault: 'bayarea'), regions,
          _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('None (radio default: bayarea)'), findsOneWidget);
      await tester.tap(find.text('Everywhere (no region)'));
      await tester.pumpAndSettle();
      expect(regions.regionOf(_channel.idKey), RegionHelper.everywhere);
    });

    testWidgets('no everywhere on firmware that cannot do it', (tester) async {
      await _pump(
        tester,
        _Connector(radioDefault: 'bayarea', everywhere: false),
        regions,
        _opener(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Everywhere (no region)'), findsNothing);
    });

    testWidgets('Nearby only is a choice, firmware 13+', (tester) async {
      await _pump(tester, _Connector(), regions, _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.text('Only radios in range hear it. Sent once, with no retries.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Nearby only (no repeaters)'));
      await tester.pumpAndSettle();
      expect(regions.regionOf(_channel.idKey), RegionHelper.nearbyOnly);
      expect(regions.regions, isEmpty, reason: 'not a region');
    });

    testWidgets('no Nearby only on older firmware', (tester) async {
      await _pump(tester, _Connector(nearby: false), regions, _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Nearby only (no repeaters)'), findsNothing);
    });

    testWidgets('None takes the region off', (tester) async {
      await regions.setChannelRegion(_channel.idKey, 'sf');
      await _pump(tester, _Connector(), regions, _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      expect(regions.regionOf(_channel.idKey), isNull);
    });

    testWidgets('a new region added here is set on the channel',
        (tester) async {
      await _pump(tester, _Connector(), regions, _opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add region'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bay area');
      await tester.pump();
      expect(
        find.text("Spaces, dots, commas and most punctuation aren't allowed."),
        findsOneWidget,
      );
      final add = find.widgetWithText(FilledButton, 'Add');
      expect(tester.widget<FilledButton>(add).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Sf');
      await tester.pump();
      expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
      await tester.tap(add);
      await tester.pumpAndSettle();

      expect(regions.regions, ['Sf'], reason: 'kept as typed');
      expect(regions.regionOf(_channel.idKey), 'Sf');
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Settings → Regions', () {
    testWidgets('add, then delete a region a channel uses', (tester) async {
      await _pump(tester, _Connector(), regions, const RegionsScreen());
      expect(find.text('No regions yet. Add the name your area\'s repeaters '
          'use.'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sf');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await regions.setChannelRegion(_channel.idKey, 'sf');
      await tester.pump();
      expect(find.text('Used by 1 channel'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
        find.text('1 channel uses this region. It goes back to no region.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(regions.regions, isEmpty);
      expect(regions.regionOf(_channel.idKey), isNull);
    });

    testWidgets('the QR option is off until switched on', (tester) async {
      await _pump(tester, _Connector(), regions, const RegionsScreen());
      final qr = find.widgetWithText(SwitchListTile, 'Region in channel QR codes');
      expect(tester.widget<SwitchListTile>(qr).value, isFalse);
      await tester.tap(qr);
      await tester.pump();
      expect(regions.regionsInQr, isTrue);
    });

    testWidgets('the radio default region is set from its dialog',
        (tester) async {
      await regions.add('sf');
      final c = _Connector();
      await _pump(tester, c, regions, const RegionsScreen());
      await tester.tap(find.text('Radio default region'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<String?>, 'sf'));
      await tester.pumpAndSettle();
      expect(c.saved, ['sf']);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Radio default region'),
          matching: find.text('sf'),
        ),
        findsOneWidget,
      );
    });
  });

  group("the channel's QR screen", () {
    testWidgets('a switch puts the region in this QR, setting off',
        (tester) async {
      await regions.setChannelRegion(_channel.idKey, 'test-a');
      await _pump(tester, _Connector(), regions,
          ChannelShareScreen(channel: _channel));
      final link = find.textContaining('region_scope=test-a');
      expect(link, findsNothing);
      await tester.tap(find.text('Include the region test-a'));
      await tester.pump();
      expect(link, findsOneWidget);
    });

    testWidgets('the setting on: in by default, and can be left out',
        (tester) async {
      await regions.setChannelRegion(_channel.idKey, 'test-a');
      await regions.setRegionsInQr(true);
      await _pump(tester, _Connector(), regions,
          ChannelShareScreen(channel: _channel));
      final link = find.textContaining('region_scope=test-a');
      expect(link, findsOneWidget);
      await tester.tap(find.text('Include the region test-a'));
      await tester.pump();
      expect(link, findsNothing);
    });

    testWidgets('no switch for a channel with no region', (tester) async {
      await _pump(tester, _Connector(), regions,
          ChannelShareScreen(channel: _channel));
      expect(find.byType(SwitchListTile), findsNothing);
    });
  });

  testWidgets('the label for Nearby only has its own icon', (tester) async {
    await _pump(
      tester,
      _Connector(),
      regions,
      const Scaffold(body: RegionLabel(RegionHelper.nearbyOnly)),
    );
    expect(find.text('Nearby only'), findsOneWidget);
    expect(find.byIcon(Icons.social_distance), findsOneWidget);
    expect(find.byIcon(Icons.hexagon_outlined), findsNothing);
  });

  testWidgets('the label reads everywhere for a channel stepping out',

      (tester) async {
    await _pump(
      tester,
      _Connector(),
      regions,
      const Scaffold(body: RegionLabel(RegionHelper.everywhere)),
    );
    expect(find.text('Everywhere (no region)'), findsOneWidget);
  });
}
