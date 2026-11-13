import 'package:material_ui/material_ui.dart';
import 'package:traxroute/traxroute.dart';

import '../l10n/l10n.dart';

/// The route panel's options for [pathType]: the few settings that change
/// which way a route goes, or its times.
class RouteOptionsSection extends StatelessWidget {
  final PathType pathType;
  final RouteOptions options;
  final ValueChanged<RouteOptions> onChanged;

  const RouteOptionsSection({
    super.key,
    required this.pathType,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final o = options;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    Widget choice<T>(Map<T, String> labels, T value, ValueChanged<T> onPick) =>
        SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final MapEntry(:key, value: text) in labels.entries)
              ButtonSegment(value: key, label: Text(text)),
          ],
          selected: {value},
          onSelectionChanged: (s) => onPick(s.single),
        );

    final avoids = [
      label(l10n.route_avoid),
      Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: Text(l10n.route_avoidHighways),
            selected: o.avoidHighways,
            onSelected: (v) => onChanged(o.copyWith(avoidHighways: v)),
          ),
          FilterChip(
            label: Text(l10n.route_avoidTolls),
            selected: o.avoidTolls,
            onSelected: (v) => onChanged(o.copyWith(avoidTolls: v)),
          ),
          FilterChip(
            label: Text(l10n.route_avoidFerries),
            selected: o.avoidFerries,
            onSelected: (v) => onChanged(o.copyWith(avoidFerries: v)),
          ),
        ],
      ),
    ];

    final children = switch (pathType) {
      PathType.paved => avoids,
      PathType.dirt => [
        label(l10n.route_prefer),
        choice(
          {
            DirtPreference.fastest: l10n.route_dirtFastest,
            DirtPreference.balanced: l10n.route_dirtBalanced,
            DirtPreference.direct: l10n.route_dirtDirect,
          },
          o.dirt,
          (v) => onChanged(o.copyWith(dirt: v)),
        ),
        const SizedBox(height: 6),
        Text(switch (o.dirt) {
          DirtPreference.fastest => l10n.route_dirtFastestHelp,
          DirtPreference.balanced => l10n.route_dirtBalancedHelp,
          DirtPreference.direct => l10n.route_dirtDirectHelp,
        }, style: theme.textTheme.bodySmall),
        ...avoids,
      ],
      PathType.hiking => [
        label(l10n.route_hardestTrail),
        DropdownMenu<int>(
          expandedInsets: EdgeInsets.zero,
          initialSelection: o.hardestTrail,
          onSelected: (v) {
            if (v != null) onChanged(o.copyWith(hardestTrail: v));
          },
          dropdownMenuEntries: [
            for (final (t, text) in [
              (1, l10n.route_trailT1),
              (2, l10n.route_trailT2),
              (3, l10n.route_trailT3),
              (4, l10n.route_trailT4),
              (5, l10n.route_trailT5),
              (6, l10n.route_trailT6),
            ])
              DropdownMenuEntry(value: t, label: text),
          ],
        ),
        label(l10n.route_climbs),
        choice(
          {
            ClimbPreference.avoid: l10n.route_climbsAvoid,
            ClimbPreference.some: l10n.route_climbsSome,
            ClimbPreference.any: l10n.route_climbsAny,
          },
          o.climbs,
          (v) => onChanged(o.copyWith(climbs: v)),
        ),
        label(l10n.route_pace),
        choice(
          {
            HikingPace.slow: l10n.route_paceSlow,
            HikingPace.normal: l10n.route_paceNormal,
            HikingPace.fast: l10n.route_paceFast,
          },
          o.pace,
          (v) => onChanged(o.copyWith(pace: v)),
        ),
      ],
    };

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
