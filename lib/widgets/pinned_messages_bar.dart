import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import 'structured_message_card.dart';

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
/// next upcoming Event pins until it has passed. In a room, the server's own
/// posts (room.post) stack, newest first: every notice until it expires,
/// every event until it is over, and the newest of the rest (a plain
/// announcement). A Location never pins, nor does a channel's or DM's
/// notice. An entry that runs out while the chat is open drops off on its
/// own.
class PinnedMessagesBar extends StatefulWidget {
  final List<PinnedEntry> entries;
  final void Function(PinnedEntry entry) onTap;
  final void Function(PinnedEntry entry) onDismiss;

  const PinnedMessagesBar({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onDismiss,
  });

  static const maxRows = 5;

  static List<PinnedEntry> compute({
    required Iterable<PinCandidate> candidates,
    required Set<String> dismissed,
    required bool isRoom,
    DateTime? now,
    LatLng? Function(String url)? resolveShortLink,
  }) {
    final clock = now ?? DateTime.now();
    PinnedEntry? sos;
    DateTime? sosAt;
    PinnedEntry? event;
    final serverPosts = <(DateTime, PinnedEntry)>[];
    (DateTime, PinnedEntry)? announcement;

    for (final c in candidates) {
      if (dismissed.contains(c.id)) continue;
      final server = isRoom && c.serverAuthored;
      final parsed = server
          ? StructuredMessage.parseAnnouncement(c.text,
              resolveShortLink: resolveShortLink, now: clock)
          : StructuredMessage.parse(c.text,
              resolveShortLink: resolveShortLink, now: clock);
      if (parsed == null) continue;
      final entry = PinnedEntry(id: c.id, message: parsed, index: c.index);

      switch (parsed) {
        case SosMessage():
          if (sosAt == null || c.timestamp.isAfter(sosAt)) {
            sos = entry;
            sosAt = c.timestamp;
          }
        case EventMessage(when: final span):
          if (!span.effectiveEnd.isAfter(clock)) continue;
          if (server) {
            serverPosts.add((c.timestamp, entry));
          } else {
            final current = event?.message as EventMessage?;
            if (current == null || span.start.isBefore(current.when.start)) {
              event = entry;
            }
          }
        case NoticeMessage(:final expires?) when server:
          if (expires.isAfter(clock)) serverPosts.add((c.timestamp, entry));
        default:
          if (server &&
              (announcement == null || c.timestamp.isAfter(announcement.$1))) {
            announcement = (c.timestamp, entry);
          }
      }
    }
    if (announcement != null) serverPosts.add(announcement);
    serverPosts.sort((a, b) => b.$1.compareTo(a.$1));
    return [?sos, for (final (_, e) in serverPosts) e, ?event]
        .take(maxRows)
        .toList();
  }

  /// Whether [entry] still pins at [now]: an event until it is over, a
  /// notice until it expires.
  static bool stillPinned(PinnedEntry entry, DateTime now) =>
      switch (entry.message) {
        EventMessage(when: final span) => span.effectiveEnd.isAfter(now),
        NoticeMessage m => !m.isExpired(now),
        _ => true,
      };

  /// The soonest moment one of [entries] stops pinning, or null.
  static DateTime? nextChange(Iterable<PinnedEntry> entries) {
    DateTime? soonest;
    for (final e in entries) {
      final at = switch (e.message) {
        EventMessage(when: final span) => span.effectiveEnd,
        NoticeMessage(:final expires) => expires,
        _ => null,
      };
      if (at != null && (soonest == null || at.isBefore(soonest))) {
        soonest = at;
      }
    }
    return soonest;
  }

  @override
  State<PinnedMessagesBar> createState() => _PinnedMessagesBarState();
}

class _PinnedMessagesBarState extends State<PinnedMessagesBar> {
  Timer? _timer;
  DateTime? _timerAt;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Rebuilds once [at] has passed, so an entry that runs out leaves.
  void _wakeAt(DateTime? at) {
    if (at == _timerAt) return;
    _timer?.cancel();
    _timerAt = at;
    if (at == null) return;
    final wait = at.difference(DateTime.now());
    _timer = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() => _timerAt = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = widget.entries
        .where((e) => PinnedMessagesBar.stillPinned(e, now))
        .toList();
    _wakeAt(PinnedMessagesBar.nextChange(entries));
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
    return InkWell(
      onTap: () => widget.onTap(entry),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        child: Row(
          children: [
            Icon(
              StructuredMessageCard.iconFor(entry.message),
              size: 18,
              color: StructuredPalette.of(context, entry.message).ink,
            ),
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
              onPressed: () => widget.onDismiss(entry),
            ),
          ],
        ),
      ),
    );
  }
}
