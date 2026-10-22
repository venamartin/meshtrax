import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../l10n/l10n.dart';
import '../../services/app_settings_service.dart';
import '../../services/map_packs_service.dart';
import '../../utils/format_bytes.dart';
import 'offline_maps_ui.dart';

/// One region's packs with their sizes and download states, and the
/// Download / Update / Delete actions (roadmap screen S3b).
class RegionDetail extends StatefulWidget {
  final Region region;

  /// Shown as "‹ Parent": the detail replaces the region list.
  final VoidCallback onBack;

  /// Switches to the Charts tab, where NOAA charts are picked by coast.
  final VoidCallback onOpenCharts;

  const RegionDetail({
    super.key,
    required this.region,
    required this.onBack,
    required this.onOpenCharts,
  });

  @override
  State<RegionDetail> createState() => _RegionDetailState();
}

class _RegionDetailState extends State<RegionDetail> {
  /// Packs ticked for download.
  late final Set<String> _ticked;

  /// The contours variant shown (one row for all variants).
  String? _contoursId;

  @override
  void initState() {
    super.initState();
    final maps = context.read<MapPacksService>();
    final units = context.read<AppSettingsService>().settings.unitSystem;
    final defaults = maps.defaultSelection(widget.region.path, units);
    _ticked = {for (final e in defaults) e.id};
    final contours = maps
        .packsForRegion(widget.region.path)
        .where((e) => e.kind == PackKind.contours)
        .toList();
    _contoursId =
        contours
            .where((e) => maps.installedPack(e.id) != null)
            .firstOrNull
            ?.id ??
        defaults.where((e) => e.kind == PackKind.contours).firstOrNull?.id ??
        contours.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final region = widget.region;
    final regions = maps.regions;
    final packs = maps.packsForRegion(region.path);
    final contours = packs.where((e) => e.kind == PackKind.contours).toList();
    final shown = [
      ...packs.where((e) => e.kind == PackKind.osm),
      ...contours.where((e) => e.id == _contoursId),
      ...packs.where((e) => e.kind == PackKind.base),
    ];
    final inUs = region.path.startsWith('north-america/us/');
    final hasUsgs = packs.any((e) => e.kind == PackKind.base);

    final toDownload = [
      for (final e in shown)
        if (_ticked.contains(e.id) && maps.statusOf(e) == PackStatus.available)
          e,
    ];
    final updates = [
      for (final e in packs)
        if (maps.statusOf(e) == PackStatus.updateAvailable) e,
    ];
    final downloadBytes = toDownload.fold(0, (sum, e) => sum + e.bytes);
    final updateBytes = updates.fold(0, (sum, e) => sum + e.bytes);
    final hasInstalled = maps.installedRegions.contains(region.path);
    final chartWaters =
        maps.chartAreas?.areasOverlapping(region.polygons).isNotEmpty ?? false;
    final ancestors = regions?.ancestorsOf(region) ?? const <Region>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.chevron_left),
            label: Text(
              ancestors.isEmpty ? l10n.offlineMaps_world : ancestors.last.name,
            ),
          ),
        ),
        Text(region.name, style: theme.textTheme.titleLarge),
        if (ancestors.isNotEmpty)
          Text(
            ancestors.map((r) => r.name).join(' › '),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, entry) in shown.indexed) ...[
                if (i > 0) const Divider(height: 1),
                PackRow(
                  entry: entry,
                  ticked: _ticked.contains(entry.id),
                  onTicked: (v) => setState(
                    () => v ? _ticked.add(entry.id) : _ticked.remove(entry.id),
                  ),
                  title: _packTitle(
                    entry,
                    entry.kind == PackKind.contours && contours.length > 1
                        ? contours
                        : const [],
                  ),
                  detail: packDetail(l10n, entry.kind),
                ),
              ],
              if (!hasUsgs && !inUs) ...[
                if (shown.isNotEmpty) const Divider(height: 1),
                ListTile(
                  enabled: false,
                  leading: const Checkbox(value: false, onChanged: null),
                  title: Text(l10n.offlineMaps_kindUsgs),
                  subtitle: Text(l10n.offlineMaps_usOnly),
                  trailing: const Text('—', style: sizeStyle),
                ),
              ],
            ],
          ),
        ),
        if (chartWaters)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.offlineMaps_chartsHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenCharts,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              l10n.offlineMaps_downloadTotal,
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              downloadBytes == 0 ? '—' : formatBytes(downloadBytes),
              style: sizeStyle.copyWith(fontSize: 18),
            ),
          ],
        ),
        if (downloadBytes >= 1e9) ...[
          const SizedBox(height: 12),
          Callout(l10n.offlineMaps_largeDownload(formatBytes(downloadBytes))),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: toDownload.isEmpty
              ? null
              : () => maps.download(toDownload),
          child: Text(
            toDownload.isEmpty
                ? l10n.offlineMaps_downloadTotal
                : l10n.offlineMaps_download(formatBytes(downloadBytes)),
          ),
        ),
        if (updates.isNotEmpty) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => maps.download(updates),
            child: Text(
              '${l10n.offlineMaps_update} ${formatBytes(updateBytes)}',
            ),
          ),
        ],
        if (hasInstalled) ...[
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () =>
                confirmDeleteRegion(context, maps, region.path, region.name),
            child: Text(l10n.offlineMaps_deleteRegion),
          ),
        ],
      ],
    );
  }

  /// A pack's name, with a variant menu when contours come in several.
  Widget _packTitle(PackIndexEntry entry, List<PackIndexEntry> variants) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(packLabel(l10n, entry.kind)),
        if (variants.isNotEmpty) ...[
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: entry.id,
            isDense: true,
            iconSize: 20,
            style: theme.textTheme.bodyMedium,
            underline: const SizedBox.shrink(),
            items: [
              for (final v in variants)
                DropdownMenuItem(
                  value: v.id,
                  child: Text(
                    intervalLabel(v.interval, v.intervalUnit) ??
                        v.variant ??
                        v.id,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              setState(() {
                if (_ticked.remove(_contoursId)) _ticked.add(id);
                _contoursId = id;
              });
            },
          ),
        ] else if (intervalLabel(entry.interval, entry.intervalUnit)
            case final interval?)
          Text('  $interval', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
