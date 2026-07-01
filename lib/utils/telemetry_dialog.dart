import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';

/// Shows the telemetry permissions dialog for a given [contact].
/// Handles reading current flags, toggling them, and saving back to the device.
void showTelemetryPermissionsDialog(
  BuildContext context,
  Contact contact,
) {
  final connector = context.read<MeshCoreConnector>();

  bool teleBase = contact.teleBaseEnabled;
  bool teleLoc = contact.teleLocEnabled;
  bool teleEnv = contact.teleEnvEnabled;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.contact_telemetry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(context.l10n.contact_teleBase),
              subtitle: Text(context.l10n.contact_teleBaseSubtitle),
              value: teleBase,
              onChanged: (val) => setState(() => teleBase = val),
            ),
            SwitchListTile(
              title: Text(context.l10n.contact_teleLoc),
              value: teleLoc,
              onChanged: teleBase ? (val) => setState(() => teleLoc = val) : null,
            ),
            SwitchListTile(
              title: Text(context.l10n.contact_teleEnv),
              value: teleEnv,
              onChanged: teleBase ? (val) => setState(() => teleEnv = val) : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await connector.setContactFlags(
                contact,
                teleBase: teleBase,
                teleLoc: teleLoc,
                teleEnv: teleEnv,
              );
            },
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    ),
  );
}
