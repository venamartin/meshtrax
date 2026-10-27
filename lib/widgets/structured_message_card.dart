import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/geo_format.dart';
import '../helpers/link_handler.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../screens/channel_chat_screen.dart';
import '../screens/chat_screen.dart';
import '../services/app_settings_service.dart';
import '../utils/calendar_export.dart';
import 'message_text.dart';
import 'mini_map.dart';

/// Colours of one card kind. Each kind has one accent per brightness; every
/// other colour is the accent's hue at a fixed saturation and lightness, so
/// all cards share one look and a new kind needs only its accents.
class StructuredPalette {
  final Color surface;
  final Color border;

  /// Fill of the badge, the date tile and the primary button.
  final Color accent;
  final Color onAccent;

  /// Accent-coloured text on the surface: the type label and the venue pin.
  final Color ink;
  final Color title;
  final Color body;
  final Color muted;

  /// Fill of the secondary buttons and the chips.
  final Color tonal;
  final Color onTonal;

  /// The pin on the map. Map tiles are light in both themes.
  final Color pin;

  /// Behind the distance label on the map, with [onScrim] for its arrow.
  final Color scrim;
  final Color onScrim;

  const StructuredPalette._({
    required this.surface,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.ink,
    required this.title,
    required this.body,
    required this.muted,
    required this.tonal,
    required this.onTonal,
    required this.pin,
    required this.scrim,
    required this.onScrim,
  });

  static StructuredPalette of(BuildContext context, StructuredMessage message) =>
      forAccents(accentsOf(message), Theme.of(context).brightness);

  /// (dark theme, light theme) accents of each kind. Share kinds use the
  /// colours the chats and contacts lists already give them.
  static (Color, Color) accentsOf(StructuredMessage message) =>
      switch (message) {
        EventMessage() => (const Color(0xFF8AB8FF), const Color(0xFF3367D6)),
        NoticeMessage() => (const Color(0xFFFFC24D), const Color(0xFFF2A900)),
        LocationMessage() =>
          (const Color(0xFF5FD4BF), const Color(0xFF00796B)),
        SosMessage() => (const Color(0xFFFF8A80), const Color(0xFFC62828)),
        ShareMessage(kind: ShareKind.channel) =>
          (const Color(0xFF90CAF9), const Color(0xFF1565C0)),
        ShareMessage(kind: ShareKind.room) =>
          (const Color(0xFFCE93D8), const Color(0xFF8E24AA)),
        ShareMessage(kind: ShareKind.repeater) =>
          (const Color(0xFFFFB74D), const Color(0xFFEF6C00)),
        ShareMessage() => (const Color(0xFF81C784), const Color(0xFF2E7D32)),
      };

  static StructuredPalette forAccents(
    (Color, Color) accents,
    Brightness brightness,
  ) {
    final (dark, light) = accents;
    final h = HSLColor.fromColor(light).hue;
    final deep = _hsl(h, 0.55, 0.11);
    if (brightness == Brightness.dark) {
      return StructuredPalette._(
        surface: _hsl(h, 0.48, 0.16),
        border: _hsl(h, 0.45, 0.27),
        accent: dark,
        onAccent: deep,
        ink: dark,
        title: _hsl(h, 0.70, 0.94),
        body: _hsl(h, 0.30, 0.86),
        muted: _hsl(h, 0.25, 0.70),
        tonal: _hsl(h, 0.45, 0.25),
        onTonal: _hsl(h, 0.65, 0.87),
        pin: light,
        scrim: deep,
        onScrim: dark,
      );
    }
    return StructuredPalette._(
      surface: _hsl(h, 0.65, 0.94),
      border: _hsl(h, 0.45, 0.80),
      accent: light,
      onAccent: contrast(Colors.white, light) >= contrast(deep, light)
          ? Colors.white
          : deep,
      ink: _hsl(h, 0.75, 0.26),
      title: _hsl(h, 0.50, 0.12),
      body: _hsl(h, 0.25, 0.18),
      muted: _hsl(h, 0.20, 0.36),
      tonal: _hsl(h, 0.55, 0.86),
      onTonal: _hsl(h, 0.60, 0.20),
      pin: light,
      scrim: deep,
      onScrim: dark,
    );
  }

  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s, l).toColor();

  /// WCAG contrast ratio between two colours.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}

class _Action {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _Action(this.icon, this.label, this.onTap, {this.primary = true});
}

/// Renders a parsed [StructuredMessage] as the whole chat bubble: the
/// screens give the bubble [bubbleDecoration] and put the sender, reply
/// quote and [StructuredCardFooter] around this.
class StructuredMessageCard extends StatelessWidget {
  final StructuredMessage message;
  final double textScale;

  /// The clock for an event's Today / Past chip; tests pin it.
  final DateTime? now;

  /// Whose message this is. A Location titled "My location" is the
  /// sender's own position: "My location" on yours, "{name}'s location" on
  /// others ([locationTitle]).
  final bool isOutgoing;
  final String? senderName;

  const StructuredMessageCard({
    super.key,
    required this.message,
    required this.textScale,
    this.now,
    this.isOutgoing = false,
    this.senderName,
  });

  /// What a location is called on screen: the sender's own position by
  /// whose it is, any other title as written, no title just "Location".
  static String locationTitle(
    AppLocalizations l10n,
    LocationMessage m, {
    required bool isOutgoing,
    String? senderName,
  }) {
    if (!m.isSendersOwn) {
      final label = m.label;
      return label == null || label.isEmpty ? l10n.chat_location : label;
    }
    if (isOutgoing) return l10n.tray_myLocation;
    return senderName == null || senderName.isEmpty
        ? l10n.chat_location
        : l10n.structured_locationOf(senderName);
  }

  /// The icon that stands for a message type in previews and pinned rows.
  static IconData iconFor(StructuredMessage message) => switch (message) {
        LocationMessage() => Icons.location_on,
        SosMessage() => Icons.warning_rounded,
        EventMessage() => Icons.event,
        NoticeMessage() => Icons.campaign,
        ShareMessage(:final kind) => switch (kind) {
            ShareKind.channel => Icons.tag,
            ShareKind.contact => Icons.person,
            ShareKind.room => Icons.meeting_room,
            ShareKind.repeater => Icons.cell_tower,
            ShareKind.sensor => Icons.sensors,
          },
      };

  /// Cards need room for a map and a row of buttons, more than a text
  /// bubble's 65%. The size only: a row that read all of MediaQuery was
  /// built again on every frame of the keyboard sliding.
  static double maxBubbleWidth(BuildContext context) =>
      math.min(MediaQuery.sizeOf(context).width * 0.85, 420);

  static BoxDecoration bubbleDecoration(
    BuildContext context,
    StructuredMessage message, {
    bool failed = false,
  }) {
    final p = StructuredPalette.of(context, message);
    return BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      border: failed
          ? Border.all(color: Theme.of(context).colorScheme.error, width: 1.5)
          : Border.all(color: p.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = StructuredPalette.of(context, message);
    return switch (message) {
      LocationMessage m => _locationCard(context, p, m),
      SosMessage m => _scaffold(
          context,
          p,
          lead: _badge(p, Icons.warning_rounded),
          overline: l10n.structured_sos,
          title: m.text.isEmpty ? l10n.structured_sos : m.text,
          richTitle: m.text.isNotEmpty,
          lines: [?m.note],
          position: m.position,
          positionLabel: l10n.structured_sos,
          actions: [
            _Action(
              Icons.near_me_outlined,
              l10n.structured_navigate,
              () => LinkHandler.openInMapsApp(context, m.position,
                  label: l10n.structured_sos),
            ),
            _Action(
              Icons.map_outlined,
              l10n.structured_map,
              () => LinkHandler.openMapAt(context, m.position,
                  label: l10n.structured_sos),
              primary: false,
            ),
          ],
        ),
      EventMessage m => _event(context, p, m),
      NoticeMessage m => _notice(context, p, m),
      ShareMessage m => _share(context, p, m),
    };
  }

  Widget _notice(BuildContext context, StructuredPalette p, NoticeMessage m) {
    final l10n = context.l10n;
    final expired = m.isExpired(now ?? DateTime.now());
    final card = _scaffold(
      context,
      p,
      lead: _badge(p, Icons.campaign),
      overline: m.announcement
          ? l10n.structured_announcement
          : l10n.structured_notice,
      title: m.headline,
      titleSize: 18,
      richTitle: true,
      chips: [
        if (expired)
          _chip(p, l10n.structured_expired)
        else if (m.expires != null)
          _chip(p, l10n.structured_until(_expiryText(context, m))),
      ],
      lines: m.lines.skip(1).toList(),
      position: m.position,
      positionLabel: m.headline,
      actions: [
        if (m.position != null)
          _Action(
            Icons.map_outlined,
            l10n.structured_map,
            () => LinkHandler.openMapAt(context, m.position!, label: m.headline),
            primary: false,
          ),
      ],
    );
    return expired ? Opacity(opacity: 0.6, child: card) : card;
  }

  /// "Thu, Oct 30" for the end of a day, else "Thu, Oct 30, 6:00 PM".
  static String _expiryText(BuildContext context, NoticeMessage m) {
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.MMMEd(locale).format(m.expiryDay);
    if (m.expiresAtDayEnd) return day;
    return '$day, ${DateFormat.jm(locale).format(m.expires!)}';
  }

  Widget _event(BuildContext context, StructuredPalette p, EventMessage m) {
    final l10n = context.l10n;
    final clock = now ?? DateTime.now();
    final when = m.when;
    final past = !when.effectiveEnd.isAfter(clock);
    final days = EventWhen.daysBetween(clock, when.start);
    final dayCount = when.dayCount;
    final running = !past && days < 0;
    final relative = past
        ? l10n.structured_past
        : running && dayCount > 1
            ? l10n.structured_dayOfDays(1 - days, dayCount)
            : days <= 0
                ? l10n.structured_today
                : days == 1
                    ? l10n.structured_tomorrow
                    : l10n.structured_inDays(days);
    final card = _scaffold(
      context,
      p,
      lead: _dateTile(context, p, when),
      overline: l10n.structured_event,
      title: m.title,
      chips: [
        Tooltip(
          message: _whenText(context, m.when),
          child: _chip(p, relative, highlight: !past && days <= 0),
        ),
        _chip(p, _timeChip(context, m.when)),
      ],
      venue: m.place,
      position: m.position,
      positionLabel: m.title,
      actions: [
        if (!past)
          _Action(Icons.event_available, l10n.structured_addToCalendar,
              () => _addToCalendar(context, m)),
        if (m.position != null)
          _Action(
            Icons.map_outlined,
            l10n.structured_map,
            () => LinkHandler.openMapAt(context, m.position!, label: m.title),
            primary: false,
          ),
      ],
    );
    return past ? Opacity(opacity: 0.6, child: card) : card;
  }

  Widget _share(BuildContext context, StructuredPalette p, ShareMessage m) {
    final l10n = context.l10n;
    final (have, isSelf) = context.select<MeshCoreConnector, (bool, bool)>(
      (c) => (_haveShared(c, m), _isSelf(c, m)),
    );
    final (overline, addLabel) = switch (m.kind) {
      ShareKind.channel => (l10n.structured_channel, l10n.structured_joinChannel),
      ShareKind.contact => (l10n.structured_contact, l10n.structured_addContact),
      ShareKind.room => (l10n.structured_room, l10n.structured_addRoom),
      ShareKind.repeater => (l10n.structured_repeater, l10n.structured_addRepeater),
      ShareKind.sensor => (l10n.structured_sensor, l10n.structured_addSensor),
    };
    final canOpen = m.kind == ShareKind.channel ||
        m.kind == ShareKind.contact ||
        m.kind == ShareKind.room;
    final _Action? action = isSelf
        ? null
        : !have
            ? _Action(Icons.add, addLabel,
                () => LinkHandler.handleMeshCoreLink(context, m.url))
            : canOpen
                ? _Action(Icons.chat_bubble_outline, l10n.structured_open,
                    () => _openShared(context, m))
                : _Action(Icons.check, l10n.structured_added, null,
                    primary: false);
    return _scaffold(
      context,
      p,
      lead: _badge(p, iconFor(m)),
      overline: overline,
      title: m.name.isEmpty ? overline : m.name,
      lines: [?m.note],
      // A channel's key is its secret: the join dialog shows it, not chat.
      keyRow: m.kind == ShareKind.channel
          ? null
          : _copyRow(
              context,
              p,
              text: '${m.keyHex.substring(0, 8).toUpperCase()}…',
              copy: m.keyHex,
            ),
      actions: [?action],
    );
  }

  static bool _haveShared(MeshCoreConnector c, ShareMessage m) {
    final key = m.keyHex.toLowerCase();
    if (m.kind == ShareKind.channel) {
      return c.channels.any((ch) => ch.idKey.toLowerCase() == key);
    }
    return c.contacts.any((ct) => ct.publicKeyHex.toLowerCase() == key);
  }

  static bool _isSelf(MeshCoreConnector c, ShareMessage m) =>
      m.kind != ShareKind.channel &&
      c.selfPublicKeyHex.toLowerCase() == m.keyHex.toLowerCase();

  void _openShared(BuildContext context, ShareMessage m) {
    final connector = context.read<MeshCoreConnector>();
    final key = m.keyHex.toLowerCase();
    if (m.kind == ShareKind.channel) {
      final channel = connector.channels
          .where((c) => c.idKey.toLowerCase() == key)
          .firstOrNull;
      if (channel == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
      );
      return;
    }
    final contact = connector.contacts
        .where((c) => c.publicKeyHex.toLowerCase() == key)
        .firstOrNull;
    // A room asks for its password when none is remembered.
    if (contact != null) ChatScreen.open(context, contact);
  }

  Widget _locationCard(
    BuildContext context,
    StructuredPalette p,
    LocationMessage m,
  ) {
    final l10n = context.l10n;
    final title = locationTitle(
      l10n,
      m,
      isOutgoing: isOutgoing,
      senderName: senderName,
    );
    // A place without a title gets no name on the map either.
    final pinLabel = m.label == null ? null : title;
    return _scaffold(
      context,
      p,
      lead: _badge(p, Icons.location_on),
      overline: m.label == null || m.isSendersOwn ? null : l10n.chat_location,
      title: title,
      lines: [?m.note],
      position: m.position,
      positionLabel: pinLabel,
      actions: [
        _Action(Icons.map_outlined, l10n.structured_openMap,
            () => LinkHandler.openMapAt(context, m.position, label: pinLabel)),
        _Action(
          Icons.near_me_outlined,
          l10n.structured_navigate,
          () => LinkHandler.openInMapsApp(context, m.position, label: pinLabel),
          primary: false,
        ),
      ],
    );
  }

  Widget _scaffold(
    BuildContext context,
    StructuredPalette p, {
    required Widget lead,
    String? overline,
    required String title,
    double titleSize = 21,

    /// Markdown and tappable links in the title: written text, not a name.
    bool richTitle = false,
    List<Widget> chips = const [],
    String? venue,
    List<String> lines = const [],
    LatLng? position,
    String? positionLabel,
    Widget? keyRow,
    List<_Action> actions = const [],
  }) {
    final l10n = context.l10n;
    final link = message.link;
    final allActions = [
      ...actions,
      if (link != null)
        _Action(Icons.open_in_new, l10n.structured_details,
            () => LinkHandler.handleLinkTap(context, link),
            primary: actions.isEmpty),
    ];
    final bodyStyle =
        TextStyle(color: p.body, fontSize: 14 * textScale, height: 1.3);
    final titleStyle = TextStyle(
      color: p.title,
      fontSize: titleSize * textScale,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            lead,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (overline != null)
                    Text(
                      overline.toUpperCase(),
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 11 * textScale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  if (richTitle)
                    MessageText(text: title, style: titleStyle)
                  else
                    Text(title, style: titleStyle),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: chips),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (venue != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18 * textScale, color: p.ink),
              const SizedBox(width: 6),
              Flexible(child: MessageText(text: venue, style: bodyStyle)),
            ],
          ),
        ],
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MessageText(text: line, style: bodyStyle),
          ),
        if (position != null) ...[
          const SizedBox(height: 12),
          _map(context, p, position, positionLabel),
          const SizedBox(height: 2),
          _copyRow(
            context,
            p,
            text: StructuredMessage.formatCoordinates(position),
          ),
        ],
        ?keyRow,
        for (final line in message.extraText)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: MessageText(text: line, style: bodyStyle),
          ),
        for (final e in message.extensions.entries)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${e.key}: ${e.value}',
              style: TextStyle(color: p.muted, fontSize: 12 * textScale),
            ),
          ),
        if (allActions.isNotEmpty) ...[
          SizedBox(height: position != null || keyRow != null ? 6 : 14),
          _actionRow(context, p, allActions),
        ],
      ],
    );
  }

  Widget _badge(StructuredPalette p, IconData icon) => Container(
        width: 40 * textScale,
        height: 40 * textScale,
        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        child: Icon(icon, size: 22 * textScale, color: p.onAccent),
      );

  /// Month over day; a multi-day event shows its range, "OCT / 20–22" or
  /// "OCT–NOV / 30–2".
  Widget _dateTile(BuildContext context, StructuredPalette p, EventWhen when) {
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.MMM(locale);
    final day = DateFormat.d(locale);
    final start = when.start;
    final end = when.dayCount > 1 ? when.end : null;
    final months = end == null || end.month == start.month
        ? month.format(start)
        : '${month.format(start)}–${month.format(end)}';
    final days =
        end == null ? day.format(start) : '${day.format(start)}–${day.format(end)}';
    return Container(
      constraints: BoxConstraints(minWidth: 56 * textScale),
      height: 62 * textScale,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            months.toUpperCase(),
            style: TextStyle(
              color: p.onAccent,
              fontSize: 12 * textScale,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 1.1,
            ),
          ),
          Text(
            days,
            style: TextStyle(
              color: p.onAccent,
              fontSize: (end == null ? 26 : 22) * textScale,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(StructuredPalette p, String text, {bool highlight = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: highlight ? p.accent : p.tonal,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: highlight ? p.onAccent : p.onTonal,
            fontSize: 12 * textScale,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _map(
    BuildContext context,
    StructuredPalette p,
    LatLng position,
    String? label,
  ) {
    final (lat, lon) = context.select<MeshCoreConnector, (double?, double?)>(
      (c) => (c.selfLatitude, c.selfLongitude),
    );
    final units = context.select<AppSettingsService, UnitSystem>(
      (s) => s.settings.unitSystem,
    );
    final offset = GeoFormat.isValidPosition(lat, lon)
        ? GeoFormat.offset(LatLng(lat!, lon!), position, units)
        : null;
    return Stack(
      children: [
        MiniMap(
          position: position,
          label: label,
          markerColor: p.pin,
          height: 170,
        ),
        // Your own shared spot is "0 m N" away: say nothing.
        if (offset != null && offset.meters >= 50)
          Positioned(
            left: 10,
            bottom: 10,
            child: IgnorePointer(child: _distanceLabel(p, offset)),
          ),
      ],
    );
  }

  Widget _distanceLabel(StructuredPalette p, GeoOffset offset) => Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: p.scrim.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: offset.bearing * math.pi / 180,
              child: Icon(Icons.navigation, size: 13, color: p.onScrim),
            ),
            const SizedBox(width: 6),
            Text(
              offset.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  /// Small mono text that copies [copy] (or [text]) when tapped.
  Widget _copyRow(
    BuildContext context,
    StructuredPalette p, {
    required String text,
    String? copy,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Clipboard.setData(ClipboardData(text: copy ?? text));
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.common_copiedToClipboard),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: p.muted,
                  fontSize: 12 * textScale,
                  // "monospace" only exists on Android.
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Consolas', 'DejaVu Sans Mono'],
                ),
              ),
            ),
            Icon(Icons.copy_rounded, size: 16, color: p.muted),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context,
    StructuredPalette p,
    List<_Action> actions,
  ) {
    final first = actions.first;
    final second = actions.length > 1 ? actions[1] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _button(context, p, first)),
            if (second != null) ...[
              const SizedBox(width: 8),
              _button(context, p, second),
            ],
          ],
        ),
        if (actions.length > 2) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final a in actions.skip(2)) _button(context, p, a)],
          ),
        ],
      ],
    );
  }

  Widget _button(BuildContext context, StructuredPalette p, _Action a) {
    return FilledButton.icon(
      onPressed: a.onTap,
      style: FilledButton.styleFrom(
        backgroundColor: a.primary ? p.accent : p.tonal,
        foregroundColor: a.primary ? p.onAccent : p.onTonal,
        disabledBackgroundColor: p.tonal,
        disabledForegroundColor: p.onTonal,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        // From the theme, or the label loses the app's font family.
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 14 * textScale,
              fontWeight: FontWeight.w600,
            ),
      ),
      icon: Icon(a.icon, size: 18),
      label: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  /// "All day", "3 days" (the dates are in the tile), "6:30 PM – 8:00 PM",
  /// or "6:00 PM – Sat 12:00 PM" when it ends on another day.
  static String _timeChip(BuildContext context, EventWhen when) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale);
    final time = DateFormat.jm(locale);
    final start = when.start;
    final end = when.end;
    if (when.allDay) {
      return when.dayCount > 1
          ? l10n.structured_days(when.dayCount)
          : l10n.structured_allDay;
    }
    if (end == null) return time.format(start);
    if (_sameDay(start, end)) return '${time.format(start)} – ${time.format(end)}';
    return '${time.format(start)} – ${weekday.format(end)} ${time.format(end)}';
  }

  static String _whenText(BuildContext context, EventWhen when) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.yMMMEd(locale);
    final time = DateFormat.jm(locale);
    final start = when.start;
    final end = when.end;
    if (when.allDay) {
      final text = day.format(start);
      if (end == null || _sameDay(start, end)) return '$text · ${l10n.structured_allDay}';
      return '$text – ${day.format(end)}';
    }
    final head = '${day.format(start)} ${time.format(start)}';
    if (end == null) return head;
    if (_sameDay(start, end)) return '$head – ${time.format(end)}';
    return '$head – ${day.format(end)} ${time.format(end)}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addToCalendar(BuildContext context, EventMessage event) async {
    final ok = await CalendarExport.addEvent(event);
    if (!ok && context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.structured_calendarFailed),
        backgroundColor: Colors.red,
      );
    }
  }
}

/// The one meta line under a card: "12:29 · A277 › BEEF · ⟲ 3", with the
/// delivery ticks on the right. Ticks keep their own status colours.
class StructuredCardFooter extends StatelessWidget {
  final StructuredMessage message;
  final String? time;

  /// Hop prefixes as the screens format them ("A277,BEEF").
  final String? path;
  final int repeats;
  final List<String> extra;
  final Widget? status;

  const StructuredCardFooter({
    super.key,
    required this.message,
    this.time,
    this.path,
    this.repeats = 0,
    this.extra = const [],
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final p = StructuredPalette.of(context, message);
    final style = TextStyle(fontSize: 12, color: p.muted);
    final spans = <InlineSpan>[];
    void add(InlineSpan span) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(span);
    }

    if (time != null) add(TextSpan(text: time));
    if (path != null && path!.isNotEmpty) {
      add(TextSpan(text: path!.split(',').join(' › ')));
    }
    if (repeats > 0) {
      add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat, size: 12, color: p.muted),
            const SizedBox(width: 2),
            Text('$repeats', style: style),
          ],
        ),
      ));
    }
    for (final e in extra) {
      add(TextSpan(text: e));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(child: Text.rich(TextSpan(style: style, children: spans))),
          if (status != null) ...[const SizedBox(width: 8), status!],
        ],
      ),
    );
  }
}
