import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:traxheard/traxheard.dart';

import '../connector/meshcore_connector.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

/// "Check sends with observers": while it is on, MeshTrax asks an observer
/// server about every channel message it sends, and one that an observer
/// heard isn't sent again. Who heard which message is kept for the grey
/// ear in the chat. The traxheard package does the asking.
class HeardService extends ChangeNotifier {
  HeardService._();

  static HeardService instance = HeardService._();

  @visibleForTesting
  static void resetForTesting() {
    instance._checker.dispose();
    instance = HeardService._();
  }

  static const _keyEnabled = 'heard_check_enabled';
  static const _keyServer = 'heard_check_server';
  static const _keyHeard = 'heard_check_heard';

  /// Messages whose observers are kept, newest last.
  static const _keptMessages = 300;

  MeshCoreConnector? _connector;
  bool _enabled = false;
  String _server = '';
  ObserverServer? _observerServer;
  final _heard = <String, List<Sighting>>{};

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
    connector.onChannelSendStamped = _onSendStamped;
    connector.onOwnChannelEcho = _onOwnEcho;
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
    notifyListeners();
    await PrefsManager.instance.setString(_keyServer, _server);
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

  void _onHeard(String messageId, List<Sighting> sightings) {
    appLogger.info(
      'Observers heard $messageId: '
      '${sightings.map((s) => s.observer).join(', ')}',
      tag: 'Heard',
    );
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
