import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/link_handler.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../screens/map_screen.dart';
import '../utils/calendar_export.dart';
import 'mini_map.dart';

/// Renders a parsed [StructuredMessage] inside a chat bubble: a Location,
/// SOS, Event or Notice card with a mini map and actions where they apply.
class StructuredMessageCard extends StatelessWidget {
  final StructuredMessage message;
  final Color textColor;
  final double textScale;

  /// Shown at the end of the header row, e.g. the delivery status icon.
  final Widget? trailing;

  const StructuredMessageCard({
    super.key,
    required this.message,
    required this.textColor,
    required this.textScale,
    this.trailing,
  });

  /// The icon that stands for a message type in previews and pinned rows.
  static IconData iconFor(StructuredMessage message) => switch (message) {
        LocationMessage() => Icons.location_on,
        SosMessage() => Icons.warning_rounded,
        EventMessage() => Icons.event,
        NoticeMessage() => Icons.campaign,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return switch (message) {
      LocationMessage m => _frame(
          context,
          icon: Icons.location_on,
          iconColor: scheme.primary,
          title: m.label ?? l10n.chat_location,
          caption: m.label == null ? null : l10n.chat_location,
          lines: [if (m.note != null) m.note!],
          position: m.position,
          positionLabel: m.label,
          markerColor: scheme.primary,
        ),
      SosMessage m => _frame(
          context,
          icon: Icons.warning_rounded,
          iconColor: scheme.error,
          title: m.text.isEmpty ? l10n.structured_sos : m.text,
          caption: l10n.structured_sos,
          lines: [if (m.note != null) m.note!],
          position: m.position,
          positionLabel: l10n.structured_sos,
          markerColor: scheme.error,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
      EventMessage m => _frame(
          context,
          icon: Icons.event,
          iconColor: scheme.primary,
          title: m.title,
          caption: l10n.structured_event,
          lines: [
            _whenText(context, m.when),
            if (m.place != null) m.place!,
          ],
          position: m.position,
          positionLabel: m.title,
          markerColor: scheme.primary,
          extraActions: [
            TextButton.icon(
              onPressed: () => _addToCalendar(context, m),
              icon: const Icon(Icons.event_available, size: 18),
              label: Text(l10n.structured_addToCalendar),
            ),
          ],
        ),
      NoticeMessage m => _frame(
          context,
          icon: Icons.campaign,
          iconColor: Colors.purple,
          title: m.headline,
          caption: l10n.structured_notice,
          lines: m.lines.skip(1).toList(),
          position: m.position,
          positionLabel: m.headline,
          markerColor: Colors.purple,
          background: Colors.purple.withValues(alpha: 0.12),
        ),
    };
  }

  Widget _frame(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? caption,
    required List<String> lines,
    required LatLng? position,
    String? positionLabel,
    required Color markerColor,
    Color? background,
    Color? foreground,
    List<Widget> extraActions = const [],
  }) {
    final l10n = context.l10n;
    final fg = foreground ?? textColor;
    final meta = fg.withValues(alpha: 0.7);
    final actions = <Widget>[
      ...extraActions,
      if (message.link != null)
        TextButton.icon(
          onPressed: () => LinkHandler.handleLinkTap(context, message.link!),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.structured_details),
        ),
      if (position != null)
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(
                highlightPosition: position,
                highlightLabel: positionLabel,
              ),
            ),
          ),
          icon: const Icon(Icons.map, size: 18),
          label: Text(l10n.structured_openMap),
        ),
    ];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22 * textScale),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption != null)
                    Text(
                      caption,
                      style: TextStyle(
                        color: meta,
                        fontSize: 11 * textScale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15 * textScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              line,
              style: TextStyle(color: fg, fontSize: 13 * textScale),
            ),
          ),
        if (position != null) ...[
          const SizedBox(height: 8),
          MiniMap(
            position: position,
            label: positionLabel,
            markerColor: markerColor,
          ),
          const SizedBox(height: 4),
          LinkHandler.buildLinkifyText(
            context: context,
            text: StructuredMessage.formatCoordinates(position),
            style: TextStyle(color: meta, fontSize: 12 * textScale),
          ),
        ],
        for (final line in message.extraText)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              line,
              style: TextStyle(color: fg, fontSize: 13 * textScale),
            ),
          ),
        for (final e in message.extensions.entries)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${e.key}: ${e.value}',
              style: TextStyle(color: meta, fontSize: 11 * textScale),
            ),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(spacing: 4, children: actions),
          ),
      ],
    );

    if (background == null) return body;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: body,
    );
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
