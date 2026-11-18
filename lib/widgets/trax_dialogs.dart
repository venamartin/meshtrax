import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../helpers/date_time_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/radio_settings.dart';
import '../models/trax.dart';
import '../services/notification_service.dart';
import '../services/trax_service.dart';

/// "Sunday 18:00": a trip's end in this phone's time zone.
String traxTimeText(BuildContext context, DateTime t) =>
    DateTimeHelper.dayAndTime(context, t);

/// What went wrong, in words; null when there is nothing to say.
String? traxOutcomeText(
  AppLocalizations l10n,
  TraxOutcome outcome, {
  LoRaParams? preset,
}) => switch (outcome) {
  TraxOutcome.ok || TraxOutcome.needPreset => null,
  TraxOutcome.sentUnconfirmed => l10n.trax_unconfirmed,
  TraxOutcome.notConnected => l10n.common_disconnected,
  TraxOutcome.unsupported => l10n.trax_unsupported,
  TraxOutcome.busy => l10n.trax_errorBusy,
  TraxOutcome.noEnd => l10n.trax_noEnd,
  TraxOutcome.noChannel => l10n.trax_noChannel,
  TraxOutcome.notAllowed => l10n.trax_errorNotAllowed(preset?.mhzText ?? '?'),
  TraxOutcome.refused => l10n.trax_errorRefused,
};

String traxStepText(AppLocalizations l10n, TraxStep step) => switch (step) {
  TraxStep.telling => l10n.trax_stepTelling,
  TraxStep.switching => l10n.trax_stepSwitching,
  TraxStep.checking => l10n.trax_stepChecking,
  TraxStep.leaving => l10n.trax_stepLeaving,
};

void _report(BuildContext context, String? text) {
  if (text == null || !context.mounted) return;
  showDismissibleSnackBar(context, content: Text(text));
}

/// Leave, asking which regular preset to return to when this phone saved
/// nothing for the radio.
Future<TraxOutcome?> traxLeave(
  BuildContext context,
  TraxService trax, {
  bool? tellGroup,
}) async {
  var outcome = await trax.leave(tellGroup: tellGroup);
  if (outcome == TraxOutcome.needPreset && context.mounted) {
    final returnTo = await showTraxPresetPicker(context, trax);
    if (returnTo == null) return null;
    outcome = await trax.leave(returnTo: returnTo, tellGroup: tellGroup);
  }
  return outcome;
}

/// The regular presets, for a radio another phone switched.
Future<TraxSavedRadio?> showTraxPresetPicker(
  BuildContext context,
  TraxService trax,
) {
  final presets = Trax.regularPresets;
  final current = trax.current;
  var picked = current == null ? null : Trax.likelyRegularPreset(current);
  return showDialog<TraxSavedRadio>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.trax_pickPreset),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.trax_pickPresetHint),
                const SizedBox(height: 8),
                Flexible(
                  child: RadioGroup<int>(
                    groupValue: picked,
                    onChanged: (i) => setState(() => picked = i),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (var i = 0; i < presets.length; i++)
                          RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: i,
                            title: Text(presets[i].$1),
                            subtitle: Text(
                              LoRaParams(
                                freqKhz: presets[i].$2.frequencyHz,
                                bwHz: presets[i].$2.bandwidthHz,
                                sf: presets[i].$2.sf,
                                cr: presets[i].$2.cr,
                              ).label,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: picked == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      trax.savedFromPreset(presets[picked!].$2),
                    ),
              child: Text(l10n.trax_leave),
            ),
          ],
        ),
      );
    },
  );
}

/// "Ana switched to TRAX mode until Sunday 18:00. Switch too?" One tap
/// each: nothing switches without it.
Future<void> showTraxFollowDialog(
  BuildContext context,
  TraxService trax, {
  required String sender,
  required TraxMessage message,
  required Channel channel,
}) {
  final l10n = context.l10n;
  return _showActionDialog(
    context,
    trax,
    body: l10n.trax_followBody(sender, traxTimeText(context, message.until!)),
    detail: l10n.trax_followDetail(message.preset!.label),
    action: l10n.trax_switchToo,
    run: () async {
      final outcome = await trax.follow(message, channel);
      return traxOutcomeText(l10n, outcome, preset: message.preset);
    },
  );
}

/// What TRAX mode asks when it happens: a member switched or is leaving,
/// or the trip has ended with the radio still in TRAX mode.
Future<void> showTraxPrompt(
  BuildContext context,
  TraxService trax,
  TraxPrompt prompt,
) {
  final l10n = context.l10n;
  return switch (prompt) {
    TraxFollowPrompt(:final sender, :final message, :final channel) =>
      showTraxFollowDialog(
        context,
        trax,
        sender: sender,
        message: message,
        channel: channel,
      ),
    TraxLeavePrompt(:final sender) => _showActionDialog(
      context,
      trax,
      body: l10n.trax_leaveBody(sender),
      action: l10n.trax_leaveToo,
      run: () => _leaveText(context, trax, tellGroup: false),
    ),
    TraxStillOnPrompt() => _showActionDialog(
      context,
      trax,
      body: l10n.trax_stillOn,
      action: l10n.trax_leave,
      run: () => _leaveText(context, trax),
    ),
  };
}

/// TRAX mode's questions over whatever screen is open: each as it comes,
/// and again from a TRAX notification's tap while it still fits. One that
/// is open already isn't put up again.
class TraxQuestions {
  TraxQuestions(this.trax, this.navigatorKey);

  final TraxService trax;
  final GlobalKey<NavigatorState> navigatorKey;
  final _open = <TraxPrompt>[];

  void ask(TraxPrompt prompt) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted || _open.contains(prompt)) return;
    _open.add(prompt);
    unawaited(
      showTraxPrompt(
        context,
        trax,
        prompt,
      ).whenComplete(() => _open.remove(prompt)),
    );
  }

  /// A notification's tap: null when it was TRAX mode's reminder, which
  /// asks again; else the payload to open as usual.
  String? onTap(String tapped) {
    if (tapped != NotificationService.traxEndedPayload) return tapped;
    if (trax.tripEndedPrompt case final prompt?) ask(prompt);
    return null;
  }
}

Future<String?> _leaveText(
  BuildContext context,
  TraxService trax, {
  bool? tellGroup,
}) async {
  final l10n = context.l10n;
  final outcome = await traxLeave(context, trax, tellGroup: tellGroup);
  return outcome == null ? null : traxOutcomeText(l10n, outcome);
}

Future<void> _showActionDialog(
  BuildContext context,
  TraxService trax, {
  required String body,
  String? detail,
  required String action,
  required Future<String?> Function() run,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _TraxActionDialog(
      trax: trax,
      body: body,
      detail: detail,
      action: action,
      run: run,
    ),
  );
  if (context.mounted) _report(context, result);
}

class _TraxActionDialog extends StatefulWidget {
  final TraxService trax;
  final String body;
  final String? detail;
  final String action;
  final Future<String?> Function() run;

  const _TraxActionDialog({
    required this.trax,
    required this.body,
    this.detail,
    required this.action,
    required this.run,
  });

  @override
  State<_TraxActionDialog> createState() => _TraxActionDialogState();
}

class _TraxActionDialogState extends State<_TraxActionDialog> {
  bool _running = false;

  Future<void> _go() async {
    setState(() => _running = true);
    final text = await widget.run();
    if (mounted) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: widget.trax,
      builder: (context, _) {
        final step = widget.trax.step;
        return AlertDialog(
          icon: const TraxIcon(size: 32, color: Color(Trax.orange)),
          title: Text(l10n.trax_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.body, style: Theme.of(context).textTheme.bodyLarge),
              if (widget.detail case final detail?) ...[
                const SizedBox(height: 12),
                Text(detail),
              ],
              if (_running) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                if (step != null) ...[
                  const SizedBox(height: 8),
                  Text(traxStepText(l10n, step)),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _running ? null : () => Navigator.pop(context),
              child: Text(l10n.trax_notNow),
            ),
            FilledButton(
              onPressed: _running ? null : _go,
              child: Text(widget.action),
            ),
          ],
        );
      },
    );
  }
}

/// The boot print from the app's notification icon.
class TraxIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const TraxIcon({super.key, this.size = 22, this.color});

  static const _asset = AssetImage('assets/icons/meshtraxnotification.png');

  @override
  Widget build(BuildContext context) =>
      ImageIcon(ResizeImage(_asset, height: 128), size: size, color: color);
}
