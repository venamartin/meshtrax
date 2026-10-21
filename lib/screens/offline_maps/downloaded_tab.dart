import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../helpers/snack_bar_builder.dart';
import '../../l10n/l10n.dart';
import '../../services/map_packs_service.dart';
import '../../services/map_tile_cache_service.dart';
import '../../utils/format_bytes.dart';
import 'offline_maps_ui.dart';

/// What's on the device: storage used, updates, downloads in progress,
/// installed regions and stray pack files (roadmap screen S3c).
class DownloadedTab extends StatelessWidget {
  final ValueChanged<String> onOpenRegion;
  final VoidCallback onFindMaps;

  const DownloadedTab({
    super.key,
    required this.onOpenRegion,
    required this.onFindMaps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final active = maps.activeDownloads;
    final updates = maps.updates;

    // Installed packs by region; packs the catalogue doesn't know are "other".
    final byRegion = <String, List<Pack>>{};
    final other = <Pack>[];
    for (final pack in maps.installed) {
      final region = pack.region;
      if (region != null &&
          (maps.regions?[region] != null ||
              maps.packsForRegion(region).isNotEmpty ||
              maps.chartAreas?.byPackRegion(region) != null)) {
        (byRegion[region] ??= []).add(pack);
      } else {
        other.add(pack);
      }
    }
    // Chart areas get their own section. Only paths holding nothing but
    // charts: a card's Delete removes everything on its path.
    bool chartsOnly(String path) =>
        byRegion[path]!.every((p) => p.kind == PackKind.charts);
    int byName(String a, String b) => _regionName(
      maps,
      a,
    ).toLowerCase().compareTo(_regionName(maps, b).toLowerCase());
    final regionPaths = [
      for (final path in byRegion.keys)
        if (!chartsOnly(path)) path,
    ]..sort(byName);
    final chartPaths = [
      for (final path in byRegion.keys)
        if (chartsOnly(path)) path,
    ]..sort(byName);

    final children = <Widget>[
      if (maps.installed.isEmpty && active.isEmpty)
        _Empty(onFindMaps: onFindMaps)
      else ...[
        Text(
          l10n.offlineMaps_storageUsed(formatBytes(maps.installedBytes)),
          style: theme.textTheme.titleMedium,
        ),
        if (updates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l10n.offlineMaps_updates(updates.length))),
              FilledButton.tonal(
                onPressed: maps.updateAll,
                child: Text(
                  l10n.offlineMaps_updateAll(
                    formatBytes(updates.fold(0, (sum, e) => sum + e.bytes)),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (active.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel(l10n.offlineMaps_downloading),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in active.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _DownloadRow(download: d),
                ],
              ],
            ),
          ),
        ],
        for (final path in regionPaths) ...[
          const SizedBox(height: 12),
          _RegionCard(
            path: path,
            packs: byRegion[path]!,
            name: _regionName(maps, path),
            deleteName: _regionName(maps, path),
            onOpen: maps.regions?[path] == null
                ? null
                : () => onOpenRegion(path),
          ),
        ],
        if (chartPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel(l10n.offlineMaps_kindCharts),
          for (final (i, path) in chartPaths.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _RegionCard(
              path: path,
              packs: byRegion[path]!,
              name: _regionName(maps, path),
              deleteName: switch (maps.chartAreas?.byPackRegion(path)) {
                final area? => l10n.offlineMaps_chartsName(area.name),
                null => _regionName(maps, path),
              },
            ),
          ],
        ],
        if (other.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel(l10n.offlineMaps_otherFiles),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final pack in other)
                  ListTile(
                    title: Text(pack.name),
                    subtitle: Text(installedLabel(l10n, pack)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatBytes(maps.sizeOf(pack)), style: sizeStyle),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.common_delete,
                          onPressed: () => maps.deletePack(pack),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
      const SizedBox(height: 24),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(l10n.offlineMaps_clearTileCache),
          onPressed: () => _clearTileCache(context),
        ),
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
    );
  }

  Future<void> _clearTileCache(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.offlineMaps_clearTileCache),
        content: Text(l10n.offlineMaps_clearTileCachePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.common_clear),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<MapTileCacheService>().clearCache();
    if (context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.offlineMaps_tileCacheCleared),
      );
    }
  }
}

/// How a region's packs are listed: as in the region detail.
const _kindOrder = [
  PackKind.osm,
  PackKind.contours,
  PackKind.base,
  PackKind.charts,
  PackKind.unknown,
];

String _regionName(MapPacksService maps, String path) =>
    maps.regions?[path]?.name ??
    maps.chartAreas?.byPackRegion(path)?.name ??
    path.split('/').last;

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onFindMaps;
  const _Empty({required this.onFindMaps});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(l10n.offlineMaps_emptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.offlineMaps_emptyBody,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onFindMaps,
            child: Text(l10n.offlineMaps_findMaps),
          ),
        ],
      ),
    );
  }
}

/// A pack being downloaded: region and pack, progress, and controls.
class _DownloadRow extends StatelessWidget {
  final PackDownload download;
  const _DownloadRow({required this.download});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.read<MapPacksService>();
    final entry = download.entry;
    final region = entry.region;
    // "Massachusetts · NOAA charts", or the pack's own name ("… (NOAA
    // charts)") alone when its chart area isn't known.
    final title =
        entry.kind == PackKind.charts &&
            (region == null || maps.chartAreas?.byPackRegion(region) == null)
        ? entry.name
        : '${region == null ? entry.name : _regionName(maps, region)}'
              ' · ${entryLabel(l10n, entry)}';
    final state = download.state;
    final failed = state == PackDownloadState.failed;
    final status = switch (state) {
      PackDownloadState.queued => l10n.offlineMaps_waiting,
      PackDownloadState.waitingToRetry => l10n.offlineMaps_retrying,
      PackDownloadState.verifying => l10n.offlineMaps_checking,
      PackDownloadState.failed => l10n.offlineMaps_failed(download.error ?? ''),
      _ => l10n.offlineMaps_bytesProgress(
        formatBytes(download.bytesDone),
        formatBytes(entry.bytes),
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: failed
                    ? Text(
                        status,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value:
                                state == PackDownloadState.running ||
                                    state == PackDownloadState.paused
                                ? download.progress
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(status, style: theme.textTheme.bodySmall),
                        ],
                      ),
              ),
              if (state == PackDownloadState.running)
                IconButton(
                  icon: const Icon(Icons.pause),
                  tooltip: l10n.offlineMaps_pause,
                  onPressed: () => maps.pause(entry.id),
                ),
              if (state == PackDownloadState.paused || failed)
                IconButton(
                  icon: Icon(failed ? Icons.refresh : Icons.play_arrow),
                  tooltip: failed ? l10n.common_retry : l10n.offlineMaps_resume,
                  onPressed: () => maps.resume(entry.id),
                ),
              if (state != PackDownloadState.verifying)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: failed ? l10n.common_remove : l10n.common_cancel,
                  onPressed: () => maps.cancel(entry.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An installed region or chart area: its packs, size, date, and Update /
/// Delete.
class _RegionCard extends StatelessWidget {
  final String path;
  final List<Pack> packs;
  final String name;

  /// What the delete dialog calls it, e.g. "Rhode Island NOAA charts".
  final String deleteName;
  final VoidCallback? onOpen;

  const _RegionCard({
    required this.path,
    required this.packs,
    required this.name,
    required this.deleteName,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final bytes = packs.fold(0, (sum, p) => sum + maps.sizeOf(p));
    final updates = [
      for (final e in maps.packsForRegion(path))
        if (maps.statusOf(e) == PackStatus.updateAvailable) e,
    ];
    final dates = [for (final p in packs) ?maps.installedAt(p)]..sort();
    final date = dates.isEmpty
        ? null
        : DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
              .format(dates.last);
    final details = [
      // A chart area's card needs no "NOAA charts" line: its section says so.
      if (!packs.every((p) => p.kind == PackKind.charts))
        (packs.toList()..sort(
              (a, b) => _kindOrder
                  .indexOf(a.kind)
                  .compareTo(_kindOrder.indexOf(b.kind)),
            ))
            .map((p) => installedLabel(l10n, p))
            .join(' · '),
      [
        if (date != null) l10n.offlineMaps_downloadedOn(date),
        if (updates.isNotEmpty) l10n.offlineMaps_updateAvailable,
      ].join(' · '),
    ].where((s) => s.isNotEmpty).join('\n');

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ListTile(
            title: Text(name),
            subtitle: Text(details),
            isThreeLine: details.contains('\n'),
            trailing: Text(formatBytes(bytes), style: sizeStyle),
            onTap: onOpen,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 8,
              children: [
                if (updates.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () => maps.download(updates),
                    child: Text(l10n.offlineMaps_update),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () =>
                      confirmDeleteRegion(context, maps, path, deleteName),
                  child: Text(l10n.common_delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
