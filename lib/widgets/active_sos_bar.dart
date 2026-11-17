import 'package:material_ui/material_ui.dart';

import '../helpers/date_time_helper.dart';
import '../l10n/l10n.dart';
import '../services/sos_service.dart';

/// The user's own SOS, above the chat it went to: when it last went out,
/// who answered, and Cancel. A restored SOS that waits for the user offers
/// Send again.
class ActiveSosBar extends StatelessWidget {
  final ActiveSos sos;
  final bool connected;
  final VoidCallback onCancel;
  final VoidCallback onSendAgain;

  const ActiveSosBar({
    super.key,
    required this.sos,
    required this.connected,
    required this.onCancel,
    required this.onSendAgain,
  });

  /// Asks before the cancel goes out to everyone.
  static Future<bool> confirmCancel(BuildContext context, String chat) async {
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sos_cancel),
        content: Text(l10n.sos_cancelBody(chat)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.sos_keep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.sos_cancel),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onErrorContainer;
    final last = sos.lastSentAt;
    final (String title, List<String> lines) = switch (sos.phase) {
      SosPhase.cancelling => (l10n.sos_cancelPending, const <String>[]),
      SosPhase.stopped => (
        l10n.sos_stopped(
          last == null ? '–' : DateTimeHelper.time(context, last),
        ),
        const <String>[],
      ),
      SosPhase.active => (
        l10n.sos_active,
        [
          if (last != null)
            l10n.sos_lastSent(DateTimeHelper.time(context, last)),
          if (last == null || !connected) l10n.sos_waitingForRadio,
          sos.gotIt.isEmpty
              ? l10n.sos_noGotIt
              : l10n.sos_gotItBy(sos.gotIt.length, sos.gotIt.join(', ')),
        ],
      ),
    };
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final line in lines)
                    Text(line, style: TextStyle(color: ink, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (sos.phase == SosPhase.stopped) ...[
              TextButton(
                onPressed: onSendAgain,
                style: TextButton.styleFrom(foregroundColor: ink),
                child: Text(l10n.sos_sendAgain),
              ),
              const SizedBox(width: 4),
            ],
            if (sos.phase != SosPhase.cancelling)
              FilledButton(
                onPressed: onCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.sos_cancel),
              ),
          ],
        ),
      ),
    );
  }
}
