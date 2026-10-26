import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as epf;
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart'
    as epf_locale;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/quick_reactions.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';

/// Bottom sheet for picking a reaction: a search box, the twelve reactions
/// used last, and the full system emoji picker (categories, skin tones).
/// Reactions travel as MeshCore One text with the literal emoji on the wire,
/// so any emoji is sendable — no fixed table.
class ReactionPickerSheet extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const ReactionPickerSheet({super.key, required this.onEmojiSelected});

  @override
  State<ReactionPickerSheet> createState() => _ReactionPickerSheetState();
}

class _ReactionPickerSheetState extends State<ReactionPickerSheet> {
  final _search = TextEditingController();
  String _query = '';
  List<epf.Emoji> _results = const [];

  /// The app language's keywords plus English, so either finds an emoji.
  /// The package caches the first set it searches, so one set serves the
  /// whole session.
  static List<epf.CategoryEmoji>? _searchSet;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static List<epf.CategoryEmoji> _keywords(Locale locale) {
    final cached = _searchSet;
    if (cached != null) return cached;
    final local = epf_locale.getDefaultEmojiLocale(locale);
    if (identical(local, epf.emojiSetEnglish)) {
      return _searchSet = epf.emojiSetEnglish;
    }
    final english = {
      for (final c in epf.emojiSetEnglish)
        for (final e in c.emoji) e.emoji: e.name,
    };
    return _searchSet = [
      for (final c in local)
        epf.CategoryEmoji(c.category, [
          for (final e in c.emoji)
            epf.Emoji(
              e.emoji,
              english[e.emoji] == null
                  ? e.name
                  : '${e.name} | ${english[e.emoji]}',
              hasSkinTone: e.hasSkinTone,
            ),
        ]),
    ];
  }

  void _select(String emoji) {
    context.read<AppSettingsService>().rememberReaction(emoji);
    widget.onEmojiSelected(emoji);
    Navigator.pop(context);
  }

  Future<void> _onSearch(String text) async {
    final query = text.trim();
    setState(() => _query = query);
    if (query.isEmpty) return;
    final found = await epf.EmojiPickerUtils()
        .searchEmoji(query, _keywords(Localizations.localeOf(context)));
    if (!mounted || query != _query) return;
    setState(() => _results = found);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // Above the keyboard while searching, never under the status bar.
    final height = math.min(
      media.size.height * 0.6,
      media.size.height - keyboard - media.padding.top,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // The picker's last row stays clear of the phone's navigation bar.
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.chat_addReaction,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.l10n.reaction_searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              _onSearch('');
                            },
                          ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_query.isEmpty) ...[
                _quickGrid(context, scheme),
                const Divider(height: 1),
                Expanded(child: _picker(scheme)),
              ] else
                Expanded(child: _searchResults(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// Two rows of six, as wide as the sheet.
  Widget _quickGrid(BuildContext context, ColorScheme scheme) {
    final recent = context.select<AppSettingsService, List<String>>(
      (s) => s.settings.recentReactions,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final emoji in QuickReactions.of(recent))
            Material(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _select(emoji),
                child: Center(
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    if (_results.isEmpty) {
      return Center(child: Text(context.l10n.reaction_noResults));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 52,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final emoji = _results[i].emoji;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _select(emoji),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }

  Widget _picker(ColorScheme scheme) {
    return epf.EmojiPicker(
      onEmojiSelected: (category, emoji) => _select(emoji.emoji),
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
        // Search lives in the box at the top; the bar would only add a
        // second, smaller one.
        bottomActionBarConfig: const epf.BottomActionBarConfig(enabled: false),
      ),
    );
  }
}
