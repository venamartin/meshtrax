import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';
import 'nearby_repeaters_dialog.dart';
import 'signal_ui.dart';

class SNRUi {
  final IconData icon;
  final Color color;
  final String text;
  const SNRUi(this.icon, this.color, this.text);
}

List<double> getSNRfromSF(int spreadingFactor) {
  switch (spreadingFactor) {
    case 7:
      return [4.0, -2.0, -4.0, -6.0];
    case 8:
      return [4.0, -4.0, -6.0, -8.0];
    case 9:
      return [4.0, -6.0, -8.0, -10.0];
    case 10:
      return [4.0, -8.0, -10.0, -13.0];
    case 11:
      return [4.0, -10.0, -12.5, -15.0];
    case 12:
      return [4.0, -12.5, -15.0, -18.0];
    default:
      return []; // Or throw Exception('Invalid SF: $spreadingFactor');
  }
}

SNRUi snrUiFromSNR(double? snr, int? spreadingFactor) {
  if (snr == null ||
      spreadingFactor == null ||
      spreadingFactor < 7 ||
      spreadingFactor > 12) {
    return const SNRUi(Icons.signal_cellular_off, Colors.grey, '—');
  }

  final snrLevels = getSNRfromSF(spreadingFactor);

  String text = '${snr.toStringAsFixed(1)} dB';
  final tier = snr >= snrLevels[0]
      ? 0
      : snr >= snrLevels[1]
      ? 1
      : snr >= snrLevels[2]
      ? 2
      : snr >= snrLevels[3]
      ? 3
      : 4;
  final signalUi = signalUiForStrengthTier(tier);

  return SNRUi(signalUi.icon, signalUi.color, text);
}

/// Compact age: 12s, 4m, 3h, 2d.
String formatAgo(DateTime lastSeen) {
  final now = DateTime.now();
  final diff = now.difference(lastSeen);
  if (diff.isNegative) {
    return "0s";
  }
  if (diff.inMinutes < 1) {
    return "${diff.inSeconds}s";
  }
  if (diff.inMinutes < 60) {
    return "${diff.inMinutes}m";
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return "${hours}h";
  }
  final days = diff.inDays;
  return "${days}d";
}

/// The top bar's signal readout: the icon, the best direct repeater's SNR
/// and, under it, how many repeaters hear this radio, the best one's code
/// and how long ago ("1: A277: 22s"). Tapping opens the nearby repeaters.
/// [showRepeaterLine]: a narrow bar drops that last line first.
class SNRIndicator extends StatelessWidget {
  final MeshCoreConnector connector;
  final bool showRepeaterLine;

  const SNRIndicator({
    super.key,
    required this.connector,
    this.showRepeaterLine = true,
  });

  static const textStyle = TextStyle(fontSize: 12);
  static const repeatersStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );
  static const _iconSize = 18.0;
  static const _padding = 8.0;
  static const _minWidth = 40.0;

  /// What the readout shows for [connector]: the icon and colour, the
  /// signal line, and the repeater line when a repeater has been heard.
  static ({SNRUi ui, String text, String? repeaters}) textsFor(
    MeshCoreConnector connector,
  ) {
    final directRepeaters = connector.directRepeaters;
    final best = List.of(directRepeaters)..sort(DirectRepeater.compare);
    final directRepeater = best.isEmpty ? null : best.first;
    final ui = snrUiFromSNR(directRepeater?.snr, connector.currentSf);
    return (
      ui: ui,
      text: connector.isDiscovering ? 'Wait' : ui.text,
      repeaters: directRepeater == null
          ? null
          : '${directRepeaters.length}: ${directRepeater.prefixHex}: '
              '${formatAgo(directRepeater.lastUpdated)}',
    );
  }

  /// The readout's width when its widest line measures [textWidth].
  static double width(double textWidth) =>
      math.max(_minWidth, math.max(_iconSize, textWidth) + _padding);

  @override
  Widget build(BuildContext context) {
    final (:ui, :text, :repeaters) = textsFor(connector);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _minWidth, minHeight: 40),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => NearbyRepeatersDialog(connector: connector),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _padding / 2,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              connector.isDiscovering
                  ? const SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(ui.icon, size: _iconSize, color: ui.color),
              Text(text, style: textStyle.copyWith(color: ui.color)),
              if (showRepeaterLine && repeaters != null)
                Text(
                  repeaters,
                  style: repeatersStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
