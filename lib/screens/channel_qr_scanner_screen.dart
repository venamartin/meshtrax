import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../helpers/meshcore_qr.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_scanner_widget.dart';
import '../helpers/snack_bar_builder.dart';

class ChannelQrScannerScreen extends StatefulWidget {
  const ChannelQrScannerScreen({super.key});

  @override
  State<ChannelQrScannerScreen> createState() => _ChannelQrScannerScreenState();
}

class _ChannelQrScannerScreenState extends State<ChannelQrScannerScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.channels_shareChannelQr),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : QrScannerWidget(
              onScanned: (data) => _handleScannedData(context, data),
              validator: MeshCoreQr.isChannelQr,
              onValidationFailed: (_) => _showInvalidQrError(context),
              instructions: context.l10n.channels_shareChannelInstructions,
            ),
    );
  }

  Future<void> _handleScannedData(BuildContext context, String data) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final channelData = MeshCoreQr.parseChannelQr(data);
      if (channelData == null) throw Exception('Invalid QR data');

      if (context.mounted) {
        await _showJoinConfirmationDialog(context, channelData);
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.community_invalidQrCode), // Can reuse this or add new l10n
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showInvalidQrError(BuildContext context) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.community_invalidQrCode),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _showJoinConfirmationDialog(
    BuildContext context,
    ChannelQrData channelData,
  ) async {
    final connector = context.read<MeshCoreConnector>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.channels_addChannel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.channels_addChannelConfirmation),
            const SizedBox(height: 16),
            Text(
              channelData.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Secret: ${channelData.pskHex.substring(0, 8)}...',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_add),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final nextIndex = _findNextAvailableChannelIndex(connector);
      if (nextIndex != null) {
        connector.setChannel(nextIndex, channelData.name, hex2Uint8List(channelData.pskHex));
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.channels_channelAddedSuccess),
          backgroundColor: Colors.green,
        );
      } else {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.channels_noAvailableChannelSlots),
          backgroundColor: Colors.red,
        );
      }
      Navigator.pop(context);
    } else if (context.mounted) {
      Navigator.pop(context);
    }
  }

  int? _findNextAvailableChannelIndex(MeshCoreConnector connector) {
    final usedIndices = connector.channels.map((c) => c.index).toSet();
    for (int i = 0; i < connector.maxChannels; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return null;
  }
}
