import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

/// Bottom sheet for picking a reaction: a quick row of favorites over the
/// full system emoji picker (search, skin tones, recents). Reactions travel
/// as MeshCore One text with the literal emoji on the wire, so any emoji is
/// sendable — no fixed table.
class ReactionPickerSheet extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const ReactionPickerSheet({super.key, required this.onEmojiSelected});

  static const List<String> quickEmojis = ['👍', '❤️', '😂', '🎉', '👏', '🔥'];

  void _select(BuildContext context, String emoji) {
    onEmojiSelected(emoji);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.chat_addReaction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              children: quickEmojis
                  .map(
                    (emoji) => InkWell(
                      onTap: () => _select(context, emoji),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: epf.EmojiPicker(
              onEmojiSelected: (category, emoji) =>
                  _select(context, emoji.emoji),
              config: epf.Config(
                height: double.infinity,
                checkPlatformCompatibility: true,
                emojiViewConfig: epf.EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 28,
                  backgroundColor: scheme.surface,
                ),
                categoryViewConfig: epf.CategoryViewConfig(
                  backgroundColor: scheme.surface,
                  indicatorColor: scheme.primary,
                  iconColor: scheme.outline,
                  iconColorSelected: scheme.primary,
                ),
                bottomActionBarConfig: epf.BottomActionBarConfig(
                  showBackspaceButton: false,
                  backgroundColor: scheme.surface,
                  buttonColor: scheme.surface,
                  buttonIconColor: scheme.onSurfaceVariant,
                ),
                searchViewConfig: epf.SearchViewConfig(
                  backgroundColor: scheme.surface,
                  buttonIconColor: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
