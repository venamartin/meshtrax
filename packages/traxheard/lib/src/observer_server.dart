import 'package:http/http.dart' as http;

import 'corescope_server.dart';
import 'sighting.dart';

/// A server that gathers what listening radios (observers) hear, and can
/// say which of them heard a packet.
abstract interface class ObserverServer {
  /// The sightings of each of [hashes] the server holds. A hash that no
  /// observer heard is left out. Throws when the server can't be asked.
  Future<Map<String, List<Sighting>>> sightings(Iterable<String> hashes);

  void close();
}

/// The kinds of observer server there are to ask.
enum ObserverServerKind { coreScope }

/// The server of [kind] at [address], or null when [address] isn't a web
/// address.
ObserverServer? observerServer(
  ObserverServerKind kind,
  String address, {
  http.Client? client,
}) {
  final base = observerServerUri(address);
  if (base == null) return null;
  return switch (kind) {
    ObserverServerKind.coreScope => CoreScopeServer(base, client: client),
  };
}

/// [address] as a server's base URL. A bare host name gets https, a path
/// is kept (a server can sit under one), and the result ends in "/".
Uri? observerServerUri(String address) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
  );
}
