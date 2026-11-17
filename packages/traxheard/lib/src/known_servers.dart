import 'observer_server.dart';

/// An observer server to pick from a list instead of typing its address.
class KnownServer {
  const KnownServer({
    required this.area,
    required this.address,
    this.kind = ObserverServerKind.coreScope,
  });

  /// Where its observers listen. A server only knows what they hear.
  final String area;

  final String address;
  final ObserverServerKind kind;

  /// How the list shows it: its area and host,
  /// "Northern California · corescope.stonekitty.net".
  String get label => '$area · ${observerServerUri(address)?.host ?? address}';
}

/// Observer servers whose read API is open to anyone.
const knownServers = [
  KnownServer(
    area: 'Northern California',
    address: 'https://corescope.stonekitty.net',
  ),
  KnownServer(area: 'Belgium', address: 'https://analyzer.on8ar.eu'),
];
