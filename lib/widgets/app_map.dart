import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../screens/offline_maps_screen.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import '../utils/format_bytes.dart';
import 'charts_notice_dialog.dart';

/// The map every MeshTrax map screen draws, with the credits the data's
/// licences require. Charts open the "Not for navigation" dialog once a run
/// (not from [compact] maps).
///
/// Everything drawn works without signal: downloaded maps and, where none
/// is downloaded, the base map bundled with the app, down to towns and
/// major roads. Past the base map's detail the map stops zooming in and
/// offers a "Download a region for detail" card. Unless the user turns it
/// off, a teal outline marks the downloaded areas of the map that's showing.
///
/// The map, contours and light/dark come from the user's settings unless a
/// screen overrides them. See docs/offline-maps-roadmap.md, "App
/// architecture".
class AppMap extends StatefulWidget {
  final List<MapOverlay> overlays;
  final OfflineMapController? controller;
  final MapCamera? initialCamera;
  final MapFit? initialFit;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;
  final ValueChanged<MapCamera>? onCameraChanged;

  /// Overrides the map chosen in settings.
  final MapType? mapType;

  /// Overrides the contours setting.
  final bool? contours;

  /// A small map (e.g. in a dialog): no "Download a region" card.
  final bool compact;

  /// Width of the screen's map buttons at the right edge: the offline card
  /// sits beside them rather than above.
  final double controlsWidth;

  /// The downloaded areas' outline.
  static const areaColor = Color(0xFF00897B);

  const AppMap({
    super.key,
    this.overlays = const [],
    this.controller,
    this.initialCamera,
    this.initialFit,
    // About a continent on a phone, as far out as the world map is drawn
    // (Martin).
    this.minZoom = 2,
    this.maxZoom = 17,
    this.onTap,
    this.onLongPress,
    this.onCameraChanged,
    this.mapType,
    this.contours,
    this.compact = false,
    this.controlsWidth = 0,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  /// Where no region is downloaded, the map stops zooming in here: the
  /// base map's detail ends (about 25 km across a phone; Martin).
  static const _baseMapZoom = 10.0;

  /// Whether installed packs cover the view centre; null until known.
  bool? _covered;

  /// The zoom cap while [_covered] is false: the base map's detail, or the
  /// zoom the view had when it left the downloaded regions, so panning off
  /// one never zooms the map out.
  double _uncoveredMaxZoom = _baseMapZoom;
  double _zoom = 0;
  MapStyleState? _style;

  /// Whether the camera has settled at the zoom cap, where the "Download a
  /// region" card explains why the map stops zooming in.
  bool _atZoomStop = false;

  /// The downloadable region at the view centre, once the camera settles.
  String? _regionPath;

  /// The NOAA chart areas at the view centre, once the camera settles.
  List<ChartArea> _chartsHere = const [];
  Timer? _settle;

  /// The downloaded areas' outlines plus the screen's overlays, kept while
  /// their inputs don't change so the map doesn't rebuild its layers.
  var _overlays = const <MapOverlay>[];
  Object? _overlaysKey;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _onCameraChanged(MapCamera camera) {
    _zoom = camera.zoom;
    widget.onCameraChanged?.call(camera);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final maps = context.read<MapPacksService>();
      final path = maps.regions?.regionAt(camera.center)?.path;
      final charts = maps.chartAreas?.areasAt(camera.center) ?? const [];
      final atZoomStop = camera.zoom >= _uncoveredMaxZoom - 0.5;
      if (path != _regionPath ||
          !listEquals(charts, _chartsHere) ||
          atZoomStop != _atZoomStop) {
        setState(() {
          _regionPath = path;
          _chartsHere = charts;
          _atZoomStop = atZoomStop;
        });
      }
    });
  }

  List<MapOverlay> _withAreas(
    MapPacksService maps, {
    required MapType type,
    required bool outline,
  }) {
    final key = (
      widget.overlays,
      type,
      outline,
      maps.installed,
      maps.regions,
      maps.chartAreas,
    );
    if (key != _overlaysKey) {
      _overlaysKey = key;
      _overlays = [
        if (outline)
          for (final MapEntry(key: path, value: polygons)
              in maps.downloadedAreas(type).entries)
            for (final (i, polygon) in polygons.indexed)
              if (polygon.isNotEmpty)
                MapPolygon(
                  id: 'downloaded-area:$path:$i',
                  points: polygon.first,
                  holes: polygon.sublist(1),
                  fillColor: Colors.transparent,
                  strokeColor: AppMap.areaColor,
                  strokeWidth: 3,
                ),
        ...widget.overlays,
      ];
    }
    return _overlays;
  }

  @override
  Widget build(BuildContext context) {
    final maps = context.watch<MapPacksService>();
    final settings = context.select<AppSettingsService, AppSettings>(
      (s) => s.settings,
    );
    final type =
        widget.mapType ?? MapType.parse(settings.mapType) ?? MapType.osm;
    final dark = settings.mapTheme == 'dark';
    final styleId = maps.styleId(type, dark: dark);
    if (styleId == null) return const SizedBox.expand();

    final style = _style;
    final credits = [...?style?.credits, ...?style?.notices];
    // Charts say at any zoom that none is drawn here; the street and topo
    // maps have the base map until it stops zooming in.
    final showCard =
        !widget.compact &&
        _covered == false &&
        (type == MapType.charts || _atZoomStop);

    return Stack(
      children: [
        OfflineMapView(
          styleId: styleId,
          styleRegistry: maps.styles,
          packs: maps.mapPacks(
            contours: widget.contours ?? settings.mapContours,
            hillShading: settings.mapHillShading,
          ),
          units: settings.unitSystem == UnitSystem.imperial
              ? Units.imperial
              : Units.metric,
          controller: widget.controller,
          initialCamera: widget.initialCamera,
          initialFit: widget.initialFit,
          minZoom: widget.minZoom,
          maxZoom: _covered == false
              ? math.min(widget.maxZoom, _uncoveredMaxZoom)
              : widget.maxZoom,
          overlays: _withAreas(
            maps,
            type: type,
            outline: !widget.compact && settings.mapDownloadedAreas,
          ),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onCameraChanged: _onCameraChanged,
          onCoverageChanged: (covered) => setState(() {
            _covered = covered;
            if (!covered) {
              _uncoveredMaxZoom = math.max(_baseMapZoom, _zoom);
              _atZoomStop = _zoom >= _uncoveredMaxZoom - 0.5;
            }
          }),
          onStyleLoaded: (s) {
            setState(() => _style = s);
            // Mini maps draw charts too, but the notice is for the map
            // screens, not a pop-up over a chat or a dialog.
            if (s.disclaimer != null && !widget.compact) {
              unawaited(showChartsNoticeIfNeeded(context));
            }
          },
        ),
        if (showCard)
          Positioned(
            left: 8,
            // Beside the screen's map buttons and above the credits chip,
            // or clear of the screen's floating action button.
            right: widget.controlsWidth > 0 ? widget.controlsWidth : 8,
            bottom: widget.controlsWidth > 0 ? 40 : 88,
            child: Center(
              child: type == MapType.charts
                  ? _NoCharts(areas: _chartsHere)
                  : _NoOfflineMap(regionPath: _regionPath),
            ),
          ),
        if (credits.isNotEmpty)
          Positioned(
            left: 8,
            bottom: 8,
            child: AttributionChip(credits: credits, dark: dark),
          ),
      ],
    );
  }
}

/// Where the base map stops zooming in: what to download for detail.
class _NoOfflineMap extends StatelessWidget {
  final String? regionPath;
  const _NoOfflineMap({required this.regionPath});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    final units = context.select<AppSettingsService, UnitSystem>(
      (s) => s.settings.unitSystem,
    );
    final region = regionPath == null ? null : maps.regions?[regionPath!];
    final packs = region == null
        ? const <PackIndexEntry>[]
        : maps.defaultSelection(region.path, units);
    final size = packs.fold(0, (sum, e) => sum + e.bytes);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(l10n.map_downloadForDetail),
          subtitle: Text(
            packs.isEmpty
                ? l10n.offlineMaps_title
                : l10n.map_downloadRegion(region!.name, formatBytes(size)),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OfflineMapsScreen(
                initialRegionPath: packs.isEmpty ? null : region!.path,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// On the Charts map, where no chart is drawn: why, and which chart area
/// to download.
class _NoCharts extends StatelessWidget {
  final List<ChartArea> areas;
  const _NoCharts({required this.areas});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    // Downloaded, but nothing drawn: charts start at closer zooms.
    if (areas.any((a) => maps.installedRegions.contains(a.packRegion))) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(l10n.map_zoomInForCharts),
        ),
      );
    }
    final offers = [
      for (final a in areas)
        if (maps.chartPackOf(a.packRegion) case final e?) (a, e),
    ];
    // One of them already on its way: offer no neighbour meanwhile.
    final (
      area,
      entry,
    ) = offers.any((o) => maps.statusOf(o.$2) != PackStatus.available)
        ? (null, null)
        : offers.firstOrNull ?? (null, null);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(l10n.map_noCharts),
          subtitle: Text(
            area == null || entry == null
                ? l10n.offlineMaps_title
                : l10n.map_downloadRegion(
                    l10n.offlineMaps_chartsName(area.name),
                    formatBytes(entry.bytes),
                  ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => area == null
                  ? const OfflineMapsScreen(initialTab: OfflineMapsTab.charts)
                  : OfflineMapsScreen(initialChartArea: area.packRegion),
            ),
          ),
        ),
      ),
    );
  }
}
