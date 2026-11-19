import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/trax.dart';
import '../services/trax_service.dart';
import 'app_bar.dart';
import 'trax_dialogs.dart';
import 'trax_sheet.dart';

/// The top bar's TRAX button, before the GPS icon: the boot print, grey
/// while TRAX mode is off and the logo's orange while it is on. Tapping it
/// opens the TRAX sheet.
class TraxButton extends StatelessWidget {
  const TraxButton({super.key});

  @override
  Widget build(BuildContext context) {
    final trax = context.watch<TraxService?>();
    final connected = context.select<MeshCoreConnector, bool>(
      (c) => c.isConnected,
    );
    if (trax == null || !connected) return const SizedBox.shrink();
    final l10n = context.l10n;
    final on = trax.isOn;
    return IconButton(
      style: topBarIconStyle,
      tooltip: on ? l10n.trax_isOn : l10n.trax_isOff,
      onPressed: () => showTraxSheet(context),
      icon: TraxIcon(
        size: topBarIconSize,
        color: on
            ? const Color(Trax.orange)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
