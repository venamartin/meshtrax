import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/guessed_location_helper.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:path_graph/path_graph.dart'
    show PathGraph, RouteResult, FloodResult;
import 'package:meshtrax/widgets/app_bar.dart';
import 'package:meshtrax/widgets/gps_status_button.dart';
import 'package:meshtrax/widgets/location_sharing_button.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/latlong2.dart';
import 'package:traxmap/traxmap.dart' hide LatLng, LatLngBounds;
import 'package:traxpoi/traxpoi.dart'
    show GeoPoint, PlaceDetail, PoiRegion, SummaryLink;
import 'package:traxroute/traxroute.dart' as trax show PathType, RouteResult;

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/app_settings.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../helpers/map_places.dart';
import '../helpers/poi_kinds.dart';
import '../helpers/path_helper.dart';
import '../helpers/position_text.dart';
import '../services/map_marker_service.dart';
import '../services/map_packs_service.dart';
import '../services/poi_service.dart';
import '../services/routing_service.dart';
import '../services/ui_view_state_service.dart';
import '../utils/app_logger.dart';
import '../utils/contact_search.dart';
import '../utils/platform_info.dart';
import '../utils/route_transitions.dart';
import '../widgets/app_map.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_layers_sheet.dart';
import '../widgets/map_legend_sheet.dart';
import '../widgets/place_marker.dart';
import '../widgets/place_sheet.dart';
import '../widgets/route_panel.dart';
import '../widgets/quick_switch_bar.dart';
import '../icons/los_icon.dart';
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
import '../services/short_link_resolver.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';
import 'line_of_sight_map_screen.dart';
import 'map_search_screen.dart';
import 'offline_maps_screen.dart';

class MapScreen extends StatefulWidget {
  /// A point to show and pin, e.g. a shared POI opened from a chat. The
  /// screen then has a back button and no quick-switch bar.
  final LatLng? highlightPosition;
  final String? highlightLabel;

  /// MapLibre zoom for [highlightPosition].
  final double highlightZoom;
  final bool hideBackButton;

  /// Pick mode: a tap or long press pops the screen with the chosen LatLng.
  final bool pickPosition;

  const MapScreen({
    super.key,
    this.highlightPosition,
    this.highlightLabel,
    this.highlightZoom = 14.0,
    this.hideBackButton = false,
    this.pickPosition = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // MapLibre zoom from which node labels show.
  static const double _labelMinZoom = 13.0;

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

  // Offline routing: where to and from (null: your position), the path
  // type, and the route found.
  ({String name, LatLng point})? _routeTo;
  LatLng? _routeFrom;
  trax.PathType _pathType = trax.PathType.hiking;
  trax.RouteResult? _route;
  bool _routing = false;
  String? _routeError;
  int _routeGeneration = 0;

  // Points of interest in view, and whether the region in view has them
  // (the map then drops its own icons for the same kinds).
  List<MapPlace> _places = const [];
  Set<MapPlace> _namedPlaces = const {};
  bool _placesHere = false;
  Timer? _placesTimer;
  int _placesGeneration = 0;
  late final MeshCoreConnector _connector;

  @override
  void initState() {
    super.initState();
    _loadRemovedMarkers();
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
  void dispose() {
    _saveCamera?.cancel();
    _placesTimer?.cancel();
    _connector.removeSelfPositionViewer();
    unawaited(_channelLatest?.cancel());
    _mapController.dispose();
    super.dispose();
  }

  /// My location: the radio's GPS position. With the GPS off, offers to turn
  /// it on, since a first fix can take minutes.
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
  }

  void _onCameraChanged(MapCamera camera) {
    _saveCamera?.cancel();
    _saveCamera = Timer(const Duration(seconds: 1), () {
      if (mounted) context.read<UiViewStateService>().setMapCamera(camera);
    });
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
    return Consumer2<MeshCoreConnector, AppSettingsService>(
      builder: (context, connector, settingsService, child) {
        final settings = settingsService.settings;
        final allContacts = connector.allContacts;

        final contacts = settings.mapShowDiscoveryContacts
            ? allContacts
            : allContacts.where((c) => c.isActive).toList();

        final highlightPosition = widget.highlightPosition;
        _refreshDirectMarkersIfChanged(connector);
        final sharedMarkers = settings.mapShowMarkers
            ? _channelMarkers
                  .where(
                    (marker) =>
                        !_hiddenMarkerIds.contains(marker.id) &&
                        !_removedMarkerIds.contains(marker.id),
                  )
                  .toList()
            : <_SharedMarker>[];

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

        // Calculate center and zoom of all nodes (flutter_map zooms; the map
        // takes MapLibre zooms, one lower).
        LatLng center = const LatLng(0, 0);
        double initialZoom = 10.0;
        final hasRealPositions =
            contactsWithLocation.isNotEmpty || sharedMarkers.isNotEmpty;
        final hasMapContent =
            hasRealPositions ||
            guessedLocations.isNotEmpty ||
            highlightPosition != null;
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
        if (highlightPosition != null) {
          center = highlightPosition;
          zoom = widget.highlightZoom;
        }
        final lastCamera = context.read<UiViewStateService>().mapCamera;
        final startCamera = hasMapContent || lastCamera == null
            ? MapCamera(center: center.toOvm(), zoom: zoom)
            : lastCamera;

        // Re center map after removed markers have loaded
        if (!_hasInitializedMap && _removedMarkersLoaded) {
          _hasInitializedMap = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (hasMapContent) {
              _mapController.move(center.toOvm(), zoom: zoom);
            } else if (lastCamera == null) {
              _showLatestDownloadedMap();
            }
          });
        }

        // A radio with no position reports 0, 0.
        final selfPosition =
            connector.hasValidLocation(
              connector.selfLatitude,
              connector.selfLongitude,
            )
            ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
            : null;
        // A pushed map (a shared point, or picking one) goes back where it
        // came from; picking without a point to start from is no exception.
        final isPoiLink = highlightPosition != null || widget.pickPosition;
        final allowBack = !connector.isConnected || isPoiLink;
        final mapDark = settings.mapTheme == 'dark';
        final showPlaces =
            settings.mapPlaces && !widget.pickPosition && !_isBuildingPathTrace;

        return PopScope(
          // Back closes a route before anything else.
          canPop: allowBack && _routeTo == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _routeTo != null) _clearRoute();
          },
          child: Scaffold(
            appBar: AppBar(
              // The map needs no name, and the room goes to the map; picking
              // a position still says what to do.
              title: AppBarTitle(
                widget.pickPosition ? context.l10n.map_pickPositionHint : '',
                subtitle: false,
              ),
              centerTitle: true,
              automaticallyImplyLeading: isPoiLink,
              actions: [
                if (!widget.pickPosition) ...[
                  const GpsStatusButton(),
                  const LocationSharingButton(),
                ],
                if (!_isBuildingPathTrace && !widget.pickPosition)
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: context.l10n.map_search,
                    onPressed: () => _openSearch(
                      connector,
                      selfPosition,
                      settings.unitSystem,
                    ),
                  ),
                if (!_isBuildingPathTrace)
                  IconButton(
                    icon: const Icon(Icons.radar),
                    onPressed: () => _startPath(selfPosition),
                    tooltip: context.l10n.contacts_pathTrace,
                  ),
                if (!_isBuildingPathTrace)
                  IconButton(
                    icon: const LosIcon(),
                    onPressed: () {
                      final candidates = <LineOfSightEndpoint>[];
                      if (selfPosition != null) {
                        candidates.add(
                          LineOfSightEndpoint(
                            label: context.l10n.pathTrace_you,
                            point: selfPosition,
                            color: Colors.teal,
                            icon: Icons.person_pin_circle,
                          ),
                        );
                      }
                      final sortedContacts = List.of(contactsWithLocation)
                        ..sort(
                          (a, b) => a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          ),
                        );
                      for (final c in sortedContacts) {
                        candidates.add(
                          LineOfSightEndpoint(
                            label: c.name,
                            point: LatLng(c.latitude!, c.longitude!),
                            color: _getNodeColor(c.type),
                            icon: _getNodeIcon(c.type),
                          ),
                        );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LineOfSightMapScreen(
                            title: context.l10n.map_losScreenTitle,
                            candidates: candidates,
                          ),
                        ),
                      );
                    },
                    tooltip: context.l10n.map_lineOfSight,
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (!PlatformInfo.isWeb)
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.download_for_offline_outlined),
                            const SizedBox(width: 8),
                            Text(context.l10n.offlineMaps_title),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfflineMapsScreen(),
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
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            body: Stack(
              children: [
                AppMap(
                  controller: _mapController,
                  initialCamera: startCamera,
                  controlsWidth: MapControls.width,
                  onTap: widget.pickPosition
                      ? (position) =>
                            Navigator.pop(context, position.toLatLong2())
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
                  appPlaces: showPlaces && _placesHere,
                  overlays: [
                    if (showPlaces)
                      for (final p in _places)
                        placeMarker(
                          p,
                          named: _namedPlaces.contains(p),
                          dark: mapDark,
                          onTap: () => _openPlace(
                            p,
                            connector,
                            selfPosition,
                            settings.unitSystem,
                          ),
                        ),
                    ..._routeOverlays(),
                    if (_isBuildingPathTrace && _points.length > 1)
                      MapLine(
                        id: 'path-trace',
                        points: _points.toOvm(),
                        color: Colors.blueAccent,
                        width: 4,
                      ),
                    if (highlightPosition != null)
                      MapMarker(
                        id: 'highlight',
                        position: highlightPosition.toOvm(),
                        size: const Size(40, 40),
                        anchor: Alignment.bottomCenter,
                        interactive: false,
                        label: widget.highlightLabel,
                        child: Icon(
                          Icons.location_on_outlined,
                          color: Colors.red[600],
                          size: 34,
                        ),
                      ),
                    ..._buildGuessedMarkers(guessedLocations),
                    ..._buildMarkers(
                      contactsWithLocation,
                      settings,
                      connector.pathHashByteWidth,
                    ),
                    ...sharedMarkers.map(_buildSharedMarker),
                    // The GPS's live position is a blue dot; a position typed
                    // into the radio is the "You" pin.
                    if (selfPosition != null && connector.gpsOn)
                      MapMarker(
                        id: 'self',
                        position: selfPosition.toOvm(),
                        size: const Size(24, 24),
                        interactive: false,
                        child: const _GpsDot(),
                      )
                    else if (selfPosition != null)
                      MapMarker(
                        id: 'self',
                        position: selfPosition.toOvm(),
                        size: const Size(40, 40),
                        interactive: false,
                        label: context.l10n.pathTrace_you,
                        labelMinZoom: _labelMinZoom,
                        child: _nodeDot(Colors.teal, Icons.person_pin_circle),
                      ),
                  ],
                ),
                if (!_isBuildingPathTrace)
                  _buildLegend(
                    contacts,
                    settings,
                    connector.pathHashByteWidth,
                    sharedMarkers.length,
                    guessedLocations.length,
                  ),
                if (_isBuildingPathTrace) _buildPathTraceOverlay(),
              ],
            ),
            bottomSheet: _routeTo == null
                ? null
                : RoutePanel(
                    destination: _routeTo!.name,
                    pathType: _pathType,
                    onPathType: (type) {
                      setState(() => _pathType = type);
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
                  ),
            bottomNavigationBar: isPoiLink
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
              onLayers: () => showMapLayersSheet(
                context,
                places: !widget.pickPosition,
                extra: _nodeLayers,
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

  Widget _buildLegend(
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
    return Positioned(
      top: 16,
      right: 16,
      child: MapLegendButton(
        counts: () {
          final located = count(noLocations: false);
          return (
            located: located,
            unlocated: count(noLocations: true) - located,
            pins: markerCount,
            guessed: guessedCount,
          );
        },
      ),
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
          final id = _buildMarkerId(
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
            ),
          );
        }
      }
      appLogger.perf('map marker scan over $scanned candidate messages', sw);
      if (!mounted) return;
      final newIds = markers.map((m) => m.id).toSet();
      final oldIds = _channelMarkers.map((m) => m.id).toSet();
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
    final parsed = StructuredMessage.parse(
      text,
      resolveShortLink: ShortLinkResolver.instance.cached,
    );
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
      SosMessage m => (m.position, m.text, 'sos'),
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
    onTap: () => _showMarkerInfo(marker),
    child: _nodeDot(
      marker.flags == 'sos'
          ? Colors.red
          : marker.isChannel
          ? (marker.isPublicChannel ? Colors.orange : Colors.purple)
          : Colors.blue,
      Icons.flag,
      padding: 6,
    ),
  );

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
              _buildInfoRow('Public Key', contact.publicKeyHex),
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
  }) {
    final routing = context.read<RoutingService?>();
    final canRoute =
        routing != null &&
        routing.available &&
        routing.offeredAt((lat: position.latitude, lon: position.longitude));
    final format = coordFormatOf(context.read<AppSettingsService>().settings);
    final lines = positionLines(position.latitude, position.longitude, format);
    final name = title ?? lines.first;
    // What's set already, so it's clear whether a route goes from or to.
    final l10n = context.l10n;
    final to = _routeTo;
    final from = _routeFrom;
    final startNow = from != null
        ? l10n.route_startNow(
            positionLines(from.latitude, from.longitude, format).first,
          )
        : to != null
        ? l10n.route_startNowYou
        : null;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
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
    );
  }

  void _routeHere(String name, LatLng to, LatLng? selfPosition) {
    final routing = context.read<RoutingService?>();
    if (routing == null || !routing.hasRoutingData) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.route_noData),
      );
      return;
    }
    setState(() => _routeTo = (name: name, point: to));
    unawaited(_findRoute(selfPosition));
  }

  void _routeFromHere(LatLng from, LatLng? selfPosition) {
    setState(() => _routeFrom = from);
    if (_routeTo != null) {
      unawaited(_findRoute(selfPosition));
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
      return;
    }
    setState(() {
      _routing = true;
      _routeError = null;
    });
    final noRoute = context.l10n.route_none;
    try {
      final r = await routing.route(
        (lat: from.latitude, lon: from.longitude),
        (lat: to.point.latitude, lon: to.point.longitude),
        _pathType,
        options: context.read<AppSettingsService>().settings.routeOptions,
      );
      if (!mounted || generation != _routeGeneration) return;
      setState(() {
        _route = r;
        _routing = false;
      });
      _mapController.fitPoints(
        [
          for (final p in r.points) LatLng(p.lat, p.lon).toOvm(),
          to.point.toOvm(),
        ],
        // Clear of the route panel, which covers the bottom of the map.
        padding: const EdgeInsets.fromLTRB(48, 48, 48 + MapControls.width, 320),
      );
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
  Future<void> _moveTo(LatLng point, double zoom) async {
    _mapController.move(point.toOvm(), zoom: zoom);
    for (var i = 0; i < 20 && mounted; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if ((_mapController.camera?.zoom ?? zoom) >= zoom - 0.01) return;
      _mapController.move(point.toOvm(), zoom: zoom);
    }
  }

  void _clearRoute() => setState(() {
    _routeGeneration++;
    _routeTo = null;
    _routeFrom = null;
    _route = null;
    _routing = false;
    _routeError = null;
  });

  List<MapOverlay> _routeOverlays() {
    final to = _routeTo;
    if (to == null) return const [];
    final r = _route;
    final color = routeColor(context);
    return [
      if (r != null) ...[
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
          color: const Color(0xFF2E7D32),
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
    unawaited(_moveTo(point, 15));
    if (detail == null || region == null) {
      _showShareMarkerAtPositionSheet(
        context: context,
        connector: connector,
        position: point,
        selfPosition: selfPosition,
        title: name,
      );
      return;
    }
    await _showPlaceSheet(detail, region, connector, selfPosition, units);
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
    UnitSystem units,
  ) async {
    final point = LatLng(detail.place.lat, detail.place.lon);
    // An unnamed place goes by its kind ("Toilets").
    final name = detail.place.name.isEmpty
        ? poiKindLabel(context.l10n, detail.place.kind)
        : detail.place.name;
    final routing = context.read<RoutingService?>();
    final canRoute =
        routing != null &&
        routing.available &&
        routing.offeredAt((lat: detail.place.lat, lon: detail.place.lon));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
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
    bool takesText(Contact c) =>
        c.type == advTypeChat || c.type == advTypeRoom;
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
      final sortKey = hasMessage ? connector.latestContactArrivalUs(contact) : now;
      chats.add((sortKey, _ShareTarget.contact(contact)));
    }
    for (final channel in connector.channels) {
      if (channel.isEmpty) continue;
      final sortKey = connector.latestChannelMessage(channel) == null
          ? 0
          : connector.latestChannelArrivalUs(channel);
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

/// The radio's live GPS position: a blue dot.
class _GpsDot extends StatelessWidget {
  const _GpsDot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.blue[600],
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

  _SharedMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.flags,
    required this.fromName,
    required this.sourceLabel,
    required this.isChannel,
    required this.isPublicChannel,
  });
}
