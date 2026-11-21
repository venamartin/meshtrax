import 'package:material_ui/material_ui.dart';

import '../helpers/region_helper.dart';
import '../l10n/l10n.dart';

/// A channel's own region: a small pin and the name. Shown only when the
/// channel has one.
class RegionLabel extends StatelessWidget {
  final String region;
  final double fontSize;

  const RegionLabel(this.region, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final text = region == RegionHelper.everywhere
        ? context.l10n.channelRegion_everywhere
        : region;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_outlined, size: fontSize + 2, color: color),
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
