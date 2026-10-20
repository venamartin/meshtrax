import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';

/// One message the pinned bar may pick from.
class PinCandidate {
  final String id;
  final String text;
  final DateTime timestamp;

  /// Index in the list the screen scrolls, so a tap can jump there.
  final int index;

  /// Rooms: a post the room server authored (room.post).
  final bool serverAuthored;

  const PinCandidate({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.index,
    this.serverAuthored = false,
  });
}

class PinnedEntry {
  final String id;
  final StructuredMessage message;
  final int index;

  const PinnedEntry({required this.id, required this.message, required this.index});
}

/// The bar above a chat's message list. Which messages it shows is decided
/// by [compute]; the screen only supplies candidates and dismissals.
///
/// Rules: the newest SOS pins everywhere until dismissed or replaced; the
/// next upcoming Event pins until it has passed; a room's newest
/// server-authored post pins; a Location never pins.
class PinnedMessagesBar extends StatelessWidget {
  final List<PinnedEntry> entries;
  final void Function(PinnedEntry entry) onTap;
  final void Function(PinnedEntry entry) onDismiss;

  const PinnedMessagesBar({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onDismiss,
  });

  static List<PinnedEntry> compute({
    required Iterable<PinCandidate> candidates,
    required Set<String> dismissed,
    required bool isRoom,
    DateTime? now,
    LatLng? Function(String url)? resolveShortLink,
  }) {
    final clock = now ?? DateTime.now();
    PinnedEntry? sos;
    PinnedEntry? event;
    PinnedEntry? notice;
    DateTime? sosAt;
    DateTime? noticeAt;

    for (final c in candidates) {
      if (dismissed.contains(c.id)) continue;
      final parsed =
          StructuredMessage.parse(c.text, resolveShortLink: resolveShortLink, now: clock);

      if (parsed is SosMessage) {
        if (sosAt == null || c.timestamp.isAfter(sosAt)) {
          sos = PinnedEntry(id: c.id, message: parsed, index: c.index);
          sosAt = c.timestamp;
        }
      } else if (parsed is EventMessage) {
        if (!parsed.when.effectiveEnd.isAfter(clock)) continue;
        final current = event?.message as EventMessage?;
        if (current == null || parsed.when.start.isBefore(current.when.start)) {
          event = PinnedEntry(id: c.id, message: parsed, index: c.index);
        }
      }

      if (isRoom && c.serverAuthored) {
        if (noticeAt == null || c.timestamp.isAfter(noticeAt)) {
          final NoticeMessage message = parsed is NoticeMessage
              ? parsed
              : NoticeMessage(lines: [c.text.trim()]);
          if (message.lines.first.isNotEmpty) {
            notice = PinnedEntry(id: c.id, message: message, index: c.index);
            noticeAt = c.timestamp;
          }
        }
      }
    }
    return [?sos, ?event, ?notice];
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries) _row(context, entry, scheme),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PinnedEntry entry, ColorScheme scheme) {
    final (icon, color) = switch (entry.message) {
      SosMessage() => (Icons.warning_rounded, scheme.error),
      EventMessage() => (Icons.event, scheme.primary),
      NoticeMessage() => (Icons.campaign, Colors.purple),
      LocationMessage() => (Icons.location_on, scheme.primary),
    };
    return InkWell(
      onTap: () => onTap(entry),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.message.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: context.l10n.pinned_dismiss,
              visualDensity: VisualDensity.compact,
              onPressed: () => onDismiss(entry),
            ),
          ],
        ),
      ),
    );
  }
}
