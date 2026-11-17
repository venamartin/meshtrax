import 'dart:io';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxlos/traxlos.dart' show LinkEnd, Verdict;
import 'package:traxmap/traxmap.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxroute/traxroute.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/map_screen.dart';
import 'package:meshtrax/screens/offline_maps/pack_offer.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/line_of_sight.dart';
import 'package:meshtrax/services/line_of_sight_session.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/routing_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/line_of_sight_sheet.dart';
import 'package:meshtrax/widgets/route_sheet.dart';

import '../helpers/los_fakes.dart';

const dantes = ll.LatLng(36.2209, -116.7266);
const badwater = ll.LatLng(36.2302, -116.7672);
const nevada = ll.LatLng(36.38, -116.35);

/// A radio at [self], with its GPS on and live when [altitude] is given.
class _Radio extends MeshCoreConnector {
  _Radio({required this.self, required this.nodes, this.altitude}) {
    if (altitude != null) {
      markSelfPositionLiveForTest();
      selfGps.value = (
        latitude: self.latitude,
        longitude: self.longitude,
        altitude: altitude!,
        at: DateTime.now().subtract(const Duration(minutes: 2)),
      );
    }
  }

  final ll.LatLng self;
  final List<Contact> nodes;
  final double? altitude;

  @override
  bool get hasGps => altitude != null;
  @override
  bool get gpsOn => altitude != null;
  @override
  int? get currentFreqHz => 910525;
  @override
  List<Contact> get allContacts => nodes;
  @override
  List<Contact> get contacts => nodes;
  @override
  List<Channel> get channels => const [];
  @override
  double? get selfLatitude => self.latitude;
  @override
  double? get selfLongitude => self.longitude;
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
}

Contact _node(String name, int type, int seed, ll.LatLng? p) => Contact(
  publicKey: Uint8List.fromList(List.filled(32, seed)),
  name: name,
  type: type,
  pathLength: 0,
  path: Uint8List(0),
  pathHashSize: 1,
  latitude: p?.latitude,
  longitude: p?.longitude,
  lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
);

/// Counts every HttpClient made while it is in place.
class _NoHttp extends HttpOverrides {
  var made = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    made++;
    return super.createHttpClient(context);
  }
}

void main() {
  late Directory tmp;
  late MapPacksService maps;
  late RecordingDownloads downloads;
  late AppSettingsService settings;

  final ana = _node('Ana', advTypeChat, 2, const ll.LatLng(36.21, -116.71));
  final peak = _node(
    'Peak',
    advTypeRepeater,
    3,
    const ll.LatLng(36.25, -116.7),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('los-map');
    downloads = RecordingDownloads();
    maps = await losMaps(tmp, downloader: downloads);
    settings = AppSettingsService();
    await settings.setUnitSystem(UnitSystem.imperial);
    await settings.setMapShowRepeaters(true);
  });
  tearDown(() => tmp.delete(recursive: true));

  Future<void> pumpMap(
    WidgetTester tester,
    MeshCoreConnector radio, {
    Locale locale = const Locale('en'),
    RoutingService? routing,
    Size view = const Size(412, 915),
  }) async {
    tester.view.physicalSize = view;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          ChangeNotifierProvider.value(value: PathGraphService()),
          if (routing != null) ChangeNotifierProvider.value(value: routing),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapScreen(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  LineOfSightSession? session(WidgetTester tester) {
    final sheet = find.byType(LineOfSightSheet);
    return sheet.evaluate().isEmpty
        ? null
        : tester.widget<LineOfSightSheet>(sheet.first).session;
  }

  /// Lets the worker isolate answer: real time passes between frames.
  Future<void> answer(WidgetTester tester) async {
    for (var i = 0; i < 300; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (!(session(tester)?.busy ?? false)) break;
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  AppMap map(WidgetTester tester) => tester.widget<AppMap>(find.byType(AppMap));

  Future<void> tapMap(WidgetTester tester, ll.LatLng p) async {
    map(tester).onTap!(LatLng(p.latitude, p.longitude));
    await answer(tester);
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(item));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Taps [finder] once it is scrolled into view (the sheet scrolls).
  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  T overlay<T extends MapOverlay>(WidgetTester tester, String id) =>
      map(tester).overlays.whereType<T>().firstWhere((o) => o.id == id);

  testWidgets('⋮ → Line of sight opens the sheet on the map; nothing runs '
      'until a target is picked', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
    );
    // The top bar has no line of sight icon any more.
    expect(find.byTooltip('Line of Sight'), findsNothing);
    await menu(tester, 'Line of sight');
    expect(find.byType(LineOfSightSheet), findsOneWidget);
    expect(find.text('Tap a person or a place on the map.'), findsOneWidget);
    expect(find.text('Me, 2m ago'), findsOneWidget);
    expect(session(tester)!.busy, isFalse);
    expect(session(tester)!.line, isNull);
  });

  testWidgets('a tap on the map moves To and gives the answer, worked out '
      'offline from the contours', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
    );
    await menu(tester, 'Line of sight');
    await tapMap(tester, dantes);
    expect(find.text('Blocked'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'^The ground 0\.3 mi from you is 2\d\d ft above the line\.$'),
      ),
      findsOneWidget,
    );
    expect(find.text('Heights: USGS 3DEP'), findsOneWidget);
    expect(
      overlay<MapLine>(tester, 'los-line').points.last.latitude,
      dantes.latitude,
    );
    expect(overlay<MapMarker>(tester, 'los-deciding'), isNotNull);
    // Another tap: To moves, From stays.
    await tapMap(tester, const ll.LatLng(36.21, -116.75));
    final s = session(tester)!;
    expect(s.from!.isMe, isTrue);
    expect(s.currentLine!.to.lat, 36.21);
    expect(find.text('Me, 2m ago'), findsOneWidget);
  });

  testWidgets('a new antenna height works the answer out again and is '
      'remembered', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
    );
    await menu(tester, 'Line of sight');
    await tapMap(tester, dantes);
    expect(session(tester)!.currentLine!.fromAntennaM, 1.5);
    await tapInSheet(tester, find.text('Hand-held').first);
    await tester.tap(find.text('Vehicle · 8 ft').last);
    await tester.pump();
    await answer(tester);
    expect(session(tester)!.currentLine!.fromAntennaM, 2.5);
    expect(settings.settings.losAntenna, 'vehicle');
    expect(find.text('Vehicle'), findsOneWidget);
    // A raised antenna takes a typed height, in feet here.
    await tapInSheet(tester, find.text('Vehicle'));
    await tester.tap(find.text('Raised · 20 ft…').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), '33');
    await tester.tap(find.text('OK'));
    await tester.pump();
    await answer(tester);
    expect(
      session(tester)!.currentLine!.fromAntennaM,
      closeTo(33 * 0.3048, 1e-9),
    );
    expect(settings.settings.losRaisedM, closeTo(33 * 0.3048, 1e-9));
    expect(find.text('Raised · 33 ft'), findsOneWidget);
  });

  testWidgets('the long-press sheet offers Line of sight from me and Radio '
      'reach from here', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
    );
    map(tester).onLongPress!(LatLng(dantes.latitude, dantes.longitude));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Radio reach from here'), findsOneWidget);
    await tester.tap(find.text('Line of sight from me'));
    await answer(tester);
    expect(session(tester)!.to!.position, dantes);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('a contact\'s dialog offers line of sight and radio reach; '
      'not for a guessed position', (tester) async {
    await settings.setMapShowGuessedLocations(true);
    final anchor = _node(
      'Anchor',
      advTypeRepeater,
      1,
      const ll.LatLng(36.21, -116.70),
    );
    final heard = Contact(
      publicKey: Uint8List.fromList(List.filled(32, 0x10)),
      name: 'Guessed',
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
      inboundPath: Uint8List.fromList(const [0x01]),
      inboundHopCount: 1,
      inboundPathHashSize: 1,
    );
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana, anchor, heard], altitude: -81.1),
    );
    overlay<MapMarker>(tester, 'guess:${heard.publicKeyHex}').onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Guessed'), findsWidgets);
    expect(find.text('Line of sight'), findsNothing);
    expect(find.text('Radio reach from Guessed'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 300));

    overlay<MapMarker>(tester, 'node:${ana.publicKeyHex}').onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Radio reach from Ana'), findsOneWidget);
    await tester.tap(find.text('Line of sight'));
    await answer(tester);
    final s = session(tester)!;
    expect(s.to!.name, 'Ana');
    expect(s.currentLine, isNotNull);
    expect(find.text('Ana, 12m ago'), findsOneWidget);
    // While the sheet is open a person's marker moves To.
    overlay<MapMarker>(tester, 'node:${anchor.publicKeyHex}').onTap!();
    await answer(tester);
    expect(session(tester)!.to!.name, 'Anchor');
    expect(session(tester)!.toAntenna.kind, AntennaKind.raised);
  });

  testWidgets('no contours for part of the line: can\'t tell, and the '
      'download offer opens Offline maps with them ticked', (tester) async {
    await pumpMap(tester, _Radio(self: dantes, nodes: [ana], altitude: 1670.1));
    await menu(tester, 'Line of sight');
    await tapMap(tester, nevada);
    expect(find.text('Can\'t tell'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'^No contour lines for .* of this line \(Nevada\)\.$'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Download Nevada contours (363 MB)'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PackOffer), findsOneWidget);
    expect(find.text('Contours for line of sight'), findsOneWidget);
    await tester.tap(find.text('Download 363 MB'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(downloads.started, ['us-nevada-contours-20ft']);
  });

  testWidgets('offline, it says to download the contours before the trip', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final offline = await Directory.systemTemp.createTemp('los-offline');
      addTearDown(() => offline.delete(recursive: true));
      maps = await losMaps(
        offline,
        downloader: downloads,
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      await maps.refresh();
    });
    expect(maps.status, CatalogueStatus.error);
    await pumpMap(tester, _Radio(self: dantes, nodes: [ana], altitude: 1670.1));
    await menu(tester, 'Line of sight');
    await tapMap(tester, nevada);
    expect(find.text('Can\'t tell'), findsOneWidget);
    expect(
      find.text(
        'Download the contours for this area before your trip. It needs an '
        'internet connection.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Download Nevada'), findsNothing);
  });

  testWidgets('a spot below the lowest contour line can\'t be told; your '
      'own GPS height can', (tester) async {
    // No GPS: the position was set by hand, and Badwater's height isn't
    // known from the contours.
    await pumpMap(tester, _Radio(self: dantes, nodes: [ana]));
    await menu(tester, 'Line of sight');
    expect(find.text('Me, position set by hand'), findsOneWidget);
    await tapMap(tester, badwater);
    expect(find.text('Can\'t tell'), findsOneWidget);
    expect(
      find.text(
        'This spot is below the lowest contour line (below sea level), so '
        'its height isn\'t known.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('radio reach: a shade on the map and who can be reached, '
      'nearest first; a row opens that line', (tester) async {
    // Heard through Peak, with no position of its own: the map guesses.
    final heard = Contact(
      publicKey: Uint8List.fromList(List.filled(32, 7)),
      name: 'AD77',
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      inboundPath: Uint8List.fromList([3]),
      inboundHopCount: 1,
      inboundPathHashSize: 1,
    );
    await settings.setMapShowGuessedLocations(true);
    // Past the shaded circle, inside 60 mi.
    final far = _node('Far', advTypeChat, 4, const ll.LatLng(36.65, -116.73));
    await pumpMap(
      tester,
      _Radio(self: dantes, nodes: [far, heard, peak, ana], altitude: 1670.1),
    );
    await menu(tester, 'Radio reach from me');
    await answer(tester);
    final s = session(tester)!;
    expect(s.reach, isNotNull);
    expect(
      map(tester).overlays.where((o) => o.id.startsWith('los-reach-')),
      isNotEmpty,
    );
    expect(
      find.textContaining('Shaded: the ground isn\'t in the way'),
      findsOneWidget,
    );
    // The valley floor is below sea level: not shaded, and it says why.
    expect(s.reach!.share(const {Verdict.unknown}), greaterThan(0.1));
    expect(
      find.textContaining('Some ground here can\'t be worked out'),
      findsOneWidget,
    );
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Peak'), findsOneWidget);
    expect(find.text('Look further (19 mi)'), findsOneWidget);
    // Everyone out to 60 mi, nearest first; a guessed position is listed
    // with what it was heard through, and no answer.
    expect(
      s.reachPeople.map((p) => p.name),
      containsAll(['Ana', 'Peak', 'Far']),
    );
    expect(s.reachGuessed.single.name, 'AD77');
    double y(String text) => tester
        .getTopLeft(
          find.descendant(
            of: find.byType(LineOfSightSheet),
            matching: find.text(text),
          ),
        )
        .dy;
    expect(y('Ana'), lessThan(y('Peak')));
    expect(y('Peak'), lessThan(y('Far')));
    expect(y('AD77'), lessThan(y('Far')));
    expect(find.text('Position guessed, heard via Peak'), findsOneWidget);
    await tapInSheet(tester, find.text('Ana'));
    await answer(tester);
    expect(session(tester)!.mode, LosMode.line);
    expect(session(tester)!.to!.name, 'Ana');
    expect(find.byTooltip('Back'), findsOneWidget);
    // Closing stops it all and takes the sheet away.
    await tester.tap(find.byTooltip('Close'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LineOfSightSheet), findsNothing);
    expect(map(tester).overlays.where((o) => o.id.startsWith('los-')), isEmpty);
  });

  testWidgets('line of sight and radio reach make no HttpClient', (
    tester,
  ) async {
    final http = _NoHttp();
    final before = HttpOverrides.current;
    HttpOverrides.global = http;
    addTearDown(() => HttpOverrides.global = before);
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana, peak], altitude: -81.1),
    );
    await menu(tester, 'Line of sight');
    await tapMap(tester, dantes);
    expect(session(tester)!.currentLine!.verdict, Verdict.blocked);
    await tapMap(tester, nevada);
    expect(session(tester)!.currentLine!.verdict, Verdict.unknown);
    await menu(tester, 'Radio reach from me');
    await answer(tester);
    expect(session(tester)!.reach, isNotNull);
    expect(http.made, 0);
  });

  testWidgets('a wide screen has it in a panel at the side of the map', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
      view: const Size(1000, 600),
    );
    await menu(tester, 'Line of sight');
    await tapMap(tester, dantes);
    final sheet = tester.widget<LineOfSightSheet>(
      find.byType(LineOfSightSheet),
    );
    expect(sheet.side, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Blocked'), findsOneWidget);
    expect(
      tester.getSize(find.byType(LineOfSightSheet)).width,
      RouteSheet.sideWidth,
    );
  });

  testWidgets('in German too', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
      locale: const Locale('de'),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final l10n = lookupAppLocalizations(const Locale('de'));
    expect(find.text(l10n.los_lineOfSight), findsOneWidget);
    expect(find.text(l10n.los_reachFromMe), findsOneWidget);
  });

  testWidgets('the sheet says how old each position is, by the clock it is '
      'given', (tester) async {
    final now = DateTime(2026, 11, 16, 12);
    final s = LineOfSightSession(
      worker: _NoWorker(),
      maps: maps,
      settings: settings,
      mode: LosMode.line,
      frequencyMHz: 915,
      people: () => const [],
      from: LosPlace.me(
        badwater,
        source: MyPosition.gps,
        seenAt: now.subtract(const Duration(minutes: 7)),
      ),
    );
    addTearDown(s.dispose);
    s.tap(
      LosPlace.contact(
        dantes,
        name: 'Ana',
        key: 'a',
        seenAt: now.subtract(const Duration(hours: 3)),
      ),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LineOfSightSheet(
              session: s,
              side: true,
              onClose: () {},
              onDownload: (_) {},
              clock: () => now,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Me, 7m ago'), findsOneWidget);
    expect(find.text('Ana, 3h ago'), findsOneWidget);
    expect(find.text('Checking…'), findsOneWidget);
  });

  testWidgets('the route sheet steps aside while it is open and comes back '
      'on close; Back closes it first', (tester) async {
    await pumpMap(
      tester,
      _Radio(self: badwater, nodes: [ana], altitude: -81.1),
      routing: _Routing(maps),
    );
    map(tester).onLongPress!(LatLng(dantes.latitude, dantes.longitude));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Route here'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(RouteSheet), findsOneWidget);
    await menu(tester, 'Line of sight');
    expect(find.byType(LineOfSightSheet), findsOneWidget);
    expect(find.byType(RouteSheet), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LineOfSightSheet), findsNothing);
    expect(find.byType(RouteSheet), findsOneWidget);
    // Back closes line of sight before anything else.
    await menu(tester, 'Line of sight');
    expect(await tester.binding.handlePopRoute(), isTrue);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LineOfSightSheet), findsNothing);
    expect(find.byType(RouteSheet), findsOneWidget);
  });
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

/// Never answers: for what the sheet shows before an answer.
class _NoWorker extends LosWorker {
  @override
  Future<Never> line(
    LosPacks packs,
    LinkEnd from,
    LinkEnd to, {
    required double frequencyMHz,
  }) => Completer<Never>().future;
}
