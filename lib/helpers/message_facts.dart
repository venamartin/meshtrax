import '../models/channel_message.dart';
import '../services/short_link_resolver.dart';
import '../utils/emoji_utils.dart';
import 'gif_helper.dart';
import 'reaction_helper.dart';
import 'structured_message.dart';

/// What a message's text says about how to draw it, worked out once per
/// text and only as far as a row asks. A row is built again every time it
/// scrolls into view or its list rebuilds, and the full chain is about
/// twenty regex passes (owner, 2026-10-26: glitches scrolling through
/// messages). A short link that resolves, or a new day, starts the cache
/// over: either can change a parse.
class MessageFacts {
  MessageFacts._(this.text, this.announcement);

  final String text;

  /// Read as a room server's own post: an announcement card even without
  /// a type keyword.
  final bool announcement;

  late final ReactionInfo? reaction =
      ReactionHelper.parseMeshCoreOneReaction(text);
  late final ReplyInfo? reply = ChannelMessage.parseReply(text);
  late final String? gifId = GifHelper.parseGif(text);
  late final StructuredMessage? structured = announcement
      ? StructuredMessage.parseAnnouncement(text,
          resolveShortLink: ShortLinkResolver.instance.cached)
      : StructuredMessage.parse(text,
          resolveShortLink: ShortLinkResolver.instance.cached);

  /// The card a quote of this text names. Quotes never asked the short
  /// link answers: a quoted link reads as the link.
  late final StructuredMessage? quoteCard = StructuredMessage.parse(text);
  late final String withoutGif = GifHelper.stripGif(text);
  late final bool emojiOnly =
      gifId == null && structured == null && isEmojiOnly(text);
  late final List<String> _shortLinks = ShortLinkResolver.shortLinksIn(text);

  /// The next moment this text's card reads differently by the clock: an
  /// event's day label turns at midnight until it ends, and a notice
  /// expires. Null when nothing on it changes again.
  DateTime? get changesAt {
    final now = DateTime.now();
    switch (structured) {
      case EventMessage(when: final span) when span.effectiveEnd.isAfter(now):
        final midnight = DateTime(now.year, now.month, now.day + 1);
        return span.effectiveEnd.isBefore(midnight)
            ? span.effectiveEnd
            : midnight;
      case NoticeMessage(:final expires?) when expires.isAfter(now):
        return expires;
      default:
        return null;
    }
  }

  /// Starts lookups for the short links in plain text (or in a room's plain
  /// announcement): one resolves later into a position. Meant for every
  /// build of the row. Returns when a lookup that failed may run again, for
  /// the row to be built again then: the resolver never retries by itself.
  DateTime? prefetchShortLinks() {
    final parsed = structured;
    if (parsed != null && !(parsed is NoticeMessage && parsed.announcement)) {
      return null;
    }
    final resolver = ShortLinkResolver.instance;
    DateTime? retry;
    for (final url in _shortLinks) {
      resolver.prefetch(url);
      final at = resolver.retryAt(url);
      if (at != null && (retry == null || at.isBefore(retry))) retry = at;
    }
    return retry;
  }

  static final _cache = <(String, bool), MessageFacts>{};
  static const _cap = 800;
  static var _day = 0;
  static var _listening = false;

  static MessageFacts of(String text, {bool announcement = false}) {
    if (!_listening) {
      _listening = true;
      ShortLinkResolver.instance.addListener(_cache.clear);
    }
    final now = DateTime.now();
    final day = now.year * 10000 + now.month * 100 + now.day;
    if (day != _day) {
      _day = day;
      _cache.clear();
    }
    final key = (text, announcement);
    final hit = _cache[key];
    if (hit != null) return hit;
    final facts = MessageFacts._(text, announcement);
    _cache[key] = facts;
    if (_cache.length > _cap) _cache.remove(_cache.keys.first);
    return facts;
  }
}
