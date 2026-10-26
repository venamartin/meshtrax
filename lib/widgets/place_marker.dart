import 'package:flutter/material.dart';
import 'package:traxmap/traxmap.dart' show LatLng, MapMarker;

import '../helpers/map_places.dart';
import '../helpers/poi_kinds.dart';

/// A place's map marker. No name on the map: a tap opens its sheet.
MapMarker placeMarker(MapPlace p, {required VoidCallback onTap}) => MapMarker(
  id: 'place-${p.place.id}-${p.place.lat}',
  position: LatLng(p.place.lat, p.place.lon),
  child: PlaceBadge(kind: p.place.kind),
  size: const Size.square(PlaceBadge.size),
  onTap: onTap,
);

/// A place's icon on a rounded square of its group's colour: smaller than
/// a node's disc and square, so places never pass for nodes.
class PlaceBadge extends StatelessWidget {
  static const double size = 22;

  final String kind;

  const PlaceBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: poiKindColor(kind),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2)],
    ),
    child: Icon(poiKindIcon(kind), size: 14, color: Colors.white),
  );
}
