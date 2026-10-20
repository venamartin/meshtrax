import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';

enum CliReplyKind { value, ok, error, unknown }

/// A companion CLI reply. The firmware's wording is not uniform ("Error, …",
/// "ERROR: …", "Error: …"), so it is classified loosely.
class CliReply {
  CliReply(String reply) : text = reply.trim();

  final String text;

  CliReplyKind get kind {
    if (text == 'Unknown command') return CliReplyKind.unknown;
    if (text.toLowerCase().startsWith('error')) return CliReplyKind.error;
    if (text.startsWith('OK')) return CliReplyKind.ok;
    return CliReplyKind.value;
  }

  /// The value of a `get`: the text after "> ", or the whole reply for the
  /// commands ("ver", "board") that answer without the marker.
  String get value => text.startsWith('>') ? text.substring(1).trim() : text;
}

/// Runs text CLI commands on the connected radio (firmware 1.18+,
/// CMD_RUN_CLI_COMMAND). Each command carries an "XX|" token that the
/// firmware echoes back: a BLE+WiFi radio sends every reply to every
/// connected app, and the token is how ours is told apart.
class CompanionCliService {
  CompanionCliService(this._connector) : _counter = Random().nextInt(256);

  final MeshCoreConnector _connector;
  int _counter;
  Future<void> _tail = Future.value();

  static const Duration attemptTimeout = Duration(seconds: 3);

  /// Runs [command] and returns the reply without its token. One command at
  /// a time. A `get` is tried twice: the radio's send queue drops frames
  /// when it is busy, and reading again is harmless. The command is sent as
  /// given: "set wifi.pwd " with one trailing space sets an empty value.
  Future<String> run(String command) {
    final result = _tail.then((_) => _runWithRetry(command));
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// For the commands that never answer: reboot, poweroff, shutdown.
  Future<void> sendWithoutReply(String command) =>
      _connector.sendFrame(buildRunCliCommandFrame(command));

  Future<String> _runWithRetry(String command) async {
    // The firmware only strips a token from commands longer than 4 chars.
    if (command.length < 2) {
      throw ArgumentError.value(command, 'command', 'too short');
    }
    final attempts = command.startsWith('get ') ? 2 : 1;
    for (var attempt = 1; ; attempt++) {
      try {
        return await _runOnce(command);
      } on TimeoutException {
        if (attempt >= attempts) rethrow;
      }
    }
  }

  Future<String> _runOnce(String command) async {
    final token =
        '${(_counter++ & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()}|';
    final completer = Completer<String>();
    final sub = _connector.receivedFrames.listen((frame) {
      if (frame.isEmpty || frame[0] != respCodeCliReply) return;
      final text = utf8.decode(frame.sublist(1), allowMalformed: true);
      if (text.startsWith(token) && !completer.isCompleted) {
        completer.complete(text.substring(token.length));
      }
    });
    try {
      await _connector.sendFrame(buildRunCliCommandFrame('$token$command'));
      return await completer.future.timeout(attemptTimeout);
    } finally {
      unawaited(sub.cancel());
    }
  }
}
