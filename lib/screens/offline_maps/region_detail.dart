import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../l10n/l10n.dart';
import '../../services/app_settings_service.dart';
import '../../services/map_packs_service.dart';
import '../../services/poi_service.dart';
import '../../services/routing_service.dart';
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
      ...packs.where((e) => e.kind == PackKind.terrain),
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
    final routing = context.watch<RoutingService?>();
    final poi = context.watch<PoiService?>();
    final extras = [
      if (routing != null &&
          routing.available &&
          routing.bundleFor(region.path) != null)
        _Extra(
          id: _routingId,
          title: l10n.offlineMaps_kindRouting,
          detail: l10n.offlineMaps_kindRoutingDetail,
          bytes: routing.isInstalled(region.path)
              ? routing.bundleFor(region.path)!.bytes
              : routing.bytesFor({region.path}),
          installed: routing.isInstalled(region.path),
          update: routing.updateAvailable(region.path),
          progress: routing.progressOf(region.path),
        ),
      for (final (id, which, title, detail) in [
        (
          _pointsId,
          PoiDownload.points,
          l10n.offlineMaps_kindPoi,
          l10n.offlineMaps_kindPoiDetail,
        ),
        (
          _addressesId,
          PoiDownload.addresses,
          l10n.offlineMaps_kindAddresses,
          l10n.offlineMaps_kindAddressesDetail,
        ),
      ])
        if (poi?.fileFor(region.path, which) case final file?)
          _Extra(
            id: id,
            title: title,
            detail: detail,
            bytes: file.bytes,
            installed: poi!.isInstalled(region.path, which),
            update: poi.updateAvailable(region.path, which),
            progress: poi.progressOf(region.path, which),
          ),
    ];
    final extrasToDownload = [
      for (final x in extras)
        if (_ticked.contains(x.id) && !x.installed && x.progress == null) x,
    ];
    final extraUpdates = [
      for (final x in extras)
        if (x.update && x.progress == null) x,
    ];

    final downloadBytes =
        toDownload.fold<int>(0, (sum, e) => sum + e.bytes) +
        extrasToDownload.fold<int>(0, (sum, x) => sum + x.bytes);
    final updateBytes =
        updates.fold<int>(0, (sum, e) => sum + e.bytes) +
        extraUpdates.fold<int>(0, (sum, x) => sum + x.bytes);
    void fetch(List<PackIndexEntry> packs, List<_Extra> more) {
      if (packs.isNotEmpty) maps.download(packs);
      final ids = {for (final x in more) x.id};
      if (ids.contains(_routingId)) routing!.download({region.path});
      final files = {
        if (ids.contains(_pointsId)) PoiDownload.points,
        if (ids.contains(_addressesId)) PoiDownload.addresses,
      };
      if (files.isNotEmpty) poi!.download(region.path, files);
    }

    final hasInstalled =
        maps.installedRegions.contains(region.path) ||
        (routing?.isInstalled(region.path) ?? false) ||
        (poi?.regionFor(region.path) != null);
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
              for (final x in extras) ...[
                if (shown.isNotEmpty || x != extras.first)
                  const Divider(height: 1),
                _ExtraRow(
                  extra: x,
                  ticked: _ticked.contains(x.id),
                  onTicked: (v) => setState(
                    () => v ? _ticked.add(x.id) : _ticked.remove(x.id),
                  ),
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
          onPressed: toDownload.isEmpty && extrasToDownload.isEmpty
              ? null
              : () => fetch(toDownload, extrasToDownload),
          child: Text(
            toDownload.isEmpty && extrasToDownload.isEmpty
                ? l10n.offlineMaps_downloadTotal
                : l10n.offlineMaps_download(formatBytes(downloadBytes)),
          ),
        ),
        if (updates.isNotEmpty || extraUpdates.isNotEmpty) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => fetch(updates, extraUpdates),
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

const _routingId = 'routing';
const _pointsId = 'poi:points';
const _addressesId = 'poi:addresses';

/// A region's routing or points of interest download, shown like a pack.
class _Extra {
  final String id;
  final String title;
  final String detail;
  final int bytes;
  final bool installed;
  final bool update;

  /// 0–1 while downloading.
  final double? progress;

  const _Extra({
    required this.id,
    required this.title,
    required this.detail,
    required this.bytes,
    required this.installed,
    required this.update,
    required this.progress,
  });
}

class _ExtraRow extends StatelessWidget {
  final _Extra extra;
  final bool ticked;
  final ValueChanged<bool> onTicked;

  const _ExtraRow({
    required this.extra,
    required this.ticked,
    required this.onTicked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final x = extra;
    final downloading = x.progress != null;
    final Widget leading = downloading
        ? const SizedBox.square(
            dimension: 24,
            child: Center(child: Icon(Icons.downloading)),
          )
        : x.update
        ? Icon(Icons.update, color: theme.colorScheme.tertiary)
        : x.installed
        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
        : Checkbox(value: ticked, onChanged: (v) => onTicked(v ?? false));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: leading,
            title: Text(x.title),
            subtitle: Text(
              downloading
                  ? l10n.offlineMaps_bytesProgress(
                      formatBytes((x.bytes * x.progress!).round()),
                      formatBytes(x.bytes),
                    )
                  : x.update
                  ? l10n.offlineMaps_updateAvailable
                  : x.detail,
            ),
            trailing: Text(formatBytes(x.bytes), style: sizeStyle),
            onTap: x.installed || downloading ? null : () => onTicked(!ticked),
          ),
          if (downloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: LinearProgressIndicator(value: x.progress),
            ),
        ],
      ),
    );
  }
}
