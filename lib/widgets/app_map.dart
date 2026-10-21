import 'dart:async';
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

/// The map every MeshTrax map screen draws, with the credits (and chart
/// disclaimer) the data's licences require.
///
/// An Online | Offline switch picks where the map comes from. Offline shows
/// exactly what works without signal: downloaded maps only, and a "No
/// offline map here" card elsewhere. Online fills everything not downloaded
/// with online OpenStreetMap tiles. Either way a dashed line marks where the
/// downloaded regions end.
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
  /// without showing the switch or the "No offline map here" card.
  final bool compact;

  const AppMap({
    super.key,
    this.overlays = const [],
    this.controller,
    this.initialCamera,
    this.initialFit,
    this.minZoom = 1,
    this.maxZoom = 17,
    this.onTap,
    this.onLongPress,
    this.onCameraChanged,
    this.mapType,
    this.contours,
    this.compact = false,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  /// Whether installed packs cover the view centre; null until known.
  bool? _covered;
  MapStyleState? _style;
  TileCoverage? _coverage;

  /// The downloadable region at the view centre, once the camera settles.
  String? _regionPath;

  /// The NOAA chart areas at the view centre, once the camera settles.
  List<ChartArea> _chartsHere = const [];
  Timer? _settle;

  /// The edges of the downloaded regions plus the screen's overlays, kept
  /// while their inputs don't change so the map doesn't rebuild its layers.
  var _overlays = const <MapOverlay>[];
  List<MapOverlay>? _overlaysFor;
  RegionIndex? _regionsFor;
  Set<String>? _installedFor;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _onCameraChanged(MapCamera camera) {
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

  List<MapOverlay> _withEdges(MapPacksService maps) {
    final regions = maps.regions;
    final installed = maps.installedRegions;
    if (!identical(widget.overlays, _overlaysFor) ||
        !identical(regions, _regionsFor) ||
        !setEquals(installed, _installedFor)) {
      _overlaysFor = widget.overlays;
      _regionsFor = regions;
      _installedFor = installed;
      _overlays = [
        for (final path in installed)
          if (regions?[path] case final region?)
            for (final (i, polygon) in region.polygons.indexed)
              for (final (j, ring) in polygon.indexed)
                MapLine(
                  id: 'offline-edge:$path:$i:$j',
                  points: [...ring, ring.first],
                  color: _edgeColor,
                  width: 2,
                  pattern: MapLinePattern.dashed,
                ),
        ...widget.overlays,
      ];
    }
    return _overlays;
  }

  static const _edgeColor = Color(0xFFD81B60);

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
    final disclaimer = style?.disclaimer;
    final coverage = _coverage;

    return Stack(
      children: [
        OfflineMapView(
          styleId: styleId,
          styleRegistry: maps.styles,
          packs: maps.mapPacks(
            contours: !online && (widget.contours ?? settings.mapContours),
          ),
          units: settings.unitSystem == UnitSystem.imperial
              ? Units.imperial
              : Units.metric,
          controller: widget.controller,
          initialCamera: widget.initialCamera,
          initialFit: widget.initialFit,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
          overlays: _withEdges(maps),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onCameraChanged: _onCameraChanged,
          baseLayers: [
            if (online && coverage != null)
              _OnlineTiles(key: ObjectKey(coverage), coverage: coverage),
          ],
          onCoverageChanged: (covered) => setState(() => _covered = covered),
          onTileCoverage: (coverage) => setState(() => _coverage = coverage),
          onStyleLoaded: (s) => setState(() => _style = s),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              if (!widget.compact) _SourceSwitch(online: online),
              if (disclaimer != null)
                _Disclaimer(context.l10n.map_notForNavigation),
            ],
          ),
        ),
        if (!widget.compact && !online && _covered == false)
          Positioned(
            left: 8,
            right: 8,
            // Clear of a screen's floating action button.
            bottom: 88,
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
          title: Text(l10n.map_noOfflineMap),
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
    final (area, entry) =
        offers.any((o) => maps.statusOf(o.$2) != PackStatus.available)
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

/// The chart styles' "Not for navigation", in MeshTrax's warning colours.
class _Disclaimer extends StatelessWidget {
  final String text;
  const _Disclaimer(this.text);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      border: const Border(left: BorderSide(color: Colors.orange, width: 3)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    ),
  );
}
