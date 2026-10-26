import 'package:flutter/material.dart';
import 'package:traxmap/traxmap.dart' show LatLng, MapMarker;

import '../helpers/map_places.dart';
import '../helpers/poi_kinds.dart';

/// A place's map marker; a tap opens its sheet. [named] puts its name
/// under the icon ([placesToName]), drawn like the map's own labels
/// ([dark] for the dark map).
MapMarker placeMarker(
  MapPlace p, {
  required VoidCallback onTap,
  bool named = false,
  bool dark = false,
}) {
  final place = p.place;
  final name = named && place.name.isNotEmpty ? place.name : null;
  return MapMarker(
    id: 'place-${place.id}-${place.lat}',
    position: LatLng(place.lat, place.lon),
    child: name == null
        ? PlaceBadge(kind: place.kind)
        : Column(
            children: [
              PlaceBadge(kind: place.kind),
              PlaceName(name, dark: dark),
            ],
          ),
    size: name == null
        ? const Size.square(PlaceBadge.size)
        : const Size(PlaceName.width, _namedHeight),
    // The icon, not the name, sits on the place.
    anchor: name == null
        ? Alignment.center
        : const Alignment(0, PlaceBadge.size / _namedHeight - 1),
    onTap: onTap,
  );
}

const double _namedHeight = PlaceBadge.size + 30;

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

/// A name under a place's icon, in the map's own label colours (the
/// standard map's place names) with a halo.
class PlaceName extends StatelessWidget {
  static const double width = 110;

  final String name;
  final bool dark;

  const PlaceName(this.name, {super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, height: 1.15);
    Text text(TextStyle s) => Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: s,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Stack(
        children: [
          text(
            style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeJoin = StrokeJoin.round
                ..color = dark ? const Color(0xFF1C2026) : Colors.white,
            ),
          ),
          text(
            style.copyWith(
              color: dark ? const Color(0xFF9AA3AD) : const Color(0xFF7A7F85),
            ),
          ),
        ],
      ),
    );
  }
}
