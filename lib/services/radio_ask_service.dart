import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/cayenne_lpp.dart';
import '../helpers/timeout_helper.dart';
import '../models/contact.dart';
import '../utils/app_logger.dart';
import 'repeater_command_service.dart';

/// What a person's radio said about itself.
class RadioAnswer {
  final DateTime receivedAt;

  /// Null when the answer carried no position: its GPS may be off.
  final ({double lat, double lon, double altitude})? position;
  final double? volts;
  final double? celsius;

  const RadioAnswer({
    required this.receivedAt,
    this.position,
    this.volts,
    this.celsius,
  });

  /// Reads the telemetry a companion radio answers with (Cayenne LPP).
  factory RadioAnswer.fromLpp(Uint8List lpp, DateTime at) {
    ({double lat, double lon, double altitude})? position;
    double? volts, celsius;
    for (final item in CayenneLpp.parse(lpp)) {
      final value = item['value'];
      switch (item['type']) {
        case CayenneLpp.lppGps when position == null && value is Map:
          position = (
            lat: (value['latitude'] as num).toDouble(),
            lon: (value['longitude'] as num).toDouble(),
            altitude: (value['altitude'] as num).toDouble(),
          );
        case CayenneLpp.lppVoltage when volts == null && value is num:
          volts = value.toDouble();
        case CayenneLpp.lppTemperature when celsius == null && value is num:
          celsius = value.toDouble();
      }
    }
    return RadioAnswer(
      receivedAt: at,
      // A radio with no fix and nothing stored sends 0, 0.
      position: position == null || (position.lat == 0 && position.lon == 0)
          ? null
          : position,
      volts: volts,
      celsius: celsius,
    );
  }
}

enum RadioAskPhase {
  /// Behind another ask: the radio keeps one telemetry request in flight.
  waiting,
  asking,

  /// Answered once; asking again about a minute later to see if it moves.
  checkingAgain,
  done,
  noAnswer,
}

/// One person's ask: up to two reads about a minute apart.
class RadioAsk {
  RadioAsk(this.contact, {this.previous});

  final Contact contact;

  /// The answer of the ask before this one, shown until this one answers.
  final RadioAnswer? previous;
  RadioAskPhase phase = RadioAskPhase.waiting;

  /// The try of the read under way, from 1.
  int attempt = 0;
  RadioAnswer? first;
  RadioAnswer? second;

  /// When the second read is due.
  DateTime? recheckAt;

  RadioAnswer? get latest => second ?? first ?? previous;

  /// A radio that had a live fix changes its reading within a minute; one
  /// that reads the same twice, or an altitude of exactly 0, is likely
  /// giving a stored position (bench, 2026-11-18: 0 of 169 one-minute pairs
  /// matched with a fix).
  bool get unchanged {
    final a = first?.position, b = second?.position;
    return a != null && b != null && a == b;
  }

  bool get noFix => latest?.position?.altitude == 0;
}

/// Asks a person's radio where it is, with the existing telemetry request:
/// companion firmware answers it by itself with its GPS position, so it
/// finds someone whose phone is dead, closed or locked. Their radio answers
/// only if it allows this one (telemetry by contact, or to everyone).
///
/// One ask at a time, as the radio keeps one telemetry request in flight;
/// a request it cleared is still answered, as a binary response with the
/// tag it was sent with. Answers are kept in memory only.
class RadioAskService extends ChangeNotifier {
  RadioAskService(
    this._connector, {
    bool Function()? repeaterHeardRecently,
    DateTime Function()? now,
    this.recheckAfter = const Duration(minutes: 1),
  }) : _repeaterHeardRecently = repeaterHeardRecently ?? (() => true),
       _now = now ?? DateTime.now;

  final MeshCoreConnector _connector;
  final bool Function() _repeaterHeardRecently;
  final DateTime Function() _now;
  final Duration recheckAfter;

  static const attempts = RepeaterCommandService.maxBinaryRequestAttempts;

  final _asks = <String, RadioAsk>{};
  final _queue = Queue<RadioAsk>();
  final _timers = <String, Timer>{};
  bool _running = false;
  bool _disposed = false;

  /// The ask for [contact], under way or done; null when never asked.
  RadioAsk? askFor(Contact contact) => _asks[contact.publicKeyHex];

  /// The asks whose latest answer gave a position.
  Iterable<RadioAsk> get located =>
      _asks.values.where((a) => a.latest?.position != null);

  /// The latest answer from [contact]'s radio, if it gave a position.
  RadioAnswer? positionOf(Contact contact) {
    final a = askFor(contact)?.latest;
    return a?.position == null ? null : a;
  }

  /// Asks [contact]'s radio, after any ask under way. Asking again while
  /// one is under way changes nothing.
  void ask(Contact contact) {
    final key = contact.publicKeyHex;
    final current = _asks[key];
    if (current != null &&
        current.phase != RadioAskPhase.done &&
        current.phase != RadioAskPhase.noAnswer) {
      return;
    }
    _timers.remove(key)?.cancel();
    final ask = RadioAsk(contact, previous: current?.latest);
    _asks[key] = ask;
    _queue.add(ask);
    notifyListeners();
    unawaited(_run());
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final ask = _queue.removeFirst();
        if (_asks[ask.contact.publicKeyHex] != ask) continue;
        await _read(ask);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _read(RadioAsk ask) async {
    final again = ask.first != null;
    ask.phase = again ? RadioAskPhase.checkingAgain : RadioAskPhase.asking;
    final answer = await _request(ask);
    if (_disposed) return;
    if (answer == null) {
      // A second read that got nothing leaves the first answer standing.
      ask.phase = again ? RadioAskPhase.done : RadioAskPhase.noAnswer;
    } else if (!again) {
      ask.first = answer;
      if (answer.position == null || answer.position!.altitude == 0) {
        ask.phase = RadioAskPhase.done;
      } else {
        ask.phase = RadioAskPhase.checkingAgain;
        ask.recheckAt = _now().add(recheckAfter);
        _timers[ask.contact.publicKeyHex] = Timer(recheckAfter, () {
          _timers.remove(ask.contact.publicKeyHex);
          if (_asks[ask.contact.publicKeyHex] != ask) return;
          _queue.add(ask);
          unawaited(_run());
        });
      }
    } else {
      ask.second = answer;
      ask.phase = RadioAskPhase.done;
    }
    ask.attempt = 0;
    notifyListeners();
  }

  /// One read: up to [attempts] tries. Where no repeater was heard lately
  /// every try floods; otherwise the request ladder, which ends in floods.
  Future<RadioAnswer?> _request(RadioAsk ask) async {
    final contact = ask.contact;
    if (!_connector.isConnected) return null;
    final plan = _connector.planRequestAttempts(
      contact,
      attempts,
      floodOnly: !_repeaterHeardRecently(),
    );
    final tags = <String>[];
    var awaitingTag = false;
    Completer<Uint8List> answered = Completer();
    final sub = _connector.receivedFrames.listen((f) {
      if (f.isEmpty || answered.isCompleted) return;
      if (f[0] == respCodeSent && f.length >= 6) {
        // The first SENT after a write is ours: the radio answers commands
        // in order.
        if (awaitingTag) {
          awaitingTag = false;
          tags.add(_hex(f.sublist(2, 6)));
        }
        return;
      }
      if (f[0] == pushCodeTelemetryResponse &&
          f.length >= 8 &&
          _prefixMatches(f.sublist(2, 8), contact.publicKey)) {
        answered.complete(Uint8List.fromList(f.sublist(8)));
      } else if (f[0] == pushCodeBinaryResponse &&
          f.length >= 6 &&
          tags.contains(_hex(f.sublist(2, 6)))) {
        answered.complete(Uint8List.fromList(f.sublist(6)));
      }
    });
    try {
      for (var i = 0; i < attempts; i++) {
        if (_disposed || !_connector.isConnected) return null;
        ask.attempt = i + 1;
        notifyListeners();
        final selection = plan[i < plan.length ? i : plan.length - 1];
        final timeoutMs = TimeoutHelper.attemptMs(
          _connector.calculateRoundTripTimeout(
            pathLength: selection.useFlood ? -1 : selection.hopCount,
            messageBytes: maxFrameSize,
            contact: contact,
          ),
          i,
          attempts,
        );
        try {
          awaitingTag = true;
          await _connector.sendOnRoute(
            contact,
            selection,
            () =>
                _connector.sendFrame(buildSendTelemetryReq(contact.publicKey)),
          );
          final lpp = await answered.future.timeout(
            Duration(milliseconds: timeoutMs),
          );
          return RadioAnswer.fromLpp(lpp, _now());
        } on TimeoutException {
          // the next try
        } catch (e) {
          appLogger.warn(
            'Asking ${contact.name}\'s radio: $e',
            tag: 'RadioAsk',
          );
          return null;
        }
      }
      return null;
    } finally {
      unawaited(sub.cancel());
    }
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static bool _prefixMatches(List<int> prefix, Uint8List key) {
    if (key.length < 6) return false;
    for (var i = 0; i < 6; i++) {
      if (prefix[i] != key[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
