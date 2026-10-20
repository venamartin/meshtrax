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
import 'offline_maps_ui.dart';
import 'region_detail.dart';

/// Region browser: breadcrumb, a suggested region, and the regions inside
/// the one being browsed (roadmap screen S3a); tapping a region opens its
/// detail in place of the list. Text only, one column on every screen size
/// (Martin, 2026-10-19).
class MapsTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final maps = context.watch<MapPacksService>();
    final regions = maps.regions;
    if (regions == null || maps.index == null) return _CatalogueState(maps);

    final selected = selectedPath == null ? null : regions[selectedPath!];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: selected == null
            ? _RegionList(
                regions: regions,
                browse: browsePath == null ? null : regions[browsePath!],
                selected: selected,
                onBrowse: onBrowse,
                onSelect: onSelect,
              )
            : RegionDetail(
                key: ValueKey(selected.path),
                region: selected,
                onBack: () => onSelect(null),
              ),
      ),
    );
  }
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
        if (regions.attribution != null) ...[
          const SizedBox(height: 24),
          Text(regions.attribution!, style: theme.textTheme.bodySmall),
        ],
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

/// A dot tinted by download size, as in the mockup's size bands.
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
