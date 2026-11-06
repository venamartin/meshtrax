import 'package:traxcoords/traxcoords.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';

/// The coordinate format chosen in App Settings.
CoordFormat coordFormatOf(AppSettings settings) =>
    CoordFormat.values.asNameMap()[settings.coordinateFormat] ??
    CoordFormat.decimalDegrees;

/// A position in [format], then in decimal degrees when [format] is
/// another, for apps that only take those (Martin, 2026-10-26).
List<String> positionLines(double lat, double lon, CoordFormat format) {
  final p = (lat: lat, lon: lon);
  final degrees = formatCoordinates(p, CoordFormat.decimalDegrees)!;
  final chosen = formatCoordinates(p, format) ?? degrees;
  return [chosen, if (chosen != degrees) degrees];
}

String coordFormatName(AppLocalizations l10n, CoordFormat f) => switch (f) {
  CoordFormat.decimalDegrees => l10n.coordFormat_decimalDegrees,
  CoordFormat.degreesMinutes => l10n.coordFormat_degreesMinutes,
  CoordFormat.degreesMinutesSeconds => l10n.coordFormat_dms,
  CoordFormat.utm => l10n.coordFormat_utm,
  CoordFormat.mgrs => l10n.coordFormat_mgrs,
  CoordFormat.maidenhead => l10n.coordFormat_maidenhead,
  CoordFormat.geohash => l10n.coordFormat_geohash,
};
