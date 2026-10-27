import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../helpers/maps_link.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

/// Expands Google Maps short links (maps.app.goo.gl) by following their
/// redirects until a URL with coordinates appears. Needs internet, so
/// answers are cached: successes for good, failures for a few minutes.
class ShortLinkResolver extends ChangeNotifier {
  static final ShortLinkResolver instance = ShortLinkResolver();

  static const _prefsKey = 'short_link_cache';
  static const _maxHops = 5;
  static const _timeout = Duration(seconds: 5);
  static const _retryFailedAfter = Duration(minutes: 5);
  static const _maxPersisted = 200;

  final http.Client Function() _clientFactory;
  final Map<String, LatLng> _resolved = {};
  final Map<String, DateTime> _failedAt = {};
  final Map<String, Future<LatLng?>> _pending = {};
  bool _loaded = false;

  ShortLinkResolver({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? http.Client.new;

  /// The cached answer, or null when unknown. Never triggers a lookup.
  LatLng? cached(String url) {
    _loadOnce();
    return _resolved[_key(url)];
  }

  bool isPending(String url) => _pending.containsKey(_key(url));

  /// The short links in a short message (at most three lines, the shape a
  /// shared location has), whose card can appear once one is looked up;
  /// none in anything longer.
  static List<String> shortLinksIn(String text) {
    if ('\n'.allMatches(text.trim()).length > 2) return const [];
    return [
      for (final url in MapsLink.findAll(text))
        if (MapsLink.isShortLink(url)) url,
    ];
  }

  /// Starts a lookup if none is cached or running; listeners are notified
  /// when it lands so a card can appear.
  void prefetch(String url) {
    if (cached(url) != null || isPending(url)) return;
    final failed = _failedAt[_key(url)];
    if (failed != null && DateTime.now().difference(failed) < _retryFailedAfter) {
      return;
    }
    unawaited(resolve(url));
  }

  /// When [prefetch] would look [url] up again after a failed lookup; null
  /// when none failed. Nothing retries by itself: a row asks again then.
  DateTime? retryAt(String url) => _failedAt[_key(url)]?.add(_retryFailedAfter);

  Future<LatLng?> resolve(String url) {
    _loadOnce();
    final key = _key(url);
    final hit = _resolved[key];
    if (hit != null) return Future.value(hit);
    final running = _pending[key];
    if (running != null) return running;
    final future = _resolveUncached(url).then((position) {
      _pending.remove(key);
      if (position != null) {
        _resolved[key] = position;
        _failedAt.remove(key);
        _persist();
      } else {
        _failedAt[key] = DateTime.now();
      }
      notifyListeners();
      return position;
    });
    _pending[key] = future;
    return future;
  }

  Future<LatLng?> _resolveUncached(String url) async {
    final client = _clientFactory();
    try {
      var current = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      for (var hop = 0; hop < _maxHops; hop++) {
        final direct = MapsLink.parse(current.toString());
        if (direct != null) return direct.position;
        final request = http.Request('GET', current)..followRedirects = false;
        final response = await client.send(request).timeout(_timeout);
        final location = response.headers['location'];
        unawaited(response.stream.drain<void>().catchError((_) {}));
        if (location == null || location.isEmpty) return null;
        current = current.resolve(location);
      }
      return MapsLink.parse(current.toString())?.position;
    } catch (e) {
      appLogger.info('Short link not resolved: $url ($e)', tag: 'MapsLink');
      return null;
    } finally {
      client.close();
    }
  }

  static String _key(String url) => url.trim();

  void _loadOnce() {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = PrefsManager.instance.getString(_prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((url, value) {
        final parts = (value as String).split(',');
        if (parts.length != 2) return;
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        if (lat != null && lon != null) _resolved[url] = LatLng(lat, lon);
      });
    } catch (_) {
      // Not initialised yet (tests) or corrupt: start empty.
    }
  }

  void _persist() {
    try {
      final entries = _resolved.entries.toList();
      final keep = entries.length > _maxPersisted
          ? entries.sublist(entries.length - _maxPersisted)
          : entries;
      final map = {
        for (final e in keep) e.key: '${e.value.latitude},${e.value.longitude}',
      };
      unawaited(PrefsManager.instance.setString(_prefsKey, jsonEncode(map)));
    } catch (_) {}
  }
}
