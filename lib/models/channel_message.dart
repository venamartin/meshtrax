import 'dart:typed_data';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/smaz.dart';

import '../utils/app_logger.dart';

enum ChannelMessageStatus { pending, sent, failed, delivered }

class Repeat {
  final Uint8List? repeaterKey;
  final String repeaterName;
  final int tripTimeMs;
  final List<Uint8List>? path;

  Repeat({
    this.repeaterKey,
    required this.repeaterName,
    required this.tripTimeMs,
    this.path,
  });

  String? get repeaterKeyHex =>
      repeaterKey != null ? pubKeyToHex(repeaterKey!) : null;
}

class ChannelMessage {
  final Uint8List? senderKey;
  final String senderName;
  final String text;

  final DateTime timestamp;
  final bool isOutgoing;
  final ChannelMessageStatus status;
  final List<Repeat> repeats;
  final int repeatCount;
  final int sendRetryCount;
  // Every wire timestamp this message was HEARD or SENT with: our own
  // send + retries (retries MUST re-stamp or mesh dedup drops them), and
  // for incoming rows every re-stamped repeat that merged in. MeshCore One
  // reaction hashes are computed over the wire clock of whichever COPY the
  // reactor heard, so the matcher must be able to try all of them. Empty
  // for rows stored before this field existed.
  final List<int> sentWireSecs;
  final int? pathLength;
  final Uint8List pathBytes;
  final int pathHashSize;
  final List<Uint8List> pathVariants;
  // Latched true when ANY copy of this message arrived with zero hops —
  // we heard the sender's own transmitter. Survives repeat merges, which
  // deliberately adopt the longest observed path for display: pathLength
  // says how the KEPT copy looks, this says "they were in range".
  final bool heardDirect;
  final int? channelIndex;
  final String messageId;
  final String? packetHash;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToText;
  // The ORIGINAL on-air text for rows whose display [text] was rewritten
  // (replies: '@[Name]\n>snippet\nbody' stored as just the body). MeshCore
  // One hashes reactions over THIS form — captured on-air 2026-08-12, hash
  // 8p4kahn8 over the raw reply markup — so both reacting to such a row and
  // matching reactions against it need the wire bytes, not the display text.
  // Null when the display text IS the wire text.
  final String? wireText;
  final Map<String, int> reactions;
  // Who reacted, per emoji. Rows written before attribution existed have
  // counts with no names, so this can be shorter than the count.
  final Map<String, List<String>> reactionSenders;

  /// An SOS whose sender repeats it: when the newest repeat merged in, with
  /// [text] its latest wire text. Null for any other message.
  final DateTime? sosUpdatedAt;

  /// When the sender cancelled this SOS ("SOS cancelled"), or null.
  final DateTime? sosCancelledAt;

  ChannelMessage({
    this.senderKey,
    required this.senderName,
    required this.text,

    required this.timestamp,
    required this.isOutgoing,
    this.status = ChannelMessageStatus.pending,
    this.repeats = const [],
    this.repeatCount = 0,
    this.sendRetryCount = 0,
    List<int>? sentWireSecs,
    this.pathLength,
    Uint8List? pathBytes,
    this.pathHashSize = 1,
    List<Uint8List>? pathVariants,
    this.heardDirect = false,
    this.channelIndex,
    String? messageId,
    this.packetHash,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    this.wireText,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
    this.sosUpdatedAt,
    this.sosCancelledAt,
  }) : messageId =
           messageId ??
           '${timestamp.millisecondsSinceEpoch}_${senderName.hashCode}_${text.hashCode}',
       sentWireSecs = sentWireSecs ?? const [],
       reactions = reactions ?? {},
       reactionSenders = reactionSenders ?? {},
       pathBytes = pathBytes ?? Uint8List(0),
       pathVariants = _mergePathVariants(
         pathBytes ?? Uint8List(0),
         pathVariants,
       );

  String? get senderKeyHex =>
      senderKey != null ? pubKeyToHex(senderKey!) : null;

  String get displayPathString => PathHelper.formatPathHex(pathBytes, stride: pathHashSize);

  List<String> get displayPathVariants => pathVariants.map((p) => PathHelper.formatPathHex(p, stride: pathHashSize)).toList();

  ChannelMessage copyWith({
    String? text,
    ChannelMessageStatus? status,
    DateTime? timestamp,
    List<Repeat>? repeats,
    int? repeatCount,
    int? sendRetryCount,
    List<int>? sentWireSecs,
    int? pathLength,
    Uint8List? pathBytes,
    int? pathHashSize,
    List<Uint8List>? pathVariants,
    bool? heardDirect,
    String? packetHash,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,
    String? wireText,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
    DateTime? sosUpdatedAt,
    DateTime? sosCancelledAt,
  }) {
    return ChannelMessage(
      senderKey: senderKey,
      senderName: senderName,
      text: text ?? this.text,

      timestamp: timestamp ?? this.timestamp,
      isOutgoing: isOutgoing,
      status: status ?? this.status,
      repeats: repeats ?? this.repeats,
      repeatCount: repeatCount ?? this.repeatCount,
      sendRetryCount: sendRetryCount ?? this.sendRetryCount,
      sentWireSecs: sentWireSecs ?? this.sentWireSecs,
      pathLength: pathLength ?? this.pathLength,
      pathBytes: pathBytes ?? this.pathBytes,
      pathHashSize: pathHashSize ?? this.pathHashSize,
      pathVariants: pathVariants ?? this.pathVariants,
      heardDirect: heardDirect ?? this.heardDirect,
      channelIndex: channelIndex,
      messageId: messageId,
      packetHash: packetHash ?? this.packetHash,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      wireText: wireText ?? this.wireText,
      reactions: reactions ?? this.reactions,
      reactionSenders: reactionSenders ?? this.reactionSenders,
      sosUpdatedAt: sosUpdatedAt ?? this.sosUpdatedAt,
      sosCancelledAt: sosCancelledAt ?? this.sosCancelledAt,
    );
  }

  static ChannelMessage? fromFrame(Uint8List frame) {
    // V3: [0]=code [1]=SNR [2]=rsv1 [3]=rsv2 [4]=channel_idx [5]=path_len [txt_type] [timestamp x4] [text...]
    // Non-V3: [0]=code [1]=channel_idx [2]=path_len [3]=txt_type [4-7]=timestamp [8+]=text
    if (frame.length < 8) return null;
    try {
      final reader = BufferReader(frame);
      final code = reader.readByte();
      if (code != respCodeChannelMsgRecv && code != respCodeChannelMsgRecvV3) {
        return null;
      }

      int pathLen;
      int txtType;
      Uint8List pathBytes = Uint8List(0);
      int channelIdx;
      if (code == respCodeChannelMsgRecvV3) {
        reader.skipBytes(3); // Skip SNR and two reserved bytes
        channelIdx = reader.readByte();
        pathLen = reader.readInt8();
        txtType = reader.readByte();
      } else {
        channelIdx = reader.readByte();
        pathLen = reader.readInt8();
        txtType = reader.readByte();
      }
      final timestampRaw = reader.readUInt32LE();

      if (txtType != txtTypePlain) {
        return null;
      }

      final text = reader.readCString();

      // Extract sender name and actual message from "name: msg" format
      String senderName = 'Unknown';
      String actualText = text;

      final colonIndex = text.indexOf(':');
      if (colonIndex > 0 && colonIndex < text.length - 1 && colonIndex < 50) {
        final potentialSender = text.substring(0, colonIndex);
        if (!RegExp(r'[:\[\]]').hasMatch(potentialSender)) {
          senderName = potentialSender;
          final offset =
              (colonIndex + 1 < text.length && text[colonIndex + 1] == ' ')
              ? colonIndex + 2
              : colonIndex + 1;
          actualText = text.substring(offset);
        }
      }

      final decodedText = Smaz.tryDecodePrefixed(actualText) ?? actualText;

      final explicitHopCount = PathHelper.pathLenHops(pathLen);
      final hashSize = PathHelper.pathLenWidth(pathLen);
      // Queue-delivered frames carry a path_len byte but NO path bytes —
      // keep the count instead of recomputing 0 from the empty path, which
      // made every offline-queued message claim it arrived "Direct"
      // (parity with _parseContactMessage). The wire byte is
      // (hashSize-1)<<6 | hopCount (firmware Packet.h), so the extract
      // helpers yield final values; nothing downstream may rescale them.
      final actualHopCount = explicitHopCount < 0
          ? -1
          : (pathBytes.isEmpty
              ? explicitHopCount
              : PathHelper.getHopCount(pathBytes, stride: hashSize));

      return ChannelMessage(
        senderKey: null,
        senderName: senderName,
        text: decodedText,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        pathLength: actualHopCount,
        pathBytes: pathBytes,
        pathHashSize: hashSize,
        heardDirect: actualHopCount == 0,
        channelIndex: channelIdx,
      );
    } catch (e) {
      appLogger.error('Error parsing channel message frame: $e');
      // If parsing fails, return null to avoid crashes
      return null;
    }
  }

  static ChannelMessage outgoing(
    String text,
    String senderName,
    int channelIndex, {
    int pathHashSize = 1,
  }) {
    return ChannelMessage(
      senderKey: null,
      senderName: senderName,
      text: text,

      timestamp: DateTime.now(),
      isOutgoing: true,
      status: ChannelMessageStatus.pending,
      sendRetryCount: 0,
      pathLength: null,
      pathBytes: Uint8List(0),
      pathHashSize: pathHashSize,
      pathVariants: const [],
      channelIndex: channelIndex,
    );
  }

  static List<Uint8List> _mergePathVariants(
    Uint8List pathBytes,
    List<Uint8List>? pathVariants,
  ) {
    final merged = <Uint8List>[];

    void addPath(Uint8List bytes) {
      if (bytes.isEmpty) return;
      for (final existing in merged) {
        if (_pathsEqual(existing, bytes)) return;
      }
      merged.add(bytes);
    }

    if (pathVariants != null) {
      for (final variant in pathVariants) {
        addPath(variant);
      }
    }
    addPath(pathBytes);
    return merged;
  }

  static bool _pathsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// What a reply quotes of [targetText]: its first [chars] characters, on
  /// one line, starting after any leading mentions, as MeshCore One quotes.
  /// A quote that is part of a mention says nothing about which message is
  /// meant, and matches none (field 2026-11-15: a reply to "@[long name]
  /// words" showed "Original message not found"). Counted in code points:
  /// half of one goes out as a broken character, and ten are at most 40
  /// bytes of the message, where ten whole emoji could be all of it.
  static String buildReplySnippet(String targetText, int chars) =>
      String.fromCharCodes(_quotable(targetText).take(chars));

  /// [text] on one line, without its leading mentions unless it has nothing
  /// else.
  static Runes _quotable(String text) {
    String flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = flat(stripLeadingMentions(text));
    return (words.isEmpty ? flat(text) : words).runes;
  }

  /// Whether a stored message [text] is the one a reply [snippet] quotes.
  /// Leading mentions are stripped from BOTH sides: the replying app builds
  /// its snippet from the parent as it displays it (mention stripped), while
  /// stored text keeps the mention. Whitespace-collapsed, case-insensitive
  /// prefix test; an empty snippet matches anything.
  ///
  /// When the parent is itself a reply, pass the text it went out as in
  /// [wireText]: an app that doesn't read replies quotes it, quote line and
  /// all, so ">Pine cone" can quote "@[Bob]\n>Pine cones..\nI got mine",
  /// shown as "I got mine" (field 2026-11-16: such replies never linked).
  static bool snippetMatches(String text, String snippet, {String? wireText}) {
    String norm(String s) => stripLeadingMentions(s)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final needle = norm(snippet);
    return needle.isEmpty ||
        norm(text).startsWith(needle) ||
        (wireText != null && norm(wireText).startsWith(needle));
  }

  /// Whether [text] mentions [name] via the `@[Name]` wire syntax anywhere —
  /// plain mentions and reply headers alike (a reply to me always carries my
  /// mention). Case-insensitive: other apps let senders type names by hand.
  static bool mentionsUser(String text, String? name) {
    if (name == null || name.isEmpty) return false;
    return text.toLowerCase().contains('@[${name.toLowerCase()}]');
  }

  /// Removes ALL leading `@[name]` mentions (each with an optional trailing
  /// space or newline) from [text].
  ///
  /// Other clients treat a leading mention as addressing, not content: they
  /// build reply snippets and reaction hashes over the STRIPPED body. Any
  /// code matching a snippet or hash against stored text must compare like
  /// with like, or replies and reactions to mention-led messages never
  /// resolve (field report: quote showed "My line of.." though the message
  /// existed; a 😂 displayed as a raw two-line message).
  static String stripLeadingMentions(String text) {
    final re = RegExp(r'^@\[[^\]]+\][ \n]?');
    var out = text;
    while (true) {
      final m = re.firstMatch(out);
      if (m == null || m.end == 0) return out;
      out = out.substring(m.end);
    }
  }

  /// Strips leading `@[name] ` addressing (SPACE form) but keeps `@[name]\n`
  /// reply markup. Receive-side tolerance only, for clients that hash the
  /// addressed body: MeshCore One never strips mentions (see [mc1HashText]),
  /// so no send may commit to this form.
  static String mc1DisplayText(String text) {
    final re = RegExp(r'^@\[[^\]]+\] ');
    var out = text;
    while (true) {
      final m = re.firstMatch(out);
      if (m == null || m.end == 0) return out;
      out = out.substring(m.end);
    }
  }

  /// The channel text MeshCore One stores and hashes reactions over: the
  /// body after "Name:", trimmed of Swift `.whitespaces` (tab and Unicode
  /// Zs — never newlines), mentions kept (MC1 ChannelMessageFormat.parse).
  /// We store the body untrimmed, so a trailing space orphaned every MC1
  /// reaction to it (field log 2026-10-21: hash nksybmwk). The ONE text form
  /// a channel reaction send commits to.
  static String mc1HashText(String text) =>
      text.replaceAll(_mc1EdgeWhitespace, '');

  static final RegExp _mc1EdgeWhitespace = RegExp(
    r'^[\t\p{Zs}]+|[\t\p{Zs}]+$',
    unicode: true,
  );

  /// Builds the on-wire reply text `@[targetName]\n><snippet>[..]\n<body>`
  /// (MeshCore One dialect: ".." only when the parent was truncated),
  /// shrinking the quoted snippet (see [buildReplySnippet]) until [fits].
  /// Falls back to `@[targetName]\n<body>`; returns null if even that
  /// doesn't fit.
  static String? buildReplyWireText({
    required String targetName,
    required String quoteText,
    required String body,
    required bool Function(String candidate) fits,
  }) {
    final quoteLength = _quotable(quoteText).length;
    for (int len = 10; len >= 6; len--) {
      final snippet = buildReplySnippet(quoteText, len);
      final suffix = quoteLength > len ? '..' : '';
      final candidate = '@[$targetName]\n>$snippet$suffix\n$body';
      if (fits(candidate)) return candidate;
    }
    final mention = '@[$targetName]\n$body';
    return fits(mention) ? mention : null;
  }

  /// Parses a reply in either dialect. Returns null for a plain mention or an
  /// ordinary message, so `@[Name] hello` is treated as a mention, not a reply.
  ///
  /// Ours: `@[Name] re:<snippet>…<response>` — marker may be "…" or "...",
  /// and the response may follow on a new line.
  ///
  /// MeshCore One: `@[Name]\n><snippet>[..]\n<response>` — snippet is the
  /// parent's first 10 chars after a leading mention, ".." only when
  /// truncated (MentionUtilities.buildReplyText in Avi0n/MeshCoreOne).
  static ReplyInfo? parseReply(String text) {
    final regex = RegExp(
      r'^@\[([^\]]+)\]\s+re:(.*?)(?:…|\.\.\.)\s*([\s\S]+)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return ReplyInfo(
        mentionedNode: match.group(1)!,
        snippet: match.group(2)!.trim(),
        actualMessage: match.group(3)!.trim(),
      );
    }

    final one = RegExp(
      r'^@\[([^\]]+)\]\n>([^\n]*)\n([\s\S]+)$',
    ).firstMatch(text);
    if (one == null) return null;
    var snippet = one.group(2)!;
    if (snippet.endsWith('..')) {
      snippet = snippet.substring(0, snippet.length - 2);
    }
    return ReplyInfo(
      mentionedNode: one.group(1)!,
      snippet: snippet.trim(),
      actualMessage: one.group(3)!.trim(),
    );
  }

  static ReactionInfo? parseReaction(String text) {
    return ReactionHelper.parseIncomingReaction(text);
  }
}

class ReplyInfo {
  final String mentionedNode;
  final String snippet;
  final String actualMessage;

  ReplyInfo({
    required this.mentionedNode,
    required this.snippet,
    required this.actualMessage,
  });
}
