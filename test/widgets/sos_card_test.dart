import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxroute/traxroute.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/map_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/routing_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/route_sheet.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';

import '../helpers/map_fakes.dart';

// The SOS card's main button opens MeshTrax's own offline map on the SOS;
// the pin there opens Route here, with Navigate (another app, which may
// have no maps out there) second (Martin's decision 16, preliminary).
class _Radio extends MeshCoreConnector {
  @override
  List<Contact> get allContacts => const [];
  @override
  List<Contact> get contacts => const [];
  @override
  List<Channel> get channels => const [];
  @override
  double? get selfLatitude => 36.45;
  @override
  double? get selfLongitude => -116.86;
  @override
  Future<void> getChannels({int? maxChannels, bool force = false}) async {}
  @override
  Future<Map<String, List<Message>>> loadPossiblePinMessages(
    Iterable<Contact> contacts,
  ) async => const {};
  @override
  Future<Map<String, List<ChannelMessage>>> loadPossiblePinChannelMessages(
    Iterable<Channel> channels,
  ) async => const {};
  @override
  Stream<
    Map<String, ({ChannelMessage message, int sortUs, ChannelMessage? unread})>
  >
  watchChannelLatest() => const Stream.empty();
  @override
  void addSelfPositionViewer() {}
  @override
  void removeSelfPositionViewer() {}
}

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

/// Routing data on hand, and a straight line for every route.
class _Routing extends RoutingService {
  _Routing(MapPacksService maps)
    : super(
        maps: maps,
        store: RoutingStore(Directory('${maps.cacheDir.path}/routing')),
        engine: null,
      );

  @override
  bool get available => true;
  @override
  bool get hasRoutingData => true;
  @override
  Future<RouteResult> route(
    LatLon from,
    LatLon to,
    PathType type, {
    RouteOptions options = const RouteOptions(),
    String language = 'en-US',
  }) async => RouteResult(
    pathType: type,
    points: [from, to],
    elevations: const [10, 12],
    elevationIntervalM: 30,
    km: 1.1,
    seconds: 900,
    maneuvers: const [],
    kmShortOfDestination: 0,
  );
}

const _spot = ll.LatLng(36.46, -116.87);
const _sos = SosMessage(position: _spot, text: 'Broken leg');

void main() {
  late Directory tmp;
  late MapPacksService maps;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('soscard');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpCard(
    WidgetTester tester, {
    SosCardState? state,
    bool outgoing = false,
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: _Radio()),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider<RoutingService>.value(value: _Routing(maps)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StructuredMessageCard(
                  message: _sos,
                  textScale: 1,
                  isOutgoing: outgoing,
                  senderName: 'Ann',
                  sos: state,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The card's buttons, in reading order.
  List<String> buttons(WidgetTester tester) {
    final found = find.byType(FilledButton).evaluate().toList()
      ..sort((a, b) {
        final pa = tester.getTopLeft(find.byWidget(a.widget));
        final pb = tester.getTopLeft(find.byWidget(b.widget));
        return pa.dy != pb.dy ? pa.dy.compareTo(pb.dy) : pa.dx.compareTo(pb.dx);
      });
    return [
      for (final e in found)
        (find
                    .descendant(
                      of: find.byWidget(e.widget),
                      matching: find.byType(Text),
                    )
                    .evaluate()
                    .first
                    .widget
                as Text)
            .data!,
    ];
  }

  testWidgets('a receiver\'s card: Map first, then Got it, then Navigate', (
    tester,
  ) async {
    var gotIt = 0;
    await pumpCard(
      tester,
      state: SosCardState(
        updatedAt: DateTime(2026, 11, 16, 14, 6),
        gotIt: const ['Bob', 'Cy'],
        onGotIt: () => gotIt++,
      ),
    );
    expect(buttons(tester), ['Map', 'Got it', 'Navigate']);
    expect(find.textContaining(RegExp(r'^Updated 2:06\sPM$')), findsOneWidget);
    expect(find.text('Got it (2): Bob, Cy'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Got it'));
    expect(gotIt, 1);
  });

  testWidgets('my own card: no Got it to send', (tester) async {
    await pumpCard(
      tester,
      outgoing: true,
      state: const SosCardState(gotIt: ['Ann']),
    );
    expect(buttons(tester), ['Map', 'Navigate']);
    expect(find.text('Got it (1): Ann'), findsOneWidget);
  });

  testWidgets('a cancelled card says so, greyed, and offers no Got it', (
    tester,
  ) async {
    await pumpCard(
      tester,
      state: SosCardState(
        cancelledAt: DateTime(2026, 11, 16, 14, 20),
        onGotIt: () {},
      ),
    );
    expect(
      find.textContaining(RegExp(r'^Cancelled 2:20\sPM$')),
      findsOneWidget,
    );
    expect(buttons(tester), ['Map', 'Navigate']);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Broken leg'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.6,
    );
  });

  testWidgets('Map opens MeshTrax\'s own map on the SOS; its pin opens Route '
      'here, then Navigate', (tester) async {
    await pumpCard(tester, state: const SosCardState());
    await tester.tap(find.widgetWithText(FilledButton, 'Map'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final screen = tester.widget<MapScreen>(find.byType(MapScreen));
    expect(screen.highlightPosition, _spot);
    expect(screen.highlightSos, isTrue);

    final pin = tester
        .widget<AppMap>(find.byType(AppMap).last)
        .overlays
        .whereType<MapMarker>()
        .firstWhere((m) => m.id == 'highlight');
    expect(pin.interactive, isTrue);
    pin.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final route = tester.getTopLeft(find.text('Route here'));
    final navigate = tester.getTopLeft(find.text('Navigate'));
    expect(route.dy, lessThan(navigate.dy), reason: 'our own routing first');
    expect(find.text('Open in another app'), findsOneWidget);

    await tester.tap(find.text('Route here'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(RouteSheet), findsOneWidget);
  });
}
