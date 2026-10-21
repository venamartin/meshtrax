import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../../helpers/snack_bar_builder.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/map_packs_service.dart';
import '../../utils/format_bytes.dart';

/// What a pack is, in the user's words: "Map", "Contours 20 ft", "USGS topo
/// map". Used by every list on the Offline maps screen.
String packLabel(
  AppLocalizations l10n,
  PackKind kind, {
  num? interval,
  String? intervalUnit,
}) => switch (kind) {
  PackKind.osm => l10n.offlineMaps_kindMap,
  PackKind.contours => [
    l10n.offlineMaps_kindContours,
    ?intervalLabel(interval, intervalUnit),
  ].join(' '),
  PackKind.base => l10n.offlineMaps_kindUsgs,
  PackKind.charts => l10n.offlineMaps_kindCharts,
  PackKind.unknown => kind.name,
};

/// A contour interval as shown to users: "20 ft", "10 m".
String? intervalLabel(num? interval, String? unit) => interval == null
    ? null
    : '${interval == interval.roundToDouble() ? interval.round() : interval} ${unit ?? ''}'
          .trim();

/// The one-line description under a pack's name in the region detail.
String packDetail(AppLocalizations l10n, PackKind kind) => switch (kind) {
  PackKind.osm => l10n.offlineMaps_kindMapDetail,
  PackKind.contours => l10n.offlineMaps_kindContoursDetail,
  PackKind.base => l10n.offlineMaps_kindUsgsDetail,
  PackKind.charts || PackKind.unknown => '',
};

String installedLabel(AppLocalizations l10n, Pack pack) => packLabel(
  l10n,
  pack.kind,
  interval: pack.metadata['interval'] as num?,
  intervalUnit: pack.metadata['interval_unit'] as String?,
);

String entryLabel(AppLocalizations l10n, PackIndexEntry e) =>
    packLabel(l10n, e.kind, interval: e.interval, intervalUnit: e.intervalUnit);

/// The mockup's download-size bands: tints of the primary colour, and
/// orange from 1 GB, where a region is worth splitting.
Color sizeBandColor(ColorScheme scheme, int bytes) => bytes >= 1e9
    ? Colors.orange
    : scheme.primary.withValues(
        alpha: bytes >= 5e8
            ? 0.85
            : bytes >= 1e8
            ? 0.55
            : 0.3,
      );

/// Sizes line up with tabular digits. Not a monospace family: there's no
/// portable one, and on Linux the fallback was the emoji font (digits only).
const sizeStyle = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// Orange-bordered notice box, as MeshTrax shows warnings.
class Callout extends StatelessWidget {
  final String text;
  const Callout(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.12),
      border: const Border(left: BorderSide(color: Colors.orange, width: 3)),
    ),
    child: Text(text),
  );
}

/// Asks before deleting a region's installed packs, then deletes them.
Future<void> confirmDeleteRegion(
  BuildContext context,
  MapPacksService maps,
  String path,
  String name,
) async {
  final l10n = context.l10n;
  final bytes = maps.installed
      .where((p) => p.region == path)
      .fold(0, (sum, p) => sum + maps.sizeOf(p));
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.offlineMaps_deleteTitle(name)),
      content: Text(l10n.offlineMaps_deleteBody(formatBytes(bytes))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.common_delete),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await maps.deleteRegion(path);
  if (context.mounted) {
    showDismissibleSnackBar(
      context,
      content: Text(l10n.offlineMaps_deleted(name)),
    );
  }
}

/// A pack: tick box (or its state), [title], one-line [detail] or progress,
/// and size; plus pause / resume / cancel / retry while it downloads.
class PackRow extends StatelessWidget {
  final PackIndexEntry entry;
  final bool ticked;
  final ValueChanged<bool> onTicked;
  final Widget title;

  /// Shown under the title while the pack is still to download (or
  /// installed with no date); none when null or empty.
  final String? detail;

  const PackRow({
    super.key,
    required this.entry,
    required this.ticked,
    required this.onTicked,
    required this.title,
    this.detail,
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
    final String? subtitle = switch (status) {
      PackStatus.available => detail,
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
            ? detail
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
            title: title,
            subtitle: subtitle == null || subtitle.isEmpty
                ? null
                : Text(
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
                  if ((active && status != PackStatus.verifying) ||
                      status == PackStatus.failed)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: status == PackStatus.failed
                          ? l10n.common_remove
                          : l10n.common_cancel,
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

/// Loading, empty and error states while a tab has nothing to list: the
/// Maps tab without the catalogue, or the Charts tab without chart areas.
class CatalogueState extends StatelessWidget {
  final MapPacksService maps;
  final bool charts;
  const CatalogueState(this.maps, {super.key, this.charts = false});

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
      // A tab shows this only when its data is missing, so a failed
      // refresh explains it, whatever is cached.
      CatalogueStatus.error => (
        Icons.cloud_off_outlined,
        l10n.offlineMaps_serverError,
        maps.error,
        true,
      ),
      // The catalogue loaded; what failed is this tab's file.
      _ when charts && maps.chartAreasError != null => (
        Icons.cloud_off_outlined,
        l10n.offlineMaps_serverError,
        maps.chartAreasError,
        true,
      ),
      _ => (
        Icons.map_outlined,
        charts
            ? l10n.offlineMaps_chartsUnavailable
            : l10n.offlineMaps_unavailable,
        l10n.offlineMaps_unavailableHint,
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

/// "Showing the list from 20 Oct" with Retry, over a list from the cache
/// after a refresh failed; [at] is when that list was fetched.
class StaleNotice extends StatelessWidget {
  final MapPacksService maps;
  final DateTime? at;
  const StaleNotice(this.maps, {super.key, required this.at});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = this.at;
    final date = at == null
        ? ''
        : DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
              .format(at);
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
