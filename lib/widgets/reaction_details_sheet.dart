import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// How far reaction chips ride up over the bottom of their message bubble.
const double kReactionOverlap = 8;

/// Shows who reacted, grouped by emoji. [senders] may be empty or shorter
/// than the counts in [reactions]: reactions stored before attribution
/// existed kept only a count.
Future<void> showReactionDetails(
  BuildContext context, {
  required Map<String, int> reactions,
  required Map<String, List<String>> senders,
  String? initialEmoji,
}) {
  final l10n = AppLocalizations.of(context);
  final ordered = [
    if (initialEmoji != null && reactions.containsKey(initialEmoji))
      initialEmoji,
    ...reactions.keys.where((e) => e != initialEmoji),
  ];

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.chat_reactionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final emoji in ordered)
            ..._namesFor(emoji, reactions, senders, l10n).map(
              (name) => ListTile(
                dense: true,
                leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                title: Text(name),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Known reactor names, padded with placeholders when the stored count is
/// higher than the number of names we recorded.
List<String> _namesFor(
  String emoji,
  Map<String, int> reactions,
  Map<String, List<String>> senders,
  AppLocalizations l10n,
) {
  final known = senders[emoji] ?? const <String>[];
  final count = reactions[emoji] ?? known.length;
  return [
    ...known,
    for (var i = known.length; i < count; i++) l10n.chat_reactionUnknownSender,
  ];
}
