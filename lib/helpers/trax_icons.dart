import 'package:material_ui/material_ui.dart';
import 'package:traxshare/traxshare.dart' show TraxMapIcon;

import '../l10n/app_localizations.dart';

/// A trip member's icon on the map, their card and the TRAX group; the
/// hiker until a report of theirs says otherwise.
IconData traxIconData(TraxMapIcon? icon) => switch (icon) {
  null || TraxMapIcon.hike => Icons.hiking,
  TraxMapIcon.vehicle => Icons.directions_car,
  TraxMapIcon.boat => Icons.directions_boat,
  TraxMapIcon.motorcycle => Icons.two_wheeler,
  TraxMapIcon.bicycle => Icons.directions_bike,
  TraxMapIcon.aircraft => Icons.flight,
  TraxMapIcon.camp => Icons.cabin,
};

String traxIconName(AppLocalizations l10n, TraxMapIcon icon) => switch (icon) {
  TraxMapIcon.hike => l10n.trax_iconHike,
  TraxMapIcon.vehicle => l10n.trax_iconVehicle,
  TraxMapIcon.boat => l10n.trax_iconBoat,
  TraxMapIcon.motorcycle => l10n.trax_iconMotorcycle,
  TraxMapIcon.bicycle => l10n.trax_iconBicycle,
  TraxMapIcon.aircraft => l10n.trax_iconAircraft,
  TraxMapIcon.camp => l10n.trax_iconCamp,
};
