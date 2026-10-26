/// The twelve reactions the picker offers first: the ones this user sent
/// last, newest first, topped up with defaults.
class QuickReactions {
  static const count = 12;

  static const defaults = [
    '👍', '❤️', '😂', '🎉', '👏', '🔥', //
    '😮', '😢', '🙏', '👀', '✅', '💯',
  ];

  /// [recent] after sending [emoji]: it moves to the front.
  static List<String> remember(List<String> recent, String emoji) =>
      [emoji, ...recent.where((e) => e != emoji)].take(count).toList();

  static List<String> of(List<String> recent) {
    final used = recent.take(count).toList();
    return [...used, ...defaults.where((d) => !used.contains(d))]
        .take(count)
        .toList();
  }
}
