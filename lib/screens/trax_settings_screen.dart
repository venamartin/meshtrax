import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/radio_settings.dart';
import '../models/trax.dart';
import '../services/trax_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/trax_dialogs.dart';

/// TRAX settings: the preset, the trip channel, the trip's end and Tell
/// the group. One set per phone.
class TraxSettingsScreen extends StatelessWidget {
  const TraxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trax = context.watch<TraxService>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final setup = trax.setup;
    // The regular settings the presets start from.
    final regular = trax.isOn ? trax.session?.saved.params : trax.current;
    LoRaParams? preset(TraxPresetKind kind) =>
        regular == null ? null : Trax.presetFor(regular, kind);
    final channel = trax.tripChannel;
    final end = setup.until;
    void save(TraxSetup next) => unawaited(trax.updateSetup(next));
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.trax_settings),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // What the TRAX sheet leaves out, to stay short.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.trax_intro),
                  const SizedBox(height: 8),
                  Text(l10n.trax_savedNote, style: muted),
                  const SizedBox(height: 8),
                  Text(l10n.trax_trailhead, style: muted),
                ],
              ),
            ),
            _header(context, l10n.trax_preset),
            RadioGroup<TraxPresetKind>(
              groupValue: setup.preset,
              onChanged: (kind) {
                if (kind != null) save(setup.copyWith(preset: kind));
              },
              child: Column(
                children: [
                  RadioListTile<TraxPresetKind>(
                    value: TraxPresetKind.mesh,
                    title: Text(l10n.trax_presetMesh),
                    subtitle: _subtitle([preset(TraxPresetKind.mesh)?.label]),
                  ),
                  RadioListTile<TraxPresetKind>(
                    value: TraxPresetKind.longRange,
                    title: Text(l10n.trax_presetLongRange),
                    subtitle: _subtitle([
                      preset(TraxPresetKind.longRange)?.label,
                      l10n.trax_presetLongRangeHint,
                    ]),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: Text(l10n.trax_tripChannel),
              subtitle: Text(
                '${channel?.displayName ?? l10n.trax_none} · '
                '${l10n.trax_tripChannelHint}',
              ),
              onTap: () => _pickChannel(context, trax),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.trax_tripEnds),
              subtitle: Text(
                end == null ? l10n.trax_notSet : traxTimeText(context, end),
                style: end != null && !end.isAfter(DateTime.now())
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
              ),
              onTap: () => _pickEnd(context, trax),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.campaign_outlined),
              title: Text(l10n.trax_tellGroup),
              subtitle: Text(l10n.trax_tellGroupHint),
              value: setup.tellGroup,
              onChanged: (on) => save(setup.copyWith(tellGroup: on)),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _subtitle(List<String?> lines) {
    final shown = lines.whereType<String>().toList();
    return shown.isEmpty ? null : Text(shown.join('\n'));
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );

  Future<void> _pickChannel(BuildContext context, TraxService trax) async {
    final channels = trax.privateChannels;
    final l10n = context.l10n;
    final picked = await showDialog<(Channel?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.trax_tripChannel),
        children: [
          RadioGroup<String?>(
            groupValue: trax.tripChannel?.idKey,
            onChanged: (key) => Navigator.pop(context, (
              channels.where((c) => c.idKey == key).firstOrNull,
            )),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(
                  value: null,
                  title: Text(l10n.trax_none),
                ),
                for (final c in channels)
                  RadioListTile<String?>(
                    value: c.idKey,
                    title: Text(c.displayName),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(l10n.trax_tripChannelHint),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await trax.updateSetup(
      trax.setup.copyWith(channelKey: () => picked.$1?.idKey),
    );
  }

  Future<void> _pickEnd(BuildContext context, TraxService trax) async {
    final now = DateTime.now();
    final current = trax.setup.until;
    final start = current != null && current.isAfter(now)
        ? current
        : DateTime(now.year, now.month, now.day + 1, 18);
    final day = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null) return;
    await trax.updateSetup(
      trax.setup.copyWith(
        until: () =>
            DateTime(day.year, day.month, day.day, time.hour, time.minute),
      ),
    );
  }
}
