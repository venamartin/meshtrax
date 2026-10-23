import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../screens/offline_maps_screen.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/format_bytes.dart';
import 'charts_notice_dialog.dart';

/// Whether maps are in Online mode (the Online | Offline switch): `map_source`,
/// where `auto` is online until a street or topo map is downloaded (charts
/// or contours alone leave the standard map with nothing to draw).
bool mapIsOnline(AppSettings settings, MapPacksService maps) =>
    switch (settings.mapSource) {
      'online' => true,
      'offline' => false,
      _ => !maps.installed.any(
        (p) => p.kind == PackKind.osm || p.kind == PackKind.base,
      ),
    };

/// The map every MeshTrax map screen draws, with the credits the data's
/// licences require. Charts open the "Not for navigation" dialog once a run.
///
/// An Online | Offline switch picks where the map comes from. Offline shows
/// exactly what works without signal: downloaded maps, the bundled world
/// map, and a "Download a region for detail" card where no region is
/// downloaded, where the map also stops zooming in. Online fills everything not downloaded
/// with online OpenStreetMap tiles. Either way, unless the user turns it off,
/// a teal outline marks the downloaded areas of the map that's showing;
/// Online it's filled too, to set them apart from the online tiles.
///
/// The map, contours and light/dark come from the user's settings (in
/// Offline mode; Online it's the standard light map) unless a screen
/// overrides them. See docs/offline-maps-roadmap.md, "App architecture".
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

  /// A small map (e.g. in a dialog): it follows the Online | Offline setting
  /// without showing the switch or the "Download a region" card.
  final bool compact;

  /// Width of the screen's map buttons at the right edge: the offline card
  /// sits beside them rather than above.
  final double controlsWidth;

  /// The downloaded areas' outline, and its fill in Online mode.
  static const areaColor = Color(0xFF00897B);
  static const areaFill = Color(0x3300897B);

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
  /// Offline, where no region is downloaded, the map stops zooming in here:
  /// the world map's detail ends, and region packs start, at zoom 6.
  static const _worldDetailZoom = 6.0;

  /// Whether installed packs cover the view centre; null until known.
  bool? _covered;

  /// The zoom cap while [_covered] is false: the world map's detail, or the
  /// zoom the view had when it left the downloaded regions, so panning off
  /// one never zooms the map out.
  double _uncoveredMaxZoom = _worldDetailZoom;
  double _zoom = 0;
  MapStyleState? _style;
  TileCoverage? _coverage;

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
      if (path != _regionPath || !listEquals(charts, _chartsHere)) {
        setState(() {
          _regionPath = path;
          _chartsHere = charts;
        });
      }
    });
  }

  List<MapOverlay> _withAreas(
    MapPacksService maps, {
    required MapType type,
    required bool online,
    required bool outline,
  }) {
    final key = (
      widget.overlays,
      type,
      online,
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
                  // Offline, everything drawn is downloaded, so a fill
                  // would only tint the map.
                  fillColor: online ? AppMap.areaFill : Colors.transparent,
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
    // Online, the whole map has the online map's look: map types, dark and
    // contours come from downloaded packs, so they're Offline mode's.
    final online = mapIsOnline(settings, maps);
    final type = online
        ? MapType.osm
        : widget.mapType ?? MapType.parse(settings.mapType) ?? MapType.osm;
    final dark = !online && settings.mapTheme == 'dark';
    final styleId = maps.styleId(type, dark: dark);
    if (styleId == null) return const SizedBox.expand();

    final style = _style;
    final credits = [
      if (online) '© OpenStreetMap contributors',
      ...?style?.credits,
      ...?style?.notices,
    ];
    final coverage = _coverage;

    return Stack(
      children: [
        OfflineMapView(
          styleId: styleId,
          styleRegistry: maps.styles,
          packs: maps.mapPacks(
            contours: !online && (widget.contours ?? settings.mapContours),
            hillShading: !online && settings.mapHillShading,
            // Online, the online tiles show the world.
            world: !online,
          ),
          units: settings.unitSystem == UnitSystem.imperial
              ? Units.imperial
              : Units.metric,
          controller: widget.controller,
          initialCamera: widget.initialCamera,
          initialFit: widget.initialFit,
          minZoom: widget.minZoom,
          maxZoom: !online && _covered == false
              ? math.min(widget.maxZoom, _uncoveredMaxZoom)
              : widget.maxZoom,
          overlays: _withAreas(
            maps,
            type: type,
            online: online,
            outline: !widget.compact && settings.mapDownloadedAreas,
          ),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onCameraChanged: _onCameraChanged,
          baseLayers: [
            if (online && coverage != null)
              _OnlineTiles(key: ObjectKey(coverage), coverage: coverage),
          ],
          onCoverageChanged: (covered) => setState(() {
            _covered = covered;
            if (!covered) {
              _uncoveredMaxZoom = math.max(_worldDetailZoom, _zoom);
            }
          }),
          onTileCoverage: (coverage) => setState(() => _coverage = coverage),
          onStyleLoaded: (s) {
            setState(() => _style = s);
            if (s.disclaimer != null) {
              unawaited(showChartsNoticeIfNeeded(context));
            }
          },
        ),
        if (!widget.compact)
          Positioned(top: 8, left: 8, child: _SourceSwitch(online: online)),
        if (!widget.compact && !online && _covered == false)
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

/// Online | Offline: where the map comes from.
class _SourceSwitch extends StatelessWidget {
  final bool online;
  const _SourceSwitch({required this.online});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: true, label: Text(l10n.map_sourceOnline)),
        ButtonSegment(value: false, label: Text(l10n.map_sourceOffline)),
      ],
      selected: {online},
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface
            .withValues(alpha: 0.9),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged: (selected) => context
          .read<AppSettingsService>()
          .setMapSource(selected.single ? 'online' : 'offline'),
    );
  }
}

/// Offline, where nothing downloaded is drawn: why, and what to download.
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

    // Downloaded, but nothing drawn: below the packs' lowest zoom.
    if (region != null && maps.installedRegions.contains(region.path)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(l10n.map_zoomInForOfflineMap),
        ),
      );
    }
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

/// Offline on the Charts map, where no chart is drawn: why, and which
/// chart area to download.
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

/// Online OpenStreetMap tiles, cached as viewed, in the gaps the downloaded
/// packs leave.
class _OnlineTiles extends StatelessWidget {
  final TileCoverage coverage;
  const _OnlineTiles({super.key, required this.coverage});

  @override
  Widget build(BuildContext context) => fm.TileLayer(
    urlTemplate: kMapTileUrlTemplate,
    userAgentPackageName: MapTileCacheService.userAgentPackageName,
    tileProvider: _GapTileProvider(
      context.read<MapTileCacheService>().tileProvider,
      coverage,
    ),
    maxNativeZoom: 19,
  );
}

/// [online]'s tiles, except where [coverage] says the packs draw the tile:
/// those are left transparent and never fetched.
class _GapTileProvider extends fm.TileProvider {
  final fm.TileProvider online;
  final TileCoverage coverage;
  _GapTileProvider(this.online, this.coverage);

  @override
  ImageProvider getImage(
    fm.TileCoordinates coordinates,
    fm.TileLayer options,
  ) => _GapImage(this, coordinates, options);
}

class _GapImage extends ImageProvider<_GapImage> {
  final _GapTileProvider provider;
  final fm.TileCoordinates coordinates;
  final fm.TileLayer options;
  const _GapImage(this.provider, this.coordinates, this.options);

  static final Future<ui.Image> _blank = () {
    final recorder = ui.PictureRecorder();
    Canvas(recorder);
    return recorder.endRecording().toImage(1, 1);
  }();

  @override
  Future<_GapImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_GapImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_load());

  Future<ImageInfo> _load() async {
    final c = coordinates;
    if (await provider.coverage.covers(c.z, c.x, c.y)) {
      return ImageInfo(image: (await _blank).clone());
    }
    final done = Completer<ImageInfo>();
    final stream = provider.online
        .getImage(c, options)
        .resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, _) {
        stream.removeListener(listener);
        done.complete(image);
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        done.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  @override
  bool operator ==(Object other) =>
      other is _GapImage &&
      identical(other.provider.coverage, provider.coverage) &&
      other.coordinates == coordinates;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(provider.coverage), coordinates);
}
