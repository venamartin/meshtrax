import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'observer_server.dart';
import 'sighting.dart';

/// An observer server running CoreScope (github.com/Kpa-clawbot/CoreScope).
/// Its read API is open: `POST api/packets/observations` with
/// `{"hashes": [...]}`, at most 200 a request. The answer's `results` has
/// a list per hash heard, one entry per observer: `observer_name`, `snr`,
/// `rssi`, `path_json`, `timestamp` and more.
class CoreScopeServer implements ObserverServer {
  CoreScopeServer(
    this.base, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client;

  /// The server's address, ending in "/".
  final Uri base;
  final Duration timeout;

  /// Made on the first request, so a server nobody asks opens nothing.
  http.Client? _client;

  static const _maxHashesPerRequest = 200;

  @override
  Future<Map<String, List<Sighting>>> sightings(
    Iterable<String> hashes,
  ) async {
    final wanted = {for (final h in hashes) h.toLowerCase()}.toList();
    final found = <String, List<Sighting>>{};
    for (var i = 0; i < wanted.length; i += _maxHashesPerRequest) {
      final part = wanted.sublist(
        i,
        min(i + _maxHashesPerRequest, wanted.length),
      );
      final response = await (_client ??= http.Client())
          .post(
            base.resolve('api/packets/observations'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'hashes': part}),
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'HTTP ${response.statusCode}',
          response.request?.url,
        );
      }
      final results = (jsonDecode(response.body) as Map)['results'];
      if (results is! Map) {
        throw const FormatException('The answer has no "results".');
      }
      for (final MapEntry(:key, :value) in results.entries) {
        if (value is! List || value.isEmpty) continue;
        found[(key as String).toLowerCase()] = [
          for (final o in value)
            if (o is Map) _sighting(o),
        ];
      }
    }
    return found;
  }

  @override
  void close() => _client?.close();
}

Sighting _sighting(Map o) => Sighting(
      observer: _text(o['observer_name']) ?? _text(o['observer_id']) ?? '?',
      snr: _number(o['snr']),
      rssi: _number(o['rssi']),
      hops: _hops(o['path_json']),
      heardAt: _time(o['timestamp']),
    );

double? _number(Object? value) => switch (value) {
      num n => n.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };

String? _text(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

/// The hops a packet took to the observer: the path is a list of repeater
/// hashes, sent as a list or as JSON text. An empty one means it heard the
/// sender directly.
int? _hops(Object? path) {
  if (path is String) {
    if (path.trim().isEmpty) return null;
    try {
      path = jsonDecode(path);
    } on FormatException {
      return null;
    }
  }
  return path is List ? path.length : null;
}

DateTime? _time(Object? value) => switch (value) {
      String text => DateTime.tryParse(text),
      // Seconds or milliseconds since 1970.
      num n => DateTime.fromMillisecondsSinceEpoch(
          (n < 1e12 ? n * 1000 : n).round(),
          isUtc: true,
        ),
      _ => null,
    };
