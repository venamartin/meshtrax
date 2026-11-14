import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/gps_cli_status.dart';
import '../l10n/l10n.dart';

/// The radio's own account of its GPS, asked every few seconds while shown:
/// satellites in use and whether it has a position. Firmware 1.18+ only (the
/// companion CLI); shows nothing until the radio answers.
class GpsStatusLine extends StatefulWidget {
  final MeshCoreConnector connector;

  const GpsStatusLine({super.key, required this.connector});

  static const interval = Duration(seconds: 5);

  @override
  State<GpsStatusLine> createState() => _GpsStatusLineState();
}

class _GpsStatusLineState extends State<GpsStatusLine> {
  GpsCliStatus? _status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ask();
    _timer = Timer.periodic(GpsStatusLine.interval, (_) => _ask());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _ask() async {
    try {
      final reply = await widget.connector.companionCli.run('gps');
      final status = GpsCliStatus.parse(reply);
      if (mounted && status != null) setState(() => _status = status);
    } catch (_) {
      // No answer this time; the next tick asks again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sats = status.satellites;
    final text = !status.powered
        ? l10n.settings_gpsOff
        : [
            status.hasFix ? l10n.settings_gpsFix : l10n.settings_gpsNoFix,
            if (sats != null) l10n.settings_gpsSatellites(sats),
          ].join(' · ');
    return Row(
      children: [
        Icon(
          status.hasFix ? Icons.gps_fixed : Icons.gps_not_fixed,
          size: 18,
          color: status.hasFix ? Colors.green : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
