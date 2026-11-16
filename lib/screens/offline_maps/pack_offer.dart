import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/map_packs_service.dart';
import '../../utils/format_bytes.dart';
import 'offline_maps_ui.dart';

/// Packs line of sight asked for, from one region or several, ticked for
/// one Download: the contours where a line or a radio reach has none.
class PackOffer extends StatefulWidget {
  /// The packs' ids.
  final List<String> ids;

  /// Back to the region list.
  final VoidCallback onBack;

  const PackOffer({super.key, required this.ids, required this.onBack});

  @override
  State<PackOffer> createState() => _PackOfferState();
}

class _PackOfferState extends State<PackOffer> {
  late final Set<String> _ticked = {...widget.ids};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final index = maps.index;
    if (index == null) return CatalogueState(maps);
    final entries = [
      for (final id in widget.ids)
        ?index.usable.where((e) => e.id == id).firstOrNull,
    ];
    final onDrive = maps.drive != null;
    final toDownload = [
      for (final e in entries)
        if (_ticked.contains(e.id) && maps.statusOf(e) == PackStatus.available)
          e,
    ];
    final bytes = toDownload.fold<int>(0, (sum, e) => sum + e.bytes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.chevron_left),
            label: Text(l10n.offlineMaps_regions),
          ),
        ),
        Text(l10n.offlineMaps_losContours, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, e) in entries.indexed) ...[
                if (i > 0) const Divider(height: 1),
                PackRow(
                  id: e.id,
                  bytes: e.bytes,
                  status: maps.statusOf(e),
                  installedAt: maps.installedAtOf(e.id),
                  ticked: _ticked.contains(e.id),
                  onTicked: (v) => setState(
                    () => v ? _ticked.add(e.id) : _ticked.remove(e.id),
                  ),
                  title: Text(
                    e.region == null
                        ? e.name
                        : maps.regions?[e.region!]?.name ?? e.name,
                  ),
                  detail: entryLabel(l10n, e),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (bytes >= 1e9 && !onDrive) ...[
          Callout(l10n.offlineMaps_largeDownload(formatBytes(bytes))),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: toDownload.isEmpty
              ? null
              : () => maps.download(toDownload),
          child: Text(switch ((onDrive, toDownload.isEmpty)) {
            (true, true) => l10n.offlineMaps_installTotal,
            (true, false) => l10n.offlineMaps_install(formatBytes(bytes)),
            (false, true) => l10n.offlineMaps_downloadTotal,
            (false, false) => l10n.offlineMaps_download(formatBytes(bytes)),
          }),
        ),
      ],
    );
  }
}
