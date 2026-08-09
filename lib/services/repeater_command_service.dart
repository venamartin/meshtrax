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

  /// What a first attempt is allowed before it is retried.
  ///
  /// A repeater on a working link answers in about a second: the firmware
  /// waits CLI_REPLY_DELAY_MILLIS (600 ms, simple_repeater/MyMesh.cpp:59)
  /// before it even transmits, and the rest is airtime. Measured against
  /// F857 over a direct link, 100+ round trips landed between 954 and
  /// 1009 ms.
  ///
  /// The connector's [calculateTimeout] returns a worst case for a busy
  /// multi-hop path; tripling it and flooring at 8 s produced give-up points
  /// of 12.4 s direct and 28.6 s flood against that 1 s reality, so a single
  /// missing packet cost half a minute and three of them cost 86 s.
  static const int firstAttemptTimeoutMs = 3000;

  RepeaterCommandService(this._connector);

  /// Early attempts are sized for a link that is working; the final attempt
  /// keeps the full conservative budget so a genuinely slow multi-hop path
  /// still completes — it just is not the first thing the user waits for.
  ///
  /// About 5% of commands get no reply even on a quiet band with the
  /// repeater in the same room, because a half-duplex radio is deaf while it
  /// forwards someone else's traffic. Retrying is the only cure, so the cost
  /// of one retry is what matters.
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
    return math.min(ceiling, firstAttemptTimeoutMs * (1 << attempt));
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

    try {
      final prefix = _nextPrefixToken();
      _commandPrefixes[commandId] = prefix;
      _pendingByPrefix[prefix] = commandId;
      final framedCommand = '$prefix$command';
      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
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
      final responseBytes = frame.length > maxFrameSize
          ? frame.length
          : maxFrameSize;
      final baseTimeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
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
      return await completer.future;
    } finally {
      _cleanup(commandId);
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
