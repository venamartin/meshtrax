import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_code_display.dart';

class ContactShareScreen extends StatelessWidget {
  final String name;
  final String pubKeyHex;
  final int type;

  const ContactShareScreen({
    super.key,
    required this.name,
    required this.pubKeyHex,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = MeshCoreQr.encodeContact(name, pubKeyHex, type);
    
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.contacts_shareMyQrCode),
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
                instructions: context.l10n.contacts_shareQrCodeDesc,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              _buildPublicKeyCard(context, pubKeyHex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicKeyCard(BuildContext context, String pubKeyHex) {
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
              context.l10n.contacts_publicKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    pubKeyHex,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pubKeyHex));
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
