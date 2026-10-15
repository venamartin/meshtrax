import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
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
  final String Function(Contact, String)? prepareContactOutboundText;
  // A message to this contact was just delivered by a flood attempt.
  final Function(Contact)? onFloodDelivered;
  // Pathfinder's ranked routes to a contact, best first; null while it is off.
  final List<PathSelection>? Function(Contact)? graphRoutes;
  // How one direct attempt ended: the route it went on, whether its ACK came.
  final void Function(Contact, PathSelection, bool delivered, int? tripTimeMs)?
      onAttemptResult;
  // An attempt is about to go out: Pathfinder gates my own echoes on it.
  final void Function(Contact, PathSelection, int attempt)? onAttemptStarted;
  // The radio confirmed an ACK for a message to this contact (uint32 hash).
  final void Function(Contact, int ackHash)? onAckMatched;
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
    this.prepareContactOutboundText,
    this.onFloodDelivered,
    this.graphRoutes,
    this.onAttemptResult,
    this.onAttemptStarted,
    this.onAckMatched,
    this.appSettingsService,
    this.debugLogService,
  });
}

/// Sends a contact message and retries it until an ACK arrives.
///
/// With Pathfinder able to route, the ladder is planned once per message
/// by [planAttempts]: Pathfinder's routes, best first, then floods; the
/// radio's stored route is never tried. Otherwise (Pathfinder off, a user
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
  // What each attempt actually went out on, and which attempts the radio
  // accepted (RESP_CODE_SENT): only those were on the air.
  final Map<String, Map<int, PathSelection>> _attemptRoutes = {};
  final Map<String, Set<int>> _onAir = {};
  final Map<String, AckHashMapping> _ackHashToMessageId = {};
  final Map<String, List<int>> _expectedAckHashes = {};
  final List<_AckHistoryEntry> _ackHistory = [];
  final Map<String, List<String>> _sendQueue = {};
  final Set<String> _activeMessages = {};
  final Set<String> _resolvedMessages = {};
  final Map<String, String> _expectedHashToMessageId = {};

  RetryServiceConfig? _config;

  int _radioWidth(Contact contact) =>
      _config?.pathHashByteWidth?.call() ?? contact.pathHashSize;

  MessageRetryService();

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
        _attemptSend(messageId).catchError((e) {
          debugPrint('_attemptSend threw for $messageId: $e');
          final msg = _pendingMessages[messageId];
          if (msg != null) {
            final failed = msg.copyWith(status: MessageStatus.failed);
            _pendingMessages[messageId] = failed;
            _config?.updateMessage(failed);
          }
          _onMessageResolved(messageId, contactKey);
        });
        return;
      }
    }
  }

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
    final fresh = planAttempts(contact,
        radioWidth: width,
        budget: old.isEmpty ? maxRetries : old.length,
        graphRoutes: routes);
    _plans[messageId] = [
      for (var i = 0; i < keep; i++)
        i < old.length
            ? old[i]
            : i < fresh.length
                ? fresh[i]
                : PathSelection.flood(width),
      ...fresh.skip(keep),
    ];
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
      : maxRetries;

  void _onMessageResolved(String messageId, String contactKey) {
    if (_resolvedMessages.contains(messageId)) return;
    _resolvedMessages.add(messageId);
    _activeMessages.remove(messageId);
    _sendNextForContact(contactKey);
  }

  Future<void> _attemptSend(String messageId) async {
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
    );

    final attempt = message.retryCount;
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
      _registerExpectedAck(messageId, message, contact, attempt, timestampSeconds);
      config.onAttemptStarted?.call(contact, selection, attempt);
      // Before the send, as always: its RESP_CODE_SENT replaces this timer
      // with the real one, and can arrive while the send is awaited.
      _startPreSentTimer(messageId);
      await config.sendMessage(contact, message.text, attempt, timestampSeconds);
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
    if (selfPubKey != null) {
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

  void _startPreSentTimer(String messageId) {
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
        if (_pendingMessages[messageId]?.status == MessageStatus.pending) {
          config?.debugLogService?.warn(
            'No RESP_CODE_SENT received within ${preSentTimeoutMs}ms for message $messageId — triggering retry',
            tag: 'AckHash',
          );
          _handleTimeout(messageId);
        }
      },
    );
  }

  bool updateMessageFromSent(int ackHash, int timeoutMs) {
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
        messageId = null;
        contact = null;
      }
    }

    if (messageId == null || contact == null) {
      // Hash lookup failed. This can happen when selfPubKey was null during
      // _attemptSend, so no hash was stored. Fall back to the oldest active
      // pending message so the timeout timer is always started and the message
      // never gets stuck at 'pending' forever.
      if (_activeMessages.isNotEmpty) {
        final fallbackId = _activeMessages.first;
        final fallbackMsg = _pendingMessages[fallbackId];
        final fallbackContact = _pendingContacts[fallbackId];
        if (fallbackMsg != null && fallbackContact != null &&
            fallbackMsg.status == MessageStatus.pending) {
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
    _ackHashToMessageId[ackHashHex] = (
      messageId: messageId,
      timestamp: DateTime.now(),
      attemptIndex: message.retryCount,
      pathLength: message.pathLength,
    );

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

    _startTimeoutTimer(messageId, actualTimeout);
    return true;
  }

  bool get hasPendingMessages => _pendingMessages.isNotEmpty;

  /// A message is queued, on the air or awaiting its ACK. Failed messages
  /// kept for a late ACK do not count.
  bool get hasMessagesInFlight => _pendingMessages.values.any(
        (m) =>
            m.status == MessageStatus.pending || m.status == MessageStatus.sent,
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

  /// Tells the graph how each direct attempt ended, once: the acked one
  /// delivered, those that went on the air and timed out before it
  /// failed. An attempt still on the air when an earlier one is acked is
  /// left unjudged, and one the radio never accepted (a dropped link) says
  /// nothing about its route.
  void _reportAttempts(String messageId,
      {int? ackedAttempt, int? tripTimeMs}) {
    final report = _config?.onAttemptResult;
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final routes = _attemptRoutes[messageId];
    if (report == null || message == null || contact == null || routes == null) {
      return;
    }
    final onAir = _onAir[messageId] ?? const <int>{};
    final timedOut = message.status == MessageStatus.failed
        ? message.retryCount + 1
        : message.retryCount;
    for (final MapEntry(key: i, value: selection) in routes.entries) {
      if (selection.useFlood) continue;
      if (i == ackedAttempt) {
        report(contact, selection, true, tripTimeMs);
      } else if (i < timedOut && onAir.contains(i)) {
        report(contact, selection, false, null);
      }
    }
  }

  void _cleanupMessage(String messageId) {
    _moveAckHashesToHistory(messageId);
    _ackHashToMessageId.removeWhere(
      (_, mapping) => mapping.messageId == messageId,
    );
    _expectedHashToMessageId.removeWhere((_, msgId) => msgId == messageId);
    _pendingMessages.remove(messageId);
    _pendingContacts.remove(messageId);
    _plans.remove(messageId);
    _pathfinderLadders.remove(messageId);
    _floodFirst.remove(messageId);
    _attemptRoutes.remove(messageId);
    _onAir.remove(messageId);
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

    if (message.retryCount < _attemptBudget(messageId) - 1) {
      const backoffMs = retryBackoffMs;

      final updatedMessage = message.copyWith(
        retryCount: message.retryCount + 1,
        status: MessageStatus.pending,
      );

      _pendingMessages[messageId] = updatedMessage;
      config?.updateMessage(updatedMessage);

      config?.debugLogService?.info(
        'Scheduling retry for "$shortText" to ${contact.name} after ${backoffMs}ms backoff',
        tag: 'AckHash',
      );

      _timeoutTimers[messageId] = Timer(Duration(milliseconds: backoffMs), () {
        if (_pendingMessages.containsKey(messageId)) {
          _attemptSend(messageId);
        }
      });
    } else {
      // Max retries reached - mark as failed
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      _pendingMessages[messageId] = failedMessage;

      config?.clearContactPath?.call(contact);

      config?.updateMessage(failedMessage);

      notifyListeners();

      _onMessageResolved(messageId, contact.publicKeyHex);

      // Keep the message matchable so a late ACK from any attempt still
      // flips it to delivered; the firmware holds 8 expected ACKs itself.
      _timeoutTimers[messageId] = Timer(lateAckGrace, () {
        _reportAttempts(messageId);
        _cleanupMessage(messageId);
      });
    }
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

  void handleAckReceived(int ackHash, int tripTimeMs) {
    final config = _config;
    String? matchedMessageId;
    int? matchedAttemptIndex;
    int? matchedPathLength;
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
    }

    // Use direct O(1) lookup via ACK hash mapping
    final mapping = _ackHashToMessageId[ackHashHex];
    if (mapping != null) {
      matchedMessageId = mapping.messageId;
      matchedAttemptIndex = mapping.attemptIndex;
      matchedPathLength = mapping.pathLength;
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
      );

      final wasAlreadyResolved = _resolvedMessages.contains(matchedMessageId);

      _reportAttempts(matchedMessageId,
          ackedAttempt: ackedAttempt, tripTimeMs: tripTimeMs);
      _cleanupMessage(matchedMessageId);

      config?.updateMessage(deliveredMessage);

      if (contact != null && !wasAlreadyResolved) {
        _onMessageResolved(matchedMessageId, contact.publicKeyHex);
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
    _attemptRoutes.clear();
    _onAir.clear();
    _expectedAckHashes.clear();
    _ackHistory.clear();
    _ackHashToMessageId.clear();
    _sendQueue.clear();
    _activeMessages.clear();
    _resolvedMessages.clear();
    super.dispose();
  }
}
