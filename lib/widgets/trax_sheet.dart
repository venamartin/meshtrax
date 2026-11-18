import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/trax.dart';
import '../screens/trax_settings_screen.dart';
import '../services/trax_service.dart';
import 'trax_dialogs.dart';

Future<void> showTraxSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => const TraxSheet(),
);

/// TRAX mode in one place: off, what one tap changes; on, what the radio
/// is on, the group check and Leave. Both link to TRAX settings, which
/// explains the rest. Kept short: it is read at the trailhead.
class TraxSheet extends StatefulWidget {
  const TraxSheet({super.key});

  @override
  State<TraxSheet> createState() => _TraxSheetState();
}

class _TraxSheetState extends State<TraxSheet> {
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<TraxService>().loadAllowed());
  }

  Future<void> _switch(TraxService trax) async {
    final l10n = context.l10n;
    final preset = trax.plannedPreset;
    setState(() => _error = null);
    final outcome = await trax.start();
    if (!mounted) return;
    setState(() => _error = traxOutcomeText(l10n, outcome, preset: preset));
  }

  Future<void> _leave(TraxService trax) async {
    final l10n = context.l10n;
    setState(() => _error = null);
    final outcome = await traxLeave(context, trax);
    if (!mounted || outcome == null) return;
    setState(() => _error = traxOutcomeText(l10n, outcome));
  }

  Future<void> _check(TraxService trax) async {
    setState(() => _error = null);
    await trax.groupCheck();
  }

  @override
  Widget build(BuildContext context) {
    final trax = context.watch<TraxService>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final on = trax.isOn;
    final busy = trax.busy;
    final step = trax.step;
    return SingleChildScrollView(
      // Clear of Android's navigation bar: the sheet runs behind it.
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TraxIcon(
                size: 30,
                color: on
                    ? const Color(Trax.orange)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  on ? l10n.trax_isOn : l10n.trax_title,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...on ? _onParts(context, trax) : _offParts(context, trax),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            if (step != null) ...[
              const SizedBox(height: 8),
              Text(traxStepText(l10n, step)),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TraxSettingsScreen(),
                  ),
                ),
                child: Text(l10n.trax_settings),
              ),
              const Spacer(),
              if (on)
                FilledButton(
                  onPressed: busy ? null : () => _leave(trax),
                  child: Text(l10n.trax_leave),
                )
              else if (trax.supported)
                FilledButton(
                  onPressed: busy || !_ready(trax) ? null : () => _switch(trax),
                  child: Text(l10n.trax_switch),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _ready(TraxService trax) {
    final end = trax.setup.until;
    return trax.plannedPreset != null &&
        end != null &&
        end.isAfter(DateTime.now()) &&
        (!trax.setup.tellGroup || trax.tripChannel != null);
  }

  List<Widget> _offParts(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    if (!trax.supported) {
      return [_note(Icons.error_outline, l10n.trax_unsupported)];
    }
    final now = trax.current;
    final planned = trax.plannedPreset;
    final setup = trax.setup;
    final end = setup.until;
    final hasEnd = end != null && end.isAfter(DateTime.now());
    final channel = trax.tripChannel;
    return [
      if (now != null) _row(context, l10n.trax_now, now.label),
      if (planned != null)
        _row(
          context,
          l10n.trax_inTrax,
          '${planned.label}\n${l10n.trax_repeatOn}',
          strong: true,
        ),
      _row(
        context,
        l10n.trax_tripEnds,
        hasEnd ? traxTimeText(context, end) : l10n.trax_notSet,
        color: hasEnd ? null : error,
      ),
      _row(
        context,
        l10n.trax_tripChannel,
        !setup.tellGroup
            ? l10n.trax_tellsNot
            : channel?.displayName ?? l10n.trax_none,
        color: setup.tellGroup && channel == null ? error : null,
      ),
    ];
  }

  List<Widget> _onParts(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = trax.current;
    final end = trax.until;
    final heard = trax.heard;
    return [
      if (end != null)
        Text(
          l10n.trax_until(traxTimeText(context, end)),
          style: theme.textTheme.titleMedium,
        ),
      if (now != null) ...[
        const SizedBox(height: 4),
        Text('${now.label}\n${l10n.trax_repeatOn}'),
      ],
      const Divider(height: 32),
      Text(l10n.trax_groupCheck, style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        l10n.trax_heard(heard.length, heard.map((c) => c.name).join(', ')),
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: trax.busy ? null : () => _check(trax),
        icon: const Icon(Icons.campaign_outlined),
        label: Text(l10n.trax_checkAgain),
      ),
      if (trax.session?.saved == null) ...[
        const SizedBox(height: 8),
        _note(Icons.restore, l10n.trax_noSaved),
      ],
    ];
  }

  /// A label over its value, so a long radio setting wraps at its own
  /// width rather than beside a label column.
  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: strong ? FontWeight.w600 : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(IconData icon, String text, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: color == null ? null : TextStyle(color: color),
          ),
        ),
      ],
    ),
  );
}
