import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/nearby_repeaters_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connector extends MeshCoreConnector {
  _Connector(this.rows, {this.scan = 0, this.startedAt});

  final List<DirectRepeater> rows;
  final int scan;
  final DateTime? startedAt;

  @override
  List<DirectRepeater> get directRepeaters => rows;
  @override
  int get discoverScan => scan;
  @override
  DateTime? get discoverStartedAt => startedAt;
  @override
  List<Contact> get allContacts => const [];
  @override
  int? get currentSf => 9;
}

DirectRepeater _repeater(int seed, double snr, {double? up, int? scan}) {
  final key = Uint8List.fromList(List.generate(32, (i) => seed + i));
  final r = DirectRepeater(
    pubkeyPrefix: key.sublist(0, 2),
    publicKey: key,
    name: 'R$seed',
    snr: snr,
  );
  if (up != null && scan != null) r.markAnswered(up, scan);
  return r;
}

Future<void> _open(WidgetTester tester, MeshCoreConnector c) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NearbyRepeatersDialog(connector: c)),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('only answers to the latest Discover are marked and counted', (
    tester,
  ) async {
    final c = _Connector(
      [
        _repeater(0x10, 9.0), // overheard, loudest
        _repeater(0x30, 2.0, up: 6.5, scan: 2), // answered the latest
        _repeater(0x50, 4.0, up: 1.0, scan: 1), // answered an earlier one
      ],
      scan: 2,
      startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await _open(tester, c);

    expect(
      find.text("1 repeater answered your Discover (1m ago) · 2 didn't answer"),
      findsOneWidget,
    );
    final verified = tester.widgetList<Icon>(find.byIcon(Icons.verified));
    // The latest answer's row and the legend are green; the earlier
    // answer and its legend entry are grey.
    expect(verified.where((i) => i.color == Colors.green), hasLength(2));
    expect(find.text('6.5'), findsOneWidget, reason: 'how it heard me');
    expect(find.text('—'), findsOneWidget, reason: 'never answered');

    // The answering row comes first even though it is heard weakest.
    final names = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^R\d+$')))
        .map((t) => t.data)
        .toList();
    expect(names.first, 'R${0x30}');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fits a phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _Connector(
      [
        for (var i = 0; i < 9; i++)
          _repeater(0x10 + i * 0x10, -12.5 + i, up: -8.25 + i, scan: 1),
      ],
      scan: 1,
      startedAt: DateTime.now(),
    );
    await _open(tester, c);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a phone on its side scrolls instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _Connector(
      [for (var i = 0; i < 6; i++) _repeater(0x10 + i * 0x10, 2.0 + i)],
      startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      scan: 1,
    );
    await _open(tester, c);
    expect(tester.takeException(), isNull);
    await _open(tester, _Connector([]));
    expect(tester.takeException(), isNull, reason: 'empty state too');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('before any Discover it says what Discover does', (tester) async {
    await _open(tester, _Connector([_repeater(0x10, 3.0)]));
    expect(find.textContaining('Tap Discover'), findsOneWidget);
    expect(find.byIcon(Icons.hearing), findsNWidgets(2)); // row + legend
    await tester.pumpWidget(const SizedBox());
  });
}
