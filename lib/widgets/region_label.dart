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
