import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  const RegionDetail({super.key, required this.region, required this.onBack});

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
      ...packs.where((e) => e.kind == PackKind.charts),
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
                _PackRow(
                  entry: entry,
                  ticked: _ticked.contains(entry.id),
                  onTicked: (v) => setState(
                    () => v ? _ticked.add(entry.id) : _ticked.remove(entry.id),
                  ),
                  variants:
                      entry.kind == PackKind.contours && contours.length > 1
                      ? contours
                      : const [],
                  onVariant: (id) => setState(() {
                    if (_ticked.remove(_contoursId)) _ticked.add(id);
                    _contoursId = id;
                  }),
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
}

/// A pack: tick box (or its state), name, one-line detail or progress, and
/// size; plus pause / resume / cancel / retry while it downloads.
class _PackRow extends StatelessWidget {
  final PackIndexEntry entry;
  final bool ticked;
  final ValueChanged<bool> onTicked;

  /// Contours variants to choose between; empty for other packs.
  final List<PackIndexEntry> variants;
  final ValueChanged<String> onVariant;

  const _PackRow({
    required this.entry,
    required this.ticked,
    required this.onTicked,
    required this.variants,
    required this.onVariant,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final status = maps.statusOf(entry);
    final download = maps.downloadOf(entry.id);

    final Widget leading = switch (status) {
      PackStatus.available => Checkbox(
        value: ticked,
        onChanged: (v) => onTicked(v ?? false),
      ),
      PackStatus.installed => Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
      ),
      PackStatus.updateAvailable => Icon(
        Icons.update,
        color: theme.colorScheme.tertiary,
      ),
      PackStatus.failed => Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
      ),
      _ => const SizedBox.square(
        dimension: 24,
        child: Center(child: Icon(Icons.downloading)),
      ),
    };

    final installed = maps.installedPack(entry.id);
    final installedAt = installed == null ? null : maps.installedAt(installed);
    final String subtitle = switch (status) {
      PackStatus.available => packDetail(l10n, entry.kind),
      PackStatus.queued => l10n.offlineMaps_waiting,
      PackStatus.waitingToRetry => l10n.offlineMaps_retrying,
      PackStatus.verifying => l10n.offlineMaps_checking,
      PackStatus.running || PackStatus.paused => l10n.offlineMaps_bytesProgress(
        formatBytes(download?.bytesDone ?? 0),
        formatBytes(entry.bytes),
      ),
      PackStatus.failed => l10n.offlineMaps_failed(download?.error ?? ''),
      PackStatus.installed =>
        installedAt == null
            ? packDetail(l10n, entry.kind)
            : l10n.offlineMaps_downloadedOn(
                DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
                    .format(installedAt),
              ),
      PackStatus.updateAvailable => l10n.offlineMaps_updateAvailable,
    };

    final active = switch (status) {
      PackStatus.queued ||
      PackStatus.running ||
      PackStatus.paused ||
      PackStatus.waitingToRetry ||
      PackStatus.verifying => true,
      _ => false,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: leading,
            title: Wrap(
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
                    onChanged: (id) => id == null ? null : onVariant(id),
                  ),
                ] else if (intervalLabel(entry.interval, entry.intervalUnit)
                    case final interval?)
                  Text('  $interval', style: theme.textTheme.bodySmall),
              ],
            ),
            subtitle: Text(
              subtitle,
              style: status == PackStatus.failed
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            trailing: Text(formatBytes(entry.bytes), style: sizeStyle),
            onTap: status == PackStatus.available
                ? () => onTicked(!ticked)
                : null,
          ),
          if (active || status == PackStatus.failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: active
                        ? LinearProgressIndicator(
                            value:
                                status == PackStatus.running ||
                                    status == PackStatus.paused
                                ? download?.progress
                                : null,
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (status == PackStatus.running)
                    IconButton(
                      icon: const Icon(Icons.pause),
                      tooltip: l10n.offlineMaps_pause,
                      onPressed: () => maps.pause(entry.id),
                    ),
                  if (status == PackStatus.paused ||
                      status == PackStatus.failed)
                    IconButton(
                      icon: Icon(
                        status == PackStatus.failed
                            ? Icons.refresh
                            : Icons.play_arrow,
                      ),
                      tooltip: status == PackStatus.failed
                          ? l10n.common_retry
                          : l10n.offlineMaps_resume,
                      onPressed: () => maps.resume(entry.id),
                    ),
                  if (active && status != PackStatus.verifying)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.common_cancel,
                      onPressed: () => maps.cancel(entry.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
