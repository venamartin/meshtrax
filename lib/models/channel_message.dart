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
  final Map<String, int> reactions;

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
    Map<String, int>? reactions,
  }) : messageId =
           messageId ??
           '${timestamp.millisecondsSinceEpoch}_${senderName.hashCode}_${text.hashCode}',
       reactions = reactions ?? {},
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
    int? pathLength,
    Uint8List? pathBytes,
    int? pathHashSize,
    List<Uint8List>? pathVariants,
    String? packetHash,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,

    Map<String, int>? reactions,
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
      reactions: reactions ?? this.reactions,
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
      final actualHopCount = explicitHopCount < 0 
          ? -1 
          : PathHelper.getHopCount(pathBytes, stride: hashSize);

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

  /// Marker appended after the quoted snippet in a reply.
  static const String replyMarker = '…';

  /// A single-line, trimmed prefix of [targetText], at most [chars] characters.
  /// Used to quote the message being replied to in a cross-app-compatible way.
  static String buildReplySnippet(String targetText, int chars) {
    final flat = targetText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= chars ? flat : flat.substring(0, chars);
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

  /// Builds the on-wire reply text `@[targetName]\nre:<snippet>…\n<body>`,
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
    for (int len = 15; len >= 6; len--) {
      final snippet = buildReplySnippet(quote, len);
      final candidate = '@[$targetName]\nre:$snippet$replyMarker\n$body';
      if (fits(candidate)) return candidate;
    }
    final mention = '@[$targetName]\n$body';
    return fits(mention) ? mention : null;
  }

  /// Parses a reply of the form `@[Name] re:<snippet>…<response>`.
  /// The snippet marker may be "…" or "...", and the response may follow on a
  /// new line. Returns null for a plain mention or an ordinary message, so
  /// `@[Name] hello` is treated as a mention, not a reply.
  static ReplyInfo? parseReply(String text) {
    final regex = RegExp(
      r'^@\[([^\]]+)\]\s+re:(.*?)(?:…|\.\.\.)\s*([\s\S]+)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    return ReplyInfo(
      mentionedNode: match.group(1)!,
      snippet: match.group(2)!.trim(),
      actualMessage: match.group(3)!.trim(),
    );
  }

  static ReactionInfo? parseReaction(String text) {
    return ReactionHelper.parseReaction(text);
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
