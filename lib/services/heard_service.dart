import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:traxheard/traxheard.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

/// "Check sends with observers": while it is on, MeshTrax asks an observer
/// server about every channel message it sends, and one that an observer
/// heard isn't sent again. Who heard which message is kept for the grey
/// ear in the chat. The traxheard package does the asking.
///
/// While observers hear this radio, a message only one repeater carried
/// goes out once more, with a back-off (traxheard's README).
class HeardService extends ChangeNotifier {
  HeardService._();

  static HeardService instance = HeardService._();

  @visibleForTesting
  static void resetForTesting() {
    instance._checker.dispose();
    for (final timer in instance._missTimers.values) {
      timer.cancel();
    }
    instance = HeardService._();
  }

  static const _keyEnabled = 'heard_check_enabled';
  static const _keyServer = 'heard_check_server';
  static const _keyHeard = 'heard_check_heard';
  static const _keyLastEar = 'heard_check_last_ear';

  /// Messages whose observers are kept, newest last.
  static const _keptMessages = 300;

  /// A resend after one repeater needs an observer to have heard this
  /// radio this lately.
  static const proofWindow = Duration(hours: 2);

  /// Resends after one repeater that went unheard, in a row, before they
  /// stop until an observer hears this radio again.
  static const missesBeforeBackOff = 3;

  MeshCoreConnector? _connector;
  bool _enabled = false;
  String _server = '';
  ObserverServer? _observerServer;
  final _heard = <String, List<Sighting>>{};

  /// When an observer last heard a channel message of each radio, by its
  /// public key.
  final _lastEar = <String, DateTime>{};
  int _misses = 0;
  final _missTimers = <String, Timer>{};

  late final _checker = HeardChecker(
    server: () => _enabled ? _observerServer : null,
    onHeard: _onHeard,
    onError: (e) => appLogger.warn('Asking the observer server: $e', tag: 'Heard'),
  );

  bool get enabled => _enabled;

  /// The server's address as the user gave it; empty when there is none.
  String get server => _server;

  /// The observers that heard channel message [messageId], or null.
  List<Sighting>? heardBy(String messageId) => _heard[messageId];

  void attach(MeshCoreConnector connector) {
    _connector = connector;
    final prefs = PrefsManager.instance;
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _server = prefs.getString(_keyServer) ?? '';
    _observerServer = observerServer(ObserverServerKind.coreScope, _server);
    try {
      final saved = jsonDecode(prefs.getString(_keyHeard) ?? '{}') as Map;
      for (final MapEntry(:key, :value) in saved.entries) {
        _heard[key as String] = [
          for (final s in value as List)
            Sighting.fromJson((s as Map).cast<String, Object?>()),
        ];
      }
    } catch (e) {
      appLogger.warn('Unreadable observer list: $e', tag: 'Heard');
    }
    try {
      final saved = jsonDecode(prefs.getString(_keyLastEar) ?? '{}') as Map;
      for (final MapEntry(:key, :value) in saved.entries) {
        _lastEar[key as String] =
            DateTime.fromMillisecondsSinceEpoch(value as int);
      }
    } catch (e) {
      appLogger.warn('Unreadable last observer times: $e', tag: 'Heard');
    }
    connector.onChannelSendStamped = _onSendStamped;
    connector.onOwnChannelEcho = _onOwnEcho;
    connector.mayResendAfterOneRepeater = _mayResendAfterOneRepeater;
    connector.onResentAfterOneRepeater = _onResentAfterOneRepeater;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    notifyListeners();
    await PrefsManager.instance.setBool(_keyEnabled, enabled);
  }

  Future<void> setServer(String address) async {
    _observerServer?.close();
    _server = address.trim();
    _observerServer = observerServer(ObserverServerKind.coreScope, _server);
    // What the old server's observers heard says nothing about the new one.
    _lastEar.clear();
    _misses = 0;
    notifyListeners();
    await PrefsManager.instance.setString(_keyServer, _server);
    await PrefsManager.instance.remove(_keyLastEar);
  }

  /// Whether the server at [address] answers: it is asked about one
  /// made-up hash, the same request the real checks make.
  static Future<bool> serverAnswers(String address) async {
    final server = observerServer(ObserverServerKind.coreScope, address);
    if (server == null) return false;
    try {
      await server.sightings(const ['0000000000000000']);
      return true;
    } catch (e) {
      appLogger.info('Observer server $address: $e', tag: 'Heard');
      return false;
    } finally {
      server.close();
    }
  }

  void _onSendStamped(
    ({
      String messageId,
      Uint8List channelKey,
      String senderName,
      String text,
      int secs,
    }) send,
  ) {
    if (!_enabled || _observerServer == null) return;
    _checker.track(
      send.messageId,
      channelTextPacketHash(
        channelKey: send.channelKey,
        senderName: send.senderName,
        text: send.text,
        timestampSecs: send.secs,
      ),
    );
  }

  /// Our radio heard a copy back: its hash should be one we worked out. If
  /// it isn't, the log says so and the server is asked about it too.
  void _onOwnEcho(String messageId, String packetHash) {
    final predicted = _checker.hashesOf(messageId);
    if (predicted == null || predicted.contains(packetHash)) return;
    appLogger.warn(
      'Observer check for $messageId: worked out ${predicted.join(', ')}, '
      'heard $packetHash',
      tag: 'Heard',
    );
    _checker.addHash(messageId, packetHash);
  }

  String? get _radioKey {
    final key = _connector?.selfPublicKey;
    return key == null ? null : pubKeyToHex(key);
  }

  /// Whether a channel message only one repeater carried may go out once
  /// more: an observer heard this radio within [proofWindow], and fewer
  /// than [missesBeforeBackOff] such resends in a row went unheard.
  bool _mayResendAfterOneRepeater() {
    if (!_enabled || _observerServer == null) return false;
    if (_misses >= missesBeforeBackOff) return false;
    final heardAt = _lastEar[_radioKey];
    return heardAt != null && DateTime.now().difference(heardAt) < proofWindow;
  }

  /// A miss unless an observer hears the message, or its resend, by the
  /// resend's last ask.
  void _onResentAfterOneRepeater(String messageId) {
    _missTimers.remove(messageId)?.cancel();
    _missTimers[messageId] = Timer(
      _checker.askAfter.last + const Duration(seconds: 30),
      () {
        _missTimers.remove(messageId);
        _misses++;
        appLogger.info(
          'Sent $messageId once more and no observer heard it '
          '($_misses in a row)',
          tag: 'Heard',
        );
        if (_misses == missesBeforeBackOff) {
          appLogger.info(
            'No more sends after one repeater until an observer hears this '
            'radio again',
            tag: 'Heard',
          );
        }
      },
    );
  }

  @visibleForTesting
  void heardForTest(String messageId, List<Sighting> sightings) =>
      _onHeard(messageId, sightings);

  void _onHeard(String messageId, List<Sighting> sightings) {
    appLogger.info(
      'Observers heard $messageId: '
      '${sightings.map((s) => s.observer).join(', ')}',
      tag: 'Heard',
    );
    _misses = 0;
    _missTimers.remove(messageId)?.cancel();
    final radio = _radioKey;
    if (radio != null) {
      _lastEar[radio] = DateTime.now();
      unawaited(
        PrefsManager.instance.setString(
          _keyLastEar,
          jsonEncode({
            for (final MapEntry(:key, :value) in _lastEar.entries)
              key: value.millisecondsSinceEpoch,
          }),
        ),
      );
    }
    _heard.remove(messageId);
    _heard[messageId] = sightings;
    while (_heard.length > _keptMessages) {
      _heard.remove(_heard.keys.first);
    }
    _connector?.confirmChannelSendHeard(messageId);
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(
        _keyHeard,
        jsonEncode({
          for (final MapEntry(:key, :value) in _heard.entries)
            key: [for (final s in value) s.toJson()],
        }),
      ),
    );
  }
}
