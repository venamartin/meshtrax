import 'dart:async';

import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxshare/traxshare.dart' show TraxMapIcon;

import '../connector/meshcore_connector.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/geo_format.dart';
import '../helpers/trax_icons.dart';
import '../l10n/l10n.dart';
import '../models/map_focus.dart';
import '../models/trax.dart';
import '../screens/map_screen.dart';
import '../screens/trax_settings_screen.dart';
import '../services/app_settings_service.dart';
import '../services/radio_ask_service.dart';
import '../services/trax_beacon_service.dart';
import '../services/trax_service.dart';
import '../services/trip_positions.dart';
import '../services/trip_service.dart';
import 'experimental_title.dart';
import 'line_of_sight_sheet.dart';
import 'trax_dialogs.dart';

Future<void> showTraxSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => const TraxSheet(),
);

/// TRAX mode in one place, in the map member card's style: off, what one
/// tap changes; on, what the radio is on, who is on TRAX and where, and
/// Leave. TRAX settings, behind the gear, explains the rest. Kept short: it
/// is read at the trailhead.
class TraxSheet extends StatefulWidget {
  const TraxSheet({super.key});

  @override
  State<TraxSheet> createState() => _TraxSheetState();
}

class _TraxSheetState extends State<TraxSheet> {
  String? _error;
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<TraxService>().loadAllowed());
    // "3m ago" keeps counting while nothing else changes.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _switch(TraxService trax) async {
    final l10n = context.l10n;
    final preset = trax.plannedPreset;
    setState(() => _error = null);
    final outcome = await trax.start();
    if (!mounted) return;
    setState(() => _error = traxOutcomeText(l10n, outcome, preset: preset));
    if (trax.isOn) await offerSosThroughDnd(context);
  }

  Future<void> _leave(TraxService trax) async {
    final l10n = context.l10n;
    setState(() => _error = null);
    final outcome = await traxLeave(context, trax);
    if (!mounted || outcome == null) return;
    setState(() => _error = traxOutcomeText(l10n, outcome));
  }

  Future<void> _check(TraxService trax) async {
    setState(() => _error = null);
    await trax.groupCheck();
  }

  @override
  Widget build(BuildContext context) {
    final trax = context.watch<TraxService>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final on = trax.isOn;
    final busy = trax.busy;
    final step = trax.step;
    return SingleChildScrollView(
      // Clear of Android's navigation bar: the sheet runs behind it.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context, trax),
          const SizedBox(height: 12),
          ...on ? _onParts(context, trax) : _offParts(context, trax),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            if (step != null) ...[
              const SizedBox(height: 8),
              Text(traxStepText(l10n, step)),
            ],
          ],
          if (on || trax.supported) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: on
                  ? FilledButton(
                      onPressed: busy ? null : () => _leave(trax),
                      child: Text(l10n.trax_leave),
                    )
                  : FilledButton(
                      onPressed: busy || !_ready(trax)
                          ? null
                          : () => _switch(trax),
                      child: Text(l10n.trax_switch),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  bool _ready(TraxService trax) {
    final end = trax.setup.until;
    return trax.plannedPreset != null &&
        end != null &&
        end.isAfter(DateTime.now()) &&
        (!trax.setup.tellGroup || trax.tripChannel != null);
  }

  /// The boot print on a disc, orange while TRAX mode is on; until when
  /// and on which channel; and the way to TRAX settings.
  Widget _header(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = trax.isOn;
    final end = trax.until;
    final subtitle = on
        ? [
            if (end != null) l10n.trax_until(traxTimeText(context, end)),
            if (trax.tripChannel case final channel?) channel.displayName,
          ].join(' · ')
        : '';
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: on
              ? const Color(Trax.orange)
              : scheme.surfaceContainerHighest,
          child: TraxIcon(color: on ? Colors.white : scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExperimentalTitle(
                Text(
                  on ? l10n.trax_isOn : l10n.trax_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.trax_settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TraxSettingsScreen()),
          ),
        ),
      ],
    );
  }

  List<Widget> _offParts(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    if (!trax.supported) {
      return [_note(context, Icons.error_outline, l10n.trax_unsupported)];
    }
    final now = trax.current;
    final planned = trax.plannedPreset;
    final setup = trax.setup;
    final end = setup.until;
    final hasEnd = end != null && end.isAfter(DateTime.now());
    final channel = trax.tripChannel;
    return [
      _chips([
        if (now != null)
          _chip(
            context,
            Icons.settings_input_antenna,
            now.label,
            name: l10n.trax_now,
            named: true,
          ),
        if (planned != null) ...[
          _chip(
            context,
            Icons.settings_input_antenna,
            planned.label,
            name: l10n.trax_inTrax,
            named: true,
            strong: true,
          ),
          _chip(context, Icons.repeat, l10n.trax_repeatOn),
          if (setup.advertPosition)
            _chip(context, Icons.share_location, l10n.locationSharing_adverts),
        ],
        _chip(
          context,
          Icons.event,
          hasEnd
              ? l10n.trax_until(traxTimeText(context, end))
              : l10n.trax_notSet,
          name: l10n.trax_tripEnds,
          named: !hasEnd,
          color: hasEnd ? null : error,
        ),
        _chip(
          context,
          Icons.forum_outlined,
          !setup.tellGroup
              ? l10n.trax_tellsNot
              : channel?.displayName ?? l10n.trax_none,
          name: l10n.trax_tripChannel,
          named: setup.tellGroup && channel == null,
          color: setup.tellGroup && channel == null ? error : null,
        ),
      ]),
    ];
  }

  List<Widget> _onParts(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final now = trax.current;
    final heard = trax.heard;
    final trip = context.watch<TripService>();
    final asks = context.watch<RadioAskService>();
    final positions = context.watch<TripPositions>();
    final members = [
      for (final m in trip.members) _member(context, trax, m, trip, positions),
    ];
    return [
      if (now != null)
        _chips([_chip(context, Icons.settings_input_antenna, now.label)]),
      const SizedBox(height: 4),
      _sending(context, trax),
      if (trax.session?.saved == null)
        _note(context, Icons.restore, l10n.trax_noSaved),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Text(
              members.isEmpty
                  ? l10n.trax_heard(
                      heard.length,
                      heard.map((c) => c.name).join(', '),
                    )
                  : l10n.trip_onTrax(
                      members.where((m) => m.on).length,
                      members.length,
                    ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          TextButton.icon(
            onPressed: trax.busy ? null : () => _check(trax),
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: Text(l10n.trax_checkAgain),
          ),
        ],
      ),
      for (final m in members) _memberTile(context, m, asks),
    ];
  }

  /// Where this phone's location goes, or why it doesn't.
  Widget _sending(BuildContext context, TraxService trax) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    final beacon = context.watch<TraxBeaconService>();
    if (trax.tripChannel == null) {
      return _note(context, Icons.share_location, l10n.trax_locationsNoChannel);
    }
    return switch (beacon.state) {
      TraxBeaconState.noLocation => _note(
        context,
        Icons.location_disabled,
        l10n.locationSharing_noPosition,
        color: error,
      ),
      TraxBeaconState.unsupported => _note(
        context,
        Icons.error_outline,
        l10n.trax_noChannelData,
        color: error,
      ),
      _ => _note(
        context,
        Icons.share_location,
        l10n.trax_sendingEvery(_minutes(context, beacon.interval)),
      ),
    };
  }

  /// A member's latest location, from their reports or their radio's
  /// answer, whichever is newer, and whether they are on TRAX: a contact as
  /// the group check hears them, anyone else by a report since TRAX mode
  /// started.
  _Member _member(
    BuildContext context,
    TraxService trax,
    TripMember member,
    TripService trip,
    TripPositions positions,
  ) {
    final contact = member.contact;
    final name = member.name.toLowerCase();
    final report = contact != null
        ? positions.of(contact)
        : positions.all.where((p) => p.name?.toLowerCase() == name).firstOrNull;
    final answer = contact == null
        ? null
        : context.read<RadioAskService>().positionOf(contact);
    var at = report?.heardAt;
    var place = report == null ? null : LatLng(report.lat, report.lon);
    var old = report?.mayBeOld ?? false;
    if (answer?.position case final p?
        when at == null || answer!.receivedAt.isAfter(at)) {
      at = answer!.receivedAt;
      place = LatLng(p.lat, p.lon);
      old = false;
    }
    final since = trax.heardSince;
    final on = contact != null
        ? trip.onTrax(contact)
        : report != null && since != null && !report.heardAt.isBefore(since);
    return (
      member: member,
      on: on,
      at: at,
      place: at == null ? null : place,
      old: old,
      trail: report?.prefix ?? contact?.publicKeyHex.substring(0, 8),
      icon: report?.icon,
    );
  }

  /// A member as the map's card heads them: when last heard, how long ago
  /// and how far, with a tap to the map; or where the group check stands.
  Widget _memberTile(BuildContext context, _Member m, RadioAskService asks) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final name = m.member.name;
    final contact = m.member.contact;
    if ((m.at, m.place, m.trail) case (final at?, final place?, final trail?)) {
      final from = _fromYou(context, place);
      return ListTile(
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(vertical: -4),
        leading: _avatar(context, old: m.old, icon: m.icon),
        title: Text(name),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: [
                  DateTimeHelper.timeWithDay(context, at),
                  losAge(l10n, at, DateTime.now()),
                  ?from,
                ].join(' · '),
              ),
              if (m.old)
                TextSpan(
                  text: ' · ${l10n.trax_mayBeOld}',
                  style: TextStyle(color: scheme.error),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => MapScreen.show(context, MapFocusMember(trail, place)),
      );
    }
    final (text, color) = contact != null && !m.on
        ? switch (asks.askFor(contact)?.phase) {
            RadioAskPhase.waiting ||
            RadioAskPhase.asking => (l10n.trip_asking(name), null),
            RadioAskPhase.noAnswer => (l10n.trip_noAnswer(name), scheme.error),
            _ => (l10n.trip_notHeardYet(name), null),
          }
        : (l10n.trax_memberNoLocation(name), null);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -4),
      leading: _avatar(context),
      title: Text(text, style: TextStyle(color: color)),
    );
  }

  /// Their icon on a disc: orange with a location, grey when it may be
  /// old, plain without one.
  Widget _avatar(BuildContext context, {bool? old, TraxMapIcon? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: switch (old) {
        null => scheme.surfaceContainerHighest,
        true => Colors.grey,
        false => const Color(Trax.orange),
      },
      child: Icon(
        traxIconData(icon),
        size: 18,
        color: old == null ? scheme.onSurfaceVariant : Colors.white,
      ),
    );
  }

  /// "0.4 mi NW", from this radio's position.
  String? _fromYou(BuildContext context, LatLng place) {
    final radio = context.read<MeshCoreConnector>();
    final units = context.read<AppSettingsService?>()?.settings.unitSystem;
    if (units == null ||
        !radio.hasValidLocation(radio.selfLatitude, radio.selfLongitude)) {
      return null;
    }
    final me = LatLng(radio.selfLatitude!, radio.selfLongitude!);
    return GeoFormat.offset(me, place, units).text;
  }

  /// "1", "2.5": an interval in minutes, in the app's language.
  static String _minutes(BuildContext context, Duration d) => NumberFormat(
    '0.#',
    Localizations.localeOf(context).toString(),
  ).format(d.inSeconds / 60);

  Widget _chips(List<Widget> chips) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);

  /// A value on a tonal chip, as on the map's member card: its [name] in
  /// front when [named], else on a long-press.
  Widget _chip(
    BuildContext context,
    IconData icon,
    String value, {
    String? name,
    bool named = false,
    Color? color,
    bool strong = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  if (named && name != null)
                    TextSpan(
                      text: '$name  ',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: color,
                      fontWeight: strong ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
    return name == null || named ? chip : Tooltip(message: name, child: chip);
  }

  Widget _note(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final shade = color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: shade),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: shade),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _Member = ({
  TripMember member,
  bool on,
  DateTime? at,
  LatLng? place,
  bool old,
  String? trail,
  TraxMapIcon? icon,
});
