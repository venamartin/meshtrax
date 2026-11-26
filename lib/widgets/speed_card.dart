import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:traxwater/traxwater.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/geo_format.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/self_motion.dart';

/// How fast and which way the radio's GPS is going, and how high it is,
/// at the map's bottom left while the map keeps you in the middle. The
/// radio is read every 3 s while it shows.
class SpeedCard extends StatefulWidget {
  final MeshCoreConnector connector;
  final UnitSystem units;

  /// Knots and degrees magnetic, as water routes give them: the charts.
  final bool nautical;

  static const width = 132.0;

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
    final old = _connector.selfPositionMayBeOld;
    final motion = old ? null : SelfMotion.instance.motionNow();
    final still = motion?.stillFor != null;
    final heading = motion?.heading;
    final speed = still ? 0.0 : motion?.speed;
    final altitude = gps == null || gps.altitude == 0 ? null : gps.altitude;
    final quiet = scheme.onSurfaceVariant;
    final text = theme.textTheme.bodyLarge?.copyWith(
      color: old ? quiet : scheme.onSurface,
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
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(value, style: text),
        ],
      ),
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        if (old) l10n.map_lastKnown,
        '${l10n.map_speed} $number $unit',
        if (still) l10n.map_notMoving,
        if (headingText != null) '${l10n.map_heading} $headingText',
        if (altitudeText != null) '${l10n.map_elevation} $altitudeText',
      ].join(', '),
      child: SizedBox(
        width: SpeedCard.width,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          number,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: old ? quiet : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: quiet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (old)
                  line(
                    Icon(Icons.gps_not_fixed, size: 16, color: quiet),
                    l10n.map_lastKnown,
                  )
                else if (still)
                  line(
                    Icon(Icons.pause_circle_outline, size: 16, color: quiet),
                    l10n.map_notMoving,
                  )
                else if (headingText != null)
                  line(
                    Transform.rotate(
                      angle: heading! * math.pi / 180,
                      child: Icon(
                        Icons.navigation,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                    headingText,
                  ),
                if (altitudeText != null)
                  line(
                    Icon(Icons.terrain, size: 16, color: quiet),
                    altitudeText,
                  ),
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
