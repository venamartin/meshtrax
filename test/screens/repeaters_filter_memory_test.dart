import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/repeaters_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/contact_filter_types.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The Manage repeaters filter and sort are kept between visits, and shown
// as chips until cleared, so nobody wonders where the other repeaters went.
class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

/// An advert heard from a repeater, sent [ago] before now.
Uint8List _heardRepeater(
  String name,
  int seed, {
  Duration ago = Duration.zero,
}) {
  final w = BytesBuilder();
  w.addByte(pushCodeNewAdvert);
  w.add(Uint8List.fromList(List.generate(32, (i) => seed + i)));
  w.addByte(advTypeRepeater);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  final secs = DateTime.now().subtract(ago).millisecondsSinceEpoch ~/ 1000;
  w.add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List());
  w.add(Uint8List(8));
  return w.toBytes();
}

void main() {
  late _Radio radio;
  late UiViewStateService viewState;

  Future<void> setUpWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    viewState = UiViewStateService();
    await viewState.initialize();
    radio = _Radio()
      ..handleFrameForTest(_heardRepeater('Zenith', 0x40))
      ..handleFrameForTest(_heardRepeater('Alder', 0x80));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider.value(value: viewState),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RepeatersScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('opens with no chips when nothing is chosen', (tester) async {
    await setUpWith({});
    await open(tester);
    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Zenith'), findsOneWidget);
    expect(find.text('Alder'), findsOneWidget);
  });

  testWidgets('a remembered A-Z sort shows its chip and sorts the list', (
    tester,
  ) async {
    await setUpWith({'ui_repeaters_sort_option': 'name'});
    await open(tester);
    expect(find.widgetWithText(InputChip, 'A-Z'), findsOneWidget);
    final alder = tester.getTopLeft(find.text('Alder'));
    final zenith = tester.getTopLeft(find.text('Zenith'));
    expect(alder.dy, lessThan(zenith.dy));
  });

  testWidgets('clearing the chip returns to last heard and is kept', (
    tester,
  ) async {
    await setUpWith({'ui_repeaters_sort_option': 'name'});
    await open(tester);
    await tester.tap(find.byTooltip('Last heard'));
    await settle(tester);
    expect(find.byType(InputChip), findsNothing);
    expect(viewState.repeatersSortOption, ContactSortOption.lastSeen);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_repeaters_sort_option'), 'lastSeen');
  });

  testWidgets('choosing Favorites in the menu shows the chip and is kept', (
    tester,
  ) async {
    await setUpWith({});
    await open(tester);
    await tester.tap(find.byTooltip('Filter and sort'));
    await settle(tester);
    await tester.tap(find.text('Favorites').last);
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Favorites'), findsOneWidget);
    expect(find.text('Zenith'), findsNothing);
    expect(viewState.repeatersTypeFilter, ContactTypeFilter.favorites);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_repeaters_type_filter'), 'favorites');
  });

  testWidgets('choosing Hops away sorts by it, shows its chip and is kept', (
    tester,
  ) async {
    await setUpWith({});
    await open(tester);
    await tester.tap(find.byTooltip('Filter and sort'));
    await settle(tester);
    await tester.tap(find.text('Hops away'));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Hops away'), findsOneWidget);
    // Neither has been heard advertising, so both stay, at the end.
    expect(find.text('Zenith'), findsOneWidget);
    expect(find.text('Alder'), findsOneWidget);
    expect(viewState.repeatersSortOption, ContactSortOption.hops);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_repeaters_sort_option'), 'hops');

    await tester.tap(find.byTooltip('Last heard'));
    await settle(tester);
    expect(find.byType(InputChip), findsNothing);
  });

  // Heard recently was a sort, so it could not go with Hops away (owner,
  // 2026-11-16). Now it is a window that goes with any sort and Favorites.
  testWidgets('a Heard window hides older repeaters, with any sort', (
    tester,
  ) async {
    await setUpWith({'ui_repeaters_sort_option': 'hops'});
    radio.handleFrameForTest(
      _heardRepeater('Faraway', 0xC0, ago: const Duration(hours: 3)),
    );
    await open(tester);
    expect(find.text('Faraway'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter and sort'));
    await settle(tester);
    await tester.tap(find.text('Last hour'));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Last hour'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Hops away'), findsOneWidget,
        reason: 'the sort stays as it was');
    expect(find.text('Faraway'), findsNothing);
    expect(find.text('Zenith'), findsOneWidget);
    expect(viewState.repeatersHeardWithin, HeardWithin.hour);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_repeaters_heard_within'), 'hour');

    await tester.tap(find.byTooltip('Any time'));
    await settle(tester);
    expect(find.text('Faraway'), findsOneWidget);
    expect(viewState.repeatersHeardWithin, HeardWithin.anyTime);
  });

  testWidgets('a remembered Heard window comes back with its chip', (
    tester,
  ) async {
    await setUpWith({'ui_repeaters_heard_within': 'week'});
    await open(tester);
    expect(find.widgetWithText(InputChip, 'Last 7 days'), findsOneWidget);
  });

  test('a window keeps what was heard inside it', () {
    final now = DateTime(2026, 11, 16, 12);
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    expect(HeardWithin.anyTime.keeps(DateTime(2020), now), isTrue);
    expect(HeardWithin.hour.keeps(twoHoursAgo, now), isFalse);
    expect(HeardWithin.twoDays.keeps(twoHoursAgo, now), isTrue);
    expect(
      HeardWithin.twoDays.keeps(now.subtract(const Duration(hours: 47)), now),
      isTrue,
      reason: 'a repeater adverts every 47 hours by default',
    );
    expect(
      HeardWithin.twoDays.keeps(now.subtract(const Duration(hours: 49)), now),
      isFalse,
    );
    expect(
      HeardWithin.week.keeps(now.subtract(const Duration(days: 8)), now),
      isFalse,
    );
  });
}
