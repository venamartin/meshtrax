import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:traxwater/traxwater.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/geo_format.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/self_motion.dart';

/// How fast and which way the radio's GPS is going, and how high it is,
/// at the map's bottom left while the map keeps you in the middle and the
/// reading is fresh: one bold number, its unit under it, then heading and
/// altitude, on a flat card with a thin outline (Martin chose this look).
/// The radio is read every 3 s while it shows.
class SpeedCard extends StatefulWidget {
  final MeshCoreConnector connector;
  final UnitSystem units;

  /// Knots and degrees magnetic, as water routes give them: the charts.
  final bool nautical;

  static const width = 116.0;

  const SpeedCard({
    super.key,
    required this.connector,
    required this.units,
    this.nautical = false,
  });

  @override
  State<SpeedCard> createState() => _SpeedCardState();
}

class _SpeedCardState extends State<SpeedCard> {
  late final MeshCoreConnector _connector = widget.connector;

  @override
  void initState() {
    super.initState();
    _connector.addSpeedViewer();
  }

  @override
  void dispose() {
    _connector.removeSpeedViewer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _connector.selfGps,
    builder: (context, gps, _) => _card(context, gps),
  );

  Widget _card(BuildContext context, SelfGpsReading? gps) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = SelfMotion.instance.motionNow();
    final still = motion?.stillFor != null;
    final heading = motion?.heading;
    final speed = still ? 0.0 : motion?.speed;
    final altitude = gps == null || gps.altitude == 0 ? null : gps.altitude;
    final quiet = scheme.onSurfaceVariant;
    // Digits of one width, so the figures hold still as they change.
    const tabular = [FontFeature.tabularFigures()];
    final text = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurface,
      fontFeatures: tabular,
    );

    final (figure, unit) = GeoFormat.speedParts(
      speed ?? 0,
      widget.units,
      knots: widget.nautical,
    );
    final number = speed == null ? '—' : figure;
    final headingText = heading == null
        ? null
        : widget.nautical && gps != null
        ? '${GeoFormat.headingText(_magnetic(heading, gps))}M'
        : GeoFormat.headingText(heading);
    final altitudeText = altitude == null
        ? null
        : GeoFormat.heightText(altitude, widget.units);

    Widget line(Widget icon, String value) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(value, style: text),
        ],
      ),
    );
    final lines = [
      if (still)
        line(
          Icon(Icons.pause_circle_outline, size: 18, color: quiet),
          l10n.map_notMoving,
        )
      else if (headingText != null)
        line(
          Transform.rotate(
            angle: heading! * math.pi / 180,
            child: Icon(Icons.navigation, size: 20, color: scheme.primary),
          ),
          headingText,
        ),
      if (altitudeText != null)
        line(Icon(Icons.terrain, size: 18, color: quiet), altitudeText),
    ];

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        '${l10n.map_speed} $number $unit',
        if (still) l10n.map_notMoving,
        if (headingText != null) '${l10n.map_heading} $headingText',
        if (altitudeText != null) '${l10n.map_elevation} $altitudeText',
      ].join(', '),
      child: SizedBox(
        width: SpeedCard.width,
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    number,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -1,
                      color: scheme.onSurface,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: quiet,
                    letterSpacing: 1.4,
                  ),
                ),
                if (lines.isNotEmpty) ...[
                  Divider(height: 18, color: scheme.outlineVariant),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: lines,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [heading] (true) as a compass reads it where [gps] is.
  static double _magnetic(double heading, SelfGpsReading gps) =>
      (heading -
          magneticDeclination(gps.latitude, gps.longitude, DateTime.now())) %
      360;
}
