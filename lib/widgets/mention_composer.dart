import 'package:flutter/material.dart';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../utils/emoji_utils.dart';

/// Composer controller that renders `@[Name]` mention tokens in the accent
/// color while keeping the IME composing region visible.
class MentionTextEditingController extends TextEditingController {
  final RegExp _mentionRegex = RegExp(r'@\[([^\]]+)\]');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // The IME's composing region must stay visible (the framework default
    // underlines it) — dropping it desyncs Android keyboards from what the
    // user sees while a word is being composed.
    final TextRange? composing =
        withComposing && value.isComposingRangeValid ? value.composing : null;
    const underline = TextStyle(decoration: TextDecoration.underline);

    final List<TextSpan> spans = [];
    void addSegment(int from, int to, TextStyle? segmentStyle) {
      if (from >= to) return;
      if (composing == null || to <= composing.start || from >= composing.end) {
        spans.add(TextSpan(text: text.substring(from, to), style: segmentStyle));
        return;
      }
      final int cs = composing.start.clamp(from, to);
      final int ce = composing.end.clamp(from, to);
      if (from < cs) {
        spans.add(TextSpan(text: text.substring(from, cs), style: segmentStyle));
      }
      spans.add(TextSpan(
        text: text.substring(cs, ce),
        style: (segmentStyle ?? const TextStyle()).merge(underline),
      ));
      if (ce < to) {
        spans.add(TextSpan(text: text.substring(ce, to), style: segmentStyle));
      }
    }

    final mentionStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    int start = 0;
    for (final Match match in _mentionRegex.allMatches(text)) {
      addSegment(start, match.start, style);
      addSegment(match.start, match.end, mentionStyle);
      start = match.end;
    }
    addSegment(start, text.length, style);

    return TextSpan(children: spans, style: style);
  }
}

/// The avatar a mention row shows: the name's first emoji, else the type
/// icon, on a tinted circle.
Widget mentionAvatar(Contact contact, ColorScheme colorScheme) {
  final emoji = firstEmoji(contact.name);
  return CircleAvatar(
    radius: 16,
    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
    child: emoji != null
        ? Text(emoji, style: const TextStyle(fontSize: 16))
        : Icon(_typeIcon(contact.type), color: colorScheme.primary, size: 16),
  );
}

IconData _typeIcon(int type) {
  switch (type) {
    case advTypeChat:
      return Icons.chat_bubble;
    case advTypeRepeater:
      return Icons.cell_tower;
    case advTypeRoom:
      return Icons.group;
    case advTypeSensor:
      return Icons.sensors;
    default:
      return Icons.device_unknown;
  }
}

/// The rounded, shadowed, height-bounded list the mention picker sits in,
/// placed in the screen's own Column (it is not an Overlay). Any screen
/// that wants the same picker look builds its rows through [itemBuilder].
class MentionsPanel extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const MentionsPanel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        // Rows paint their ink on the nearest Material; without this one
        // they would paint under the decorated box.
        child: Material(
          type: MaterialType.transparency,
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: itemBuilder,
          ),
        ),
      ),
    );
  }
}

/// The @-autocomplete list shown above the composer while a mention is being
/// typed. The caller owns filtering and insertion.
class MentionsOverlay extends StatelessWidget {
  final List<Contact> contacts;
  final ValueChanged<Contact> onSelect;

  const MentionsOverlay({
    super.key,
    required this.contacts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MentionsPanel(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: mentionAvatar(contact, colorScheme),
          title: Text(
            contact.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onTap: () => onSelect(contact),
        );
      },
    );
  }
}
