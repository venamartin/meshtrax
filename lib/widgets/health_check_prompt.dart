import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../screens/settings_screen.dart';
import '../services/app_settings_service.dart';
import '../utils/platform_info.dart';

/// Asks once whether to run the health check, after the first radio has
/// finished syncing. New defaults only reach new installs, so this is how
/// people who update find out what they could change. If the radio drops, or
/// the user has moved on to another screen, it asks on a later launch.
///
/// Not shown for now (owner, 2026-11-03: users pushed back on the check
/// asking by itself); Settings runs it on request.
Future<void> showHealthCheckPromptIfNeeded(BuildContext context) async {
  final settingsService = context.read<AppSettingsService>();
  if (settingsService.settings.healthCheckPromptSeen) return;
  if (!await context.read<MeshCoreConnector>().waitUntilSynced()) return;
  if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;

  final run = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(l10n.healthCheck_promptTitle),
        content: Text(
          PlatformInfo.isWindows || PlatformInfo.isLinux
              ? l10n.healthCheck_promptBodyDesktop
              : l10n.healthCheck_promptBody,
        ),
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
  await settingsService.setHealthCheckPromptSeen();
  if (run != true || !context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SettingsScreen(openHealthCheck: true),
    ),
  );
}
