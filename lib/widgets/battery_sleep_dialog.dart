import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/battery_sleep_service.dart';

/// Warns once (until dismissed) when the phone may put MeshTrax to sleep.
Future<void> showBatterySleepWarningIfNeeded(BuildContext context) async {
  final settingsService = context.read<AppSettingsService>();
  if (settingsService.settings.batterySleepWarningDismissed) return;
  if (!await BatterySleepService.shouldWarn()) return;
  final isSamsung = await BatterySleepService.manufacturer() == 'samsung';
  if (!context.mounted) return;

  var dontShowAgain = false;
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(dialogContext.l10n.batterySleep_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSamsung
                  ? dialogContext.l10n.batterySleep_bodySamsung
                  : dialogContext.l10n.batterySleep_bodyGeneric,
            ),
            CheckboxListTile(
              title: Text(dialogContext.l10n.dmChannel_dontShowAgain),
              value: dontShowAgain,
              onChanged: (value) =>
                  setDialogState(() => dontShowAgain = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.batterySleep_notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.batterySleep_openSettings),
          ),
        ],
      ),
    ),
  );
  if (dontShowAgain) await settingsService.dismissBatterySleepWarning();
  if (openSettings == true) await BatterySleepService.openSettings();
}
