import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/region_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../screens/regions_screen.dart';
import '../services/region_service.dart';
import 'region_label.dart';

/// Asks for a new region name and adds it. The added name, or null.
Future<String?> showAddRegionDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _AddRegionDialog());

/// Picks [channel]'s own region: none, everywhere (when the radio has a
/// default region to step out of), or one of the user's regions.
Future<void> showChannelRegionDialog(BuildContext context, Channel channel) {
  unawaited(context.read<MeshCoreConnector>().loadRadioDefaultRegion());
  return showDialog<void>(
    context: context,
    builder: (_) => _ChannelRegionDialog(channel: channel),
  );
}

/// Picks the region saved on the radio as its default.
Future<void> showRadioDefaultRegionDialog(BuildContext context) async {
  final connector = context.read<MeshCoreConnector>();
  final regions = context.read<RegionService>();
  final l10n = context.l10n;
  final current = connector.radioDefaultRegion;
  final options = {...regions.regions, ?current}.toList();
  final picked = await showDialog<({String? name})>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.regions_radioDefault),
      content: SingleChildScrollView(
        child: RadioGroup<String?>(
          groupValue: current,
          onChanged: (value) => Navigator.pop(dialogContext, (name: value)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: Text(l10n.regions_none),
                value: null,
              ),
              for (final region in options)
                RadioListTile<String?>(title: Text(region), value: region),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.common_cancel),
        ),
      ],
    ),
  );
  if (picked == null || picked.name == current) return;
  final ok = await connector.setRadioDefaultRegion(picked.name);
  if (!ok && context.mounted) {
    showDismissibleSnackBar(
      context,
      content: Text(l10n.regions_radioNoAnswer),
      backgroundColor: Colors.red,
    );
  }
}

class _ChannelRegionDialog extends StatelessWidget {
  final Channel channel;

  const _ChannelRegionDialog({required this.channel});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final regions = context.watch<RegionService>();
    final connector = context.watch<MeshCoreConnector>();
    final current = regions.regionOf(channel.idKey);
    final radioDefault = connector.radioDefaultRegion;
    final offerEverywhere =
        (radioDefault != null && connector.supportsRegionEverywhere) ||
        current == RegionHelper.everywhere;
    final offerNearby =
        connector.supportsNearbyOnly || current == RegionHelper.nearbyOnly;

    void pick(String? region) {
      unawaited(regions.setChannelRegion(channel.idKey, region));
      Navigator.pop(context);
    }

    return AlertDialog(
      title: Text(l10n.channelRegion_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.channelRegion_help,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            RadioGroup<String?>(
              groupValue: current,
              onChanged: pick,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String?>(
                    title: Text(
                      radioDefault == null
                          ? l10n.regions_none
                          : l10n.channelRegion_noneWithDefault(radioDefault),
                    ),
                    value: null,
                  ),
                  if (offerEverywhere)
                    RadioListTile<String?>(
                      title: Text(l10n.channelRegion_everywhere),
                      value: RegionHelper.everywhere,
                    ),
                  if (offerNearby)
                    RadioListTile<String?>(
                      title: Text(l10n.channelRegion_nearbyOption),
                      subtitle: Text(l10n.channelRegion_nearbyHelp),
                      value: RegionHelper.nearbyOnly,
                    ),
                  for (final region in regions.regions)
                    RadioListTile<String?>(
                      title: Text(region),
                      subtitle: regions.hasRepeaterReports
                          ? RegionCarriers(regions.carriersOf(region))
                          : null,
                      value: region,
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.regions_add),
              onTap: () async {
                final added = await showAddRegionDialog(context);
                if (added != null && context.mounted) pick(added);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final navigator = Navigator.of(context)..pop();
            navigator.push(
              MaterialPageRoute<void>(builder: (_) => const RegionsScreen()),
            );
          },
          child: Text(l10n.channelRegion_manage),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_close),
        ),
      ],
    );
  }
}

class _AddRegionDialog extends StatefulWidget {
  const _AddRegionDialog();

  @override
  State<_AddRegionDialog> createState() => _AddRegionDialogState();
}

class _AddRegionDialogState extends State<_AddRegionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _problem(RegionService regions) {
    final l10n = context.l10n;
    final text = _controller.text;
    return switch (RegionHelper.check(text)) {
      RegionNameProblem.empty => null,
      RegionNameProblem.tooLong => l10n.regions_nameTooLong,
      RegionNameProblem.badCharacter => l10n.regions_nameBadCharacter,
      null =>
        regions.regions.contains(RegionHelper.normalize(text))
            ? l10n.regions_nameExists
            : null,
    };
  }

  Future<void> _save(RegionService regions) async {
    final name = RegionHelper.normalize(_controller.text);
    if (await regions.add(name) && mounted) Navigator.pop(context, name);
  }

  /// A name nearby repeaters use that differs from the typed one only in
  /// capitals: offered, since the firmware tells them apart.
  String? _repeaterSpelling(RegionService regions) {
    final typed = RegionHelper.normalize(_controller.text);
    if (typed.isEmpty || regions.heardFromRepeaters.contains(typed)) {
      return null;
    }
    final lower = typed.toLowerCase();
    return regions.heardFromRepeaters
        .where((n) => n.toLowerCase() == lower)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final regions = context.watch<RegionService>();
    final problem = _problem(regions);
    final canSave =
        problem == null && RegionHelper.check(_controller.text) == null;
    final spelling = _repeaterSpelling(regions);
    return AlertDialog(
      title: Text(l10n.regions_add),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(context, regions, problem, canSave),
          if (spelling != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.regions_nearbySpelling(spelling))),
                  TextButton(
                    onPressed: () => setState(() => _controller.text = spelling),
                    child: Text(l10n.regions_useSpelling),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: canSave ? () => _save(regions) : null,
          child: Text(l10n.common_add),
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    RegionService regions,
    String? problem,
    bool canSave,
  ) {
    final l10n = context.l10n;
    return TextField(
      controller: _controller,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      decoration: InputDecoration(
        labelText: l10n.regions_nameLabel,
        helperText: l10n.regions_nameHelp,
        helperMaxLines: 3,
        errorText: problem,
        errorMaxLines: 3,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: canSave ? (_) => _save(regions) : null,
    );
  }
}
