import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/guessed_location_helper.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:path_graph/path_graph.dart'
    show PathGraph, RouteResult, FloodResult;
import 'package:meshtrax/widgets/app_bar.dart';
import 'package:meshtrax/widgets/icon_help.dart';
import 'package:meshtrax/widgets/my_location_button.dart';
import 'package:meshtrax/widgets/trax_button.dart';
import 'package:meshtrax/widgets/trax_dialogs.dart';
import 'package:meshtrax/widgets/trax_sheet.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/latlong2.dart';
import 'package:traxmap/traxmap.dart' hide LatLng, LatLngBounds;
import 'package:traxlos/traxlos.dart'
    show Verdict, defaultFrequencyMHz, destination;
import 'package:traxpoi/traxpoi.dart'
    show GeoPoint, PlaceDetail, PoiRegion, SummaryLink;
import 'package:traxroute/traxroute.dart' as trax show RouteResult;
import 'package:traxwater/traxwater.dart'
    show WaterRoutingException, WaterRoutingProblem, WaterTrip;
import 'package:traxshare/traxshare.dart' show TrailPoint;

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/app_settings.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../models/map_focus.dart';
import '../models/trax.dart';
import '../services/app_settings_service.dart';
import '../services/line_of_sight.dart';
import '../services/line_of_sight_session.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/geo_format.dart';
import '../helpers/link_handler.dart';
import '../helpers/map_places.dart';
import '../helpers/poi_kinds.dart';
import '../helpers/path_helper.dart';
import '../helpers/position_text.dart';
import '../services/map_marker_service.dart';
import '../services/map_packs_service.dart';
import '../services/poi_service.dart';
import '../services/radio_ask_service.dart';
import '../services/trax_beacon_service.dart';
import '../services/trip_positions.dart';
import '../services/trip_service.dart';
import '../services/trax_service.dart';
import '../services/routing_service.dart';
import '../services/ui_view_state_service.dart';
import '../services/water_routing_service.dart';
import '../utils/app_logger.dart';
import '../utils/contact_search.dart';
import '../utils/platform_info.dart';
import '../utils/route_transitions.dart';
import '../widgets/app_map.dart';
import '../widgets/line_of_sight_sheet.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_layers_sheet.dart';
import '../widgets/map_legend_sheet.dart';
import '../widgets/place_marker.dart';
import '../widgets/place_sheet.dart';
import '../widgets/radio_ask_sheet.dart';
import '../widgets/route_sheet.dart';
import '../widgets/speed_card.dart';
import '../widgets/water_boat_dialog.dart';
import '../widgets/water_route_parts.dart';
import '../widgets/quick_switch_bar.dart';
import 'chat_screen.dart';
import 'chats_screen.dart';
import '../widgets/path_selection_dialog.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import '../widgets/routing_dialog.dart';
import '../widgets/structured_message_card.dart';
import '../widgets/structured_message_dialogs.dart';
import 'path_graph_screen.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../helpers/trax_icons.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';
import 'map_search_screen.dart';
import 'offline_maps_screen.dart';

class MapScreen extends StatefulWidget {
  /// What the map opens on: a point, the route to one, or a trip member's
  /// card. [show] gives an open map the same.
  final MapFocus? focus;

  /// A map over another screen, opened to show [focus]: a back button and
  /// no quick-switch bar, and Back returns to that screen. It leaves the
  /// Map tab's view as it was; a route started on it is kept for the Map
  /// tab.
  final bool overScreen;

  /// Pick mode: a tap or long press pops the screen with the chosen LatLng.
  final bool pickPosition;

  /// Where picking starts, pinned.
  final LatLng? pickAround;

  const MapScreen({
    super.key,
    this.focus,
    this.overScreen = false,
    this.pickPosition = false,
    this.pickAround,
  });

  /// Shows [focus] where you are, never on a map over another map: in place
  /// on the map you're on, from the Chats tab on the Map tab in its place,
  /// or else on a map over this screen, which Back leaves. A sheet or
  /// dialog over the screen closes first.
  static void show(BuildContext context, MapFocus focus) {
    final viewState = context.read<UiViewStateService>();
    final navigator = Navigator.of(context);
    Route<Object?>? screen;
    navigator.popUntil((route) {
      if (route is PopupRoute) return false;
      screen = route;
      return true;
    });
    final onMap = viewState.openMaps[screen];
    if (onMap != null) {
      onMap(focus);
    } else if (screen != null && screen == viewState.chatsTab) {
      navigator.pushReplacement(buildQuickSwitchRoute(MapScreen(focus: focus)));
    } else {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => MapScreen(focus: focus, overScreen: true),
        ),
      );
    }
  }

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // MapLibre zoom from which node labels show.
  static const double _labelMinZoom = 13.0;

  /// MapLibre zoom for a point the map is asked to show.
  static const double _focusZoom = 14.0;

  final _mapController = OfflineMapController();
  final MapMarkerService _markerService = MapMarkerService();
  final Set<String> _hiddenMarkerIds = {};
  Set<String> _removedMarkerIds = {};
  bool _isBuildingPathTrace = false;
  bool _hasInitializedMap = false;
  bool _removedMarkersLoaded = false;
  final List<int> _pathTrace = [];
  final List<Contact> _pathTraceContacts = [];
  final List<LatLng> _points = [];
  // Estimates for tapped guessed pins, by public key: never put on a contact,
  // where they would read as its real position.
  final Map<String, LatLng> _pathTraceGuesses = {};
  List<GuessedLocation> _cachedGuessedLocations = [];
  String _guessedLocationsCacheKey = '';
  Timer? _saveCamera;
  StreamSubscription<Object?>? _channelLatest;

  /// The trip member whose trail shows, by key prefix: the last one tapped,
  /// until another is.
  String? _trailOf;

  /// Whom the map keeps in the middle as new positions come in, until it
  /// is dragged: you after My location, or a trip member by key prefix
  /// after a tap on them (or the one the map was asked to show).
  bool _followMe = false;
  String? _followOf;

  /// Where the map last went for [_followMe] or [_followOf].
  LatLng? _followedAt;

  /// The trip member whose card is open, and how much of the map it covers.
  String? _cardOf;
  double _cardCovered = 0;

  /// Where the map opens: what it was asked to show, or where picking
  /// starts.
  late final LatLng? _openedOn = switch (widget.focus) {
    MapFocusPoint(:final position) ||
    MapFocusRoute(:final position) => position,
    MapFocusMember(:final place) => place,
    null => widget.pickAround,
  };

  /// The point the map was asked to show, pinned until another is; or
  /// where picking starts.
  late MapFocusPoint? _pin = switch ((widget.focus, widget.pickAround)) {
    (final focus?, _) => _pinOf(focus),
    (null, final around?) => MapFocusPoint(around),
    (null, null) => null,
  };

  /// This map's route, in [UiViewStateService.openMaps] while it is open.
  ModalRoute<Object?>? _pageRoute;

  /// The route this map last kept in [UiViewStateService.mapRoute], or took
  /// from it. Another there since was kept by a map over a chat.
  MapRoute<trax.RouteResult>? _keptRoute;

  /// The Map tab opened on a route started over a chat: shown whole.
  bool _routeUnseen = false;

  /// The main map without the title bar and the tabs, and on a phone without
  /// its status and navigation bars. Never saved: the app starts without it.
  bool _fullScreen = false;

  /// In full screen the map's buttons fade after a few seconds untouched.
  bool _controlsFaded = false;
  Timer? _fadeTimer;

  // Offline routing: where to and from (null: your position), and the route
  // found.
  ({String name, LatLng point})? _routeTo;
  LatLng? _routeFrom;
  trax.RouteResult? _route;

  /// Where the route was found from, and when: a route from your position
  /// stays from there as you move.
  LatLng? _routeFoundFrom;
  DateTime? _routeFoundAt;
  bool _routing = false;
  String? _routeError;
  int _routeGeneration = 0;
  final _sheetKey = GlobalKey<RouteSheetState>();

  /// The trip on the water: charts show it in the route's place, and the
  /// other maps the route on land. Each keeps its own, and switching maps
  /// swaps them (owner, 2026-11-24).
  final _water = _WaterRoute();
  final _waterSheetKey = GlobalKey<RouteSheetState>();

  /// Whether the map last built showed charts, and the land map shown
  /// last: a route on land from the charts goes there.
  bool? _builtOnWater;
  MapType _landMapType = MapType.osm;

  // Line of sight or radio reach: one question at a time, in a sheet that
  // takes the route sheet's place while it is open. The worker isolate
  // stays for the next question.
  LineOfSightSession? _los;
  LosWorker? _losWorker;
  final _losKey = GlobalKey<LineOfSightSheetState>();

  /// How much of the map's bottom the line of sight sheet covers: the
  /// map's credits stay above it.
  final _losCovered = ValueNotifier<double>(0);

  /// The ends (or reach) the map last moved to show.
  Object? _losShown;

  /// The reach's shade, drawn once per sweep.
  (Object?, List<MapOverlay>) _losShade = (null, const []);

  /// What the map last drew of line of sight: the map is rebuilt only
  /// when it changes, not for every step of a sweep's progress.
  Object? _losDrawn;

  /// The map's area on screen, to see how much of it a sheet covers.
  final _mapKey = GlobalKey();

  /// The point a place or position sheet is about, pinned while it's open
  /// unless something on the map is already there ([_sheetPin] false).
  LatLng? _sheetPoint;
  bool _sheetPin = true;

  // Points of interest in view, and whether the region in view has them
  // (the map then drops its own icons for the same kinds).
  List<MapPlace> _places = const [];
  Set<MapPlace> _namedPlaces = const {};
  bool _placesHere = false;
  Timer? _placesTimer;
  int _placesGeneration = 0;
  late final MeshCoreConnector _connector;
  late final UiViewStateService _viewState;

  /// Back on the main map in the same run: it opens where it was left.
  late final bool _keepView;

  /// Your GPS position, when the map went there as it opened.
  LatLng? _openedOnGps;

  /// The Map tab: it keeps its view and its route for the next visit, and
  /// goes to your GPS position once a run.
  bool get _isMapTab => !_overScreen;

  /// Over another screen, which Back returns to: a back button, and no
  /// quick-switch bar.
  bool get _overScreen => widget.overScreen || widget.pickPosition;

  /// Full screen on any map but one picking a position: a map opened from a
  /// chat had none (owner, 2026-11-16, after Navigate).
  bool get _canFullScreen => !widget.pickPosition;

  /// Charts show the trip on the water, the other maps the route on land.
  bool get _onWater =>
      MapType.parse(context.read<AppSettingsService>().settings.mapType) ==
      MapType.charts;

  /// Where the route shown goes, on land or on the water.
  ({String name, LatLng point})? get _shownTo =>
      _onWater ? _water.to : _routeTo;
  bool get _shownFound => _onWater ? _water.trip != null : _route != null;
  bool get _shownFinding => _onWater ? _water.finding : _routing;
  GlobalKey<RouteSheetState> get _shownSheetKey =>
      _onWater ? _waterSheetKey : _sheetKey;
  Future<void> _findShown(LatLng? selfPosition) =>
      _onWater ? _findWaterRoute(selfPosition) : _findRoute(selfPosition);
  void _fitShown() => _onWater ? _fitWaterRoute() : _fitRoute();
  void _clearShown() => _onWater ? _clearWaterRoute() : _clearRoute();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _loadRemovedMarkers();
    _viewState = context.read<UiViewStateService>();
    // The Map tab goes to what it was asked to show, not to your GPS
    // position or where it was left.
    if (widget.focus != null && _isMapTab) _viewState.mapWentToGps = true;
    _keepView =
        widget.focus == null &&
        _isMapTab &&
        _viewState.mapShownThisRun &&
        _viewState.mapCamera != null;
    // A map over a chat starts with just what it was opened for.
    final kept = _keptRoute = _isMapTab ? _viewState.mapRoute : null;
    if (kept != null) {
      _routeUnseen = !_viewState.mapRouteSeen;
      _viewState.mapRouteSeen = true;
      _routeTo = (name: kept.name, point: kept.to.toLatLong2());
      _routeFrom = kept.from?.toLatLong2();
      _route = kept.result;
      _routeFoundFrom = kept.foundFrom?.toLatLong2();
      _routeFoundAt = kept.foundAt;
    }
    final keptWater = _water.kept = _isMapTab ? _viewState.mapWaterRoute : null;
    if (keptWater != null) {
      _water.unseen = !_viewState.mapWaterRouteSeen;
      _viewState.mapWaterRouteSeen = true;
      _water.take(keptWater);
    }
    final connector = _connector = context.read<MeshCoreConnector>();
    // A new channel message may carry a pin.
    _channelLatest = connector.watchChannelLatest().listen((_) {
      if (mounted) unawaited(_refreshChannelMarkers(connector));
    });
    // A radio with GPS moves with its owner: "You" follows it every 10 s.
    connector.addSelfPositionViewer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) connector.getChannels();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pickPosition) return;
    // What you tap on this map shows on it (MapScreen.show).
    if (_pageRoute == null) {
      final route = _pageRoute = ModalRoute.of(context);
      if (route != null) _viewState.openMaps[route] = _show;
    }
    // Back on the Map tab: a route started on a map over a chat since.
    if (_isMapTab &&
        (ModalRoute.isCurrentOf(context) ?? false) &&
        !identical(_viewState.mapRoute, _keptRoute)) {
      _takeKeptRoute();
    }
    if (_isMapTab &&
        (ModalRoute.isCurrentOf(context) ?? false) &&
        !identical(_viewState.mapWaterRoute, _water.kept)) {
      _takeKeptWaterRoute();
    }
  }

  /// Takes the route a map over a chat kept, and shows it whole.
  void _takeKeptRoute() {
    final kept = _keptRoute = _viewState.mapRoute;
    _viewState.mapRouteSeen = true;
    // A route of this map's still being found is dropped.
    _routeGeneration++;
    _routeTo = kept == null
        ? null
        : (name: kept.name, point: kept.to.toLatLong2());
    _routeFrom = kept?.from?.toLatLong2();
    _route = kept?.result;
    _routeFoundFrom = kept?.foundFrom?.toLatLong2();
    _routeFoundAt = kept?.foundAt;
    _routing = false;
    _routeError = null;
    if (kept == null) return;
    _followMe = false;
    _followOf = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_los != null) _closeLos();
      // Charts show the trip on the water: the route waits for a land map.
      if (_onWater) return;
      if (_route != null) return _fitRoute();
      final connector = _connector;
      unawaited(
        _findRoute(
          connector.hasValidLocation(
                connector.selfLatitude,
                connector.selfLongitude,
              )
              ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
              : null,
        ),
      );
    });
  }

  /// Takes the trip on the water a map over a chat kept, as
  /// [_takeKeptRoute] takes a route; it waits for the charts.
  void _takeKeptWaterRoute() {
    final kept = _water.kept = _viewState.mapWaterRoute;
    _viewState.mapWaterRouteSeen = true;
    _water.take(kept);
    if (kept == null) return;
    _followMe = false;
    _followOf = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_los != null) _closeLos();
      if (!_onWater) return;
      if (_water.trip != null) return _fitWaterRoute();
      unawaited(_findWaterRoute(_selfPosition(_connector)));
    });
  }

  /// The pin [focus] puts on the map: its point, or the route's end.
  static MapFocusPoint? _pinOf(MapFocus focus) => switch (focus) {
    final MapFocusPoint point => point,
    MapFocusRoute(:final position, :final label) => MapFocusPoint(
      position,
      label: label,
    ),
    MapFocusMember() => null,
  };

  /// Shows [focus] as this map shows such things itself: the point pinned,
  /// the route to it as Route here finds it, or the member's card as their
  /// pin opens it. Line of sight closes, and the map follows no one else.
  void _show(MapFocus focus) {
    if (_isMapTab) _viewState.mapWentToGps = true;
    if (_los != null) _closeLos();
    setState(() {
      _pin = _pinOf(focus);
      _followMe = false;
      _followOf = null;
    });
    switch (focus) {
      case MapFocusPoint(:final position):
        unawaited(_moveTo(position, _focusZoom));
      case MapFocusRoute(:final position, :final label):
        // From your position, not a start picked for the route before.
        if (_onWater) {
          _water.from = null;
        } else {
          _routeFrom = null;
        }
        _mapController.move(position.toOvm(), zoom: _focusZoom);
        final connector = _connector;
        _routeHere(
          label ??
              positionLines(
                position.latitude,
                position.longitude,
                coordFormatOf(context.read<AppSettingsService>().settings),
              ).first,
          position,
          connector.hasValidLocation(
                connector.selfLatitude,
                connector.selfLongitude,
              )
              ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
              : null,
        );
      case MapFocusMember(:final prefix, :final place):
        final member = _members(
          context.read<TripPositions?>(),
          context.read<TripService?>(),
          context.read<TraxService?>()?.isOn ?? false,
          _connector,
        ).where((m) => m.prefix == prefix).firstOrNull;
        if (member != null &&
            _person(context, member.contact, member.report).place != null) {
          unawaited(_showMemberCard(member, zoom: _focusZoom));
          return;
        }
        // Not one of the map's group: their trail, followed.
        setState(() {
          _trailOf = prefix;
          _followOf = prefix;
          _followedAt = place;
        });
        unawaited(_moveTo(place, _focusZoom));
    }
  }

  @override
  void dispose() {
    _viewState.openMaps.remove(_pageRoute);
    if (_saveCamera?.isActive ?? false) {
      _saveCamera!.cancel();
      _viewState.setMapCamera(_viewState.mapCamera!);
    }
    _placesTimer?.cancel();
    _connector.removeSelfPositionViewer();
    unawaited(_channelLatest?.cancel());
    _mapController.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _fadeTimer?.cancel();
    if (_fullScreen && _phone) unawaited(_showSystemBars());
    _los?.dispose();
    _losWorker?.dispose();
    _losCovered.dispose();
    super.dispose();
  }

  static bool get _phone =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// The phone's status and navigation bars as they are by default.
  static Future<void> _showSystemBars() => SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  /// Full screen on or off. On the way in, a hint says how to get out: the
  /// same button, or Back on Android and Esc on a computer.
  void _setFullScreen(bool on) {
    if (on == _fullScreen) return;
    _fadeTimer?.cancel();
    setState(() {
      _fullScreen = on;
      _controlsFaded = false;
    });
    _wakeControls();
    if (_phone) {
      unawaited(
        on
            ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
            : _showSystemBars(),
      );
    }
    if (!on) return;
    final l10n = context.l10n;
    showDismissibleSnackBar(
      context,
      duration: const Duration(seconds: 3),
      content: Text(switch (defaultTargetPlatform) {
        TargetPlatform.android => l10n.map_fullScreenHintBack,
        TargetPlatform.iOS => l10n.map_fullScreenHintTap,
        _ => l10n.map_fullScreenHintKey,
      }),
    );
  }

  void _touched() {
    if (_isMapTab) _viewState.mapWentToGps = true;
    _wakeControls();
  }

  /// In full screen, any touch on the map or its buttons (or a mouse moving
  /// over them) brings the buttons back, and they fade again a few seconds
  /// later. The full-screen button itself never fades: it's the way out.
  void _wakeControls() {
    if (!_fullScreen) return;
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _fullScreen) setState(() => _controlsFaded = true);
    });
    if (_controlsFaded) setState(() => _controlsFaded = false);
  }

  /// Esc leaves full screen; F11 turns it on and off on Windows and Linux,
  /// as it does in their browsers. Only while the map itself is in front.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !_canFullScreen) return false;
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape && _fullScreen) {
      _setFullScreen(false);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.f11 &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      _setFullScreen(!_fullScreen);
      return true;
    }
    return false;
  }

  /// My location: the radio's GPS position, kept in the middle as it moves
  /// until the map is dragged. With the GPS off, offers to turn it on, since
  /// a first fix can take minutes.
  Future<void> _myLocation(
    MeshCoreConnector connector,
    LatLng? selfPosition,
  ) async {
    final l10n = context.l10n;
    if (!connector.gpsOn) {
      final turnOn = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.gps_turnOnTitle),
          content: Text(l10n.gps_turnOnBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.gps_notNow),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.gps_turnOn),
            ),
          ],
        ),
      );
      if (turnOn == true) await connector.setGps(true);
      return;
    }
    if (selfPosition == null) {
      showDismissibleSnackBar(context, content: Text(l10n.gps_noPosition));
      return;
    }
    MapControls.centerOn(_mapController, selfPosition.toOvm());
    setState(() {
      _followMe = true;
      _followOf = null;
      _followedAt = selfPosition;
    });
  }

  /// Where the trip member [prefix] is, as their card says: from their
  /// TRAX report, or a contact's answer or advert before one comes.
  LatLng? _memberPlace(
    TripPositions? trip,
    MeshCoreConnector connector,
    String prefix,
  ) {
    final report = trip?.all.where((p) => p.prefix == prefix).firstOrNull;
    final contact = report != null
        ? connector.contactByKeyPrefix4(report.prefixBytes)
        : connector.allContacts
              .where((c) => c.publicKeyHex.startsWith(prefix))
              .firstOrNull;
    if (report == null && contact == null) return null;
    return _person(context, contact, report).place;
  }

  /// Puts [at] in the middle of the map, or of what the open card of the
  /// member followed leaves, at the zoom the map has.
  void _followTo(LatLng at) {
    final zoom = _mapController.camera?.zoom;
    if (zoom == null) return;
    _mapController.fitPoints(
      [at.toOvm()],
      padding: EdgeInsets.only(bottom: _cardOf == null ? 0 : _cardCovered),
      maxZoom: zoom,
    );
  }

  /// A drag of the map ends following; a zoom doesn't.
  void _stopFollowing() {
    if (!_followMe && _followOf == null) return;
    setState(() {
      _followMe = false;
      _followOf = null;
    });
  }

  void _onCameraChanged(MapCamera camera) {
    _saveCamera?.cancel();
    // Only the Map tab's view is kept, at once for the next map of the run
    // (a quick switch back starts it before this one is gone), and on the
    // device after a pause. A map over another screen leaves it as it was.
    if (_isMapTab) {
      _viewState.setMapCamera(camera, save: false);
      _saveCamera = Timer(
        const Duration(seconds: 1),
        () => _viewState.setMapCamera(camera),
      );
    }
    _placesTimer?.cancel();
    _placesTimer = Timer(
      const Duration(milliseconds: 300),
      () => _loadPlaces(camera),
    );
  }

  Future<void> _loadPlaces(MapCamera camera) async {
    final poi = context.read<PoiService?>();
    final bounds = _mapController.visibleBounds;
    final generation = ++_placesGeneration;
    if (poi == null || bounds == null || camera.zoom < 12) {
      if (_places.isNotEmpty) setState(() => _places = const []);
      return;
    }
    final region = context
        .read<MapPacksService>()
        .regions
        ?.regionAt(camera.center)
        ?.path;
    final here = region != null && poi.isInstalled(region, PoiDownload.points);
    final found = await placesIn(poi.regions, bounds);
    if (!mounted || generation != _placesGeneration) return;
    setState(() {
      _places = placesToShow(found, camera);
      _namedPlaces = placesToName(_places, camera);
      _placesHere = here;
    });
  }

  Future<void> _loadRemovedMarkers() async {
    final ids = await _markerService.loadRemovedIds();
    if (!mounted) return;
    setState(() {
      _removedMarkerIds = ids;
      _removedMarkersLoaded = true;
    });
  }

  double _standardDeviation(List<double> values) {
    if (values.length <= 1) {
      return 0.0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;

    double sumSquaredDiff = 0.0;
    for (final value in values) {
      final diff = value - mean;
      sumSquaredDiff += diff * diff;
    }

    // Sample standard deviation (n-1) — most appropriate here
    final variance = sumSquaredDiff / (values.length - 1);

    return sqrt(variance);
  }

  // Calculate zoom level based on the spread of points (std deviation in degrees)
  double _zoomFromStdDev(double latStdDev, double lonStdDev) {
    final maxSpread = max(latStdDev, lonStdDev);
    if (maxSpread <= 0) return 13.0;
    // Approximate: each zoom level halves the visible area
    // ~0.01 degrees spread -> zoom 13, ~0.1 -> zoom 10, ~1.0 -> zoom 7
    final zoom = 10.0 - log(maxSpread * 10 + 1) / ln10 * 3;
    return zoom.clamp(4.0, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final radioAsks = context.watch<RadioAskService?>();
    final tripPositions = context.watch<TripPositions?>();
    final beacon = context.watch<TraxBeaconService?>();
    final traxOn = context.watch<TraxService?>()?.isOn ?? false;
    final tripService = context.watch<TripService?>();
    return Consumer2<MeshCoreConnector, AppSettingsService>(
      builder: (context, connector, settingsService, child) {
        final settings = settingsService.settings;
        final allContacts = connector.allContacts;

        final contacts = settings.mapShowDiscoveryContacts
            ? allContacts
            : allContacts.where((c) => c.isActive).toList();

        final pin = _pin;
        _refreshDirectMarkersIfChanged(connector);
        // An SOS shows whatever the marker filter says, until removed.
        final sharedMarkers = _channelMarkers
            .where(
              (marker) =>
                  (settings.mapShowMarkers || marker.isSos) &&
                  !_hiddenMarkerIds.contains(marker.id) &&
                  !_removedMarkerIds.contains(marker.id),
            )
            .toList();

        // Filter by time
        final now = DateTime.now();
        final filteredByTime = settings.mapTimeFilterHours == 0
            ? contacts
            : contacts.where((c) {
                final hoursSinceLastSeen = now.difference(c.lastSeen).inHours;
                return hoursSinceLastSeen <= settings.mapTimeFilterHours;
              }).toList();

        // Filter by key prefix
        final keyPrefix = settings.mapKeyPrefix.trim();
        final filteredByKeyPrefix =
            (settings.mapKeyPrefixEnabled && keyPrefix.isNotEmpty)
            ? filteredByTime.where((c) {
                return c.publicKeyHex.toLowerCase().startsWith(
                  keyPrefix.toLowerCase(),
                );
              }).toList()
            : filteredByTime;

        // Filter by location
        final contactsWithLocation = filteredByKeyPrefix.where((c) {
          return c.hasLocation;
        }).toList();

        // All contacts with a known location — used as anchors regardless of
        // time/key-prefix filters so that repeaters are always available.
        final allContactsWithLocation = allContacts
            .where((c) => c.hasLocation)
            .toList();

        // Compute guessed locations with caching
        final maxRangeKm = GuessedLocationHelper.estimateRangeKm(
          freqKHz: connector.currentFreqHz,
          bwHz: connector.currentBwHz,
          sf: connector.currentSf,
          txPowerDbm: connector.currentTxPower,
        );
        final guessStaleBefore = now.subtract(GuessedLocationHelper.staleAfter);
        final cacheKey =
            '${GuessedLocationHelper.cacheKey(targets: filteredByKeyPrefix, located: allContactsWithLocation, maxRangeKm: maxRangeKm, staleBefore: guessStaleBefore, routeWrittenByApp: connector.wroteContactPath)}|${settings.mapShowGuessedLocations}';
        if (cacheKey != _guessedLocationsCacheKey) {
          _guessedLocationsCacheKey = cacheKey;
          _cachedGuessedLocations = settings.mapShowGuessedLocations
              ? GuessedLocationHelper.compute(
                  targets: filteredByKeyPrefix,
                  located: allContactsWithLocation,
                  maxRangeKm: maxRangeKm,
                  staleBefore: guessStaleBefore,
                  routeWrittenByApp: connector.wroteContactPath,
                )
              : [];
        }
        final guessedLocations = _drawnGuesses(
          GuessedLocationHelper.withCurrentContacts(
            _cachedGuessedLocations,
            filteredByKeyPrefix,
          ),
          settings,
          connector.pathHashByteWidth,
        );

        // A TRAX group member has one pin, theirs: no node, answer or guess.
        final members = _members(tripPositions, tripService, traxOn, connector);
        final memberKeys = {for (final m in members) ?m.contact?.publicKeyHex};

        // Calculate center and zoom of all nodes (flutter_map zooms; the map
        // takes MapLibre zooms, one lower).
        LatLng center = const LatLng(0, 0);
        double initialZoom = 10.0;
        final hasRealPositions =
            contactsWithLocation.isNotEmpty || sharedMarkers.isNotEmpty;
        final hasMapContent =
            hasRealPositions ||
            guessedLocations.isNotEmpty ||
            _openedOn != null;
        if (hasRealPositions || guessedLocations.isNotEmpty) {
          final allPoints = [
            ...contactsWithLocation.map(
              (c) => LatLng(c.latitude!, c.longitude!),
            ),
            ...sharedMarkers.map((m) => m.position),
            // A guess can be tens of km out: it frames the map only when
            // nothing else can.
            if (!hasRealPositions) ...guessedLocations.map((g) => g.position),
          ];
          if (allPoints.length >= 3) {
            final latValues = allPoints.map((p) => p.latitude).toList();
            final lonValues = allPoints.map((p) => p.longitude).toList();

            final meanLat =
                latValues.reduce((a, b) => a + b) / latValues.length;
            final meanLon =
                lonValues.reduce((a, b) => a + b) / lonValues.length;
            final latStdDev = _standardDeviation(latValues);
            final lonStdDev = _standardDeviation(lonValues);

            final filteredPoints = allPoints
                .where(
                  (p) =>
                      (p.latitude - meanLat).abs() <= latStdDev * 2 &&
                      (p.longitude - meanLon).abs() <= lonStdDev * 2,
                )
                .toList();

            if (filteredPoints.isNotEmpty) {
              final filteredLatValues = filteredPoints
                  .map((p) => p.latitude)
                  .toList();
              final filteredLonValues = filteredPoints
                  .map((p) => p.longitude)
                  .toList();
              final avgLat = filteredLatValues.reduce((a, b) => a + b);
              final avgLon = filteredLonValues.reduce((a, b) => a + b);
              center = LatLng(
                avgLat / filteredPoints.length,
                avgLon / filteredPoints.length,
              );
              // Use std deviation of filtered points for zoom
              final filteredLatStdDev = _standardDeviation(filteredLatValues);
              final filteredLonStdDev = _standardDeviation(filteredLonValues);
              initialZoom = _zoomFromStdDev(
                filteredLatStdDev,
                filteredLonStdDev,
              );
            } else {
              center = LatLng(meanLat, meanLon);
              initialZoom = _zoomFromStdDev(latStdDev, lonStdDev);
            }
          } else {
            double avgLat = 0.0;
            double avgLon = 0.0;
            for (final point in allPoints) {
              avgLat += point.latitude;
              avgLon += point.longitude;
            }
            center = LatLng(
              avgLat / allPoints.length,
              avgLon / allPoints.length,
            );
            initialZoom = 12.0;
          }
        }
        var zoom = MapCamera.fromFlutterMapZoom(initialZoom);
        if (_openedOn case final opened?) {
          center = opened;
          zoom = _focusZoom;
        }

        // A radio with no position reports 0, 0.
        final selfPosition =
            connector.hasValidLocation(
              connector.selfLatitude,
              connector.selfLongitude,
            )
            ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
            : null;

        // Switching between the charts and the other maps swaps the route
        // shown: one not found yet is found now.
        final mapType = MapType.parse(settings.mapType) ?? MapType.osm;
        final onWater = mapType == MapType.charts;
        if (!onWater) _landMapType = mapType;
        if (_builtOnWater != null && _builtOnWater != onWater) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _shownTo != null && !_shownFound && !_shownFinding) {
              unawaited(_findShown(selfPosition));
            }
          });
        }
        _builtOnWater = onWater;

        // Once a run the Map tab goes to your position, as soon as the
        // radio's GPS has one, unless you've touched the map first. A map
        // still loading opens there.
        if (_isMapTab &&
            !_viewState.mapWentToGps &&
            connector.gpsOn &&
            selfPosition != null) {
          _viewState.mapWentToGps = true;
          if (_mapController.isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                MapControls.centerOn(_mapController, selfPosition.toOvm());
              }
            });
          } else {
            _openedOnGps = selfPosition;
          }
        }
        // The map keeps whom it follows in the middle. A sheet about
        // something else holds it; once that closes, the map goes back.
        final held = _los != null || (_sheetPoint != null && _cardOf == null);
        final followAt = _followMe
            ? selfPosition
            : switch (_followOf) {
                final prefix? => _memberPlace(tripPositions, connector, prefix),
                null => null,
              };
        if (followAt != null) {
          if (held) {
            _followedAt = null;
          } else if (followAt != _followedAt) {
            _followedAt = followAt;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _followTo(followAt);
            });
          }
        }
        final lastCamera = _viewState.mapCamera;
        final startCamera = switch (_openedOnGps) {
          // As close as My location goes: where nothing is downloaded, as
          // close as the base map's detail.
          final gps? => MapCamera(
            center: gps.toOvm(),
            zoom:
                context.read<MapPacksService?>()?.downloadedAt(
                      MapType.parse(settings.mapType) ?? MapType.osm,
                      gps.toOvm(),
                    ) ??
                    false
                ? MapControls.locateZoom
                : AppMap.baseMapZoom,
          ),
          null when _keepView => lastCamera!,
          null when hasMapContent || lastCamera == null => MapCamera(
            center: center.toOvm(),
            zoom: zoom,
          ),
          null => lastCamera!,
        };

        // Re center map after removed markers have loaded
        if (!_hasInitializedMap && _removedMarkersLoaded) {
          _hasInitializedMap = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (widget.focus case final focus?) {
              // What it was asked to show. A route kept from the last visit
              // stays, found again if it wasn't.
              if (_shownTo != null && !_shownFound && focus is! MapFocusRoute) {
                unawaited(_findShown(selfPosition));
              }
              _show(focus);
            } else if (_shownTo != null) {
              // A route kept from the last visit: the map stays as it was
              // left, and the route is found again if it wasn't. One
              // started over a chat is shown whole.
              if (!_shownFound) {
                unawaited(_findShown(selfPosition));
              } else if (!_keepView ||
                  (onWater ? _water.unseen : _routeUnseen)) {
                _fitShown();
              }
            } else if (_isMapTab && (_keepView || _viewState.mapWentToGps)) {
              // Where it was left, or on your position.
            } else if (hasMapContent) {
              _mapController.move(center.toOvm(), zoom: zoom);
            } else if (lastCamera == null) {
              _showLatestDownloadedMap();
            }
          });
        }

        // A map over another screen (showing something, or a picker) goes
        // back where it came from.
        final allowBack = !connector.isConnected || _overScreen;
        final mapDark = settings.mapTheme == 'dark';
        final showPlaces =
            settings.mapPlaces && !widget.pickPosition && !_isBuildingPathTrace;

        // A wide screen has the route at the side of the map, not over it.
        final screen = MediaQuery.sizeOf(context);
        final routeAtSide = screen.width >= 600 && screen.width > screen.height;
        final sideSheet = routeAtSide && (_los != null || _shownTo != null);
        final groupButton =
            traxOn &&
            _los == null &&
            !_isBuildingPathTrace &&
            !widget.pickPosition;
        // Your speed, heading and altitude while the map keeps you in the
        // middle, gone while the GPS reading may be old (Martin).
        final showSpeed =
            _followMe &&
            connector.gpsOn &&
            !connector.selfPositionMayBeOld &&
            !held;

        return PopScope(
          // Back leaves full screen and line of sight first. On the Map tab
          // it then lowers a raised route sheet, then closes the route; a
          // map over another screen goes straight back there, and its route
          // stays for the Map tab.
          canPop:
              allowBack &&
              !_fullScreen &&
              _los == null &&
              (_shownTo == null || _overScreen),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_fullScreen) return _setFullScreen(false);
            // Line of sight first: its sheet is the one showing.
            if (_los != null) {
              if (!(_losKey.currentState?.lower() ?? false)) _closeLos();
              return;
            }
            if (_shownTo == null) return;
            if (!(_shownSheetKey.currentState?.lower() ?? false)) {
              _clearShown();
            }
          },
          child: Scaffold(
            appBar: _fullScreen
                ? null
                : AppBar(
                    // The map needs no name, and the room goes to the map; picking
                    // a position still says what to do.
                    title: AppBarTitle(
                      widget.pickPosition
                          ? context.l10n.map_pickPositionHint
                          : '',
                      subtitle: false,
                    ),
                    centerTitle: true,
                    automaticallyImplyLeading: _overScreen,
                    actions: [
                      if (!widget.pickPosition) ...[
                        const TraxButton(),
                        const MyLocationButton(),
                      ],
                      PopupMenuButton(
                        style: topBarIconStyle,
                        iconSize: topBarIconSize,
                        itemBuilder: (context) => [
                          if (context.read<TraxService?>() case final mode?
                              when !widget.pickPosition &&
                                  connector.isConnected)
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  TraxIcon(
                                    size: 24,
                                    color: mode.isOn
                                        ? const Color(Trax.orange)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(context.l10n.trax_title),
                                  ),
                                ],
                              ),
                              onTap: () => showTraxSheet(context),
                            ),
                          // The map's tools first: the reach from you,
                          // where a tap on the map or a name gives the line
                          // to it, and a path trace, in the menu since
                          // 2026-11-23 (Martin).
                          if (_losOffered || !_isBuildingPathTrace) ...<
                            PopupMenuEntry<Object?>
                          >[
                            if (_losOffered)
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility_outlined),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(context.l10n.los_lineOfSight),
                                    ),
                                  ],
                                ),
                                onTap: () => _openLos(
                                  LosMode.reach,
                                  from: _me(connector, selfPosition),
                                ),
                              ),
                            if (!_isBuildingPathTrace)
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(Icons.radar),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        context.l10n.contacts_pathTrace,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _startPath(selfPosition),
                              ),
                            const PopupMenuDivider(),
                          ],
                          if (!PlatformInfo.isWeb)
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.download_for_offline_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(context.l10n.offlineMaps_title),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OfflineMapsScreen(),
                                ),
                              ),
                            ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                const Icon(Icons.logout, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(context.l10n.common_disconnect),
                              ],
                            ),
                            onTap: () => _disconnect(context, connector),
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                const Icon(Icons.settings),
                                const SizedBox(width: 8),
                                Text(context.l10n.settings_title),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline),
                                const SizedBox(width: 8),
                                Flexible(child: Text(context.l10n.iconHelp_title)),
                              ],
                            ),
                            onTap: () => showIconHelp(context),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
            // Always a row, so that the map keeps its state when a route
            // moves between the side and the bottom.
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sideSheet) ...[
                  SizedBox(
                    width: RouteSheet.sideWidth,
                    child: _los != null
                        ? _buildLosSheet(side: true)
                        : onWater
                        ? _buildWaterSheet(
                            settingsService,
                            selfPosition,
                            side: true,
                          )
                        : _buildRouteSheet(
                            settingsService,
                            selfPosition,
                            side: true,
                          ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Stack(
                    key: _mapKey,
                    children: [
                      AppMap(
                        controller: _mapController,
                        initialCamera: startCamera,
                        controlsWidth: MapControls.width,
                        leftControlsWidth: showSpeed
                            ? MapControls.speedWidth
                            : groupButton
                            ? MapControls.width
                            : 0,
                        coveredBottom: _losCovered,
                        onTap: widget.pickPosition
                            ? (position) =>
                                  Navigator.pop(context, position.toLatLong2())
                            : _los != null
                            ? (position) => _los!.tap(
                                LosPlace.point(position.toLatLong2()),
                              )
                            : null,
                        onLongPress: (position) {
                          if (widget.pickPosition) {
                            Navigator.pop(context, position.toLatLong2());
                            return;
                          }
                          _showShareMarkerAtPositionSheet(
                            context: context,
                            connector: connector,
                            position: position.toLatLong2(),
                            selfPosition: selfPosition,
                          );
                        },
                        onCameraChanged: _onCameraChanged,
                        onDrag: _stopFollowing,
                        appPlaces: showPlaces && _placesHere,
                        overlays: [
                          if (showPlaces)
                            for (final p in _places)
                              placeMarker(
                                p,
                                named: _namedPlaces.contains(p),
                                dark: mapDark,
                                onTap: () => _los != null
                                    ? _los!.tap(
                                        LosPlace.point(
                                          LatLng(p.place.lat, p.place.lon),
                                          name: p.place.name.isEmpty
                                              ? null
                                              : p.place.name,
                                        ),
                                      )
                                    : _openPlace(
                                        p,
                                        connector,
                                        selfPosition,
                                        settings.unitSystem,
                                      ),
                              ),
                          ..._trailLines(tripPositions, beacon),
                          ...onWater
                              ? _waterOverlays(darkMap: mapDark)
                              : _routeOverlays(),
                          ..._losOverlays(),
                          if (_isBuildingPathTrace && _points.length > 1)
                            MapLine(
                              id: 'path-trace',
                              points: _points.toOvm(),
                              color: Colors.blueAccent,
                              width: 4,
                            ),
                          if (pin != null)
                            MapMarker(
                              id: 'highlight',
                              position: pin.position.toOvm(),
                              size: const Size(40, 40),
                              // An SOS looks as its pin from the message
                              // does, which lies on it.
                              anchor: pin.sos
                                  ? Alignment.center
                                  : Alignment.bottomCenter,
                              interactive: pin.sos,
                              onTap: pin.sos
                                  ? () => _showSosSheet(
                                      pin.position,
                                      title:
                                          pin.label ??
                                          context.l10n.structured_sos,
                                    )
                                  : null,
                              label: pin.label,
                              child: pin.sos
                                  ? _nodeDot(
                                      Colors.red,
                                      Icons.warning_rounded,
                                      padding: 6,
                                    )
                                  : Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.red[600],
                                      size: 34,
                                    ),
                            ),
                          ..._buildGuessedMarkers([
                            for (final guess in guessedLocations)
                              if (!memberKeys.contains(
                                guess.contact.publicKeyHex,
                              ))
                                guess,
                          ]),
                          ..._buildRadioAnswerMarkers(
                            radioAsks,
                            memberKeys,
                            connector,
                          ),
                          ..._buildMarkers(
                            [
                              for (final c in contactsWithLocation)
                                if (!memberKeys.contains(c.publicKeyHex)) c,
                            ],
                            settings,
                            connector.pathHashByteWidth,
                          ),
                          // The group's people above the mesh's nodes.
                          ..._buildTripMarkers(members),
                          ...sharedMarkers.map(_buildSharedMarker),
                          // The GPS's position is a blue dot while its reading
                          // changes, then grey and "Last known"; a position
                          // typed into the radio is the "You" pin.
                          if (selfPosition != null && connector.gpsOn)
                            MapMarker(
                              id: 'self',
                              position: selfPosition.toOvm(),
                              size: const Size(24, 24),
                              interactive: false,
                              label: !connector.selfPositionMayBeOld
                                  ? null
                                  : switch (connector.selfGpsChangedAt) {
                                      final at? => context.l10n.map_lastKnownAt(
                                        DateTimeHelper.time(context, at),
                                      ),
                                      null => context.l10n.map_lastKnown,
                                    },
                              // Its time must show in full.
                              labelMaxWidth: 200,
                              child: _GpsDot(
                                old: connector.selfPositionMayBeOld,
                              ),
                            )
                          else if (selfPosition != null)
                            MapMarker(
                              id: 'self',
                              position: selfPosition.toOvm(),
                              size: const Size(40, 40),
                              interactive: false,
                              label: context.l10n.pathTrace_you,
                              labelMinZoom: _labelMinZoom,
                              child: _nodeDot(
                                Colors.teal,
                                Icons.person_pin_circle,
                              ),
                            ),
                          if (_sheetPoint case final point? when _sheetPin)
                            MapMarker(
                              id: 'sheet-pin',
                              position: point.toOvm(),
                              size: const Size(40, 40),
                              anchor: Alignment.bottomCenter,
                              interactive: false,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red[600],
                                size: 38,
                              ),
                            ),
                        ],
                      ),
                      if (!_isBuildingPathTrace && _nodesShown(settings))
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _filterButton(settingsService),
                        ),
                      if (_isBuildingPathTrace) _buildPathTraceOverlay(),
                      // A touch on the Map tab makes it yours: it no longer
                      // goes to your GPS position by itself. In full screen
                      // it also brings back the faded buttons.
                      if (!widget.pickPosition)
                        Positioned.fill(
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (_) => _touched(),
                            onPointerSignal: (_) => _touched(),
                            onPointerMove: (_) => _wakeControls(),
                            onPointerHover: (_) => _wakeControls(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            bottomSheet: routeAtSide
                ? null
                : _los != null
                ? _buildLosSheet(side: false)
                : _shownTo == null
                ? null
                : onWater
                ? _buildWaterSheet(settingsService, selfPosition, side: false)
                : _buildRouteSheet(settingsService, selfPosition, side: false),
            bottomNavigationBar: _overScreen || _fullScreen
                ? null
                : QuickSwitchBar(
                    selectedIndex: 1,
                    onDestinationSelected: (index) =>
                        _handleQuickSwitch(index, context),
                  ),
            floatingActionButtonLocation: MapControls.aboveSheet,
            floatingActionButton: MapControls(
              controller: _mapController,
              onMyLocation: connector.hasGps
                  ? () => unawaited(_myLocation(connector, selfPosition))
                  : null,
              gpsOff: !connector.gpsOn,
              following: _followMe,
              onTraxGroup: groupButton
                  ? () => unawaited(_showGroupSheet())
                  : null,
              speedCard: showSpeed
                  ? SpeedCard(
                      connector: connector,
                      units: settings.unitSystem,
                      nautical: onWater,
                      dark: mapDark,
                    )
                  : null,
              mapLeft: sideSheet ? RouteSheet.sideWidth + 1 : 0,
              onSearch: !_isBuildingPathTrace && !widget.pickPosition
                  ? () => _openSearch(
                      connector,
                      selfPosition,
                      settings.unitSystem,
                    )
                  : null,
              onFullScreen: _canFullScreen
                  ? () => _setFullScreen(!_fullScreen)
                  : null,
              fullScreen: _fullScreen,
              faded: _controlsFaded,
              onTouch: _fullScreen ? _wakeControls : null,
              onLayers: () => showMapLayersSheet(
                context,
                places: !widget.pickPosition,
                extra: _nodeLayers,
                legend: !_isBuildingPathTrace,
                legendCounts: () => _legendCounts(
                  contacts,
                  settings,
                  connector.pathHashByteWidth,
                  sharedMarkers.length,
                  guessedLocations.length,
                ),
                onMoreFilters: () =>
                    _showFilterDialog(context, settingsService),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The guesses the map draws: the same node layers as real positions, and
  /// none in the overlaps view.
  List<GuessedLocation> _drawnGuesses(
    List<GuessedLocation> guesses,
    AppSettings settings,
    int stride,
  ) {
    if (settings.mapShowOverlaps) return const [];
    final shown = _filterContactsBySettings(
      [for (final guess in guesses) guess.contact],
      settings,
      stride,
      noLocations: true,
    ).map((c) => c.publicKeyHex).toSet();
    return guesses
        .where((guess) => shown.contains(guess.contact.publicKeyHex))
        .toList();
  }

  List<MapMarker> _buildGuessedMarkers(List<GuessedLocation> guessed) => [
    for (final guess in guessed)
      MapMarker(
        id: 'guess:${guess.contact.publicKeyHex}',
        position: guess.position.toOvm(),
        size: const Size(35, 35),
        label: guess.contact.name,
        labelMinZoom: _labelMinZoom,
        onTap: () => _isBuildingPathTrace
            ? _addToPath(context, guess.contact, position: guess.position)
            : _showNodeInfo(
                context,
                guess.contact,
                guessedPosition: guess.position,
              ),
        onLongPress: () {
          if (_isBuildingPathTrace) {
            _showNodeInfo(
              context,
              guess.contact,
              guessedPosition: guess.position,
            );
          }
        },
        child: _nodeDot(
          _getNodeColor(guess.contact.type)
              .withValues(alpha: guess.highConfidence ? 0.55 : 0.30),
          Icons.not_listed_location,
        ),
      ),
  ];

  List<Contact> _filterContactsBySettings(
    List<Contact> contacts,
    dynamic settings,
    int stride, {
    bool noLocations = false,
  }) {
    List<Contact> filtered = [];

    // Precompute prefix counts for overlaps if needed to make filtering O(N)
    final prefixCounts = <String, int>{};
    if (settings.mapShowOverlaps) {
      for (final c in contacts) {
        if (c.type == advTypeRepeater || c.type == advTypeRoom) {
          final prefix = c.hashPrefixWithStride(stride);
          prefixCounts[prefix] = (prefixCounts[prefix] ?? 0) + 1;
        }
      }
    }

    bool addContact = false;
    for (final contact in contacts) {
      addContact = false;
      if (!contact.hasLocation && !noLocations) {
        continue;
      }

      // Apply node type filters
      if (contact.type == advTypeRepeater &&
          (settings.mapShowRepeaters ||
              _isBuildingPathTrace ||
              settings.mapShowOverlaps)) {
        addContact = true;
      }
      if (contact.type == advTypeChat &&
          (settings.mapShowChatNodes || _isBuildingPathTrace)) {
        addContact = true;
      }
      if (contact.type != advTypeChat &&
          contact.type != advTypeRepeater &&
          (settings.mapShowOtherNodes ||
              _isBuildingPathTrace ||
              settings.mapShowOverlaps)) {
        addContact = true;
      }

      if (contact.type == advTypeChat && _isBuildingPathTrace) {
        addContact = false;
      }

      if (settings.mapShowOverlaps) {
        bool hasOverlap = false;
        if (contact.type == advTypeRepeater || contact.type == advTypeRoom) {
          final prefix = contact.hashPrefixWithStride(stride);
          hasOverlap = (prefixCounts[prefix] ?? 0) > 1;
        }

        if (!hasOverlap && !_isBuildingPathTrace) {
          addContact = false;
        }
      }

      if (addContact) {
        filtered.add(contact);
      }
    }
    return filtered;
  }

  /// Where people's radios said they were, when asked: apart from their
  /// advert pins, with the time it said so. A TRAX group member's answer is
  /// on their own pin.
  List<MapMarker> _buildRadioAnswerMarkers(
    RadioAskService? asks,
    Set<String> memberKeys,
    MeshCoreConnector connector,
  ) {
    if (asks == null) return const [];
    return [
      for (final ask in asks.located)
        if (ask.latest case final answer?)
          if (answer.position case final p?)
            if (!memberKeys.contains(ask.contact.publicKeyHex))
              MapMarker(
                id: 'ask:${ask.contact.publicKeyHex}',
                position: LatLng(p.lat, p.lon).toOvm(),
                size: const Size(35, 35),
                label: context.l10n.radioAsk_mapLabel(
                  ask.contact.name,
                  DateTimeHelper.timeWithDay(context, answer.receivedAt),
                ),
                labelMinZoom: _labelMinZoom,
                onTap: () => _los != null
                    ? _los!.tap(
                        LosPlace.point(
                          LatLng(p.lat, p.lon),
                          name: ask.contact.name,
                        ),
                      )
                    : _showNodeInfo(
                        context,
                        connector.allContacts.firstWhere(
                          (c) => c.publicKeyHex == ask.contact.publicKeyHex,
                          orElse: () => ask.contact,
                        ),
                      ),
                child: _nodeDot(
                  _getNodeColor(advTypeChat),
                  Icons.settings_input_antenna,
                ),
              ),
    ];
  }

  /// The TRAX group as the map shows it, by the first 4 bytes of their keys:
  /// whoever sent a TRAX location the map shows and, in TRAX mode, the trip
  /// members who are contacts.
  List<_Member> _members(
    TripPositions? trip,
    TripService? group,
    bool traxOn,
    MeshCoreConnector connector,
  ) {
    final out = <String, _Member>{};
    for (final p in trip?.shown ?? const <TripPosition>[]) {
      final contact = connector.contactByKeyPrefix4(p.prefixBytes);
      out[p.prefix] = (
        prefix: p.prefix,
        name: contact?.name ?? p.name ?? p.prefix.toUpperCase(),
        contact: contact,
        report: p,
      );
    }
    if (traxOn) {
      for (final m in group?.members ?? const <TripMember>[]) {
        final contact = m.contact;
        if (contact == null || contact.publicKey.length < 4) continue;
        final prefix = pubKeyToHex(contact.publicKey.sublist(0, 4));
        out.putIfAbsent(
          prefix,
          () => (
            prefix: prefix,
            name: contact.name,
            contact: contact,
            report: null,
          ),
        );
      }
    }
    return out.values.toList();
  }

  /// One pin per TRAX group member, with their name, where they were last
  /// known to be: from their TRAX location, their radio's answer or their
  /// advert, whichever is newest. Grey when that reading may be old. A tap
  /// opens their card, a long-press their node's.
  List<MapMarker> _buildTripMarkers(List<_Member> members) => [
    for (final m in members)
      if (_person(context, m.contact, m.report) case final p
          when p.place != null)
        MapMarker(
          id: 'trip:${m.prefix}',
          position: p.place!.toOvm(),
          size: const Size(35, 35),
          label: m.name,
          labelMinZoom: _labelMinZoom,
          onTap: () => _los != null
              ? _los!.tap(LosPlace.point(p.place!, name: m.name))
              : _showMemberCard(m),
          onLongPress: switch (m.contact) {
            final contact? => () => _showNodeInfo(context, contact),
            null => null,
          },
          child: _nodeDot(
            p.old ? Colors.grey : const Color(Trax.orange),
            traxIconData(m.report?.icon),
          ),
        ),
  ];

  /// Your own TRAX track behind your dot, 10 miles of it, and the tapped
  /// trip member's trail over it.
  /// The blue dot's place while its reading is live.
  TrailPoint? _liveDot() {
    final c = _connector;
    return c.gpsOn &&
            !c.selfPositionMayBeOld &&
            c.hasValidLocation(c.selfLatitude, c.selfLongitude)
        ? (lat: c.selfLatitude!, lon: c.selfLongitude!)
        : null;
  }

  List<MapLine> _trailLines(TripPositions? trip, TraxBeaconService? beacon) {
    final of = _trailOf;
    List<MapLine> lines(String id, List<List<TrailPoint>> parts, Color color) =>
        [
          for (final (i, part) in parts.indexed)
            if (part.length >= 2)
              MapLine(
                id: 'trail:$id:$i',
                points: [for (final p in part) LatLng(p.lat, p.lon).toOvm()],
                color: color,
                width: 3,
              ),
        ];
    return [
      if (beacon != null && beacon.track.recording)
        ...lines(
          'self',
          beacon.track.lines(dot: _liveDot()),
          Colors.blue[600]!,
        ),
      if (of != null)
        ...lines('of', [
          for (final p in trip?.all ?? const <TripPosition>[])
            if (p.prefix == of) ...p.line,
        ], const Color(Trax.orange)),
    ];
  }

  List<MapMarker> _buildMarkers(
    List<Contact> contacts,
    AppSettings settings,
    int stride,
  ) {
    final overlaps = settings.mapShowOverlaps && !_isBuildingPathTrace;
    return [
      for (final contact in _filterContactsBySettings(
        contacts,
        settings,
        stride,
      ))
        MapMarker(
          id: 'node:${contact.publicKeyHex}',
          position: LatLng(contact.latitude!, contact.longitude!).toOvm(),
          size: const Size(35, 35),
          label: overlaps
              ? '${contact.hashPrefixWithStride(stride)}:${contact.name}'
              : contact.name,
          labelMinZoom: _labelMinZoom,
          onTap: () => _isBuildingPathTrace
              ? _addToPath(context, contact)
              : _los != null
              ? _los!.tap(_contactPlace(contact))
              : _showNodeInfo(context, contact),
          onLongPress: () {
            if (_isBuildingPathTrace) _showNodeInfo(context, contact);
          },
          child: _nodeDot(
            overlaps ? Colors.red : _getNodeColor(contact.type),
            _getNodeIcon(contact.type),
          ),
        ),
    ];
  }

  /// The round white-ringed badge every map marker uses.
  Widget _nodeDot(Color color, IconData icon, {double padding = 4}) =>
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );

  /// With nothing to show and no saved camera: the latest downloaded map.
  void _showLatestDownloadedMap() {
    final fit = context.read<MapPacksService?>()?.latestMapFit;
    if (fit != null) {
      _mapController.fitBounds(fit.bounds!, minZoom: fit.minZoom);
    }
  }

  Color _getNodeColor(int type) {
    switch (type) {
      case advTypeChat:
        return Colors.blue;
      case advTypeRepeater:
        return Colors.green;
      case advTypeRoom:
        return Colors.purple;
      case advTypeSensor:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.person;
      case advTypeRepeater:
        return Icons.router;
      case advTypeRoom:
        return Icons.meeting_room;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  /// Whether the map draws any of the layers the node filters apply to.
  static bool _nodesShown(AppSettings settings) =>
      settings.mapShowRepeaters ||
      settings.mapShowChatNodes ||
      settings.mapShowOtherNodes ||
      settings.mapShowMarkers ||
      settings.mapShowGuessedLocations;

  /// The node filters, a tap away while nodes are on the map; the layers
  /// sheet has the same button. It fades in full screen with the others.
  Widget _filterButton(AppSettingsService settingsService) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: _controlsFaded ? MapControls.fadedOpacity : 1,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.small(
        heroTag: null,
        tooltip: context.l10n.map_filterNodes,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurfaceVariant,
        onPressed: () => _showFilterDialog(context, settingsService),
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  /// What the legend's Mesh part counts: the nodes the map draws, those it
  /// can't place, pins and guesses.
  MeshLegendCounts _legendCounts(
    List<Contact> contacts,
    AppSettings settings,
    int stride,
    int markerCount,
    int guessedCount,
  ) {
    int count({required bool noLocations}) => _filterContactsBySettings(
      contacts,
      settings,
      stride,
      noLocations: noLocations,
    ).length;
    final located = count(noLocations: false);
    return (
      located: located,
      unlocated: count(noLocations: true) - located,
      pins: markerCount,
      guessed: guessedCount,
    );
  }

  /// Pins come from messages in the database. Channel messages trigger a
  /// reload through [MeshCoreConnector.watchChannelLatest]; direct ones are
  /// noticed here, by a contact's newest message time changing, so the
  /// database isn't read on every rebuild.
  void _refreshDirectMarkersIfChanged(MeshCoreConnector connector) {
    final key = Object.hashAll(connector.contacts.map((c) => c.lastMessageAt));
    if (key == _directMessagesKey) return;
    _directMessagesKey = key;
    unawaited(_refreshChannelMarkers(connector));
  }

  int? _directMessagesKey;

  /// Returns how many candidate messages were scanned.
  Future<int> _collectContactMarkers(
    MeshCoreConnector connector,
    List<_SharedMarker> markers,
  ) async {
    final selfName = connector.selfName ?? 'Me';
    var scanned = 0;

    final contacts = connector.contacts;
    final candidates = await connector.loadPossiblePinMessages(contacts);
    for (final contact in contacts) {
      final messages = candidates[contact.publicKeyHex] ?? const [];
      scanned += messages.length;
      for (final message in messages) {
        final fromName = message.isOutgoing ? selfName : contact.name;
        final payload = _parseMarkerText(
          message.text,
          outgoing: message.isOutgoing,
          fromName: fromName,
        );
        if (payload == null) continue;
        final id = _buildMarkerId(
          sourceId: contact.publicKeyHex,
          timestamp: message.timestamp,
          text: message.text,
        );
        markers.add(
          _SharedMarker(
            id: id,
            position: payload.position,
            label: payload.label,
            flags: payload.flags,
            fromName: fromName,
            sourceLabel: contact.name,
            isChannel: false,
            isPublicChannel: false,
            sentAt: message.timestamp,
          ),
        );
      }
    }
    return scanned;
  }

  List<_SharedMarker> _channelMarkers = const [];
  bool _refreshingChannelMarkers = false;
  bool _refreshAgain = false;

  Future<void> _refreshChannelMarkers(MeshCoreConnector connector) async {
    if (_refreshingChannelMarkers) {
      _refreshAgain = true;
      return;
    }
    _refreshingChannelMarkers = true;
    try {
      final sw = Stopwatch()..start();
      final markers = <_SharedMarker>[];
      var scanned = await _collectContactMarkers(connector, markers);
      final channels = connector.channels.where((c) => !c.isEmpty).toList();
      final candidates = await connector.loadPossiblePinChannelMessages(
        channels,
      );
      for (final channel in channels) {
        final isPublic = _isPublicChannel(channel);
        final messages = candidates[channel.idKey] ?? const [];
        scanned += messages.length;
        for (final message in messages) {
          final payload = _parseMarkerText(
            message.text,
            outgoing: message.isOutgoing,
            fromName: message.senderName,
          );
          if (payload == null) continue;
          // An SOS keeps its id as its repeats move it, so a removed one
          // stays removed.
          final id = payload.flags == 'sos'
              ? 'channel:${channel.index}|sos|${message.messageId}'
              : _buildMarkerId(
                  sourceId: 'channel:${channel.index}',
                  timestamp: message.timestamp,
                  text: message.text,
                );
          markers.add(
            _SharedMarker(
              id: id,
              position: payload.position,
              label: payload.label,
              flags: payload.flags,
              fromName: message.senderName,
              sourceLabel: channel.name.isEmpty
                  ? 'Channel ${channel.index}'
                  : channel.name,
              isChannel: true,
              isPublicChannel: isPublic,
              sentAt: message.timestamp,
              updatedAt: message.sosUpdatedAt,
              cancelledAt: message.sosCancelledAt,
            ),
          );
        }
      }
      appLogger.perf('map marker scan over $scanned candidate messages', sw);
      if (!mounted) return;
      // An SOS repeat moves a marker under the same id.
      final newIds = markers.map((m) => m.signature).toSet();
      final oldIds = _channelMarkers.map((m) => m.signature).toSet();
      if (newIds.length != oldIds.length || !newIds.containsAll(oldIds)) {
        setState(() => _channelMarkers = markers);
      }
    } finally {
      _refreshingChannelMarkers = false;
    }
    if (_refreshAgain && mounted) {
      _refreshAgain = false;
      await _refreshChannelMarkers(connector);
    }
  }

  /// Location and SOS messages become shared markers. Events and notices
  /// carry no pin of their own. A sender's own position is named as the
  /// chat card names it: "My location" or "{fromName}'s location".
  _MarkerPayload? _parseMarkerText(
    String text, {
    required bool outgoing,
    required String fromName,
  }) {
    final parsed = StructuredMessage.parse(text);
    final (LatLng position, String label, String flags) = switch (parsed) {
      LocationMessage m when m.isSendersOwn => (
        m.position,
        StructuredMessageCard.locationTitle(
          context.l10n,
          m,
          isOutgoing: outgoing,
          senderName: fromName,
        ),
        'poi',
      ),
      LocationMessage m => (m.position, m.label ?? '', 'poi'),
      SosMessage m => (
        m.position,
        m.text.isEmpty ? context.l10n.structured_sos : m.text,
        'sos',
      ),
      _ => (const LatLng(0, 0), '', ''),
    };
    if (flags.isEmpty) return null;
    return _MarkerPayload(
      position: position,
      label: label.isEmpty ? context.l10n.map_sharedPin : label,
      flags: flags,
    );
  }

  String _buildMarkerId({
    required String sourceId,
    required DateTime timestamp,
    required String text,
  }) {
    return '$sourceId|${timestamp.millisecondsSinceEpoch}|$text';
  }

  MapMarker _buildSharedMarker(_SharedMarker marker) => MapMarker(
    id: 'pin:${marker.id}',
    position: marker.position.toOvm(),
    size: const Size(40, 40),
    onTap: () => _los != null
        ? _los!.tap(LosPlace.point(marker.position, name: marker.label))
        : marker.isSos
        ? _showSosSheet(marker.position, title: marker.label, marker: marker)
        : _showMarkerInfo(marker),
    child: _nodeDot(
      marker.isSos
          ? (marker.cancelledAt != null ? Colors.grey : Colors.red)
          : marker.isChannel
          ? (marker.isPublicChannel ? Colors.orange : Colors.purple)
          : Colors.blue,
      marker.isSos ? Icons.warning_rounded : Icons.flag,
      padding: 6,
    ),
  );

  /// An SOS pin: Route here with MeshTrax's own offline routing first,
  /// then Navigate in another app, which may have no maps out there.
  /// [marker]: the pin from a message, which says who sent it and when,
  /// and can be removed from the map.
  void _showSosSheet(
    LatLng position, {
    required String title,
    _SharedMarker? marker,
  }) {
    final l10n = context.l10n;
    final canRoute = _canRouteAt(position);
    final format = coordFormatOf(context.read<AppSettingsService>().settings);
    final lines = positionLines(position.latitude, position.longitude, format);
    final selfPosition = _selfPosition(_connector);
    String time(DateTime t) => DateTimeHelper.time(context, t);
    final details = [
      if (marker != null) '${marker.fromName} · ${marker.sourceLabel}',
      if (marker?.cancelledAt case final at?)
        l10n.sos_cancelledAt(time(at))
      else if (marker?.updatedAt case final at?)
        l10n.sos_updated(time(at))
      else if (marker?.sentAt case final at?)
        l10n.sos_sentAt(time(at)),
      ...lines,
    ];
    _showPointSheet(
      position,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.warning_rounded,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                subtitle: Text(details.join('\n')),
                trailing: CopyPositionButton(text: lines.first),
              ),
              ListTile(
                leading: const Icon(Icons.directions),
                title: Text(l10n.route_here),
                subtitle: canRoute ? null : Text(l10n.navigate_noRoutingHere),
                enabled: canRoute,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _routeHere(title, position, selfPosition);
                },
              ),
              ListTile(
                leading: const Icon(Icons.near_me_outlined),
                title: Text(l10n.structured_navigate),
                subtitle: Text(l10n.route_otherApp),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(
                    LinkHandler.openInMapsApp(context, position, label: title),
                  );
                },
              ),
              if (marker != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.common_remove),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _hiddenMarkerIds.add(marker.id);
                      _removedMarkerIds.add(marker.id);
                    });
                    await _markerService.saveRemovedIds(_removedMarkerIds);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.common_close),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepeaterLogin(BuildContext context, Contact repeater) {
    showDialog(
      context: context,
      builder: (context) => RepeaterLoginDialog(
        repeater: repeater,
        onLogin: (password, isAdmin) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepeaterHubScreen(
                repeater: repeater,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoomLogin(BuildContext context, Contact room) {
    showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: room,
        // onLogin(password, isAdmin) isAdmin not used for room caht screen
        onLogin: (password, _) {
          // Navigate to chat screen after successful login
          context.read<MeshCoreConnector>().markContactRead(room.publicKeyHex);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(contact: room)),
          );
        },
      ),
    );
  }

  void _showNodeInfo(
    BuildContext context,
    Contact contact, {
    LatLng? guessedPosition,
  }) {
    final connector = context.read<MeshCoreConnector>();
    final pathGraph = context.read<PathGraphService>();
    final graph = pathGraph.isRunning ? pathGraph.graph : null;
    final amber = RoutingIcon.pathfinderColor(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNodeIcon(contact.type),
              color: _getNodeColor(contact.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: SelectableText(contact.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.type == advTypeChat)
                ..._personRows(context, contact, guessedPosition)
              else ...[
                _buildInfoRow('Type', contact.typeLabel),
                _buildInfoRow('Path', contact.pathLabel),
                if (contact.hasLocation)
                  _buildInfoRow(
                    'Location',
                    '${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}',
                  )
                else if (guessedPosition != null)
                  _buildInfoRow(
                    'Est. Location',
                    '~${guessedPosition.latitude.toStringAsFixed(6)}, ${guessedPosition.longitude.toStringAsFixed(6)}',
                  ),
                _buildInfoRow(
                  context.l10n.map_lastSeen,
                  _formatLastSeen(contact.lastSeen),
                ),
              ],
              _buildInfoRow('Public Key', contact.publicKeyHex),
              if (contact.type == advTypeChat &&
                  connector.isConnected &&
                  !_isBuildingPathTrace) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_input_antenna),
                  title: Text(context.l10n.radioAsk_title(contact.name)),
                  subtitle: Text(context.l10n.radioAsk_menuSubtitle),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    RadioAskSheet.show(
                      context,
                      contact,
                      onShowOnMap: (p) => _moveTo(
                        p,
                        max(_mapController.camera?.zoom ?? 14, 14),
                      ),
                    );
                  },
                ),
              ],
              // Not from a guessed position: it can be tens of km out. A
              // person's info is about them, not the radio path (owner,
              // 2026-11-21).
              if (_losOffered &&
                  contact.type != advTypeChat &&
                  guessedPosition == null &&
                  contact.hasLocation &&
                  !_isBuildingPathTrace) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(context.l10n.los_lineOfSight),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _openLos(
                      LosMode.line,
                      from: _me(connector, _selfPosition(connector)),
                      to: _contactPlace(contact),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text(context.l10n.los_reachFrom(contact.name)),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _openLos(LosMode.reach, from: _contactPlace(contact));
                  },
                ),
              ],
              if (graph != null) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(RoutingIcon.icon, color: amber),
                  title: Text(context.l10n.routing_pathfinder),
                  subtitle: Text(context.l10n.routing_pathfinderSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PathGraphScreen(
                          initialTargetKey: contact.publicKeyHex,
                        ),
                      ),
                    );
                  },
                ),
                if (contact.type == advTypeRepeater &&
                    graph.findPathToRepeater(_graphHash(graph, contact))
                        is RouteResult)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(RoutingIcon.icon, color: amber),
                    title: Text(context.l10n.map_pathfinderTrace),
                    subtitle: Text(context.l10n.map_pathfinderTraceSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _routeAndTrace(
                        context,
                        contact,
                        contact,
                        guesses: {contact.publicKeyHex: ?guessedPosition},
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
          if (contact.type ==
              advTypeChat) // Only show chat button for chat nodes
            TextButton(
              onPressed: () async {
                if (!contact.isActive &&
                    !await connector.importDiscoveredContact(contact)) {
                  if (context.mounted) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.contacts_contactImportFailed),
                    );
                  }
                  return;
                }
                if (!dialogContext.mounted || !context.mounted) return;
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(contact: contact),
                  ),
                );
              },
              child: Text(context.l10n.contacts_openChat),
            ),
          if (contact.type == advTypeRepeater)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showRepeaterLogin(context, contact);
              },
              child: Text(context.l10n.map_manageRepeater),
            ),
          if (contact.type == advTypeRoom)
            TextButton(
              onPressed: () async {
                if (!contact.isActive &&
                    !await connector.importDiscoveredContact(contact)) {
                  if (context.mounted) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.contacts_contactImportFailed),
                    );
                  }
                  return;
                }
                if (!dialogContext.mounted || !context.mounted) return;
                Navigator.pop(dialogContext);
                _showRoomLogin(context, contact);
              },
              child: Text(context.l10n.map_joinRoom),
            ),
        ],
      ),
    );
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        buildQuickSwitchRoute(const ChatsScreen(hideBackButton: true)),
      );
    }
  }

  Future<void> _disconnect(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.common_disconnect),
        content: Text(context.l10n.map_disconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_disconnect),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await connector.disconnect();
    }
  }

  void _showMarkerInfo(_SharedMarker marker) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(marker.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context.l10n.map_from, marker.fromName),
            _buildInfoRow(context.l10n.map_source, marker.sourceLabel),
            _buildInfoRow(
              'Location',
              '${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}',
            ),
            if (marker.flags.isNotEmpty)
              _buildInfoRow(context.l10n.map_flags, marker.flags),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
              });
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.common_hide),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
                _removedMarkerIds.add(marker.id);
              });
              await _markerService.saveRemovedIds(_removedMarkerIds);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(context.l10n.common_remove),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  /// What is known of a person: when they were last heard and, from the
  /// newest of their TRAX report, their radio's answer and their advert,
  /// where; which way and how fast from a TRAX report that is the newest.
  List<Widget> _personRows(
    BuildContext context,
    Contact contact,
    LatLng? guessedPosition,
  ) {
    final l10n = context.l10n;
    final units = context.read<AppSettingsService>().settings.unitSystem;
    final p = _person(
      context,
      contact,
      context.read<TripPositions?>()?.of(contact),
    );
    return [
      _buildInfoRow(l10n.map_lastHeard, _heardText(p.heard, p.old)),
      if (p.place case final place?)
        _buildInfoRow(
          'Location',
          '${place.latitude.toStringAsFixed(5)}, '
              '${place.longitude.toStringAsFixed(5)}',
        )
      else if (guessedPosition != null)
        _buildInfoRow(
          'Est. Location',
          '~${guessedPosition.latitude.toStringAsFixed(5)}, ${guessedPosition.longitude.toStringAsFixed(5)}',
        ),
      if (_fromYou(p.place) case final from?)
        _buildInfoRow(l10n.map_fromYou, from),
      if (p.heading case final h?)
        _buildInfoRow(l10n.map_heading, _headingText(h)),
      if (p.speed case final v?)
        _buildInfoRow(l10n.map_speed, GeoFormat.speedText(v, units)),
      if (p.stillSince case final still?)
        _buildInfoRow(
          l10n.map_notMoving,
          l10n.map_notMovingSince(
            DateTimeHelper.timeWithDay(context, still),
            DateTime.now().difference(still).inMinutes,
          ),
        ),
      if (p.altitude case final a?)
        _buildInfoRow(l10n.map_elevation, GeoFormat.heightText(a, units)),
      if (p.battery case final b?) _buildInfoRow(l10n.map_radioBattery, '$b%'),
      _buildInfoRow('Path', contact.pathLabel),
    ];
  }

  /// What the map knows of a person, from the newest of their TRAX
  /// [report], their radio's answer and their advert: when they were last
  /// heard, whether that reading may be old, where they are, which way and
  /// how fast they go or since when they haven't moved, how high they are
  /// and their radio's battery. One of [contact] and [report] at least.
  ({
    DateTime heard,
    bool old,
    LatLng? place,
    double? heading,
    double? speed,
    DateTime? stillSince,
    double? altitude,
    int? battery,
  })
  _person(BuildContext context, Contact? contact, TripPosition? report) {
    final answer = contact == null
        ? null
        : context.read<RadioAskService?>()?.positionOf(contact);
    final places = [
      if (report != null)
        (
          at: report.heardAt,
          place: LatLng(report.lat, report.lon),
          altitude: report.altitude?.toDouble(),
          old: report.mayBeOld,
        ),
      if (answer?.position case final p?)
        (
          at: answer!.receivedAt,
          place: LatLng(p.lat, p.lon),
          altitude: p.altitude == 0 ? null : p.altitude,
          old: false,
        ),
      if (contact != null && contact.hasLocation)
        (
          at: contact.lastSeen,
          place: LatLng(contact.latitude!, contact.longitude!),
          altitude: null,
          old: false,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    final latest = places.firstOrNull;
    final heard = [
      ?contact?.lastSeen,
      ?report?.heardAt,
      ?answer?.receivedAt,
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    final moving = report != null && latest?.at == report.heardAt;
    return (
      heard: heard,
      old: latest != null && latest.old && latest.at == heard,
      place: latest?.place,
      heading: moving ? report.heading : null,
      speed: moving ? report.speed : null,
      stillSince: moving ? report.stillSince : null,
      altitude: latest?.altitude,
      battery: report?.battery,
    );
  }

  /// "0.4 mi NW": how far [place] is from this radio, and which way.
  String? _fromYou(LatLng? place) {
    final me = _selfPosition(_connector);
    if (me == null || place == null) return null;
    final units = context.read<AppSettingsService>().settings.unitSystem;
    return GeoFormat.offset(me, place, units).text;
  }

  /// Battery icons with 1 to 7 bars, for 20 % and up.
  static const _batteryIcons = [
    Icons.battery_1_bar,
    Icons.battery_2_bar,
    Icons.battery_3_bar,
    Icons.battery_4_bar,
    Icons.battery_5_bar,
    Icons.battery_6_bar,
    Icons.battery_full,
  ];

  static String _headingText(double degrees) =>
      '${GeoFormat.compass8(degrees)} ${degrees.round()}°';

  /// "5:25 PM · 3m ago", and "may be old" when the reading may be.
  String _heardText(DateTime heard, bool old) => [
    DateTimeHelper.timeWithDay(context, heard),
    _formatLastSeen(heard),
    if (old) context.l10n.trax_mayBeOld,
  ].join(' · ');

  /// A trip member's card over a clear map: their trail above it, centred
  /// on them, and what is known of them, kept up to date. The map follows
  /// them, with the card open or closed, until it is dragged; their trail
  /// stays. Their own marker is the pin. With a [zoom], the map goes to them
  /// first: asked from elsewhere, they may be out of view.
  Future<void> _showMemberCard(_Member member, {double? zoom}) async {
    final place = _person(context, member.contact, member.report).place;
    if (place == null) return;
    setState(() {
      _trailOf = member.prefix;
      _followMe = false;
      _followOf = member.prefix;
      _followedAt = place;
      _cardOf = member.prefix;
    });
    await _showPointSheet(
      place,
      pin: false,
      centerAfter: zoom == null ? Future<void>.value() : _moveTo(place, zoom),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: _Ticking(
            builder: (context) => _memberCard(context, sheetContext, member),
          ),
        ),
      ),
    );
    // Back in the middle of the whole map.
    if (mounted && _cardOf == member.prefix) {
      setState(() {
        _cardOf = null;
        _cardCovered = 0;
        _followedAt = null;
      });
    }
  }

  /// Who, when heard and how far, then one line of small figures (which
  /// way, how fast or how long stopped, how high, their battery; each
  /// names itself on a long-press), then Chat and Ask for a contact, or Ask
  /// for track for a member who isn't one.
  Widget _memberCard(
    BuildContext context,
    BuildContext sheetContext,
    _Member member,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = context.read<AppSettingsService>().settings;
    final units = settings.unitSystem;
    final contact = member.contact;
    final positions = context.watch<TripPositions?>();
    final report =
        positions?.all.where((q) => q.prefix == member.prefix).firstOrNull ??
        member.report;
    final connected = context.read<MeshCoreConnector>().isConnected;
    final asksTrack =
        contact == null && connected && (positions?.canAskTrack ?? false);
    final trackAsked = positions?.askedAt(member.prefix);
    final p = _person(context, contact, report);
    final place = p.place;

    Widget figure(
      String label,
      IconData icon,
      String value, {
      double? degrees,
      Color? color,
    }) {
      final glyph = Icon(
        icon,
        size: 16,
        color: color ?? scheme.onSurfaceVariant,
      );
      return Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (degrees != null)
                Transform.rotate(angle: degrees * pi / 180, child: glyph)
              else
                glyph,
              const SizedBox(width: 6),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
    }

    final figures = [
      if (p.heading case final h?)
        figure(l10n.map_heading, Icons.north, _headingText(h), degrees: h),
      if (p.speed case final v?)
        figure(l10n.map_speed, Icons.speed, GeoFormat.speedText(v, units)),
      if (p.stillSince case final still?)
        figure(
          l10n.map_notMoving,
          Icons.pause_circle_outline,
          l10n.map_stoppedFor(DateTime.now().difference(still).inMinutes),
        ),
      if (p.altitude case final a?)
        figure(
          l10n.map_elevation,
          Icons.terrain,
          GeoFormat.heightText(a, units),
        ),
      if (p.battery case final b?)
        figure(
          l10n.map_radioBattery,
          b < 20
              ? Icons.battery_alert
              : _batteryIcons[(b * 7 / 100).round().clamp(1, 7) - 1],
          '$b%',
          color: b < 20 ? scheme.error : null,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: p.old ? Colors.grey : const Color(Trax.orange),
                child: Icon(
                  traxIconData(report?.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact?.name ?? report?.name ?? member.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text.rich(
                      TextSpan(
                        text: [
                          DateTimeHelper.timeWithDay(context, p.heard),
                          _formatLastSeen(p.heard),
                          ?_fromYou(place),
                        ].join(' · '),
                        children: [
                          if (p.old)
                            TextSpan(
                              text: ' · ${l10n.trax_mayBeOld}',
                              style: TextStyle(color: scheme.error),
                            ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (place != null)
                CopyPositionButton(
                  text: positionLines(
                    place.latitude,
                    place.longitude,
                    coordFormatOf(settings),
                  ).first,
                ),
            ],
          ),
          if (figures.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(spacing: 8, runSpacing: 8, children: figures),
            ),
          ],
          if (asksTrack) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => unawaited(positions!.askTrack(member.prefix)),
              icon: const Icon(Icons.route, size: 18),
              label: Text(
                trackAsked == null
                    ? l10n.trax_askTrack
                    : l10n.trax_trackAsked(
                        DateTimeHelper.time(context, trackAsked),
                      ),
              ),
            ),
          ],
          if (contact != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final connector = this.context.read<MeshCoreConnector>();
                    if (!contact.isActive &&
                        !await connector.importDiscoveredContact(contact)) {
                      if (mounted) {
                        showDismissibleSnackBar(
                          this.context,
                          content: Text(l10n.contacts_contactImportFailed),
                        );
                      }
                      return;
                    }
                    if (!mounted) return;
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(contact: contact),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l10n.map_chat),
                ),
                if (connected)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      RadioAskSheet.show(
                        this.context,
                        contact,
                        onShowOnMap: (point) => _moveTo(
                          point,
                          max(_mapController.camera?.zoom ?? 14, 14),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_input_antenna, size: 18),
                    label: Text(l10n.radioAsk_title(contact.name)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The TRAX group by name, with how far away and which way each is and
  /// when heard; grey when that may be old, and those with no location yet
  /// last. A tap opens their card on the map.
  Future<void> _showGroupSheet() async {
    final picked = await showModalBottomSheet<_Member>(
      context: context,
      barrierColor: Colors.transparent,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: _Ticking(
            builder: (context) => _groupList(context, sheetContext),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final contact = picked.contact;
    // Nowhere to show yet: their radio is asked, and their phone for their
    // track in TRAX mode.
    if (contact != null &&
        _person(context, contact, picked.report).place == null) {
      await RadioAskSheet.show(
        context,
        contact,
        onShowOnMap: (point) =>
            _moveTo(point, max(_mapController.camera?.zoom ?? 14, 14)),
      );
      return;
    }
    await _showMemberCard(picked);
  }

  Widget _groupList(BuildContext context, BuildContext sheetContext) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final group = context.watch<TripService?>();
    context.watch<RadioAskService?>();
    final positions = context.watch<TripPositions?>();
    final members = _members(
      positions,
      group,
      context.watch<TraxService?>()?.isOn ?? false,
      context.watch<MeshCoreConnector>(),
    );
    final newer = positions?.newer ?? const <String, DateTime>{};
    // Senders of a newer TRAX with no name here.
    final someone = [
      for (final MapEntry(:key, :value) in newer.entries)
        if (!members.any((m) => m.prefix == key)) value,
    ];
    final located = <(_Member, LatLng, DateTime, bool)>[];
    final unlocated = <(String, _Member?)>[];
    for (final m in members) {
      final p = _person(context, m.contact, m.report);
      if (p.place case final place?) {
        located.add((m, place, p.heard, p.old));
      } else {
        unlocated.add((m.name, m));
      }
    }
    // The trip channel's posters no single contact has.
    final listed = {
      for (final m in members) ...[
        m.name.toLowerCase(),
        ?m.report?.name?.toLowerCase(),
      ],
    };
    for (final t in group?.members ?? const <TripMember>[]) {
      if (t.contact == null && !listed.contains(t.name.toLowerCase())) {
        unlocated.add((t.name, null));
      }
    }
    located.sort((a, b) => _byName(a.$1.name, b.$1.name));
    unlocated.sort((a, b) => _byName(a.$1, b.$1));
    final connected = context.read<MeshCoreConnector>().isConnected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.trax_group,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (located.isEmpty && unlocated.isEmpty && someone.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(l10n.trax_heard(0, '')),
          ),
        for (final (member, place, heard, old) in located)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: old ? Colors.grey : const Color(Trax.orange),
              child: Icon(
                traxIconData(member.report?.icon),
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              newer.containsKey(member.prefix)
                  ? l10n.trax_updateToSee(member.name)
                  : member.name,
              maxLines: newer.containsKey(member.prefix) ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [?_fromYou(place), _formatLastSeen(heard)].join(' · '),
            ),
            onTap: () => Navigator.pop(sheetContext, member),
          ),
        for (final (name, member) in unlocated)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.hiking,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            title: Text(
              newer[member?.prefix] == null
                  ? l10n.trax_memberNoLocation(name)
                  : l10n.trax_updateToSee(name),
              maxLines: newer[member?.prefix] == null ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: switch (newer[member?.prefix]) {
              final at? => Text(_formatLastSeen(at)),
              null => null,
            },
            trailing: member?.contact != null && connected
                ? Icon(
                    Icons.settings_input_antenna,
                    semanticLabel: l10n.radioAsk_title(name),
                  )
                : null,
            onTap: member?.contact != null && connected
                ? () => Navigator.pop(sheetContext, member)
                : null,
          ),
        for (final at in someone)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.hiking,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            title: Text(l10n.trax_updateToSeeSomeone, maxLines: 2),
            subtitle: Text(_formatLastSeen(at)),
          ),
      ],
    );
  }

  static int _byName(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return context.l10n.time_justNow;
    } else if (difference.inMinutes < 60) {
      return context.l10n.time_minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return context.l10n.time_hoursAgo(difference.inHours);
    } else {
      return context.l10n.time_daysAgo(difference.inDays);
    }
  }

  void _showShareMarkerAtPositionSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
    LatLng? selfPosition,
    String? title,
    Future<void>? centerAfter,
  }) {
    final canRoute = _canRouteAt(position);
    final format = coordFormatOf(context.read<AppSettingsService>().settings);
    final lines = positionLines(position.latitude, position.longitude, format);
    final name = title ?? lines.first;
    // What's set already, so it's clear whether a route goes from or to.
    final l10n = context.l10n;
    final to = _shownTo;
    final from = _onWater ? _water.from : _routeFrom;
    final startNow = from != null
        ? l10n.route_startNow(
            positionLines(from.latitude, from.longitude, format).first,
          )
        : to != null
        ? l10n.route_startNowYou
        : null;
    _showPointSheet(
      position,
      centerAfter: centerAfter,
      // As tall as its rows, which scroll on a screen too small for them.
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  title ?? lines.first,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                subtitle: title == null && lines.length == 1
                    ? null
                    : Text((title == null ? lines.skip(1) : lines).join('\n')),
                trailing: CopyPositionButton(text: lines.first),
              ),
              if (canRoute) ...[
                ListTile(
                  leading: const Icon(Icons.directions),
                  title: Text(context.l10n.route_here),
                  subtitle: to == null
                      ? null
                      : Text(l10n.route_destinationNow(to.name)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _routeHere(name, position, selfPosition);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trip_origin),
                  title: Text(context.l10n.route_fromHere),
                  subtitle: startNow == null ? null : Text(startNow),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _routeFromHere(position, selfPosition);
                  },
                ),
              ],
              if (_losOffered) ...[
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(l10n.los_lineFromMe),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openLos(
                      LosMode.line,
                      from: _me(connector, selfPosition),
                      to: LosPlace.point(position, name: title),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text(l10n.los_reachFromHere),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openLos(
                      LosMode.reach,
                      from: LosPlace.point(position, name: title),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.place),
                title: Text(context.l10n.map_shareMarkerHere),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareMarker(
                    context: context,
                    connector: connector,
                    position: position,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(context.l10n.map_setAsMyLocation),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final successMsg = context.l10n.settings_locationUpdated;
                  Navigator.pop(sheetContext);
                  if (!connector.isConnected) return;
                  await connector.setNodeLocation(
                    lat: position.latitude,
                    lon: position.longitude,
                  );
                  unawaited(connector.refreshRadioSettings());
                  if (!mounted) return;
                  showDismissibleSnackBar(
                    messenger.context,
                    content: Text(successMsg),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(context.l10n.common_cancel),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Line of sight is on offer: on a map of your own (not one pushed to
  /// pick a position) with offline maps.
  bool get _losOffered =>
      !widget.pickPosition &&
      !_isBuildingPathTrace &&
      context.read<MapPacksService?>() != null;

  /// A radio with no position reports 0, 0.
  LatLng? _selfPosition(MeshCoreConnector connector) =>
      connector.hasValidLocation(
        connector.selfLatitude,
        connector.selfLongitude,
      )
      ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
      : null;

  /// You, at the radio's position: with the GPS's age and, from its
  /// altitude, the ground under you (the radio in a hand or a car, 1.5 m
  /// up). A position the GPS hasn't confirmed this connection may be the
  /// one stored before a restart; without GPS it was set by hand.
  LosPlace? _me(MeshCoreConnector connector, LatLng? position) {
    if (position == null) return null;
    final gps = connector.selfGps.value;
    final live = connector.gpsOn && connector.selfPositionIsLive && gps != null;
    final here =
        live &&
        const Distance().as(
              LengthUnit.Meter,
              position,
              LatLng(gps.latitude, gps.longitude),
            ) <
            100;
    return LosPlace.me(
      position,
      source: !connector.gpsOn
          ? MyPosition.byHand
          : live
          ? MyPosition.gps
          : MyPosition.notYetGps,
      seenAt: live ? gps.at : null,
      groundM: here && gps.altitude != 0 ? gps.altitude - 1.5 : null,
    );
  }

  LosPlace _contactPlace(Contact contact) => LosPlace.contact(
    LatLng(contact.latitude!, contact.longitude!),
    name: contact.name,
    key: contact.publicKeyHex,
    repeater: contact.type == advTypeRepeater,
    seenAt: contact.lastSeen,
  );

  /// Everyone with a known position, you too, and those the map shows at
  /// a guessed position: the radio reach's list.
  List<LosPlace> _losPeople() {
    final connector = _connector;
    return [
      ?_me(connector, _selfPosition(connector)),
      for (final c in connector.allContacts)
        if (c.hasLocation) _contactPlace(c),
      for (final g in GuessedLocationHelper.withCurrentContacts(
        _cachedGuessedLocations,
        connector.allContacts,
      ))
        LosPlace.contact(
          g.position,
          name: g.contact.name,
          key: g.contact.publicKeyHex,
          repeater: g.contact.type == advTypeRepeater,
          seenAt: g.contact.lastSeen,
          guessedVia: g.heardVia,
        ),
    ];
  }

  /// Opens the line of sight sheet in place of the route sheet; nothing
  /// is worked out until there is somewhere to look.
  void _openLos(LosMode mode, {LosPlace? from, LosPlace? to}) {
    final maps = context.read<MapPacksService?>();
    if (maps == null) return;
    final khz = _connector.currentFreqHz;
    _los?.dispose();
    final session = LineOfSightSession(
      worker: _losWorker ??= LosWorker(),
      maps: maps,
      settings: context.read<AppSettingsService>(),
      mode: mode,
      // The radio's frequency (currentFreqHz holds kHz).
      frequencyMHz: khz != null && khz > 0 ? khz / 1000 : defaultFrequencyMHz,
      people: _losPeople,
      peopleChanged: _connector,
      from: from,
      to: to,
    )..addListener(_onLos);
    _losCovered.value = 0;
    setState(() {
      _los = session;
      _losShown = null;
    });
    _onLos();
  }

  void _closeLos() {
    _los?.dispose();
    _losCovered.value = 0;
    setState(() => _los = null);
  }

  void _onLos() {
    if (!mounted) return;
    final s = _los;
    if (s == null) return;
    final drawn = (s.endsVersion, s.mode, s.line, s.reach, s.busy);
    if (drawn != _losDrawn) {
      _losDrawn = drawn;
      setState(() {});
    }
    // Again once the answer is in: the sheet then has its height.
    final key = (
      s.endsVersion,
      s.mode,
      s.reachRadiusM,
      s.mode == LosMode.line ? s.currentLine != null : s.reach != null,
    );
    if (key == _losShown) return;
    _losShown = key;
    // Once the sheet is laid out, to fit clear of it.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && _los == s) _showLos(s);
      })
      ..ensureVisualUpdate();
  }

  /// Moves the map to show the line's ends or the whole reach, clear of
  /// the map's buttons and the sheet, unless it shows them already.
  void _showLos(LineOfSightSession s) {
    final from = s.from;
    if (from == null) return;
    final points = s.mode == LosMode.reach
        ? [
            for (final b in [0.0, 90.0, 180.0, 270.0])
              latLngOf(destination(geoOf(from.position), b, s.reachRadiusM)),
          ]
        : [from.position, ?s.to?.position];
    if (points.length < 2) return;
    final sheet = _losKey.currentState?.restHeight() ?? 0;
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final onScreen = [
      for (final p in points) _mapController.toScreen(p.toOvm()),
    ];
    final inView = onScreen.every(
      (at) =>
          at != null &&
          at.dx >= 16 &&
          at.dx <= box.size.width - MapControls.width &&
          at.dy >= 16 &&
          at.dy <= box.size.height - sheet - 16,
    );
    // A line in view stays where it is, unless it is too small to see.
    if (s.mode == LosMode.line &&
        inView &&
        (onScreen[0]! - onScreen[1]!).distance > box.size.width / 4) {
      return;
    }
    _mapController.fitPoints(
      points.toOvm(),
      padding: EdgeInsets.fromLTRB(
        48,
        48,
        48 + MapControls.width,
        max(48, min(sheet + 48, box.size.height - 120)),
      ),
      maxZoom: 15,
    );
  }

  Widget _buildLosSheet({required bool side}) => LineOfSightSheet(
    key: side ? null : _losKey,
    session: _los!,
    side: side,
    onClose: _closeLos,
    onDownload: (ids) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OfflineMapsScreen(initialPacks: ids)),
    ),
    onHeight: side ? null : (height) => _losCovered.value = height,
    bottomInset: side || !_overScreen
        ? 0
        : MediaQuery.paddingOf(context).bottom,
  );

  /// The line in its answer's colour (grey while it is worked out), the
  /// spot that decides it, and a reach's shade where the ground isn't in
  /// the way.
  List<MapOverlay> _losOverlays() {
    final s = _los;
    final from = s?.from;
    if (s == null || from == null) return const [];
    final out = <MapOverlay>[];
    if (s.mode == LosMode.reach) {
      final r = s.reach;
      if (r != null) {
        if (_losShade.$1 != r) {
          _losShade = (
            r,
            [
              for (final (i, area) in r.areas({
                Verdict.clear,
                Verdict.marginal,
              }).indexed)
                MapPolygon(
                  id: 'los-reach-$i',
                  points: [for (final g in area.outline) latLngOf(g).toOvm()],
                  holes: [
                    for (final hole in area.holes)
                      [for (final g in hole) latLngOf(g).toOvm()],
                  ],
                  fillColor: losReachColor(context).withValues(alpha: 0.45),
                  strokeColor: losReachColor(context),
                  strokeWidth: 1.5,
                ),
            ],
          );
        }
        out.addAll(_losShade.$2);
      }
      out.add(
        MapLine(
          id: 'los-reach-edge',
          points: [
            for (var b = 0; b <= 360; b += 5)
              latLngOf(
                destination(geoOf(from.position), b.toDouble(), s.reachRadiusM),
              ).toOvm(),
          ],
          color: losReachColor(context),
          width: 2,
          pattern: MapLinePattern.dashed,
        ),
      );
    } else if (s.to case final to?) {
      final r = s.currentLine;
      final color = losVerdictColor(context, r?.verdict ?? Verdict.unknown);
      out.add(
        MapLine(
          id: 'los-line',
          points: [from.position.toOvm(), to.position.toOvm()],
          color: color,
          width: 4,
        ),
      );
      final deciding = r?.deciding;
      if (deciding != null &&
          (r!.verdict == Verdict.blocked || r.verdict == Verdict.marginal)) {
        out.add(
          MapMarker(
            id: 'los-deciding',
            position: latLngOf(deciding.position).toOvm(),
            color: color,
            radius: 7,
            interactive: false,
          ),
        );
      }
      if (to.kind == LosPlaceKind.point) {
        out.add(
          MapMarker(
            id: 'los-to',
            position: to.position.toOvm(),
            size: const Size(40, 40),
            anchor: Alignment.bottomCenter,
            interactive: false,
            child: Icon(Icons.location_on, color: Colors.red[600], size: 38),
          ),
        );
      }
    }
    if (from.kind == LosPlaceKind.point) {
      out.add(
        MapMarker(
          id: 'los-from',
          position: from.position.toOvm(),
          color: routeStartColor,
          radius: 7,
          interactive: false,
        ),
      );
    }
    return out;
  }

  /// Whether Route here is on offer at [point] on the map shown: routing
  /// on land, or on the charts water routing.
  bool _canRouteAt(LatLng point) {
    if (_onWater) {
      return context.read<WaterRoutingService?>()?.offeredAt(point.toOvm()) ??
          false;
    }
    final routing = context.read<RoutingService?>();
    return routing != null &&
        routing.available &&
        routing.offeredAt((lat: point.latitude, lon: point.longitude));
  }

  void _routeHere(String name, LatLng to, LatLng? selfPosition) {
    if (_onWater) {
      unawaited(_waterHere(name, to, selfPosition));
    } else {
      _landHere(name, to, selfPosition);
    }
  }

  void _landHere(String name, LatLng to, LatLng? selfPosition) {
    final routing = context.read<RoutingService?>();
    if (routing == null || !routing.hasRoutingData) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.route_noData),
      );
      return;
    }
    // One sheet at a time: the route's takes over.
    if (_los != null) _closeLos();
    setState(() => _routeTo = (name: name, point: to));
    unawaited(_findRoute(selfPosition));
  }

  void _routeFromHere(LatLng from, LatLng? selfPosition) {
    setState(() {
      if (_onWater) {
        _water.from = from;
      } else {
        _routeFrom = from;
      }
    });
    if (_shownTo != null) {
      unawaited(_findShown(selfPosition));
    } else {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.route_startSet),
      );
    }
  }

  Future<void> _findRoute(LatLng? selfPosition) async {
    final to = _routeTo;
    final routing = context.read<RoutingService?>();
    if (to == null || routing == null) return;
    final from = _routeFrom ?? selfPosition;
    final generation = ++_routeGeneration;
    if (from == null) {
      setState(() {
        _route = null;
        _routing = false;
        _routeError = context.l10n.route_noStart;
      });
      _keepRoute();
      return;
    }
    setState(() {
      _routing = true;
      _routeError = null;
    });
    _keepRoute();
    final noRoute = context.l10n.route_none;
    final settings = context.read<AppSettingsService>().settings;
    try {
      final r = await routing.route(
        (lat: from.latitude, lon: from.longitude),
        (lat: to.point.latitude, lon: to.point.longitude),
        settings.routePathType,
        options: settings.routeOptions,
      );
      if (!mounted || generation != _routeGeneration) return;
      setState(() {
        _route = r;
        _routing = false;
        _routeFoundFrom = from;
        _routeFoundAt = DateTime.now();
      });
      _keepRoute();
      // Once the sheet is laid out for this route, to fit clear of it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _routeGeneration) _fitRoute();
      });
    } on Object catch (e) {
      appLogger.warn('Route failed: $e', tag: 'Routing');
      if (!mounted || generation != _routeGeneration) return;
      setState(() {
        _route = null;
        _routing = false;
        _routeError = noRoute;
      });
    }
  }

  /// Goes to [point] at [zoom]. Offline, the map caps the zoom where
  /// nothing is downloaded, and it lifts the cap only once it sees it is
  /// over a downloaded region, so a jump from far away tries again for a
  /// moment.
  /// A sheet about [point] over a clear map: no dimming, a pin on the point,
  /// and the point clear of the sheet. A search pick goes in the middle of
  /// the map left above the sheet once [centerAfter] (its move) is done; a
  /// point on the map moves only if the sheet would cover it.
  Future<void> _showPointSheet(
    LatLng point, {
    required WidgetBuilder builder,
    Future<void>? centerAfter,
    bool dragHandle = false,
    bool pin = true,
  }) async {
    setState(() {
      _sheetPoint = point;
      _sheetPin = pin;
    });
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: dragHandle,
      useSafeArea: true,
      builder: (sheetContext) => _ReportHeight(
        // The drag handle sits above what the builder gives.
        onHeight: (height) => _keepClear(
          point,
          height + (dragHandle ? kMinInteractiveDimension : 0),
          centerAfter: centerAfter,
        ),
        child: builder(sheetContext),
      ),
    );
    if (mounted && _sheetPoint == point) setState(() => _sheetPoint = null);
  }

  /// Moves the map so a sheet [sheetHeight] tall leaves [point] in view.
  Future<void> _keepClear(
    LatLng point,
    double sheetHeight, {
    Future<void>? centerAfter,
  }) async {
    await centerAfter;
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || _sheetPoint != point || box == null || !box.hasSize) {
      return;
    }
    // How much of the map's bottom the sheet covers.
    final top = MediaQuery.sizeOf(context).height - sheetHeight;
    final covered = box.localToGlobal(Offset.zero).dy + box.size.height - top;
    if (_cardOf != null) _cardCovered = max(0, covered);
    if (covered <= 0) return;
    if (centerAfter == null) {
      final at = _mapController.toScreen(point.toOvm());
      // The pin stands on the point, so a little room above the sheet will do.
      if (at == null || at.dy < box.size.height - covered - 16) return;
    }
    _mapController.fitPoints(
      [point.toOvm()],
      padding: EdgeInsets.only(bottom: covered),
      maxZoom: _mapController.camera?.zoom,
    );
  }

  Future<void> _moveTo(LatLng point, double zoom) async {
    _mapController.move(point.toOvm(), zoom: zoom);
    for (var i = 0; i < 20 && mounted; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if ((_mapController.camera?.zoom ?? zoom) >= zoom - 0.01) return;
      _mapController.move(point.toOvm(), zoom: zoom);
    }
  }

  /// Shows the whole route, clear of the map's buttons and the route sheet.
  void _fitRoute() {
    final r = _route, to = _routeTo;
    if (r == null || to == null) return;
    _mapController.fitPoints([
      for (final p in r.points) LatLng(p.lat, p.lon).toOvm(),
      to.point.toOvm(),
    ], padding: _routePadding(_sheetKey.currentState));
  }

  /// Room around a route fitted on the map: clear of the map's buttons and
  /// of [sheet].
  EdgeInsets _routePadding(RouteSheetState? sheet) => EdgeInsets.fromLTRB(
    48,
    48,
    48 + MapControls.width,
    // A sheet over most of the map still leaves the route some of it.
    sheet == null
        ? 48
        : max(48, min(sheet.restHeight() + 48, sheet.room - 120)),
  );

  void _clearRoute() {
    setState(() {
      _routeGeneration++;
      _routeTo = null;
      _routeFrom = null;
      _route = null;
      _routeFoundFrom = null;
      _routeFoundAt = null;
      _routing = false;
      _routeError = null;
    });
    _keepRoute();
  }

  /// Keeps the route for the Map tab: the quick switch puts another screen
  /// in its place, and Back from a map over a chat leaves the route there.
  /// One still being found is found again then. A map under another one
  /// that has kept a route since leaves that route.
  void _keepRoute() {
    if (widget.pickPosition) return;
    if (!(_pageRoute?.isCurrent ?? true) &&
        !identical(_viewState.mapRoute, _keptRoute)) {
      return;
    }
    final to = _routeTo;
    _viewState.mapRoute = _keptRoute = to == null
        ? null
        : (
            name: to.name,
            to: to.point.toOvm(),
            from: _routeFrom?.toOvm(),
            result: _routing ? null : _route,
            foundFrom: _routeFoundFrom?.toOvm(),
            foundAt: _routeFoundAt,
          );
    _viewState.mapRouteSeen = _isMapTab;
  }

  Widget _buildRouteSheet(
    AppSettingsService settingsService,
    LatLng? selfPosition, {
    required bool side,
  }) {
    final settings = settingsService.settings;
    final from = _routeFrom;
    final foundFrom = _routeFoundFrom;
    final movedAway =
        from == null &&
        _route != null &&
        foundFrom != null &&
        selfPosition != null &&
        const Distance().as(LengthUnit.Meter, foundFrom, selfPosition) > 100;
    return RouteSheet(
      key: side ? null : _sheetKey,
      destination: _routeTo!.name,
      start: from == null
          ? null
          : positionLines(
              from.latitude,
              from.longitude,
              coordFormatOf(settings),
            ).first,
      positionMayBeOld: _connector.selfPositionMayBeOld,
      positionKnownAt: _connector.selfGpsChangedAt,
      youWereAt: movedAway ? _routeFoundAt : null,
      dataDate: context.read<RoutingService?>()?.dataDate,
      onUseMyPosition: () {
        setState(() => _routeFrom = null);
        unawaited(_findRoute(selfPosition));
      },
      pathType: settings.routePathType,
      onPathType: (type) async {
        await settingsService.setRoutePathType(type);
        unawaited(_findRoute(selfPosition));
      },
      options: settings.routeOptions,
      onOptions: (options) async {
        await settingsService.setRouteOptions(options);
        unawaited(_findRoute(selfPosition));
      },
      result: _route,
      loading: _routing,
      error: _routeError,
      units: settings.unitSystem,
      onClose: _clearRoute,
      onOtherApp: () {
        final to = _routeTo;
        if (to == null) return;
        unawaited(LinkHandler.openInMapsApp(context, to.point, label: to.name));
      },
      actions: [
        if ((_route, _routeTo) case (final r?, final to?)
            when !r.reachesDestination && _waterOfferedAt(to.point))
          (
            icon: Icons.directions_boat_outlined,
            label: context.l10n.route_onWater,
            onPressed: () => unawaited(_routeOnOtherMap(to, selfPosition)),
          ),
      ],
      side: side,
      // With no quick-switch bar under the map, the sheet reaches the
      // screen's edge.
      bottomInset: side || !_overScreen
          ? 0
          : MediaQuery.paddingOf(context).bottom,
    );
  }

  List<MapOverlay> _routeOverlays() {
    final to = _routeTo;
    if (to == null) return const [];
    final r = _route;
    final color = routeColor(context);
    final start = _routeFoundFrom;
    return [
      if (r != null) ...[
        if (r.startsOffPath && start != null)
          MapLine(
            id: 'route-start-gap',
            points: [
              start.toOvm(),
              LatLng(r.points.first.lat, r.points.first.lon).toOvm(),
            ],
            color: color,
            width: 2,
            pattern: MapLinePattern.dotted,
          ),
        if (!r.reachesDestination)
          MapLine(
            id: 'route-rest',
            points: [
              LatLng(r.points.last.lat, r.points.last.lon).toOvm(),
              to.point.toOvm(),
            ],
            color: color,
            width: 2,
            pattern: MapLinePattern.dotted,
          ),
        MapLine(
          id: 'route',
          points: [for (final p in r.points) LatLng(p.lat, p.lon).toOvm()],
          color: color.withValues(alpha: 0.85),
          width: 5,
        ),
        MapMarker(
          id: 'route-start',
          position: LatLng(r.points.first.lat, r.points.first.lon).toOvm(),
          color: routeStartColor,
          radius: 7,
          interactive: false,
        ),
      ],
      MapMarker(
        id: 'route-end',
        position: to.point.toOvm(),
        color: const Color(0xFFC62828),
        radius: 7,
        interactive: false,
      ),
    ];
  }

  /// Whether a chart area at [point] has water routing, on the device or
  /// to download, for a route on land that can't reach it.
  bool _waterOfferedAt(LatLng point) =>
      context.read<WaterRoutingService?>()?.areaAt(point.toOvm()) != null;

  /// The other map's route to where the one shown can't reach: the land
  /// map's from the charts, the charts' from a land map. Each map's route
  /// keeps its own start.
  Future<void> _routeOnOtherMap(
    ({String name, LatLng point}) to,
    LatLng? selfPosition,
  ) async {
    final toWater = !_onWater;
    await context.read<AppSettingsService>().setMapType(
      toWater ? MapType.charts.name : _landMapType.name,
    );
    if (!mounted) return;
    if (toWater) {
      await _waterHere(to.name, to.point, selfPosition);
    } else {
      _landHere(to.name, to.point, selfPosition);
    }
  }

  Future<void> _waterHere(String name, LatLng to, LatLng? selfPosition) async {
    final water = context.read<WaterRoutingService?>();
    if (water == null || !water.hasRoutingData) {
      final area = water?.areaAt(to.toOvm());
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.water_noData),
        action: area == null
            ? null
            : SnackBarAction(
                label: context.l10n.navigate_showDownload,
                onPressed: () => _showWaterDownload(area.packRegion),
              ),
      );
      return;
    }
    if (!await askWaterBoatIfNeeded(context, notices: water.notices) ||
        !mounted) {
      return;
    }
    // One sheet at a time: the trip's takes over.
    if (_los != null) _closeLos();
    setState(() => _water.to = (name: name, point: to));
    unawaited(_findWaterRoute(selfPosition));
  }

  /// Offline maps on the charts, with [area]'s water routing ticked.
  void _showWaterDownload(String? area) => unawaited(
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => area == null
            ? const OfflineMapsScreen(initialTab: OfflineMapsTab.charts)
            : OfflineMapsScreen(initialWaterRouting: area),
      ),
    ),
  );

  Future<void> _findWaterRoute(LatLng? selfPosition) async {
    final w = _water;
    final to = w.to;
    final water = context.read<WaterRoutingService?>();
    if (to == null || water == null) return;
    final from = w.from ?? selfPosition;
    final generation = ++w.generation;
    final l10n = context.l10n;
    if (from == null) {
      setState(() {
        w.trip = null;
        w.finding = false;
        w.error = l10n.route_noStart;
        w.problem = null;
      });
      _keepWaterRoute();
      return;
    }
    setState(() {
      w.finding = true;
      w.error = null;
      w.problem = null;
    });
    _keepWaterRoute();
    final boat = context.read<AppSettingsService>().settings.waterRouteOptions;
    try {
      final trip = await water.route(
        (lat: from.latitude, lon: from.longitude),
        (lat: to.point.latitude, lon: to.point.longitude),
        options: boat,
      );
      if (!mounted || generation != w.generation) return;
      setState(() {
        w.trip = trip;
        w.finding = false;
        w.foundFrom = from;
        w.foundAt = DateTime.now();
      });
      _keepWaterRoute();
      // Once the sheet is laid out for this trip, to fit clear of it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == w.generation && _onWater) {
          _fitWaterRoute();
        }
      });
    } on Object catch (e) {
      appLogger.warn('Water route failed: $e', tag: 'Routing');
      if (!mounted || generation != w.generation) return;
      final problem = e is WaterRoutingException ? e.problem : null;
      setState(() {
        w.trip = null;
        w.finding = false;
        w.problem = problem;
        w.error = switch (problem) {
          WaterRoutingProblem.noTiles => l10n.water_noTiles,
          WaterRoutingProblem.mixedBuilds => l10n.water_mixedBuilds,
          WaterRoutingProblem.noWater => l10n.water_noWater,
          null => l10n.route_none,
        };
      });
    }
  }

  void _fitWaterRoute() {
    final trip = _water.trip, to = _water.to;
    if (trip == null || to == null) return;
    _mapController.fitPoints([
      for (final p in trip.waypoints) LatLng(p.lat, p.lon).toOvm(),
      to.point.toOvm(),
    ], padding: _routePadding(_waterSheetKey.currentState));
  }

  void _clearWaterRoute() {
    setState(_water.clear);
    _keepWaterRoute();
  }

  /// Keeps the trip on the water for the Map tab, as [_keepRoute] keeps the
  /// route on land.
  void _keepWaterRoute() {
    if (widget.pickPosition) return;
    final w = _water;
    if (!(_pageRoute?.isCurrent ?? true) &&
        !identical(_viewState.mapWaterRoute, w.kept)) {
      return;
    }
    final to = w.to;
    _viewState.mapWaterRoute = w.kept = to == null
        ? null
        : (
            name: to.name,
            to: to.point.toOvm(),
            from: w.from?.toOvm(),
            result: w.finding ? null : w.trip,
            foundFrom: w.foundFrom?.toOvm(),
            foundAt: w.foundAt,
          );
    _viewState.mapWaterRouteSeen = _isMapTab;
  }

  Widget _buildWaterSheet(
    AppSettingsService settingsService,
    LatLng? selfPosition, {
    required bool side,
  }) {
    final settings = settingsService.settings;
    final l10n = context.l10n;
    final water = context.read<WaterRoutingService?>();
    final routing = context.read<RoutingService?>();
    final w = _water;
    final to = w.to!;
    final from = w.from;
    final foundFrom = w.foundFrom;
    final movedAway =
        from == null &&
        w.trip != null &&
        foundFrom != null &&
        selfPosition != null &&
        const Distance().as(LengthUnit.Meter, foundFrom, selfPosition) > 100;
    // Short of the place, or no water there: the land map's route where it
    // has one. Routing missing at an end: its download.
    final short =
        w.trip?.endsShort != null ||
        w.problem == WaterRoutingProblem.noTiles ||
        w.problem == WaterRoutingProblem.noWater;
    final missing = [
      for (final p in [to.point, ?(from ?? selfPosition)])
        if (water?.areaAt(p.toOvm()) case final area?
            when !water!.isInstalled(area.packRegion))
          area.packRegion,
    ].firstOrNull;
    return RouteSheet.water(
      key: side ? null : _waterSheetKey,
      destination: to.name,
      start: from == null
          ? null
          : positionLines(
              from.latitude,
              from.longitude,
              coordFormatOf(settings),
            ).first,
      positionMayBeOld: _connector.selfPositionMayBeOld,
      positionKnownAt: _connector.selfGpsChangedAt,
      youWereAt: movedAway ? w.foundAt : null,
      onUseMyPosition: () {
        setState(() => w.from = null);
        unawaited(_findWaterRoute(selfPosition));
      },
      water: WaterRouteBody(
        boat: settings.waterRouteOptions,
        onBoat: (boat) async {
          await settingsService.setWaterRouteOptions(boat);
          unawaited(_findWaterRoute(selfPosition));
        },
        trip: w.trip,
        notices: water?.notices ?? const [],
      ),
      loading: w.finding,
      error: w.error,
      units: settings.unitSystem,
      onClose: _clearWaterRoute,
      actions: [
        if (short &&
            routing != null &&
            routing.available &&
            routing.offeredAt((
              lat: to.point.latitude,
              lon: to.point.longitude,
            )))
          (
            icon: Icons.directions_outlined,
            label: l10n.route_onLand,
            onPressed: () => unawaited(_routeOnOtherMap(to, selfPosition)),
          ),
        if (w.problem == WaterRoutingProblem.mixedBuilds ||
            (w.problem == WaterRoutingProblem.noTiles && missing != null))
          (
            icon: Icons.download_outlined,
            label: l10n.navigate_showDownload,
            onPressed: () => _showWaterDownload(missing),
          ),
      ],
      side: side,
      // With no quick-switch bar under the map, the sheet reaches the
      // screen's edge.
      bottomInset: side || !_overScreen
          ? 0
          : MediaQuery.paddingOf(context).bottom,
    );
  }

  /// The trip on the water, on the chart in its own colour: dotted from
  /// the point picked to where it starts, and on from where it ends to the
  /// place asked for.
  List<MapOverlay> _waterOverlays({required bool darkMap}) {
    final to = _water.to;
    if (to == null) return const [];
    final trip = _water.trip;
    final color = waterRouteColor(darkMap: darkMap);
    final points = [
      for (final p in trip?.waypoints ?? const <({double lat, double lon})>[])
        LatLng(p.lat, p.lon).toOvm(),
    ];
    return [
      if (trip != null && points.length > 1) ...[
        if (trip.from.movedM > 1)
          MapLine(
            id: 'route-start-gap',
            points: [
              LatLng(trip.from.asked.lat, trip.from.asked.lon).toOvm(),
              points.first,
            ],
            color: color,
            width: 2,
            pattern: MapLinePattern.dotted,
          ),
        if (trip.endsShort != null || trip.to.movedM > 1)
          MapLine(
            id: 'route-rest',
            points: [points.last, to.point.toOvm()],
            color: color,
            width: 2,
            pattern: MapLinePattern.dotted,
          ),
        MapLine(
          id: 'route',
          points: points,
          color: color.withValues(alpha: 0.85),
          width: 5,
        ),
        MapMarker(
          id: 'route-start',
          position: points.first,
          color: routeStartColor,
          radius: 7,
          interactive: false,
        ),
      ],
      MapMarker(
        id: 'route-end',
        position: to.point.toOvm(),
        color: const Color(0xFFC62828),
        radius: 7,
        interactive: false,
      ),
    ];
  }

  Future<void> _openSearch(
    MeshCoreConnector connector,
    LatLng? selfPosition,
    UnitSystem units,
  ) async {
    final camera = _mapController.camera;
    final near = selfPosition != null
        ? GeoPoint(selfPosition.latitude, selfPosition.longitude)
        : camera == null
        ? null
        : GeoPoint(camera.center.latitude, camera.center.longitude);
    final pick = await Navigator.push<MapSearchPick>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(
          regions: context.read<PoiService?>()?.regions ?? const [],
          near: near,
          units: units,
        ),
      ),
    );
    if (pick == null || !mounted) return;
    final region = pick.region;
    final detail = pick.placeId == null || region == null
        ? null
        : await region.detail(pick.placeId!);
    if (!mounted) return;
    await _goTo(
      pick.name,
      LatLng(pick.point.lat, pick.point.lon),
      region,
      detail,
      connector,
      selfPosition,
      units,
    );
  }

  /// Moves to a search pick or a link in a place's text and opens its
  /// sheet: a place's own, or the position's.
  Future<void> _goTo(
    String name,
    LatLng point,
    PoiRegion? region,
    PlaceDetail? detail,
    MeshCoreConnector connector,
    LatLng? selfPosition,
    UnitSystem units,
  ) async {
    final moved = _moveTo(point, 15);
    if (detail == null || region == null) {
      _showShareMarkerAtPositionSheet(
        context: context,
        connector: connector,
        position: point,
        selfPosition: selfPosition,
        title: name,
        centerAfter: moved,
      );
      return;
    }
    await _showPlaceSheet(
      detail,
      region,
      connector,
      selfPosition,
      units,
      centerAfter: moved,
    );
  }

  Future<void> _openPlace(
    MapPlace p,
    MeshCoreConnector connector,
    LatLng? selfPosition,
    UnitSystem units,
  ) async {
    final detail = await p.region.detail(p.place.id);
    if (detail == null || !mounted) return;
    await _showPlaceSheet(detail, p.region, connector, selfPosition, units);
  }

  Future<void> _openLink(
    PoiRegion region,
    SummaryLink link,
    MeshCoreConnector connector,
    LatLng? selfPosition,
    UnitSystem units,
  ) async {
    if (link.feature) {
      final f = await region.feature(link.id);
      if (f == null || !mounted) return;
      await _goTo(
        f.name,
        LatLng(f.lat, f.lon),
        region,
        null,
        connector,
        selfPosition,
        units,
      );
      return;
    }
    final detail = await region.detail(link.id);
    if (detail == null || !mounted) return;
    await _goTo(
      detail.place.name,
      LatLng(detail.place.lat, detail.place.lon),
      region,
      detail,
      connector,
      selfPosition,
      units,
    );
  }

  Future<void> _showPlaceSheet(
    PlaceDetail detail,
    PoiRegion region,
    MeshCoreConnector connector,
    LatLng? selfPosition,
    UnitSystem units, {
    Future<void>? centerAfter,
  }) async {
    final point = LatLng(detail.place.lat, detail.place.lon);
    // An unnamed place goes by its kind ("Toilets").
    final name = detail.place.name.isEmpty
        ? poiKindLabel(context.l10n, detail.place.kind)
        : detail.place.name;
    final canRoute = _canRouteAt(point);
    await _showPointSheet(
      point,
      centerAfter: centerAfter,
      dragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (_, controller) => PlaceSheet(
          detail: detail,
          format: coordFormatOf(context.read<AppSettingsService>().settings),
          units: units,
          controller: controller,
          onRoute: canRoute
              ? () {
                  Navigator.pop(sheetContext);
                  _routeHere(name, point, selfPosition);
                }
              : null,
          onShare: () {
            Navigator.pop(sheetContext);
            _shareMarker(
              context: context,
              connector: connector,
              position: point,
              title: name,
            );
          },
          onLink: (link) {
            Navigator.pop(sheetContext);
            _openLink(region, link, connector, selfPosition, units);
          },
        ),
      ),
    );
  }

  /// The same Location dialog as the composer's tray (position, title,
  /// note), then who gets it.
  Future<void> _shareMarker({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
    String? title,
  }) async {
    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.map_connectToShareMarkers),
      );
      return;
    }
    final message = await StructuredMessageDialogs.location(
      context,
      position: position,
      title: title,
      action: context.l10n.common_continue,
    );
    if (message == null || !mounted) return;
    await _showRecipientSheet(
      // ignore: use_build_context_synchronously
      context: context,
      connector: connector,
      markerText: message.toWire(),
    );
  }

  /// Who a shared marker can go to: the chats the Chats screen lists,
  /// newest first, then the favourites it leaves out (owner, 2026-10-27).
  /// A tap sends it at once; the Public channel asks first.
  Future<void> _showRecipientSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required String markerText,
  }) async {
    if (!connector.isLoadingChannels && connector.channels.isEmpty) {
      connector.getChannels();
    }
    final drafts = context.read<UiViewStateService>().drafts;
    var query = '';

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Consumer<MeshCoreConnector>(
            builder: (consumerContext, liveConnector, child) {
              final (chats, favorites) = _shareTargets(liveConnector, drafts);
              bool shown(_ShareTarget target) {
                if (query.isEmpty) return true;
                final contact = target.contact;
                return contact != null
                    ? matchesContactQuery(contact, query)
                    : target.name.toLowerCase().contains(query);
              }

              Widget header(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
              Widget tile(_ShareTarget target) => ListTile(
                leading: Icon(target.icon, color: target.color),
                title: Text(
                  target.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: target.channel?.isPublicChannel ?? false
                    ? Text(context.l10n.channels_publicChannel)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(
                    _sendMarker(context, liveConnector, target, markerText),
                  );
                },
              );
              final shownChats = chats.where(shown).toList();
              final shownFavorites = favorites.where(shown).toList();
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                context.l10n.contacts_searchContactsNoNumber,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              query = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      if (liveConnector.isLoadingChannels)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: LinearProgressIndicator(),
                        ),
                      if (shownChats.isNotEmpty) ...[
                        header(context.l10n.chats_title),
                        ...shownChats.map(tile),
                      ],
                      if (shownFavorites.isNotEmpty) ...[
                        header(context.l10n.listFilter_favorites),
                        ...shownFavorites.map(tile),
                      ],
                      if (shownChats.isEmpty && shownFavorites.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(context.l10n.chat_searchNoMatches),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// The Chats screen's list, newest first (its rule: a contact or room
  /// with a message or a draft, and every channel), then the favourites it
  /// leaves out, by name. Repeaters and sensors take no text.
  static (List<_ShareTarget>, List<_ShareTarget>) _shareTargets(
    MeshCoreConnector connector,
    Map<String, String> drafts,
  ) {
    bool takesText(Contact c) => c.type == advTypeChat || c.type == advTypeRoom;
    final now = DateTime.now().microsecondsSinceEpoch;
    final chats = <(int, _ShareTarget)>[];
    final listed = <String>{};
    for (final contact in connector.contacts) {
      if (!takesText(contact)) continue;
      final hasMessage = connector.latestContactMessage(contact) != null;
      final hasDraft = drafts[contact.publicKeyHex]?.isNotEmpty ?? false;
      if (!hasMessage && !hasDraft) continue;
      listed.add(contact.publicKeyHex);
      // A chat with only a draft sits on top, as on the Chats screen.
      final sortKey = hasMessage
          ? connector.latestContactArrivalUs(contact)
          : now;
      chats.add((sortKey, _ShareTarget.contact(contact)));
    }
    for (final channel in connector.channels) {
      if (channel.isEmpty) continue;
      final sortKey = connector.latestChannelMessage(channel) == null
          ? 0
          : connector.latestChannelSortUs(channel);
      chats.add((sortKey, _ShareTarget.channel(channel)));
    }
    chats.sort((a, b) => b.$1.compareTo(a.$1));
    final favorites = [
      for (final contact in connector.contacts)
        if (contact.isFavorite &&
            takesText(contact) &&
            !listed.contains(contact.publicKeyHex))
          _ShareTarget.contact(contact),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ([for (final (_, target) in chats) target], favorites);
  }

  /// Sends a shared marker to [target], unless it is too long for it.
  Future<void> _sendMarker(
    BuildContext context,
    MeshCoreConnector connector,
    _ShareTarget target,
    String text,
  ) async {
    final channel = target.channel;
    final contact = target.contact;
    final int maxBytes;
    final String outbound;
    if (channel != null) {
      maxBytes = maxChannelMessageBytes(connector.selfName);
      outbound = connector.prepareChannelOutboundText(channel.index, text);
    } else {
      maxBytes = contact!.type == advTypeRoom
          ? maxRoomMessageBytes()
          : maxContactMessageBytes();
      outbound = connector.prepareContactOutboundText(contact, text);
    }
    if (utf8.encode(outbound).length > maxBytes) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(maxBytes)),
      );
      return;
    }
    if (channel == null) {
      unawaited(connector.sendMessage(contact!, text));
      return;
    }
    if (channel.isPublicChannel &&
        !await _confirmPublicShare(context, target.name)) {
      return;
    }
    unawaited(connector.sendChannelMessage(channel, text));
  }

  bool _isPublicChannel(Channel channel) {
    return channel.isPublicChannel;
  }

  Future<bool> _confirmPublicShare(
    BuildContext context,
    String channelLabel,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_publicLocationShare),
        content: Text(
          context.l10n.map_publicLocationShareConfirm(channelLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_share),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// The layers sheet's Nodes section: which kinds of node show.
  Widget _nodeLayers(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<AppSettingsService>();
    final settings = service.settings;
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget badge(Color color, IconData icon) => ColoredBox(
      color: background,
      child: Center(child: _nodeDot(color, icon)),
    );
    return MapLayerSection(
      title: l10n.mapLayers_nodes,
      children: [
        MapLayerTile(
          picture: badge(_getNodeColor(advTypeRepeater), Icons.router),
          label: l10n.map_repeaters,
          selected: settings.mapShowRepeaters,
          onTap: () => service.setMapShowRepeaters(!settings.mapShowRepeaters),
        ),
        MapLayerTile(
          picture: badge(_getNodeColor(advTypeChat), Icons.person),
          label: l10n.map_chatNodes,
          selected: settings.mapShowChatNodes,
          onTap: () => service.setMapShowChatNodes(!settings.mapShowChatNodes),
        ),
        MapLayerTile(
          picture: badge(_getNodeColor(advTypeRoom), Icons.meeting_room),
          label: l10n.map_otherNodes,
          selected: settings.mapShowOtherNodes,
          onTap: () =>
              service.setMapShowOtherNodes(!settings.mapShowOtherNodes),
        ),
        MapLayerTile(
          picture: badge(Colors.orange, Icons.flag),
          label: l10n.mapLayers_pins,
          selected: settings.mapShowMarkers,
          onTap: () => service.setMapShowMarkers(!settings.mapShowMarkers),
        ),
        MapLayerTile(
          picture: badge(
            Colors.grey.withValues(alpha: 0.55),
            Icons.not_listed_location,
          ),
          label: l10n.mapLayers_guessed,
          selected: settings.mapShowGuessedLocations,
          onTap: () => service.setMapShowGuessedLocations(
            !settings.mapShowGuessedLocations,
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_filterNodes),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: Consumer<AppSettingsService>(
            builder: (consumerContext, service, child) {
              final settings = service.settings;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: Text(context.l10n.map_showDiscoveryContacts),
                    value: settings.mapShowDiscoveryContacts,
                    onChanged: (value) {
                      service.setMapShowDiscoveryContacts(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(context.l10n.map_showOverlaps),
                    value: settings.mapShowOverlaps,
                    onChanged: (value) {
                      service.setMapShowOverlaps(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),
                  Text(
                    context.l10n.map_keyPrefix,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(context.l10n.map_filterByKeyPrefix),
                    value: settings.mapKeyPrefixEnabled,
                    onChanged: (value) {
                      service.setMapKeyPrefixEnabled(value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    initialValue: settings.mapKeyPrefix,
                    enabled: settings.mapKeyPrefixEnabled,
                    decoration: InputDecoration(
                      labelText: context.l10n.map_publicKeyPrefix,
                      hintText: 'e.g. ab12',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      service.setMapKeyPrefix(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.map_lastSeenTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeFilterLabel(settings.mapTimeFilterHours),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Slider(
                    value: _hoursToSliderValue(settings.mapTimeFilterHours),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      final hours = _sliderValueToHours(value);
                      service.setMapTimeFilterHours(hours);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  // Convert hours to slider value (0-100) with exponential scaling
  double _hoursToSliderValue(double hours) {
    if (hours == 0) return 100; // All time

    // Map hours exponentially
    // 0-24h: 0-40
    // 24h-7d: 40-60
    // 7d-30d: 60-80
    // 30d-6mo: 80-99
    // All time: 100

    if (hours <= 24) {
      return (hours / 24) * 40;
    } else if (hours <= 168) {
      // 7 days
      return 40 + ((hours - 24) / (168 - 24)) * 20;
    } else if (hours <= 720) {
      // 30 days
      return 60 + ((hours - 168) / (720 - 168)) * 20;
    } else if (hours <= 4380) {
      // 6 months
      return 80 + ((hours - 720) / (4380 - 720)) * 19;
    } else {
      return 100;
    }
  }

  // Convert slider value (0-100) to hours with exponential scaling
  double _sliderValueToHours(double value) {
    if (value >= 99.5) return 0; // All time

    if (value <= 40) {
      return (value / 40) * 24; // 0-24 hours
    } else if (value <= 60) {
      return 24 + ((value - 40) / 20) * (168 - 24); // 1-7 days
    } else if (value <= 80) {
      return 168 + ((value - 60) / 20) * (720 - 168); // 7-30 days
    } else {
      return 720 + ((value - 80) / 19) * (4380 - 720); // 30 days - 6 months
    }
  }

  String _getTimeFilterLabel(double hours) {
    if (hours == 0) return context.l10n.time_allTime;

    if (hours < 1) {
      return '${(hours * 60).round()} ${context.l10n.time_minutes}';
    } else if (hours < 24) {
      final h = hours.round();
      return '$h ${h == 1 ? context.l10n.time_hour : context.l10n.time_hours}';
    } else if (hours < 168) {
      final days = (hours / 24).round();
      return '$days ${days == 1 ? context.l10n.time_day : context.l10n.time_days}';
    } else if (hours < 720) {
      final weeks = (hours / 168).round();
      return '$weeks ${weeks == 1 ? context.l10n.time_week : context.l10n.time_weeks}';
    } else if (hours < 4380) {
      final months = (hours / 730).round();
      return '$months ${months == 1 ? context.l10n.time_month : context.l10n.time_months}';
    } else {
      return context.l10n.time_allTime;
    }
  }

  void _addToPath(BuildContext context, Contact contact, {LatLng? position}) {
    setState(() {
      final stride = context.read<MeshCoreConnector>().pathHashByteWidth;
      _pathTrace.addAll(
        PathHelper.pubKeyPrefix(contact.publicKey, stride: stride),
      );
      _pathTraceContacts.add(contact); // Add contact to path trace contacts
      if (position != null) _pathTraceGuesses[contact.publicKeyHex] = position;
      _points.add(position ?? LatLng(contact.latitude!, contact.longitude!));
    });
  }

  /// Asks the path graph for a route from me through the first tapped
  /// repeater to the second, and for its best route from there back to
  /// me, then traces out and back. With no route back known it returns
  /// the same way. The trace runs at the graph's own hash width (a trace
  /// carries its width in its flags, so the radio's path hash size does
  /// not matter), and its result is filed at that width.
  Future<void> _routeAndTrace(
    BuildContext context,
    Contact a,
    Contact b, {
    required Map<String, LatLng> guesses,
  }) async {
    final connector = context.read<MeshCoreConnector>();
    final graph = context.read<PathGraphService>().graph;
    final l10n = context.l10n;
    if (graph == null) return;
    final width = graph.hashWidthBytes;

    final result = graph.findRouteVia(
      _graphHash(graph, a),
      _graphHash(graph, b),
    );
    if (result is! RouteResult) {
      final reason = result is FloodResult
          ? floodReasonText(result.reason)
          : l10n.chat_direct;
      showDismissibleSnackBar(
        context,
        content: Text('${l10n.map_routeAndTrace}: $reason'),
      );
      return;
    }

    final back = graph.findReturnPathFromRepeater(_graphHash(graph, b));
    final roundTrip = PathHelper.outAndBackPath(
      result.pathBytes,
      back is RouteResult ? back.pathBytes : null,
      stride: width,
    );
    if (back is! RouteResult) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.map_routeBackMirrored),
      );
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PathTraceMapScreen(
          title: a.publicKeyHex == b.publicKeyHex
              ? '${l10n.map_routeAndTrace} → ${b.name}'
              : '${l10n.map_routeAndTrace} ${a.name} → ${b.name}',
          path: roundTrip,
          pathHashByteWidth: width,
          pathContacts: connector.allContacts,
          guessedPositions: guesses,
        ),
      ),
    );
    setState(() {
      _isBuildingPathTrace = false;
    });
  }

  String _graphHash(PathGraph graph, Contact c) => PathHelper.hopHex(
    PathHelper.pubKeyPrefix(c.publicKey, stride: graph.hashWidthBytes),
  );

  /// Starts a trace from [position], the radio's own, when it has one.
  void _startPath(LatLng? position) {
    if (_los != null) _closeLos();
    setState(() {
      _isBuildingPathTrace = true;
      _pathTrace.clear();
      _pathTraceContacts.clear();
      _pathTraceGuesses.clear();
      _points
        ..clear()
        ..addAll([?position]);
    });
  }

  // Opens the hex/contact path picker so a trace can be typed or built from
  // contacts without first tapping repeaters on the map. Pre-fills whatever is
  // already selected, then runs the trace on the entered path.
  Future<void> _setCustomTracePath() async {
    final connector = context.read<MeshCoreConnector>();
    final hashW = connector.pathHashByteWidth;
    final navigator = Navigator.of(context);
    final title = context.l10n.contacts_pathTrace;
    final initial = _pathTrace.isNotEmpty
        ? PathHelper.formatPathHex(_pathTrace, stride: hashW)
        : null;

    final result = await PathSelectionDialog.show(
      context,
      availableContacts: connector.allContacts,
      initialPath: initial,
      pathHashByteWidth: hashW,
    );

    if (result == null || result.isEmpty || !mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (context) => PathTraceMapScreen(
          title: title,
          path: result,
          pathHashByteWidth: hashW,
          pathContacts: connector.allContacts,
          guessedPositions: _pathTraceGuesses,
        ),
      ),
    );
    setState(() {
      _isBuildingPathTrace = false;
    });
  }

  void _removePath(BuildContext context) {
    setState(() {
      final stride = context.read<MeshCoreConnector>().pathHashByteWidth;
      final removed = _pathTraceContacts.removeLast().publicKeyHex;
      if (!_pathTraceContacts.any((c) => c.publicKeyHex == removed)) {
        _pathTraceGuesses.remove(removed);
      }
      final trimmed = PathHelper.dropLastHop(_pathTrace, stride: stride);
      _pathTrace
        ..clear()
        ..addAll(trimmed);
      _points.removeLast();
    });
  }

  void _showTraceHelp() {
    final l10n = context.l10n;
    final pathfinder = context.read<PathGraphService>().isRunning;
    Widget row(Widget icon, String title, String subtitle) => ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.map_traceHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(
                const Icon(Icons.edit_road),
                l10n.chat_setCustomPath,
                l10n.map_traceHelpCustom,
              ),
              row(
                const Icon(Icons.arrow_forward_outlined),
                l10n.map_runTrace,
                l10n.map_traceHelpRun,
              ),
              row(
                const Icon(Icons.replay),
                l10n.map_traceHelpThereAndBack,
                l10n.map_traceHelpThereAndBackSubtitle,
              ),
              if (pathfinder)
                row(
                  Icon(
                    RoutingIcon.icon,
                    color: RoutingIcon.pathfinderColor(context),
                  ),
                  l10n.map_routeAndTrace,
                  l10n.map_traceHelpPathfinder,
                ),
              row(
                const Icon(Icons.undo),
                l10n.map_removeLast,
                l10n.map_traceHelpRemoveLast,
              ),
              row(
                const Icon(Icons.close),
                l10n.common_cancel,
                l10n.map_traceHelpCancel,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildPathTraceOverlay() {
    final l10n = context.l10n;
    final isImperial =
        context.read<AppSettingsService>().settings.unitSystem ==
        UnitSystem.imperial;
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      l10n.contacts_pathTrace,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _showTraceHelp,
                    tooltip: l10n.map_traceHelpTitle,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline, size: 20),
                  ),
                ],
              ),
              if (_pathTrace.isEmpty) const SizedBox(height: 8),
              if (_pathTrace.isEmpty)
                Text(l10n.map_tapToAdd, style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              if (_pathTrace.isNotEmpty)
                Text(
                  "${l10n.path_currentPathLabel} ${formatDistance(getPathDistanceMeters(_points), isImperial: isImperial)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              SelectableText(
                PathHelper.formatPathHex(
                  _pathTrace,
                  stride: context.read<MeshCoreConnector>().pathHashByteWidth,
                ),
                style: TextStyle(fontSize: 18),
              ),
              // const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                runSpacing: 1,
                children: [
                  IconButton(
                    onPressed: _setCustomTracePath,
                    tooltip: l10n.chat_setCustomPath,
                    icon: const Icon(Icons.edit_road),
                  ),
                  if (_pathTrace.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        final hashW = context
                            .read<MeshCoreConnector>()
                            .pathHashByteWidth;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PathTraceMapScreen(
                              title: l10n.contacts_pathTrace,
                              path: Uint8List.fromList(_pathTrace),
                              pathHashByteWidth: hashW,
                              pathContacts: _pathTraceContacts,
                              guessedPositions: _pathTraceGuesses,
                            ),
                          ),
                        );
                        setState(() {
                          _isBuildingPathTrace = false;
                        });
                      },
                      tooltip: l10n.map_runTrace,
                      icon: const Icon(Icons.arrow_forward_outlined),
                    ),
                  if (_pathTrace.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        final hashW = Provider.of<MeshCoreConnector>(
                          context,
                          listen: false,
                        ).pathHashByteWidth;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PathTraceMapScreen(
                              title: l10n.contacts_pathTrace,
                              path: Uint8List.fromList(_pathTrace),
                              flipPathAround: true,
                              pathHashByteWidth: hashW,
                              pathContacts: _pathTraceContacts,
                              guessedPositions: _pathTraceGuesses,
                            ),
                          ),
                        );
                        setState(() {
                          _isBuildingPathTrace = false;
                        });
                      },
                      tooltip: l10n.map_runTraceWithReturnPath,
                      icon: const Icon(Icons.replay),
                    ),
                  if (_pathTraceContacts.length >= 2 &&
                      context.watch<PathGraphService>().isRunning)
                    IconButton(
                      onPressed: () => _routeAndTrace(
                        context,
                        _pathTraceContacts[_pathTraceContacts.length - 2],
                        _pathTraceContacts.last,
                        guesses: _pathTraceGuesses,
                      ),
                      tooltip: l10n.map_routeAndTrace,
                      icon: Icon(
                        RoutingIcon.icon,
                        color: RoutingIcon.pathfinderColor(context),
                      ),
                    ),
                  if (_pathTrace.isNotEmpty)
                    IconButton(
                      onPressed: () => _removePath(context),
                      tooltip: l10n.map_removeLast,
                      icon: const Icon(Icons.undo),
                    ),
                  if (_pathTrace.isEmpty)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isBuildingPathTrace = false;
                          _pathTrace.clear();
                          _points.clear();
                        });
                        showDismissibleSnackBar(
                          context,
                          content: Text(l10n.map_pathTraceCancelled),
                        );
                      },
                      tooltip: l10n.common_cancel,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tells [onHeight] how tall [child] is once laid out: how much of the
/// screen a bottom sheet covers. It slides in, but its height is final.
class _ReportHeight extends StatefulWidget {
  final ValueChanged<double> onHeight;
  final Widget child;

  const _ReportHeight({required this.onHeight, required this.child});

  @override
  State<_ReportHeight> createState() => _ReportHeightState();
}

class _ReportHeightState extends State<_ReportHeight> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = mounted ? context.size?.height : null;
      if (height != null) widget.onHeight(height);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A TRAX group member on the map, by the first 4 bytes of their key: their
/// TRAX location, their contact or both.
typedef _Member = ({
  String prefix,
  String name,
  Contact? contact,
  TripPosition? report,
});

/// Builds again every 30 s, so a time shown as "3m ago" keeps counting
/// while nothing else changes.
class _Ticking extends StatefulWidget {
  final WidgetBuilder builder;

  const _Ticking({required this.builder});

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// The radio's GPS position: a blue dot, or grey when it may be [old].
class _GpsDot extends StatelessWidget {
  final bool old;

  const _GpsDot({required this.old});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: old ? Colors.grey[500] : Colors.blue[600],
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
    ),
  );
}

class _MarkerPayload {
  final LatLng position;
  final String label;
  final String flags;

  _MarkerPayload({
    required this.position,
    required this.label,
    required this.flags,
  });
}

/// A chat a shared marker can go to: a contact or room, or a channel. It
/// looks as it does on the Chats screen.
class _ShareTarget {
  final Contact? contact;
  final Channel? channel;

  const _ShareTarget.contact(Contact this.contact) : channel = null;
  const _ShareTarget.channel(Channel this.channel) : contact = null;

  String get name {
    final channel = this.channel;
    if (channel != null) {
      return channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name;
    }
    return contact!.name.isEmpty ? 'Unknown' : contact!.name;
  }

  IconData get icon {
    final channel = this.channel;
    if (channel == null) {
      return contact!.type == advTypeRoom ? Icons.meeting_room : Icons.person;
    }
    if (channel.isPublicChannel) return Icons.public;
    return channel.name.startsWith('#') ? Icons.tag : Icons.lock;
  }

  Color get color => channel != null
      ? Colors.blue
      : contact!.type == advTypeRoom
      ? Colors.purple
      : Colors.green;
}

class _SharedMarker {
  final String id;
  final LatLng position;
  final String label;
  final String flags;
  final String fromName;
  final String sourceLabel;
  final bool isChannel;
  final bool isPublicChannel;
  final DateTime? sentAt;

  /// An SOS: its latest repeat, and its cancel.
  final DateTime? updatedAt;
  final DateTime? cancelledAt;

  _SharedMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.flags,
    required this.fromName,
    required this.sourceLabel,
    required this.isChannel,
    required this.isPublicChannel,
    this.sentAt,
    this.updatedAt,
    this.cancelledAt,
  });

  bool get isSos => flags == 'sos';

  /// What the map redraws on: an SOS moves and closes under one id.
  String get signature =>
      '$id|${position.latitude},${position.longitude}|'
      '${updatedAt?.millisecondsSinceEpoch}|${cancelledAt != null}';
}

/// A trip on the water on the main map, kept as the route on land is:
/// where to and from (null: your position), the trip found, and from where
/// and when.
class _WaterRoute {
  ({String name, LatLng point})? to;
  LatLng? from;
  WaterTrip? trip;
  LatLng? foundFrom;
  DateTime? foundAt;
  bool finding = false;
  String? error;

  /// Why there's no trip, where the data says.
  WaterRoutingProblem? problem;
  int generation = 0;

  /// The trip this map last kept in [UiViewStateService.mapWaterRoute], or
  /// took from it.
  MapRoute<WaterTrip>? kept;

  /// The Map tab opened on a trip started over a chat: shown whole.
  bool unseen = false;

  /// Takes [kept] as this trip: one still being found is dropped.
  void take(MapRoute<WaterTrip>? kept) {
    generation++;
    to = kept == null ? null : (name: kept.name, point: kept.to.toLatLong2());
    from = kept?.from?.toLatLong2();
    trip = kept?.result;
    foundFrom = kept?.foundFrom?.toLatLong2();
    foundAt = kept?.foundAt;
    finding = false;
    error = null;
    problem = null;
  }

  void clear() => take(null);
}
