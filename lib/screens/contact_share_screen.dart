import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_code_display.dart';

/// A QR code and a meshcore:// link that add a contact, room or repeater on
/// another phone. A room's link carries no password: the person who scans
/// it is asked for one when they open the room.
class ContactShareScreen extends StatelessWidget {
  final String name;
  final String pubKeyHex;
  final int type;

  /// This radio's own identity.
  final bool isSelf;

  const ContactShareScreen({
    super.key,
    required this.name,
    required this.pubKeyHex,
    required this.type,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final qrData = MeshCoreQr.encodeContact(name, pubKeyHex, type);
    final isRoom = type == advTypeRoom;
    final title = isSelf
        ? l10n.contacts_shareMyQrCode
        : isRoom
            ? l10n.share_roomTitle
            : l10n.share_contactTitle;
    final instructions = isSelf
        ? l10n.contacts_shareQrCodeDesc
        : isRoom
            ? l10n.share_roomInstructions
            : l10n.share_contactInstructions;

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QrCodeDisplay(
                data: qrData,
                size: 300,
                title: name,
                instructions: instructions,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              _copyCard(context, l10n.contacts_publicKey, pubKeyHex),
              const SizedBox(height: 16),
              _copyCard(context, l10n.channels_meshcoreUri, qrData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _copyCard(BuildContext context, String label, String value) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.common_copiedToClipboard),
                    );
                  },
                  tooltip: context.l10n.common_copyToClipboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
