import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_connector.dart';

class CompanionInfoScreen extends StatelessWidget {
  const CompanionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_deviceInfo),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoTile('Device Name', connector.deviceDisplayName),
          _buildInfoTile('Firmware Version', connector.firmwareVersion ?? (connector.firmwareVerCode != null ? 'v${connector.firmwareVerCode}' : 'Unknown')),
          if (connector.firmwareVerCode != null) _buildInfoTile('Protocol Version', 'v${connector.firmwareVerCode}'),
          _buildInfoTile('Hardware ID', connector.deviceId ?? 'Unknown'),
          _buildInfoTile('Public Key (Hex)', connector.selfPublicKeyHex),
          _buildInfoTile('Transport Type', connector.activeTransport.name),
          if (connector.currentTxPower != null) _buildInfoTile('Current TX Power', '${connector.currentTxPower} dBm'),
          if (connector.maxTxPower != null) _buildInfoTile('Max TX Power', '${connector.maxTxPower} dBm'),
          if (connector.currentFreqHz != null) _buildInfoTile('Frequency', '${(connector.currentFreqHz! / 1000).toStringAsFixed(2)} MHz'),
          if (connector.currentBwHz != null) _buildInfoTile('Bandwidth', '${connector.currentBwHz! / 1000} kHz'),
          if (connector.currentSf != null) _buildInfoTile('Spreading Factor (SF)', '${connector.currentSf}'),
          if (connector.currentCr != null) _buildInfoTile('Coding Rate (CR)', '4/${connector.currentCr}'),
          if (connector.batteryPercent != null) _buildInfoTile('Battery Percent', '${connector.batteryPercent}%'),
          if (connector.batteryMillivolts != null) _buildInfoTile('Battery Voltage', '${connector.batteryMillivolts} mV'),
          if (connector.selfLatitude != null && connector.selfLongitude != null) _buildInfoTile('Location', '${connector.selfLatitude!.toStringAsFixed(4)}, ${connector.selfLongitude!.toStringAsFixed(4)}'),
          if (connector.multiAcks != 0) _buildInfoTile('Multi-Acks', '${connector.multiAcks}'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
  }
}
