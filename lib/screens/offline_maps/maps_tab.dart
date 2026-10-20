import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../connector/meshcore_connector.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/app_settings_service.dart';
import '../../services/map_packs_service.dart';
import '../../utils/format_bytes.dart';
import '../../widgets/app_map.dart';
import 'offline_maps_ui.dart';
import 'region_detail.dart';

/// Above this width the region detail sits beside the map and list (the
/// mockup's 880 px breakpoint); below it the map sits above the list, and
/// the detail replaces the list.
const _wideLayout = 880.0;

/// Region browser: a map of the regions being browsed, the breadcrumb, a
/// suggested region, and the region chips (roadmap screen S3a).
class MapsTab extends StatefulWidget {
  final String? browsePath;
  final String? selectedPath;
  final ValueChanged<String?> onBrowse;
  final ValueChanged<String?> onSelect;

  const MapsTab({
    super.key,
    required this.browsePath,
    required this.selectedPath,
    required this.onBrowse,
    required this.onSelect,
  });

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final _map = OfflineMapController();

  @override
  void didUpdateWidget(MapsTab old) {
    super.didUpdateWidget(old);
    if (old.browsePath != widget.browsePath ||
        old.selectedPath != widget.selectedPath) {
      final regions = context.read<MapPacksService>().regions;
      if (regions != null) {
        _map.fitBounds(
          _focusBounds(regions, widget.browsePath, widget.selectedPath),
          padding: const EdgeInsets.all(24),
        );
      }
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maps = context.watch<MapPacksService>();
    final regions = maps.regions;
    if (regions == null || maps.index == null) return _CatalogueState(maps);

    final browse = widget.browsePath == null
        ? null
        : regions[widget.browsePath!];
    final selected = widget.selectedPath == null
        ? null
        : regions[widget.selectedPath!];
    final map = _PickerMap(
      controller: _map,
      regions: regions,
      browse: browse,
      selected: selected,
      onBrowse: widget.onBrowse,
      onSelect: widget.onSelect,
    );
    final list = _RegionList(
      regions: regions,
      browse: browse,
      selected: selected,
      onBrowse: widget.onBrowse,
      onSelect: widget.onSelect,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _wideLayout) {
          return Column(
            children: [
              SizedBox(
                height: (constraints.maxHeight * 0.38).clamp(200.0, 420.0),
                child: map,
              ),
              Expanded(
                child: selected == null
                    ? list
                    : RegionDetail(
                        key: ValueKey(selected.path),
                        region: selected,
                        onBack: () => widget.onSelect(null),
                      ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(flex: 5, child: map),
                  Expanded(flex: 4, child: list),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Card.outlined(
                  margin: EdgeInsets.zero,
                  child: selected == null
                      ? const _ChooseRegion()
                      : RegionDetail(
                          key: ValueKey(selected.path),
                          region: selected,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// What the map frames: the selected region, else the one being browsed,
/// else every top-level region.
LatLngBounds _focusBounds(
  RegionIndex regions,
  String? browsePath,
  String? selectedPath,
) {
  final focus =
      (selectedPath == null ? null : regions[selectedPath]) ??
      (browsePath == null ? null : regions[browsePath]);
  if (focus != null) return focus.bounds;
  final all = [for (final r in regions.roots) r.bounds];
  return LatLngBounds(
    south: all.map((b) => b.south).reduce((a, b) => a < b ? a : b),
    west: all.map((b) => b.west).reduce((a, b) => a < b ? a : b),
    north: all.map((b) => b.north).reduce((a, b) => a > b ? a : b),
    east: all.map((b) => b.east).reduce((a, b) => a > b ? a : b),
  );
}

/// The regions being browsed, drawn over the map and tinted by download
/// size (installed ones filled), with the legend strip below.
class _PickerMap extends StatelessWidget {
  final OfflineMapController controller;
  final RegionIndex regions;
  final Region? browse;
  final Region? selected;
  final ValueChanged<String?> onBrowse;
  final ValueChanged<String?> onSelect;

  const _PickerMap({
    required this.controller,
    required this.regions,
    required this.browse,
    required this.selected,
    required this.onBrowse,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maps = context.watch<MapPacksService>();
    final units = context.select<AppSettingsService, UnitSystem>(
      (s) => s.settings.unitSystem,
    );
    final shown = [
      ...regions.childrenOf(browse),
      if (selected != null && selected!.parentPath != browse?.path) selected!,
    ];
    final overlays = <MapOverlay>[
      for (final region in shown)
        for (final (i, polygon) in region.polygons.indexed)
          if (polygon.isNotEmpty)
            _regionPolygon(
              region,
              i,
              polygon,
              scheme: scheme,
              maps: maps,
              units: units,
            ),
    ];
    return Column(
      children: [
        Expanded(
          child: AppMap(
            controller: controller,
            mapType: MapType.osm,
            contours: false,
            initialFit: MapFit.bounds(
              _focusBounds(regions, browse?.path, selected?.path),
              padding: const EdgeInsets.all(24),
            ),
            overlays: overlays,
            extraCredits: [?regions.attribution],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final (bytes, label) in [
                (50e6, '< 100 MB'),
                (2e8, '100–500 MB'),
                (7e8, '0.5–1 GB'),
                (2e9, '> 1 GB'),
              ])
                _LegendItem(sizeBandColor(scheme, bytes.toInt()), label),
              _LegendItem(
                scheme.primary.withValues(alpha: 0.6),
                l10n.offlineMaps_tabDownloaded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  MapPolygon _regionPolygon(
    Region region,
    int part,
    List<List<LatLng>> polygon, {
    required ColorScheme scheme,
    required MapPacksService maps,
    required UnitSystem units,
  }) {
    final container = regions.childrenOf(region).isNotEmpty;
    final packs = maps.packsForRegion(region.path);
    final installed = maps.installedRegions.contains(region.path);
    final isSelected = region.path == selected?.path;
    final bytes = maps
        .defaultSelection(region.path, units)
        .fold(0, (sum, e) => sum + e.bytes);
    final fill = installed
        ? scheme.primary.withValues(alpha: 0.6)
        : container
        ? scheme.primary.withValues(alpha: 0.06)
        : packs.isEmpty
        ? scheme.outline.withValues(alpha: 0.12)
        : sizeBandColor(scheme, bytes).withValues(alpha: 0.5);
    VoidCallback? onTap;
    if (container) {
      onTap = () => onBrowse(region.path);
    } else if (packs.isNotEmpty) {
      onTap = () => onSelect(region.path);
    }
    return MapPolygon(
      id: '${region.path}#$part',
      points: polygon.first,
      holes: polygon.skip(1).toList(),
      fillColor: fill,
      strokeColor: isSelected ? scheme.primary : scheme.outline,
      strokeWidth: isSelected ? 3 : 1,
      onTap: onTap,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Loading, empty and error states while there's no catalogue to show.
class _CatalogueState extends StatelessWidget {
  final MapPacksService maps;
  const _CatalogueState(this.maps);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, title, body, retry) = switch (maps.status) {
      CatalogueStatus.unknown ||
      CatalogueStatus.loading => (null, l10n.offlineMaps_loading, null, false),
      CatalogueStatus.unavailable => (
        Icons.map_outlined,
        l10n.offlineMaps_unavailable,
        l10n.offlineMaps_unavailableHint,
        true,
      ),
      CatalogueStatus.error || CatalogueStatus.ready => (
        Icons.cloud_off_outlined,
        l10n.offlineMaps_serverError,
        maps.error,
        true,
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (retry) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: maps.refresh,
                child: Text(l10n.common_retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegionList extends StatelessWidget {
  final RegionIndex regions;
  final Region? browse;
  final Region? selected;
  final ValueChanged<String?> onBrowse;
  final ValueChanged<String?> onSelect;

  const _RegionList({
    required this.regions,
    required this.browse,
    required this.selected,
    required this.onBrowse,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final children = regions.childrenOf(browse);
    final suggested = _suggestedRegion(context, maps);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (maps.status == CatalogueStatus.error) _StaleNotice(maps),
        if (maps.index!.needsNewerApp || regions.needsNewerApp)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Callout(l10n.offlineMaps_needsNewerApp),
          ),
        _Breadcrumb(regions: regions, browse: browse, onBrowse: onBrowse),
        if (suggested != null) ...[
          const SizedBox(height: 8),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.near_me_outlined),
              title: Text(suggested.name),
              subtitle: Text(l10n.offlineMaps_suggested),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _regionSizeText(context, maps, suggested),
                    style: sizeStyle,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                onBrowse(suggested.parentPath);
                onSelect(suggested.path);
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          browse == null
              ? l10n.offlineMaps_regions
              : l10n.offlineMaps_regionsIn(browse!.name),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final region in children)
              _RegionChip(
                region: region,
                regions: regions,
                selected: region.path == selected?.path,
                onBrowse: onBrowse,
                onSelect: onSelect,
              ),
          ],
        ),
      ],
    );
  }

  /// The region at the radio's position, when it has packs. The phone's
  /// GPS and the map's last view join in later steps.
  Region? _suggestedRegion(BuildContext context, MapPacksService maps) {
    final lat = context.select<MeshCoreConnector, double?>(
      (c) => c.selfLatitude,
    );
    final lon = context.select<MeshCoreConnector, double?>(
      (c) => c.selfLongitude,
    );
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return null;
    final region = regions.regionAt(LatLng(lat, lon));
    if (region == null || maps.packsForRegion(region.path).isEmpty) {
      return null;
    }
    return region;
  }
}

class _StaleNotice extends StatelessWidget {
  final MapPacksService maps;
  const _StaleNotice(this.maps);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fetched = maps.fetchedAt;
    final date = fetched == null
        ? ''
        : DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
              .format(fetched);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.offlineMaps_cachedFrom(date))),
          TextButton(onPressed: maps.refresh, child: Text(l10n.common_retry)),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final RegionIndex regions;
  final Region? browse;
  final ValueChanged<String?> onBrowse;

  const _Breadcrumb({
    required this.regions,
    required this.browse,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trail = [
      (null, context.l10n.offlineMaps_world),
      if (browse != null)
        for (final r in [...regions.ancestorsOf(browse!), browse!])
          (r.path, r.name),
    ];
    final separator = Text(
      '›',
      style: TextStyle(color: theme.colorScheme.outline),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < trail.length; i++) ...[
          if (i > 0) separator,
          if (i == trail.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                trail[i].$2,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            TextButton(
              onPressed: () => onBrowse(trail[i].$1),
              child: Text(trail[i].$2),
            ),
        ],
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  final Region region;
  final RegionIndex regions;
  final bool selected;
  final ValueChanged<String?> onBrowse;
  final ValueChanged<String?> onSelect;

  const _RegionChip({
    required this.region,
    required this.regions,
    required this.selected,
    required this.onBrowse,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final inside = regions.childrenOf(region).length;
    final installed = maps.installedRegions.contains(region.path);
    final hasPacks = maps.packsForRegion(region.path).isNotEmpty;

    final String trailing;
    final VoidCallback? onPressed;
    if (inside > 0) {
      trailing = '${l10n.offlineMaps_inside(inside)} ›';
      onPressed = () => onBrowse(region.path);
    } else if (hasPacks) {
      trailing = _regionSizeText(context, maps, region);
      onPressed = () => onSelect(region.path);
    } else {
      trailing = '—';
      onPressed = null;
    }

    return ActionChip(
      avatar: installed
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : inside > 0 || !hasPacks
          ? null
          : _SizeDot(_defaultBytes(context, maps, region)),
      side: selected
          ? BorderSide(color: theme.colorScheme.primary, width: 2)
          : null,
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: region.name),
            TextSpan(
              text: '  $trailing',
              style: inside > 0
                  ? TextStyle(color: theme.colorScheme.primary)
                  : sizeStyle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ],
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// A dot tinted by download size, as on the map.
class _SizeDot extends StatelessWidget {
  final int bytes;
  const _SizeDot(this.bytes);

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: sizeBandColor(Theme.of(context).colorScheme, bytes),
      shape: BoxShape.circle,
    ),
  );
}

class _ChooseRegion extends StatelessWidget {
  const _ChooseRegion();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.offlineMaps_chooseRegion,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.offlineMaps_chooseRegionHint,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

int _defaultBytes(BuildContext context, MapPacksService maps, Region region) {
  final units = context.select<AppSettingsService, UnitSystem>(
    (s) => s.settings.unitSystem,
  );
  return maps
      .defaultSelection(region.path, units)
      .fold(0, (sum, e) => sum + e.bytes);
}

String _regionSizeText(
  BuildContext context,
  MapPacksService maps,
  Region region,
) => formatBytes(_defaultBytes(context, maps, region));
