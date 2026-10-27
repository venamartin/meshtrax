import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/widgets/battery_indicator.dart';
import 'package:provider/provider.dart';

import 'snr_indicator.dart';

/// The top bar's title with the radio's battery and signal readouts after
/// it. The title has first claim on the width; the readouts fit into what
/// is left and give way in a fixed order when the bar is narrow (owner,
/// 2026-10-27): the signal's repeater line first, then the battery text,
/// then the battery, then the signal. What goes stays one tap away in the
/// dialogs the readouts open.
class AppBarTitle extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool indicators;
  final bool showBatteryIndicator;
  final bool subtitle;
  const AppBarTitle(
    this.title, {
    this.leading,
    this.trailing,
    this.indicators = true,
    this.showBatteryIndicator = true,
    this.subtitle = true,
    super.key,
  });

  static const _gap = 6.0;
  static final _subtitleStyle = TextStyle(fontSize: 14, color: Colors.grey[600]);

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    final selfName = connector.selfName;
    final titleStyle = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);

    double width(String text, TextStyle style) => (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout())
        .width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final showSubtitle =
            connector.isConnected && selfName != null && subtitle;

        // What the readouts need, full and cut down.
        final battery = showBatteryIndicator && indicators
            ? BatteryIndicator.textsFor(connector)
            : const <String>[];
        final batteryFull = battery.isEmpty
            ? 0.0
            : BatteryIndicator.width(
                battery.map((t) => width(t, BatteryIndicator.textStyle)).reduce(math.max),
              );
        final batteryIcon = battery.isEmpty ? 0.0 : BatteryIndicator.width(0);
        final signal = SNRIndicator.textsFor(connector);
        final signalShort = SNRIndicator.width(width(signal.text, SNRIndicator.textStyle));
        final signalFull = signal.repeaters == null
            ? signalShort
            : math.max(signalShort, SNRIndicator.width(width(signal.repeaters!, SNRIndicator.repeatersStyle)));

        // The title's claim: what its lines need, leaving the signal its
        // icon and dB at least, and never less than half the bar.
        final wanted = math.max(
              width(title, titleStyle),
              showSubtitle ? width(selfName, _subtitleStyle) : 0,
            ) +
            4;
        final claim = math.min(
          wanted,
          math.max(availableWidth / 2, availableWidth - signalShort - _gap),
        );
        final room = availableWidth - claim - _gap;

        var showBattery = battery.isNotEmpty;
        var batteryText = true;
        var showSignal = indicators;
        var repeaterLine = true;
        if (!indicators) {
          showBattery = false;
        } else if (batteryFull + signalFull <= room) {
          // Everything fits.
        } else if (batteryFull + signalShort <= room) {
          repeaterLine = false;
        } else if (batteryIcon + signalShort <= room) {
          repeaterLine = false;
          batteryText = false;
        } else if (signalShort <= room) {
          repeaterLine = false;
          showBattery = false;
        } else if (batteryIcon <= room) {
          batteryText = false;
          showSignal = false;
        } else {
          showBattery = false;
          showSignal = false;
        }
        final showIndicators = showBattery || showSignal;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            leading ?? const SizedBox.shrink(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (showSubtitle)
                    Text(
                      selfName,
                      style: _subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (showIndicators) const SizedBox(width: _gap),
            if (showIndicators)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBattery)
                    BatteryIndicator(connector: connector, showText: batteryText),
                  if (showSignal)
                    SNRIndicator(
                      connector: connector,
                      showRepeaterLine: repeaterLine,
                    ),
                ],
              ),
            trailing ?? const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
