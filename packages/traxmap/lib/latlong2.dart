/// Conversions between this package's coordinates and latlong2's, for apps
/// (like MeshTrax) built on latlong2. Import the main library with
/// `hide LatLng, LatLngBounds` if both names clash in one file.
library;

import 'package:latlong2/latlong.dart' as ll;

import 'src/packs/geo.dart' as ovm;

extension OvmLatLngToLatLong2 on ovm.LatLng {
  ll.LatLng toLatLong2() => ll.LatLng(latitude, longitude);
}

extension LatLong2ToOvm on ll.LatLng {
  ovm.LatLng toOvm() => ovm.LatLng(latitude, longitude);
}

extension LatLong2ListToOvm on Iterable<ll.LatLng> {
  List<ovm.LatLng> toOvm() => [for (final p in this) p.toOvm()];
}
