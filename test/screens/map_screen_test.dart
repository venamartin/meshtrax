import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxroute/traxroute.dart';
import 'package:traxwater/traxwater.dart'
    show EndsShort, EndsShortReason, WaterRouteOptions, WaterRoutingProblem;

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/date_time_helper.dart';
import 'package:meshtrax/helpers/link_handler.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/map_focus.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/map_screen.dart';
import 'package:meshtrax/screens/offline_maps_screen.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/routing_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/services/water_routing_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/icon_help.dart';
import 'package:meshtrax/widgets/map_controls.dart';
import 'package:meshtrax/widgets/map_layers_sheet.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';
import 'package:meshtrax/widgets/room_login_dialog.dart';
import 'package:meshtrax/widgets/route_sheet.dart';
import 'package:meshtrax/widgets/water_route_parts.dart';

import '../helpers/map_fakes.dart';
import '../helpers/water_fakes.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector({required this.nodes, this.self, this.gps});

  final List<Contact> nodes;
  ll.LatLng? self;

  /// The radio reports a new position of its own.
  void moveSelf(ll.LatLng? position) {
    self = position;
    notifyListeners();
  }

  /// The radio's `gps` setting: null when it has no GPS module.
  String? gps;
  final gpsSets = <bool>[];

  @override
  bool get hasGps => gps != null;
  @override
  bool get gpsOn => gps == '1';

  /// Whether the GPS reading changed lately, and when it last did.
  bool fresh = true;
  DateTime? changedAt;
  @override
  bool get selfGpsIsFresh => fresh;
  @override
  DateTime? get selfGpsChangedAt => changedAt;
  @override
  Future<void> setGps(bool on) async {
    gpsSets.add(on);
    gps = on ? '1' : '0';
    notifyListeners();
  }

  void replaceNode(int index, Contact node) {
    nodes[index] = node;
    notifyListeners();
  }

  @override
  List<Contact> get allContacts => nodes;
  @override
  List<Contact> get contacts => nodes;
  @override
  List<Channel> get channels => const [];
  @override
  double? get selfLatitude => self?.latitude;
  @override
  double? get selfLongitude => self?.longitude;
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
  Stream<Map<String, ({ChannelMessage message, int sortUs, ChannelMessage? unread})>>
  watchChannelLatest() => const Stream.empty();
}

// The values a real radio reports: frequency in kHz despite the getter's name.
class _RadioConnector extends _FakeConnector {
  _RadioConnector({required super.nodes});

  final written = <String>{};
  @override
  bool wroteContactPath(Contact contact) =>
      written.contains(contact.publicKeyHex);

  @override
  int? get currentFreqHz => 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentTxPower => 22;
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
  @override
  set pendingTraceTag(int? tag) {} // the real one starts a 60 s timer
}

/// A radio that answers an add with [saves].
class _AddingConnector extends _FakeConnector {
  _AddingConnector({required super.nodes, required this.saves});

  final bool saves;
  final adds = <String>[];

  @override
  Future<bool> importDiscoveredContact(
    Contact contact, {
    int? lastAdvertEpochSeconds,
  }) async {
    adds.add(contact.publicKeyHex);
    return saves;
  }
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
  _Routing(
    MapPacksService maps, {
    this.elevations = const [10, 12],
    this.hasData = true,
    this.steps = const [],
  }) : super(
         maps: maps,
         store: RoutingStore(Directory('${maps.cacheDir.path}/routing')),
         engine: null,
       );

  final requests = <(PathType, RouteOptions)>[];
  final List<double> elevations;
  final bool hasData;
  final List<Maneuver> steps;

  /// Holds routes back until it completes.
  Completer<void>? gate;

  /// Where routes begin instead of at their start: the nearest path, off
  /// any path from the start.
  LatLon? snapStart;

  @override
  bool get available => true;
  @override
  bool get hasRoutingData => hasData;
  @override
  Future<RouteResult> route(
    LatLon from,
    LatLon to,
    PathType type, {
    RouteOptions options = const RouteOptions(),
    String language = 'en-US',
  }) async {
    requests.add((type, options));
    await gate?.future;
    return RouteResult(
      pathType: type,
      points: [snapStart ?? from, to],
      elevations: elevations,
      elevationIntervalM: 30,
      km: 1.1,
      seconds: 900,
      maneuvers: steps,
      kmShortOfDestination: 0,
      kmFromStart: snapStart == null ? 0 : kmBetween(from, snapStart!),
    );
  }
}

Contact _node(String name, int type, int seed, double lat, double lon) =>
    Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: name,
      type: type,
      pathLength: 0,
      path: Uint8List(0),
      pathHashSize: 1,
      latitude: lat,
      longitude: lon,
      lastSeen: DateTime.now(),
    );

void main() {
  late Directory tmp;
  late MapPacksService maps;

  final systemFormats = DateTimeHelper.systemFormats;
  setUp(() async {
    // Times as a US phone writes them, whatever machine runs the tests.
    DateTimeHelper.systemFormats = () => null;
    addTearDown(() => DateTimeHelper.systemFormats = systemFormats);
    // The first route's one-time popup has its own tests.
    SharedPreferences.setMockInitialValues({RouteSheet.conditionsToldKey: true});
    PrefsManager.reset();
    await PrefsManager.initialize();
    tmp = await Directory.systemTemp.createTemp('mapscreen');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  var guessedLocationsOn = false;

  Future<void> pumpMap(
    WidgetTester tester,
    MeshCoreConnector connector, {
    Widget screen = const MapScreen(),
    RoutingService? routing,
    WaterRoutingService? water,
    String mapType = 'osm',
    Size view = const Size(800, 900),
    UiViewStateService? viewState,
  }) async {
    tester.view.physicalSize = view;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider(
            create: (_) =>
                AppSettingsService()
                  ..setMapShowRepeaters(true)
                  ..setMapShowOtherNodes(true)
                  ..setMapShowMarkers(true)
                  ..setMapShowGuessedLocations(guessedLocationsOn)
                  ..setMapType(mapType),
          ),
          if (viewState != null)
            ChangeNotifierProvider.value(value: viewState)
          else
            ChangeNotifierProvider(create: (_) => UiViewStateService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          ChangeNotifierProvider.value(value: PathGraphService()),
          if (routing != null) ChangeNotifierProvider.value(value: routing),
          if (water != null) ChangeNotifierProvider.value(value: water),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => screen)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<MapOverlay> overlays(WidgetTester tester) =>
      tester.widget<AppMap>(find.byType(AppMap)).overlays;

  T overlay<T extends MapOverlay>(WidgetTester tester, String id) =>
      overlays(tester).whereType<T>().firstWhere((o) => o.id == id);

  // The chat or room login opened at once while the add ran behind it, so a
  // radio that refused the node (a full table with overwrite off) left a chat
  // whose DMs all failed with no reason given.
  group('a node not saved yet', () {
    const openChat = 'Open Chat';
    const joinRoom = 'Join Room';
    const refused = 'Failed to import contact.';

    Future<_AddingConnector> showNode(
      WidgetTester tester,
      Contact node, {
      required bool radioSaves,
    }) async {
      final radio = _AddingConnector(
        nodes: [node.copyWith(isActive: false)],
        saves: radioSaves,
      );
      await pumpMap(tester, radio);
      overlay<MapMarker>(tester, 'node:${node.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return radio;
    }

    Future<void> press(WidgetTester tester, String button) async {
      await tester.tap(find.text(button));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Open chat says so when the radio cannot save it', (
      tester,
    ) async {
      final alice = _node('Alice', advTypeChat, 2, 41.82, -71.41);
      final radio = await showNode(tester, alice, radioSaves: false);

      await press(tester, openChat);

      expect(radio.adds, [alice.publicKeyHex]);
      expect(find.text(refused), findsOneWidget);
      expect(find.text(openChat), findsOneWidget, reason: 'no chat opened');
    });

    testWidgets('Join room says so when the radio cannot save it', (
      tester,
    ) async {
      final room = _node('Clubhouse', advTypeRoom, 3, 41.82, -71.41);
      final radio = await showNode(tester, room, radioSaves: false);

      await press(tester, joinRoom);

      expect(radio.adds, [room.publicKeyHex]);
      expect(find.text(refused), findsOneWidget);
      expect(find.byType(RoomLoginDialog), findsNothing);
    });

    testWidgets('Join room asks for the password once the radio saved it', (
      tester,
    ) async {
      final room = _node('Clubhouse', advTypeRoom, 3, 41.82, -71.41);
      final radio = await showNode(tester, room, radioSaves: true);

      await press(tester, joinRoom);

      expect(radio.adds, [room.publicKeyHex]);
      expect(find.text(refused), findsNothing);
      expect(
        find.text(joinRoom),
        findsNothing,
        reason: 'the node dialog closed',
      );
      expect(find.byType(RoomLoginDialog), findsOneWidget);
    });
  });

  // On a phone the layers button straddled the route sheet's top edge and
  // covered its X, the only way to close the route.
  group("a point's sheet", () {
    Future<void> settle(WidgetTester tester, [int frames = 6]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    OfflineMapController map(WidgetTester tester) =>
        tester.widget<AppMap>(find.byType(AppMap)).controller!;

    Future<void> showMap(WidgetTester tester) => pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(41.81, -71.42)),
    );

    // A point a [share] of the way up the map, in the middle.
    LatLng up(WidgetTester tester, double share) {
      final b = map(tester).visibleBounds!;
      return LatLng(
        b.south + (b.north - b.south) * share,
        (b.west + b.east) / 2,
      );
    }

    Future<void> longPress(WidgetTester tester, LatLng at) async {
      tester.widget<AppMap>(find.byType(AppMap)).onLongPress!(at);
      await settle(tester);
    }

    // Where [point] is on the screen, and the middle of the map left above
    // the sheet.
    (double, double) whereAndMiddle(WidgetTester tester, LatLng point) {
      final top = tester.getTopLeft(find.byType(AppMap)).dy;
      final sheet = tester.getTopLeft(find.byType(BottomSheet)).dy;
      return (top + map(tester).toScreen(point)!.dy, (top + sheet) / 2);
    }

    testWidgets('leaves the map clear, with a pin while it is open', (
      tester,
    ) async {
      await showMap(tester);
      final point = up(tester, 0.8);
      final center = map(tester).camera!.center;
      await longPress(tester, point);
      expect(find.text('Share marker here'), findsOneWidget);
      expect(find.byType(AnimatedModalBarrier), findsNothing);
      expect(overlay<MapMarker>(tester, 'sheet-pin').position, point);
      // In clear view: the map stays where it was.
      expect(map(tester).camera!.center, center);

      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(overlays(tester).where((o) => o.id == 'sheet-pin'), isEmpty);
    });

    testWidgets('moves a point it would cover to the middle above it', (
      tester,
    ) async {
      await showMap(tester);
      final point = up(tester, 0.1);
      await longPress(tester, point);
      final (at, middle) = whereAndMiddle(tester, point);
      expect(at, closeTo(middle, 1));
    });

    testWidgets('puts a search pick in the middle of the map above it', (
      tester,
    ) async {
      await showMap(tester);
      await tester.tap(find.byTooltip('Search'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '41.85, -71.35');
      await settle(tester);
      await tester.tap(find.widgetWithIcon(ListTile, Icons.my_location));
      // The map gets there in a few tries while it learns what is downloaded.
      await settle(tester, 40);

      const point = LatLng(41.85, -71.35);
      expect(find.text('41.85, -71.35'), findsOneWidget);
      expect(overlay<MapMarker>(tester, 'sheet-pin').position, point);
      final (at, middle) = whereAndMiddle(tester, point);
      expect(at, closeTo(middle, 1));
    });
  });

  group('a route', () {
    late _Routing routing;
    const steps = [
      Maneuver('Walk north on Mill Lane', 0.4, 300, 0),
      Maneuver('Turn left onto Main Street', 0.7, 600, 1),
      Maneuver('You have arrived', 0, 0, 1),
    ];
    final header = find.textContaining('To 41.8');

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.tap(finder);
      await settle(tester);
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
    }

    Future<void> longPress(WidgetTester tester, LatLng at) async {
      tester.widget<AppMap>(find.byType(AppMap)).onLongPress!(at);
      await settle(tester);
    }

    Future<void> showMap(
      WidgetTester tester, {
      Widget screen = const MapScreen(),
      Size view = const Size(800, 900),
      _FakeConnector? radio,
    }) => pumpMap(
      tester,
      radio ??
          _FakeConnector(nodes: const [], self: const ll.LatLng(41.81, -71.42)),
      screen: screen,
      routing: routing,
      view: view,
    );

    Future<void> showRoute(
      WidgetTester tester, {
      List<double> heights = const [10, 12],
      List<Maneuver> steps = const [],
      Completer<void>? gate,
      Widget screen = const MapScreen(),
      Size view = const Size(800, 900),
      _FakeConnector? radio,
      LatLon? snapStart,
    }) async {
      routing = _Routing(maps, elevations: heights, steps: steps)
        ..gate = gate
        ..snapStart = snapStart;
      await showMap(tester, screen: screen, view: view, radio: radio);
      await longPress(tester, const LatLng(41.8, -71.4));
      await tap(tester, find.text('Route here'));
      expect(find.byType(RouteSheet), findsOneWidget);
    }

    double height(WidgetTester tester) =>
        tester.getSize(find.byType(RouteSheet)).height;

    Finder shown(String text) => find.text(text).hitTestable();

    // Where on the screen the middle of the route is.
    Offset routeMiddle(WidgetTester tester) {
      final map = tester.getRect(find.byType(AppMap));
      final b = tester
          .widget<AppMap>(find.byType(AppMap))
          .controller!
          .visibleBounds!;
      double y(double lat) => math.log(math.tan((90 + lat) * math.pi / 360));
      return Offset(
        map.left + map.width * (-71.41 - b.west) / (b.east - b.west),
        map.top +
            map.height *
                (y(b.north) - (y(41.81) + y(41.8)) / 2) /
                (y(b.north) - y(b.south)),
      );
    }

    testWidgets('without heights, says so instead of a climb', (tester) async {
      await showRoute(tester, heights: const []);
      expect(find.textContaining('↑'), findsNothing);
      expect(
        find.text('No heights for this area, so the time leaves out climbs.'),
        findsOneWidget,
      );

      await tap(tester, find.text('Paved'));
      expect(find.text('No heights for this area.'), findsOneWidget);
    });

    testWidgets('the first route ever says what the data can\'t know, once', (
      tester,
    ) async {
      await PrefsManager.instance.remove(RouteSheet.conditionsToldKey);
      await showRoute(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          "MeshTrax doesn't know closures, washouts or which roads need 4x4. "
          'Check current conditions before you go.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await settle(tester);

      await tap(tester, find.text('Paved'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining("doesn't know closures"), findsNothing);
    });

    testWidgets('slides between a bar, open and the whole map', (tester) async {
      await showRoute(tester, steps: steps);
      final map = tester.getRect(find.byType(AppMap));
      final open = height(tester);
      expect(open, lessThan(map.height * 0.6));
      expect(shown('Paved'), findsOneWidget);
      expect(shown('Directions'), findsOneWidget);
      expect(shown('Turn left onto Main Street'), findsNothing);

      // The bar: where to, how far, how long and how much climb.
      await tap(tester, header);
      final bar = height(tester);
      expect(bar, lessThan(100));
      expect(find.textContaining('↑').hitTestable(), findsOneWidget);
      expect(shown('Paved'), findsNothing);
      expect(overlay<MapLine>(tester, 'route').points, hasLength(2));

      await tap(tester, header);
      expect(height(tester), open);

      // The whole map: the directions, under the same header.
      await tap(tester, find.text('Directions'));
      expect(height(tester), map.height);
      expect(header.hitTestable(), findsOneWidget);
      expect(shown('From your location'), findsOneWidget);
      expect(shown('Turn left onto Main Street'), findsOneWidget);

      // Scaffold puts a sheet that was raised back at its first height.
      await tap(tester, find.text('Directions'));
      expect(height(tester), open);
      await tap(tester, header);
      expect(height(tester), bar);
    });

    testWidgets('dragged down, leaves the bar and the route', (tester) async {
      await showRoute(tester, steps: steps);
      final open = height(tester);

      await tester.drag(header, const Offset(0, 400));
      await settle(tester);
      expect(height(tester), lessThan(100));
      expect(overlay<MapLine>(tester, 'route').points, hasLength(2));

      await tester.drag(header, const Offset(0, -200));
      await settle(tester);
      expect(height(tester), open);
    });

    testWidgets('keeps its height while a route is found', (tester) async {
      final gate = Completer<void>();
      await showRoute(tester, steps: steps, gate: gate);
      final open = height(tester);
      expect(shown('Finding a route…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      gate.complete();
      await settle(tester);
      expect(find.text('Finding a route…'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(height(tester), open);

      // The last route stays in place while the next one is found.
      routing.gate = Completer();
      await tap(tester, find.text('Paved'));
      expect(shown('Finding a route…'), findsOneWidget);
      expect(shown('Directions'), findsOneWidget);
      expect(height(tester), open);

      routing.gate!.complete();
      await settle(tester);
      expect(find.text('Finding a route…'), findsNothing);
      expect(height(tester), open);
    });

    testWidgets('shows the whole route in the map left clear', (tester) async {
      await showRoute(tester);
      final map = tester.getRect(find.byType(AppMap));
      final sheet = tester.getRect(find.byType(RouteSheet));
      final middle = routeMiddle(tester);
      expect(
        middle.dx,
        closeTo((map.left + map.right - MapControls.width) / 2, 1),
      );
      expect(middle.dy, closeTo((map.top + sheet.top) / 2, 1));
    });

    testWidgets('starts as the bar on a screen too short for more', (
      tester,
    ) async {
      await showRoute(tester, steps: steps, view: const Size(500, 480));
      final map = tester.getRect(find.byType(AppMap));
      final sheet = tester.getRect(find.byType(RouteSheet));
      expect(sheet.height, lessThan(100));
      expect(shown('Paved'), findsNothing);
      expect(routeMiddle(tester).dy, closeTo((map.top + sheet.top) / 2, 1));

      await tap(tester, header);
      expect(shown('Paved'), findsOneWidget);
    });

    testWidgets('is a panel at the side of a wide screen', (tester) async {
      await showRoute(tester, steps: steps, view: const Size(1200, 800));
      final map = tester.getRect(find.byType(AppMap));
      final panel = tester.getRect(find.byType(RouteSheet));
      expect(panel.left, 0);
      expect(panel.width, RouteSheet.sideWidth);
      expect(panel.height, map.height);
      expect(map.left, greaterThan(panel.right));
      expect(map.right, 1200);
      final middle = routeMiddle(tester);
      expect(
        middle.dx,
        closeTo((map.left + map.right - MapControls.width) / 2, 1),
      );
      expect(middle.dy, closeTo(map.center.dy, 1));
      // Nothing to slide: the directions are listed.
      expect(shown('Turn left onto Main Street'), findsOneWidget);
      expect(find.byTooltip('Map layers').hitTestable(), findsOneWidget);

      // Turned upright, the same map has the sheet over its bottom.
      final state = tester.state(find.byType(AppMap));
      tester.view.physicalSize = const Size(800, 1200);
      await settle(tester);
      expect(tester.state(find.byType(AppMap)), same(state));
      expect(
        tester.getRect(find.byType(RouteSheet)).bottom,
        tester.getRect(find.byType(AppMap)).bottom,
      );
      expect(shown('Turn left onto Main Street'), findsNothing);
    });

    testWidgets('keeps the map buttons clear of its X', (tester) async {
      await showRoute(tester, steps: steps);

      final close = tester.getRect(find.byTooltip('Clear route'));
      final layers = tester.getRect(find.byTooltip('Map layers'));
      expect(layers.overlaps(close), isFalse);
      expect(
        tester.getRect(find.byType(MapControls)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(RouteSheet)).top),
      );

      // Over the whole map it leaves them no room: they go.
      await tap(tester, find.text('Directions'));
      expect(find.byTooltip('Map layers').hitTestable(), findsNothing);
      expect(find.byTooltip('Clear route').hitTestable(), findsOneWidget);
    });

    testWidgets('options re-route, are remembered, and reset', (tester) async {
      await showRoute(tester);
      await tap(tester, find.text('Dirt'));
      await tap(tester, find.byTooltip('Route options'));
      expect(find.text('Reset'), findsNothing);

      await tap(tester, find.text('Most direct'));
      expect(routing.requests.last.$1, PathType.dirt);
      expect(routing.requests.last.$2.dirt, DirtPreference.direct);
      expect(find.text('Reset'), findsOneWidget);
      final later = AppSettingsService();
      await later.loadSettings();
      expect(later.settings.routeOptions.dirt, DirtPreference.direct);

      await tap(tester, find.text('Reset'));
      expect(routing.requests.last.$2.dirt, DirtPreference.balanced);
      expect(find.text('Reset'), findsNothing);
    });

    // On a small screen the last options were cut off.
    testWidgets('its options scroll on a small screen', (tester) async {
      await showRoute(tester, view: const Size(360, 480));
      await tap(tester, find.byTooltip('Route options'));
      expect(shown('Fast'), findsNothing);

      await scrollTo(tester, find.text('Fast'));
      await tap(tester, find.text('Fast'));
      expect(routing.requests.last.$2.pace, HikingPace.fast);
    });

    // Every session started with Hiking.
    testWidgets('the path type is kept for the next route', (tester) async {
      await showRoute(tester);
      expect(routing.requests.last.$1, PathType.hiking);
      await tap(tester, find.text('Paved'));
      expect(routing.requests.last.$1, PathType.paved);
      final later = AppSettingsService();
      await later.loadSettings();
      expect(later.settings.routePathType, PathType.paved);

      await tap(tester, find.byTooltip('Clear route'));
      expect(find.byType(RouteSheet), findsNothing);
      await longPress(tester, const LatLng(41.9, -71.5));
      await tap(tester, find.text('Route here'));
      expect(routing.requests, hasLength(3));
      expect(routing.requests.last.$1, PathType.paved);
    });

    testWidgets('from a GPS position that may be old, says so', (tester) async {
      final radio =
          _FakeConnector(
              nodes: const [],
              self: const ll.LatLng(41.81, -71.42),
              gps: '1',
            )
            ..fresh = false
            ..changedAt = DateTime(2026, 11, 16, 14, 2);
      await showRoute(tester, steps: steps, radio: radio);
      await tap(tester, find.text('Directions'));
      expect(
        find
            .textContaining(
              RegExp(
                r'^From your last known location \(2:02\sPM\), may be old$',
              ),
            )
            .hitTestable(),
        findsOneWidget,
      );

      radio
        ..changedAt = null
        ..notifyListeners();
      await settle(tester);
      expect(
        shown('From your last known location, may be old'),
        findsOneWidget,
      );

      radio
        ..fresh = true
        ..notifyListeners();
      await settle(tester);
      expect(shown('From your location'), findsOneWidget);
    });

    testWidgets('the directions start where the route does', (tester) async {
      await showRoute(tester, steps: steps);
      await longPress(tester, const LatLng(41.7, -71.3));
      await tap(tester, find.text('Route from here'));
      expect(routing.requests, hasLength(2));
      await tap(tester, find.text('Directions'));
      expect(find.textContaining('From 41.7').hitTestable(), findsOneWidget);
      expect(
        overlay<MapMarker>(tester, 'route-start').position,
        const LatLng(41.7, -71.3),
      );

      await tap(tester, find.text('Use my location'));
      expect(shown('From your location'), findsOneWidget);
      expect(find.text('Use my location'), findsNothing);
      expect(
        overlay<MapMarker>(tester, 'route-start').position,
        const LatLng(41.81, -71.42),
      );
    });

    testWidgets('a start off any path: a dotted line to where the route '
        'begins, and the distance counts it', (tester) async {
      // About 2.2 km north of your position.
      await showRoute(tester, snapStart: (lat: 41.83, lon: -71.42));
      expect(
        overlay<MapLine>(tester, 'route-start-gap').points,
        [const LatLng(41.81, -71.42), const LatLng(41.83, -71.42)],
      );
      expect(
        overlay<MapLine>(tester, 'route-start-gap').pattern,
        MapLinePattern.dotted,
      );
      expect(
        find.text('Starts 2.2 km from where you start, off any mapped path'),
        findsOneWidget,
      );
      // 1.1 km of route and 2.2 km to reach it.
      expect(find.textContaining('3.3 km'), findsOneWidget);
    });

    testWidgets('a start on a path: no gap', (tester) async {
      await showRoute(tester);
      expect(
        tester
            .widget<AppMap>(find.byType(AppMap))
            .overlays
            .where((o) => o.id == 'route-start-gap'),
        isEmpty,
      );
      expect(find.textContaining('off any mapped path'), findsNothing);
    });

    testWidgets('moved away from where the route was found: it starts from '
        'where you were', (tester) async {
      final radio = _FakeConnector(
        nodes: const [],
        self: const ll.LatLng(41.81, -71.42),
        gps: '1',
      );
      await showRoute(tester, steps: steps, radio: radio);
      await tap(tester, find.text('Directions'));
      expect(shown('From your location'), findsOneWidget);

      // 50 m on: still from your position.
      radio.moveSelf(const ll.LatLng(41.8104, -71.42));
      await settle(tester);
      expect(shown('From your location'), findsOneWidget);

      // 250 m on: the route stays where it was found.
      radio.moveSelf(const ll.LatLng(41.8123, -71.42));
      await settle(tester);
      expect(
        find.textContaining(RegExp(r'^From where you were at ')).hitTestable(),
        findsOneWidget,
      );
      expect(routing.requests, hasLength(1));
    });

    testWidgets('the long-press sheet says what is set already', (
      tester,
    ) async {
      routing = _Routing(maps);
      await showMap(tester);
      await longPress(tester, const LatLng(41.7, -71.3));
      expect(find.textContaining('now:'), findsNothing);
      await tap(tester, find.text('Route from here'));

      await longPress(tester, const LatLng(41.8, -71.4));
      expect(find.textContaining('Start now: 41.7'), findsOneWidget);
      expect(find.textContaining('Destination now:'), findsNothing);
      await tap(tester, find.text('Route here'));
      expect(routing.requests, hasLength(1));

      await longPress(tester, const LatLng(41.9, -71.5));
      expect(find.textContaining('Start now: 41.7'), findsOneWidget);
      expect(find.textContaining('Destination now: 41.8'), findsOneWidget);
    });

    // With a route set, its last rows were cut off.
    testWidgets('the long-press sheet shows all its rows on a small phone', (
      tester,
    ) async {
      routing = _Routing(maps);
      await showMap(tester, view: const Size(360, 640));
      await longPress(tester, const LatLng(41.7, -71.3));
      await tap(tester, find.text('Route from here'));
      await longPress(tester, const LatLng(41.8, -71.4));
      await tap(tester, find.text('Route here'));

      await longPress(tester, const LatLng(41.9, -71.5));
      await tap(tester, shown('Cancel'));
      expect(find.text('Route here'), findsNothing);

      // On its side, they scroll.
      tester.view.physicalSize = const Size(480, 320);
      await settle(tester);
      await longPress(tester, const LatLng(41.9, -71.5));
      expect(shown('Cancel'), findsNothing);
      await scrollTo(tester, find.text('Cancel'));
      await tap(tester, find.text('Cancel'));
      expect(find.text('Route here'), findsNothing);
    });

    // "Route here" would only say to download routing that isn't offered.
    testWidgets('is not offered with no routing data on the device or in '
        'the catalogue', (tester) async {
      routing = _Routing(maps, hasData: false);
      await showMap(tester);
      await longPress(tester, const LatLng(41.8, -71.4));
      expect(find.text('Route here'), findsNothing);
      expect(find.text('Route from here'), findsNothing);
    });

    testWidgets('back lowers it, then closes it, then leaves the map', (
      tester,
    ) async {
      await showRoute(tester, steps: steps);
      final open = height(tester);
      await tap(tester, find.text('Directions'));
      expect(height(tester), greaterThan(open));

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(height(tester), open);

      // The sheet slides away.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(RouteSheet), findsNothing);
      expect(find.byType(MapScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsNothing);
    });

    // The app bar changes colour over what scrolls, and keeps it once the
    // sheet is gone: the directions scroll under the sheet's own header.
    testWidgets('scrolled directions leave the app bar as it was', (
      tester,
    ) async {
      await showRoute(
        tester,
        steps: [for (var i = 0; i < 30; i++) Maneuver('Step $i', 0.1, 60, i)],
      );
      double barElevation() => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(AppBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .elevation;
      await tap(tester, find.text('Directions'));
      await tester.drag(find.text('Step 5'), const Offset(0, -400));
      await settle(tester);
      expect(shown('Step 0'), findsNothing);
      expect(barElevation(), 0);

      await tap(tester, find.byTooltip('Clear route'));
      expect(find.byType(RouteSheet), findsNothing);
      expect(barElevation(), 0);
    });

    // With no quick-switch bar under the map, the sheet reaches the bottom
    // of the screen, where the system has a bar of its own.
    testWidgets('stays above the system bar on a map opened from a chat', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      await showRoute(
        tester,
        steps: steps,
        screen: const MapScreen(
          overScreen: true,
          focus: MapFocusPoint(ll.LatLng(41.83, -71.4)),
        ),
      );
      final map = tester.getRect(find.byType(AppMap));
      expect(map.bottom, 900);
      var sheet = tester.getRect(find.byType(RouteSheet));
      expect(sheet.bottom, 900);
      expect(tester.getRect(find.text('Directions')).bottom, lessThan(866));
      expect(routeMiddle(tester).dy, closeTo((map.top + sheet.top) / 2, 1));

      await tap(tester, header);
      sheet = tester.getRect(find.byType(RouteSheet));
      expect(sheet.height, lessThan(100 + 34));
      expect(
        tester.getRect(find.textContaining('↑')).bottom,
        lessThanOrEqualTo(866),
      );

      await tap(tester, header);
      await tap(tester, find.text('Directions'));
      expect(tester.getRect(find.byType(RouteSheet)).top, map.top);
    });

    // The quick switch puts another screen in the map's place, and a new map
    // in that one's: the route was gone.
    testWidgets('is still there after a visit to Chats', (tester) async {
      Future<void> go(
        Widget screen, {
        bool replace = true,
        bool wait = true,
      }) async {
        final navigator = Navigator.of(
          tester.element(find.byType(Scaffold).first),
        );
        final route = MaterialPageRoute<void>(builder: (_) => screen);
        unawaited(
          replace ? navigator.pushReplacement(route) : navigator.push(route),
        );
        if (!wait) return tester.pump(const Duration(milliseconds: 50));
        await settle(tester);
        await settle(tester);
      }

      await showRoute(tester, steps: steps);
      // Back at once: the map left is still on its way out.
      await go(const Scaffold(), wait: false);
      await go(const MapScreen());
      expect(shown('Directions'), findsOneWidget);

      await go(const Scaffold());
      expect(find.byType(RouteSheet), findsNothing);

      await go(const MapScreen());
      expect(shown('Directions'), findsOneWidget);
      expect(overlay<MapLine>(tester, 'route').points, hasLength(2));
      expect(routing.requests, hasLength(1));
      final map = tester.getRect(find.byType(AppMap));
      final sheet = tester.getRect(find.byType(RouteSheet));
      expect(routeMiddle(tester).dy, closeTo((map.top + sheet.top) / 2, 1));

      // One left while it was being found is found again.
      routing.gate = Completer();
      await tap(tester, find.text('Paved'));
      await go(const Scaffold());
      await go(const MapScreen());
      expect(shown('Finding a route…'), findsOneWidget);
      routing.gate!.complete();
      await settle(tester);
      expect(routing.requests, hasLength(3));
      expect(routing.requests.last.$1, PathType.paved);
      expect(find.text('Finding a route…'), findsNothing);
      expect(overlay<MapLine>(tester, 'route').points, hasLength(2));

      // Closed, it stays closed.
      await tap(tester, find.byTooltip('Clear route'));
      await go(const Scaffold());
      await go(const MapScreen());
      expect(find.byType(RouteSheet), findsNothing);
    });

    // Navigate on a card: the screen it opens from.
    Widget card() => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => MapScreen.show(
            context,
            const MapFocusRoute(ll.LatLng(41.8, -71.4), label: 'Camp'),
          ),
          child: const Text('Navigate'),
        ),
      ),
    );

    // A route from a chat opens over it, and Back goes straight back to the
    // chat with the route kept for the Map tab.
    testWidgets('Navigate from a chat: over it, kept for the Map tab', (
      tester,
    ) async {
      routing = _Routing(maps, elevations: const [10, 12], steps: steps);
      await showMap(tester, screen: card());
      await tap(tester, find.text('Navigate'));
      await settle(tester);
      expect(find.textContaining('To Camp'), findsOneWidget);
      expect(shown('Directions'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Camp');

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Navigate'), findsOneWidget);

      unawaited(
        Navigator.of(tester.element(find.text('Navigate'))).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MapScreen()),
        ),
      );
      await settle(tester);
      await settle(tester);
      expect(find.textContaining('To Camp'), findsOneWidget);
      expect(shown('Directions'), findsOneWidget);
      expect(routing.requests, hasLength(1));
    });

    // The chat was opened from the Map tab, which was left far from Camp:
    // Back returns to the chat, then the Map tab shows the route whole.
    testWidgets('Navigate from a chat over the Map tab: the chat stays, and '
        'the Map tab shows the route', (tester) async {
      routing = _Routing(maps, elevations: const [10, 12], steps: steps);
      await showMap(tester);
      tester
          .widget<AppMap>(find.byType(AppMap))
          .controller!
          .move(const LatLng(45, -110), zoom: 10);
      await settle(tester);
      unawaited(
        Navigator.of(tester.element(find.byType(AppMap)))
            .push(MaterialPageRoute<void>(builder: (_) => card())),
      );
      await settle(tester);
      await tap(tester, find.text('Navigate'));
      await settle(tester);
      expect(find.byType(MapScreen, skipOffstage: false), findsNWidgets(2));
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.textContaining('To Camp'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Navigate'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(QuickSwitchBar), findsOneWidget);
      expect(shown('Directions'), findsOneWidget);
      expect(find.textContaining('To Camp'), findsOneWidget);
      expect(routing.requests, hasLength(1));
      final map = tester.getRect(find.byType(AppMap));
      final sheet = tester.getRect(find.byType(RouteSheet));
      expect(routeMiddle(tester).dy, closeTo((map.top + sheet.top) / 2, 1));
    });

    // A quick look over a chat leaves the Map tab's route where it was.
    testWidgets("a map over a chat starts without the Map tab's route", (
      tester,
    ) async {
      await showRoute(tester, steps: steps);
      unawaited(
        Navigator.of(tester.element(find.byType(AppMap))).push(
          MaterialPageRoute<void>(
            builder: (_) => Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => LinkHandler.openMapAt(
                    context,
                    const ll.LatLng(41.83, -71.4),
                    label: 'Spring',
                  ),
                  child: const Text('Card map'),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      await tap(tester, find.text('Card map'));
      await settle(tester);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Spring');
      expect(find.byType(RouteSheet), findsNothing);
      await tester.pump(const Duration(seconds: 3));

      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(header, findsOneWidget);
      expect(routing.requests, hasLength(1));
    });
  });

  // Charts show the trip on the water and the other maps the route on land:
  // the two never mix (owner, 2026-11-24).
  group('a trip on the water', () {
    late FakeWaterRouting water;
    late _Routing routing;

    setUp(() {
      maps = MapPacksService(
        manager: PackManager(Directory('${tmp.path}/packs')),
        downloader: _NoDownloads(),
        cacheDir: tmp,
        styles: StyleRegistry(MemoryStyles(maps: const ['osm', 'charts'])),
      );
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    AppSettingsService settings(WidgetTester tester) =>
        tester.element(find.byType(MapScreen)).read<AppSettingsService>();

    Future<void> setMap(WidgetTester tester, String type) async {
      await settings(tester).setMapType(type);
      await settle(tester);
    }

    Future<void> routeHere(WidgetTester tester) async {
      tester.widget<AppMap>(find.byType(AppMap)).onLongPress!(
        const LatLng(41.8, -71.4),
      );
      await settle(tester);
      await tester.tap(find.text('Route here'));
      await settle(tester);
    }

    Future<void> showCharts(
      WidgetTester tester, {
      WaterRoutingProblem? problem,
      EndsShort? endsShort,
      UiViewStateService? viewState,
      Size view = const Size(800, 900),
      bool askBoat = false,
    }) async {
      water = FakeWaterRouting(maps, problem: problem, endsShort: endsShort);
      routing = _Routing(maps);
      await pumpMap(
        tester,
        _FakeConnector(nodes: const [], self: const ll.LatLng(41.81, -71.42)),
        routing: routing,
        water: water,
        mapType: 'charts',
        viewState: viewState,
        view: view,
      );
      if (!askBoat) await settings(tester).setWaterBoatAskDismissed(true);
    }

    RouteSheetBody? body(WidgetTester tester) {
      final sheets = find.byType(RouteSheet);
      return sheets.evaluate().isEmpty
          ? null
          : tester.widget<RouteSheet>(sheets).body;
    }

    testWidgets('on the charts, Route here finds one in its own colour', (
      tester,
    ) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      await showCharts(tester);
      await routeHere(tester);

      expect(body(tester), isA<WaterRouteBody>());
      expect(find.text('5.0 nm · 50 min'), findsOneWidget);
      expect(water.requests, [const WaterRouteOptions()]);
      expect(routing.requests, isEmpty);
      expect(
        overlay<MapLine>(tester, 'route').color,
        waterRouteColor(darkMap: false).withValues(alpha: 0.85),
      );
    });

    Finder inDialog(Finder f) =>
        find.descendant(of: find.byType(AlertDialog), matching: f);

    Future<void> tapInDialog(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(inDialog(f));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(f));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'before each new trip the boat, until "Don\'t show this again"',
      (tester) async {
        await showCharts(tester, askBoat: true);
        await routeHere(tester);
        expect(inDialog(find.text('Your boat')), findsOneWidget);
        expect(water.requests, isEmpty, reason: 'asked first');
        expect(
          inDialog(find.text('Not for navigation')),
          findsOneWidget,
          reason: "the first time, the data's notice is in it",
        );

        await tapInDialog(tester, find.widgetWithText(ChoiceChip, 'None'));
        await tapInDialog(tester, find.text('OK'));
        expect(water.requests, [const WaterRouteOptions(offLandNm: null)]);
        expect(
          settings(tester).settings.waterRouteOptions,
          const WaterRouteOptions(offLandNm: null),
        );
        expect(body(tester), isA<WaterRouteBody>());
        expect(find.byType(AlertDialog), findsNothing, reason: 'no 2nd notice');

        // The next trip asks again, without the notice.
        await routeHere(tester);
        expect(inDialog(find.text('Your boat')), findsOneWidget);
        expect(inDialog(find.text('Not for navigation')), findsNothing);
        await tapInDialog(tester, find.text("Don't show this again"));
        await tapInDialog(tester, find.text('OK'));
        expect(water.requests, hasLength(2));
        expect(settings(tester).settings.waterBoatAskDismissed, isTrue);

        await routeHere(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(water.requests, hasLength(3));
      },
    );

    testWidgets('a number still being typed counts; Cancel finds nothing', (
      tester,
    ) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      await showCharts(tester, askBoat: true);
      await routeHere(tester);
      await tapInDialog(tester, find.text('Cancel'));
      expect(water.requests, isEmpty);
      expect(body(tester), isNull);

      await routeHere(tester);
      final mast = inDialog(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Mast height'),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(TextField),
        ),
      );
      await tester.ensureVisible(mast);
      await tester.enterText(mast, '12');
      await tester.tap(inDialog(find.text('OK')));
      await tester.pumpAndSettle();
      expect(water.requests.single.mastHeightM, 12, reason: 'metres here');
    });

    testWidgets('on a wide screen, a panel at the side with its legs', (
      tester,
    ) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      await showCharts(tester, view: const Size(1200, 800));
      await routeHere(tester);

      expect(body(tester), isA<WaterRouteBody>());
      final map = tester.getRect(find.byType(AppMap));
      final panel = tester.getRect(find.byType(RouteSheet));
      expect(panel.left, 0);
      expect(panel.width, RouteSheet.sideWidth);
      expect(map.left, greaterThan(panel.right));
      expect(find.text('67°M · 5.0 nm'), findsOneWidget);
    });

    testWidgets('the first trip shows the data\'s notice, once', (
      tester,
    ) async {
      await showCharts(tester);
      await routeHere(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Not for navigation'), findsWidgets);
      await tester.tap(find.text('OK'));
      await settle(tester);

      await routeHere(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('each map keeps its own: switching swaps them, X ends one', (
      tester,
    ) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      await showCharts(tester);
      await routeHere(tester);
      expect(body(tester), isA<WaterRouteBody>());

      // The street map has no trip on the water, and a route of its own.
      await setMap(tester, 'osm');
      expect(body(tester), isNull);
      expect(overlays(tester).where((o) => o.id == 'route'), isEmpty);
      await routeHere(tester);
      expect(body(tester), isA<LandRouteBody>());
      expect(routing.requests, hasLength(1));

      // Back on the charts: the trip as it was, not found again.
      await setMap(tester, 'charts');
      expect(body(tester), isA<WaterRouteBody>());
      expect(water.requests, hasLength(1));

      // X ends the trip; the route on land stays.
      await tester.tap(find.byTooltip('Clear route'));
      await settle(tester);
      expect(body(tester), isNull);
      await setMap(tester, 'osm');
      expect(body(tester), isA<LandRouteBody>());
      expect(routing.requests, hasLength(1));
    });

    testWidgets('one that ends short offers the route on land', (tester) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      await showCharts(
        tester,
        endsShort: const EndsShort(
          reason: EndsShortReason.noConnection,
          remainingM: 3704,
          lowObjects: [],
          deepestWayM: null,
        ),
      );
      await routeHere(tester);
      expect(
        find.textContaining('no charted water joins them'),
        findsOneWidget,
      );
      expect(overlay<MapLine>(tester, 'route-rest').points, hasLength(2));

      await tester.tap(find.text('Route on land'));
      await settle(tester);
      expect(settings(tester).settings.mapType, 'osm');
      expect(body(tester), isA<LandRouteBody>());
      expect(routing.requests, hasLength(1));
    });

    testWidgets('no water routing at the place says so and offers the land', (
      tester,
    ) async {
      await showCharts(tester, problem: WaterRoutingProblem.noTiles);
      await routeHere(tester);
      expect(find.text('No water routing here'), findsOneWidget);
      expect(find.text('Route on land'), findsOneWidget);
      // No chart area at either end to get it for.
      expect(find.text('Show download'), findsNothing);
    });

    testWidgets('areas of different builds offer the download', (tester) async {
      await showCharts(tester, problem: WaterRoutingProblem.mixedBuilds);
      await routeHere(tester);
      expect(
        find.text(
          'Update water routing in Offline maps: its areas are of different '
          'builds.',
        ),
        findsOneWidget,
      );
      expect(find.text('Show download'), findsOneWidget);
      expect(find.text('Route on land'), findsNothing);
    });

    testWidgets('the Map tab keeps the trip apart from the route on land', (
      tester,
    ) async {
      await PrefsManager.instance.setBool(RouteSheet.waterNoticeToldKey, true);
      final viewState = UiViewStateService();
      await showCharts(tester, viewState: viewState);
      await routeHere(tester);
      expect(viewState.mapWaterRoute?.result, isNotNull);
      expect(viewState.mapRoute, isNull);
    });
  });

  testWidgets('nodes and the radio are map markers, labelled from zoom 13', (
    tester,
  ) async {
    final repeater = _node('Hilltop', advTypeRepeater, 1, 41.8, -71.4);
    final chat = _node('Alice', advTypeChat, 2, 41.82, -71.41);
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [repeater, chat],
        self: const ll.LatLng(41.81, -71.42),
      ),
    );

    final hilltop = overlay<MapMarker>(tester, 'node:${repeater.publicKeyHex}');
    expect(hilltop.label, 'Hilltop');
    expect(hilltop.labelMinZoom, 13);
    expect(hilltop.position, const LatLng(41.8, -71.4));
    expect(hilltop.onTap, isNotNull);
    expect(
      overlay<MapMarker>(tester, 'node:${chat.publicKeyHex}').label,
      'Alice',
    );
    final self = overlay<MapMarker>(tester, 'self');
    expect(self.label, 'You');
    expect(self.interactive, isFalse);
    expect(find.byType(QuickSwitchBar), findsOneWidget);
  });

  testWidgets(
    'guesses use the radio\'s range: 912 km apart is a guess, 1,750 km is not',
    (tester) async {
      Contact target(int seed, int routeHop) => Contact(
        publicKey: Uint8List.fromList(List.filled(32, seed)),
        name: 'T$seed',
        type: advTypeChat,
        pathLength: 1,
        path: Uint8List.fromList([routeHop]),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
        inboundPath: Uint8List.fromList(const [0x01]),
        inboundHopCount: 1,
        inboundPathHashSize: 1,
      );
      final near = target(0x10, 0x02);
      final across = target(0x11, 0x03);
      final tooFar = target(0x12, 0x04);
      await pumpMap(
        tester,
        _RadioConnector(
          nodes: [
            _node('A', advTypeRepeater, 0x01, 37.3, -122.0),
            _node('B', advTypeRepeater, 0x02, 37.5, -122.2),
            _node('Portland', advTypeRepeater, 0x03, 45.5, -122.7),
            _node('Rapid City', advTypeRepeater, 0x04, 44.1, -103.2),
            near,
            across,
            tooFar,
          ],
        ),
      );
      await tester
          .element(find.byType(AppMap))
          .read<AppSettingsService>()
          .setMapShowGuessedLocations(true);
      await tester.pump();

      final guess = overlay<MapMarker>(tester, 'guess:${near.publicKeyHex}');
      expect(guess.position.latitude, closeTo(37.4, 0.01));
      expect(guess.position.longitude, closeTo(-122.1, 0.01));
      expect(
        overlays(tester).map((o) => o.id),
        contains('guess:${across.publicKeyHex}'),
      );
      expect(
        overlays(tester).map((o) => o.id),
        isNot(contains('guess:${tooFar.publicKeyHex}')),
      );
    },
  );

  group('guessed pins', () {
    setUp(() => guessedLocationsOn = true);
    tearDown(() => guessedLocationsOn = false);

    final anchor = _node('Anchor', advTypeRepeater, 0x01, 37.3, -122.0);
    Contact heardVia(int seed, int type) => Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: 'T$seed',
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
      inboundPath: Uint8List.fromList(const [0x01]),
      inboundHopCount: 1,
      inboundPathHashSize: 1,
    );
    final chat = heardVia(0x10, advTypeChat);
    final repeater = heardVia(0x11, advTypeRepeater);
    final room = heardVia(0x12, advTypeRoom);

    String guessId(Contact c) => 'guess:${c.publicKeyHex}';
    Iterable<String?> ids(WidgetTester tester) =>
        overlays(tester).map((o) => o.id);
    AppSettingsService settingsOf(WidgetTester tester) =>
        tester.element(find.byType(AppMap)).read<AppSettingsService>();
    // What the legend counts, as the layers sheet hands it over.
    Future<int> legendGuesses(WidgetTester tester) async {
      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.tap(find.byTooltip('Map layers'));
      await settle();
      final guessed = tester
          .widget<MapLayersSheet>(find.byType(MapLayersSheet))
          .legendCounts!()
          .guessed;
      await tester.tap(find.byTooltip('Close'));
      await settle();
      return guessed;
    }

    testWidgets('follow the node layers, and the legend counts what is drawn', (
      tester,
    ) async {
      await pumpMap(
        tester,
        _RadioConnector(nodes: [anchor, chat, repeater, room]),
      );
      final settings = settingsOf(tester);
      expect(
        ids(tester),
        containsAll([guessId(chat), guessId(repeater), guessId(room)]),
      );
      expect(await legendGuesses(tester), 3);

      await settings.setMapShowChatNodes(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(chat))));
      expect(ids(tester), contains(guessId(repeater)));
      expect(await legendGuesses(tester), 2);

      await settings.setMapShowRepeaters(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(repeater))));
      expect(await legendGuesses(tester), 1);

      await settings.setMapShowOtherNodes(false);
      await tester.pump();
      expect(ids(tester), isNot(contains(guessId(room))));
      expect(await legendGuesses(tester), 0);
    });

    testWidgets('are off in the overlaps view, and off the legend', (
      tester,
    ) async {
      // Sharing a first byte, so the filter alone would keep them in this view.
      Contact sharing(int fill) => Contact(
        publicKey: Uint8List.fromList([0x20, ...List.filled(31, fill)]),
        name: 'S$fill',
        type: advTypeRepeater,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
        inboundPath: Uint8List.fromList(const [0x01]),
        inboundHopCount: 1,
        inboundPathHashSize: 1,
      );
      final first = sharing(0x21);
      final second = sharing(0x22);
      await pumpMap(tester, _RadioConnector(nodes: [anchor, first, second]));
      expect(ids(tester), containsAll([guessId(first), guessId(second)]));

      await settingsOf(tester).setMapShowOverlaps(true);
      await tester.pump();

      expect(ids(tester), isNot(contains(guessId(first))));
      expect(ids(tester), isNot(contains(guessId(second))));
      expect(await legendGuesses(tester), 0);
    });

    testWidgets('in a trace: no chat nodes, repeaters whatever the layer', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat, repeater]));
      await settingsOf(tester).setMapShowRepeaters(false);
      await _startPathTrace(tester);
      await tester.pump();

      expect(ids(tester), isNot(contains(guessId(chat))));
      expect(ids(tester), contains(guessId(repeater)));
    });

    testWidgets('show the contact as it is now, not as it was first guessed', (
      tester,
    ) async {
      final connector = _RadioConnector(nodes: [anchor, chat]);
      await pumpMap(tester, connector);
      final before = overlay<MapMarker>(tester, guessId(chat));

      connector.replaceNode(1, chat.copyWith(name: 'Renamed'));
      await tester.pump(const Duration(milliseconds: 200));

      final after = overlay<MapMarker>(tester, guessId(chat));
      expect(after.label, 'Renamed');
      expect(after.position, before.position);

      after.onTap!();
      await tester.pump();
      expect(find.text('Renamed'), findsWidgets);
    });

    testWidgets('long-press in a trace keeps the estimated location', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await _startPathTrace(tester);
      await tester.pump();

      overlay<MapMarker>(tester, guessId(repeater)).onLongPress!();
      await tester.pump();

      expect(find.textContaining('Est. Location'), findsOneWidget);
    });

    testWidgets('a guess in a trace stays an estimate, off the contact', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await _startPathTrace(tester);
      await tester.pump();
      final marker = overlay<MapMarker>(tester, guessId(repeater));

      marker.onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.pathContacts!.single.hasLocation, isFalse);
      final position = trace.guessedPositions[repeater.publicKeyHex]!;
      expect(position.latitude, marker.position.latitude);
      expect(position.longitude, marker.position.longitude);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'a route the app wrote is no anchor, as soon as it is written',
      (tester) async {
        final routed = Contact(
          publicKey: Uint8List.fromList(List.filled(32, 0x13)),
          name: 'Routed',
          type: advTypeChat,
          pathLength: 1,
          path: Uint8List.fromList(const [0x01]),
          pathHashSize: 1,
          lastSeen: DateTime.now(),
        );
        final connector = _RadioConnector(nodes: [anchor, routed]);
        await pumpMap(tester, connector);
        expect(ids(tester), contains(guessId(routed)));

        connector.written.add(routed.publicKeyHex);
        connector.replaceNode(1, routed);
        await tester.pump(const Duration(milliseconds: 200));

        expect(ids(tester), isNot(contains(guessId(routed))));
      },
    );

    testWidgets('a return trace carries the estimate too', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await _startPathTrace(tester);
      await tester.pump();
      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, contains(repeater.publicKeyHex));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new trace starts with no old estimates', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await _startPathTrace(tester);
      await tester.pump();
      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      Navigator.of(tester.element(find.byType(PathTraceMapScreen))).pop();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await _startPathTrace(tester);
      await tester.pump();
      overlay<MapMarker>(tester, 'node:${anchor.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('undoing a guessed hop drops its estimate', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, repeater]));
      await _startPathTrace(tester);
      await tester.pump();

      overlay<MapMarker>(tester, guessId(repeater)).onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      overlay<MapMarker>(tester, 'node:${anchor.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final trace = tester.widget<PathTraceMapScreen>(
        find.byType(PathTraceMapScreen),
      );
      expect(trace.guessedPositions, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('frame the map only when nothing else can', (tester) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat]));
      // A map with content opens on it, not on where it was last left.
      tester
          .element(find.byType(AppMap))
          .read<UiViewStateService>()
          .setMapCamera(const MapCamera(center: LatLng(10, 10), zoom: 5));
      // Anchors count whatever the filter; a key prefix leaves only the guess.
      final settings = settingsOf(tester);
      await settings.setMapKeyPrefixEnabled(true);
      await settings.setMapKeyPrefix('10');
      await tester.pump();
      expect(ids(tester), contains(guessId(chat)));
      expect(ids(tester), isNot(contains('node:${anchor.publicKeyHex}')));

      final camera = tester.widget<AppMap>(find.byType(AppMap)).initialCamera!;
      expect(camera.center.latitude, closeTo(37.3, 0.01));
      expect(camera.center.longitude, closeTo(-122.0, 0.01));
    });

    testWidgets('leave the framing to real positions when there are any', (
      tester,
    ) async {
      await pumpMap(tester, _RadioConnector(nodes: [anchor, chat]));

      final camera = tester.widget<AppMap>(find.byType(AppMap)).initialCamera!;
      expect(camera.center.latitude, 37.3);
      expect(camera.center.longitude, -122.0);
    });
  });

  testWidgets('over a chat: back button, labelled pin, no quick-switch bar', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const []),
      screen: const MapScreen(
        overScreen: true,
        focus: MapFocusPoint(ll.LatLng(41.83, -71.4), label: 'Trailhead'),
      ),
    );
    final pin = overlay<MapMarker>(tester, 'highlight');
    expect(pin.label, 'Trailhead');
    expect(pin.anchor, Alignment.bottomCenter);
    expect(find.byType(QuickSwitchBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MapScreen), findsNothing);
  });

  // Back from a map could land on another map: a second one opened over the
  // Map tab from its TRAX sheet (Martin, 2026-11-24). What you tap on a map
  // now shows on it; from a chat, a map opens over the chat.
  group('shown on a map', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // A chat with a card's map button; [tab] makes it the Chats tab.
    Widget chat({bool tab = false}) => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () {
            if (tab) {
              context.read<UiViewStateService>().chatsTab = ModalRoute.of(
                context,
              );
            }
            LinkHandler.openMapAt(
              context,
              const ll.LatLng(41.83, -71.4),
              label: 'Camp',
            );
          },
          child: const Text('Card map'),
        ),
      ),
    );

    // With nothing downloaded there, the map tries the zoom again for 3 s.
    Future<void> outOfDetail(WidgetTester tester) =>
        tester.pump(const Duration(seconds: 3));

    ll.LatLng center(WidgetTester tester) {
      final c = tester
          .widget<AppMap>(find.byType(AppMap))
          .controller!
          .camera!
          .center;
      return ll.LatLng(c.latitude, c.longitude);
    }

    testWidgets('from a chat: a map over it; Back returns there', (
      tester,
    ) async {
      await pumpMap(tester, _FakeConnector(nodes: const []), screen: chat());
      await tester.tap(find.text('Card map'));
      await settle(tester);
      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).overScreen,
        isTrue,
      );
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Camp');
      expect(center(tester).latitude, closeTo(41.83, 1e-6));
      expect(find.byType(QuickSwitchBar), findsNothing);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Card map'), findsOneWidget);
    });

    // The chat was opened from the Map tab: Back returns to the chat, then
    // to the Map tab as it was.
    testWidgets('from a chat over the Map tab: over the chat, and the Map '
        'tab stays as it was', (tester) async {
      await pumpMap(tester, _FakeConnector(nodes: const []));
      final before = center(tester);
      unawaited(
        Navigator.of(tester.element(find.byType(AppMap)))
            .push(MaterialPageRoute<void>(builder: (_) => chat())),
      );
      await settle(tester);
      await tester.tap(find.text('Card map'));
      await settle(tester);
      expect(find.byType(MapScreen, skipOffstage: false), findsNWidgets(2));
      expect(find.byType(BackButton), findsOneWidget);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Camp');
      expect(center(tester).latitude, closeTo(41.83, 1e-6));
      await outOfDetail(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Card map'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(QuickSwitchBar), findsOneWidget);
      expect(center(tester).latitude, closeTo(before.latitude, 1e-6));
      expect(
        overlays(tester).whereType<MapMarker>().map((m) => m.id),
        isNot(contains('highlight')),
      );
    });

    testWidgets('on a map over a chat: shown there, not on a third map', (
      tester,
    ) async {
      await pumpMap(tester, _FakeConnector(nodes: const []), screen: chat());
      await tester.tap(find.text('Card map'));
      await settle(tester);
      MapScreen.show(
        tester.element(find.byType(AppMap)),
        const MapFocusPoint(ll.LatLng(41.85, -71.45), label: 'Spring'),
      );
      await settle(tester);
      expect(find.byType(MapScreen, skipOffstage: false), findsOneWidget);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Spring');
      expect(center(tester).latitude, closeTo(41.85, 1e-6));
      await outOfDetail(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Card map'), findsOneWidget);
    });

    testWidgets('from the Chats tab: the Map tab in its place', (tester) async {
      await pumpMap(
        tester,
        _FakeConnector(nodes: const []),
        screen: chat(tab: true),
      );
      await tester.tap(find.text('Card map'));
      await settle(tester);
      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).overScreen,
        isFalse,
      );
      expect(find.text('Card map', skipOffstage: false), findsNothing);
      expect(find.byType(QuickSwitchBar), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Camp');
    });

    testWidgets('on the Map tab: shown there', (tester) async {
      await pumpMap(tester, _FakeConnector(nodes: const []));
      MapScreen.show(
        tester.element(find.byType(AppMap)),
        const MapFocusPoint(ll.LatLng(41.83, -71.4), label: 'Camp'),
      );
      await settle(tester);
      expect(find.byType(MapScreen, skipOffstage: false), findsOneWidget);
      expect(overlay<MapMarker>(tester, 'highlight').label, 'Camp');
      expect(center(tester).latitude, closeTo(41.83, 1e-6));
      await outOfDetail(tester);
    });
  });

  testWidgets('the menu opens Offline maps', (tester) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    await tester.tap(find.byIcon(Icons.more_vert));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Offline maps'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(OfflineMapsScreen), findsOneWidget);
  });

  testWidgets('Path trace is in the menu, not the bar; the icon help last', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    expect(find.byIcon(Icons.radar), findsNothing);
    await tester.tap(find.byIcon(Icons.more_vert));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final texts = [
      for (final item in find
          .byWidgetPredicate((w) => w is PopupMenuItem)
          .evaluate())
        tester
            .widget<Text>(
              find.descendant(
                of: find.byWidget(item.widget),
                matching: find.byType(Text),
              ),
            )
            .data,
    ];
    expect(texts.take(2), contains('Path Trace'), reason: 'with the tools');
    expect(texts.last, 'What the icons mean');
    await tester.tap(find.text('What the icons mean'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(IconHelpSheet), findsOneWidget);
  });

  testWidgets('the layers button: map types, details and node types', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    final settings = tester
        .element(find.byType(MapScreen))
        .read<AppSettingsService>();
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Map type'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(
      find.text('Not downloaded'),
      findsNWidgets(6),
      reason: 'USGS, charts, contours, hill shading, parks and places: '
          'nothing downloaded',
    );
    expect(find.text('Nodes'), findsOneWidget);

    await tester.tap(find.text('Dark map'));
    await tester.pump();
    expect(settings.settings.mapTheme, 'dark');

    await tester.tap(find.text('Downloaded areas'));
    await tester.pump();
    expect(settings.settings.mapDownloadedAreas, isFalse);
    await tester.tap(find.text('Repeaters'));
    await tester.pump();
    expect(settings.settings.mapShowRepeaters, isFalse);
  });

  testWidgets('a layer with nothing downloaded opens Offline maps', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    final settings = tester
        .element(find.byType(MapScreen))
        .read<AppSettingsService>();
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Parks'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(OfflineMapsScreen), findsOneWidget);
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      OfflineMapsTab.maps.index,
      reason: 'where it can be downloaded',
    );
    expect(settings.settings.mapParks, isTrue, reason: 'kept for later');
  });

  testWidgets('the layers sheet: its buttons by the X, five tiles to a row', (
    tester,
  ) async {
    // A narrow phone: tiles shrink so five still fit.
    await pumpMap(
      tester,
      _FakeConnector(nodes: const []),
      view: const Size(360, 800),
    );
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Legend, More filters and Offline maps, left of the X, and no rows
    // under the tiles for them.
    final xs = [
      for (final tooltip in ['Legend', 'More filters', 'Offline maps', 'Close'])
        tester.getCenter(find.byTooltip(tooltip)).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(find.text('More filters'), findsNothing);
    expect(find.text('Offline maps'), findsNothing);

    // The five node types share one row on a phone.
    expect(
      tester.getTopLeft(find.text('Guessed')).dy,
      tester.getTopLeft(find.text('Repeaters')).dy,
    );

    // With nothing to update, Offline maps opens on maps to download.
    await tester.tap(find.byTooltip('Offline maps'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      OfflineMapsTab.maps.index,
    );
  });

  testWidgets('a filter button on the map while it draws nodes', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    final settings = tester
        .element(find.byType(MapScreen))
        .read<AppSettingsService>();
    await tester.tap(find.byTooltip('Filter Nodes'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.widgetWithText(AlertDialog, 'Filter Nodes'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // With every node layer off there's nothing to filter.
    await settings.setMapShowRepeaters(false);
    await settings.setMapShowChatNodes(false);
    await settings.setMapShowOtherNodes(false);
    await settings.setMapShowMarkers(false);
    await settings.setMapShowGuessedLocations(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Filter Nodes'), findsNothing);

    await settings.setMapShowChatNodes(true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Filter Nodes'), findsOneWidget);
  });

  testWidgets('the layers Charts tile, not downloaded, opens the Charts tab', (
    tester,
  ) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Charts'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Map type', skipOffstage: false),
      findsNothing,
      reason: 'the sheet closed, not left under Offline maps',
    );
    expect(
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
      OfflineMapsTab.charts.index,
    );
  });

  MapCamera camera(WidgetTester tester) =>
      tester.widget<AppMap>(find.byType(AppMap)).controller!.camera!;

  testWidgets("GPS on: My location goes to the GPS's blue dot", (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: const [],
        self: const ll.LatLng(41.81, -71.42),
        gps: '1',
      ),
    );
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
    expect(
      camera(tester).zoom,
      10,
      reason: "nothing downloaded: as close as the base map's detail goes",
    );
    expect(
      overlay<MapMarker>(tester, 'self').label,
      isNull,
      reason: 'the blue dot, not the "You" pin',
    );
  });

  testWidgets('GPS off: My location offers to turn it on', (tester) async {
    final connector = _FakeConnector(
      nodes: const [],
      self: const ll.LatLng(41.81, -71.42),
      gps: '0',
    );
    await pumpMap(tester, connector);
    expect(overlay<MapMarker>(tester, 'self').label, 'You');
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(find.text('Turn on GPS?'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(connector.gpsSets, [true]);
    expect(overlay<MapMarker>(tester, 'self').label, isNull);
  });

  testWidgets('GPS on, no position yet: says so', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(0, 0), gps: '1'),
    );
    await tester.tap(find.byTooltip('My location'));
    await tester.pump();
    expect(find.textContaining('No location yet'), findsOneWidget);
  });

  testWidgets('no GPS module: no My location; "You" is the typed position', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(41.81, -71.42)),
    );
    expect(find.byTooltip('My location'), findsNothing);
    expect(overlay<MapMarker>(tester, 'self').label, 'You');
  });

  testWidgets('a radio without a position: no "You"', (tester) async {
    // A radio with no position reports 0, 0: never centre on it.
    await pumpMap(
      tester,
      _FakeConnector(nodes: const [], self: const ll.LatLng(0, 0)),
    );
    expect(overlays(tester).where((o) => o.id == 'self'), isEmpty);
  });

  // A radio that lost its fix keeps reporting the last one (safety review
  // CH-07): blue only while the reading changes.
  group('a GPS reading that stopped changing', () {
    _FakeConnector frozen({DateTime? since}) =>
        _FakeConnector(
            nodes: const [],
            self: const ll.LatLng(41.81, -71.42),
            gps: '1',
          )
          ..fresh = false
          ..changedAt = since;

    testWidgets('is a grey "Last known" pin with its time', (tester) async {
      final radio = frozen(since: DateTime(2026, 11, 16, 14, 2));
      await pumpMap(tester, radio);
      final self = overlay<MapMarker>(tester, 'self');
      expect(self.label, matches(RegExp(r'^Last known · 2:02\sPM$')));
      expect(self.labelMinZoom, isNull, reason: 'at every zoom');

      radio
        ..fresh = true
        ..notifyListeners();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(overlay<MapMarker>(tester, 'self').label, isNull);
    });

    testWidgets("in the phone's 24-hour time", (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpMap(tester, frozen(since: DateTime(2026, 11, 16, 14, 2)));
      expect(overlay<MapMarker>(tester, 'self').label, 'Last known · 14:02');
    });

    testWidgets('with no change seen since connecting, has no time', (
      tester,
    ) async {
      await pumpMap(tester, frozen());
      expect(overlay<MapMarker>(tester, 'self').label, 'Last known');
    });

    testWidgets('My location still goes there', (tester) async {
      await pumpMap(tester, frozen());
      tester
          .widget<AppMap>(find.byType(AppMap))
          .controller!
          .move(const LatLng(40, -100), zoom: 6);
      await tester.pump();
      await tester.tap(find.byTooltip('My location'));
      await tester.pump();
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
    });

    testWidgets('a typed position is still the "You" pin', (tester) async {
      await pumpMap(tester, frozen()..gps = '0');
      expect(overlay<MapMarker>(tester, 'self').label, 'You');
    });
  });

  group('where the map opens', () {
    final contact = _node('Contact', advTypeChat, 3, 37.3, -122.0);
    const gps = ll.LatLng(41.81, -71.42);
    // Leaves the map for another screen, as the quick switch does.
    Future<void> leave(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('back on the map in the same run: where it was left', (
      tester,
    ) async {
      final viewState = UiViewStateService();
      final connector = _FakeConnector(nodes: [contact]);
      await pumpMap(tester, connector, viewState: viewState);
      expect(camera(tester).center.latitude, closeTo(37.3, 0.01));
      tester
          .widget<AppMap>(find.byType(AppMap))
          .controller!
          .move(const LatLng(40, -100), zoom: 6);
      await tester.pump();
      await leave(tester);

      await pumpMap(tester, connector, viewState: viewState);
      expect(camera(tester).center.latitude, closeTo(40, 1e-6));
      expect(camera(tester).center.longitude, closeTo(-100, 1e-6));
      expect(camera(tester).zoom, closeTo(6, 1e-6));
    });

    testWidgets("the first map of a run opens on the radio's GPS position", (
      tester,
    ) async {
      await pumpMap(
        tester,
        _FakeConnector(nodes: [contact], self: gps, gps: '1'),
      );
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
      expect(camera(tester).center.longitude, closeTo(-71.42, 1e-6));
      expect(
        camera(tester).zoom,
        AppMap.baseMapZoom,
        reason: 'nothing downloaded there: as close as My location goes',
      );
    });

    testWidgets('it opens there before the reading has changed, too', (
      tester,
    ) async {
      await pumpMap(
        tester,
        _FakeConnector(nodes: [contact], self: gps, gps: '1')..fresh = false,
      );
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
      expect(camera(tester).center.longitude, closeTo(-71.42, 1e-6));
    });

    testWidgets('a fix that comes later moves the map there, once a run', (
      tester,
    ) async {
      final viewState = UiViewStateService();
      final connector = _FakeConnector(nodes: [contact], gps: '1');
      await pumpMap(tester, connector, viewState: viewState);
      expect(camera(tester).center.latitude, closeTo(37.3, 0.01));

      connector.moveSelf(gps);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));

      // From then on the map is yours: it doesn't follow, here or later.
      connector.moveSelf(const ll.LatLng(42.5, -72.5));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
      await leave(tester);
      await pumpMap(tester, connector, viewState: viewState);
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
    });

    testWidgets('a map touched before the fix stays where you put it', (
      tester,
    ) async {
      final connector = _FakeConnector(nodes: [contact], gps: '1');
      await pumpMap(tester, connector);
      await tester.drag(find.byType(AppMap), const Offset(80, 0));
      await tester.pump(const Duration(milliseconds: 200));
      final moved = camera(tester).center;

      connector.moveSelf(gps);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(camera(tester).center.latitude, closeTo(moved.latitude, 1e-6));
      expect(camera(tester).center.longitude, closeTo(moved.longitude, 1e-6));
    });

    testWidgets('GPS off: the position typed into the radio moves nothing', (
      tester,
    ) async {
      await pumpMap(
        tester,
        _FakeConnector(nodes: [contact], self: gps, gps: '0'),
      );
      expect(camera(tester).center.latitude, closeTo(37.3, 0.01));
    });

    testWidgets("a map over a chat keeps the Map tab's view", (tester) async {
      final viewState = UiViewStateService();
      final connector = _FakeConnector(nodes: [contact]);
      await pumpMap(tester, connector, viewState: viewState);
      await leave(tester);
      final main = viewState.mapCamera!;

      await pumpMap(
        tester,
        connector,
        viewState: viewState,
        screen: const MapScreen(
          overScreen: true,
          focus: MapFocusPoint(ll.LatLng(45, -110)),
        ),
      );
      await leave(tester);
      expect(viewState.mapCamera!.center.latitude, main.center.latitude);
    });

    // A look over a chat, even one dragged around, isn't the Map tab made
    // yours: the Map tab still goes to your position once a run.
    testWidgets('a map over a chat leaves the GPS start to the Map tab', (
      tester,
    ) async {
      final viewState = UiViewStateService();
      final connector = _FakeConnector(nodes: [contact], gps: '1');
      await pumpMap(
        tester,
        connector,
        viewState: viewState,
        screen: const MapScreen(
          overScreen: true,
          focus: MapFocusPoint(ll.LatLng(45, -110)),
        ),
      );
      await tester.drag(find.byType(AppMap), const Offset(80, 0));
      await tester.pump(const Duration(milliseconds: 200));
      await leave(tester);
      expect(viewState.mapWentToGps, isFalse);

      await pumpMap(tester, connector, viewState: viewState);
      connector.moveSelf(gps);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(camera(tester).center.latitude, closeTo(41.81, 1e-6));
    });
  });

  testWidgets('no zoom buttons on phones: they pinch', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: const [],
        self: const ll.LatLng(41.81, -71.42),
        gps: '1',
      ),
    );
    expect(find.byTooltip('Zoom in'), findsNothing);
    expect(find.byTooltip('My location'), findsOneWidget);
  });

  testWidgets(
    'zoom buttons on desktop',
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    (tester) async {
      await pumpMap(tester, _FakeConnector(nodes: const []));
      final before = camera(tester).zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(camera(tester).zoom, before + 1);
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(camera(tester).zoom, before - 1);
    },
  );

  testWidgets('the legend opens from the layers sheet, not the map', (
    tester,
  ) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [_node('Hilltop', advTypeRepeater, 1, 41.8, -71.4)],
      ),
    );
    expect(find.textContaining('Nodes:'), findsNothing);
    expect(find.byTooltip('Legend'), findsNothing, reason: 'not on the map');

    await tester.tap(find.byTooltip('Map layers'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byTooltip('Legend'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Mesh'), findsOneWidget);
    expect(find.textContaining('Nodes:'), findsOneWidget);
    expect(find.text('Repeater'), findsOneWidget, reason: 'the key shows too');
    expect(find.text('Chart symbols'), findsNothing, reason: 'not charts');
  });

  testWidgets('a path trace starts without a radio position', (tester) async {
    await pumpMap(
      tester,
      _FakeConnector(
        nodes: [_node('Hilltop', advTypeRepeater, 1, 41.8, -71.4)],
      ),
    );
    await _startPathTrace(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Path Trace'), findsOneWidget);
    expect(find.text('Tap on nodes to add them to the path.'), findsOneWidget);
  });

  testWidgets('search is a map button, not in the title bar', (tester) async {
    await pumpMap(tester, _FakeConnector(nodes: const []));
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.search),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Search'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(TextField), findsOneWidget);
  });

  group('full screen', () {
    late List<String> system;

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // The map with the system calls recorded: how the phone's bars are set.
    Future<void> showMap(WidgetTester tester, {Widget? screen}) async {
      system = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('SystemChrome.setEnabledSystemUI')) {
            system.add('${call.method.split('.').last} ${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpMap(
        tester,
        _FakeConnector(nodes: const []),
        screen: screen ?? const MapScreen(),
      );
    }

    bool full(WidgetTester tester) =>
        find.byType(AppBar).evaluate().isEmpty &&
        find.byType(QuickSwitchBar).evaluate().isEmpty;

    testWidgets('hides the title bar, the tabs and the phone\'s bars', (
      tester,
    ) async {
      await showMap(tester);
      await tester.tap(find.byTooltip('Full screen'));
      await settle(tester);
      expect(full(tester), isTrue);
      expect(system, ['setEnabledSystemUIMode SystemUiMode.immersiveSticky']);
      expect(
        find.text('To leave full screen, press Back or tap the same button.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Search'), findsOneWidget, reason: 'still there');

      // The same button, in the same place, brings everything back.
      await tester.tap(find.byTooltip('Leave full screen'));
      await settle(tester);
      expect(full(tester), isFalse);
      expect(find.byType(QuickSwitchBar), findsOneWidget);
      expect(system.last, startsWith('setEnabledSystemUIOverlays'));
      expect(system.last, contains('SystemUiOverlay.top'));
      expect(system.last, contains('SystemUiOverlay.bottom'));
    });

    testWidgets('Back leaves it before it leaves the map', (tester) async {
      await showMap(tester);
      await tester.tap(find.byTooltip('Full screen'));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(full(tester), isFalse);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsNothing);
    });

    testWidgets('Esc leaves it; F11 turns it on and off on Linux', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await showMap(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f11);
        await settle(tester);
        expect(full(tester), isTrue);
        expect(
          find.text(
            'To leave full screen, press Esc or click the same button.',
          ),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(full(tester), isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.f11);
        await settle(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f11);
        await settle(tester);
        expect(full(tester), isFalse);
        expect(system, isEmpty, reason: 'a computer has no phone bars');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('leaving the map gives the phone its bars back', (
      tester,
    ) async {
      await showMap(tester);
      await tester.tap(find.byTooltip('Full screen'));
      await settle(tester);
      await tester.pumpWidget(const SizedBox());
      expect(system.last, startsWith('setEnabledSystemUIOverlays'));
    });

    testWidgets('its buttons fade when left alone, but not the way out', (
      tester,
    ) async {
      double opacity(String tooltip) => tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: find.byTooltip(tooltip),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;

      await showMap(tester);
      await tester.tap(find.byTooltip('Full screen'));
      await settle(tester);
      expect(opacity('Search'), 1);

      await tester.pump(const Duration(seconds: 5));
      expect(opacity('Search'), MapControls.fadedOpacity);
      expect(opacity('Map layers'), MapControls.fadedOpacity);
      expect(opacity('Filter Nodes'), MapControls.fadedOpacity);
      expect(
        find.ancestor(
          of: find.byTooltip('Leave full screen'),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
        reason: 'the way out never fades',
      );

      // A touch on the map brings them back, and they fade again later.
      await tester.tapAt(tester.getCenter(find.byType(AppMap)));
      await tester.pump();
      expect(opacity('Search'), 1);
      await tester.pump(const Duration(seconds: 5));
      expect(opacity('Search'), MapControls.fadedOpacity);

      // A faded button still works.
      await tester.tap(find.byTooltip('Search'));
      await settle(tester);
      expect(find.byType(TextField), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);

      // Out of full screen they never fade.
      await tester.tap(find.byTooltip('Leave full screen'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 5));
      expect(opacity('Search'), 1);
    });

    // A map opened from a chat (Navigate, a card's Map) had none (owner,
    // 2026-11-16).
    testWidgets('a map opened from a chat has it; Back leaves it first', (
      tester,
    ) async {
      await showMap(
        tester,
        screen: const MapScreen(
          overScreen: true,
          focus: MapFocusPoint(ll.LatLng(41.8, -71.4)),
        ),
      );
      await tester.tap(find.byTooltip('Full screen'));
      await settle(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(system, ['setEnabledSystemUIMode SystemUiMode.immersiveSticky']);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(system.last, startsWith('setEnabledSystemUIOverlays'));
    });

    testWidgets('a map picking a position has none', (tester) async {
      await showMap(tester, screen: const MapScreen(pickPosition: true));
      expect(find.byTooltip('Full screen'), findsNothing);
    });
  });
}

/// Path trace, from the ⋮ menu since 2026-11-23 (Martin).
Future<void> _startPathTrace(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byIcon(Icons.radar));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
