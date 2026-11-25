import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../connector/meshcore_connector.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/map_packs_service.dart';
import '../../services/routing_service.dart' show RoutingDriveBlock;
import '../../services/water_routing_service.dart';
import '../../utils/format_bytes.dart';
import '../../widgets/charts_notice_dialog.dart';
import 'offline_maps_ui.dart';

/// NOAA chart areas by coast (roadmap screen S3d): tick areas in any coast
/// and download them together. Text only, one column (Martin, 2026-10-20).
///
/// The selection belongs to the screen, so it survives switching tabs; it
/// holds pack regions, so an area listed under two coasts is one tick, and
/// [routingTick]s for the areas' water routing.
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

  /// The tick of [area]'s water routing in the selection.
  static String routingTick(String area) => 'routing:$area';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final water = context.watch<WaterRoutingService?>();
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
    final routing = {
      if (water != null)
        for (final path in selected)
          if (path.startsWith('routing:') &&
              _routingStatus(maps, water, path.substring(8)) ==
                  PackStatus.available)
            path.substring(8),
    };
    final routingTodo = water?.downloadsFor(routing) ?? const <String>{};
    final bytes =
        toDownload.fold(0, (sum, e) => sum + e.bytes) +
        routingTodo.fold<int>(
          0,
          (sum, area) =>
              sum +
              water!.bundleFor(area)!.bytes +
              switch (water.chartFor(area)) {
                final chart? when !toDownload.contains(chart) => chart.bytes,
                _ => 0,
              },
        );
    final count = {...toDownload.map((e) => e.region), ...routing}.length;
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
                        id: entry.id,
                        bytes: entry.bytes,
                        status: maps.statusOf(entry),
                        installedAt: maps.installedAtOf(entry.id),
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
            if (toDownload.isNotEmpty || routing.isNotEmpty)
              _DownloadBar(
                count: count,
                bytes: bytes,
                onDownload: () {
                  onSelectionChanged(
                    {...selected}..removeAll([
                      for (final e in toDownload) e.region,
                      for (final area in routing) routingTick(area),
                    ]),
                  );
                  unawaited(maps.download(toDownload));
                  if (routing.isNotEmpty) unawaited(water!.download(routing));
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
    final water = context.watch<WaterRoutingService?>();
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
          if (entries[area.packRegion] case final entry?) ...[
            PackRow(
              id: entry.id,
              bytes: entry.bytes,
              status: maps.statusOf(entry),
              installedAt: maps.installedAtOf(entry.id),
              ticked: selected.contains(area.packRegion),
              onTicked: (on) => onToggle(area.packRegion, on),
              title: Text(area.name),
              detail: _alsoIn(l10n, area),
            ),
            if (water != null && water.bundleFor(area.packRegion) != null)
              _RoutingRow(
                area: area.packRegion,
                water: water,
                ticked: selected.contains(
                  ChartsTab.routingTick(area.packRegion),
                ),
                chartTicked: selected.contains(area.packRegion),
                onTicked: (on) =>
                    onToggle(ChartsTab.routingTick(area.packRegion), on),
              ),
          ] else
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

/// How [area]'s water routing download stands, as its row shows it.
PackStatus _routingStatus(
  MapPacksService maps,
  WaterRoutingService water,
  String area,
) =>
    maps.downloadStatus(WaterRoutingService.downloadId(area)) ??
    (water.updateAvailable(area)
        ? PackStatus.updateAvailable
        : water.isInstalled(area)
        ? PackStatus.installed
        : PackStatus.available);

/// An area's water routing, under its chart: its own tick and size,
/// unticked to start. The chart comes too where the one on the device
/// isn't the build the routing was made from, unless its own row is
/// ticked.
class _RoutingRow extends StatelessWidget {
  final String area;
  final WaterRoutingService water;
  final bool ticked;
  final bool chartTicked;
  final ValueChanged<bool> onTicked;

  const _RoutingRow({
    required this.area,
    required this.water,
    required this.ticked,
    required this.chartTicked,
    required this.onTicked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    final installed = water.isInstalled(area);
    final block = installed ? null : water.driveBlock;
    final Widget row;
    if (water.rebuilding(area) || block != null) {
      row = ListTile(
        enabled: false,
        leading: const Checkbox(value: false, onChanged: null),
        title: Text(l10n.offlineMaps_kindWaterRouting),
        subtitle: Text(switch (block) {
          RoutingDriveBlock.older => l10n.offlineMaps_routingDriveOlder,
          RoutingDriveBlock.incomplete =>
            l10n.offlineMaps_routingDriveIncomplete,
          null => l10n.offlineMaps_waterRoutingRebuilding,
        }),
        trailing: const Text('—', style: sizeStyle),
      );
    } else {
      final chart = installed || chartTicked ? null : water.chartFor(area);
      row = PackRow(
        id: WaterRoutingService.downloadId(area),
        bytes: chart == null
            ? water.bundleFor(area)!.bytes
            : water.bytesFor({area}),
        status: _routingStatus(maps, water, area),
        ticked: ticked,
        onTicked: onTicked,
        title: Text(l10n.offlineMaps_kindWaterRouting),
        detail: chart == null
            ? l10n.offlineMaps_kindWaterRoutingDetail
            : maps.installedPack(chart.id) == null
            ? l10n.offlineMaps_waterRoutingWithChart
            : l10n.offlineMaps_waterRoutingUpdatesChart,
      );
    }
    // Set in under its chart's row.
    return Padding(padding: const EdgeInsets.only(left: 40), child: row);
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
    final onDrive = context.select<MapPacksService, bool>(
      (m) => m.drive != null,
    );
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
                if (bytes >= 1e9 && !onDrive) ...[
                  const SizedBox(height: 12),
                  Callout(l10n.offlineMaps_largeDownload(formatBytes(bytes))),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onDownload,
                  child: Text(
                    onDrive
                        ? l10n.offlineMaps_install(formatBytes(bytes))
                        : l10n.offlineMaps_download(formatBytes(bytes)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
