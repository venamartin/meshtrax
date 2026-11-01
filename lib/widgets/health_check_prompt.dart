import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../screens/settings_screen.dart';
import '../services/app_settings_service.dart';

/// Asks once whether to run the health check, the first time a radio is
/// connected. New defaults only reach new installs, so this is how people who
/// update find out what they could change.
Future<void> showHealthCheckPromptIfNeeded(BuildContext context) async {
  final settingsService = context.read<AppSettingsService>();
  if (settingsService.settings.healthCheckPromptSeen) return;
  if (!context.read<MeshCoreConnector>().isConnected) return;

  await settingsService.setHealthCheckPromptSeen();
  if (!context.mounted) return;

  final run = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(l10n.healthCheck_promptTitle),
        content: Text(l10n.healthCheck_promptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.healthCheck_promptLater),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.healthCheck_promptRun),
          ),
        ],
      );
    },
  );
  if (run != true || !context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SettingsScreen(openHealthCheck: true),
    ),
  );
}
