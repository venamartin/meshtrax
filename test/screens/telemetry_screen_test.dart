import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/screens/telemetry_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/map_tile_cache_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';

import '../helpers/map_fakes.dart';

// A telemetry reply's GPS reading shows as the card a shared position gets
// in a chat, with Open map and Navigate (owner, 2026-10-26). It used to be
// the raw map "{latitude: 36.9558, longitude: -121.7291, altitude: 44.9}".
class _Radio extends MeshCoreConnector {
  _Radio(this.lpp);
  final List<int> lpp;
  final _frames = StreamController<Uint8List>.broadcast();

  @override
  bool get isConnected => true;
  @override
  Stream<Uint8List> get receivedFrames => _frames.stream;
  @override
  Future<void> sendOnRoute(
    Contact contact,
    PathSelection selection,
    Future<void> Function() send,
  ) =>
      send();
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] != cmdSendTelemetryReq) return;
    scheduleMicrotask(() => _frames.add(Uint8List.fromList(
        [pushCodeTelemetryResponse, 0, ..._key.sublist(0, 6), ...lpp])));
  }
}

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(PackIndexEntry entry) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0x47 + i));

final _contact = Contact(
  publicKey: _key,
  name: 'GWQ',
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 10, 26),
);

// Channel 1: 4.15 V; GPS 36.9558, -121.7291 at 44.9 m; 40.0 °C.
const _battery = [1, 116, 0x01, 0x9F];
const _temperature = [1, 103, 0x01, 0x90];
const _gps = [1, 136, 0x05, 0xA3, 0x96, 0xED, 0x6C, 0xF5, 0x00, 0x11, 0x8A];
const _noFix = [1, 136, 0, 0, 0, 0, 0, 0, 0, 0, 0];

void main() {
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('telemetry');
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> open(WidgetTester tester, List<int> lpp) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: _Radio(lpp)),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(
            create: (_) => MapPacksService(
              manager: PackManager(Directory('${tmp.path}/packs')),
              downloader: _NoDownloads(),
              cacheDir: tmp,
              styles: StyleRegistry(MemoryStyles()),
            ),
          ),
          Provider<MapTileCacheService>.value(value: BlankTileCache()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TelemetryScreen(contact: _contact),
        ),
      ),
    );
    // The request waits on real async work the fake clock never runs; then
    // the "received" snack bar and its timer.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a GPS reading shows as the location card', (tester) async {
    await open(tester, [..._battery, ..._gps, ..._temperature]);

    expect(find.byType(StructuredMessageCard), findsOneWidget);
    expect(find.text("GWQ's location"), findsOneWidget);
    expect(find.text('Open map'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.textContaining('latitude'), findsNothing);
    expect(find.text('Altitude'), findsOneWidget);
    expect(find.text('45 m'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no fix (0,0) shows no card and a dash', (tester) async {
    await open(tester, [..._battery, ..._noFix]);

    expect(find.byType(StructuredMessageCard), findsNothing);
    expect(find.text('Position'), findsOneWidget);
    expect(find.textContaining('latitude'), findsNothing);
  });
}
