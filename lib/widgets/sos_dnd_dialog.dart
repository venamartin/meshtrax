import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../services/notification_service.dart';

/// Says where this phone lets an SOS ring through Do Not Disturb, then opens
/// that page. The app can't switch it itself, and no phone opens straight to
/// the switch: Samsung keeps it under Do not disturb → App notifications,
/// other phones on the SOS alerts page. [samsung]: tests, instead of asking
/// the phone.
Future<void> askSosThroughDnd(BuildContext context, {bool? samsung}) async {
  final service = NotificationService();
  final inDndPage = samsung ?? await service.sosSwitchInDndPage();
  if (!context.mounted) return;
  final l10n = context.l10n;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.trip_sosTitle),
      content: Text(
        inDndPage ? l10n.sos_dndStepsSamsung : l10n.sos_dndStepsOther,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l10n.trax_notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.batterySleep_openSettings),
        ),
      ],
    ),
  );
  if (open == true) await service.openSosDndSettings();
}

/// The SOS alerts row and the health check's Fix: the steps when Do Not
/// Disturb silences it, the SOS alerts page when the phone turned it off.
Future<void> fixSosAlerts(BuildContext context) async {
  final service = NotificationService();
  if (await service.sosAlertState() != SosAlertState.silencedByDnd) {
    return service.openSosSettings();
  }
  if (context.mounted) await askSosThroughDnd(context);
}
