import 'package:flutter/material.dart';
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

/// Sizes line up in a fixed-width face, as in the mockup.
const sizeStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: [FontFeature.tabularFigures()],
);

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
