import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import 'dart:math' as math;

class RepeaterCommandService {
  final MeshCoreConnector _connector;
  final Map<String, Completer<String>> _pendingCommands = {};
  final Map<String, Timer> _commandTimeouts = {};
  final Map<String, String> _commandPrefixes = {};
  final Map<String, String> _pendingByPrefix = {};
  int _prefixCounter = 0;

  static const int maxRetries = 5;

  /// Floor for an early attempt, not a target.
  ///
  /// The repeater waits CLI_REPLY_DELAY_MILLIS (600 ms,
  /// simple_repeater/MyMesh.cpp:59) before it even transmits its reply, so a
  /// budget much under this cannot succeed on any path and would only add a
  /// duplicate transmission.
  static const int minAttemptTimeoutMs = 3000;

  RepeaterCommandService(this._connector);

  /// Every attempt scales with the path, and the last attempt keeps the full
  /// conservative budget so a genuinely slow multi-hop path still completes.
  ///
  /// [baseTimeoutMs] already carries the hop count — the connector's physics
  /// bound is `500 + (airtime*6 + 250) * (hops+1)`, so on the bench radios it
  /// runs 4.1 s direct, 7.8 s at one hop, 15.0 s at three, 9.5 s flood.
  /// Scaling attempts by it keeps a distant repeater's first attempt long
  /// enough to succeed, which a flat constant did not: 3 s would have expired
  /// on nearly every 3-hop command and put a duplicate on the mesh before the
  /// real reply arrived.
  ///
  /// About 5% of commands get no reply even on a quiet band with the repeater
  /// in the same room, because a half-duplex radio is deaf while it forwards
  /// someone else's traffic. Retrying is the only cure, so what matters is
  /// the cost of one retry — previously `max(8000, base*3)` on every attempt,
  /// i.e. 12.4 s direct and 28.6 s flood against a measured 955 ms round trip.
  ///
  /// Only safe because [handleResponse] discards a reply whose token no
  /// longer matches a pending command. Without that, shortening the timeout
  /// would turn every late reply into an answer for the next command.
  @visibleForTesting
  static int attemptTimeoutMs(
    int baseTimeoutMs,
    int attempt,
    int attemptCount,
  ) {
    final ceiling = math.max(8000, baseTimeoutMs * 3);
    if (attempt >= attemptCount - 1) return ceiling;
    final scaled = baseTimeoutMs * (attempt + 1);
    return math.min(ceiling, math.max(minAttemptTimeoutMs, scaled));
  }

  /// Send a CLI command to a repeater with automatic retries
  /// Returns a future that completes when a response is received or after max retries
  /// Resolves the send path once for a batch of commands. Each
  /// [sendCommand] otherwise re-derives it, and that writes a contact-path
  /// frame to the radio (plus a settle delay) every single time — for a
  /// ten-command save, ten pushes of a path that never changed.
  Future<PathSelection> preparePath(Contact repeater) =>
      _connector.preparePathForContactSend(repeater);

  /// Pass [selection] from [preparePath] when sending several commands in
  /// a row; omit it for one-offs and the path is resolved per call.
  Future<String> sendCommand(
    Contact repeater,
    String command, {
    Function(String)? onResponse,
    Function(int)? onAttempt,
    int retries = maxRetries,
    PathSelection? selection,
  }) async {
    final repeaterKey = repeater.publicKeyHex;
    final hasPending = _pendingCommands.keys.any(
      (id) => id.startsWith(repeaterKey),
    );
    if (hasPending) {
      throw Exception('Another command is still awaiting a response.');
    }

    final attemptCount = retries < 1 ? 1 : retries;
    final resolved =
        selection ?? await _connector.preparePathForContactSend(repeater);

    for (int attempt = 0; attempt < attemptCount; attempt++) {
      onAttempt?.call(attempt + 1);
      try {
        final response = await _sendCommandAttempt(
          repeater,
          command,
          resolved,
          attempt,
          attemptCount,
        );
        onResponse?.call(response);
        return response;
      } catch (e) {
        if (attempt == attemptCount - 1) rethrow;
      }
    }

    throw Exception('Command failed after $attemptCount attempts');
  }

  Future<String> _sendCommandAttempt(
    Contact repeater,
    String command,
    PathSelection selection,
    int attempt,
    int attemptCount,
  ) async {
    final repeaterKey = repeater.publicKeyHex;
    final commandId = '${repeaterKey}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<String>();
    _pendingCommands[commandId] = completer;

    // Kept for the round-trip observation below, which needs the same
    // features the prediction was made from.
    final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
    var responseBytes = maxFrameSize;
    final sentAt = DateTime.now();

    try {
      final prefix = _nextPrefixToken();
      _commandPrefixes[commandId] = prefix;
      _pendingByPrefix[prefix] = commandId;
      final framedCommand = '$prefix$command';
      final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _connector.trackRepeaterAck(
        contact: repeater,
        selection: selection,
        text: framedCommand,
        timestampSeconds: timestampSeconds,
        attempt: attempt,
      );
      final frame = buildSendCliCommandFrame(
        repeater.publicKey,
        framedCommand,
        attempt: attempt,
        timestampSeconds: timestampSeconds,
      );
      responseBytes = frame.length > maxFrameSize ? frame.length : maxFrameSize;
      // contactKey lets the model blend in what THIS repeater actually costs
      // once it has enough round trips; without it every repeater is budgeted
      // from the worst-case physics bound forever.
      final baseTimeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
        contactKey: repeaterKey,
      );
      final timeoutMs = attemptTimeoutMs(baseTimeoutMs, attempt, attemptCount);
      final timeoutSeconds = (timeoutMs / 1000).ceil();
      await _connector.sendFrame(frame);
      _commandTimeouts[commandId]?.cancel();
      _commandTimeouts[commandId] = Timer(
        Duration(milliseconds: timeoutMs),
        () {
          final completer = _pendingCommands[commandId];
          if (completer != null && !completer.isCompleted) {
            completer.completeError(
              'Command timeout after $timeoutSeconds seconds',
            );
            _cleanup(commandId);
          }
        },
      );
    } catch (e) {
      _cleanup(commandId);
      throw Exception('Failed to send command: $e');
    }

    try {
      final response = await completer.future;
      // The only place a repeater round trip can be observed. The firmware
      // does not ack TXT_TYPE_CLI_DATA and _handleMessageSent returns early
      // for CLI sends, so _handleRepeaterCommandAck — which trains the model
      // for ordinary messages — never fires for these commands.
      _connector.recordRepeaterCommandRoundTrip(
        contactKey: repeaterKey,
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
        tripTimeMs: DateTime.now().difference(sentAt).inMilliseconds,
      );
      return response;
    } finally {
      _cleanup(commandId);
    }
  }

  /// Attempts for a binary request (status / telemetry / neighbors). One
  /// fewer than [maxRetries]: these are user-watched screens where 3 slow
  /// attempts already take ~15 s, and the per-request cost of a retry is a
  /// whole packet, not a keystroke.
  static const int maxBinaryRequestAttempts = 3;

  /// Sends a CMD_SEND_BINARY_REQ (PAYLOAD_TYPE_REQ) to a repeater with the
  /// same retry-and-escalate treatment CLI commands get, and returns the
  /// response payload (everything after the reflected 4-byte tag).
  ///
  /// The screens used to send ONE frame and arm ONE timer, so ~5% baseline
  /// packet loss meant a red "timed out" banner — and their still-subscribed
  /// listeners then painted the screen green when the reply arrived anyway.
  /// Retrying is safe here in a way it never was for CLI text: the companion
  /// stamps every attempt with getCurrentTimeUnique() (a fresh tag, so the
  /// repeater's strict replay guard accepts it) and clearPendingReqs() makes
  /// it drop a late response to an earlier attempt, so cross-talk cannot
  /// happen at this layer.
  Future<Uint8List> sendBinaryRequest(
    Contact repeater,
    Uint8List requestPayload, {
    int retries = maxBinaryRequestAttempts,
    void Function(int attempt)? onAttempt,
    PathSelection? selection,
  }) {
    return _requestWithRetries(
      repeater: repeater,
      buildFrame: () =>
          buildSendBinaryReq(repeater.publicKey, payload: requestPayload),
      match: (frame, tag) {
        if (frame[0] != pushCodeBinaryResponse || frame.length < 7) {
          return null;
        }
        if (tag == null || !listEquals(frame.sublist(2, 6), tag)) return null;
        return Uint8List.fromList(frame.sublist(6));
      },
      retries: retries,
      onAttempt: onAttempt,
      selection: selection,
    );
  }

  /// Sends a CMD_SEND_STATUS_REQ and returns the full
  /// pushCodeStatusResponse frame (callers already parse that layout).
  /// Status responses carry the repeater's key prefix instead of a tag.
  Future<Uint8List> sendStatusRequest(
    Contact repeater, {
    int retries = maxBinaryRequestAttempts,
    void Function(int attempt)? onAttempt,
    PathSelection? selection,
  }) {
    return _requestWithRetries(
      repeater: repeater,
      buildFrame: () => buildSendStatusRequestFrame(repeater.publicKey),
      match: (frame, tag) {
        if (frame[0] != pushCodeStatusResponse || frame.length < 8) {
          return null;
        }
        if (!_prefixMatches(frame.sublist(2, 8), repeater.publicKey)) {
          return null;
        }
        return frame;
      },
      retries: retries,
      onAttempt: onAttempt,
      selection: selection,
    );
  }

  /// Telemetry: repeaters answer a binary request (tag-matched); chat
  /// contacts answer with pushCodeTelemetryResponse (prefix-matched).
  /// Returns the Cayenne LPP payload either way.
  Future<Uint8List> sendTelemetryRequest(
    Contact contact, {
    int retries = maxBinaryRequestAttempts,
    void Function(int attempt)? onAttempt,
    PathSelection? selection,
  }) {
    if (contact.type != advTypeChat) {
      return sendBinaryRequest(
        contact,
        Uint8List.fromList([reqTypeGetTelemetry]),
        retries: retries,
        onAttempt: onAttempt,
        selection: selection,
      );
    }
    return _requestWithRetries(
      repeater: contact,
      buildFrame: () => buildSendTelemetryReq(contact.publicKey),
      match: (frame, tag) {
        if (frame[0] != pushCodeTelemetryResponse || frame.length < 8) {
          return null;
        }
        if (!_prefixMatches(frame.sublist(2, 8), contact.publicKey)) {
          return null;
        }
        return Uint8List.fromList(frame.sublist(8));
      },
      retries: retries,
      onAttempt: onAttempt,
      selection: selection,
    );
  }

  static bool _prefixMatches(Uint8List prefix, Uint8List pubKey) {
    if (pubKey.length < 6 || prefix.length < 6) return false;
    for (var i = 0; i < 6; i++) {
      if (prefix[i] != pubKey[i]) return false;
    }
    return true;
  }

  Future<Uint8List> _requestWithRetries({
    required Contact repeater,
    required Uint8List Function() buildFrame,
    required Uint8List? Function(Uint8List frame, Uint8List? tag) match,
    required int retries,
    void Function(int attempt)? onAttempt,
    PathSelection? selection,
  }) async {
    final resolved =
        selection ?? await _connector.preparePathForContactSend(repeater);
    final attemptCount = retries < 1 ? 1 : retries;
    for (var attempt = 0; attempt < attemptCount; attempt++) {
      onAttempt?.call(attempt + 1);
      try {
        final response = await _requestAttempt(
          repeater: repeater,
          frame: buildFrame(),
          match: match,
          selection: resolved,
          attempt: attempt,
          attemptCount: attemptCount,
        );
        // Success trains the rotation stats too — these screens used to
        // record only failures, so they could only ever hurt a path's score.
        _connector.recordRepeaterPathResult(repeater, resolved, true, null);
        return response;
      } on TimeoutException {
        // fall through to the next attempt
      }
    }
    _connector.recordRepeaterPathResult(repeater, resolved, false, null);
    throw TimeoutException('No response after $attemptCount attempts');
  }

  Future<Uint8List> _requestAttempt({
    required Contact repeater,
    required Uint8List frame,
    required Uint8List? Function(Uint8List frame, Uint8List? tag) match,
    required PathSelection selection,
    required int attempt,
    required int attemptCount,
  }) async {
    final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
    // The RESPONSE dominates the round trip — a full neighbors reply is
    // ~150 bytes against a ~50-byte request — and the repeater holds it for
    // SERVER_RESPONSE_DELAY (300 ms) first. Budgeting a full frame keeps
    // the airtime estimate honest for the return leg.
    final messageBytes =
        frame.length > maxFrameSize ? frame.length : maxFrameSize;
    final baseTimeoutMs = _connector.calculateTimeout(
      pathLength: pathLengthValue,
      messageBytes: messageBytes,
      contactKey: repeater.publicKeyHex,
    );
    final timeoutMs = attemptTimeoutMs(baseTimeoutMs, attempt, attemptCount);

    final completer = Completer<Uint8List>();
    Uint8List? tag;
    final sub = _connector.receivedFrames.listen((f) {
      if (f.isEmpty) return;
      if (f[0] == respCodeSent && f.length >= 6) {
        // First SENT after our write is ours: the companion answers serial
        // commands in order.
        tag ??= Uint8List.fromList(f.sublist(2, 6));
        return;
      }
      final payload = match(f, tag);
      if (payload != null && !completer.isCompleted) {
        completer.complete(payload);
      }
    });
    final sentAt = DateTime.now();
    try {
      await _connector.sendFrame(frame);
      final response = await completer.future
          .timeout(Duration(milliseconds: timeoutMs));
      _connector.recordRepeaterCommandRoundTrip(
        contactKey: repeater.publicKeyHex,
        pathLength: pathLengthValue,
        messageBytes: messageBytes,
        tripTimeMs: DateTime.now().difference(sentAt).inMilliseconds,
      );
      return response;
    } finally {
      await sub.cancel();
    }
  }

  /// Call this when a text message response is received from a repeater
  void handleResponse(Contact repeater, String responseText) {
    // Find pending command for this repeater and complete it
    final repeaterKey = repeater.publicKeyHex;

    String? commandId;
    String responsePayload = responseText;
    if (responseText.length >= 3 && responseText[2] == '|') {
      // The repeater reflects the token it was sent back on the reply
      // (simple_repeater/MyMesh.cpp:1211), so a token matching nothing
      // pending belongs to an attempt this service has already given up on.
      //
      // It used to fall through to "complete whatever is pending for this
      // repeater", which meant a late reply always landed on the NEXT
      // command — and the settings screen refreshes in batches 200 ms
      // apart. Confirmed on hardware: the app asked "get tx" and was handed
      // "910.5250244,62.5,7,5", which it then stored as the TX power.
      final prefix = responseText.substring(0, 3);
      final match = _pendingByPrefix[prefix];
      if (match == null) return;
      commandId = match;
      responsePayload = responseText.substring(3).trimLeft();
    }

    // No token at all: firmware that does not reflect the prefix, so there
    // is nothing to match on and the single pending command is the only
    // possible owner.
    commandId ??= _pendingCommands.keys.firstWhere(
      (id) => id.startsWith(repeaterKey),
      orElse: () => '',
    );

    if (commandId.isEmpty) return;

    final completer = _pendingCommands[commandId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(responsePayload);
      _cleanup(commandId);
    }
  }

  void _cleanup(String commandId) {
    _commandTimeouts[commandId]?.cancel();
    _commandTimeouts.remove(commandId);
    _pendingCommands.remove(commandId);
    final prefix = _commandPrefixes.remove(commandId);
    if (prefix != null) {
      _pendingByPrefix.remove(prefix);
    }
  }

  void dispose() {
    for (final timer in _commandTimeouts.values) {
      timer.cancel();
    }
    _commandTimeouts.clear();
    _pendingCommands.clear();
    _commandPrefixes.clear();
    _pendingByPrefix.clear();
  }

  String _nextPrefixToken() {
    for (var i = 0; i < 256; i++) {
      final value = _prefixCounter++ & 0xFF;
      final token = '${value.toRadixString(16).padLeft(2, '0').toUpperCase()}|';
      if (!_pendingByPrefix.containsKey(token)) {
        return token;
      }
    }
    return '00|';
  }
}
