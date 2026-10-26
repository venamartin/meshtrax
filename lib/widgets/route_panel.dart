import 'package:flutter/material.dart';
import 'package:traxroute/traxroute.dart';

import '../helpers/geo_format.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import 'elevation_profile.dart';

/// The colour a route is drawn in on the map and in its profile.
Color routeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFF8A50)
    : const Color(0xFFD84315);

IconData pathTypeIcon(PathType type) => switch (type) {
  PathType.paved => Icons.directions_car,
  PathType.dirtRoad => Icons.landscape,
  PathType.hiking => Icons.hiking,
};

String pathTypeLabel(BuildContext context, PathType type) => switch (type) {
  PathType.paved => context.l10n.route_pathPaved,
  PathType.dirtRoad => context.l10n.route_pathDirt,
  PathType.hiking => context.l10n.route_pathHiking,
};

String routeDuration(BuildContext context, double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return context.l10n.route_minutes(minutes);
  return context.l10n.route_hoursMinutes(minutes ~/ 60, minutes % 60);
}

/// The route to [destination] at the bottom of the map: the path type, the
/// distance, time and climb, where it stops short when the destination
/// can't be reached that way, and the height profile.
class RoutePanel extends StatelessWidget {
  final String destination;
  final PathType pathType;
  final ValueChanged<PathType> onPathType;
  final RouteResult? result;
  final bool loading;
  final String? error;
  final UnitSystem units;
  final VoidCallback onClose;

  const RoutePanel({
    super.key,
    required this.destination,
    required this.pathType,
    required this.onPathType,
    required this.result,
    required this.loading,
    required this.error,
    required this.units,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = result;
    // The map screen docks this as its bottom sheet, which gives it its
    // surface.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.route_to(destination),
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.route_clear,
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<PathType>(
                showSelectedIcon: false,
                segments: [
                  for (final t in PathType.values)
                    ButtonSegment(
                      value: t,
                      icon: Icon(pathTypeIcon(t)),
                      label: Text(pathTypeLabel(context, t)),
                    ),
                ],
                selected: {pathType},
                onSelectionChanged: (s) => onPathType(s.single),
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.route_finding),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ),
              )
            else if (error != null || r == null)
              Text(error ?? l10n.route_none, style: theme.textTheme.bodyLarge)
            else ...[
              Text(
                [
                  GeoFormat.distanceText(r.km * 1000, units),
                  routeDuration(context, r.seconds),
                  '↑ ${GeoFormat.heightText(r.climb.up, units)}',
                ].join(' · '),
                style: theme.textTheme.titleSmall,
              ),
              if (!r.reachesDestination) ...[
                const SizedBox(height: 8),
                _EndsShort(result: r, destination: destination, units: units),
              ],
              if (r.elevations.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevationProfile(
                      elevations: r.elevations,
                      units: units,
                      color: routeColor(context),
                    ),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.format_list_numbered),
                  label: Text(l10n.route_directions),
                  onPressed: () => showRouteDirections(context, r, units),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EndsShort extends StatelessWidget {
  final RouteResult result;
  final String destination;
  final UnitSystem units;

  const _EndsShort({
    required this.result,
    required this.destination,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final distance = GeoFormat.distanceText(
      result.kmShortOfDestination * 1000,
      units,
    );
    final text = switch (result.pathType) {
      PathType.paved => l10n.route_endsShortPaved(distance, destination),
      PathType.dirtRoad => l10n.route_endsShortDirt(distance, destination),
      PathType.hiking => l10n.route_endsShortHiking(distance, destination),
    };
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// The turn-by-turn list, from the route's instructions.
Future<void> showRouteDirections(
  BuildContext context,
  RouteResult route,
  UnitSystem units,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 1,
    builder: (context, controller) => ListView(
      controller: controller,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            context.l10n.route_directions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final m in route.maneuvers)
          ListTile(
            title: Text(m.instruction),
            trailing: m.km > 0
                ? Text(GeoFormat.distanceText(m.km * 1000, units))
                : null,
          ),
      ],
    ),
  ),
);
