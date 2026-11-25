import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/position_text.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../screens/location_people_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_settings_service.dart';
import 'app_bar.dart';
import 'icon_help.dart';
import 'location_icon.dart';
import 'snr_indicator.dart';

/// What the My location icon shows, from the radio's settings.
typedef LocationLook = ({
  LocationAudience audience,
  LocationGps gps,
  bool hasGps,
  bool everyone,
});

/// Who can see the radio's location and what its GPS is doing. Everyone
/// is the radio's "allow all" for location: every contact saved on it.
LocationLook locationLookOf(MeshCoreConnector c) {
  final everyone =
      c.telemetryModeBase == teleModeAllowAll &&
      c.telemetryModeLoc == teleModeAllowAll;
  return (
    audience: c.advertLocationPolicy != 0
        ? LocationAudience.adverts
        : c.contacts.any(c.sharesPositionWith)
        ? LocationAudience.people
        : LocationAudience.onlyYou,
    gps: !c.hasGps || !c.gpsOn
        ? LocationGps.off
        : c.selfGpsIsFresh
        ? LocationGps.on
        : LocationGps.noFix,
    hasGps: c.hasGps,
    everyone: everyone,
  );
}

/// The icon's colour: quiet while only you see it, the primary colour while
/// someone can, red while someone can and the GPS has no fix.
Color locationColor(BuildContext context, LocationLook look) {
  final scheme = Theme.of(context).colorScheme;
  if (look.audience == LocationAudience.onlyYou) return scheme.onSurfaceVariant;
  return look.gps == LocationGps.noFix ? scheme.error : scheme.primary;
}

/// The icon in words: "In your adverts · GPS on".
String locationWords(AppLocalizations l10n, LocationLook look) => [
  switch (look.audience) {
    LocationAudience.onlyYou => l10n.myLocation_onlyYou,
    LocationAudience.people =>
      look.everyone ? l10n.myLocation_everyone : l10n.myLocation_people,
    LocationAudience.adverts => l10n.myLocation_adverts,
  },
  if (look.hasGps)
    switch (look.gps) {
      LocationGps.on => l10n.gps_on,
      LocationGps.noFix => l10n.myLocation_gpsNoFix,
      LocationGps.off => l10n.gps_off,
    },
].join(' · ');

/// The top bar's My location button, after the TRAX button: one icon for
/// the radio's GPS and who can see its location (Martin, 2026-11-21).
/// Tapping it opens [showMyLocationSheet].
class MyLocationButton extends StatelessWidget {
  const MyLocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final look = context.select<MeshCoreConnector, LocationLook?>(
      (c) => c.isConnected ? locationLookOf(c) : null,
    );
    if (look == null) return const SizedBox.shrink();
    return IconButton(
      style: topBarIconStyle,
      tooltip: locationWords(context.l10n, look),
      onPressed: () => showMyLocationSheet(context),
      icon: LocationIcon(
        audience: look.audience,
        gps: look.gps,
        color: locationColor(context, look),
      ),
    );
  }
}

Future<void> showMyLocationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const MyLocationSheet(),
    );

/// The radio's GPS, its adverts and the people who may ask it, each on its
/// own: the three never change one another. TRAX has its own sheet.
class MyLocationSheet extends StatefulWidget {
  const MyLocationSheet({super.key});

  @override
  State<MyLocationSheet> createState() => _MyLocationSheetState();
}

class _MyLocationSheetState extends State<MyLocationSheet> {
  late final MeshCoreConnector _connector;
  // Keeps "Fix 4 s ago" counting.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _connector.addSelfPositionViewer();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _connector.removeSelfPositionViewer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = context.watch<MeshCoreConnector>();
    final look = locationLookOf(c);
    final quiet = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final people = c.contacts.where(c.sharesPositionWith).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final names = people.take(3).map((p) => p.name).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.myLocation_title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    LocationIcon(
                      audience: look.audience,
                      gps: look.gps,
                      size: 18,
                      color: locationColor(context, look),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(locationWords(l10n, look), style: quiet),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (c.hasGps) ...[
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(l10n.myLocation_radioGps),
              subtitle: Text(_gpsText(context, c, look)),
              value: c.gpsOn,
              onChanged: (on) => unawaited(c.setGps(on)),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
          ],
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(l10n.myLocation_inAdverts),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l10n.myLocation_advertsHint} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _advertsInfo(context),
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        semanticLabel: l10n.myLocation_inAdverts,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            value: c.advertLocationPolicy != 0,
            onChanged: (on) => unawaited(_writeModes(c, advert: on ? 1 : 0)),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(l10n.myLocation_peopleWho),
            subtitle: look.everyone
                ? Text(
                    l10n.myLocation_allSaved(people.length),
                    style: TextStyle(color: scheme.error),
                  )
                : Text(
                    people.isEmpty
                        ? l10n.myLocation_nobody
                        : people.length > 3
                        ? '$names +${people.length - 3}'
                        : names,
                  ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPeopleScreen()),
            ),
          ),
          if (look.everyone)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton(
                onPressed: () => unawaited(pickPeopleInstead(c)),
                child: Text(l10n.myLocation_pickPeople),
              ),
            ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => showPrivacySettings(context, c),
                    child: Text(l10n.myLocation_batterySensors),
                  ),
                  TextButton(
                    onPressed: () => showIconHelp(context),
                    child: Text(l10n.iconHelp_title),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Fix 4s ago · 36.4570, -116.8660", "No fix yet. Last fix 14:02.",
  /// "Off saves battery. Last fix 14:02."
  String _gpsText(
    BuildContext context,
    MeshCoreConnector c,
    LocationLook look,
  ) {
    final l10n = context.l10n;
    final changed = c.selfGpsChangedAt;
    final reading = c.selfGps.value;
    if (look.gps == LocationGps.on && changed != null && reading != null) {
      final format = coordFormatOf(context.read<AppSettingsService>().settings);
      return l10n.myLocation_fix(
        formatAgo(changed),
        positionLines(reading.latitude, reading.longitude, format).first,
      );
    }
    final last = changed == null
        ? null
        : l10n.myLocation_lastFix(
            TimeOfDay.fromDateTime(changed).format(context),
          );
    return [
      c.gpsOn ? l10n.myLocation_noFix : l10n.myLocation_offSaves,
      ?last,
    ].join(' ');
  }

  void _advertsInfo(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.myLocation_inAdverts),
      content: Text(context.l10n.myLocation_advertsInfo),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_ok),
        ),
      ],
    ),
  );
}

/// The radio's privacy settings with what is given changed and the rest
/// as they are.
Future<void> _writeModes(
  MeshCoreConnector c, {
  int? base,
  int? location,
  int? advert,
}) async {
  await c.setTelemetryModeBase(
    base ?? c.telemetryModeBase,
    location ?? c.telemetryModeLoc,
    c.telemetryModeEnv,
    advert ?? c.advertLocationPolicy,
  );
  unawaited(c.refreshRadioSettings());
}

/// From "allow all" to the contacts picked one by one: the radio then
/// answers only those it has a permission for.
Future<void> pickPeopleInstead(MeshCoreConnector c) =>
    _writeModes(c, base: teleModeAllowFlags, location: teleModeAllowFlags);

/// Asking needs base and location on "by contact": a radio that answers
/// nobody starts answering the people it has a permission for.
Future<void> allowAskingByContact(MeshCoreConnector c) async {
  if (c.telemetryModeBase != teleModeDeny &&
      c.telemetryModeLoc != teleModeDeny) {
    return;
  }
  await _writeModes(
    c,
    base: c.telemetryModeBase == teleModeDeny ? teleModeAllowFlags : null,
    location: c.telemetryModeLoc == teleModeDeny ? teleModeAllowFlags : null,
  );
}
