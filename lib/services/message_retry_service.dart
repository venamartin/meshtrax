import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../helpers/path_helper.dart';
import '../helpers/timeout_helper.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_protocol.dart';
import 'app_settings_service.dart';
import 'app_debug_log_service.dart';

class _AckHistoryEntry {
  final String messageId;
  final List<int> ackHashes;
  final DateTime timestamp;

  _AckHistoryEntry({
    required this.messageId,
    required this.ackHashes,
    required this.timestamp,
  });
}

/// (messageId, timestamp, attemptIndex, pathLength) — stored per ACK hash
/// for O(1) lookup, so a late PUSH_CODE_SEND_CONFIRMED credits the attempt
/// it belongs to and the route kind (-1 flood) that attempt used.
typedef AckHashMapping = ({
  String messageId,
  DateTime timestamp,
  int attemptIndex,
  int? pathLength,
});

class RetryServiceConfig {
  final FutureOr<void> Function(Contact, String, int, int) sendMessage;
  // Writes the attempt's route and runs the send with no other route write
  // in between (the connector's sendOnRoute). Without it the service writes
  // the route itself and then sends.
  final Future<void> Function(
      Contact, PathSelection, Future<void> Function() send)? sendOnRoute;
  final void Function(String, Message) addMessage;
  final void Function(Message) updateMessage;
  final Function(Contact)? clearContactPath;
  // (contact, path bytes, hop count, hash width of the bytes)
  final Function(Contact, Uint8List, int, int)? setContactPath;
  final int Function(int pathLength, int messageBytes, {Contact? contact})?
  calculateTimeout;
  final Uint8List? Function()? getSelfPublicKey;
  // The radio's on-air hash width: the width a user override is written at.
  final int Function()? pathHashByteWidth;
  // LoRa airtime of a packet of this many bytes at the radio's settings:
  // sizes the wait for a repeater's copy of my own flood.
  final int Function(int packetBytes)? estimateAirtime;
  final String Function(Contact, String)? prepareContactOutboundText;
  // A message to this contact was just delivered by a flood attempt.
  final Function(Contact)? onFloodDelivered;
  // Pathfinder's ranked routes to a contact, best first; null while it is off.
  final List<PathSelection>? Function(Contact)? graphRoutes;
  // How one direct attempt ended: the route it went on, whether its ACK
  // came, and how many hops of the route were heard passing it on (0: the
  // first repeater was listened for and not heard; null: nobody could be
  // listened for).
  final void Function(Contact, PathSelection, bool delivered,
      int? tripTimeMs, int? hopsHeard)? onAttemptResult;
  // Pathfinder may ask for a moment before a message's first attempt: the
  // time a Discover's answers take, where it does not know who hears this
  // radio. Null: send now.
  final Future<void>? Function(Contact)? beforeFirstAttempt;
  // Whether the repeater [hop] ([width] bytes) would be heard passing a
  // routed DM of mine on: the app can read its own packets in the radio's
  // RX log, and that repeater was heard lately.
  final bool Function(List<int> hop, int width)? hearsPassOnBy;
  // A repeater was heard passing a routed attempt on, for the first time:
  // the first repeater of its route heard this radio.
  final void Function(Contact, PathSelection)? onPassedOn;
  // An attempt is about to go out: Pathfinder gates my own echoes on it.
  final void Function(Contact, PathSelection, int attempt)? onAttemptStarted;
  // The radio confirmed an ACK for a message to this contact (uint32 hash).
  final void Function(Contact, int ackHash)? onAckMatched;
  // The last ladder to this contact (pubkey hex) ended: the route it left
  // on the radio is no longer the ladder's to hold. [delivered] is that
  // last message's outcome; a ladder that ran out cleared the route, and
  // the graph hears of its failures only after [lateAckGrace].
  final void Function(String contactKey, {required bool delivered})?
      onLadderEnded;
  // One message's ladder is over: delivered or not, and whether a repeater
  // was heard echoing a flood of it (null: no flood of it was observable).
  final void Function(String contactKey,
      {required bool delivered, required bool? echoHeard})? onSendOutcome;
  // A flood attempt that went on the air ended: its ACK came, or its wait
  // ran out. Floods are never reported through onAttemptResult (nothing
  // to judge a route by), but Pathfinder still needs to know.
  final void Function(Contact, {required bool delivered})? onFloodAttemptEnded;
  final AppSettingsService? appSettingsService;
  final AppDebugLogService? debugLogService;

  const RetryServiceConfig({
    required this.sendMessage,
    this.sendOnRoute,
    required this.addMessage,
    required this.updateMessage,
    this.clearContactPath,
    this.setContactPath,
    this.calculateTimeout,
    this.getSelfPublicKey,
    this.pathHashByteWidth,
    this.estimateAirtime,
    this.prepareContactOutboundText,
    this.onFloodDelivered,
    this.graphRoutes,
    this.onAttemptResult,
    this.beforeFirstAttempt,
    this.hearsPassOnBy,
    this.onPassedOn,
    this.onAttemptStarted,
    this.onAckMatched,
    this.onLadderEnded,
    this.onSendOutcome,
    this.onFloodAttemptEnded,
    this.appSettingsService,
    this.debugLogService,
  });
}

/// Sends a contact message and retries it until an ACK arrives.
///
/// With Pathfinder able to route, the ladder is planned by [planAttempts]:
/// Pathfinder's best route twice, then its next, then floods; the radio's
/// stored route is never tried. Otherwise (Pathfinder off, a user
/// override, a manual resend) each attempt is resolved from the live
/// contact: the known route (the override, else the firmware's) gets one
/// try, two at 4 or more attempts, then floods. A flood resets the path,
/// which is also how the firmware re-learns the route. The app writes a
/// route to the radio only for a Pathfinder route or a user override,
/// never for the firmware's own.
class MessageRetryService extends ChangeNotifier {
  static const int maxAckHistorySize = 100;
  static const int retryBackoffMs = 5000;
  static const Duration lateAckGrace = Duration(minutes: 5);
  int _maxRetries = 3;

  /// Read live from settings so a slider change applies to the next send.
  int get maxRetries =>
      (_config?.appSettingsService?.settings.maxMessageRetries ?? _maxRetries)
          .clamp(1, 5);

  final Map<String, Timer> _timeoutTimers = {};
  final Map<String, Message> _pendingMessages = {};
  final Map<String, Contact> _pendingContacts = {};
  // Pathfinder's ladder, by attempt index, for the messages in
  // [_pathfinderLadders]. The rest (Pathfinder off, a user override, a
  // manual resend) resolve each attempt from the live contact, as before
  // Pathfinder.
  final Map<String, List<PathSelection>> _plans = {};
  final Set<String> _pathfinderLadders = {};
  final Set<String> _floodFirst = {};
  // Texts too long for the firmware's fifth attempt
  // (maxTextBytesForLateAttempt): their ladder stops at four.
  final Set<String> _nearMaxText = {};
  // What each attempt actually went out on, and which attempts the radio
  // accepted (RESP_CODE_SENT): only those were on the air.
  final Map<String, Map<int, PathSelection>> _attemptRoutes = {};
  final Map<String, Set<int>> _onAir = {};
  // Attempts already reported to Pathfinder as failed, at their timeout.
  final Map<String, Set<int>> _reported = {};
  // Routed attempts whose first repeater is listened for, and how many
  // hops of the route were heard passing each on so far; the watch for
  // the attempt in flight; and the attempts whose packet was asked to go
  // out a second time, true once the radio took that copy (see
  // [_armPassOnWatch]).
  final Map<String, Map<int, int>> _passedOn = {};
  final Map<String, Timer> _passOnTimers = {};
  final Map<String, Map<int, bool>> _secondCopy = {};
  // Waiting for a repeater: the watch for a repeater's copy of a flood
  // in flight, how long it was, when a message was parked for lack of one,
  // and how often it has been sent again on a repeater coming into range.
  final Map<String, Timer> _echoTimers = {};
  final Map<String, int> _echoWaitMs = {};
  // Parked messages: false until their cooldown has run.
  final Map<String, bool> _parkedReady = {};
  final Map<String, Timer> _cooldownTimers = {};
  final Map<String, int> _autoResends = {};
  // How often a flood nobody passed on went out again at once, a repeater
  // having been heard within [quickResendWindow] (see [_park]).
  final Map<String, int> _quickResends = {};
  static const int maxQuickResends = 2;
  static const Duration quickResendWindow = Duration(minutes: 1);
  // The attempt numbers those sends went out with, and the number the
  // radio was last given for each message, with the attempt it was for.
  final Map<String, Set<int>> _resendAttempts = {};
  final Map<String, int> _wireAttempts = {};
  final Map<String, int> _wireRungs = {};
  // Every send the radio took for each ACK code: the firmware hashes only
  // an attempt's low two bits into its ACK (composeMsgPacket), so attempts
  // 0 and 4 of one DM share a code, as a rung and its resends do.
  // [blind]: the receiver's ACK names no attempt for this send (see
  // _blindAttemptByte).
  final Map<String, List<({int rung, int wire, bool flood, bool blind})>>
      _sendsByAck = {};

  /// Whether the receiver's ACK carries no attempt byte worth reading for a
  /// send of [textBytes] (as sent) at attempt [wire]: at 0-3 the byte comes
  /// after the text, and when the 5 header bytes plus the text fill their
  /// AES blocks exactly there is no padding there, so the receiver reads
  /// past its decrypted bytes (Mesh.cpp, `data[MAX_PACKET_PAYLOAD]`).
  static bool _blindAttemptByte(int wire, int textBytes) =>
      wire <= 3 && (5 + textBytes) % 16 == 0;

  /// Sends a parked message gets on repeaters coming into range, outside
  /// Max Message Retries; after that its ladder moves on.
  static const int maxAutoResends = 3;

  /// Floor between one parked send and the next, on top of the echo wait.
  static const int repeaterCooldownMs = 30000;

  /// A flood nobody echoed is parked only when a repeater was heard this
  /// recently. With none heard for longer, none is near: waiting for one
  /// would hold the message, and every later one to the contact, so it
  /// goes on up its ladder like any other and fails if no ACK comes.
  static const Duration repeaterHeardWindow = Duration(minutes: 10);

  /// A parked message that has heard no repeater for this long fails,
  /// so the messages queued behind it to the same contact can go.
  static const Duration parkLimit = Duration(minutes: 10);
  final Map<String, Timer> _parkLimitTimers = {};
  final DateTime Function() _now;
  DateTime? _repeaterHeardAt;

  /// Whether a repeater was heard within [repeaterHeardWindow]: where
  /// none was, a direct route can't be relied on.
  bool get repeaterHeardRecently {
    final at = _repeaterHeardAt;
    if (at == null) return false;
    // A clock set back can't tell: no park, the default.
    final since = _now().difference(at);
    return !since.isNegative && since < repeaterHeardWindow;
  }
  final Map<String, AckHashMapping> _ackHashToMessageId = {};
  final Map<String, List<int>> _expectedAckHashes = {};
  final List<_AckHistoryEntry> _ackHistory = [];
  final Map<String, List<String>> _sendQueue = {};
  final Set<String> _activeMessages = {};
  final Set<String> _resolvedMessages = {};
  final Map<String, String> _expectedHashToMessageId = {};
  // Messages whose attempt went out with no ACK hash to know its SENT by
  // (no self key yet): the only ones a SENT that matches nothing may go to.
  final Set<String> _sentWithoutHash = {};

  RetryServiceConfig? _config;

  int _radioWidth(Contact contact) =>
      _config?.pathHashByteWidth?.call() ?? contact.pathHashSize;

  MessageRetryService({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  void initialize(RetryServiceConfig config) {
    _config = config;
  }

  void setMaxRetries(int value) {
    _maxRetries = value.clamp(1, 5);
  }

  /// Compute expected ACK hash using same algorithm as firmware:
  /// SHA256([timestamp(4)][attempt(1)][text][sender_pubkey(32)]) -> first 4 bytes
  static int computeExpectedAckHash(
    int timestampSeconds,
    int attempt,
    String text,
    Uint8List senderPubKey,
  ) {
    final textBytes = utf8.encode(text);
    final buffer = Uint8List(4 + 1 + textBytes.length + senderPubKey.length);
    int offset = 0;

    // timestamp (4 bytes, little-endian)
    buffer[offset++] = timestampSeconds & 0xFF;
    buffer[offset++] = (timestampSeconds >> 8) & 0xFF;
    buffer[offset++] = (timestampSeconds >> 16) & 0xFF;
    buffer[offset++] = (timestampSeconds >> 24) & 0xFF;

    // attempt (1 byte)
    buffer[offset++] = attempt & 0x03;

    // text
    buffer.setRange(offset, offset + textBytes.length, textBytes);
    offset += textBytes.length;

    // sender public key (32 bytes)
    buffer.setRange(offset, offset + senderPubKey.length, senderPubKey);

    // Compute SHA256 and return first 4 bytes
    final hash = sha256.convert(buffer);
    final bytes = Uint8List.fromList(hash.bytes.sublist(0, 4));
    return (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | bytes[0];
  }

  /// Whether [messageId] is waiting behind another message to its contact.
  bool isQueued(String messageId) =>
      _pendingMessages.containsKey(messageId) &&
      !_activeMessages.contains(messageId);

  /// [floodFirst] floods every attempt, for resending a message whose route
  /// just failed. Ignored when the contact has a manual route override — a
  /// user-pinned route outranks the flood heuristic.
  Future<void> sendMessageWithRetry({
    required Contact contact,
    required String text,
    Uint8List? pathBytes,
    int? pathLength,
    bool floodFirst = false,
  }) async {
    final messageId = const Uuid().v4();
    // A user override outranks the resend's flood.
    if (floodFirst && contact.pathOverride == null) _floodFirst.add(messageId);
    final outboundText =
        _config?.prepareContactOutboundText?.call(contact, text) ?? text;
    if (utf8.encode(outboundText).length > maxTextBytesForLateAttempt) {
      _nearMaxText.add(messageId);
    }
    _plan(messageId, contact);
    final first = _selectionFor(messageId, 0, contact);
    final messagePathBytes = pathBytes ?? Uint8List.fromList(first.pathBytes);
    final messagePathLength =
        pathLength ?? (first.useFlood ? -1 : first.hopCount);
    final message = Message(
      senderKey: contact.publicKey,
      text: text,

      timestamp: DateTime.now(),
      isOutgoing: true,
      status: MessageStatus.pending,
      messageId: messageId,
      retryCount: 0,
      pathLength: messagePathLength,
      pathBytes: messagePathBytes,
      pathHashSize: first.hashSize,
      routeSource: first.source ?? RouteSource.firmware,
    );

    _pendingMessages[messageId] = message;
    _pendingContacts[messageId] = contact;

    _config?.addMessage(contact.publicKeyHex, message);

    // Queue per contact — only one message in-flight at a time to avoid
    // overflowing the firmware's 8-entry expected_ack_table.
    final contactKey = contact.publicKeyHex;
    _sendQueue[contactKey] ??= [];
    _sendQueue[contactKey]!.add(messageId);

    if (!_activeMessages.any(
      (id) => _pendingContacts[id]?.publicKeyHex == contactKey,
    )) {
      _sendNextForContact(contactKey);
    }
  }

  void _sendNextForContact(String contactKey) {
    final queue = _sendQueue[contactKey];
    if (queue == null) return;

    // Drain stale entries iteratively instead of recursing.
    while (queue.isNotEmpty) {
      final messageId = queue.removeAt(0);
      if (_pendingMessages.containsKey(messageId)) {
        _activeMessages.add(messageId);
        final contact = _pendingContacts[messageId];
        final wait = contact == null
            ? null
            : _config?.beforeFirstAttempt?.call(contact);
        if (wait == null) {
          _send(messageId);
        } else {
          // The ladder is planned again from what the wait brought; a
          // wait that failed still ends in the send.
          void go() {
            final to = _pendingContacts[messageId];
            if (to == null ||
                !_pendingMessages.containsKey(messageId) ||
                _resolvedMessages.contains(messageId)) {
              return;
            }
            _plan(messageId, to);
            _send(messageId);
          }

          wait.then((_) => go(), onError: (_) => go());
        }
        return;
      }
    }
  }

  /// Sends [messageId]'s current attempt. One that throws (a radio write
  /// that failed) fails the message: left pending with no timer, it would
  /// hold every later message to the contact behind it for good.
  void _send(String messageId, {bool resend = false, bool same = false}) {
    final attempt = _pendingMessages[messageId]?.retryCount;
    _attemptSend(messageId, resend: resend, same: same).catchError((e) {
      debugPrint('_attemptSend threw for $messageId: $e');
      final message = _pendingMessages[messageId];
      final contact = _pendingContacts[messageId];
      // Settled already, or its ladder moved on with a timer of its own.
      if (message == null ||
          contact == null ||
          _resolvedMessages.contains(messageId) ||
          message.retryCount != attempt ||
          message.status != MessageStatus.pending) {
        return;
      }
      _config?.debugLogService?.warn(
        'Sending "${_short(message.text)}" to ${contact.name} failed: $e',
        tag: 'AckHash',
      );
      _fail(messageId, message, contact, clearRoute: false);
    });
  }

  static String _short(String text) =>
      text.length > 20 ? '${text.substring(0, 20)}...' : text;

  /// Plans Pathfinder's ladder for [messageId] when it applies to
  /// [contact]: no override, no manual resend, and Pathfinder can route.
  /// The first [keep] attempts already went out and stay as they were.
  void _plan(String messageId, Contact contact, {int keep = 0}) {
    final routes = contact.pathOverride == null &&
            !_floodFirst.contains(messageId)
        ? _config?.graphRoutes?.call(contact)
        : null;
    if (routes == null) {
      _pathfinderLadders.remove(messageId);
      _plans.remove(messageId);
      return;
    }
    final width = _radioWidth(contact);
    final old = _plans[messageId] ?? const <PathSelection>[];
    if (old.isEmpty || keep <= 0) {
      _plans[messageId] = planAttempts(contact,
          radioWidth: width,
          budget: _budgetFor(messageId),
          graphRoutes: routes,
          bestTwice: true);
    } else {
      // The rungs already sent stay; the rest is planned again from the
      // routes not yet tried, still closing with the floods the ladder
      // owes.
      final kept = old.take(keep).toList();
      final owed = old.where((s) => s.useFlood).length -
          kept.where((s) => s.useFlood).length;
      _plans[messageId] = [
        ...kept,
        ...planAttempts(contact,
            radioWidth: width,
            budget: old.length - kept.length,
            graphRoutes: routes,
            // An attempt that never left my doorstep tried nothing of its
            // route.
            tried: [
              for (var i = 0; i < kept.length; i++)
                if (!_silent(messageId, i)) kept[i],
            ],
            floods: owed,
            bestTwice: true),
      ];
    }
    _pathfinderLadders.add(messageId);
  }

  /// The route attempt [attempt] goes out on.
  PathSelection _selectionFor(String messageId, int attempt, Contact contact) {
    final width = _radioWidth(contact);
    if (_pathfinderLadders.contains(messageId)) {
      final plan = _plans[messageId]!;
      return attempt < plan.length ? plan[attempt] : PathSelection.flood(width);
    }
    final routeAttempts = maxRetries >= 4 ? 2 : 1;
    return attempt < routeAttempts && !_floodFirst.contains(messageId)
        ? resolvePathSelection(contact, radioWidth: width)
        : PathSelection.flood(width);
  }

  /// Attempts this message gets: Pathfinder's ladder keeps its planned
  /// length; the firmware ladder follows the setting, as before.
  int _attemptBudget(String messageId) => _pathfinderLadders.contains(messageId)
      ? _plans[messageId]!.length
      : _budgetFor(messageId);

  /// The Max Message Retries setting, except that a text the firmware
  /// refuses to send a fifth time stops at four.
  int _budgetFor(String messageId) => _nearMaxText.contains(messageId)
      ? math.min(maxRetries, maxAttemptsForNearMaxText)
      : maxRetries;

  void _onMessageResolved(String messageId, String contactKey,
      {required bool delivered}) {
    if (_resolvedMessages.contains(messageId)) return;
    _resolvedMessages.add(messageId);
    _activeMessages.remove(messageId);
    _config?.onSendOutcome?.call(contactKey,
        delivered: delivered,
        echoHeard: _echoHeard.remove(messageId)
            ? true
            : _echoObservable.remove(messageId)
                ? false
                : null);
    _sendNextForContact(contactKey);
    if (!isSendingTo(contactKey)) {
      _config?.onLadderEnded?.call(contactKey, delivered: delivered);
    }
  }

  // Messages a flood of which could be seen echoed, and those one was.
  final Set<String> _echoObservable = {};
  final Set<String> _echoHeard = {};

  /// Whether a message to [contactKey] is on its ladder now: that ladder
  /// owns the route stored on the radio.
  bool isSendingTo(String contactKey) => _activeMessages
      .any((id) => _pendingContacts[id]?.publicKeyHex == contactKey);

  /// Whether the copy numbered [attempt] of the DM [text] to [contactKey]
  /// stamped [timestampSeconds] should still go out: the DM waits for its
  /// ACK, and the attempt this copy was made for is the one running. A
  /// copy that waited for a quiet radio while the ACK came is not worth
  /// sending, and one whose attempt ended meanwhile would pass for the
  /// next attempt with this one's bytes (simulator, 2026-11-24).
  bool awaitsAck(
      String contactKey, int timestampSeconds, String text, int attempt) {
    final id = _messageIdOf(contactKey, timestampSeconds, text);
    final message = id == null ? null : _pendingMessages[id];
    return message != null &&
        _wireAttempts[id] == attempt &&
        _wireRungs[id] == message.retryCount;
  }

  String? _messageIdOf(String contactKey, int timestampSeconds, String text) =>
      _pendingMessages.entries
          .where(
            (e) =>
                e.value.text == text &&
                e.value.timestamp.millisecondsSinceEpoch ~/ 1000 ==
                    timestampSeconds &&
                _pendingContacts[e.key]?.publicKeyHex == contactKey,
          )
          .firstOrNull
          ?.key;

  /// The route of the attempt now going out with the DM [text] to
  /// [contact] (as the radio holds it now) stamped [timestampSeconds],
  /// chosen again: the radio learned a route from them while the attempt
  /// waited, and stored it over the one written for it. Pathfinder's ladder
  /// plans this rung again from what it knows now; the firmware ladder takes
  /// the radio's route as it is. The attempt is recorded on the new route,
  /// so its outcome is credited to the route that carried it. Null when no
  /// such message waits.
  PathSelection? rechooseRoute(
      Contact contact, int timestampSeconds, String text) {
    final messageId =
        _messageIdOf(contact.publicKeyHex, timestampSeconds, text);
    final message = messageId == null ? null : _pendingMessages[messageId];
    if (messageId == null || message == null) return null;
    final attempt = message.retryCount;
    final before = _attemptRoutes[messageId]?[attempt];
    if (_pathfinderLadders.contains(messageId)) {
      _plan(messageId, contact, keep: attempt);
    }
    final selection = _selectionFor(messageId, attempt, contact);
    (_attemptRoutes[messageId] ??= {})[attempt] = selection;
    _pendingMessages[messageId] = message.copyWith(
      pathLength: selection.useFlood ? -1 : selection.hopCount,
      pathBytes: Uint8List.fromList(selection.pathBytes),
      pathHashSize: selection.hashSize,
      routeSource: selection.source ?? RouteSource.firmware,
      guessedHops: selection.guessedHops,
    );
    // A flood's echoes are told apart by attempt from its start.
    if (selection.useFlood && !(before?.useFlood ?? false)) {
      _config?.onAttemptStarted?.call(contact, selection, attempt);
    }
    return selection;
  }

  /// The attempt number a parked rung is sent again with. Its own number
  /// would repeat the packet exactly, and every radio that heard it drops
  /// a packet it has seen, unforwarded and unACKed (Mesh.cpp, wasSeen). A
  /// number above the ladder's with the rung's low two bits is a new packet
  /// whose ACK still names the rung: the firmware hides the number in a
  /// tail byte and hashes only its low two bits into the ACK
  /// (BaseChatMesh::composeMsgPacket). A text too long for the tail byte
  /// goes out as before.
  int _resendAttempt(String messageId, int rung) {
    if (_nearMaxText.contains(messageId)) return rung;
    final used = _resendAttempts[messageId] ??= {};
    var attempt = (rung & 3) + 4;
    while (attempt < _attemptBudget(messageId) || used.contains(attempt)) {
      attempt += 4;
    }
    used.add(attempt);
    return attempt;
  }

  /// [resend]: a parked rung goes out again as a new packet
  /// ([_resendAttempt]). [same]: the attempt in flight goes out again as
  /// the same packet ([_armPassOnWatch]); its ACK wait runs on until the
  /// radio takes this copy.
  Future<void> _attemptSend(String messageId,
      {bool resend = false, bool same = false}) async {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final config = _config;

    if (message == null || contact == null || config == null) return;

    final selection = _selectionFor(messageId, message.retryCount, contact);
    (_attemptRoutes[messageId] ??= {})[message.retryCount] = selection;
    _pendingMessages[messageId] = message.copyWith(
      pathLength: selection.useFlood ? -1 : selection.hopCount,
      pathBytes: Uint8List.fromList(selection.pathBytes),
      pathHashSize: selection.hashSize,
      routeSource: selection.source ?? RouteSource.firmware,
      guessedHops: selection.guessedHops,
    );

    final attempt = message.retryCount;
    final wireAttempt = same
        ? _wireAttempts[messageId] ?? attempt
        : resend
            ? _resendAttempt(messageId, attempt)
            : attempt;
    final timestampSeconds = message.timestamp.millisecondsSinceEpoch ~/ 1000;
    Future<void> send() async {
      // Re-validate after the route write — a timer or ACK could have
      // resolved/retried this message while it waited.
      final currentMessage = _pendingMessages[messageId];
      if (currentMessage == null || _resolvedMessages.contains(messageId)) {
        debugPrint(
          '_attemptSend: message $messageId resolved during path sync, aborting',
        );
        return;
      }
      if (currentMessage.retryCount != attempt) {
        debugPrint(
          '_attemptSend: message $messageId retryCount changed during path sync, aborting',
        );
        return;
      }
      _wireAttempts[messageId] = wireAttempt;
      _wireRungs[messageId] = attempt;
      _registerExpectedAck(
          messageId, message, contact, wireAttempt, timestampSeconds);
      if (!same) {
        config.onAttemptStarted?.call(contact, selection, attempt);
        // Before the send, as always: its RESP_CODE_SENT replaces this
        // timer with the real one, and can arrive while the send is
        // awaited.
        _startPreSentTimer(messageId);
      }
      await config.sendMessage(
          contact, message.text, wireAttempt, timestampSeconds);
    }

    final onRoute = config.sendOnRoute;
    if (onRoute != null) {
      await onRoute(contact, selection, send);
    } else {
      if (selection.useFlood) {
        await config.clearContactPath?.call(contact);
      } else if (selection.source != RouteSource.firmware) {
        await config.setContactPath?.call(
          contact,
          Uint8List.fromList(selection.pathBytes),
          selection.hopCount,
          selection.hashSize,
        );
      }
      await send();
    }
  }

  void _registerExpectedAck(String messageId, Message message, Contact contact,
      int attempt, int timestampSeconds) {
    final config = _config;
    if (config == null) return;
    // Compute expected ACK hash that device will return in RESP_CODE_SENT
    // IMPORTANT: Use the transformed text (with SMAZ encoding if enabled) to match device's hash
    final selfPubKey = config.getSelfPublicKey?.call();
    if (selfPubKey == null) {
      _sentWithoutHash.add(messageId);
    } else {
      _sentWithoutHash.remove(messageId);
      final outboundText =
          config.prepareContactOutboundText?.call(contact, message.text) ??
          message.text;
      final expectedHash = MessageRetryService.computeExpectedAckHash(
        timestampSeconds,
        attempt,
        outboundText,
        selfPubKey,
      );
      final expectedHashHex = expectedHash.toRadixString(16).padLeft(8, '0');
      _expectedHashToMessageId[expectedHashHex] = messageId;

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      config.debugLogService?.info(
        'Sent "$shortText" to ${contact.name} → expect ACK hash $expectedHashHex (attempt $attempt)',
        tag: 'AckHash',
      );
    }
  }

  /// [copy]: the attempt's packet is going out a second time
  /// ([_notPassedOn]); the message stays "sent" while it does.
  void _startPreSentTimer(String messageId, {bool copy = false}) {
    final config = _config;

    // Safety timer: if RESP_CODE_SENT never arrives (silent BLE failure, device
    // busy, etc.) the message would stay at 'pending' forever.  Start a fallback
    // timer here that triggers _handleTimeout if updateMessageFromSent() hasn't
    // already started a real timer.
    const preSentTimeoutMs = 15000;
    _timeoutTimers[messageId]?.cancel();
    _timeoutTimers[messageId] = Timer(
      const Duration(milliseconds: preSentTimeoutMs),
      () {
        // Only act if the message is still pending (no RESP_CODE_SENT received yet)
        final status = _pendingMessages[messageId]?.status;
        if (status == MessageStatus.pending ||
            (copy && status == MessageStatus.sent)) {
          config?.debugLogService?.warn(
            'No RESP_CODE_SENT received within ${preSentTimeoutMs}ms for message $messageId — triggering retry',
            tag: 'AckHash',
          );
          _handleTimeout(messageId);
        }
      },
    );
  }

  /// [isFlood]: how the radio sent it (RESP_CODE_SENT byte 1). The radio
  /// floods whenever it holds no route to the contact, whatever the app
  /// asked for, and a route the app did not ask for means a stale stored
  /// one went out — either way the attempt's evidence is not what the
  /// ladder thinks.
  bool updateMessageFromSent(int ackHash, int timeoutMs, {bool? isFlood}) {
    final config = _config;
    if (config == null) return false;

    final ackHashHex = ackHash.toRadixString(16).padLeft(8, '0');

    // Try hash-based matching (fixes LoRa message drops causing mismatches)
    String? messageId = _expectedHashToMessageId.remove(ackHashHex);
    Contact? contact;

    if (messageId != null) {
      contact = _pendingContacts[messageId];
      final message = _pendingMessages[messageId];

      if (contact != null && message != null) {
        final shortText = message.text.length > 20
            ? '${message.text.substring(0, 20)}...'
            : message.text;
        config.debugLogService?.info(
          'RESP_CODE_SENT received: ACK hash $ackHashHex ✓ matched "$shortText" to ${contact.name}',
          tag: 'AckHash',
        );
      } else {
        config.debugLogService?.warn(
          'RESP_CODE_SENT: ACK hash $ackHashHex matched but message no longer pending',
          tag: 'AckHash',
        );
        return true;
      }
    } else if (_checkAckHistory(ackHash)) {
      // A copy of a message already done with, such as a resend that went
      // out as its ACK came: it is nobody else's SENT.
      config.debugLogService?.info(
        'RESP_CODE_SENT: ACK hash $ackHashHex is a completed message\'s copy',
        tag: 'AckHash',
      );
      return true;
    }

    if (messageId == null || contact == null) {
      // Hash lookup failed. This can happen when selfPubKey was null during
      // _attemptSend, so no hash was stored. Fall back to the oldest active
      // pending message sent that way so the timeout timer is always started
      // and the message never gets stuck at 'pending' forever. A message
      // sent with a hash only takes its own SENT: another contact's once
      // marked it delivered on that contact's ACK.
      final fallbackId = _activeMessages
          .where(_sentWithoutHash.contains)
          .firstOrNull;
      if (fallbackId != null) {
        final fallbackMsg = _pendingMessages[fallbackId];
        final fallbackContact = _pendingContacts[fallbackId];
        if (fallbackMsg != null && fallbackContact != null &&
            fallbackMsg.status == MessageStatus.pending) {
          _sentWithoutHash.remove(fallbackId);
          messageId = fallbackId;
          contact = fallbackContact;
          config.debugLogService?.warn(
            'RESP_CODE_SENT: ACK hash $ackHashHex not matched — using fallback for "${fallbackMsg.text.length > 20 ? "${fallbackMsg.text.substring(0, 20)}..." : fallbackMsg.text}" to ${fallbackContact.name}',
            tag: 'AckHash',
          );
        }
      }
      if (messageId == null || contact == null) {
        debugPrint('No pending message found for ACK hash: $ackHashHex');
        return false;
      }
    }

    final message = _pendingMessages[messageId]!;
    (_onAir[messageId] ??= {}).add(message.retryCount);
    if (isFlood != null) {
      final askedFlood = (message.pathLength ?? -1) < 0;
      final asked = _attemptRoutes[messageId]?[message.retryCount];
      if (askedFlood == isFlood) {
        config.debugLogService?.info(
          'RESP_CODE_SENT: attempt ${message.retryCount + 1} to ${contact.name} '
          'went out ${isFlood ? "as a flood" : "on the route"}, as asked',
          tag: 'AckHash',
        );
      } else if (!isFlood && asked?.source == RouteSource.firmware) {
        config.debugLogService?.info(
          'RESP_CODE_SENT: attempt ${message.retryCount + 1} to ${contact.name} '
          "went out on the radio's route, one the contact list didn't show yet",
          tag: 'AckHash',
        );
      } else {
        config.debugLogService?.warn(
          'RESP_CODE_SENT: attempt ${message.retryCount + 1} to ${contact.name} '
          'was asked to go ${askedFlood ? "as a flood" : "on a route"} but the '
          'radio sent it ${isFlood ? "as a flood" : "on its stored route"}',
          tag: 'AckHash',
        );
      }
    }
    _ackHashToMessageId[ackHashHex] = (
      messageId: messageId,
      timestamp: DateTime.now(),
      attemptIndex: message.retryCount,
      pathLength: message.pathLength,
    );
    final wire = _wireAttempts[messageId] ?? message.retryCount;
    final sends = _sendsByAck[ackHashHex] ??= [];
    if (!sends.any((s) => s.rung == message.retryCount && s.wire == wire)) {
      final sentText =
          config.prepareContactOutboundText?.call(contact, message.text) ??
              message.text;
      sends.add((
        rung: message.retryCount,
        wire: wire,
        flood: isFlood ?? (message.pathLength ?? -1) < 0,
        blind: _blindAttemptByte(wire, utf8.encode(sentText).length),
      ));
    }

    // Add this ACK hash to the list of expected ACKs for this message (for history)
    _expectedAckHashes[messageId] ??= [];
    if (!_expectedAckHashes[messageId]!.any((hash) => hash == ackHash)) {
      _expectedAckHashes[messageId]!.add(ackHash);
    }

    final pathLengthValue = message.pathLength ?? contact.pathLength;

    int actualTimeout = timeoutMs;
    if (config.calculateTimeout != null) {
      final outboundText =
          config.prepareContactOutboundText?.call(contact, message.text) ??
          message.text;
      actualTimeout = config.calculateTimeout!(
        pathLengthValue,
        txtMsgPacketBytes(
          utf8.encode(outboundText).length,
          hops: pathLengthValue < 0 ? 0 : pathLengthValue,
        ),
        contact: contact,
      );
    }

    final updatedMessage = message.copyWith(
      status: MessageStatus.sent,
      expectedAckHash: ackHash,
      estimatedTimeoutMs: actualTimeout,
      sentAt: DateTime.now(),
    );

    _pendingMessages[messageId] = updatedMessage;
    config.updateMessage(updatedMessage);

    // The radio took the second copy of this attempt's packet.
    final copies = _secondCopy[messageId];
    if (copies?[message.retryCount] == false) {
      copies![message.retryCount] = true;
    }
    _startTimeoutTimer(messageId, actualTimeout);
    _armEchoWatch(messageId, contact, updatedMessage, actualTimeout,
        isFlood: isFlood);
    _armPassOnWatch(messageId, contact, updatedMessage, isFlood: isFlood);
    return true;
  }

  /// A routed attempt just left the radio. Its first repeater sends it on
  /// within [TimeoutHelper.passOnWaitMs], and this radio hears that when it
  /// has heard that repeater lately ([RetryServiceConfig.hearsPassOnBy]).
  /// Not heard: most likely the packet never reached the repeater (two
  /// radios sending at once), so the same packet goes out once more. A
  /// repeater that did pass the first on drops the second unsent (Mesh.cpp
  /// onRecvPacket, wasSeen), so nothing is doubled on the air but this
  /// radio's own transmission, and the receiver never gets two. Not heard
  /// again: the attempt is over now, without waiting out its ACK.
  ///
  /// The second copy waits for a quiet radio like any send, which after a
  /// message came in is several seconds. The attempt's ACK wait stops
  /// while it does and starts again when the radio takes the copy:
  /// running on, it ended the attempt on one unheard copy, and the copy
  /// then went out as the next attempt (simulator, 2026-11-24).
  void _armPassOnWatch(String messageId, Contact contact, Message message,
      {bool? isFlood}) {
    final config = _config;
    final airtime = config?.estimateAirtime;
    final rung = message.retryCount;
    final selection = _attemptRoutes[messageId]?[rung];
    if (config == null || airtime == null || selection == null) return;
    if ((isFlood ?? false) ||
        selection.useFlood ||
        selection.hopCount <= 0 ||
        selection.pathBytes.length < selection.hashSize) {
      return;
    }
    // A 1-byte code is shared by too many repeaters to say which one was
    // heard lately.
    if (selection.hashSize < 2) return;
    if ((_passedOn[messageId]?[rung] ?? 0) > 0) return;
    final firstHop = selection.pathBytes.sublist(0, selection.hashSize);
    if (!(config.hearsPassOnBy?.call(firstHop, selection.hashSize) ?? false)) {
      return;
    }
    (_passedOn[messageId] ??= {})[rung] = 0;
    final waitMs = TimeoutHelper.passOnWaitMs(airtime(txtMsgPacketBytes(
        _sentBytes(contact, message).length,
        hops: selection.pathBytes.length)));
    _passOnTimers[messageId]?.cancel();
    _passOnTimers[messageId] = Timer(
        Duration(milliseconds: waitMs), () => _notPassedOn(messageId, rung));
  }

  Uint8List _sentBytes(Contact contact, Message message) => utf8.encode(
      _config?.prepareContactOutboundText?.call(contact, message.text) ??
          message.text);

  void _notPassedOn(String messageId, int rung) {
    _passOnTimers.remove(messageId);
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final selection = _attemptRoutes[messageId]?[rung];
    if (message == null || contact == null || selection == null) return;
    // Not on this attempt any more, or settled.
    if (message.retryCount != rung ||
        message.status != MessageStatus.sent ||
        _resolvedMessages.contains(messageId)) {
      return;
    }
    final hop = PathHelper.firstHopHex(selection.pathBytes,
            stride: selection.hashSize) ??
        'The first repeater';
    final copies = _secondCopy[messageId] ??= {};
    if (!copies.containsKey(rung)) {
      copies[rung] = false;
      _config?.debugLogService?.info(
        '$hop was not heard passing "${_short(message.text)}" to '
        '${contact.name} on: sending the same packet once more',
        tag: 'AckHash',
      );
      _startPreSentTimer(messageId, copy: true);
      _send(messageId, same: true);
      return;
    }
    // The last attempt keeps its whole wait: nothing follows that could
    // use the time, and its ACK may still come.
    if (rung >= _attemptBudget(messageId) - 1) return;
    _config?.debugLogService?.warn(
      '$hop was not heard passing "${_short(message.text)}" to '
      '${contact.name} on, twice: attempt ${rung + 1} is over',
      tag: 'AckHash',
    );
    _timeoutTimers.remove(messageId)?.cancel();
    _handleTimeout(messageId);
  }

  /// Whether attempt [rung] of [messageId] never left my doorstep, as far
  /// as can be told: its first repeater was listened for and heard passing
  /// on neither of the two copies sent.
  bool _silent(String messageId, int rung) =>
      _passedOn[messageId]?[rung] == 0 &&
      _secondCopy[messageId]?[rung] == true;

  /// What Pathfinder is told of how far attempt [rung] was heard passed
  /// on. [skip]: a failed attempt whose first repeater was listened for
  /// and not heard, with one copy sent, says nothing: most likely two
  /// radios sent at once, and one such miss is no doubt about a doorstep.
  ({int? hops, bool skip}) _heardFor(String messageId, int rung,
      {required bool delivered}) {
    final hops = _passedOn[messageId]?[rung];
    if (hops != 0) return (hops: hops, skip: false);
    // Delivered, the doorstep heard it whatever was heard here.
    if (delivered) return (hops: null, skip: false);
    return (hops: 0, skip: !_silent(messageId, rung));
  }

  /// A repeater's copy of a routed DM of mine was read from the radio's RX
  /// log: the DM stamped [timestampSeconds] to [contactKey], sent as
  /// attempt [wireAttempt] with [textBytes], heard with [hopsLeft] still to
  /// go ([hopWidth] bytes each). The hops of its route before those have
  /// carried it, and the first of them heard this radio.
  void noteOwnCopy(String contactKey, int timestampSeconds, int wireAttempt,
      List<int> textBytes, List<int> hopsLeft, int hopWidth) {
    final config = _config;
    if (config == null) return;
    for (final MapEntry(key: id, value: message)
        in _pendingMessages.entries) {
      final contact = _pendingContacts[id];
      // A routed attempt goes out under its own number.
      final selection = _attemptRoutes[id]?[wireAttempt];
      if (contact == null ||
          contact.publicKeyHex != contactKey ||
          message.timestamp.millisecondsSinceEpoch ~/ 1000 !=
              timestampSeconds ||
          selection == null ||
          selection.useFlood ||
          selection.hashSize != hopWidth ||
          !listEquals<int>(_sentBytes(contact, message), textBytes)) {
        continue;
      }
      final route = selection.pathBytes;
      final done = route.length - hopsLeft.length;
      if (done <= 0 ||
          done % hopWidth != 0 ||
          !listEquals<int>(route.sublist(done), hopsLeft)) {
        return;
      }
      final hops = done ~/ hopWidth;
      final heard = _passedOn[id] ??= {};
      final before = heard[wireAttempt] ?? 0;
      if (before >= hops) return;
      heard[wireAttempt] = hops;
      if (message.retryCount == wireAttempt) {
        _passOnTimers.remove(id)?.cancel();
      }
      // How long it took is logged: the wait is sized from firmware
      // defaults, and a repeater's owner can set its delay longer.
      final sentAt = message.sentAt;
      final after = sentAt == null || message.retryCount != wireAttempt
          ? ''
          : ', ${DateTime.now().difference(sentAt).inMilliseconds} ms '
              'after the radio took it';
      config.debugLogService?.info(
        '${PathHelper.formatPathHex(route.sublist(done - hopWidth, done), stride: hopWidth)} '
        'passed "${_short(message.text)}" to ${contact.name} on '
        '(attempt ${wireAttempt + 1}, hop $hops of ${selection.hopCount}$after)',
        tag: 'AckHash',
      );
      if (before == 0) config.onPassedOn?.call(contact, selection);
      return;
    }
  }

  /// A flood just left the radio: if a repeater's copy of it can be seen
  /// at all, wait the firmware-anchored echo window for one; none means
  /// no repeater heard this radio, and the message is parked when one was
  /// heard within [repeaterHeardWindow]. [isFlood] is how the radio says it
  /// sent it (RESP_CODE_SENT), which wins over the plan: a rung planned as a
  /// flood that the radio sent on a route it still held can never come back
  /// as a flood echo, so waiting for one parked it next to a repeater; and
  /// a rung the radio flooded for want of a route can.
  void _armEchoWatch(
      String messageId, Contact contact, Message message, int attemptTimeoutMs,
      {bool? isFlood}) {
    final config = _config;
    final airtime = config?.estimateAirtime;
    final selection = _attemptRoutes[messageId]?[message.retryCount];
    if (config == null || airtime == null || selection == null) return;
    if (!(isFlood ?? selection.useFlood)) return;
    final outboundText =
        config.prepareContactOutboundText?.call(contact, message.text) ??
            message.text;
    final width = config.pathHashByteWidth?.call() ?? contact.pathHashSize;
    if (!isContactEchoObservable(outboundText, width,
        attempt: _wireAttempts[messageId] ?? message.retryCount)) {
      return;
    }
    final textBytes = utf8.encode(outboundText).length;
    final waitMs = TimeoutHelper.echoWaitMs(
        airtime(txtMsgPacketBytes(textBytes, hops: width)), attemptTimeoutMs);
    _echoWaitMs[messageId] = waitMs;
    _echoObservable.add(messageId);
    _echoTimers[messageId]?.cancel();
    _echoTimers[messageId] =
        Timer(Duration(milliseconds: waitMs), () => _park(messageId));
  }

  /// The raw RX log showed a repeater's copy of a flooded DM of mine to
  /// the contact whose first key byte is [destByte]: somebody heard me.
  void noteOwnFloodEcho(int destByte) {
    for (final id in _echoTimers.keys.toList()) {
      final key = _pendingContacts[id]?.publicKey;
      if (key == null || key.isEmpty || key[0] != destByte) continue;
      _echoHeard.add(id);
      _echoTimers.remove(id)?.cancel();
    }
  }

  void _park(String messageId) {
    _echoTimers.remove(messageId);
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final config = _config;
    if (message == null || contact == null || config == null) return;
    // Not on this attempt any more, or settled: its own timer runs.
    if (message.status != MessageStatus.sent ||
        _resolvedMessages.contains(messageId)) {
      return;
    }
    if (!repeaterHeardRecently) {
      // The ACK wait runs on, and the ladder after it.
      config.debugLogService?.warn(
        'No repeater heard "${_short(message.text)}" to ${contact.name} '
        'within ${((_echoWaitMs[messageId] ?? 0) / 1000).toStringAsFixed(0)} s, '
        'and none was heard in the last '
        '${repeaterHeardWindow.inMinutes} min — not waiting for one',
        tag: 'AckHash',
      );
      return;
    }
    // A repeater was heard within the last minute, so one is in range: the
    // flood most likely met another transmission. The same packet goes
    // out again now, with nothing shown: a repeater that did pass the
    // first on drops it, so the mesh never carries the flood twice (owner,
    // 2026-11-24: 30 s parked beside a repeater 30 m away).
    final heardAt = _repeaterHeardAt;
    final quick = _quickResends[messageId] ?? 0;
    if (heardAt != null &&
        quick < maxQuickResends &&
        // Parked before, it keeps the pace of a parked message.
        !_autoResends.containsKey(messageId) &&
        !_now().difference(heardAt).isNegative &&
        _now().difference(heardAt) < quickResendWindow) {
      _quickResends[messageId] = quick + 1;
      config.debugLogService?.info(
        'No repeater passed on "${_short(message.text)}" to ${contact.name} '
        'within ${((_echoWaitMs[messageId] ?? 0) / 1000).toStringAsFixed(0)} s, '
        'but one was heard ${_now().difference(heardAt).inSeconds} s ago: '
        'sending the same packet again (${quick + 1}/$maxQuickResends)',
        tag: 'AckHash',
      );
      _send(messageId, same: true);
      return;
    }
    // The ACK wait is cancelled, not the ACK itself: a copy I failed to
    // hear can still be delivered, and its ACK flips the message as usual.
    _timeoutTimers.remove(messageId)?.cancel();
    final parked = message.copyWith(waitingForRepeater: true);
    _pendingMessages[messageId] = parked;
    _parkedReady[messageId] = false;
    final cooldown = math.max(_echoWaitMs[messageId] ?? 0, repeaterCooldownMs);
    _cooldownTimers[messageId]?.cancel();
    _cooldownTimers[messageId] = Timer(Duration(milliseconds: cooldown), () {
      _cooldownTimers.remove(messageId);
      if (_parkedReady.containsKey(messageId)) _parkedReady[messageId] = true;
    });
    _parkLimitTimers[messageId]?.cancel();
    _parkLimitTimers[messageId] =
        Timer(parkLimit, () => _parkLimitReached(messageId));
    final shortText = message.text.length > 20
        ? '${message.text.substring(0, 20)}...'
        : message.text;
    config.debugLogService?.warn(
      'No repeater heard "$shortText" to ${contact.name} within '
      '${((_echoWaitMs[messageId] ?? 0) / 1000).toStringAsFixed(0)} s — '
      'waiting for one to be in range',
      tag: 'AckHash',
    );
    config.updateMessage(parked);
    notifyListeners();
    // A flood nobody echoed is a flood that ended without delivery for
    // now: Pathfinder may answer it with one Discover, whose answers are
    // repeater transmissions that resume the parked message.
    config.onFloodAttemptEnded?.call(contact, delivered: false);
  }

  /// No repeater came into range in [parkLimit]: the parked message fails.
  /// A late ACK still delivers it within [lateAckGrace].
  void _parkLimitReached(String messageId) {
    _parkLimitTimers.remove(messageId);
    if (_parkedReady.remove(messageId) == null) return;
    _cooldownTimers.remove(messageId)?.cancel();
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    if (message == null ||
        contact == null ||
        _resolvedMessages.contains(messageId)) {
      return;
    }
    _config?.debugLogService?.warn(
      'No repeater in range for ${parkLimit.inMinutes} min: '
      '"${_short(message.text)}" to ${contact.name} failed',
      tag: 'AckHash',
    );
    _fail(messageId, message, contact);
  }

  /// A repeater's transmission reached this radio: every parked message
  /// past its cooldown is sent again on the same rung (up to
  /// [maxAutoResends] times), then its ladder moves on.
  void noteRepeaterHeard() {
    _repeaterHeardAt = _now();
    for (final id in _parkedReady.keys.toList()) {
      final message = _pendingMessages[id];
      final contact = _pendingContacts[id];
      if (message == null || contact == null) {
        _parkedReady.remove(id);
        _cooldownTimers.remove(id)?.cancel();
        _parkLimitTimers.remove(id)?.cancel();
        continue;
      }
      if (_parkedReady[id] != true) continue;
      _parkedReady.remove(id);
      _parkLimitTimers.remove(id)?.cancel();
      final resumed = message.copyWith(
          status: MessageStatus.pending, waitingForRepeater: false);
      _pendingMessages[id] = resumed;
      _config?.updateMessage(resumed);
      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      final n = _autoResends[id] ?? 0;
      if (n < maxAutoResends) {
        _autoResends[id] = n + 1;
        _config?.debugLogService?.info(
          'A repeater is in range: sending "$shortText" to ${contact.name} '
          'again (${n + 1}/$maxAutoResends)',
          tag: 'AckHash',
        );
        _send(id, resend: true);
      } else {
        _handleTimeout(id);
      }
    }
  }

  bool get hasPendingMessages => _pendingMessages.isNotEmpty;

  /// A message is queued, on the air, awaiting its ACK, or parked for a
  /// repeater to come into range: something still wants to be sent.
  bool get hasMessagesWaiting => _pendingMessages.values.any((m) =>
      m.status == MessageStatus.pending || m.status == MessageStatus.sent);

  /// A message is queued, on the air or awaiting its ACK. Failed messages
  /// kept for a late ACK do not count.
  /// A parked message is not in flight: nothing is on the air for it.
  bool get hasMessagesInFlight => _pendingMessages.values.any(
        (m) =>
            !m.waitingForRepeater &&
            (m.status == MessageStatus.pending ||
                m.status == MessageStatus.sent),
      );

  /// Update the stored contact snapshot for all pending messages to this
  /// contact. Call this when the contact's route choice changes so the
  /// attempts still to come follow it: the firmware ladder reads the live
  /// contact at each attempt, and Pathfinder's ladder is re-planned from
  /// the next attempt on (an override hands it to the firmware ladder).
  void updatePendingContact(Contact contact) {
    final keys = _pendingContacts.entries
        .where((e) => e.value.publicKeyHex == contact.publicKeyHex)
        .map((e) => e.key)
        .toList();
    for (final key in keys) {
      _pendingContacts[key] = contact;
      final message = _pendingMessages[key];
      if (message == null || _resolvedMessages.contains(key)) continue;
      final started = _activeMessages.contains(key);
      _plan(key, contact, keep: started ? message.retryCount + 1 : 0);
    }
  }

  void _startTimeoutTimer(String messageId, int timeoutMs) {
    _timeoutTimers[messageId]?.cancel();
    _timeoutTimers[messageId] = Timer(Duration(milliseconds: timeoutMs), () {
      _handleTimeout(messageId);
    });
  }

  /// A direct attempt that went on the air timed out: tell the graph now,
  /// not at the message's end, so the rungs still to come can be planned
  /// around it (field 2026-10-17: rungs 2 and 3 repeated rung 1's stale
  /// first hop). A late ACK still reports it delivered; the graph then
  /// sees one failure and one delivery on that route.
  void _reportTimedOut(String messageId, int attempt) {
    final report = _config?.onAttemptResult;
    final contact = _pendingContacts[messageId];
    final selection = _attemptRoutes[messageId]?[attempt];
    if (report == null || contact == null || selection == null) return;
    if (selection.useFlood || !(_onAir[messageId]?.contains(attempt) ?? false)) {
      return;
    }
    if (!(_reported[messageId] ??= {}).add(attempt)) return;
    final heard = _heardFor(messageId, attempt, delivered: false);
    if (!heard.skip) report(contact, selection, false, null, heard.hops);
  }

  /// Tells the graph how each direct attempt ended, once: the acked one
  /// delivered, those that went on the air and timed out before it
  /// failed (unless already reported at their timeout). An attempt still
  /// on the air when an earlier one is acked is left unjudged, and one the
  /// radio never accepted (a dropped link) says nothing about its route.
  void _reportAttempts(String messageId,
      {int? ackedAttempt, int? tripTimeMs, Set<int> unjudged = const {}}) {
    final report = _config?.onAttemptResult;
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final routes = _attemptRoutes[messageId];
    if (report == null || message == null || contact == null || routes == null) {
      return;
    }
    final onAir = _onAir[messageId] ?? const <int>{};
    final reported = _reported[messageId] ?? const <int>{};
    final timedOut = message.status == MessageStatus.failed
        ? message.retryCount + 1
        : message.retryCount;
    for (final MapEntry(key: i, value: selection) in routes.entries) {
      if (selection.useFlood || unjudged.contains(i)) continue;
      if (i == ackedAttempt) {
        report(contact, selection, true, tripTimeMs,
            _heardFor(messageId, i, delivered: true).hops);
      } else if (i < timedOut && onAir.contains(i) && !reported.contains(i)) {
        final heard = _heardFor(messageId, i, delivered: false);
        if (!heard.skip) report(contact, selection, false, null, heard.hops);
      }
    }
  }

  void _cleanupMessage(String messageId) {
    _moveAckHashesToHistory(messageId);
    _ackHashToMessageId.removeWhere((hash, mapping) {
      if (mapping.messageId != messageId) return false;
      _sendsByAck.remove(hash);
      return true;
    });
    _expectedHashToMessageId.removeWhere((_, msgId) => msgId == messageId);
    _sentWithoutHash.remove(messageId);
    _pendingMessages.remove(messageId);
    _pendingContacts.remove(messageId);
    _plans.remove(messageId);
    _pathfinderLadders.remove(messageId);
    _floodFirst.remove(messageId);
    _nearMaxText.remove(messageId);
    _attemptRoutes.remove(messageId);
    _onAir.remove(messageId);
    _reported.remove(messageId);
    _passedOn.remove(messageId);
    _passOnTimers.remove(messageId)?.cancel();
    _secondCopy.remove(messageId);
    _echoTimers.remove(messageId)?.cancel();
    _echoWaitMs.remove(messageId);
    _echoObservable.remove(messageId);
    _echoHeard.remove(messageId);
    _parkedReady.remove(messageId);
    _cooldownTimers.remove(messageId)?.cancel();
    _parkLimitTimers.remove(messageId)?.cancel();
    _autoResends.remove(messageId);
    _quickResends.remove(messageId);
    _resendAttempts.remove(messageId);
    _wireAttempts.remove(messageId);
    _wireRungs.remove(messageId);
    _timeoutTimers.remove(messageId);
    _resolvedMessages.remove(messageId);
  }

  void _handleTimeout(String messageId) {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final config = _config;

    if (message == null || contact == null) {
      debugPrint(
        'Timeout fired but message $messageId no longer pending (likely already delivered)',
      );
      return;
    }

    final shortText = message.text.length > 20
        ? '${message.text.substring(0, 20)}...'
        : message.text;
    config?.debugLogService?.warn(
      'Timeout: No ACK received for "$shortText" to ${contact.name} (attempt ${message.retryCount}) → retrying',
      tag: 'AckHash',
    );

    _passOnTimers.remove(messageId)?.cancel();
    _reportTimedOut(messageId, message.retryCount);
    final timedOut = _attemptRoutes[messageId]?[message.retryCount];
    if (timedOut != null &&
        timedOut.useFlood &&
        (_onAir[messageId]?.contains(message.retryCount) ?? false)) {
      config?.onFloodAttemptEnded?.call(contact, delivered: false);
    }

    if (message.retryCount < _attemptBudget(messageId) - 1) {
      const backoffMs = retryBackoffMs;

      final updatedMessage = message.copyWith(
        retryCount: message.retryCount + 1,
        status: MessageStatus.pending,
        waitingForRepeater: false,
      );

      _pendingMessages[messageId] = updatedMessage;
      config?.updateMessage(updatedMessage);
      // The failure just reported may have changed Pathfinder's ranking
      // (a doorstep held, a corridor marked down): re-plan the rungs still
      // to come instead of repeating this one's mistake.
      _plan(messageId, contact, keep: updatedMessage.retryCount);

      config?.debugLogService?.info(
        'Scheduling retry for "$shortText" to ${contact.name} after ${backoffMs}ms backoff',
        tag: 'AckHash',
      );

      _timeoutTimers[messageId] = Timer(Duration(milliseconds: backoffMs), () {
        final waiting = _pendingMessages[messageId];
        final to = _pendingContacts[messageId];
        if (waiting == null || to == null) return;
        // What the wait brought counts too: a Discover's answers, a
        // repeater heard passing the last attempt on after all.
        _plan(messageId, to, keep: waiting.retryCount);
        _send(messageId);
      });
    } else {
      _fail(messageId, message, contact);
    }
  }

  /// The ladder is over without an ACK: max retries reached, the park
  /// limit, or a send that threw ([clearRoute] false: nothing to clear
  /// over a link that just failed a write).
  void _fail(String messageId, Message message, Contact contact,
      {bool clearRoute = true}) {
    final config = _config;
    final failedMessage = message.copyWith(
        status: MessageStatus.failed, waitingForRepeater: false);
    _pendingMessages[messageId] = failedMessage;

    if (clearRoute) config?.clearContactPath?.call(contact);

    config?.updateMessage(failedMessage);

    notifyListeners();

    _onMessageResolved(messageId, contact.publicKeyHex, delivered: false);

    // Keep the message matchable so a late ACK from any attempt still
    // flips it to delivered; the firmware holds 8 expected ACKs itself.
    _timeoutTimers[messageId]?.cancel();
    _timeoutTimers[messageId] = Timer(lateAckGrace, () {
      _reportAttempts(messageId);
      _cleanupMessage(messageId);
    });
  }

  void _moveAckHashesToHistory(String messageId) {
    final ackHashes = _expectedAckHashes.remove(messageId);
    if (ackHashes != null && ackHashes.isNotEmpty) {
      _ackHistory.add(
        _AckHistoryEntry(
          messageId: messageId,
          ackHashes: ackHashes,
          timestamp: DateTime.now(),
        ),
      );

      while (_ackHistory.length > maxAckHistorySize) {
        _ackHistory.removeAt(0);
      }
    }
  }

  bool _checkAckHistory(int ackHash) {
    for (final entry in _ackHistory) {
      for (final expectedHash in entry.ackHashes) {
        if (expectedHash == ackHash) {
          return true;
        }
      }
    }
    return false;
  }

  /// How long ago the attempt [ackHash] belongs to went out, while its DM
  /// still waits for an ACK; null when nothing waits for that hash.
  Duration? waitingForAck(int ackHash) {
    final mapping = _ackHashToMessageId[ackHash.toRadixString(16).padLeft(8, '0')];
    if (mapping == null || !_pendingMessages.containsKey(mapping.messageId)) {
      return null;
    }
    return DateTime.now().difference(mapping.timestamp);
  }

  /// Which rung of [sends], the sends sharing one ACK code, an ACK was for,
  /// from what the app saw of it: a path reply answers a flooded copy, a
  /// plain or MULTIPART ACK a routed one (BaseChatMesh::onPeerDataRecv);
  /// and the byte the receiver copies from the DM's tail is the attempt
  /// number above 3, 0 at or below, except for a [_blindAttemptByte] send,
  /// which any byte fits. Null while more than one rung fits.
  static int? _rungAcked(
      List<({int rung, int wire, bool flood, bool blind})> sends,
      {bool? viaPathReply, int? wireAttempt}) {
    var fit = sends;
    if (viaPathReply != null) {
      fit = [for (final s in fit) if (s.flood == viaPathReply) s];
    }
    if (wireAttempt != null && {for (final s in fit) s.rung}.length > 1) {
      fit = [
        for (final s in fit)
          if (s.blind ||
              (wireAttempt > 3 ? s.wire == wireAttempt : s.wire <= 3))
            s,
      ];
    }
    final rungs = {for (final s in fit) s.rung};
    return rungs.length == 1 ? rungs.single : null;
  }

  /// [viaPathReply] and [wireAttempt]: what the app saw of the ACK on the
  /// air (a HeardAck), when it saw it.
  void handleAckReceived(int ackHash, int tripTimeMs,
      {bool? viaPathReply, int? wireAttempt}) {
    final config = _config;
    String? matchedMessageId;
    int? matchedAttemptIndex;
    int? matchedPathLength;
    // Rungs the ACK may be for, when it can't be told which: none of them
    // proves or fails its route.
    var unjudged = const <int>{};
    final ackHashHex = ackHash.toRadixString(16).padLeft(8, '0');

    // Clean up old ACK hash mappings (older than 15 minutes)
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 15));
    final hashesToRemove = <String>[];
    for (var entry in _ackHashToMessageId.entries) {
      if (entry.value.timestamp.isBefore(cutoffTime)) {
        hashesToRemove.add(entry.key);
      }
    }
    for (var hash in hashesToRemove) {
      _ackHashToMessageId.remove(hash);
      _sendsByAck.remove(hash);
    }

    // Use direct O(1) lookup via ACK hash mapping
    final mapping = _ackHashToMessageId[ackHashHex];
    if (mapping != null) {
      matchedMessageId = mapping.messageId;
      matchedAttemptIndex = mapping.attemptIndex;
      matchedPathLength = mapping.pathLength;
      final sends = _sendsByAck[ackHashHex];
      final rungs = <int>{...?sends?.map((s) => s.rung)};
      if (rungs.length > 1) {
        final rung = _rungAcked(sends!,
            viaPathReply: viaPathReply, wireAttempt: wireAttempt);
        if (rung != null) {
          matchedAttemptIndex = rung;
        } else {
          unjudged = rungs;
        }
        config?.debugLogService?.info(
          'ACK hash $ackHashHex stands for attempts '
          '${rungs.map((r) => r + 1).join(" and ")}: '
          '${rung == null ? "can't tell which, no route credited" : "it was attempt ${rung + 1}"}',
          tag: 'AckHash',
        );
      }
    } else {
      config?.debugLogService?.warn(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex not found in direct mapping, trying fallback',
        tag: 'AckHash',
      );
      // Fallback: Check against ALL expected ACK hashes (from all retry attempts)
      for (var entry in _expectedAckHashes.entries) {
        final messageId = entry.key;
        final expectedHashes = entry.value;

        for (final expectedHash in expectedHashes) {
          if (expectedHash == ackHash) {
            matchedMessageId = messageId;
            matchedAttemptIndex = expectedHashes.indexOf(expectedHash);
            break;
          }
        }

        if (matchedMessageId != null) break;
      }
    }

    if (matchedMessageId != null) {
      final message = _pendingMessages[matchedMessageId];
      if (message == null) {
        _ackHashToMessageId.remove(ackHashHex);
        _sendsByAck.remove(ackHashHex);
        return;
      }
      final contact = _pendingContacts[matchedMessageId];
      final ackedAttempt = matchedAttemptIndex ?? message.retryCount;
      if (contact != null) config?.onAckMatched?.call(contact, ackHash);

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      config?.debugLogService?.info(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex ✓ "$shortText" delivered to ${contact?.name ?? "unknown"} on attempt $ackedAttempt in ${tripTimeMs}ms',
        tag: 'AckHash',
      );

      _timeoutTimers[matchedMessageId]?.cancel();

      // Record the attempt that was actually acknowledged, not the one
      // that happened to be in flight — its route too, since a later
      // attempt may have overwritten the message's.
      final acked = _attemptRoutes[matchedMessageId]?[ackedAttempt];
      if (acked != null && acked.useFlood && contact != null &&
          unjudged.isEmpty) {
        config?.onFloodAttemptEnded?.call(contact, delivered: true);
      }
      final deliveredMessage = message.copyWith(
        status: MessageStatus.delivered,
        deliveredAt: DateTime.now(),
        tripTimeMs: tripTimeMs,
        retryCount: ackedAttempt,
        pathLength: acked == null
            ? (matchedPathLength ?? message.pathLength)
            : (acked.useFlood ? -1 : acked.hopCount),
        pathBytes:
            acked == null ? null : Uint8List.fromList(acked.pathBytes),
        pathHashSize: acked?.hashSize,
        routeSource: acked?.source ?? RouteSource.firmware,
        deliveredLate: message.status == MessageStatus.failed,
        waitingForRepeater: false,
      );

      final wasAlreadyResolved = _resolvedMessages.contains(matchedMessageId);

      _reportAttempts(matchedMessageId,
          ackedAttempt: unjudged.isEmpty ? ackedAttempt : null,
          tripTimeMs: tripTimeMs,
          unjudged: unjudged);
      _cleanupMessage(matchedMessageId);

      config?.updateMessage(deliveredMessage);

      if (contact != null && !wasAlreadyResolved) {
        _onMessageResolved(matchedMessageId, contact.publicKeyHex,
            delivered: true);
      }

      // After the queue has moved on, so the listener can tell whether
      // another send is already in flight.
      if (contact != null && deliveredMessage.pathLength == -1) {
        config?.onFloodDelivered?.call(contact);
      }

      notifyListeners();
    } else {
      if (_checkAckHistory(ackHash)) {
        config?.debugLogService?.info(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex matched a recently completed message (duplicate ACK)',
          tag: 'AckHash',
        );
      } else {
        config?.debugLogService?.error(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex has no matching message!',
          tag: 'AckHash',
        );
        debugPrint('No matching message found for ACK: $ackHashHex');
      }
    }
  }

  String? getContactKeyForAckHash(int ackHash) {
    for (var entry in _pendingMessages.entries) {
      final message = entry.value;
      if (message.expectedAckHash != null &&
          message.expectedAckHash == ackHash) {
        final contact = _pendingContacts[entry.key];
        return contact?.publicKeyHex;
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (var timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    _pendingMessages.clear();
    _pendingContacts.clear();
    _plans.clear();
    _pathfinderLadders.clear();
    _floodFirst.clear();
    _nearMaxText.clear();
    _attemptRoutes.clear();
    _onAir.clear();
    _reported.clear();
    for (final timer in _passOnTimers.values) {
      timer.cancel();
    }
    _passOnTimers.clear();
    _passedOn.clear();
    _secondCopy.clear();
    for (final timer in _echoTimers.values) {
      timer.cancel();
    }
    for (final timer in _cooldownTimers.values) {
      timer.cancel();
    }
    for (final timer in _parkLimitTimers.values) {
      timer.cancel();
    }
    _parkLimitTimers.clear();
    _echoTimers.clear();
    _echoWaitMs.clear();
    _parkedReady.clear();
    _cooldownTimers.clear();
    _autoResends.clear();
    _quickResends.clear();
    _resendAttempts.clear();
    _wireAttempts.clear();
    _wireRungs.clear();
    _expectedAckHashes.clear();
    _ackHistory.clear();
    _ackHashToMessageId.clear();
    _sendsByAck.clear();
    _sendQueue.clear();
    _activeMessages.clear();
    _resolvedMessages.clear();
    _sentWithoutHash.clear();
    super.dispose();
  }
}
