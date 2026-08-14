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
    this.channelIndex,
    String? messageId,
    this.packetHash,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    this.wireText,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
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
    String? packetHash,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,
    String? wireText,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
  }) {
    return ChannelMessage(
      senderKey: senderKey,
      senderName: senderName,
      text: text,

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
      channelIndex: channelIndex,
      messageId: messageId,
      packetHash: packetHash ?? this.packetHash,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      wireText: wireText ?? this.wireText,
      reactions: reactions ?? this.reactions,
      reactionSenders: reactionSenders ?? this.reactionSenders,
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

      final explicitHopCount = extractPathHopCount(pathLen);
      final hashSize = extractPathHashSize(pathLen);
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

  /// A single-line, trimmed prefix of [targetText], at most [chars] characters.
  /// Used to quote the message being replied to in a cross-app-compatible way.
  static String buildReplySnippet(String targetText, int chars) {
    final flat = targetText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= chars ? flat : flat.substring(0, chars);
  }

  /// Whether [text] mentions [name] via the `@[Name]` wire syntax anywhere —
  /// plain mentions and reply headers alike (a reply to me always carries my
  /// mention). Case-insensitive: other apps let senders type names by hand.
  static bool mentionsUser(String text, String? name) {
    if (name == null || name.isEmpty) return false;
    return text.toLowerCase().contains('@[${name.toLowerCase()}]');
  }

  /// Removes ALL leading `@[name]` mentions (each with an optional trailing
  /// space or newline) from [text] — the generic form of
  /// [stripLeadingMention] for when the mentioned name is unknown.
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

  /// MeshCore One's actual display rule, measured on the air (2026-08-12
  /// #mtdebug capture): a leading `@[name] ` followed by a SPACE is
  /// addressing and gets stripped before hashing; `@[name]\n` followed by a
  /// newline is reply markup and stays. Use this — never
  /// [stripLeadingMentions] — when producing the ONE text form a reaction
  /// send commits to.
  static String mc1DisplayText(String text) {
    final re = RegExp(r'^@\[[^\]]+\] ');
    var out = text;
    while (true) {
      final m = re.firstMatch(out);
      if (m == null || m.end == 0) return out;
      out = out.substring(m.end);
    }
  }

  /// Removes a single leading `@[name]` mention (with an optional trailing
  /// space or newline) from [text]. Used to avoid echoing our own handle back
  /// inside a reply's quoted snippet.
  static String stripLeadingMention(String text, String name) {
    final bare = '@[$name]';
    if (name.isEmpty || !text.startsWith(bare)) return text;
    final rest = text.substring(bare.length);
    return (rest.startsWith(' ') || rest.startsWith('\n'))
        ? rest.substring(1)
        : rest;
  }

  /// Builds the on-wire reply text `@[targetName]\n><snippet>[..]\n<body>`
  /// (MeshCore One dialect: ".." only when the parent was truncated),
  /// shrinking the quoted snippet until [fits]. A leading self-mention is
  /// stripped from [quoteText] so we don't re-quote our own handle. Falls back
  /// to `@[targetName]\n<body>`; returns null if even that doesn't fit.
  static String? buildReplyWireText({
    required String targetName,
    required String quoteText,
    required String body,
    required String selfName,
    required bool Function(String candidate) fits,
  }) {
    final quote = stripLeadingMention(quoteText, selfName);
    final flatLength = quote.replaceAll(RegExp(r'\s+'), ' ').trim().length;
    for (int len = 10; len >= 6; len--) {
      final snippet = buildReplySnippet(quote, len);
      final suffix = flatLength > len ? '..' : '';
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
  /// parent's first 10 chars, ".." only when truncated
  /// (MentionUtilities.buildReplyText in Avi0n/MeshCoreOne).
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
