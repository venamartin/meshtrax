import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/geo_format.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import 'snr_indicator.dart';

/// The top bar's GPS icon: on or off, shown only when the radio has a GPS.
/// Tapping it opens [showGpsDialog].
class GpsStatusButton extends StatelessWidget {
  const GpsStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final (:shown, :on) = context
        .select<MeshCoreConnector, ({bool shown, bool on})>(
          (c) => (shown: c.isConnected && c.hasGps, on: c.gpsOn),
        );
    if (!shown) return const SizedBox.shrink();
    final l10n = context.l10n;
    return IconButton(
      tooltip: on ? l10n.gps_on : l10n.gps_off,
      visualDensity: VisualDensity.compact,
      onPressed: () => showGpsDialog(context),
      icon: Icon(
        on ? Icons.gps_fixed : Icons.gps_off,
        size: 20,
        color: on ? Colors.green : Colors.grey,
      ),
    );
  }
}

Future<void> showGpsDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _GpsDialog());

/// The radio's GPS: the switch, and where the GPS puts the radio.
class _GpsDialog extends StatefulWidget {
  const _GpsDialog();

  @override
  State<_GpsDialog> createState() => _GpsDialogState();
}

class _GpsDialogState extends State<_GpsDialog> {
  late final MeshCoreConnector _connector;
  // Keeps "read 4s ago" counting.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _connector.addSelfPositionViewer();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _connector.removeSelfPositionViewer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = context.select<MeshCoreConnector, bool>((c) => c.gpsOn);
    final units = context.select<AppSettingsService, UnitSystem>(
      (s) => s.settings.unitSystem,
    );
    final small = Theme.of(context).textTheme.bodySmall;
    return AlertDialog(
      title: Text(l10n.gps_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.gps_title),
            subtitle: Text(on ? l10n.gps_onHint : l10n.gps_offHint),
            value: on,
            onChanged: (value) => unawaited(_connector.setGps(value)),
          ),
          if (on)
            ValueListenableBuilder<SelfGpsReading?>(
              valueListenable: _connector.selfGps,
              builder: (context, reading, _) {
                if (reading == null) return Text(l10n.gps_asking);
                if (!GeoFormat.isValidPosition(
                  reading.latitude,
                  reading.longitude,
                )) {
                  return Text(l10n.gps_noPosition);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      l10n.gps_position,
                      '${reading.latitude.toStringAsFixed(4)}, '
                      '${reading.longitude.toStringAsFixed(4)}',
                    ),
                    _row(
                      l10n.gps_altitude,
                      GeoFormat.heightText(reading.altitude, units),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.gps_readAgo(formatAgo(reading.at)), style: small),
                  ],
                );
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_close),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    ),
  );
}
