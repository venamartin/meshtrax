import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';

/// What a contact may read from this radio. The firmware answers a request
/// only when [base] is allowed; [location] and [environment] ride on it.
typedef TelemetryGrants = ({bool base, bool location, bool environment});

TelemetryGrants telemetryGrantsOf(Contact contact) => (
      base: contact.teleBaseEnabled,
      location: contact.teleLocEnabled,
      environment: contact.teleEnvEnabled,
    );

/// Shows the telemetry permissions dialog for a given [contact].
/// Handles reading current flags, toggling them, and saving back to the device.
void showTelemetryPermissionsDialog(
  BuildContext context,
  Contact contact,
) {
  final connector = context.read<MeshCoreConnector>();
  final live = connector.contacts
          .where((c) => c.publicKeyHex == contact.publicKeyHex)
          .firstOrNull ??
      contact;
  final before = telemetryGrantsOf(live);
  var grants = before;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.contact_telemetry),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: telemetrySwitchTiles(
              context,
              connector: connector,
              contactName: live.name,
              grants: grants,
              onChanged: (next) => setState(() => grants = next),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await saveTelemetryGrants(
                connector,
                live,
                before: before,
                after: grants,
              );
            },
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    ),
  );
}

/// The three permission switches, as both permission dialogs show them.
/// Each says when the radio's privacy settings overrule it, and switching
/// one on while they share it with nobody offers to change them.
List<Widget> telemetrySwitchTiles(
  BuildContext context, {
  required MeshCoreConnector connector,
  required String contactName,
  required TelemetryGrants grants,
  required ValueChanged<TelemetryGrants> onChanged,
  EdgeInsetsGeometry? contentPadding,
}) {
  final l10n = context.l10n;
  final base = connector.telemetryModeBase;

  Future<void> set(
    TelemetryGrants next, {
    required bool switchedOn,
    bool location = false,
    bool environment = false,
  }) async {
    onChanged(next);
    if (!switchedOn) return;
    await _offerAllowByContactFlags(
      context,
      connector,
      contactName,
      location: location,
      environment: environment,
    );
    // Repaint the notes under the switches.
    if (context.mounted) onChanged(next);
  }

  return [
    SwitchListTile(
      contentPadding: contentPadding,
      title: Text(l10n.contact_teleBase),
      subtitle: _subtitle(
          context, l10n.contact_teleBaseSubtitle, _radioNote(l10n, [base])),
      value: grants.base,
      onChanged: (value) => set(
        (
          base: value,
          location: grants.location,
          environment: grants.environment,
        ),
        switchedOn: value,
      ),
    ),
    SwitchListTile(
      contentPadding: contentPadding,
      title: Text(l10n.contact_teleLoc),
      subtitle: _subtitle(context, l10n.contact_teleLocSubtitle,
          _radioNote(l10n, [base, connector.telemetryModeLoc])),
      value: grants.location,
      onChanged: grants.base
          ? (value) => set(
                (
                  base: grants.base,
                  location: value,
                  environment: grants.environment,
                ),
                switchedOn: value,
                location: true,
              )
          : null,
    ),
    SwitchListTile(
      contentPadding: contentPadding,
      title: Text(l10n.contact_teleEnv),
      subtitle: _subtitle(context, l10n.contact_teleEnvSubtitle,
          _radioNote(l10n, [base, connector.telemetryModeEnv])),
      value: grants.environment,
      onChanged: grants.base
          ? (value) => set(
                (
                  base: grants.base,
                  location: grants.location,
                  environment: value,
                ),
                switchedOn: value,
                environment: true,
              )
          : null,
    ),
  ];
}

/// Writes only the grants that changed since [before], with [remoteCli]
/// when that changed too; nothing at all when none did.
Future<void> saveTelemetryGrants(
  MeshCoreConnector connector,
  Contact contact, {
  required TelemetryGrants before,
  required TelemetryGrants after,
  bool? remoteCli,
}) async {
  bool? changed(bool was, bool now) => was == now ? null : now;
  final base = changed(before.base, after.base);
  final location = changed(before.location, after.location);
  final environment = changed(before.environment, after.environment);
  if (base == null &&
      location == null &&
      environment == null &&
      remoteCli == null) {
    return;
  }
  await connector.setContactFlags(
    contact,
    teleBase: base,
    teleLoc: location,
    teleEnv: environment,
    remoteCli: remoteCli,
  );
}

/// Why a switch does nothing, from the radio's privacy [modes] it needs
/// (base, and the part itself): shared with nobody, or with everyone.
({String text, bool denies})? _radioNote(
  AppLocalizations l10n,
  List<int> modes,
) {
  if (modes.contains(teleModeDeny)) {
    return (
      text: l10n.contact_teleRadioDenies(l10n.settings_denyAll),
      denies: true,
    );
  }
  if (modes.every((m) => m == teleModeAllowAll)) {
    return (
      text: l10n.contact_teleRadioAllowsAll(l10n.settings_allowAll),
      denies: false,
    );
  }
  return null;
}

Widget _subtitle(
  BuildContext context,
  String text,
  ({String text, bool denies})? note,
) {
  if (note == null) return Text(text);
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text),
      Text(
        note.text,
        style: TextStyle(color: note.denies ? scheme.error : scheme.primary),
      ),
    ],
  );
}

/// A permission switched on for [contactName] while the radio's privacy
/// settings share it with nobody: say so, and offer "Allow by contact
/// flags" for each setting in the way. The base setting is always one of
/// them, since without it the radio answers nobody.
Future<void> _offerAllowByContactFlags(
  BuildContext context,
  MeshCoreConnector connector,
  String contactName, {
  required bool location,
  required bool environment,
}) async {
  final base = connector.telemetryModeBase == teleModeDeny;
  final loc = location && connector.telemetryModeLoc == teleModeDeny;
  final env = environment && connector.telemetryModeEnv == teleModeDeny;
  if (!(base || loc || env) || !connector.isConnected) return;
  final l10n = context.l10n;
  final change = '${l10n.settings_denyAll} → ${l10n.settings_allowByContact}';
  final allow = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.contact_teleBlockedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.contact_teleBlockedBody(contactName)),
          const SizedBox(height: 12),
          for (final setting in [
            if (base) l10n.settings_telemetryBaseMode,
            if (loc) l10n.settings_telemetryLocationMode,
            if (env) l10n.settings_telemetryEnvironmentMode,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$setting: $change',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l10n.contact_teleNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.settings_allowByContact),
        ),
      ],
    ),
  );
  if (allow != true) return;
  await connector.setTelemetryModeBase(
    base ? teleModeAllowFlags : connector.telemetryModeBase,
    loc ? teleModeAllowFlags : connector.telemetryModeLoc,
    env ? teleModeAllowFlags : connector.telemetryModeEnv,
    connector.advertLocationPolicy,
    connector.multiAcks,
  );
}
