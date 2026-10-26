import 'dart:typed_data';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import 'path_selection.dart';


enum MessageStatus { pending, sent, delivered, failed }

class Message {
  final Uint8List senderKey;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final bool isCli;
  final MessageStatus status;


  // NEW: Retry logic fields
  final String messageId;
  final int retryCount;
  final int? estimatedTimeoutMs;
  final int? expectedAckHash;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final int? tripTimeMs;
  final int? pathLength;
  final Uint8List pathBytes;
  // Hash width of pathBytes. Null for messages stored before it was recorded;
  // their bytes can only be shown at the contact's current width.
  final int? pathHashSize;
  // Incoming: pathBytes are the repeaters this very packet passed, read from
  // the radio's raw log. Rows stored before carry a copy of our route to the
  // sender instead, which is not shown as theirs.
  final bool pathFromPacket;
  // Who chose the route of the attempt pathLength describes. Rows stored
  // before Pathfinder read as firmware.
  final RouteSource routeSource;
  // Of a Pathfinder route's hops, how many were splice guesses (the
  // reverse of links heard on the contact's inbound path) rather than
  // links observed in the sending direction.
  final int guessedHops;
  // The ACK arrived after every attempt had timed out and the message had
  // already been marked failed.
  final bool deliveredLate;
  // A flood of it was heard by no repeater; it waits for one to be in range
  // before it is sent again. Lives only in memory: a restart starts over.
  final bool waitingForRepeater;
  final Map<String, int> reactions;
  // Who reacted, per emoji. Rows written before attribution existed have
  // counts with no names, so this can be shorter than the count.
  final Map<String, List<String>> reactionSenders;
  final Map<String, MessageStatus> reactionStatuses;
  final Uint8List fourByteRoomContactKey;

  Message({
    required this.senderKey,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    this.isCli = false,
    this.status = MessageStatus.pending,
    String? messageId,

    this.retryCount = 0,
    this.estimatedTimeoutMs,
    this.expectedAckHash,
    this.sentAt,
    this.deliveredAt,
    this.tripTimeMs,
    Uint8List? pathBytes,
    Uint8List? fourByteRoomContactKey,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
    Map<String, MessageStatus>? reactionStatuses,
    this.pathLength,
    this.pathHashSize,
    this.pathFromPacket = false,
    this.routeSource = RouteSource.firmware,
    this.guessedHops = 0,
    this.deliveredLate = false,
    this.waitingForRepeater = false,
  }) : messageId = messageId ??
           '${timestamp.millisecondsSinceEpoch}_${pubKeyToHex(senderKey)}_${text.hashCode}',
       pathBytes = pathBytes ?? Uint8List(0),
       fourByteRoomContactKey = fourByteRoomContactKey ?? Uint8List(0),
       reactions = reactions ?? {},
       reactionSenders = reactionSenders ?? {},
       reactionStatuses = reactionStatuses ?? {};

  String get senderKeyHex => pubKeyToHex(senderKey);

  Message copyWith({
    MessageStatus? status,
    DateTime? timestamp,
    int? retryCount,
    int? estimatedTimeoutMs,
    int? expectedAckHash,
    DateTime? sentAt,
    DateTime? deliveredAt,
    int? tripTimeMs,
    int? pathLength,
    Uint8List? pathBytes,
    int? pathHashSize,
    bool? pathFromPacket,
    RouteSource? routeSource,
    int? guessedHops,
    bool? isCli,
    bool? deliveredLate,
    bool? waitingForRepeater,

    Map<String, int>? reactions,
    Map<String, List<String>>? reactionSenders,
    Map<String, MessageStatus>? reactionStatuses,
    Uint8List? fourByteRoomContactKey,
  }) {
    return Message(
      senderKey: senderKey,
      text: text,
      timestamp: timestamp ?? this.timestamp,
      isOutgoing: isOutgoing,
      isCli: isCli ?? this.isCli,
      status: status ?? this.status,
      messageId: messageId,

      retryCount: retryCount ?? this.retryCount,
      estimatedTimeoutMs: estimatedTimeoutMs ?? this.estimatedTimeoutMs,
      expectedAckHash: expectedAckHash ?? this.expectedAckHash,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      tripTimeMs: tripTimeMs ?? this.tripTimeMs,
      pathLength: pathLength ?? this.pathLength,
      pathBytes: pathBytes ?? this.pathBytes,
      pathHashSize: pathHashSize ?? this.pathHashSize,
      pathFromPacket: pathFromPacket ?? this.pathFromPacket,
      routeSource: routeSource ?? this.routeSource,
      guessedHops: guessedHops ?? this.guessedHops,
      deliveredLate: deliveredLate ?? this.deliveredLate,
      waitingForRepeater: waitingForRepeater ?? this.waitingForRepeater,
      reactions: reactions ?? this.reactions,
      reactionSenders: reactionSenders ?? this.reactionSenders,
      reactionStatuses: reactionStatuses ?? this.reactionStatuses,
      fourByteRoomContactKey:
          fourByteRoomContactKey ?? this.fourByteRoomContactKey,
    );
  }


  static Message outgoing(
    Uint8List recipientKey,
    String text, {

    int? pathLength,
    Uint8List? pathBytes,
    int? pathHashSize,
  }) {
    return Message(
      senderKey: recipientKey,
      text: text,

      timestamp: DateTime.now(),
      isOutgoing: true,
      isCli: false,
      status: MessageStatus.pending,
      pathLength: pathLength,
      pathBytes: pathBytes,
      pathHashSize: pathHashSize,
    );
  }

  static ReactionInfo? parseReaction(String text) {
    return ReactionHelper.parseIncomingReaction(text);
  }
}
