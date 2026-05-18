import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_scanner_widget.dart';
import '../helpers/snack_bar_builder.dart';

/// Scans a contact QR code and returns the raw scanned string to the caller.
///
/// Accepts three formats:
/// - `meshtrax://HEX` — full advert frame (MeshTrax export)
/// - URL with `?public_key=HEX64` — letsmesh.net share link
/// - 64-char hex string — bare 32-byte public key
class ContactQrScannerScreen extends StatefulWidget {
  const ContactQrScannerScreen({super.key});

  @override
  State<ContactQrScannerScreen> createState() => _ContactQrScannerScreenState();
}

class _ContactQrScannerScreenState extends State<ContactQrScannerScreen> {
  bool _isProcessing = false;

  static bool _isValidContactQr(String data) {
    // meshtrax:// full advert format
    if (data.startsWith('meshtrax://')) {
      final hex = data.substring('meshtrax://'.length);
      return hex.length >= 196 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex);
    }
    // URI with ?public_key=<64-hex> — meshcore://contact/add or letsmesh.net links
    if (RegExp(r'[?&]public_key=[0-9a-fA-F]{64}').hasMatch(data)) {
      return true;
    }
    // Bare 64-char hex public key
    if (data.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(data)) {
      return true;
    }
    return false;
  }

  void _handleScanned(BuildContext context, String data) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    Navigator.pop(context, data);
  }

  void _showInvalidQrError(BuildContext context) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.contacts_invalidAdvertFormat),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.contacts_scanQrCode),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : QrScannerWidget(
              onScanned: (data) => _handleScanned(context, data),
              validator: _isValidContactQr,
              onValidationFailed: (_) => _showInvalidQrError(context),
              instructions: context.l10n.contacts_scanContactInstructions,
            ),
    );
  }
}
