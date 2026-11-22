import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/region_service.dart';
import '../widgets/region_dialogs.dart';

/// Settings → Regions: the user's regions, the radio's default region, and
/// whether channel QR codes carry a region.
class RegionsScreen extends StatefulWidget {
  const RegionsScreen({super.key});

  @override
  State<RegionsScreen> createState() => _RegionsScreenState();
}

class _RegionsScreenState extends State<RegionsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<MeshCoreConnector>().loadRadioDefaultRegion());
  }

  Future<void> _confirmDelete(RegionService regions, String region) async {
    final l10n = context.l10n;
    final users = regions.channelsUsing(region);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.regions_deleteTitle(region)),
        content: users > 0 ? Text(l10n.regions_deleteInUse(users)) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await regions.remove(region);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final connector = context.watch<MeshCoreConnector>();
    final regions = context.watch<RegionService>();
    final canSetDefault =
        connector.isConnected && connector.supportsRadioDefaultRegion;
    final heard = [
      for (final name in regions.heardFromRepeaters)
        if (!regions.regions.contains(name)) name,
    ]..sort();
    final defaultText = !canSetDefault || !connector.radioDefaultRegionKnown
        ? '—'
        : connector.radioDefaultRegion ?? l10n.regions_none;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regions_title), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddRegionDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.regions_add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Text(l10n.regions_intro, style: theme.textTheme.bodyMedium),
            ),
            if (connector.isConnected && !connector.supportsRegions)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.regions_unsupported),
                ),
              ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.radio),
                    title: Text(l10n.regions_radioDefault),
                    subtitle: Text(defaultText),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: canSetDefault && connector.radioDefaultRegionKnown,
                    onTap: () => showRadioDefaultRegionDialog(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      l10n.regions_radioDefaultHelp,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.qr_code),
                    title: Text(l10n.regions_inQr),
                    subtitle: Text(l10n.regions_inQrSubtitle),
                    value: regions.regionsInQr,
                    onChanged: regions.setRegionsInQr,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                l10n.regions_yourRegions,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (regions.regions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(l10n.regions_empty, style: theme.textTheme.bodyMedium),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final region in regions.regions)
                      ListTile(
                        leading: const Icon(Icons.hexagon_outlined),
                        title: Text(region),
                        subtitle: Text(
                          l10n.regions_usedBy(regions.channelsUsing(region)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.common_delete,
                          onPressed: () => _confirmDelete(regions, region),
                        ),
                      ),
                  ],
                ),
              ),
            if (heard.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(
                  l10n.regions_heardNearby,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final region in heard)
                      ListTile(
                        leading: const Icon(Icons.hexagon_outlined),
                        title: Text(region),
                        subtitle: Text(
                          l10n.channelRegion_carriers(
                            regions.carriersOf(region),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: l10n.common_add,
                          onPressed: () => regions.add(region),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
