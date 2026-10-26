import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// After a contact's name: they get this radio's position when they ask
/// for telemetry (the connector's sharesPositionWith). Not to be read as
/// their own position, which contact rows mark with a plain pin.
class SharesPositionIcon extends StatelessWidget {
  const SharesPositionIcon({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.l10n.contact_sharesPosition,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          Icons.share_location,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
