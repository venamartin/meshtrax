import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../screens/settings_screen.dart';
import '../utils/telemetry_dialog.dart';

/// The top bar's location icon, after the GPS icon: blue while someone can
/// see the radio's position, grey while nobody can. Tapping it opens
/// [showLocationSharingDialog].
class LocationSharingButton extends StatelessWidget {
  const LocationSharingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final (:shown, :visible) = context
        .select<MeshCoreConnector, ({bool shown, bool visible})>(
          (c) => (shown: c.isConnected, visible: c.positionVisible),
        );
    if (!shown) return const SizedBox.shrink();
    final l10n = context.l10n;
    return IconButton(
      tooltip: visible
          ? l10n.locationSharing_someone
          : l10n.locationSharing_nobody,
      onPressed: () => showLocationSharingDialog(context),
      icon: Icon(
        Icons.share_location,
        size: 20,
        color: visible ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
    );
  }
}

Future<void> showLocationSharingDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _LocationSharingDialog(),
    );

typedef _Grants = ({bool base, bool location, bool environment});

/// Who can see the radio's position and read its telemetry: one switch for
/// sharing at all, the advert switch, and the contacts that may ask (each
/// opens its permissions).
class _LocationSharingDialog extends StatelessWidget {
  const _LocationSharingDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final primary = Theme.of(context).colorScheme.primary;
    final saved = connector.contacts
        .where((c) => c.type == advTypeChat && c.isActive)
        .toList();
    // On Allow all every contact gets battery, and location and sensors
    // too where their own setting allows all: one row says so.
    final everyone = connector.telemetryModeBase == teleModeAllowAll;
    final _Grants forAll = (
      base: everyone,
      location: everyone && connector.telemetryModeLoc == teleModeAllowAll,
      environment: everyone && connector.telemetryModeEnv == teleModeAllowAll,
    );
    final rows = <(Contact, _Grants)>[
      for (final contact in saved)
        if (connector.telemetryGrantedTo(contact) case final g
            when g.base &&
                (!everyone ||
                    (g.location && !forAll.location) ||
                    (g.environment && !forAll.environment)))
          (contact, g),
    ]..sort((a, b) {
        if (a.$2.location != b.$2.location) return a.$2.location ? -1 : 1;
        return a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
      });
    final sharedWithContacts = saved.any(connector.sharesPositionWith);
    final base = connector.telemetryModeBase;
    final loc = connector.telemetryModeLoc;
    // On while anything could carry the position: the adverts, or the
    // radio answering location requests from the contacts it allows.
    final sharing = connector.advertLocationPolicy != 0 ||
        (base != teleModeDeny && loc != teleModeDeny);

    final String headline;
    if (!connector.hasSelfPosition) {
      headline = l10n.locationSharing_noPosition;
    } else if (connector.advertsSharePosition) {
      headline = l10n.locationSharing_everyone;
    } else if (forAll.location) {
      headline = l10n.locationSharing_allContacts;
    } else if (sharedWithContacts) {
      headline = l10n.locationSharing_someContacts;
    } else {
      headline = l10n.locationSharing_nobody;
    }

    return AlertDialog(
      title: Text(l10n.locationSharing_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.locationSharing_share),
              subtitle: Text(
                sharing
                    ? l10n.locationSharing_shareOnHint
                    : l10n.locationSharing_shareOffHint,
              ),
              value: sharing,
              // Off: the adverts and every location answer. On: the contacts
              // with permission again, never everyone (owner, 2026-10-27);
              // location rides on base, so base comes back with it.
              onChanged: (on) => unawaited(
                on
                    ? _write(
                        connector,
                        base: base == teleModeDeny ? teleModeAllowFlags : base,
                        location: loc == teleModeDeny ? teleModeAllowFlags : loc,
                      )
                    : _write(connector, advert: 0, location: teleModeDeny),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.locationSharing_adverts),
              subtitle: Text(l10n.locationSharing_advertsHint),
              value: connector.advertLocationPolicy != 0,
              onChanged: (on) =>
                  unawaited(_write(connector, advert: on ? 1 : 0)),
            ),
            const Divider(),
            Text(
              l10n.locationSharing_contactsHeader,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (connector.telemetryModeBase == teleModeDeny)
              _note(l10n.locationSharing_noTelemetry)
            else ...[
              if (everyone)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    forAll.location ? Icons.share_location : Icons.groups,
                    color: forAll.location ? primary : null,
                  ),
                  title: Text(l10n.locationSharing_allContactsRow(saved.length)),
                  subtitle: Text(_parts(l10n, forAll)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showPrivacySettings(context, connector),
                ),
              for (final (contact, grants) in rows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    grants.location ? Icons.share_location : Icons.battery_std,
                    color: grants.location ? primary : Colors.grey,
                  ),
                  title: Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_parts(l10n, grants)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showTelemetryPermissionsDialog(context, contact),
                ),
              if (!everyone && rows.isEmpty)
                _note(l10n.locationSharing_noContacts),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => showPrivacySettings(context, connector),
          child: Text(l10n.settings_privacy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_close),
        ),
      ],
    );
  }

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text),
  );

  String _parts(AppLocalizations l10n, _Grants grants) => [
    if (grants.location) l10n.locationSharing_partLocation,
    if (grants.base) l10n.locationSharing_partBattery,
    if (grants.environment) l10n.locationSharing_partSensors,
  ].join(' · ');

  /// The radio's privacy settings with what is given changed and the rest
  /// as they are.
  Future<void> _write(
    MeshCoreConnector connector, {
    int? base,
    int? location,
    int? advert,
  }) async {
    await connector.setTelemetryModeBase(
      base ?? connector.telemetryModeBase,
      location ?? connector.telemetryModeLoc,
      connector.telemetryModeEnv,
      advert ?? connector.advertLocationPolicy,
      connector.multiAcks,
    );
    await connector.refreshDeviceInfo();
  }
}
