import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';

class BatteryUi {
  final IconData icon;
  final Color? color;
  const BatteryUi(this.icon, this.color);
}

BatteryUi batteryUiForPercent(int? percent) {
  if (percent == null) {
    return const BatteryUi(Icons.battery_unknown, Colors.grey);
  }

  final p = percent.clamp(0, 100);

  return switch (p) {
    <= 5 => const BatteryUi(Icons.battery_alert, Colors.redAccent),
    <= 15 => const BatteryUi(Icons.battery_0_bar, Colors.redAccent),
    <= 30 => const BatteryUi(Icons.battery_1_bar, Colors.orange),
    <= 45 => const BatteryUi(Icons.battery_2_bar, Colors.amber),
    <= 60 => const BatteryUi(Icons.battery_3_bar, Colors.lightGreen),
    <= 80 => const BatteryUi(Icons.battery_5_bar, Colors.green),
    _ => const BatteryUi(Icons.battery_full, Colors.green),
  };
}

/// The top bar's battery readout: the icon over the percentage, or the
/// voltage after a tap. [showText]: a narrow bar keeps the icon alone.
class BatteryIndicator extends StatefulWidget {
  final MeshCoreConnector connector;
  final bool showText;

  const BatteryIndicator({
    super.key,
    required this.connector,
    this.showText = true,
  });

  static const textStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const _iconSize = 18.0;
  static const _padding = 8.0;

  /// The texts the readout can show, both to be measured: the percentage
  /// and the voltage it toggles to. Empty while the radio has reported no
  /// battery, when the readout shows nothing at all.
  static List<String> textsFor(MeshCoreConnector connector) {
    final millivolts = connector.batteryMillivolts;
    if (millivolts == null) return const [];
    final percent = connector.batteryPercent;
    return [
      percent != null ? '$percent%' : '—',
      '${(millivolts / 1000.0).toStringAsFixed(2)}V',
    ];
  }

  /// The readout's width for a text that measures [textWidth] (0: the
  /// icon alone).
  static double width(double textWidth) =>
      math.max(_iconSize, textWidth) + _padding;

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  bool _showBatteryVoltage = false;

  @override
  Widget build(BuildContext context) {
    final percent = widget.connector.batteryPercent;
    final millivolts = widget.connector.batteryMillivolts;

    if (millivolts == null) {
      return const SizedBox.shrink();
    }

    final String displayText;
    if (_showBatteryVoltage) {
      displayText = '${(millivolts / 1000.0).toStringAsFixed(2)}V';
    } else {
      displayText = percent != null ? '$percent%' : '—';
    }

    final batteryUi = batteryUiForPercent(percent);

    return InkWell(
      onTap: () {
        setState(() {
          _showBatteryVoltage = !_showBatteryVoltage;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatteryIndicator._padding / 2,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              batteryUi.icon,
              size: BatteryIndicator._iconSize,
              color: batteryUi.color,
            ),
            if (widget.showText) ...[
              const SizedBox(height: 2),
              Text(
                displayText,
                style: BatteryIndicator.textStyle.copyWith(color: batteryUi.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
