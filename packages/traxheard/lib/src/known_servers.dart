import 'observer_server.dart';

/// An observer server to pick from a list instead of typing its address.
class KnownServer {
  const KnownServer({
    required this.area,
    required this.address,
    this.kind = ObserverServerKind.coreScope,
  });

  /// Where its observers listen. A server only knows what they hear, on
  /// the frequency they listen to; one not on 910.525 MHz says so.
  final String area;

  final String address;
  final ObserverServerKind kind;

  /// "corescope.stonekitty.net".
  String get host => observerServerUri(address)?.host ?? address;

  /// Its area and host on one line,
  /// "Northern California · corescope.stonekitty.net".
  String get label => '$area · $host';
}

/// Observer servers in North America whose read API is open to anyone.
/// Each answered the app's own request on 2026-11-17; community servers
/// behind a bot check, on a staging build or a personal domain are left
/// out, and so is a second name for a server already listed. Northern
/// California first, the rest A to Z.
const knownServers = [
  KnownServer(
    area: 'Northern California',
    address: 'https://corescope.stonekitty.net',
  ),
  KnownServer(area: 'Chattanooga', address: 'https://live.chattamesh.com'),
  KnownServer(area: 'Chicago', address: 'https://scope.chicagooffline.com'),
  KnownServer(
    area: 'Connecticut and New England',
    address: 'https://analyzer.ctmesh.org',
  ),
  KnownServer(
    area: 'Gulf Coast (LA, MS, FL panhandle)',
    address: 'https://live.ecmesh.us',
  ),
  KnownServer(
    area: 'Long Island, New York',
    address: 'https://corescope.limesh.org',
  ),
  KnownServer(
    area: 'Minneapolis–St Paul',
    address: 'https://corescope.mspmesh.org',
  ),
  KnownServer(area: 'Nashville', address: 'https://analyzer.nashme.sh'),
  KnownServer(
    area: 'Ohio, Kentucky and Indiana',
    address: 'https://map.okimesh.org',
  ),
  KnownServer(
    area: 'Philadelphia (919.5 MHz)',
    address: 'https://corescope500.phlm.sh',
  ),
  KnownServer(
    area: 'Sacramento (909.875 MHz)',
    address: 'https://corescope.sacmesh.org',
  ),
  KnownServer(
    area: 'Southern California (927.875 MHz)',
    address: 'https://corescope.wcmesh.com',
  ),
  KnownServer(
    area: 'Spokane and Inland Northwest',
    address: 'https://scope.inwmesh.org',
  ),
  KnownServer(area: 'Texas', address: 'https://analyzer.meshtexas.org'),
  KnownServer(
    area: 'Texas and Gulf Coast',
    address: 'https://analyzer.comchan.net',
  ),
  KnownServer(
    area: 'Wisconsin and Upper Midwest',
    address: 'https://map.rflab.io',
  ),
];
