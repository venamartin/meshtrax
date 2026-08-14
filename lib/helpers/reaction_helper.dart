import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Which client dialect a reaction arrived in.
/// [open] is our own `r:HASH:INDEX`; [one] is MeshCore One's
/// `{emoji}@[{targetSender}]\n{hash}` (channel) / `{emoji}\n{hash}` (DM),
/// spec: https://github.com/Avi0n/MeshCoreOne/blob/main/docs/Reactions.md
enum ReactionFormat { open, one }

class ReactionInfo {
  final String targetHash;
  final String emoji;
  final ReactionFormat format;

  /// Sender of the target message (MeshCore One channel reactions only) —
  /// disambiguates identical text+timestamp from different senders.
  final String? targetSender;

  ReactionInfo({
    required this.targetHash,
    required this.emoji,
    this.format = ReactionFormat.open,
    this.targetSender,
  });
}

class ReactionHelper {
  /// Apply a reaction to a list of messages by matching the reaction hash.
  ///
  /// [messages] - the message list to search
  /// [reactionInfo] - the parsed reaction
  /// [reactorName] - display name of whoever sent this reaction
  /// [getTimestampSecs] - extract timestamp seconds from a message
  /// [getSenderName] - extract sender name for hash (null for 1:1 implicit)
  /// [getMessageText] - extract message text
  /// [getReactions] - extract current reactions map
  /// [getReactionSenders] - extract current per-emoji reactor names
  /// [shouldSkip] - filter function to skip messages (e.g., skip outgoing for incoming reactions)
  /// [updateMessage] - callback to update the message at index with new reactions
  /// [getWireTimestampSecs] - candidate original wire timestamps for a message,
  /// used for MeshCore One hashes (which are computed over the sender's wire
  /// clock, untouched by the ingest clamp). Falls back to [getTimestampSecs].
  /// [getMessageTextVariants] - candidate texts for MeshCore One hashes: the
  /// sender hashes the message AS IT DISPLAYS it, which strips a leading
  /// mention — so a reaction to "@[Bob] hello" hashes only "hello". Callers
  /// pass the stored text plus its mention-stripped form. Falls back to
  /// [getMessageText].
  ///
  /// Returns whether a match was found.
  static bool applyReaction<T>({
    required List<T> messages,
    required ReactionInfo reactionInfo,
    required String reactorName,
    required int Function(T) getTimestampSecs,
    required String? Function(T) getSenderName,
    required String Function(T) getMessageText,
    required Map<String, int> Function(T) getReactions,
    required Map<String, List<String>> Function(T) getReactionSenders,
    required bool Function(T) shouldSkip,
    required void Function(
      int index,
      Map<String, int> newReactions,
      Map<String, List<String>> newSenders,
    )
    updateMessage,
    List<int> Function(T)? getWireTimestampSecs,
    List<String> Function(T)? getMessageTextVariants,
  }) {
    final foundIndex = findTargetIndex<T>(
      messages: messages,
      reactionInfo: reactionInfo,
      getTimestampSecs: getTimestampSecs,
      getSenderName: getSenderName,
      getMessageText: getMessageText,
      shouldSkip: shouldSkip,
      getWireTimestampSecs: getWireTimestampSecs,
      getMessageTextVariants: getMessageTextVariants,
    );
    if (foundIndex < 0) return false;

    final msg = messages[foundIndex];
    final merged = mergeReaction(
      getReactions(msg),
      getReactionSenders(msg),
      reactionInfo.emoji,
      reactorName,
    );
    if (merged == null) return true;
    updateMessage(foundIndex, merged.reactions, merged.senders);
    return true;
  }

  /// Locate the message a reaction targets, or -1. This is the single
  /// hash-matching authority — every path that must find a reaction's target
  /// (applying it, updating its send status, resolving a parked orphan) goes
  /// through here so the formats can never drift apart.
  static int findTargetIndex<T>({
    required List<T> messages,
    required ReactionInfo reactionInfo,
    required int Function(T) getTimestampSecs,
    required String? Function(T) getSenderName,
    required String Function(T) getMessageText,
    required bool Function(T) shouldSkip,
    List<int> Function(T)? getWireTimestampSecs,
    List<String> Function(T)? getMessageTextVariants,
  }) {
    final targetHash = reactionInfo.targetHash;

    bool matches(T msg) {
      if (reactionInfo.format == ReactionFormat.one) {
        final texts =
            getMessageTextVariants?.call(msg) ?? [getMessageText(msg)];
        final candidates =
            getWireTimestampSecs?.call(msg) ?? [getTimestampSecs(msg)];
        return texts.any(
          (text) => candidates.any(
            (secs) => computeMeshCoreOneHash(text, secs) == targetHash,
          ),
        );
      }
      return computeReactionHash(
            getTimestampSecs(msg),
            getSenderName(msg),
            getMessageText(msg),
          ) ==
          targetHash;
    }

    // A MeshCore One channel reaction names the target's sender; prefer rows
    // from that sender so identical text+timestamp from two people resolves
    // to the right one, but fall back to any match (names can drift between
    // clients).
    final targetSender = reactionInfo.targetSender;
    if (targetSender != null) {
      for (int i = messages.length - 1; i >= 0; i--) {
        if (shouldSkip(messages[i])) continue;
        if (getSenderName(messages[i]) != targetSender) continue;
        if (matches(messages[i])) return i;
      }
    }
    for (int i = messages.length - 1; i >= 0; i--) {
      if (shouldSkip(messages[i])) continue;
      if (matches(messages[i])) return i;
    }
    return -1;
  }

  /// Add [reactorName]'s [emoji] to a reaction map pair, or null when this
  /// person already reacted with this emoji — a repeat of the same packet
  /// must not inflate the count. Inputs are never mutated.
  static ({Map<String, int> reactions, Map<String, List<String>> senders})?
      mergeReaction(
    Map<String, int> reactions,
    Map<String, List<String>> reactionSenders,
    String emoji,
    String reactorName,
  ) {
    final newSenders = <String, List<String>>{
      for (final e in reactionSenders.entries)
        e.key: List<String>.from(e.value),
    };
    final senders = newSenders.putIfAbsent(emoji, () => []);
    if (senders.contains(reactorName)) return null;
    senders.add(reactorName);

    final newReactions = Map<String, int>.from(reactions);
    newReactions[emoji] = (newReactions[emoji] ?? 0) + 1;
    return (reactions: newReactions, senders: newSenders);
  }

  /// Reads the persisted per-emoji reactor names. Rows written before
  /// attribution existed simply have no entry.
  static Map<String, List<String>> decodeSenders(dynamic json) {
    if (json is! Map) return {};
    return {
      for (final entry in json.entries)
        entry.key as String: [
          for (final name in (entry.value as List<dynamic>? ?? const []))
            name as String,
        ],
    };
  }

  /// The legacy r: format's emoji table, FROZEN — it is the decode side of a
  /// wire index, so its order and contents can never change. Sends stopped
  /// using it when the app switched to the MeshCore One dialect; it exists
  /// only so reactions from older meshtrax builds keep decoding.
  static const List<String> reactionEmojis = [
    // quick
    '👍', '❤️', '😂', '🎉', '👏', '🔥',
    // smileys
    '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉',
    '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪',
    '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟',
    '😕', '🙁', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
    '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔',
    '🤭', '🤫', '🤥', '😶',
    // gestures
    '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤌',
    '🤏', '👈', '👉', '👆', '👇', '☝️', '👋', '🤚', '🖐️', '✋', '🖖', '👏',
    '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅', '🤳', '💪',
    // hearts
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❤️‍🔥',
    '❤️‍🩹', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '💌', '💢',
    '💥', '💫', '💦', '💨', '🕳️', '💬', '👁️‍🗨️', '🗨️', '🗯️', '💭',
    // objects
    '🎉', '🎊', '🎈', '🎁', '🎀', '🪅', '🪆', '🏆', '🥇', '🥈', '🥉', '⚽',
    '⚾', '🥎', '🏀', '🏐', '🏈', '🏉', '🎾', '🥏', '🎳', '🏏', '🏑', '🏒',
    '🥍', '🏓', '🏸', '🥊', '🥋', '🥅', '⛳', '🔥', '⭐', '🌟', '✨', '⚡',
    '💡', '🔦', '🏮', '🪔', '📱', '💻', '⌚', '📷', '📺', '📻', '🎵', '🎶',
    '🚀',
  ];

  /// Convert emoji to 2-char hex index. Returns null if emoji not in list.
  /// Legacy r: format only — no new call sites.
  static String? emojiToIndex(String emoji) {
    final idx = reactionEmojis.indexOf(emoji);
    if (idx < 0) return null;
    return idx.toRadixString(16).padLeft(2, '0');
  }

  /// Convert 2-char hex index to emoji. Returns null if invalid index.
  static String? indexToEmoji(String hexIndex) {
    final idx = int.tryParse(hexIndex, radix: 16);
    if (idx == null || idx < 0 || idx >= reactionEmojis.length) return null;
    return reactionEmojis[idx];
  }

  /// Compute a 4-char hex hash for a message reaction.
  /// Hash input: timestampSeconds + [senderName] + first 5 chars of text
  /// For 1:1 chats, senderName can be null (sender is implicit).
  static String computeReactionHash(
    int timestampSeconds,
    String? senderName,
    String text,
  ) {
    final first5 = text.length >= 5 ? text.substring(0, 5) : text;
    final input = senderName != null
        ? '$timestampSeconds$senderName$first5'
        : '$timestampSeconds$first5';
    // Use hashCode and take lower 16 bits, format as 4 hex chars
    final hash = input.hashCode & 0xFFFF;
    return hash.toRadixString(16).padLeft(4, '0');
  }

  /// Crockford Base32 alphabet (no I, L, O, U).
  static const String _crockford = '0123456789abcdefghjkmnpqrstvwxyz';

  /// MeshCore One message hash:
  /// SHA-256(UTF-8 text + little-endian u32 sender timestamp), first 5 bytes,
  /// as 8 chars of Crockford Base32.
  static String computeMeshCoreOneHash(String text, int timestampSeconds) {
    final input = BytesBuilder(copy: false)
      ..add(utf8.encode(text))
      ..add(
        Uint8List(4)
          ..buffer.asByteData().setUint32(
            0,
            timestampSeconds & 0xFFFFFFFF,
            Endian.little,
          ),
      );
    final digest = crypto.sha256.convert(input.toBytes()).bytes;
    int bits = 0;
    for (int i = 0; i < 5; i++) {
      bits = (bits << 8) | digest[i];
    }
    return [
      for (int shift = 35; shift >= 0; shift -= 5)
        _crockford[(bits >> shift) & 0x1f],
    ].join();
  }

  /// Lowercases and applies Crockford substitutions (O→0, I/L→1). Returns null
  /// unless the result is exactly 8 valid Crockford Base32 chars.
  static String? _normalizeCrockford(String raw) {
    if (raw.length != 8) return null;
    final out = StringBuffer();
    for (final rune in raw.toLowerCase().runes) {
      var ch = String.fromCharCode(rune);
      if (ch == 'o') ch = '0';
      if (ch == 'i' || ch == 'l') ch = '1';
      if (!_crockford.contains(ch)) return null;
      out.write(ch);
    }
    return out.toString();
  }

  /// Parse a MeshCore One reaction:
  /// channel `{emoji}@[{targetSender}]\n{hash}`, DM `{emoji}\n{hash}`.
  ///
  /// This shape can collide with a genuine two-line message, so callers must
  /// only consume the text as a reaction when the hash actually resolves to a
  /// message they hold — otherwise show it as a normal message.
  static ReactionInfo? parseMeshCoreOneReaction(String text) {
    final nl = text.lastIndexOf('\n');
    if (nl < 0) return null;
    final hash = _normalizeCrockford(text.substring(nl + 1));
    if (hash == null) return null;

    var emojiPart = text.substring(0, nl);
    String? targetSender;
    final at = emojiPart.indexOf('@[');
    if (at >= 0) {
      if (!emojiPart.endsWith(']')) return null;
      targetSender = emojiPart.substring(at + 2, emojiPart.length - 1);
      if (targetSender.isEmpty) return null;
      emojiPart = emojiPart.substring(0, at);
    }
    if (emojiPart.isEmpty || emojiPart.runes.length > 8) return null;
    // Emoji, not prose: nearly all emoji start at U+2000 or above; the
    // exceptions (keycaps, ©/®) carry a variation selector U+FE0F or a
    // combining keycap U+20E3. Ordinary ASCII text fails both tests.
    final looksLikeEmoji = emojiPart.runes.first >= 0x2000 ||
        emojiPart.runes.any((r) => r == 0xFE0F || r == 0x20E3);
    if (!looksLikeEmoji) return null;

    return ReactionInfo(
      targetHash: hash,
      emoji: emojiPart,
      format: ReactionFormat.one,
      targetSender: targetSender,
    );
  }

  /// All reaction dialects we can display: our own r: format, then
  /// MeshCore One. Use on the receive path; sends stay r:-format.
  static ReactionInfo? parseIncomingReaction(String text) {
    return parseReaction(text) ?? parseMeshCoreOneReaction(text);
  }

  /// Parse reaction format: r:HASH:INDEX (where INDEX is 2-char hex emoji index)
  /// Returns null if text is not a valid reaction format
  static ReactionInfo? parseReaction(String text) {
    final regex = RegExp(r'^r:([0-9a-f]{4}):([0-9a-f]{2})$');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final emoji = indexToEmoji(match.group(2)!);
    if (emoji == null) return null;

    return ReactionInfo(targetHash: match.group(1)!, emoji: emoji);
  }

  /// Encode a reaction message that parseReaction() can parse.
  /// Legacy r: format only — no new call sites; sends use
  /// [encodeMeshCoreOne].
  static String encodeReaction(String hash, String emojiIndex) {
    return 'r:$hash:$emojiIndex';
  }

  /// Encode a MeshCore One reaction — the send format. Channel reactions
  /// carry the target message's sender; DM reactions do not. The result is
  /// human-readable on clients that don't speak the dialect, and
  /// [parseMeshCoreOneReaction] round-trips it.
  static String encodeMeshCoreOne(
    String emoji,
    String hash, {
    String? targetSender,
  }) {
    return targetSender != null
        ? '$emoji@[$targetSender]\n$hash'
        : '$emoji\n$hash';
  }
}
