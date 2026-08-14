import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../l10n/l10n.dart';
import 'signal_ui.dart';

/// A reusable tile widget for displaying a MeshCore device in a list
class DeviceTile extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.scanResult, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final device = scanResult.device;
    final rssi = scanResult.rssi;
    // advName comes from the advert we just heard; platformName is the OS's
    // cached GATT name, which survives a rename on the device.
    final advName = scanResult.advertisementData.advName;
    final name = advName.isNotEmpty ? advName : device.platformName;

    return ListTile(
      leading: _buildSignalIcon(rssi),
      title: Text(
        name.isNotEmpty ? name : context.l10n.common_unknownDevice,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(device.remoteId.toString()),
      trailing: ElevatedButton(
        onPressed: onTap,
        child: Text(context.l10n.common_connect),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSignalIcon(int rssi) {
    final tier = rssi >= -60
        ? 0
        : rssi >= -70
        ? 1
        : rssi >= -80
        ? 2
        : rssi >= -90
        ? 3
        : 4;
    final signalUi = signalUiForStrengthTier(tier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(signalUi.icon, color: signalUi.color),
        Text(
          '$rssi dBm',
          style: TextStyle(fontSize: 10, color: signalUi.color),
        ),
      ],
    );
  }
}
