import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/date_time_helper.dart';
import '../helpers/markdown_helper.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
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

  /// An SOS its sender repeats: when the latest repeat came in.
  final DateTime? sosUpdatedAt;

  /// An SOS its sender cancelled, which no longer pins.
  final bool sosCancelled;

  const PinCandidate({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.index,
    this.serverAuthored = false,
    this.sosUpdatedAt,
    this.sosCancelled = false,
  });
}

class PinnedEntry {
  final String id;
  final StructuredMessage message;
  final int index;

  /// An SOS: when it was sent, or last repeated, shown on its row.
  final DateTime? at;

  const PinnedEntry({
    required this.id,
    required this.message,
    required this.index,
    this.at,
  });
}

/// The bar above a chat's message list. Which messages it shows is decided
/// by [compute]; the screen only supplies candidates and dismissals.
///
/// Rules: everything stacks, one row per message, each until dismissed
/// (owner, 2026-10-26: "if three came in, you should see them all"). Every
/// SOS until dismissed or cancelled, newest (or newest repeated) first,
/// with its time; then every Event until it is over, soonest first;
/// then every notice until it expires, newest first; in a room only the
/// server's own notices (room.post), with the newest of the server's other
/// posts (a plain announcement) last. A Location never pins. An entry that
/// runs out while the chat is open drops off on its own.
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
  }) {
    final clock = now ?? DateTime.now();
    final sos = <(DateTime, PinnedEntry)>[];
    // Keyed by start, not by when it was posted.
    final events = <(DateTime, PinnedEntry)>[];
    final notices = <(DateTime, PinnedEntry)>[];
    (DateTime, PinnedEntry)? announcement;

    for (final c in candidates) {
      if (dismissed.contains(c.id)) continue;
      final server = isRoom && c.serverAuthored;
      final parsed = server
          ? StructuredMessage.parseAnnouncement(c.text, now: clock)
          : StructuredMessage.parse(c.text, now: clock);
      if (parsed == null) continue;
      if (parsed is SosMessage) {
        if (c.sosCancelled) continue;
        final at = c.sosUpdatedAt ?? c.timestamp;
        sos.add((
          at,
          PinnedEntry(id: c.id, message: parsed, index: c.index, at: at),
        ));
        continue;
      }
      final entry = PinnedEntry(id: c.id, message: parsed, index: c.index);

      switch (parsed) {
        case EventMessage(when: final span):
          if (span.effectiveEnd.isAfter(clock)) events.add((span.start, entry));
        case NoticeMessage(:final expires?) when server:
          if (expires.isAfter(clock)) notices.add((c.timestamp, entry));
        // In a room a member's notice is just a post.
        case NoticeMessage notice when !isRoom:
          if (!notice.isExpired(clock)) notices.add((c.timestamp, entry));
        default:
          if (server &&
              (announcement == null || c.timestamp.isAfter(announcement.$1))) {
            announcement = (c.timestamp, entry);
          }
      }
    }
    int newestFirst((DateTime, PinnedEntry) a, (DateTime, PinnedEntry) b) =>
        b.$1.compareTo(a.$1);
    sos.sort(newestFirst);
    events.sort((a, b) => a.$1.compareTo(b.$1));
    notices.sort(newestFirst);
    return [
      for (final (_, e) in sos) e,
      for (final (_, e) in events) e,
      for (final (_, e) in notices) e,
      ?announcement?.$2,
    ].take(maxRows).toList();
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
    final delay =
        wait.isNegative ? Duration.zero : wait + const Duration(seconds: 1);
    // At most a day: a web timer past ~24.8 days overflows and fires at
    // once. Waking early only rebuilds and waits again.
    _timer = Timer(
      delay > const Duration(days: 1) ? const Duration(days: 1) : delay,
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
    final media = MediaQuery.of(context);
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A stack of pins never takes more than a quarter of the room
          // above the keyboard (a phone on its side); past that it scrolls.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (media.size.height - media.viewInsets.bottom) * 0.25,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in entries) _row(context, entry, scheme),
                ],
              ),
            ),
          ),
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
              // Plain: a spoiler the card hides must not show here.
              child: Text(
                MarkdownHelper.toPlainText(
                  entry.message.summary,
                  formatting: context.select<AppSettingsService, bool>(
                    (s) => s.settings.showTextFormatting,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
            ),
            if (entry.at case final at?) ...[
              const SizedBox(width: 8),
              Text(
                DateTimeHelper.time(context, at),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
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
