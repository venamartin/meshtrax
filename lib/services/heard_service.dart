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
    for (final timer in [
      ...instance._missTimers.values,
      ...instance._learnTimers.values,
    ]) {
      timer.cancel();
    }
    instance = HeardService._();
  }

  static const _keyEnabled = 'heard_check_enabled';
  static const _keyServer = 'heard_check_server';
  static const _keyHeard = 'heard_check_heard';
  static const _keyLastEar = 'heard_check_last_ear';
  static const _keyRegions = 'heard_check_regions';

  /// Messages whose observers are kept, newest last.
  static const _keptMessages = 300;

  /// A resend after one repeater needs an observer to have heard this
  /// radio this lately. A day, so a quiet morning doesn't switch it off
  /// for the next message (owner, 2026-11-24: at 2 hours it did); a radio
  /// taken out of the observers' reach is stopped by [missesBeforeBackOff].
  static const proofWindow = Duration(hours: 24);

  /// Resends after one repeater that went unheard, in a row, before they
  /// stop until an observer hears this radio again.
  static const missesBeforeBackOff = 3;

  /// Sends in a region, in a row, that no observer heard before the
  /// region counts as having none: its channels go unchecked, and get no
  /// resend after one repeater, for [regionQuietFor]. Then one send is
  /// checked again; unheard, the region is quiet for another day.
  static const regionMissesBeforeQuiet = 3;
  static const regionQuietFor = Duration(days: 1);

  /// The region rule's clock; tests move it.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  MeshCoreConnector? _connector;
  bool _enabled = false;
  String _server = '';
  ObserverServer? _observerServer;
  final _heard = <String, List<Sighting>>{};

  /// When an observer last heard a channel message of each radio, by its
  /// public key; for a message sent in a region, by key|region.
  final _lastEar = <String, DateTime>{};
  int _misses = 0;
  final _missTimers = <String, Timer>{};

  /// The region each recent send of mine went out in.
  final _sendRegion = <String, String>{};

  /// Per region: unheard sends in a row, and until when it counts as
  /// having no observer.
  final _regions = <String, ({int misses, DateTime? quietUntil})>{};
  final _learnTimers = <String, Timer>{};

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
    try {
      final saved = jsonDecode(prefs.getString(_keyRegions) ?? '{}') as Map;
      for (final MapEntry(:key, :value) in saved.entries) {
        final quiet = (value as Map)['quietUntil'] as int?;
        _regions[key as String] = (
          misses: value['misses'] as int? ?? 0,
          quietUntil: quiet == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(quiet),
        );
      }
    } catch (e) {
      appLogger.warn('Unreadable region observer state: $e', tag: 'Heard');
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
    _regions.clear();
    notifyListeners();
    await PrefsManager.instance.setString(_keyServer, _server);
    await PrefsManager.instance.remove(_keyLastEar);
    await PrefsManager.instance.remove(_keyRegions);
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
      String? region,
    }) send,
  ) {
    if (!_enabled || _observerServer == null) return;
    final region = send.region;
    if (region != null) {
      _sendRegion.remove(send.messageId);
      _sendRegion[send.messageId] = region;
      while (_sendRegion.length > _keptMessages) {
        _sendRegion.remove(_sendRegion.keys.first);
      }
      if (_regionQuiet(region)) return;
      _learnTimers.remove(send.messageId)?.cancel();
      _learnTimers[send.messageId] = Timer(
        _checker.askAfter.last + const Duration(seconds: 30),
        () => _regionMissed(send.messageId, region),
      );
    }
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

  /// A photo of mine went out on the channel with secret [channelKey] as
  /// [packets] of channel data type [dataType]: from now, asks about them
  /// all together, as about a channel text, and the photo's row gets the
  /// ear when an observer heard any of them. A packet sent again is the same
  /// bytes, with the same hash. False when the check is off.
  bool trackPhoto(
    String messageId,
    Uint8List channelKey,
    int dataType,
    List<Uint8List> packets,
  ) {
    if (!_enabled || _observerServer == null || packets.isEmpty) return false;
    final hashes = [
      for (final p in packets)
        channelDataPacketHash(
          channelKey: channelKey,
          dataType: dataType,
          data: p,
        ),
    ];
    appLogger.info(
      'Observer check for photo $messageId: ${hashes.join(', ')}',
      tag: 'Heard',
    );
    _checker.track(messageId, hashes.first);
    for (final hash in hashes.skip(1)) {
      _checker.addHash(messageId, hash);
    }
    return true;
  }

  /// How long after a send its last ask comes.
  Duration get lastAsk => _checker.askAfter.last;

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

  /// Where an ear on [messageId] proves observers hear this radio: the
  /// radio itself, or the radio in that message's region.
  String? _laneOf(String messageId) {
    final radio = _radioKey;
    final region = _sendRegion[messageId];
    return radio == null || region == null ? radio : '$radio|$region';
  }

  bool _regionQuiet(String region) {
    final until = _regions[region]?.quietUntil;
    return until != null && now().isBefore(until);
  }

  /// No observer heard [messageId], sent in [region], by its last ask.
  void _regionMissed(String messageId, String region) {
    _learnTimers.remove(messageId);
    final misses = (_regions[region]?.misses ?? 0) + 1;
    if (misses >= regionMissesBeforeQuiet) {
      appLogger.info(
        'No observer heard $misses sends in a row in region $region: no '
        'observer checks there for a day',
        tag: 'Heard',
      );
      // After the day, one unheard send is enough to stay quiet.
      _regions[region] = (
        misses: regionMissesBeforeQuiet - 1,
        quietUntil: now().add(regionQuietFor),
      );
    } else {
      _regions[region] = (misses: misses, quietUntil: null);
    }
    _saveRegions();
  }

  void _saveRegions() => unawaited(
    PrefsManager.instance.setString(
      _keyRegions,
      jsonEncode({
        for (final MapEntry(:key, :value) in _regions.entries)
          key: {
            'misses': value.misses,
            'quietUntil': value.quietUntil?.millisecondsSinceEpoch,
          },
      }),
    ),
  );

  @visibleForTesting
  bool regionQuietForTest(String region) => _regionQuiet(region);

  @visibleForTesting
  bool checkingForTest(String messageId) =>
      _checker.hashesOf(messageId) != null;

  @visibleForTesting
  Set<String>? hashesForTest(String messageId) => _checker.hashesOf(messageId);

  /// Whether channel message [messageId], which only one repeater carried,
  /// may go out once more: an observer heard this radio, in that message's
  /// region, within [proofWindow]; the region isn't quiet; and fewer than
  /// [missesBeforeBackOff] such resends in a row went unheard.
  bool _mayResendAfterOneRepeater(String messageId) {
    if (!_enabled || _observerServer == null) return false;
    if (_misses >= missesBeforeBackOff) return false;
    final region = _sendRegion[messageId];
    if (region != null && _regionQuiet(region)) return false;
    final heardAt = _lastEar[_laneOf(messageId)];
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
    // An ear starts the row again: a resend still waiting on its own ear
    // isn't a miss after it.
    _misses = 0;
    for (final timer in _missTimers.values) {
      timer.cancel();
    }
    _missTimers.clear();
    final region = _sendRegion[messageId];
    if (region != null) {
      _learnTimers.remove(messageId)?.cancel();
      if (_regions.remove(region) != null) _saveRegions();
    }
    final lane = _laneOf(messageId);
    if (lane != null) {
      _lastEar[lane] = DateTime.now();
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
