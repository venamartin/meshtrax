import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import '../services/map_tile_cache_service.dart';

/// The map every MeshTrax map screen draws: offline vector packs where they
/// cover the view, and online OpenStreetMap tiles elsewhere, with the
/// credits (and chart disclaimer) the data's licences require.
///
/// The map, contours and light/dark come from the user's settings unless a
/// screen overrides them (the region picker always shows OSM without
/// contours). See docs/offline-maps-roadmap.md, "App architecture".
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

  /// Credits for what the screen draws on top, e.g. region outlines.
  final List<String> extraCredits;

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
    this.extraCredits = const [],
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  /// Whether installed packs cover the view centre; null until known.
  bool? _covered;
  MapStyleState? _style;

  @override
  Widget build(BuildContext context) {
    final maps = context.watch<MapPacksService>();
    final settings = context.select<AppSettingsService, AppSettings>(
      (s) => s.settings,
    );
    final type =
        widget.mapType ?? MapType.parse(settings.mapType) ?? MapType.osm;
    final dark = switch (settings.mapTheme) {
      'dark' => true,
      'light' => false,
      _ => Theme.of(context).brightness == Brightness.dark,
    };
    final styleId = maps.styleId(type, dark: dark);
    if (styleId == null) return const SizedBox.expand();

    final online = _covered == false;
    final style = _style;
    final credits = [
      ...?style?.credits,
      if (online) '© OpenStreetMap contributors',
      ...widget.extraCredits,
      ...?style?.notices,
    ];
    final disclaimer = style?.disclaimer;

    return Stack(
      children: [
        OfflineMapView(
          styleId: styleId,
          styleRegistry: maps.styles,
          packs: maps.mapPacks(
            contours: widget.contours ?? settings.mapContours,
          ),
          units: settings.unitSystem == UnitSystem.imperial
              ? Units.imperial
              : Units.metric,
          controller: widget.controller,
          initialCamera: widget.initialCamera,
          initialFit: widget.initialFit,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
          overlays: widget.overlays,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onCameraChanged: widget.onCameraChanged,
          baseLayers: [if (online) const _OnlineTiles()],
          onCoverageChanged: (covered) => setState(() => _covered = covered),
          onStyleLoaded: (s) => setState(() => _style = s),
        ),
        if (disclaimer != null)
          Positioned(
            top: 8,
            left: 8,
            child: _Disclaimer(context.l10n.map_notForNavigation),
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

/// Online OpenStreetMap tiles, cached as viewed, under the overlays.
class _OnlineTiles extends StatelessWidget {
  const _OnlineTiles();

  @override
  Widget build(BuildContext context) => fm.TileLayer(
    urlTemplate: kMapTileUrlTemplate,
    userAgentPackageName: MapTileCacheService.userAgentPackageName,
    tileProvider: context.read<MapTileCacheService>().tileProvider,
    maxNativeZoom: 19,
  );
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
