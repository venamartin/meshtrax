import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/date_time_helper.dart';
import '../helpers/position_text.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/radio_ask_service.dart';

/// Asks [contact]'s radio where it is and shows the answer as it comes:
/// where, when, its battery, and whether the position may be old.
class RadioAskSheet extends StatelessWidget {
  const RadioAskSheet({super.key, required this.contact, this.onShowOnMap});

  final Contact contact;
  final ValueChanged<LatLng>? onShowOnMap;

  static Future<void> show(
    BuildContext context,
    Contact contact, {
    ValueChanged<LatLng>? onShowOnMap,
  }) {
    context.read<RadioAskService>().ask(contact);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RadioAskSheet(contact: contact, onShowOnMap: onShowOnMap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final service = context.watch<RadioAskService>();
    final ask = service.askFor(contact);
    final answer = ask?.latest;
    final position = answer?.position;
    final format = coordFormatOf(context.watch<AppSettingsService>().settings);
    final busy =
        ask != null &&
        ask.phase != RadioAskPhase.done &&
        ask.phase != RadioAskPhase.noAnswer;
    final warn = TextStyle(color: theme.colorScheme.error);

    final status = switch (ask?.phase) {
      RadioAskPhase.waiting => l10n.radioAsk_waiting,
      RadioAskPhase.asking => l10n.radioAsk_asking(
        ask!.attempt,
        RadioAskService.attempts,
      ),
      RadioAskPhase.checkingAgain when ask!.attempt > 0 =>
        l10n.radioAsk_checkingAgain(ask.attempt, RadioAskService.attempts),
      RadioAskPhase.checkingAgain => l10n.radioAsk_checkAgainAt(
        DateTimeHelper.time(context, ask!.recheckAt!),
      ),
      _ => null,
    };
    final caveat = ask == null || answer == null || answer == ask.previous
        ? null
        : answer.position == null
        ? l10n.radioAsk_noPosition
        : ask.noFix
        ? l10n.radioAsk_noFix
        : ask.unchanged
        ? l10n.radioAsk_unchanged
        : ask.phase == RadioAskPhase.done && ask.second == null
        ? l10n.radioAsk_notChecked
        : null;
    final volts = answer?.volts, celsius = answer?.celsius;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.radioAsk_title(contact.name),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (answer != null) ...[
              if (position != null) ...[
                Text(
                  l10n.radioAsk_where(
                    contact.name,
                    DateTimeHelper.timeWithDay(context, answer.receivedAt),
                  ),
                  style: theme.textTheme.titleSmall,
                ),
                for (final line in positionLines(
                  position.lat,
                  position.lon,
                  format,
                ))
                  SelectableText(line),
              ],
              if (volts != null || celsius != null)
                Text(
                  [
                    if (volts != null)
                      l10n.radioAsk_volts(volts.toStringAsFixed(2)),
                    if (celsius != null)
                      l10n.telemetry_temperatureValue(
                        celsius.toStringAsFixed(0),
                        (celsius * 9 / 5 + 32).toStringAsFixed(0),
                      ),
                  ].join(' · '),
                ),
              if (caveat != null) ...[
                const SizedBox(height: 4),
                Text(caveat, style: warn),
              ],
              const SizedBox(height: 12),
            ],
            if (ask?.phase == RadioAskPhase.noAnswer) ...[
              Text(l10n.radioAsk_noAnswer, style: warn),
              const SizedBox(height: 12),
            ],
            if (status != null)
              Row(
                children: [
                  if (ask!.attempt > 0 || ask.phase == RadioAskPhase.waiting)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(child: Text(status)),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (position != null && onShowOnMap != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onShowOnMap!(LatLng(position.lat, position.lon));
                    },
                    child: Text(l10n.radioAsk_showOnMap),
                  ),
                if (!busy)
                  TextButton(
                    onPressed: () => service.ask(contact),
                    child: Text(l10n.radioAsk_askAgain),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.common_close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
