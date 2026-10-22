import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../connector/meshcore_connector.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/map_packs_service.dart';
import '../../utils/format_bytes.dart';
import '../../widgets/charts_notice_dialog.dart';
import 'offline_maps_ui.dart';

/// NOAA chart areas by coast (roadmap screen S3d): tick areas in any coast
/// and download them together. Text only, one column (Martin, 2026-10-20).
///
/// The selection belongs to the screen, so it survives switching tabs; it
/// holds pack regions, so an area listed under two coasts is one tick.
class ChartsTab extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelectionChanged;

  /// The area the screen was opened for: its coasts start open.
  final String? openArea;

  const ChartsTab({
    super.key,
    required this.selected,
    required this.onSelectionChanged,
    this.openArea,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final index = maps.index;
    final areas = maps.chartAreas;
    if (index == null || areas == null) {
      return CatalogueState(maps, charts: true);
    }

    bool available(PackIndexEntry e) =>
        maps.statusOf(e) == PackStatus.available;
    final toDownload = [
      for (final path in selected)
        if (maps.chartPackOf(path) case final e? when available(e)) e,
    ];
    final bytes = toDownload.fold(0, (sum, e) => sum + e.bytes);
    final suggested = _suggested(context, maps, areas);

    void toggle(String path, bool on) => onSelectionChanged(
      on ? {...selected, path} : ({...selected}..remove(path)),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const PageStorageKey('charts-list'),
                padding: const EdgeInsets.all(16),
                children: [
                  if (maps.status == CatalogueStatus.error)
                    StaleNotice(maps, at: maps.fetchedAt)
                  else if (maps.chartAreasError != null)
                    StaleNotice(maps, at: maps.chartAreasFetchedAt),
                  if (index.needsNewerApp || areas.needsNewerApp)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Callout(l10n.offlineMaps_needsNewerApp),
                    ),
                  Callout(
                    l10n.offlineMaps_chartsNotice,
                    onTap: () => showChartsNotice(context),
                  ),
                  if (suggested case (final area, final entry)) ...[
                    const SizedBox(height: 12),
                    Card.outlined(
                      margin: EdgeInsets.zero,
                      child: PackRow(
                        entry: entry,
                        ticked: selected.contains(area.packRegion),
                        onTicked: (on) => toggle(area.packRegion, on),
                        title: Text(area.name),
                        detail: l10n.offlineMaps_chartsSuggested(
                          areas.coasts.firstWhere(area.coasts.contains),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    l10n.offlineMaps_chartsByCoast,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, coast) in [
                          for (final c in areas.coasts)
                            if (areas.inCoast(c).isNotEmpty) c,
                        ].indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _Coast(
                            coast: coast,
                            areas: areas,
                            open: areas
                                .inCoast(coast)
                                .any((a) => a.packRegion == openArea),
                            selected: selected,
                            onToggle: toggle,
                            onSelectionChanged: onSelectionChanged,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (areas.attribution case final credit?) ...[
                    const SizedBox(height: 16),
                    Text(credit, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (toDownload.isNotEmpty)
              _DownloadBar(
                count: toDownload.length,
                bytes: bytes,
                onDownload: () {
                  onSelectionChanged(
                    {...selected}
                      ..removeAll([for (final e in toDownload) e.region]),
                  );
                  unawaited(maps.download(toDownload));
                },
              ),
          ],
        ),
      ),
    );
  }

  /// The chart area at the radio's position that's still to download, with
  /// its pack.
  (ChartArea, PackIndexEntry)? _suggested(
    BuildContext context,
    MapPacksService maps,
    ChartAreaIndex areas,
  ) {
    final lat = context.select<MeshCoreConnector, double?>(
      (c) => c.selfLatitude,
    );
    final lon = context.select<MeshCoreConnector, double?>(
      (c) => c.selfLongitude,
    );
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return null;
    for (final area in areas.areasAt(LatLng(lat, lon))) {
      final entry = maps.chartPackOf(area.packRegion);
      if (entry != null && maps.statusOf(entry) == PackStatus.available) {
        return (area, entry);
      }
    }
    return null;
  }
}

/// One coast: a row that opens to its areas, with Select all.
class _Coast extends StatelessWidget {
  final String coast;
  final ChartAreaIndex areas;

  /// Starts open; afterwards the user's choice, kept in PageStorage.
  final bool open;
  final Set<String> selected;
  final void Function(String path, bool on) onToggle;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _Coast({
    required this.coast,
    required this.areas,
    required this.open,
    required this.selected,
    required this.onToggle,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    final listed = areas.inCoast(coast);
    final entries = {
      for (final a in listed) a.packRegion: maps.chartPackOf(a.packRegion),
    };
    PackStatus? statusOf(ChartArea a) {
      final e = entries[a.packRegion];
      return e == null ? null : maps.statusOf(e);
    }

    final downloadable = [
      for (final a in listed)
        if (statusOf(a) == PackStatus.available) a.packRegion,
    ];
    final downloaded = listed.where(
      (a) =>
          statusOf(a) == PackStatus.installed ||
          statusOf(a) == PackStatus.updateAvailable,
    );
    final ticked = downloadable.where(selected.contains).length;
    final allTicked = downloadable.isNotEmpty && ticked == downloadable.length;
    final summary = [
      l10n.offlineMaps_chartsCoastSummary(
        listed.length,
        formatBytes(entries.values.fold(0, (sum, e) => sum + (e?.bytes ?? 0))),
      ),
      if (downloaded.isNotEmpty)
        l10n.offlineMaps_chartsDownloadedCount(downloaded.length),
      if (ticked > 0) l10n.offlineMaps_chartsSelectedCount(ticked),
    ].join(' · ');

    return ExpansionTile(
      key: PageStorageKey('charts-coast:$coast'),
      initiallyExpanded: open,
      title: Text(coast),
      subtitle: Text(summary),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        if (downloadable.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onSelectionChanged(
                allTicked
                    ? ({...selected}..removeAll(downloadable))
                    : {...selected, ...downloadable},
              ),
              child: Text(
                allTicked
                    ? l10n.offlineMaps_clearSelection
                    : l10n.offlineMaps_selectAll,
              ),
            ),
          ),
        for (final area in listed)
          if (entries[area.packRegion] case final entry?)
            PackRow(
              entry: entry,
              ticked: selected.contains(area.packRegion),
              onTicked: (on) => onToggle(area.packRegion, on),
              title: Text(area.name),
              detail: _alsoIn(l10n, area),
            )
          else
            ListTile(
              enabled: false,
              leading: const Checkbox(value: false, onChanged: null),
              title: Text(area.name),
              subtitle: Text(l10n.offlineMaps_chartsNotAvailable),
              trailing: const Text('—', style: sizeStyle),
            ),
      ],
    );
  }

  /// "Also in Gulf Coast" for an area listed under more than one coast.
  String? _alsoIn(AppLocalizations l10n, ChartArea area) {
    final others = [
      for (final c in areas.coasts)
        if (c != coast && area.coasts.contains(c)) c,
    ];
    return others.isEmpty
        ? null
        : l10n.offlineMaps_chartsAlsoIn(others.join(', '));
  }
}

/// The ticked areas' count and size, and Download, under the list.
class _DownloadBar extends StatelessWidget {
  final int count;
  final int bytes;
  final VoidCallback onDownload;

  const _DownloadBar({
    required this.count,
    required this.bytes,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.offlineMaps_chartsAreaCount(count),
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      formatBytes(bytes),
                      style: sizeStyle.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                if (bytes >= 1e9) ...[
                  const SizedBox(height: 12),
                  Callout(l10n.offlineMaps_largeDownload(formatBytes(bytes))),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onDownload,
                  child: Text(l10n.offlineMaps_download(formatBytes(bytes))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
