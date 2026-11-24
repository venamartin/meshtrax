import 'package:latlong2/latlong.dart';

/// What a map is asked to show, from a chat card, a link, Navigate or the
/// TRAX sheet. A map shows these itself rather than open a second map over
/// it, so Back never goes from one map to another.
sealed class MapFocus {
  const MapFocus();
}

/// A point, pinned with its name: a shared location, an event's place, a
/// coordinate or maps link in a message. An [sos] pin opens Route here and
/// Navigate.
class MapFocusPoint extends MapFocus {
  final LatLng position;
  final String? label;
  final bool sos;

  const MapFocusPoint(this.position, {this.label, this.sos = false});
}

/// The route from your position to [position], as Route here finds it:
/// Navigate on a card.
class MapFocusRoute extends MapFocus {
  final LatLng position;
  final String? label;

  const MapFocusRoute(this.position, {this.label});
}

/// A TRAX group member's card, by key prefix, last known at [place].
class MapFocusMember extends MapFocus {
  final String prefix;
  final LatLng place;

  const MapFocusMember(this.prefix, this.place);
}
