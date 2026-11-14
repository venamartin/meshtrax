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

Uint8List _heardRepeater(String name, int seed) {
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
  w.add([1, 0, 0, 0]);
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

  testWidgets('clearing the chip returns to heard recently and is kept', (
    tester,
  ) async {
    await setUpWith({'ui_repeaters_sort_option': 'name'});
    await open(tester);
    await tester.tap(find.byTooltip('Heard recently'));
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
}
