import 'observer_server.dart';

/// An observer server to pick from a list instead of typing its address.
class KnownServer {
  const KnownServer({
    required this.name,
    required this.area,
    required this.address,
    this.kind = ObserverServerKind.coreScope,
  });

  final String name;

  /// Where its observers listen. A server only knows what they hear.
  final String area;

  final String address;
  final ObserverServerKind kind;
}

/// Observer servers whose read API is open to anyone.
const knownServers = [
  KnownServer(
    name: 'ON8AR',
    area: 'Belgium',
    address: 'https://analyzer.on8ar.eu',
  ),
];
