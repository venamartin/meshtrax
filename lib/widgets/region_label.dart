import 'package:material_ui/material_ui.dart';

import '../helpers/region_helper.dart';
import '../l10n/l10n.dart';

/// A channel's own region, or Nearby only: a small icon and the name.
/// Shown only when the channel has one.
class RegionLabel extends StatelessWidget {
  final String region;
  final double fontSize;

  const RegionLabel(this.region, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final nearby = region == RegionHelper.nearbyOnly;
    final text = switch (region) {
      RegionHelper.everywhere => context.l10n.channelRegion_everywhere,
      RegionHelper.nearbyOnly => context.l10n.channelRegion_nearby,
      _ => region,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          nearby ? Icons.social_distance : Icons.hexagon_outlined,
          size: fontSize + 2,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, color: color),
          ),
        ),
      ],
    );
  }
}

/// How many nearby repeaters said they carry a region: a green check and
/// the count, or an amber warning when none does.
class RegionCarriers extends StatelessWidget {
  final int count;

  const RegionCarriers(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Icon(
          count == 0 ? Icons.warning_amber : Icons.check,
          size: 16,
          color: count == 0 ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            count == 0
                ? l10n.channelRegion_noCarrier
                : l10n.channelRegion_carriers(count),
          ),
        ),
      ],
    );
  }
}
