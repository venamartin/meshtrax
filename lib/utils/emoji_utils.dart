import 'package:characters/characters.dart';

/// Most emoji a message can hold and still be drawn large.
const int jumboEmojiMax = 5;

// The analyzer's regex validator does not understand the \p{Emoji} binary
// property, but Dart's engine does with unicode: true. An actually invalid
// pattern would throw on construction; emoji_only_regex_test.dart proves
// this one does not.
// ignore: valid_regexps
final _emojiOnly = RegExp(r'^[\p{Emoji}\u200D\uFE0F\uFE0E\u20E3\s]+$', unicode: true);
final _hasLetter = RegExp(r'[\p{L}a-zA-Z0-9]', unicode: true);

/// Whether [text] is nothing but emoji, at most [jumboEmojiMax] of them, so
/// the bubble draws them large.
bool isEmojiOnly(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
  if (noSpaces.characters.length > jumboEmojiMax) return false;
  return _emojiOnly.hasMatch(trimmed) && !_hasLetter.hasMatch(trimmed);
}

String? firstEmoji(String name) {
  if (name.isEmpty) return null;
  for (final cluster in name.characters) {
    if (_containsEmoji(cluster)) {
      return cluster;
    }
  }
  return null;
}

bool _containsEmoji(String cluster) {
  for (final rune in cluster.runes) {
    if (_isEmojiRune(rune)) return true;
  }
  return false;
}

bool _isEmojiRune(int rune) {
  if (rune == 0x00A9 || rune == 0x00AE) return true;
  if (rune == 0x203C || rune == 0x2049) return true;
  if (rune == 0x2122 || rune == 0x2139) return true;
  if (rune >= 0x2194 && rune <= 0x21AA) return true;
  if (rune >= 0x2300 && rune <= 0x23FF) return true;
  if (rune >= 0x2460 && rune <= 0x24FF) return true;
  if (rune >= 0x25A0 && rune <= 0x27BF) return true;
  if (rune >= 0x2900 && rune <= 0x297F) return true;
  if (rune >= 0x2B00 && rune <= 0x2BFF) return true;
  if (rune >= 0x1F000 && rune <= 0x1FAFF) return true;
  if (rune >= 0x1FC00 && rune <= 0x1FFFD) return true;
  return false;
}
