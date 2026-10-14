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

class SNRIndicator extends StatelessWidget {
  final MeshCoreConnector connector;

  const SNRIndicator({super.key, required this.connector});

  bool _isValidSelfLocation(double lat, double lon) {
    const double epsilon = 1e-6;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  @override
  Widget build(BuildContext context) {
    final directRepeaters = connector.directRepeaters;
    final directBestRepeaters = List.of(directRepeaters)
      ..sort(DirectRepeater.compare);
    final directRepeater = directBestRepeaters.isEmpty
        ? null
        : directBestRepeaters.first;

    final snrUi = snrUiFromSNR(
      directBestRepeaters.isNotEmpty ? directRepeater!.snr : null,
      connector.currentSf,
    );

    final selfLat = connector.selfLatitude;
    final selfLon = connector.selfLongitude;
    final hasValidLocation = selfLat != null && selfLon != null && _isValidSelfLocation(selfLat, selfLon);
    final isLiveGps = connector.advertLocationPolicy == 1;

    IconData locationIcon;
    if (hasValidLocation) {
      locationIcon = isLiveGps ? Icons.satellite_alt : Icons.location_on;
    } else {
      locationIcon = Icons.location_off;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),

      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => NearbyRepeatersDialog(connector: connector),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  connector.isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(snrUi.icon, size: 18, color: snrUi.color),
                  const SizedBox(width: 4),
                  Icon(
                    locationIcon,
                    size: 14,
                    color: hasValidLocation ? Colors.green : Colors.red,
                  ),
                ],
              ),
              Text(
                connector.isDiscovering ? 'Wait' : snrUi.text,
                style: TextStyle(fontSize: 12, color: snrUi.color),
              ),
              if (directRepeater != null)
                Text(
                  '${directRepeaters.length}: ${directRepeater.prefixHex}: ${formatAgo(directRepeater.lastUpdated)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
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
